dmd -I=../ -J=. -i -unittest -version=sut $@
declare -r compile_error=$?
[ ${compile_error} -ne 0 ] \
    && echo "Compilation error:" \
    || echo "Compilation successful:"
echo "$(date +'%T %Y-%m-%d %:z')"

[ ${compile_error} -ne 0 ] && exit

declare output_file=${1##*/}
declare base_filename=${output_file%.*}
declare output_file="${base_filename}"

echo -e "\nRunning executable...\n"
./${output_file}
