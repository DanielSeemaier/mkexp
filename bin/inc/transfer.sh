if [[ $mode == "upload" ]]; then 
    dir="$(pwd)"
    name="${dir##*/}"
    UploadDirectory "$dir"/ "$name"
fi
if [[ $mode == "upload-self" ]]; then
    UploadDirectory "$ROOT"/ mkexp
fi
if [[ $mode == "download" ]]; then
    dir="$(pwd)"
    name="${dir##*/}"
    DownloadDirectory "$dir"/ "$name"
fi

