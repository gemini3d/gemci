#!/usr/bin/env bash

set -e
set -o nounset

gemext_dir=$ci_code/gemext
pygemini_dir=$ci_code/pygemini

# build libraries
if git -C $gemext_dir pull --rebase; then
  :
else
  echo "gemext git pull failed"
  exit 1
fi

if git -C $pygemini_dir pull --rebase; then
  :
else
  echo "pygemini git pull failed"
  exit 1
fi

if cmake -Dbindir=$gemext_bin -Dprefix=$prefix -P $gemext_dir/scripts/online_install.cmake; then
  :
else
  rm -rf $gemext_bin
  if cmake -Dbindir=$gemext_bin -Dprefix=$prefix -P $gemext_dir/scripts/online_install.cmake; then
    :
  else
    echo "gemext cmake failed"
    exit 1
  fi
fi

# install / update PyGemini
if conda run python -m gemini3d; then
  :
else
  conda run python -m pip --quiet install -e $pygemini_dir
  if conda run python -m gemini3d; then
    :
  else
    echo "PyGemini install failed"
    exit 1
  fi
fi
