from __future__ import annotations

import csv
import hashlib
import os
import subprocess
import tempfile
from pathlib import Path
from zipfile import ZipFile


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
if source_rows[0]["landing_page"] != release["landing_page"]:
    raise RuntimeError("The source catalog and release manifest landing pages disagree.")

raw_archive = Path("../../../data_raw/hud_lihtc_property/2024/lihtcpub.zip")
temporary_file = tempfile.NamedTemporaryFile(
    prefix="lihtcpub.zip.",
    suffix=".tmp",
    dir=raw_archive.parent,
    delete=False,
)
temporary_archive = Path(temporary_file.name)
temporary_file.close()

try:
    subprocess.run(
        [
            "curl",
            "--fail",
            "--location",
            "--http1.1",
            "--silent",
            "--show-error",
            "--retry",
            "5",
            "--retry-delay",
            "2",
            "--retry-all-errors",
            "--connect-timeout",
            "30",
            "--max-time",
            "300",
            "--user-agent",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36",
            "--referer",
            release["landing_page"],
            "--header",
            "Accept: application/zip,application/octet-stream;q=0.9,*/*;q=0.8",
            "--output",
            str(temporary_archive),
            release["source_url"],
        ],
        check=True,
    )

    if temporary_archive.stat().st_size != int(release["expected_archive_bytes"]):
        raise RuntimeError("Downloaded LIHTC archive size does not match the pinned release.")

    archive_sha256 = hashlib.sha256(temporary_archive.read_bytes()).hexdigest()
    if archive_sha256 != release["expected_archive_sha256"]:
        raise RuntimeError("Downloaded LIHTC archive checksum does not match the pinned release.")

    expected_members = {
        "LIHTCPUB.accdb",
        f"LIHTC Data Dictionary {release['release_year']}.pdf",
        release["workbook_member"],
        "LIHTCPUB_BIN.xlsx",
    }
    with ZipFile(temporary_archive) as archive:
        if set(archive.namelist()) != expected_members:
            raise RuntimeError("Downloaded LIHTC archive members do not match the pinned release.")
        corrupt_member = archive.testzip()
        if corrupt_member is not None:
            raise RuntimeError(f"Downloaded LIHTC archive has a corrupt member: {corrupt_member}")
        workbook_info = archive.getinfo(release["workbook_member"])
        if workbook_info.file_size != int(release["expected_workbook_bytes"]):
            raise RuntimeError("LIHTC workbook size does not match the pinned release.")
        with archive.open(release["workbook_member"]) as workbook_file:
            workbook_sha256 = hashlib.sha256(workbook_file.read()).hexdigest()
        if workbook_sha256 != release["expected_workbook_sha256"]:
            raise RuntimeError("LIHTC workbook checksum does not match the pinned release.")

    os.replace(temporary_archive, raw_archive)
finally:
    temporary_archive.unlink(missing_ok=True)

print(f"Downloaded and verified {raw_archive}")
