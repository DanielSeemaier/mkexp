# Clone a GIT repository and checkout the specified version
GenericGitFetch() {
    local -n generic_git_fetch_args=$1
    local url=$2
    local src_dir_key=$3

    src_dir="${generic_git_fetch_args[$src_dir_key]}"
    if [[ ! -d "$src_dir" ]]; then
        mkdir -p "$src_dir"
        git clone "$url" "$src_dir"
        git -C "$src_dir" submodule update --init --recursive
    else
        git -C "$src_dir" fetch origin
        git -C "$src_dir" submodule update
    fi

    if [[ "${generic_git_fetch_args[algorithm_version]}" != "latest" ]]; then 
        git -C "$src_dir" reset --hard "${generic_git_fetch_args[algorithm_version]}"
    else
        git -C "$src_dir" pull origin
    fi
}
