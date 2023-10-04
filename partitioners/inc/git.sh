# Clone a GIT repository and checkout the specified version
GenericGitFetch() {
    local -n generic_git_fetch_args=$1
    local url=$2
    local src_dir_key=$3

    src_dir="${generic_git_fetch_args[$src_dir_key]}"
    if [[ ! -d "$src_dir" ]]; then
        mkdir -p "$src_dir"
        echo -e "Directory '$src_dir' for algorithm '$ALGO_COLOR${generic_git_fetch_args[algorithm]}$NO_COLOR' does not exist: initialize from a remote Git repository"
        echo "Cloning Git repository '$url' to directory '$src_dir'"
        echo ""

        Prefixed git clone "$url" "$src_dir"
        Prefixed git -C "$src_dir" submodule update --init --recursive
    else
        echo -e "Directory '$src_dir' for algorithm '$ALGO_COLOR${generic_git_fetch_args[algorithm]}$NO_COLOR' does already exist: update from a remote Git repository"
        echo ""

        Prefixed git -C "$src_dir" fetch origin
        Prefixed git -C "$src_dir" submodule update
    fi

    if [[ "${generic_git_fetch_args[algorithm_version]}" != "latest" ]]; then 
        echo -e "Specific version specified for algorithm '$ALGO_COLOR${generic_git_fetch_args[algorithm]}$NO_COLOR': checkout '$ARGS_COLOR${generic_git_fetch_args[algorithm_version]}$NO_COLOR'"
        echo ""

        Prefixed git -C "$src_dir" reset --hard "${generic_git_fetch_args[algorithm_version]}"
    else
        echo -e "No version specified for algorithm '$ALGO_COLOR${generic_git_fetch_args[algorithm]}$NO_COLOR': update to latest commit"
        echo ""

        Prefixed git -C "$src_dir" pull origin
    fi
}

GenericGitReportVersion() {
    local -n generic_report_version_args=$1
    echo -n "disk:"
    if [[ -d "${generic_report_version_args[disk_driver_src]}" ]]; then
        echo -n $(git -C "${generic_report_version_args[disk_driver_src]}" rev-parse HEAD)
    fi
    echo -n ";kagen:"
    if [[ -d "${generic_report_version_args[kagen_driver_src]}" ]]; then
        echo -n $(git -C "${generic_report_version_args[kagen_driver_src]}" rev-parse HEAD)
    fi
    echo -n ";generic:"
    if [[ -d "${generic_report_version_args[generic_kagen_driver_src]}" ]]; then
        echo -n $(git -C "${generic_report_version_args[generic_kagen_driver_src]}" rev-parse HEAD)
    fi
}
