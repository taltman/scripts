#!/bin/bash
## Example:
## time run_mp assembly_dir scaffolds mp_template_config.txt mp_template_param.txt assembly_dir/metapathways_v2-5


function run_mp () {

    input_dir="$1"
    input_file="$2"
    config_file="$3"
    param_file="$4"
    output_dir="$5"    
    mp_root_dir=$HOME/farmshare/third-party/bin/MetaPathways/v2.5.2/
    mp_exec=$mp_root_dir/MetaPathways_Python.2.5.1/MetaPathways.py

    mkdir -p $output_dir
    
    pushd $output_dir

    source $mp_root_dir/MetaPathways_Python.2.5.1/MetaPathwaysrc
 
    date
    time python $mp_exec -i $input_dir \
	-o $PWD \
	-c $config_file \
	-p $param_file \
	-v -s $input_file
    date
    
    popd >> /dev/null
    
}
