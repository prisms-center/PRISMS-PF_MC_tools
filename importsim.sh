#!/bin/bash

#############################################################
# Grab the date and start a global timer
if builtin command -v gdate >/dev/null; then
	DATE_CMD=$(which gdata)
else
	DATE_CMD=$(which date)
fi
TIC_GLOBAL="$(${DATE_CMD} +%s)"

#############################################################
# Various niceties that make the script look pretty

# Colors
BAD="\033[1;31m"
GOOD="\033[1;32m"
WARN="\033[1;35m"
INFO="\033[1;34m"
BOLD="\033[1m"

# Color echo
color_echo() {
	COLOR=$1
	shift
	echo -e "${COLOR}$@\033[0m"
}

# Exit with some useful information
quit_if_fail() {
	STATUS=$?
	if [ ${STATUS} -ne 0 ]; then
		color_echo ${BAD} "Failure with exit status:" ${STATUS}
		color_echo ${BAD} "Exit message:" $1
		exit ${STATUS}
	fi
}

#############################################################
# Parse command line inputs with default values below
COPY_OUTPUT=ON
SRC_DIR=""
DST_DIR=""

while [ -n "$1" ]; do
	input="$1"
	case $input in

	-h | --help)
		echo "PRISMS-PF file organization for Materials Commons importing"
		echo
		echo "Usage: $0 [options] SRC_DIR DST_DIR"
		echo "Options:"
		echo "  --copy=<ON/OFF> whether to copy or move *.vtu, *.pvtu, and *.vtk files (default = ${COPY_OUTPUT})"
		exit 0
		;;

	--copy=*)
		COPY_OUTPUT="${input#*=}"
		;;

	*)
		# If we haven't set SRC_DIR yet, this is the source
		if [ -z "$SRC_DIR" ]; then
			SRC_DIR="$input"
		# If we have SRC_DIR but not DST_DIR, this is the destination
		elif [ -z "$DST_DIR" ]; then
			DST_DIR="$input"
		else
			color_echo ${BAD} "Invalid command line option <$input>. See -h for more information."
			exit 2
		fi
		;;

	esac
	shift
done

#############################################################
# Function to check if a directory exists and ask for overwrite permission
check_and_create_dir() {
	local dir=$1
	if [ -d "$dir" ]; then
		read -p "Directory '$dir' already exists. Overwrite files? (y/n): " choice
		case "$choice" in
		y | Y)
			color_echo ${WARN} "Overwriting existing files..."
			;;
		n | N)
			color_echo ${WARN} "Aborting..."
			exit 1
			;;
		*)
			color_echo ${BAD} "Invalid choice. Aborting..."
			exit 1
			;;
		esac
	else
		mkdir -p "$dir"
	fi
}

# Function to copy or move files with error handling
copy_or_move_files() {
	local SRC_REGEX=$1
	local LOCAL_SRC=$2
	local LOCAL_DST=$3
	local COPY_FLAG=$4
	local found_files=false

	# Handle brace expansion patterns
	for pattern in ${SRC_REGEX//,/ }; do
		if compgen -G "${LOCAL_SRC}/${pattern}" >/dev/null; then
			found_files=true
			if [ "${COPY_FLAG}" != "ON" ]; then
				mv ${LOCAL_SRC}/${pattern} "${LOCAL_DST}/"
			else
				cp ${LOCAL_SRC}/${pattern} "${LOCAL_DST}/"
			fi
		fi
	done

	if [ "$found_files" = false ]; then
		echo
		color_echo ${WARN} "No files matching '${SRC_REGEX}' found in ${LOCAL_SRC}"
	fi
}

#############################################################
# Main script

# Check if SRC_DIR and DST_DIR are set
if [ -z "$SRC_DIR" ]; then
	color_echo ${BAD} "No source directory has been specified."
	exit 1
fi
if [ -z "$DST_DIR" ]; then
	# Get the last folder name from SRC_DIR
	LAST_FOLDER=$(basename "${SRC_DIR}")
	DST_DIR="./${LAST_FOLDER}"
	color_echo ${INFO} "No destination specified, using relative path: ${DST_DIR}"
fi

# First expand any shell variables and home directory
SRC_DIR=$(eval echo "${SRC_DIR}")
DST_DIR=$(eval echo "${DST_DIR}")

# Then convert to absolute path
SRC_DIR=$(realpath "${SRC_DIR}")
DST_DIR=$(realpath "${DST_DIR}")

echo
color_echo ${INFO} "Source directory: ${SRC_DIR}"
color_echo ${INFO} "Destination directory: ${DST_DIR}"
echo

# Collect the various subfolders that we organize data into
CODE_DIR="${DST_DIR}/code"
DATA_DIR="${DST_DIR}/data"
OUTPUT_DIR="${DATA_DIR}/vtk"
IMAGE_DIR="${DATA_DIR}/images"
MOVIE_DIR="${DATA_DIR}/movies"
POSTPROCESS_DIR="${DATA_DIR}/postprocess"

# Create the DST_DIR and ask if we have to overwrite files
check_and_create_dir "${DST_DIR}"
quit_if_fail "Failed to create destination directory."

# Make the subfolders
mkdir -p ${CODE_DIR} ${DATA_DIR} ${OUTPUT_DIR} ${IMAGE_DIR} ${MOVIE_DIR} ${POSTPROCESS_DIR}
quit_if_fail "Failed to create subfolders in destination directory."

# Organizing files
copy_or_move_files "*.cc,*.c,*.cpp,*.cxx,*.h,*.hpp,*.prm,*.py,*.sh,*.json,*.yaml,*.yml" "${SRC_DIR}" "${CODE_DIR}" "ON"
copy_or_move_files "*.vtk,*.vtu,*.pvtu" "${SRC_DIR}" "${OUTPUT_DIR}" "${COPY_OUTPUT}"
copy_or_move_files "*.md" "${SRC_DIR}" "${DST_DIR}" "ON"

# Special case: Handle single file copy for CMakeLists.txt and integratedFields.txt
if [ -f "${SRC_DIR}/CMakeLists.txt" ]; then
	cp "${SRC_DIR}/CMakeLists.txt" "${CODE_DIR}/"
else
	echo
	color_echo ${WARN} "CMakeLists.txt not found."
fi

if [ -f "${SRC_DIR}/integratedFields.txt" ]; then
	cp "${SRC_DIR}/integratedFields.txt" "${POSTPROCESS_DIR}/"
else
	echo
	color_echo ${WARN} "integratedFields.txt not found."
fi

# Stop the timer
TOC_GLOBAL="$(($(${DATE_CMD} +%s) - TIC_GLOBAL))"

# Summary
echo
color_echo ${GOOD} "File organization completed in $((TOC_GLOBAL)) seconds."
echo
