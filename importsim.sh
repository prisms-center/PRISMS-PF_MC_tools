#!/bin/bash

# Function to check if a directory exists and ask for overwrite permission
check_and_create_dir() {
    local dir=$1
    if [ -d "$dir" ]; then
        read -p "Directory '$dir' already exists. Overwrite files? (y/n): " choice
        case "$choice" in 
            y|Y ) echo "Overwriting existing files...";;
            n|N ) echo "Aborting."; exit 1;;
            * ) echo "Invalid choice. Aborting."; exit 1;;
        esac
    else
        mkdir -p "$dir"
    fi
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    echo "No arguments supplied. Please provide an input directory."
    exit 1
fi

# Default values
move_vtk=false
rename_dir=""

# Parse command-line flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --move_vtk) move_vtk=true; shift ;;
        --rename)
            if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
                rename_dir=$2
                shift 2
            else
                echo "Error: --rename flag requires a directory name."
                exit 1
            fi
            ;;
        *) 
            # The first non-flag argument is treated as the input directory
            if [ -z "$input_dir" ]; then
                input_dir=$1
            else
                echo "Unknown option: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Ensure input_dir is set
if [ -z "$input_dir" ]; then
    echo "Error: No input directory specified."
    exit 1
fi

# Set locdir based on --rename flag or default to input_dir name
if [ -n "$rename_dir" ]; then
    locdir=$rename_dir
else
    locdir=${input_dir##*/}
fi

echo "Setting simulation directory: $locdir"

code_dir="$locdir/code"
results_dir="$locdir/results"
vtk_files_dir="$results_dir/vtk"
image_files_dir="$results_dir/images"
movie_files_dir="$results_dir/movies"
pp_files_dir="$results_dir/postprocess"

# Creating directories with overwrite check
check_and_create_dir "$locdir"
mkdir -p "$code_dir" "$results_dir" "$vtk_files_dir" "$image_files_dir" "$movie_files_dir" "$pp_files_dir"

# Function to copy or move files with error handling
copy_or_move_files() {
    local src_ext=$1
    local dest_dir=$2
    local move_flag=$3

    if compgen -G "$input_dir/*.$src_ext" > /dev/null; then
        if [ "$move_flag" = true ]; then
            mv "$input_dir"/*."$src_ext" "$dest_dir"/
        else
            cp "$input_dir"/*."$src_ext" "$dest_dir"/
        fi
    else
        echo "Warning: No .$src_ext files found in $input_dir"
    fi
}

# Organizing files
copy_or_move_files "cc" "$code_dir" false
copy_or_move_files "h" "$code_dir" false
copy_or_move_files "prm" "$code_dir" false
copy_or_move_files "vtk" "$vtk_files_dir" "$move_vtk"
copy_or_move_files "vtu" "$vtk_files_dir" "$move_vtk"
copy_or_move_files "md" "$locdir" false

# Special case: Handle single file copy for CMakeLists.txt and integratedFields.txt
[ -f "$input_dir/CMakeLists.txt" ] && cp "$input_dir/CMakeLists.txt" "$code_dir/" || echo "Warning: CMakeLists.txt not found."
[ -f "$input_dir/integratedFields.txt" ] && cp "$input_dir/integratedFields.txt" "$pp_files_dir/" || echo "Warning: integratedFields.txt not found."

echo "File organization completed."