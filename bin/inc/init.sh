if [[ $mode == "init" ]]; then 
    if [[ ! -f "$ROOT/examples/$init_filename" ]]; then
        echo "Error: File $ROOT/examples/$init_filename not found."
        exit 1
    fi
    cp "$ROOT/examples/$init_filename" "$PWD/Experiment"
    exit 0
fi
