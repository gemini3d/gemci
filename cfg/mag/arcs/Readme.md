# ARCS magnetic field

We set in config.nml

```
&Jpar
flagJpar=.true.
/
```

to enable gemini.bin computing of currents. After gemini.bin runs, we run MatGemini gemini3d.model.magcalc() and then magcalc.bin.

## Run

Assuming Gemini3d is already built.

Ensure environment variable MATLABPATH includes the path to MatGemini, like:

```sh
export MATLABPATH=~/code/mat_gemini/:~/code/mat_gemini/matlab-stdlib/
```

Setup and run simulation

```sh
# a limitation of Matlab is that user setup functions must be on the Matlab path or current working directory

cd gemci/cfg/mag/arcs

matlab -batch "gemini3d.run('.', '~/sims/arcs_mag')"
```

This gemini3d.run takes about 8 minutes with 32 CPU cores.

Generate the magcalc grid, which in general is distinct from the Gemini3d simulation grid as desired by the user.

```sh
matlab -batch "gemini3d.model.magcalc('~/sims/arcs_mag')"
```

finally, simulate the magnetic field by running the executable:

```sh
gemini3d/build/magcalc.run ~/sims/arcs_mag
```

Then plot the output.
