# Low-resolution, Comprehensive, Continuous Integration Tests

This document collects together tests of various use cases for GEMINI demonstrating a range of grids and solvers.  These can be useful reference cases to build off of or can be used to do comprehensive testing of a new deployment of GEMINI.  These tests are designed to all be runnable as a less than 24 hour batch job on one HPC node or reasonable workstation (~8+ cores).

These test cases are too long-running to be used on every Git push.
We choose to use CMake to orchestrate these tests as CMake is a common denominator for Gemini, and is easier and more robust for this type of task.
This task is within the main use cases of CMake, versus a data analysis language like Matlab or Python.

```sh
cd gemini-examples/

ctest -S ci.cmake -VV
```

The `-VV` is optional to show verbose test status in the terminal; it can be omitted.
The non-MPI tests run in parallel, while the MPI-based tests run one at a time to avoid oversubscribing the CPU.
The HWLOC library is used when available to maximum CPU usage for MPI-based tests.

These tests are intended to *supplement* (not replace) those already conducted as part of the automatic CI.  because these are too computationally expensive to run on every push they are optional but highly recommended for verification.

For each example there are sample commands showing how to run the example using ```mpirun``` on either a small workstation (4 cores) or a large workstation (16 cores).  MPI image splits can be adjusted accordingly to best leverage whatever system one runs from.  Each test description below also briefly describes the specific GEMINI features that the example in intended to test/verify.


# Test 

For each test documented below, we list:

* *Dimensionality*
* *Grid coordinate system*
* *Grid periodicity*
* *Grid size*
* *Grid motion*
* *Potential solver type*
* *Potential boundary conditions*
* *Precipitation boundary conditions*
* *Neutral perturbations*

to allow once to check specific integrated functionality for different combinations of solvers by choosing an appropriate (integration) test.  


##  arcs\_CI

* Simulation of an auroral arc
* Tests:
	* *Dimensionality* - 3D
	* *Grid coordinate system* - Cartesian
	* *Grid periodicity* - aperiodic
	* *Grid size* - 98 x 96 (nonuniform) x 96 (nonuniform)
	* *Grid motion* - Eulerian
	* *Potential solver type* - 2D field-integrated, Cartesian, noninertial
	* *Potential boundary conditions* - Neumann via source terms
	* *Precipitation boundary conditions* - auroral
	* *Neutral perturbations* - none
* corresponding eq simulation:  ./arcs_eq
* (future work) validation of currents using MATLAB scripts

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/arcs_CI -manual_grid 2 2
```

* runtime:  about 60 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/arcs_CI -manual_grid 4 4
```

* runtime:  ???

## arcs\_CI magnetic fields

* Calculates magnetic field perturbations after the arcs\_CI example has been completed.
* Tests:
	* magnetic field calculations for a 3D Cartesian grid
* (future work) Could also be further run using curl(H) script to validate magcalc...

*Small workstation run:*

```sh
mpirun -np 4 ./magcalc.bin ~/simulations/arcs_CI -manual_grid 2 2 -debug -start_time 2017 3 2 27270 -end_time 2017 3 2 27300
```

* runtime:  15 mins. (one time frame)

*Large workstation run:*

```sh
mpirun -np 16 ./magcalc.bin ~/simulations/arcs_CI -manual_grid 4 4 -debug -start_time 2017 3 2 27270 -end_time 2017 3 2 27300
```

* runtime:  ???


## GDI\_periodic\_lowres\_CI

* Simulation of gradient-drift instability
* Tests:
	* *Dimensionality* - 3D
	* *Grid coordinate system* - Cartesian
	* *Grid periodicity* - periodic in x3
	* *Grid size* - 34 x 184 (nonuniform) x 48
	* *Grid motion* - Lagrangian
	* *Potential solver type* - 2D field integrated, Cartesian, inertial
	* *Potential boundary conditions* - Neumann
	* *Precipitation boundary conditions* - minimal, background
	* *Neutral perturbations* - none
* corresponding eq simulation:  ./GDIKHI_eq
* tests Lagrangian mesh features

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/GDI_CI -manual_grid 2 2
```

* runtime:  25 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/GDI_CI -manual_grid 4 4
```

* runtime:  ???

Testing restart with GDI example:


