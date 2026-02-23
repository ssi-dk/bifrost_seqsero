from bifrostlib import common
from bifrostlib.datahandling import Sample
from bifrostlib.datahandling import Component
from bifrostlib.datahandling import SampleComponentReference
from bifrostlib.datahandling import SampleComponent
from bifrostlib.datahandling import Category
import os


def parse_sistr_results(component_name: str):
    file_path = os.path.join(component_name, "sistr_results.tab")
    with open(file_path) as fh:
        header = fh.readline().strip().split("\t")
        values = fh.readline().strip().split("\t")
        return dict(zip(header, values))

def extract_sistr_statistics(serotype: Category, results: dict) -> None:
    """Store all SISTR results inside the summary section only."""

    # Core serotype fields
    serotype["summary"]["serotype"] = results.get("serovar", "")
    serotype["summary"]["antigenic_profile"] = results.get("antigenic_formula", "")
    serotype["summary"]["status"] = results.get("qc_status", "")   # single source of truth

    # Antigen predictions
    serotype["summary"]["h1"] = results.get("h1", "")
    serotype["summary"]["h2"] = results.get("h2", "")
    serotype["summary"]["o_antigen"] = results.get("o_antigen", "")
    serotype["summary"]["serogroup"] = results.get("serogroup", "")

    # cgMLST fields
    serotype["summary"]["cgmlst_ST"] = results.get("cgmlst_ST", "")
    serotype["summary"]["cgmlst_distance"] = results.get("cgmlst_distance", "")
    serotype["summary"]["cgmlst_found_loci"] = results.get("cgmlst_found_loci", "")
    serotype["summary"]["serovar_cgmlst"] = results.get("serovar_cgmlst", "")

    # QC messages
    serotype["summary"]["qc_messages"] = results.get("qc_messages", "")

    # Genome info
    serotype["summary"]["genome"] = results.get("genome", "")
    serotype["summary"]["fasta_filepath"] = results.get("fasta_filepath", "")


def datadump(samplecomponent_id: str):
    samplecomponent_ref = SampleComponentReference(_id=samplecomponent_id)
    samplecomponent = SampleComponent.load(samplecomponent_ref)
    sample = Sample.load(samplecomponent.sample)
    component = Component.load(samplecomponent.component)

    serotype = samplecomponent.get_category("serotype")
    if serotype is None:
        serotype = Category(value={
            "name": "serotype",
            "component": {
                "id": samplecomponent["component"]["_id"],
                "name": samplecomponent["component"]["name"]
            },
            "summary": {
                "serotype": "",
                "antigenic_profile": "",
                "status": ""
            },
            "report": {}
        })

    results = parse_sistr_results(samplecomponent["component"]["name"])
    extract_sistr_statistics(serotype, results)

    samplecomponent.set_category(serotype)
    sample.set_category(serotype)

    samplecomponent.save_files()
    common.set_status_and_save(sample, samplecomponent, "Success")

    with open(os.path.join(samplecomponent["component"]["name"], "datadump_complete"), "w+") as fh:
        fh.write("done")


datadump(
    snakemake.params.samplecomponent_id
)
