from bifrostlib import common
from bifrostlib.datahandling import Sample
from bifrostlib.datahandling import SampleComponentReference
from bifrostlib.datahandling import SampleComponent
from bifrostlib.datahandling import Component
from bifrostlib.datahandling import Category
from typing import Dict
import os

def split_and_store_result(line: str, results: Dict):
    results[line.split(":",1)[0]] = line.split(":",1)[1].strip()

def extract_serotype_results(serotype: Category, results: Dict, component_name: str) -> None:
    file_name = "serotype.txt"
    file_key = common.json_key_cleaner(file_name)
    file_path = os.path.join(component_name, file_name)

    for line in open(file_path,'r'):
        if line.startswith("Input files"):
            split_and_store_result(line, results)
        elif line.startswith("O antigen prediction"):
            split_and_store_result(line, results)
        elif line.startswith("H1 antigen prediction"):
            split_and_store_result(line, results)
        elif line.startswith("H2 antigen prediction"):
            split_and_store_result(line, results)
        elif line.startswith("Predicted antigenic profile"):
            split_and_store_result(line, results)
        elif line.startswith("Sdf prediction"):
            split_and_store_result(line, results)
        elif line.startswith("Predicted serotype"):
            split_and_store_result(line, results)
        else:
            results["comment"] = line.strip()

    serotype["summary"]["serotype"] = results["Predicted serotype(s)"]
    serotype["summary"]["antigenic profile"] = results["Predicted antigenic profile"]

def datadump(samplecomponent_ref_json: Dict):
    samplecomponent_ref = SampleComponentReference(value=samplecomponent_ref_json)
    samplecomponent = SampleComponent.load(samplecomponent_ref)
    sample = Sample.load(samplecomponent.sample)
    component = Component.load(samplecomponent.component)
    
    serotype = samplecomponent.get_category("serotype")
    if serotype is None:
        serotype = Category(value={
            "name": "serotype",
            "component": samplecomponent.component,
            "summary": {
                "serotype": "",
                "antigenic profile": "",
            },
            "report": {}
        })
    extract_serotype_results(serotype, samplecomponent["results"], samplecomponent["component"]["name"])
    samplecomponent.set_category(serotype)
    sample.set_category(serotype)
    samplecomponent.save_files()
    common.set_status_and_save(sample, samplecomponent, "Success")
    with open(os.path.join(samplecomponent["component"]["name"], "datadump_complete"), "w+") as fh:
        fh.write("done")


datadump(
    snakemake.params.samplecomponent_ref_json,
)
