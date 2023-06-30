# Experiment Framework for (Distributed) Graph Partitioners

0. Add `bin/` to your `$PATH` variable.
1. Run `mkexp --init` in a fresh directory. This creates a file `Experiment`.
2. Edit the file to setup your experiment.
3. Run `mkexp` once. This will download and compile the required partitioners and generate the jobfiles.
4. Run `./submit.sh` to start the experiment. Use `mkexp --progress` to query its progress.
5. Once the experiment has finished, run `mkexp --results` to generate standardized CSV files containing the results. 
6. Run `mkexp --plots` to generate performance profiles, running time boxplots as well as per-instance running time and cut plots.
   This requires `R` with some packages preinstalled.

## Extending the Framework

To add a new partitioner, create a new file in `partitioners/`. This file contains instructions to download / compile / install the partitioner and invoke it.
Additionally, create a new AWK script in `parsers/` with the same name that parses the logfiles and generates CSV output.
