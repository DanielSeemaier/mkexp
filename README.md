# Experiment Framework for (Distributed) Graph Partitioners

0. Add `./bin/` to `$PATH`
1. Run `mkexp --init` in a fresh directory. This creates a file `Experiment`
2. Edit the file to setup your experiment.
3. Run `mkexp [--local]` to download and compile the partitioners required to run the experiment and generate the jobfiles.
   Per default, partitioners are only installed once and shared between experiments. To install them to a unique directory, use the `--local` flag.
4. Run `mkexp --submit` to start the experiment (submit the jobfiles)
5. Once the experiment was executed, run `mkexp --results` to generate standardized CSV files containing the results. 
   Then, run `mkexp --plots` to generate performance profiles based on the results (required `R` with some packages preinstalled).

## Extending the Framework

To add a new partitioner, create a new file in `partitioners/`. This file contains instructions to download / compile / install the partitioner and invoke it.
Additionally, create a new AWK script in `parsers/` with the same name that parses the logfiles and generates CSV output.
