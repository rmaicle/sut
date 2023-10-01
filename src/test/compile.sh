#!/usr/bin/env bash

#
# Driver for compiling test examples using the SUT module.
#
# $ ../compile test.d
#

declare -r SCRIPT_NAME=${0##*/}
declare -r SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
declare -r CURRENT_DIR=$(pwd)



flag_compiler_dmd=1
flag_compiler_ldc=0
flag_build_debug=1

v_param_build="-debug"



# Define the short and long options
OPTIONS_SHORT="d"
OPTIONS_LONG=""
OPTIONS_LONG+="dmd"
OPTIONS_LONG+=",ldc"
OPTIONS_LONG+=",release"
OPTIONS_TEMP=$(getopt               \
    --options ${OPTIONS_SHORT}      \
    --longoptions ${OPTIONS_LONG}   \
    --name "${SCRIPT_NAME}" -- "$@")
# Append unrecognized arguments after --
eval set -- "${OPTIONS_TEMP}"



while true; do
    case "${1}" in
        -d)                     flag_build_debug=1 ; shift ;;
        --dmd)                  flag_compiler_dmd=1
                                flag_compiler_ldc=0
                                shift ;;
        --ldc)                  flag_compiler_ldc=1
                                flag_compiler_dmd=0
                                shift ;;
        --release)              flag_build_debug=0 ; shift ;;
        --)                     shift ; break ;;
        *)                      echo "Internal error! $@" ; exit 1 ;;
    esac
done



if [ ${flag_compiler_dmd} -gt 0 ]; then
    v_compiler="dmd"
elif [ ${flag_compiler_ldc} -gt 0 ]; then
    v_compiler="ldmd2"
fi

if [ ${flag_build_debug} -gt 0 ]; then
    v_param_build="-debug"
elif [ ${flag_build_debug} -eq 0 ]; then
    v_param_build="-release"
fi



${v_compiler}               \
    -I=${SCRIPT_DIR}/..     \
    -I=${CURRENT_DIR}       \
    -i                      \
    -main                   \
    ${v_param_build}        \
    -unittest               \
    -version=sut            \
    -debug=verbose          \
    -run $@
