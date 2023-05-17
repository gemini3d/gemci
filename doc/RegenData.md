# Regenerate Gemini3D reference data

This is done occasionally by development team.
It takes about 12 hours to run all the simulations on a powerful workstation or HPC.
We recommend using PyGemini for this `pip install pygemini`.
If neither PyGemini or MatGemini are available, the regeneration will use previously generated reference input, which is *not* a clean regeneration of the reference data.
It's preferable to have PyGemini working before regenerating the reference data.

Set environment variable `GEMINI_CIROOT` to a fresh directory--this is where the regenerated data will be put.
Configure GemCI in a fresh build directory.
To serve as a CI, Gemini3D is rebuilt each time if change occurs in Gemini3D repo.

To specify a specific Git branch/commit/tag for Gemini3D, instead use the multi-step process below.

```sh
cmake --preset regen -Dgemini3d_tag=my_branch_or_tag_or_commit

cmake --build build

ctest --preset regen
```

By default, the "--preset regen" turns on the equilibrium simulations, which take much longer to run than the normal simulations.
If you have known good equilibrium data, you can skip the equilibrium regeneration by:

```sh
cmake --preset regen -Dequil=off
```

Note: to specify a subset of simulations to regenerate (potentially saving hours of time) use the "-R" ctest regex option like:

```sh
ctest --preset regen -R "KHI"
```

Uploading the reference data for public use can be manually done from the GEMINI_CIROOT directory.
Optionally, if the program
[rclone](https://rclone.org/)
is present and has been configured by the user for the appropriate file sharing service, CTest will automatically upload the reference data to the cloud storage.
The final step would be visually checking that the URLs in "ref_data.json" are correct and "git commit" the new ref_data.json in gemci/.
