from bifrostlib import common
from bifrostlib.datahandling import Sample
from bifrostlib.datahandling import SampleComponentReference
from bifrostlib.datahandling import SampleComponent
from bifrostlib.datahandling import Category
from typing import Dict
import os


def ensure_tool_category(samplecomponent, category_name: str) -> Category:
    category = samplecomponent.get_category(category_name)
    if category is None:
        category = Category(value={
            "name": category_name,
            "component": samplecomponent.component,
            "summary": {
                "serotype": "",
                "antigenic_profile": "",
                "status": "",
            },
            "report": {},
        })

    if "summary" not in category:
        category["summary"] = {}
    if "report" not in category:
        category["report"] = {}

    category["summary"].setdefault("serotype", "")
    category["summary"].setdefault("antigenic_profile", "")
    category["summary"].setdefault("status", "")

    return category


def ensure_final_serotype_category(sample) -> Category:
    serotype = sample.get_category("serotype")
    if serotype is None:
        serotype = Category(value={
            "name": "serotype",
            "component": {
                "name": "serotype"
            },
            "summary": {
                "serotype": "",
                "antigenic_profile": "",
                "status": "",
            },
            "report": {},
        })

    if "summary" not in serotype:
        serotype["summary"] = {}
    if "report" not in serotype:
        serotype["report"] = {}

    serotype["summary"].setdefault("serotype", "")
    serotype["summary"].setdefault("antigenic_profile", "")
    serotype["summary"].setdefault("status", "")

    return serotype


def find_category_by_name(obj, category_name: str):
    return obj.get_category(category_name)


def update_consensus_field(summary: dict, field: str, value: str) -> bool:
    if value is None:
        return False

    value = value.strip()
    if value == "":
        return False

    current = summary.get(field, "")
    if current is None:
        current = ""
    current = current.strip()

    if current == "":
        summary[field] = value
        return False

    if current == value:
        return False

    return True


def update_consensus_summary(serotype: Category, tool_serotype: str) -> None:
    summary = serotype["summary"]
    previous_status = summary.get("status", "")

    serotype_conflict = update_consensus_field(summary, "serotype", tool_serotype)


    if serotype_conflict:
        summary["status"] = "Ambiguous"
    elif previous_status != "Ambiguous":
        has_serotype = summary.get("serotype", "").strip() != ""

        if has_serotype:
            summary["status"] = "Concordant"


def merge_tool_into_final(final_serotype: Category, tool_category) -> None:
    if tool_category is None:
        return

    tool_summary = tool_category["summary"]
    tool_report = tool_category["report"]

    update_consensus_summary(
        final_serotype,
        tool_summary.get("serotype", ""),

    )

    final_serotype["report"].update(tool_report)


def rebuild_final_serotype(sample) -> None:
    final_serotype = ensure_final_serotype_category(sample)

    final_serotype["summary"]["serotype"] = ""
    final_serotype["summary"]["antigenic_profile"] = ""
    final_serotype["summary"]["status"] = ""
    final_serotype["report"] = {}

    merge_tool_into_final(final_serotype, find_category_by_name(sample, "enterobase_serotype"))
    merge_tool_into_final(final_serotype, find_category_by_name(sample, "sistr_serotype"))
    merge_tool_into_final(final_serotype, find_category_by_name(sample, "seqsero_serotype"))

    sample.set_category(final_serotype)


def parse_seqsero_results(results: Dict, component_name: str) -> Dict:
    file_path = os.path.join(component_name, "SeqSero_result.txt")

    key_map = {
        "Input files": "Input files",
        "O antigen prediction": "O antigen prediction",
        "H1 antigen prediction(fliC)": "H1 antigen prediction",
        "H2 antigen prediction(fljB)": "H2 antigen prediction",
        "Predicted identification": "Predicted identification",
        "Predicted antigenic profile": "Predicted antigenic profile",
        "Predicted serotype": "Predicted serotype",
        "Note": "Note",
    }

    with open(file_path, "r", encoding="utf-8") as fh:
        for raw_line in fh:
            line = raw_line.strip()

            if ":" not in line:
                continue

            key, value = line.split(":", 1)
            key = key.strip()
            value = value.strip()

            if key in key_map:
                results[key_map[key]] = value

    return {
        "seqsero_serotype": results.get("Predicted serotype", ""),
        "seqsero_antigenic_profile": results.get("Predicted antigenic profile", ""),
        "seqsero_identification": results.get("Predicted identification", ""),
        "seqsero_note": results.get("Note", ""),
        "seqsero_o_antigen_prediction": results.get("O antigen prediction", ""),
        "seqsero_h1_antigen_prediction": results.get("H1 antigen prediction", ""),
        "seqsero_h2_antigen_prediction": results.get("H2 antigen prediction", ""),
        "seqsero_input_files": results.get("Input files", ""),
    }


def datadump(samplecomponent_ref_json: Dict):
    samplecomponent_ref = SampleComponentReference(value=samplecomponent_ref_json)
    samplecomponent = SampleComponent.load(samplecomponent_ref)
    sample = Sample.load(samplecomponent.sample)

    parsed = parse_seqsero_results(
        samplecomponent["results"],
        samplecomponent["component"]["name"],
    )

    seqsero_category = ensure_tool_category(samplecomponent, "seqsero_serotype")

    seqsero_category["summary"]["serotype"] = parsed["seqsero_serotype"]
    seqsero_category["summary"]["antigenic_profile"] = parsed["seqsero_antigenic_profile"]
    seqsero_category["summary"]["status"] = ""

    seqsero_category["report"]["seqsero_serotype"] = parsed["seqsero_serotype"]
    seqsero_category["report"]["seqsero_antigenic_profile"] = parsed["seqsero_antigenic_profile"]
    seqsero_category["report"]["seqsero_identification"] = parsed["seqsero_identification"]
    seqsero_category["report"]["seqsero_note"] = parsed["seqsero_note"]
    seqsero_category["report"]["seqsero_o_antigen_prediction"] = parsed["seqsero_o_antigen_prediction"]
    seqsero_category["report"]["seqsero_h1_antigen_prediction"] = parsed["seqsero_h1_antigen_prediction"]
    seqsero_category["report"]["seqsero_h2_antigen_prediction"] = parsed["seqsero_h2_antigen_prediction"]
    seqsero_category["report"]["seqsero_input_files"] = parsed["seqsero_input_files"]

    samplecomponent.set_category(seqsero_category)
    sample.set_category(seqsero_category)

    samplecomponent.save_files()
    common.set_status_and_save(sample, samplecomponent, "Success")

    fresh_sample = Sample.load(samplecomponent.sample)
    rebuild_final_serotype(fresh_sample)
    common.set_status_and_save(fresh_sample, samplecomponent, "Success")

    with open(
        os.path.join(samplecomponent["component"]["name"], "datadump_complete"),
        "w+",
        encoding="utf-8",
    ) as fh:
        fh.write("done")


datadump(
    snakemake.params.samplecomponent_ref_json,
)
