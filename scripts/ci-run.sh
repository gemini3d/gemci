#!/usr/bin/env bash

set -e
set -o nounset

ctest_model=$1
duration=$2
cadence=$3
cpp=$4
tag=$5

wd=/tmp
cc_name="$(basename $CC)"

gemext_bin=${wd}/build_gemext_${cc_name}
ci_bin=${wd}/build_gemci_${cc_name}
prefix=${wd}/libgem_${cc_name}
ci_data=$HOME/gemci

cwd="$(dirname "${BASH_SOURCE}")"

if [[ $1 == "Nightly" ]]; then
  if [[ $OSTYPE == 'darwin'* ]]; then
    # Nproc=$(sysctl -n hw.physicalcpu)
    memGB=$(echo "$(sysctl -n hw.memsize) / 1024^3" | bc)
  elif [[ $OSTYPE == 'linux-gnu' ]]; then
    # Nproc=$(nproc)
    memKB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    memGB=$(echo "${memKB}/1024^2" | bc)
  else
    echo "Unknown OSTYPE: $OSTYPE"
    exit 1
  fi

  hdur=8 # maximum duration (hours)
  # select tests based on total RAM
  if [[ ${memGB} -gt 12 ]]; then
    # do all tests, including 3D
    test_exclude=""
    test_include=""
  elif [[ ${memGB} -gt 4 ]]; then
    # do 2D tests
    test_exclude="3D"
    test_include=""
  else
    # do only small 2D tests
    test_exclude="3D"
    test_include="mini2d"
  fi

  if [[ $OSTYPE == 'darwin'* ]]; then
    stop_time=$(date -v +${hdur}H +%FT%T)
  else # linux
    stop_time=$(date -d "+${hdur} hour" '+%FT%T')
  fi
else
  stop_time=""
  test_exclude=""
  test_include=""
fi

source ${cwd}/ci-prep.sh

site_name=$(uname -s)-$(uname -m)-${cc_name}

# run GemCI tests
${conda} \
  ctest \
  -DCMAKE_PREFIX_PATH:PATH=${prefix} \
  -DCTEST_STOP_TIME=${stop_time} \
  -Dgemini3d_tag=${tag} \
  -DGEMINI_CIROOT:PATH=${ci_data} \
  -DCTEST_BINARY_DIRECTORY=${ci_bin} \
  -DCTEST_SITE=${site_name} \
  -DCTEST_MODEL=${ctest_model} \
  -Dduration=${duration} \
  -Dcadence=${cadence} \
  -Dcpp:BOOL=${cpp} \
  -Dexclude=${test_exclude} \
  -Dinclude=${test_include} \
  -S ${ci_code}/gemci/ci.cmake -V
