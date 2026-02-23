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
from snakemake.io import directory
import datetime

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
<<<<<<< Updated upstream
        samplecomponent:SampleComponent = SampleComponent(sample_reference=sample.to_reference(), component_reference=component.to_reference()) # schema 2.1

=======
        samplecomponent:SampleComponent = SampleComponent(sample_reference=sample.to_reference(), component_reference=component.to_reference())
>>>>>>> Stashed changes
    common.set_status_and_save(sample, samplecomponent, "Running")

except Exception as error:
    print(traceback.format_exc(), file=sys.stderr)
    raise Exception("failed to set sample, component and/or samplecomponent")

onerror:
    if samplecomponent['status'] == "Running":
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

<<<<<<< Updated upstream
rule set_time_start:
    output:
        start_file = f"{component['name']}/time_start.txt"
=======

rule setup:
    output:
        init_file = touch(temp(f"{component['name']}/initialized")),
>>>>>>> Stashed changes
    run:
        import time
        with open(output.start_file, "w") as fh:
            fh.write(str(time.time()))

<<<<<<< Updated upstream
rule setup:
    input:
        rules.set_time_start.output.start_file
    output:
        init_file = touch(f"{component['name']}/initialized")
    run:
        samplecomponent["path"] = os.path.join(os.getcwd(), component["name"])
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
        check_file = f"{component['name']}/requirements_met",
    run:
        if samplecomponent.has_requirements():
            pass

=======
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        rules.check_requirements.output.check_file,
        contigs = sample['categories']['contigs']['summary']['data']
    output:
        outdir = directory(f"{component['name']}"),
        output_file = f"{component['name']}/SeqSero_result.txt",
        threads_file = f"{component['name']}/threads_used.txt",
        tool_version = f"{component['name']}/tool_version.txt"
    params:
        options = "-m k -t 4"
	name = f"{sample['name']}"
    threads: 8
    shell:
        r"""
        SeqSero2_package.py -i {input.contigs} -d {output.outdir} -n {params.name} {params.options} -p {threads} 1> {log.out_file} 2> {log.err_file}
=======
        assembly = sample['categories']['contigs']['summary']['data'],
        serovarlist = os.path.join(os.path.dirname(workflow.snakefile), "..", "resources", "serovar-list.txt")
    output:
        outdir = directory(f"{component['name']}"),
        sistr_tab = f"{component['name']}/sistr_results.tab",
        allele_results = f"{component['name']}/allele_results.tsv",
        gmlst_profile = f"{component['name']}/cgmlst_profiles.tsv",
        threads_file = f"{component['name']}/threads_used.txt",
        tool_version = f"{component['name']}/tool_version.txt"
    threads: 8
    conda:
        "RAHCS_env"
    shell:
        r"""
        mkdir -p {output.outdir}

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
>>>>>>> Stashed changes

        SeqSero2_package.py -v > {output.tool_version} 2>&1

<<<<<<< Updated upstream
        # Save threads used
        echo {threads} > {output.threads_file}
        """

# -------------------------------------------------------------------------
# END TIME + RUNTIME
# -------------------------------------------------------------------------

rule set_time_end:
    input:
        rules.run_seqsero.output.output_file
    output:
        end_file = f"{component['name']}/time_end.txt"
    run:
        import time
        with open(output.end_file, "w") as fh:
            fh.write(str(time.time()))

rule_name = "git_version"
rule git_version:
=======

#- Templated section: start ------------------------------------------------------------------------

rule_name = "datadump"
rule datadump:
>>>>>>> Stashed changes
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component['name']}/log/{rule_name}.out.log",
        err_file = f"{component['name']}/log/{rule_name}.err.log",
    benchmark:
        f"{component['name']}/benchmarks/{rule_name}.benchmark"
    input:
<<<<<<< Updated upstream
        rules.setup.output.init_file
=======
        rules.run_sistr.output.sistr_tab
>>>>>>> Stashed changes
    output:
        git_hash = f"{component['name']}/git_hash.txt"
    run:
        import subprocess, os

        snake_dir = os.path.dirname(workflow.snakefile)

        try:
            git_hash = subprocess.check_output(
                ["git", "-C", snake_dir, "rev-parse", "HEAD"],
                stderr=subprocess.STDOUT,
                text=True
            ).strip()
        except Exception as e:
            git_hash = "-"
            os.makedirs(os.path.dirname(log.err_file), exist_ok=True)
            with open(log.err_file, "a") as fh:
                fh.write(f"[git_version] Could not determine git hash from {snake_dir}: {e}\n")

        with open(output.git_hash, "w") as fh:
            fh.write(str(git_hash))

rule dump_info:
    input:
        start_file = rules.set_time_start.output.start_file,
        end_file = rules.set_time_end.output.end_file,
        threads_file = rules.run_seqsero.output.threads_file,
        tool_version = rules.run_seqsero.output.tool_version,
        git_hash = rules.git_version.output.git_hash
    output:
        runtime_flag = touch(f"{component['name']}/runtime_set")
    run:
        import time
        from bifrostlib.datahandling import SampleComponent

        with open(input.start_file) as fh:
            t_start = float(fh.read().strip())
        with open(input.end_file) as fh:
            t_end = float(fh.read().strip())
        with open(input.threads_file) as fh:
            threads_used = int(fh.read().strip())
        with open(input.tool_version) as fh:
            tool_version = str(fh.read().rstrip("\n"))
        with open(input.git_hash) as fh:
            git_hash = str(fh.read().strip())

        runtime_minutes = (t_end - t_start) / 60.0

        sc = SampleComponent.load(samplecomponent.to_reference())
        sc["time_start"] = datetime.datetime.fromtimestamp(t_start).strftime("%Y-%m-%d %H:%M:%S")
        sc["time_end"] = datetime.datetime.fromtimestamp(t_end).strftime("%Y-%m-%d %H:%M:%S")
        sc["time_running"] = round(runtime_minutes, 3)
        sc["threads_used"] = threads_used
        sc["tool_version"] = tool_version
        sc["git_hash"] = git_hash

        sc.save()

# -------------------------------------------------------------------------
# DATADUMP
# -------------------------------------------------------------------------

#* Dynamic section: end ****************************************************************************

rule_name = "datadump"
rule datadump:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component['name']}/log/{rule_name}.out.log",
        err_file = f"{component['name']}/log/{rule_name}.err.log"
    benchmark:
        f"{component['name']}/benchmarks/{rule_name}.benchmark"
    input:
        rules.run_seqsero.output.output_file,
        rules.dump_info.output.runtime_flag
    output:
        complete = f"{component['name']}/datadump_complete"
    params:
        samplecomponent_id = samplecomponent["_id"]
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "datadump.py")

#- Templated section: end --------------------------------------------------------------------------

