MKEXP_MODE_HELP="help"
MKEXP_MODE_RESULTS="results"
MKEXP_MODE_CLEAN="clean"
MKEXP_MODE_PURGE="purge"
MKEXP_MODE_INSTALL="install"
MKEXP_MODE_GENERATE="generate"
MKEXP_MODE_INIT="init"

mkexp_mode="$MKEXP_MODE_INSTALL+$MKEXP_MODE_GENERATE"
mkexp_init_preset="Default"
mkexp_results_parser=""

while [[ $# -gt 0 ]]; do 
    case $1 in 
        help)
            mkexp_mode="$MKEXP_MODE_HELP"
            shift
            ;;
            
        results)
            mkexp_mode="$MKEXP_MODE_RESULTS"
            shift
            if [[ $# -gt 0 ]]; then
                mkexp_results_parser=${1:-}
                shift
            fi
            ;;

        clean)
            mkexp_mode="$MKEXP_MODE_CLEAN"
            shift 
            ;;

        purge)
            mkexp_mode="$MKEXP_MODE_PURGE"
            shift
            ;;

        install)
            mkexp_mode="$MKEXP_MODE_INSTALL"
            shift 
            ;;

        generate)
            mkexp_mode="$MKEXP_MODE_GENERATE"
            shift
            ;;

        init)
            mkexp_mode="init"
            shift
            if [[ -f "$MKEXP_HOME/presets/${1:-}" ]]; then
                mkexp_init_preset="$1"
                shift
            fi
            ;;

        *)
            echo "Error: unknown option $1"
            exit 1
            ;;
    esac
done

if [[ $mkexp_mode == *"$MKEXP_MODE_HELP"* ]]; then
    echo "Usage: mkexp [init|install|generate|results|clean|purge|help]"
    exit 0
fi

