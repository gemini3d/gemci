# ARCS magnetic field

We set in config.nml

```
&Jpar
flagJpar=.true.
/
```

to enable gemini.bin computing of currents. After gemini.bin runs, we run MatGemini gemini3d.model.magcalc() and then magcalc.bin.
