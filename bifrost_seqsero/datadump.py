from bifrostlib import common
from bifrostlib.datahandling import Sample
from bifrostlib.datahandling import SampleComponentReference
from bifrostlib.datahandling import SampleComponent
from bifrostlib.datahandling import Category
from typing import Dict
import os


def extract_resistance_results(resistance: Category, results: Dict):
    file_name = "pheno_table.txt"
    file_key = common.json_key_cleaner(file_name)
    file_path = os.path.join(component_name, file_name)

    for line in open(file_path,'r'):
        if line.startswith('#'):
            continue
        line.strip().split()
        resistance["summary"]["genes"][""]



def datadump(samplecomponent_ref_json: Dict):
    samplecomponent_ref = SampleComponentReference(value=samplecomponent_ref_json)
    samplecomponent = SampleComponent.load(samplecomponent_ref)
    sample = Sample.load(samplecomponent.sample)
    component = Component.load(samplecomponent.component)
    
    resistance = samplecomponent.get_category("resistance")
    if resistance is None:
        resistance = Category(value={
            "name": "resistance",
            "component": samplecomponent.component,
            "summary": {
                "genes": {}
            },
            "report"
        }
    extract_resistance_results(resistance: Category, results: Dict)

datadump(
    snakemake.params.samplecomponent_ref_json,
)
