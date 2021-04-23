# CI

Gemini3D CI consists of several minutes to hours simulations that can run as a daily CI job on a powerful workstation or HPC.
While the CI tests in general take hours to run, particularly on a laptop, one may quickly (in a few minutes) check that the CI simulations setup by:

```sh
cmake --preset ninja
ctest --preset setup
```
