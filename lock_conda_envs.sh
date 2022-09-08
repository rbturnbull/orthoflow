#!/usr/bin/env bash

mamba_flag=$(type -P "mamba" > /dev/null && echo "--mamba")

echo "\nGenerating lock files for rule conda envs."
echo "This may take a few minutes!...\n"

for envfile in $(find orthoflow/workflow/envs -name '*.yaml' -o -name '*.yml'); do
    envbase=${envfile%.*}
    conda-lock $mamba_flag -p linux-64 -p osx-64 -f $envfile -k explicit --filename-template "${envbase}.{platform}.pin.txt"
done
