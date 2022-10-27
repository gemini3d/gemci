#!/usr/bin/env bash

wrap=$HOME/oneapi.sh

[[ -f $wrap ]] || { echo "$wrap not found"; exit 1; }

source $wrap

source $HOME/ci-run.sh
