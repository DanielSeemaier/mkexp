if [[ $mode == "init" ]]; then 
    if [[ ! -f "$MKEXP_HOME/examples/$init_filename" ]]; then
        echo "Error: File $MKEXP_HOME/examples/$init_filename not found."
        exit 1
    fi
    cp "$MKEXP_HOME/examples/$init_filename" "$PWD/Experiment"
    exit 0
fi
