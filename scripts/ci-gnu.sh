#!/usr/bin/env bash

set -e
set -o nounset

wd=/tmp

gemext_bin=$wd/build_gemext_gnu
ci_bin=$wd/build_gemci_gnu
prefix=$wd/libgem_gnu
ci_data=$HOME/ci_data

source ci-prep.sh

site_name=$(uname -s)-$(uname -m)-GNU

# run GemCI tests
conda run \
  ctest \
  -Dexclude=3D \
  -DCMAKE_PREFIX_PATH:PATH=$prefix \
  -Dgemini3d_tag=main \
  -DGEMINI_CIROOT:PATH=$ci_data \
  -DCTEST_BINARY_DIRECTORY=$ci_bin \
  -DCTEST_SITE=$site_name \
  -DCTEST_MODEL=$1 \
  -Dduration=$2 \
  -Dcadence=$3 \
  -Dcpp:BOOL=$4 \
  -S $HOME/code/gemci/ci.cmake
