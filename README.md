# `mkexp`

Quickstart: 

1. Clone this repository and add the `bin/` subdirectory to your `$PATH` variable.
2. In an empty directory, run `mkexp --init` to initialize a new experiment.
3. Modify the `Experiment` file to configure your experiment.
4. Run `mkexp` to download and build the configured graph partitioners, and generate bash scripts to invoke them.
5. Run `./submit.sh` to start the experiment. 
6. Once completed, run `mkexp --results` to parse the produced log files, then run `mkexp --plots` to generate some standard plots visualizing your results.

