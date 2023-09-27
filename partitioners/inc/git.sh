# Clone a GIT repository and checkout the specified version
GenericGitFetch() {
    local -n generic_git_fetch_args=$1
    local url=$2
    local src_dir_key=$3

    src_dir="${generic_git_fetch_args[$src_dir_key]}"
    if [[ ! -d "$src_dir" ]]; then
        mkdir -p "$src_dir"
        echo "Directory '$src_dir' for algorithm '${generic_git_fetch_args[algorithm]}' does not exist: initialize from a remote Git repository"
        echo "Cloning Git repository '$url' to directory '$src_dir'"

        Prefixed git clone "$url" "$src_dir"
        Prefixed git -C "$src_dir" submodule update --init --recursive
    else
        echo "Directory '$src_dir' for algorithm '${generic_git_fetch_args[algorithm]}' does already exist: update from a remote Git repository"

        Prefixed git -C "$src_dir" fetch origin
        Prefixed git -C "$src_dir" submodule update
    fi

    if [[ "${generic_git_fetch_args[algorithm_version]}" != "latest" ]]; then 
        echo "Specific version specified for algorithm '${generic_git_fetch_args[algorithm]}': checkout '${generic_git_fetch_args[algorithm_version]}'"
        Prefiex git -C "$src_dir" reset --hard "${generic_git_fetch_args[algorithm_version]}"
    else
        echo "No version specified for algorithm '${generic_git_fetch_args[algorithm]}': update to latest commit"

        Prefixed git -C "$src_dir" pull origin
    fi
}
