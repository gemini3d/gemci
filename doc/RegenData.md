# Regenerate Gemini3D reference data

This is done occasionally by development team.
It takes about 12 hours to run all the simulations on a powerful workstation or HPC.
We recommend using PyGemini for this `pip install pygemini`.
If neither PyGemini or MatGemini are available, the regeneration will use previously generated reference input, which is *not* a clean regeneration of the reference data.
It's preferable to have PyGemini working before regenerating the reference data.

1. set environment variable GEMINI_CIROOT to a fresh directory, or erase all the existing files/folders there.
2. Configure GemCI in a fresh build directory. To serve as a CI, Gemini3D is rebuilt each time if change occurs in Gemini3D repo. To specify a specific Git branch/commit/tag for Gemini3D, add option below: `-Dgemini3d_tag=my_branch_or_tag_or_commit`

    ```sh
    cmake --preset regen
    ```
3. Build Gemini3D:

    ```sh
    cmake --build build
    ```
4. Run the tests, which regenerates data in the GEMINI_CIROOT directory:

    ```sh
    ctest --preset regen
    ```

Uploading the reference data for public use can be manually done from the GEMINI_CIROOT directory.
Optionally, if the program
[rclone](https://rclone.org/)
is present and has been configured by the user for the appropriate file sharing service, CTest will automatically upload the reference data to the cloud storage.
The final step would be visually checking that the URLs in "ref_data.json" are correct and "git commit" the new ref_data.json in gemci/.
