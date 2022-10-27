#!/usr/bin/env bash

set -e
set -o nounset

wd=/tmp

gemext_bin=$wd/build_gemext_gnu
ci_bin=$wd/build_gemci_gnu
prefix=$wd/libgem_gnu
ci_data=$HOME/ci_data

cwd="$(dirname "${BASH_SOURCE}")"

if [[ $1 == "Nightly" ]]; then
  if [[ $OSTYPE == 'darwin'* ]]; then
    Nproc=$(sysctl -n hw.physicalcpu)
  else
    Nproc=$(nproc)
  fi
  # guess at how long tests will take (hours)
  if [[ ${Nproc} -gt 8 ]]; then
    hdur=4
  elif [[ ${Nproc} -gt 4 ]]; then
    hdur=6
  else
    hdur=12
  fi
  if [[ $OSTYPE == 'darwin'* ]]; then
    stop_time=$(date -v +${hdur}H +%FT%T)
  else
    stop_time=$(date -d "+${hdur} hour" '+%FT%T')
  fi
else
  stop_time=""
fi

source ${cwd}/ci-prep.sh

site_name=$(uname -s)-$(uname -m)-$CC-$CXX-$FC

# run GemCI tests
${conda} \
  ctest \
  -Dexclude=3D \
  -DCMAKE_PREFIX_PATH:PATH=$prefix \
  -DCTEST_STOP_TIME=${stop_time} \
  -Dgemini3d_tag=main \
  -DGEMINI_CIROOT:PATH=$ci_data \
  -DCTEST_BINARY_DIRECTORY=$ci_bin \
  -DCTEST_SITE=$site_name \
  -DCTEST_MODEL=$1 \
  -Dduration=$2 \
  -Dcadence=$3 \
  -Dcpp:BOOL=$4 \
  -S $ci_code/gemci/ci.cmake
