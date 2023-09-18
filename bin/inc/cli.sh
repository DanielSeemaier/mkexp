mode="generate"
skip_install=0

declare -A active_algorithms
while [[ $# -gt 0 ]]; do 
    case $1 in 
        --results)
            mode="results"
            shift
            ;;
        --plots)
            mode="plots"
            shift 
            ;;
        --clean)
            mode="clean"
            shift 
            ;;
        --purge)
            mode="purge"
            shift
            ;;
        --stats)
            mode="stats"
            shift
            ;;
        --help)
            mode="help"
            shift
            ;;
        --submit)
            mode="submit"
            shift
            ;;
        --install)
            mode="install"
            shift 
            ;;
        --install-fetched)
            mode="install-fetched"
            shift
            ;;
        --skip-install)
            skip_install=1
            shift
            ;;
        --fetch)
            mode="fetch"
            shift
            ;;
        --upload)
            mode="upload"
            shift
            ;;
        --download)
            mode="download"
            shift
            ;;
        --init)
            mode="init"
            shift 
            ;;
        --progress)
            mode="progress"
            shift 
            ;;
        -*|--*)
            echo "Error: unknown option $1"
            exit 1
            ;;
    esac
done

if [[ $mode == "help" ]]; then 
    echo "Usage: call from within a directory containing a file named 'Experiment'"
    echo ""
    echo "The standard workflow is as follows:"
    echo "0. Add the bin/ directory to your PATH variable."
    echo "1. Create a new directory which will contain everything related to the experiment. In that directory, run \`mkexp --init\` to create the Experiment file."
    echo "2. Modify the Experiment file to configure your experiment. Once configured, run \`mkexp\` to build dependencies, partitioners and generate the jobfiles."
    echo "3. Run \`./submit.sh\` to execute the experiment. This will usually happen in the background."
    echo "4. Once the experiment has finished, parse the log files by running \`mkexp --results\`. On a system with R installed, you can generate some standard plots by running \`mkexp --plots\` afterwards."
    echo ""
    echo "mkexp [--init, --submit, --fetch, --install-fetched, --skip-install, --results, --plot, --clean, --purge, --stats, --upload, --download, --help]"
    echo ""
    echo "Without any options, generate the jobfiles and directory structure to run the experiment."
    echo "If not all algorithms should be included in the job files, specify a subset of defined algorithms as positional arguments"
    echo ""
    echo "Options are:"
    echo "    --init: Initialize a new experiment"
    echo "    --submit: Start the experiment"
    echo "    --fetch: Download libraries and partitioners, but do not build them yet"
    echo "    --install-fetched: Build and install libraries and partitioners that were already fetched, i.e., run this after running --fetched"
    echo "    --skip-install: Regenerate jobfiles, but do not recompile the partitioners"
    echo "    --results: Parse log files and output CSV files"
    echo "    --plot:  Generate performance- and running time plots from the CSV files"
    echo "    --clean: Delete generated experiment files"
    echo "    --purge: --clean, but also delete log and result files"
    echo "    --stats: Compute some statistics from the CSV files"
    echo "    --upload: Upload the experiments to a remote machine"
    echo "    --download: Download results from a remove machine"
    echo "    --help: Print this help message"
    echo ""
    echo "This framework supports running experiments on a machine without internet access."
    echo "To do so, configure the experiment on a machine with internet access, then run \`mkexp --fetch\`."
    echo "Afterwards, upload everything to the remote machine using \`mkexp --upload\`, and compile it there by running \`mkexp --install-fetched\`."
    echo "Once the experiments has finished, download the log files using \`mkexp --download\` and proceed as normal."
    exit 0
fi

