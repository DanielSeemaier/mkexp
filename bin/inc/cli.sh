mode="generate"
skip_install=0
init_filename="Default"

declare -A active_algorithms
while [[ $# -gt 0 ]]; do 
    case $1 in 
        --help)
            mode="help"
            shift
            ;;
            
        --results)
            mode="results"
            shift
            ;;
        --stats)
            mode="stats"
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
        --upload-self)
            mode="upload-self"
            shift
            ;;
        --download)
            mode="download"
            shift
            ;;
        --setup-system)
            mode="setup-system"
            shift
            ;;

        --init)
            mode="init"
            shift
            if [[ -f "$ROOT/examples/${1:-}" ]]; then
                init_filename="$1"
                shift
            fi
            ;;

        -*|--*)
            echo "Error: unknown option $1"
            exit 1
            ;;
    esac
done

if [[ $mode == "help" ]]; then
    echo "usage: mkexp [<command>]"
    echo ""
    echo "The standard workflow for mkexp works as follows:"
    echo ""
    echo "1. In an empty directory, call \`mkexp --init [type]\` to initialize a new experiment. This will create a single file called \`Experiment\`, which must be edited to configure the experiment."
    echo "2. Once configured, simply run \`mkexp\` to download and build the configured algorithms, as well as generate the jobfiles."
    echo "3. Run the generated \`./submit.sh\` script to run the experiment. This will usually happen in the background."
    echo "4. Once the experiment has finished, parse the log files by running \`mkexp --results\`. This will parse the log files and output *.csv files in the \`results/\` subdirectory."
    echo "5. On your local machine, you can then build a set of standard plots by running \`mkexp --plots\`. Alternative, you can build a subset of the plots by running \`mkplots <algorithms...>\`, where the algorithms... refer to files (without extension) in the \`results/\` directory."
    echo ""
    echo "While not required, we assume that experiments are generated in subdirectories of a Git repository (running \`mkexp\` will generate an appropriate .gitignore file)."
    echo ""
    echo "Available commands:"
    echo ""
    echo "- Initialization:"
    echo "   --init [$(ls $ROOT/examples | tr '\n' '|')]: initialize a new experiment"
    echo ""
    echo "- Setup:"
    echo "    (no command): download, build partitioners and generate jobfiles"
    echo "    --fetch: only download partitioners, but do not compile anything"
    echo "    --install-fetched: only build partitioners, but do not download them (i.e., run after --fetch)"
    echo "    --skip-install: regenerate jobfiles, but do not download or build anything"
    echo ""
    echo "- Post-processing:"
    echo "   --results: parse log files and generate *.csv files"
    echo "   --plot: generate standard performance profiles etc."
    echo ""
    echo "- Misc:"
    echo "   --help: print this help message"
    echo "   --clean: delete generated files, but keep the logs and result files"
    echo "   --purge: delete everything except for the Experiment file"
    echo ""
    echo "- SuperMUC options:"
    echo "   --upload: upload the experiments to a remote machine"
    echo "   --upload-self: upload the mkexp toolkit to a remote machine"
    echo "   --download: download results from a remove machine"
    echo ""
    echo "This framework supports running experiments on a machine without internet access."
    echo "To do so, configure the experiment on a machine with internet access, then run \`mkexp --fetch\`."
    echo "Afterwards, upload everything to the remote machine using \`mkexp --upload\`, and compile it there by running \`mkexp --install-fetched\`."
    echo "Once the experiments has finished, download the log files using \`mkexp --download\` and proceed as usual."
    exit 0
fi

