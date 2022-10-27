#!/usr/bin/env bash

wrap=$HOME/gcc.sh
ci_code=$HOME/code

[[ -f $wrap ]] || { echo "$wrap not found"; exit 1; }

source $wrap

source $ci_code/gemci/scripts/ci-run.sh
