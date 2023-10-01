#!/usr/bin/env bash

#
# Archive project files.
# Create .tar.gz for GNU/Linux and .zip for Microsoft Windows.
#
# Run from the root of the project:
#   ./archive.sh
#

declare OUTPUT_FILE_LINUX="sut-${VERSION}.tar.gz"
declare OUTPUT_FILE_WINDOWS="sut-${VERSION}.zip"
declare DESTINATION_DIR="dist"



[[ ! -d ./${DESTINATION_DIR} ]] && mkdir ${DESTINATION_DIR}

tar -czf ${OUTPUT_FILE_LINUX} CHANGELOG.md LICENSE README.md ./src
mv -n ${OUTPUT_FILE_LINUX} ./${DESTINATION_DIR}

zip -r ${OUTPUT_FILE_WINDOWS} CHANGELOG.md LICENSE README.md ./src
mv -n ${OUTPUT_FILE_WINDOWS} ./${DESTINATION_DIR}

echo "Done: Archive files are in ${DESTINATION_DIR}"
