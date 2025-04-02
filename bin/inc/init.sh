if [[ $mkexp_mode == *"$MKEXP_MODE_INIT"* ]]; then 
    if [[ ! -f "$MKEXP_HOME/presets/$mkexp_init_preset" ]]; then
        echo "Error: File $MKEXP_HOME/presets/$mkexp_init_preset not found."
        exit 1
    fi
    cp "$MKEXP_HOME/presets/$mkexp_init_preset" "$PWD/Experiment"
    exit 0
fi
