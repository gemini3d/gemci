# CI

Gemini3D CI consists of several minutes to hours simulations that can run as a daily CI job on a powerful workstation or HPC.
While the CI tests in general take hours to run, particularly on a laptop, one may quickly (in a few minutes) check that the CI simulations setup by:

```sh
cmake --preset default
ctest --preset setup
```

The "hourly/mini*" tests are good for validating a workflow on a laptop or workstation in about a minute runtime each.
