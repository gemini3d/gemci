# CI

Gemini3D CI consists of several minutes to hours simulations that can run as a daily CI job on a powerful workstation or HPC.
While the CI tests in general take hours to run, particularly on a laptop, one may quickly (in a few minutes) check that the CI simulations setup by:

```sh
cmake --preset default
ctest --preset setup
```

The "hourly/mini*" tests are good for validating a workflow on a laptop or workstation in about a minute runtime each.

## Bounds checking

Typically the CI is run with Gemini3D having been built with `cmake -DCMAKE_BUILD_TYPE=Release`, which is the default if no build type has been specified.
Among other options, Release builds have compiler flag `-O3` or equivalent that make simulations runtimes several times faster than no optimizations. Even `-O2` is significantly slower.

Bounds checking is a basic runtime check that arrays are not being indexed outside their bounds.
This check is not perfect, but has in the past caught array indexing bugs.
We mitigate the slower runtimes by only running bounds checks with simulation "-dryrun" option that only runs the first time step of the simulation without file output.

The way this is implemented is to first build Gemini3D using Ninja Multi-Config, instead of the plain GNU Make or Ninja builds that are the default.
First, build Gemini3D with:

```sh
cd gemini3d/
cmake --preset multi
cmake --build --preset release
cmake --build --preset debug
```

It doesn't matter if you build release or debug first. The executables will be under:
gemini3d/build/Release/
gemini3d/build/Debug/

The GemCI CMake scripts know how to find these executables and use them appropriately.
A basic check is made to help ensure that bounds checking flags were enabled.

After doing the above Gemini3D Ninja Multi-Config build, come back to gemci/ and use a fresh build/ directory:

```sh
cmake --preset default
ctest --preset default -N
```

Notice the tests named "run_bounds_check:".
They should not have "(Disabled)" after the test name.
Those use the `-dryrun` option and bounds checking.

## Data directory

It is necessary to specify the data directory where the CI tests will be run.
This is accomplished by either/both:

* set environment variable GEMINI_CIROOT
* CMake configure option `cmake -DGEMINI_CIROOT=<path>`  (priority over environment variable)
