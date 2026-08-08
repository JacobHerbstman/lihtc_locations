from __future__ import annotations

import csv
import hashlib
import os
from io import BytesIO
from pathlib import PurePosixPath, Path
from xml.etree import ElementTree
from zipfile import ZipFile


MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
DOC_REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"

with open("release_manifest.csv", encoding="utf-8", newline="") as manifest_file:
    release_rows = list(csv.DictReader(manifest_file))

if len(release_rows) != 1:
    raise RuntimeError("The LIHTC release manifest must contain exactly one release.")

release = release_rows[0]
if release["release_year"] != "2024":
    raise RuntimeError("This task is pinned to the 2024 LIHTC release.")

with open("../input/source_catalog.csv", encoding="utf-8", newline="") as catalog_file:
    source_rows = [
        row for row in csv.DictReader(catalog_file) if row["source_id"] == "hud_lihtc_property"
    ]

if len(source_rows) != 1:
    raise RuntimeError("The source catalog must contain exactly one hud_lihtc_property row.")
if source_rows[0]["direct_download"] != release["source_url"]:
    raise RuntimeError("The source catalog and release manifest LIHTC URLs disagree.")

raw_archive = Path("../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip")
if raw_archive.stat().st_size != int(release["expected_archive_bytes"]):
    raise RuntimeError("LIHTC archive size does not match the pinned release.")

archive_sha256 = hashlib.sha256(raw_archive.read_bytes()).hexdigest()
if archive_sha256 != release["expected_archive_sha256"]:
    raise RuntimeError("LIHTC archive checksum does not match the pinned release.")

with ZipFile(raw_archive) as archive:
    workbook_bytes = archive.read(release["workbook_member"])

workbook_sha256 = hashlib.sha256(workbook_bytes).hexdigest()
if workbook_sha256 != release["expected_workbook_sha256"]:
    raise RuntimeError("LIHTC workbook checksum does not match the pinned release.")
if len(workbook_bytes) != int(release["expected_workbook_bytes"]):
    raise RuntimeError("LIHTC workbook size does not match the pinned release.")

with ZipFile(BytesIO(workbook_bytes)) as workbook:
    shared_strings = []
    if "xl/sharedStrings.xml" in workbook.namelist():
        shared_root = ElementTree.fromstring(workbook.read("xl/sharedStrings.xml"))
        for item in shared_root.findall(f"{{{MAIN_NS}}}si"):
            shared_strings.append(
                "".join(node.text or "" for node in item.iter(f"{{{MAIN_NS}}}t"))
            )

    workbook_root = ElementTree.fromstring(workbook.read("xl/workbook.xml"))
    sheets = workbook_root.findall(f".//{{{MAIN_NS}}}sheet")
    if len(sheets) != 1 or sheets[0].attrib["name"] != "Data":
        raise RuntimeError("LIHTC workbook must contain exactly one sheet named Data.")

    relationships_root = ElementTree.fromstring(workbook.read("xl/_rels/workbook.xml.rels"))
    relationship_targets = {
        relationship.attrib["Id"]: relationship.attrib["Target"]
        for relationship in relationships_root.findall(f"{{{PKG_REL_NS}}}Relationship")
    }
    relationship_id = sheets[0].attrib[f"{{{DOC_REL_NS}}}id"]
    sheet_path = relationship_targets[relationship_id].lstrip("/")
    if not sheet_path.startswith("xl/"):
        sheet_path = str(PurePosixPath("xl") / sheet_path)

    workbook_rows = 0
    header = []
    with workbook.open(sheet_path) as sheet_file:
        for _, element in ElementTree.iterparse(sheet_file, events=("end",)):
            if element.tag != f"{{{MAIN_NS}}}row":
                continue
            workbook_rows += 1
            if workbook_rows == 1:
                for cell in element.findall(f"{{{MAIN_NS}}}c"):
                    value_node = cell.find(f"{{{MAIN_NS}}}v")
                    value = "" if value_node is None else value_node.text
                    if cell.attrib.get("t") == "s" and value:
                        value = shared_strings[int(value)]
                    header.append(value)
            element.clear()

project_rows = workbook_rows - 1
if project_rows != int(release["expected_project_rows"]):
    raise RuntimeError("LIHTC workbook project count does not match the pinned release.")
if len(header) != int(release["expected_columns"]):
    raise RuntimeError("LIHTC workbook column count does not match the pinned release.")
if len(header) != len(set(header)):
    raise RuntimeError("LIHTC workbook column names must be unique.")

required_columns = {
    "hud_id",
    "latitude",
    "longitude",
    "fips2020",
    "n_units",
    "li_units",
    "yr_pis",
    "yr_alloc",
    "type",
    "credit",
    "record_stat",
}
if not required_columns.issubset(header):
    missing_columns = ", ".join(sorted(required_columns.difference(header)))
    raise RuntimeError(f"LIHTC workbook is missing required columns: {missing_columns}")

output_row = {
    "source_id": "hud_lihtc_property",
    "release_year": release["release_year"],
    "published_on": release["published_on"],
    "retrieved_on": release["retrieved_on"],
    "source_url": release["source_url"],
    "landing_page": release["landing_page"],
    "archive_path": "data_raw/hud_lihtc_property/2024/lihtcpub.zip",
    "archive_sha256": archive_sha256,
    "archive_bytes": raw_archive.stat().st_size,
    "workbook_member": release["workbook_member"],
    "workbook_sha256": workbook_sha256,
    "workbook_bytes": len(workbook_bytes),
    "project_rows": project_rows,
    "columns": len(header),
}

output_path = Path("../output/lihtc_property_2024_files.csv")
temporary_output = output_path.with_suffix(".csv.tmp")
with temporary_output.open("w", encoding="utf-8", newline="") as output_file:
    writer = csv.DictWriter(output_file, fieldnames=output_row.keys())
    writer.writeheader()
    writer.writerow(output_row)
os.replace(temporary_output, output_path)

print(f"Validated {project_rows:,} LIHTC projects in {raw_archive}")
