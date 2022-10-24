# Cron CI scripts

These scripts are for a Unix-like system (Linux, MacOS, WSL) especially for Cron jobs, but can be run manually.

```sh
crontab -e
```

## Nightly crontab

Assuming CI runs in under 4 hours, this says:

* midnight Sunday, Tuesday, Thursday, Saturday: run C++ frontend GNU
* 4am Sunday, Tuesday, Thursday, Saturday: run C++ frontend Intel oneAPI
* midnight Monday, Wednesday, Friday: run Fortran frontend GNU
* 4am Monday, Wednesday, Friday: run Fortran frontend Intel oneAPI

```sh
0 0 * * 0,2,4,6 $HOME/code/gemci/scripts/ci-gnu.sh Nightly 0 0 1
0 4 * * 0,2,4,6 $HOME/code/gemci/scripts/ci-oneapi.sh Nightly 0 0 1
0 0 * * 1,3,5 $HOME/code/gemci/scripts/ci-gnu.sh Nightly 0 0 0
0 4 * * 1,3,5 $HOME/code/gemci/scripts/ci-oneapi.sh Nightly 0 0 0
```

## Continuous crontab

This polls for duration 54000 seconds (15 hours) with cadence 900 seconds (15 minutes) for Git changes, and runs CI if changes detected.

Here, we start at 8am and poll until 11pm.

* Sunday, Tuesday, ...: C++ GNU frontend
* Monday, Wednesday, ...: Fortran GNU frontend

```sh
0 8 * * 0,2,4,6 $HOME/code/gemci/scripts/ci-gnu.sh Continuous 54000 900 1
0 8 * * 1,3,5 $HOME/code/gemci/scripts/ci-gnu.sh Continuous 54000 900 0
```
