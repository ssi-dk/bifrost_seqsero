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

import datetime

os.umask(0o2)

try:
    sample_ref = SampleReference(_id=config.get('sample_id', None), name=config.get('sample_name', None))
    sample: Sample = Sample.load(sample_ref)
    if sample is None:
        raise Exception("invalid sample passed")

    component_ref = ComponentReference(name=config['component_name'])
    component: Component = Component.load(reference=component_ref)
    if component is None:
        raise Exception("invalid component passed")

    samplecomponent_ref = SampleComponentReference(
        name=SampleComponentReference.name_generator(sample.to_reference(), component.to_reference())
    )
    samplecomponent = SampleComponent.load(samplecomponent_ref)
    if samplecomponent is None:
        samplecomponent = SampleComponent(
            sample_reference=sample.to_reference(),
            component_reference=component.to_reference()
        )

    # Only set status here
    common.set_status_and_save(sample, samplecomponent, "Running")

except Exception:
    print(traceback.format_exc(), file=sys.stderr)
    raise Exception("failed to set sample, component and/or samplecomponent")

onerror:
    if not samplecomponent.has_requirements():
        common.set_status_and_save(sample, samplecomponent, "Requirements not met")
    if samplecomponent['status'] == "Running":
        common.set_status_and_save(sample, samplecomponent, "Failure")

envvars:
    "BIFROST_INSTALL_DIR",
    "CONDA_PREFIX",
    "BIFROST_STAGE", 
    "BIFROST_CPUS_BIG",

JOB_CPUS = int(os.environ.get("BIFROST_CPUS_BIG", 4))

# -------------------------------------------------------------------------
# MAIN RULES FIRST
# -------------------------------------------------------------------------

rule all:
    input:
        f"{component['name']}/datadump_complete"
    run:
        common.set_status_and_save(sample, samplecomponent, "Success")

# -------------------------------------------------------------------------
# FILE-BASED TIMING
# -------------------------------------------------------------------------

rule set_time_start:
    output:
        start_file = f"{component['name']}/time_start.txt"
    run:
        import time
        with open(output.start_file, "w") as fh:
            fh.write(str(time.time()))

rule setup:
    input:
        rules.set_time_start.output.start_file
    output:
        init_file = touch(f"{component['name']}/initialized")
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
        folder = rules.setup.output.init_file,
    output:
        check_file = touch(f"{component['name']}/requirements_met")
    run:
        if samplecomponent.has_requirements():
            #No need to write anything as the output is using touch to create the flag used to check the requirements
            pass

#* Dynamic section: start **************************************************************************

rule_name = "run_seqsero2"
rule run_seqsero2:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component['name']}/log/{rule_name}.out.log",
        err_file = f"{component['name']}/log/{rule_name}.err.log",
    benchmark:
        f"{component['name']}/benchmarks/{rule_name}.benchmark"
    input:
        rules.check_requirements.output.check_file,
        filtered_reads = sample["categories"]["trimmed_reads"]["summary"]["data"]
    output:
        seqsero2_file = f"{component['name']}/SeqSero_result.txt",
        threads_file = f"{component['name']}/threads_used.txt",
        tool_version = f"{component['name']}/tool_version.txt",
    params:
        options = "-m a -t 2",
        name = f"{sample['name']}",
        output_prefix = f"{component['name']}"
    threads: JOB_CPUS
    conda:
        f"bifrost_{os.environ["BIFROST_STAGE"]}_SeqSero"
    shell:
        r"""
        set -euo pipefail
        mkdir -p "$(dirname "{params.output_prefix}")"

        SeqSero2_package.py -i {input.filtered_reads[0]} {input.filtered_reads[1]} -n {params.name} {params.options} -p {threads} -d {params.output_prefix} 1> {log.out_file} 2> {log.err_file}

        SeqSero2_package.py -v > {output.tool_version}

        echo {threads} > {output.threads_file} 2>&1
        """

#* Dynamic section: end ****************************************************************************

# -------------------------------------------------------------------------
# END TIME + RUNTIME (FILE-BASED)
# -------------------------------------------------------------------------

rule set_time_end:
    input:
        rules.run_seqsero2.output.seqsero2_file
    output:
        end_file = f"{component['name']}/time_end.txt"
    run:
        import time
        with open(output.end_file, "w") as fh:
            fh.write(str(time.time()))

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
        rules.run_seqsero2.output.seqsero2_file,
        start_file = rules.set_time_start.output.start_file,
        end_file = rules.set_time_end.output.end_file,
    output:
        complete = rules.all.input
    params:
        samplecomponent_ref_json = samplecomponent.to_reference().json,
        samplecomponent_id = samplecomponent["_id"]
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "datadump.py")

#- Templated section: end --------------------------------------------------------------------------

