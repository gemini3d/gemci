# Gemini3D CI

[![ci](https://github.com/gemini3d/gemci/actions/workflows/ci.yml/badge.svg)](https://github.com/gemini3d/gemci/actions/workflows/ci.yml)

Gemini3D CI "GemCI" consists of several simulations that can run as a daily CI job on a powerful workstation or HPC.
The CI tests in general each take a few minutes to about an hour to run on a powerful computer.
It is possible to select subsets of tests to speedup testing.

As typical for CMake projects, there is a 3 step process: configure-build-test:

```sh
cmake --preset default

cmake --build --preset default

ctest --preset default
```

By default PyGemini is used to create simulation inputs and process simulation outputs.
Replacing the first command with

```sh
cmake --preset matlab
```

uses MatGemini instead of PyGemini.

[CDash](./doc/CDash.md) tracks automated or manual runs of GemCI.

To add a new simulation or re-generate reference data, refer to [this guide](./doc/RegenData.md).

## Gemini3D build

For robustness/repeatability, GemCI downloads and builds its own copy of Gemini3D.
The default Git tag/commit is in the top-level gemci/libraries.json.
The user may specify a custom Gemini3D Git tag/commit like:

```sh
cmake --preset default -Dgemini3d_tag=my_branch_or_tag_or_commit
```

Every time GemCI CMake reconfigures, it checks if there is an update to Gemini3D on gemini3d_tag.
If you make a change to Gemini3D that you want to test with GemCI, reconfigure before CTest like:

```sh
cmake --preset default

ctest --preset default
```

CTest ignores changes to CMake scripts and other projects.

## Data directory

It is necessary to specify the data directory where the CI tests will be run and reference data downloaded.
This is accomplished by either/both:

* set environment variable GEMINI_CIROOT
* CMake configure option `cmake -DGEMINI_CIROOT=<path>`  (priority over environment variable)

Note there can be over 20 GB of data, so ensure the hard drive has enough disk space.

### Offline HPC batch CTest

Note: some HPC systems only have internet when on a login node, but cannot run MPI simulations on the login node.
Batch sessions, including interactive, may be offline.
To run CTest in such an environment, download the data once from the login node:

```sh
ctest --preset download
```

then from an interactive batch session, run the tests:

```sh
ctest --preset offline
```

## Selecting tests

[CTest](https://cmake.org/cmake/help/latest/manual/ctest.1.html)
has a regex syntax to select tests.
Use `ctest -R` to select a subset of tests.
Note that CTest
[test fixtures](https://cmake.org/cmake/help/latest/prop_test/FIXTURES_REQUIRED.html)
are used to specify the hierarchy of tests.
Since there are hundreds of individual tests, learn about how the tests are organized by selecting one simulation and look at the JSON produced like:

```sh
ctest --preset default -R mini2dns_glow -N
```

The "-N" flag prints the test names that would run.
We use "-N" frequently to avoid wasting time running unwanted tests in interactive use.
Run the tests by omitting "-N".

To omit all tests automatically added by fixtures, add option `ctest -FA fxt`.
The "-FA" flag also uses regex--in GemCI we use the suffix "_fxt" on each fixture to allow for easy selection.

The "default" preset in CMakePresets.json does not run equilibrium simulations, as they take more than an hour each, and use the most basic features of Gemini.
To enable equilibrium simulations, run:

```sh
cmake --preset default -Dequil=on
```

For developers, the flag `ctest --show-only=json-v1` emits JSON test trace data revealing the dependencies between tests in detail.

### Example test selection

```sh
ctest --preset default -R mini2dns_glow -N
```

```
Test project gemci/build
  Test #51: setup:download_equilibrium:mini2dns_glow
  Test #52: setup:python:mini2dns_glow
  Test #53: compare:download:mini2dns_glow
  Test #54: compare:input:mini2dns_glow
  Test #55: read_grid:python:mini2dns_glow
  Test #56: run_bounds_check:mini2dns_glow
  Test #57: run:mini2dns_glow
  Test #58: compare:output:mini2dns_glow
  Test #59: plotdiff:output:mini2dns_glow
  Test #60: plot:python:mini2dns_glow

Total Tests: 10
```

To omit plotting, which can take nearly as long as the simulation itself:

```sh
ctest --preset default -R mini2dns_glow -E plot -N
```

```
Test project gemci/build
  Test #51: setup:download_equilibrium:mini2dns_glow
  Test #52: setup:python:mini2dns_glow
  Test #53: compare:download:mini2dns_glow
  Test #54: compare:input:mini2dns_glow
  Test #55: read_grid:python:mini2dns_glow
  Test #56: run_bounds_check:mini2dns_glow
  Test #57: run:mini2dns_glow
  Test #58: compare:output:mini2dns_glow

Total Tests: 8
```

## Bounds checking

Most Gemini3D users build with `cmake -DCMAKE_BUILD_TYPE=Release`, which is the Gemini3D default if no CMake build type has been specified.
Among other options, Release builds have compiler flag "-O3" or equivalent that make simulation runtimes several times faster than no optimizations.
Even "-O2" is significantly slower than "-O3".

Bounds checking is a basic runtime check that arrays are not being indexed outside their bounds.
This check is not perfect, but has in the past caught array indexing bugs.
We mitigate the slower runtimes by only running bounds checks with simulation "-dryrun" option that only runs the first time step of the simulation without file output.

The tests named "run_bounds_check:" are only present if "gemini3d.run.debug" is available with bounds checking enabled.
They should not have "(Disabled)" after the test name.
Those tests use the `-dryrun` option and bounds checking.

## Number of MPI processes

Normally we let Gemini3D determine the number of MPI processes to use.
For debugging, this can be manually overridden with -Dmpi_nprocs=<nprocs> argument like:

```sh
cmake -B build -Dmpi_nprocs=32
```

Then, each test will use that value instead of the automatically determined value.
This option can make tests fail if the simulation grid isn't evenly divisible in lat/lon by the number of MPI processes.

## Adding new tests

Many new tests use an existing equilibrium simulation to kickstart the new simulation with initial conditions.
Option `cmake -Dequil=false` is the default the CMake condition when configuring the build, which means that by default new simulations will not create a new equilibrium simulation.
If you are making a new equilibrium simulation, then add option `cmake-Dequil=true` when configuring the build.
Notice how `eq_dir` of config.nml is defined in an
[example](https://github.com/gemini3d/gemci/blob/main/cfg/hourly/mini2dns_glow/config.nml)
under `&setup / eq_dir = '@GEMINI_CIROOT@/mini2dns_eq'`
that means to look under env var `$GEMINI_CIROOT/mini2dns_eq`.
For a simulation, tell where the equilibrium data is similarly in the my_new/config.nml if `cmake -Dequil=false`.

* `-Dequil=true`: the Fortran simulation doesn't look for config.nml field `&setup / eq_dir` because it is creating a new equilibrium simulation.
* `-Dequil=false`: the Fortran simulation looks for config.nml field `&setup / eq_dir` to find the existing equilibrium simulation.

0. set an environment variable `GEMINI_CIROOT` in Terminal that points to an existing directory to store the multi-gigabyte simulation outputs.
1. Put the config.nml for the particular simulation under a new subdirectory with the desired simulation name under `gemci/cfg/{daily,equilibrium}`. For example "cfg/daily/my_new/config.nml".
2. Generate the new archive .zst that will be created under the directory defined in `GEMINI_CIROOT` environment variable. For clarity we set `-Dequil=false` even though it's the default - set `-Dequil=true` if you're making a new equilibrium simulation.

  ```sh
  cmake -Bbuild -Dpackage=true -Dequil=false

  cmake --build build

  ctest --test-dir build -R my_new -V
  ```

3. Compute the sha256 hash of the file that you need for the ref_data.json of the next step like

  ```sh
  cmake -E sha256sum my_new.zst
  ```

4. Upload this my_new.zst to the public data server e.g. Dropbox or university server.
5. Add this my_new simulation info to the ref_data.json that's at the URL given in [cmake/libraries.json](./cmake/libraries.json). The name of the simulation must match the directory under `cfg/{daily,hourly}` of this gemci/ repo - gemci/CMakeLists.txt scans all the given subdirectories. Look at the other sims in ref_data.json for how to define the sha256sum and url etc.
6. Finally, `git add` the file "my_new/config.nml" and `git commit` and `git push` from gemci/
