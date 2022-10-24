#!/usr/bin/env bash

set -o nounset

gemext_dir=$HOME/code/gemext
pygemini_dir=$HOME/code/pygemini

# build libraries
[[ git -C $gemext_dir pull --rebase ]] || { echo "gemext git pull failed"; exit 1; }
[[ git -C $pygemini_dir pull --rebase ]] || { echo "pygemini git pull failed"; exit 1; }

if cmake -Dbindir=$gemext_bin -Dprefix=$prefix -P $gemext_dir/scripts/online_install.cmake; then
  :
else
  rm -rf $gemext_bin
  [[ cmake -Dbindir=$gemext_bin -Dprefix=$prefix -P $gemext_dir/scripts/online_install.cmake ]] || { echo "gemext cmake failed"; exit 1; }
fi

# install / update PyGemini
if conda run python -m gemini3d; then
  :
else
  conda run python -m pip --quiet install -e $pygemini_dir
  [[ conda run python -m gemini3d ]] || { echo "PyGemini install failed"; exit 1; }
fi
