# CDash GemCI

A Unix-like workstation (e.g. Linux, MacOS) can be used in general as a CDash CI client by using a crontab schedule for periodic runs e.g. daily.

## crontab basics

Print the current crontab by:

```sh
crontab -l
```

Edit the current crontab by:

```sh
crontab -e
```

The crontab environment has virtually nothing specified by default.
Crontab environment variables are specified at the top of the crontab.
**Crontab environment variable must specify fully resolved absolute paths**.
"~" or "$HOME" do NOT work in crontab environment variables in general.

## Example crontab for GemCI

This system uses:

* Miniconda Python under ~/miniconda3
* CMake Snap under /var/lib/snapd/snap/bin
* Gemini3d/external libraries install-prefix ~/lib_gcc
* CTEST_SITE name of MyCI

We must specify CONDA_PREFIX as even auto-enabled "conda activate" doesn't propagate to crontab.

```sh
PATH=/home/ci/miniconda3/bin:/home/ci/miniconda3/condabin:/var/lib/snapd/snap/bin:/usr/share/Modules/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
CONDA_PREFIX=/home/ci/miniconda3
MPI_ROOT=/usr/lib64/openmpi
GEMINI_CIROOT=/mnt/raid/ci
CMAKE_PREFIX_PATH=/home/ci/lib_gcc
CI=true
CTEST_SITE=MyCI
49 10 * * * ctest -Dgemini3d_tag=fclaw_prep3_geogdneu -Dcpp:BOOL=yes -DCTEST_MODEL=Nightly -S $HOME/code/gemci/ci.cmake -V
10 04 * * * ctest -Dgemini3d_tag=fclaw_prep3_geogdneu -Dcpp:BOOL=no -DCTEST_MODEL=Nightly -S $HOME/code/gemci/ci.cmake -V
```
