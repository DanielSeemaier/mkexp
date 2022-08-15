# Experiment Framework for (Distributed) Graph Partitioners

1. `git submodule update --init --recursive`
2. `source env.sh`
3. `cp -r experiments/example/ experiments/<your-experiment>/`
4. Setup the experiment by editing `experiments/<your-experiment>/Experiment`
5. Run `MakeExperiment` while in `experiments/<your-experiment>/`
6. Start the experiment by running `./submit.sh`
7. After execution is complete, run `MakeExperiment --parse` to parse log files to CSV files
8. Run `MakeExperiment --plot` and/or `Make-Experiment --stats` to generate performance profiles, running time plots and basic statistics

