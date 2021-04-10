declare -r SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
declare -r CURRENT_DIR=$(pwd)

dmd \
    -I=${SCRIPT_DIR}/.. \
    -I=${CURRENT_DIR} \
    -J=${CURRENT_DIR} \
    -i -main -unittest -version=sut -run $@
declare -r compile_error=$?
[ ${compile_error} -ne 0 ] \
    && echo "Compilation error:" \
    || echo "Compilation successful:"
echo "$(date +'%T %Y-%m-%d %:z')"