## Restarting GDI\_periodic\_lowres\_CI

* The prior simulation may also be used to test the restart code for 3D simulations.  There is a milestone on the 6th (of 8th output).  By making a copy of the output and deleting the 7-8th outputs the same command can be run again to produce a restarted 7,8th output.
* These restarted outputs should be compared against the output when the restart was not used to demonstrate consistency.


## KHI\_periodic\_lowres\_CI

* Simulation of Kelvin-Helmholtz instability
* Tests:
	* *Dimensionality* - 3D
	* *Grid coordinate system* - Cartesian
	* *Grid periodicity* - periodic in x3
	* *Grid size* - 34 x 256 (nonuniform) x 128
	* *Grid motion* - Eulerian
	* *Potential solver type* - 2D, field integrated, Cartesian, inertial
	* *Potential boundary conditions* - Neumann via source terms, specified Dirichlet in x2
	* *Precipitation boundary conditions* - minimal, background
	* *Neutral perturbations* - none
* corresponding eq simulation:  ./GDIKHI_eq

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/KHI_CI -manual_grid 2 2
```

* runtime:  80 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/KHI_CI -manual_grid 4 4
```

* runtime:  ???


## tohoku20113D\_lowres\_3Dneu\_CI

* 3D dipole simulation with 3D neutral perturbation input.
* Tests:
	* *Dimensionality* - 3D
	* *Grid coordinate system* - closed dipole
	* *Grid periodicity* - aperiodic
	* *Grid size* - 512 x 128 x 48
	* *Grid motion* - Eulerian
	* *Potential solver type* - 2D field-integrated, Dipole, noninertial
	* *Potential boundary conditions* - Neumann with neutral source terms
	* *Precipitation boundary conditions* - none
	* *Neutral perturbations* - 3D Cartesian
* corresponding eq simulation:  ./tohoku20113D_eq

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/tohoku20113D_lowres_3Dneu_CI -manual_grid 2 2
```

* runtime:  240 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/tohoku20113D_lowres_3Dneu_CI -manual_grid 4 4
```

* runtime:  ???


## tohoku20113D\_lowres\_axineu\_CI

* 3D dipole simulation with 2D axisymmetric perturbation input.
* Tests:
	* *Dimensionality* - 3D
	* *Grid coordinate system* - closed dipole
	* *Grid periodicity* - aperiodic
	* *Grid size* - 512 x 128 x 48
	* *Grid motion* - Eulerian
	* *Potential solver type* - 2D field-integrated, Dipole, noninertial
	* *Potential boundary conditions* - Neumann with neutral source terms
	* *Precipitation boundary conditions* - none
	* *Neutral perturbations* - 2D axisymmetric
* corresponding eq simulation:  ./tohoku20113D_eq

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/tohoku20113D_lowres_axineu_CI -manual_grid 2 2
```

* runtime:  240 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/tohoku20113D_lowres_axineu_CI -manual_grid 4 4
```

* runtime:  ???


## tohoku20112D\_medres\_axineu\_CI

* 2D Dipole grid simulation using axisymmetric neutral perturbations as input.
* 	Tests:
	* *Dimensionality* - 2D
	* *Grid coordinate system* - closed dipole
	* *Grid periodicity* - aperiodic
	* *Grid size* - 512 x 512 x 1
	* *Grid motion* - Eulerian
	* *Potential solver type* - 2D field-resolved, dipole
	* *Potential boundary conditions* - Neumann
	* *Precipitation boundary conditions* - none
	* *Neutral perturbations* - 2D axisymmetric
* corresponding eq simulation:  ./tohoku20112D_eq
* grid size:  512 x 512 x 1

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/tohoku20112D_medres_axineu_CI
```

* runtime:  45 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/tohoku20112D_medres_axineu_CI
```

* runtime:  ???


## Restarting tohoku20112D\_medres\_axineu\_CI

* The prior simulation may also be used to test the restart code for 2D simulations with neutral inputs.  There is a milestone on the 10th output.  By making a copy of the output and deleting the remaining outputs the same command can be run again to produce a restarted version of the calculations.
* These restarted outputs should be compared against the output when the restart was not used to demonstrate consistency.  These comparisons can be restricted to the frames after the restart was conducted.


