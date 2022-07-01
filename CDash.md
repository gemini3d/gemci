# CDash GemCI

A Unix-like workstation (e.g. Linux, MacOS) can be used in general as a CDash CI client by using a crontab schedule for periodic runs e.g. daily.
These results are published to the public
[GemCI CDash](https://my.cdash.org/index.php?subproject=python&project=GemCI).
Implicit in running the CDash CTest client commands in this document are that some system details like compiler version are pushed to the public internet.

## CTest CDash run

To do a quick CDash CI run from a computer (takes 2 hours on a 64-core workstation) do like:

```sh
ctest -S ci.cmake -V
```

Options one may wish to use include:

`-Dgemini3d_tag=`
: set to Gemini3D Git branch, tag, or commit hash (default "main" branch)

`-Dcpp=`
: "true" to use C++ Gemini3d frontent, "false" to use Fortran Gemini3d front-end (default false)

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

A typical CI system uses:

* Python with PyGemini installed
* Gemini3D and external libraries install-prefix ~/lib_gcc

Specify CONDA_PREFIX as auto-enabled "conda activate" doesn't propagate to crontab.
We use example home directory "/home/ci".

These examples use multiple daily runs spaced far enough apart in time so that the cron jobs shouldn't run simultaneously.

These example crontab were created by examining the user PATH `echo $PATH` and including other key environment variables at the top of crontab.

### Linux crontab

* CMake Snap under /var/lib/snapd/snap/bin
* seperate big hard drive for CI data at path /mnt/raid/ci
* C++ test starts at 00:10 local time, Fortran test starts at 04:10 local time (each run takes about 2.5 hours on this 32-core Xeon machine)

```sh
PATH=/home/ci/miniconda3/bin:/home/ci/miniconda3/condabin:/var/lib/snapd/snap/bin:/usr/share/Modules/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
CONDA_PREFIX=/home/ci/miniconda3
MPI_ROOT=/usr/lib64/openmpi
GEMINI_CIROOT=/mnt/raid/ci_data
CMAKE_PREFIX_PATH=/home/ci/lib_gcc
CI=true
CTEST_SITE=LinuxCI

10 00 * * * ctest -Dgemini3d_tag=fclaw_prep3_geogdneu -Dcpp:BOOL=yes -DCTEST_MODEL=Nightly -S $HOME/code/gemci/ci.cmake -V
10 04 * * * ctest -Dgemini3d_tag=fclaw_prep3_geogdneu -Dcpp:BOOL=no -DCTEST_MODEL=Nightly -S $HOME/code/gemci/ci.cmake -V
```

### MacOS crontab

* Homebrew Gfortran + AppleClang C/C++ compilers
* C++ test starts at 00:10 local time, Fortran test starts at 08:10 local time (each run takes about 5 hours on Apple Silicon M1)

```sh
PATH=/opt/homebrew/sbin:/opt/homebrew/bin:/Users/ci/miniconda3/condabin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin
CONDA_PREFIX=/Users/ci/miniconda3
GEMINI_CIROOT=/Users/ci/ci_data
CMAKE_PREFIX_PATH=/Users/ci/lib_gcc
CI=true
CTEST_SITE=MacCI

10 00 * * * ctest -Dgemini3d_tag=fclaw_prep3_geogdneu -Dcpp:BOOL=yes -DCTEST_MODEL=Nightly -S $HOME/code/gemci/ci.cmake -V
10 08 * * * ctest -Dgemini3d_tag=fclaw_prep3_geogdneu -Dcpp:BOOL=no -DCTEST_MODEL=Nightly -S $HOME/code/gemci/ci.cmake -V
```
