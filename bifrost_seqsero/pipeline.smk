#- Templated section: start ------------------------------------------------------------------------
import os
import sys
import traceback

from bifrostlib import common
from bifrostlib.datahandling import SampleReference
from bifrostlib.datahandling import Sample
from bifrostlib.datahandling import ComponentReference
from bifrostlib.datahandling import Component
from bifrostlib.datahandling import SampleComponentReference
from bifrostlib.datahandling import SampleComponent
os.umask(0o2)

try:
    sample_ref = SampleReference(_id=config.get('sample_id', None), name=config.get('sample_name', None))
    sample:Sample = Sample.load(sample_ref)
    if sample is None:
        raise Exception("invalid sample passed")
    component_ref = ComponentReference(name=config['component_name'])
    component:Component = Component.load(reference=component_ref)
    if component is None:
        raise Exception("invalid component passed")
    samplecomponent_ref = SampleComponentReference(name=SampleComponentReference.name_generator(sample.to_reference(), component.to_reference()))
    samplecomponent = SampleComponent.load(samplecomponent_ref)
    if samplecomponent is None:
        samplecomponent:SampleComponent = SampleComponent(sample_reference=sample.to_reference(), component_reference=component.to_reference())
    common.set_status_and_save(sample, samplecomponent, "Running")
except Exception as error:
    print(traceback.format_exc(), file=sys.stderr)
    raise Exception("failed to set sample, component and/or samplecomponent")

onerror:
    if not samplecomponent.has_requirements():
        common.set_status_and_save(sample, samplecomponent, "Requirements not met")
    if samplecomponent["status"] == "Running":
        common.set_status_and_save(sample, samplecomponent, "Failure")

envvars:
    "BIFROST_INSTALL_DIR",
    "CONDA_PREFIX",
    "BIFROST_STAGE"


rule all:
    input:
        f"{component['name']}/datadump_complete"
    run:
        common.set_status_and_save(sample, samplecomponent, "Success")


rule setup:
    output:
        init_file = touch(f"{component['name']}/initialized"),
    run:
        samplecomponent['path'] = os.path.join(os.getcwd(), component['name'])
        samplecomponent.save()

rule_name = "check_requirements"
rule check_requirements:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component['name']}/log/{rule_name}.out.log",
        err_file = f"{component['name']}/log/{rule_name}.err.log",
    benchmark:
        f"{component['name']}/benchmarks/{rule_name}.benchmark"
    input:
        rules.setup.output.init_file
    output:
        check_file = touch(f"{component['name']}/requirements_met")
    run:
        os.makedirs(os.path.dirname(output.check_file), exist_ok=True)
        if samplecomponent.has_requirements():
            # touch file is enough
            pass

#- Templated section: end --------------------------------------------------------------------------


#* Dynamic section: start **************************************************************************

rule_name = "run_sistr"
rule run_sistr:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component['name']}/log/{rule_name}.out.log",
        err_file = f"{component['name']}/log/{rule_name}.err.log",
    benchmark:
        f"{component['name']}/benchmarks/{rule_name}.benchmark"
    input:
        rules.check_requirements.output.check_file,
        assembly = sample['categories']['contigs']['summary']['data'],
        serovarlist = os.path.join(os.path.dirname(workflow.snakefile), "..", "resources", "serovar-list.txt")
    output:
        sistr_tab = f"{component['name']}/sistr_results.tab",
        allele_results = f"{component['name']}/allele_results.tsv",
        gmlst_profile = f"{component['name']}/cgmlst_profiles.tsv",
        threads_file = f"{component['name']}/threads_used.txt",
        tool_version = f"{component['name']}/tool_version.txt"
    threads: 8
    shell:
        r"""
        sistr -f tab --qc \
            -t {threads} \
            -l {input.serovarlist} \
            --cgmlst-profiles {output.gmlst_profile} \
            --alleles-output {output.allele_results} \
            --output-prediction {output.sistr_tab} \
            {input.assembly} \
            1> {log.out_file} 2> {log.err_file}

        sistr --version > {output.tool_version} 2>&1
        echo {threads} > {output.threads_file}
        """

#* Dynamic section: end ****************************************************************************


#- Templated section: start ------------------------------------------------------------------------

rule_name = "datadump"
rule datadump:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component['name']}/log/{rule_name}.out.log",
        err_file = f"{component['name']}/log/{rule_name}.err.log",
    benchmark:
        f"{component['name']}/benchmarks/{rule_name}.benchmark"
    input:
        rules.run_sistr.output.sistr_tab
    output:
        complete = rules.all.input
    params:
        samplecomponent_id = samplecomponent["_id"]
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "datadump.py")

#- Templated section: end --------------------------------------------------------------------------