## tohoku20112D\_medres\_2Dneu\_CI

* 2D Dipole grid simulation using 2D Cartesian neutral perturbations as input.
* Tests:
	* *Dimensionality* - 2D
	* *Grid coordinate system* - closed dipole
	* *Grid periodicity* - aperiodic
	* *Grid size* - 512 x 512 x 1
	* *Grid motion* - Eulerian
	* *Potential solver type* - 2D field-resolved, dipole
	* *Potential boundary conditions* - Neumann
	* *Precipitation boundary conditions* - none
	* *Neutral perturbations* - 2D Cartesian
* corresponding eq simulation:  ./tohoku20112D_eq

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/tohoku20112D_medres_2Dneu_CI
```

* runtime:  45 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/tohoku20112D_medres_2Dneu_CI
```

* runtime:  ???


## cusp\_softprecip3D\_CI

* 3D open dipole simulation with particle flux and FAC inputs
* Tests:
	* *Dimensionality* - 3D
	* *Grid coordinate system* - open dipole
	* *Grid periodicity* - aperiodic
	* *Grid size* - 160 x 120 x 64
	* *Grid motion* - Eulerian
	* *Potential solver type* - 2D field integrated, dipole, noninertial
	* *Potential boundary conditions* - Neumann via source terms
	* *Precipitation boundary conditions* - auroral
	* *Neutral perturbations* - none
* corresponding eq simulation:  ./cusp3D_eq

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/cusp_softprecip -manual_grid 2 2
```

* runtime:  60 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/cusp_softprecip -manual_grid 4 4
```

* runtime:  ???


## cusp\_softprecip2D\_Dirich\_CI

* 2D open dipole simulation with particle flux and potential boudary condition inputs (Dirichlet problem)
	* *Dimensionality* - 2D
	* *Grid coordinate system* - open dipole
	* *Grid periodicity* - aperiodic
	* *Grid size* - 160 x 128 x 1
	* *Grid motion* - Eulerian
	* *Potential solver type* - 2D field resolved, noninertial
	* *Potential boundary conditions* - Dirichlet
	* *Precipitation boundary conditions* - auroral
	* *Neutral perturbations* - none
* corresponding eq simulation:  ./cusp2D_eq

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/cusp_softprecip -manual_grid
```

* runtime:  15 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/cusp_softprecip -manual_grid
```

* runtime:  ???


## cusp\_softprecip2D\_Neu\_CI

* 3D open dipole simulation with particle flux and FAC boundary inputs (Nuemann problem)
* Tests:
	* *Dimensionality* - 2D
	* *Grid coordinate system* - open dipole
	* *Grid periodicity* - aperiodic
	* *Grid size* - 160 x 128 x 1
	* *Grid motion* - Eulerian
	* *Potential solver type* - 2D field resolved, noninertial
	* *Potential boundary conditions* - Neumann
	* *Precipitation boundary conditions* - auroral
	* *Neutral perturbations* - none
* corresponding eq simulation:  ./cusp2D_eq
* grid size:  160 x 128 x 1

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/cusp_softprecip -manual_grid
```

* runtime:  15 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/cusp_softprecip -manual_grid
```

* runtime:  ???


# Planned Capabilities and Associated Tests

Future extension to GEMINI will also require further tests to insure the code is deployed successfully.

## cusp\_softprecip3D\_glow

* 3D open dipole simulation with particle flux input
* corresponding eq simulation:  ./cusp3D_eq
* tests field-resolved 2D potential solver with neutral inputs (2D Cartesian)
* grid size:  192 x 132 x 64
* non-finite output values for integrated volume emission rate...  Probably need to flip arrays back and forth to deal with curvilinear grid?  Could be a quick fix worth trying soon...  May also need to set inclination angle somewhere, as well.

*Small workstation run:*

```sh
mpirun -np 4 ./gemini.bin ~/simulations/cusp_softprecip -manual_grid 2 2
```

* runtime:  60 mins.

*Large workstation run:*

```sh
mpirun -np 16 ./gemini.bin ~/simulations/cusp_softprecip -manual_grid 4 4
```

* runtime:  ???



## Time-dependent precipitation and fields???  ISINGLASS???

## Equatorial Plasma Bubble example


