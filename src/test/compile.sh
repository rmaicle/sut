declare -r SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
declare -r CURRENT_DIR=$(pwd)

dmd                         \
    -I=${SCRIPT_DIR}/..     \
    -I=${CURRENT_DIR}       \
    -i                      \
    -main                   \
    -debug                  \
    -unittest               \
    -version=sut            \
    -run $@
