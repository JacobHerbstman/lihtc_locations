from __future__ import annotations

import csv
import os
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree
from zipfile import ZipFile


MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
WORKBOOK_PATH = Path("../temp/LIHTCPUB.xlsx")

metrics: list[dict[str, str | int]] = []

with ZipFile(WORKBOOK_PATH) as workbook:
    workbook_root = ElementTree.fromstring(workbook.read("xl/workbook.xml"))
    sheets = workbook_root.findall(f".//{{{MAIN_NS}}}sheet")
    defined_names = workbook_root.findall(f".//{{{MAIN_NS}}}definedName")

    metrics.extend(
        [
            {"category": "workbook", "metric": "sheet_count", "value": len(sheets)},
            {
                "category": "workbook",
                "metric": "hidden_sheet_count",
                "value": sum(sheet.attrib.get("state", "visible") != "visible" for sheet in sheets),
            },
            {
                "category": "workbook",
                "metric": "defined_name_count",
                "value": len(defined_names),
            },
            {
                "category": "workbook",
                "metric": "external_link_part_count",
                "value": sum(name.startswith("xl/externalLinks/") for name in workbook.namelist()),
            },
        ]
    )

    for sheet_path in sorted(
        name
        for name in workbook.namelist()
        if name.startswith("xl/worksheets/sheet") and name.endswith(".xml")
    ):
        cell_types: Counter[str] = Counter()
        row_count = 0
        cell_count = 0
        formula_count = 0
        error_cell_count = 0
        merged_range_count = 0
        data_validation_count = 0
        hyperlink_count = 0

        with workbook.open(sheet_path) as sheet_file:
            for _, element in ElementTree.iterparse(sheet_file, events=("end",)):
                if element.tag == f"{{{MAIN_NS}}}row":
                    row_count += 1
                elif element.tag == f"{{{MAIN_NS}}}c":
                    cell_count += 1
                    cell_type = element.attrib.get("t", "n")
                    cell_types[cell_type] += 1
                    error_cell_count += cell_type == "e"

                    formula = element.find(f"{{{MAIN_NS}}}f")
                    if formula is not None:
                        formula_count += 1
                elif element.tag == f"{{{MAIN_NS}}}mergeCell":
                    merged_range_count += 1
                elif element.tag == f"{{{MAIN_NS}}}dataValidation":
                    data_validation_count += 1
                elif element.tag == f"{{{MAIN_NS}}}hyperlink":
                    hyperlink_count += 1
                if element.tag in {
                    f"{{{MAIN_NS}}}row",
                    f"{{{MAIN_NS}}}c",
                    f"{{{MAIN_NS}}}mergeCell",
                    f"{{{MAIN_NS}}}dataValidation",
                    f"{{{MAIN_NS}}}hyperlink",
                }:
                    element.clear()

        sheet_metrics = {
            "row_count": row_count,
            "cell_count": cell_count,
            "formula_cell_count": formula_count,
            "error_cell_count": error_cell_count,
            "merged_range_count": merged_range_count,
            "data_validation_count": data_validation_count,
            "hyperlink_count": hyperlink_count,
        }
        sheet_metrics.update(
            {f"cell_type_{cell_type}_count": count for cell_type, count in sorted(cell_types.items())}
        )
        metrics.extend(
            {
                "category": sheet_path,
                "metric": metric,
                "value": value,
            }
            for metric, value in sheet_metrics.items()
        )

output_path = Path("../output/workbook_structure.csv")
temporary_path = output_path.with_suffix(f"{output_path.suffix}.tmp")
with temporary_path.open("w", encoding="utf-8", newline="") as output_file:
    writer = csv.DictWriter(output_file, fieldnames=["category", "metric", "value"])
    writer.writeheader()
    writer.writerows(metrics)
os.replace(temporary_path, output_path)

print(f"Inspected {len(sheets)} workbook sheet")
