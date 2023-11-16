if [[ $mode == "upload" ]]; then 
    dir="$(pwd)"
    name="${dir##*/}"
    UploadDirectory "$dir"/ "$name"
fi

if [[ $mode == "upload-self" ]]; then
    UploadDirectory "$ROOT"/ mkexp

    echo "Uploaded mkexp framework to the remote host"
    echo "  You can now add the bin directory to your PATH environment variable, e.g., by running on the remote host:"
    echo "  echo 'export PATH=\$PATH:~/mkexp/bin' >> ~/.bashrc"
fi

if [[ $mode == "download" ]]; then
    dir="$(pwd)"
    name="${dir##*/}"
    DownloadDirectory "$dir"/ "$name"
fi

