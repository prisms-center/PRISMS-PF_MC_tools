#!/bin/bash

#############################################################
# Grab the date and start a global timer
if builtin command -v gdate >/dev/null; then
	DATE_CMD=$(which gdate)
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
    local COLOR=$1
    shift
    echo -e "${COLOR}$*\033[0m"
    # or: echo -e "${COLOR}$@\033[0m" is mostly fine, but $* is often nicer here
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

    # Split on commas safely (no glob expansion)
    local patterns=()
    IFS=',' read -r -a patterns <<< "$SRC_REGEX"

    # Enable nullglob only for the LOCAL_SRC expansion
    local old_nullglob
    old_nullglob=$(shopt -p nullglob 2>/dev/null)
    shopt -s nullglob

    local pattern
    for pattern in "${patterns[@]}"; do
        # Expand the glob inside LOCAL_SRC into an array (space-safe)
        local files=( "$LOCAL_SRC"/$pattern )

        if ((${#files[@]})); then
            found_files=true
            local f
            for f in "${files[@]}"; do
                if [ "$COPY_FLAG" != "ON" ]; then
                    mv -- "$f" "$LOCAL_DST"/
                else
                    cp -- "$f" "$LOCAL_DST"/
                fi
            done
        fi
    done

    # Restore nullglob setting
    eval "$old_nullglob" 2>/dev/null || true

    if [ "$found_files" = false ]; then
        echo
        color_echo "${WARN}" "No files matching '${SRC_REGEX}' found in ${LOCAL_SRC}"
    fi
}


#############################################################
# Main script

# Check if SRC_DIR and DST_DIR are set
if [ -z "$SRC_DIR" ]; then
	color_echo ${BAD} "No source directory has been specified."
	exit 1
fi

# Expand any shell variables and home directory in SRC_DIR
SRC_DIR=$(eval echo "${SRC_DIR}")

# Convert SRC_DIR to absolute path
SRC_DIR=$(realpath "${SRC_DIR}")
SRC_BASENAME=$(basename "${SRC_DIR}")

# Handle DST_DIR according to the 4 rules
if [ -z "$DST_DIR" ] || [ "$DST_DIR" == "." ]; then
	# Rule 1: If DST_DIR is "." or empty, create a new directory with SRC name inside current directory
	DST_DIR="./${SRC_BASENAME}"
elif [[ ! "$DST_DIR" = /* && -d "$DST_DIR" ]]; then
	# Rule 3: If DST_DIR is an existing directory within working dir (and not absolute path), create a subdir inside it
	DST_DIR="${DST_DIR}/${SRC_BASENAME}"
fi

# Expand and convert DST_DIR to absolute path (portable version)
DST_DIR=$(eval echo "${DST_DIR}")
ALREADY_EXISTS=false
if [ -d "$DST_DIR" ]; then
	ALREADY_EXISTS=true
fi

mkdir -p "$DST_DIR" || { echo "Failed to create DST_DIR"; exit 1; }
DST_DIR=$(cd "$DST_DIR" && pwd)

# Sanity check
[ -z "$DST_DIR" ] && echo "DST_DIR is empty! Aborting..." && exit 1

# Prompt only if it already existed
if [ "$ALREADY_EXISTS" = true ]; then
	check_and_create_dir "${DST_DIR}"
	quit_if_fail "Failed to confirm overwrite for destination directory."
fi

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

# Make the subfolders
mkdir -p "$CODE_DIR" "$DATA_DIR" "$OUTPUT_DIR" "$IMAGE_DIR" "$MOVIE_DIR" "$POSTPROCESS_DIR"
quit_if_fail "Failed to create subfolders in destination directory."

# Organizing files
copy_or_move_files "*.cc,*.c,*.cpp,*.cxx,*.h,*.in,*.hpp,*.prm,*.py,*.sh,*.json,*.yaml,*.yml" "${SRC_DIR}" "${CODE_DIR}" "ON"
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
