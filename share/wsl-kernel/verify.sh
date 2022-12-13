#!/bin/bash

set -eu

source "kernel.conf"

for module in ${loadables[@]}
do
    cat /proc/config.gz | gunzip | grep "${module}=m"
done

for module in ${builtins[@]}
do
    cat /proc/config.gz | gunzip | grep "${module}=y"
done

echo -e '\nAll modules are found.'
