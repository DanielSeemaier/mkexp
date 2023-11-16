if [[ $mode == "init" ]]; then 
    cp "$ROOT/examples/Default" "$PWD/Experiment"
    exit 0
fi
if [[ $mode == "init-mtkahypar-supermuc" ]]; then 
    cp "$ROOT/examples/MtKaHyPar-SuperMUC" "$PWD/Experiment"
    exit 0
fi
