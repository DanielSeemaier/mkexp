# The directory in which all partitioners, tools, libraries etc. are build
# $PWD refers to the directory of the experiment in which mkexp is executed
PREFIX="$PWD/usr"

export PATH="$PREFIX/bin:$PATH"
export C_INCLUDE_PATH="$PREFIX/include:${C_INCLUDE_PATH-""}"
export CPLUS_INCLUDE_PATH="$PREFIX/include:${CPLUS_INCLUDE_PATH-""}"
export LIBRARY_PATH="$PREFIX/lib:${LIBRARY_PATH-""}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH-""}"
export CMAKE_PREFIX_PATH="$PREFIX/:${CMAKE_PREFIX_PATH-""}"

ExportEnv() {
    echo "export PATH=\"$PATH\""
    echo "export C_INCLUDE_PATH=\"$C_INCLUDE_PATH\""
    echo "export CPLUS_INCLUDE_PATH=\"$CPLUS_INCLUDE_PATH\""
    echo "export LIBRARY_PATH=\"$LIBRARY_PATH\""
    echo "export LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH\""
}

