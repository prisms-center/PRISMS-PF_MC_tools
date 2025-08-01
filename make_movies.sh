#!/bin/bash

# Default frame rate
frame_rate=5

# Parse optional --frame_rate argument
if [[ "$1" == "--frame_rate" ]]; then
    if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
        frame_rate=$2
        shift 2  # Remove --frame_rate and its value from arguments
    else
        echo "Error: Invalid or missing value for --frame_rate."
        echo "Usage: $0 [--frame_rate <rate>] <field1> <field2> ... <input_directory>"
        exit 1
    fi
fi

# Check if at least one field and the input directory are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 [--frame_rate <rate>] <field1> <field2> ... <input_directory>"
    exit 1
fi

# Convert input directory to an absolute path
input_dir=$(realpath "${@: -1}")

# Check if input directory exists
if [ ! -d "$input_dir" ]; then
    echo "Error: Directory '$input_dir' does not exist."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$input_dir/data/movies"

# Loop over all specified fields (excluding the last argument, which is the input directory)
for field in "${@:1:$#-1}"; do
    image_dir="$input_dir/data/images"
    output_movie="$input_dir/data/movies/${field}_movie.mp4"

    # Find matching images (ensuring absolute paths)
    png_files=($(find "$image_dir" -type f -name "${field}_frame_*.png" 2>/dev/null | sort -V))

    # Check if there are any matching images
    if [ ${#png_files[@]} -eq 0 ]; then
        echo "Warning: No images found for field '$field'. Skipping."
        continue
    fi

    # Generate a temporary text file listing the sorted image sequence
    list_file=$(mktemp)
    for img in "${png_files[@]}"; do
        echo "file '$(realpath "$img")'" >> "$list_file"
    done

    # Validate that the list file contains paths before running ffmpeg
    if [ ! -s "$list_file" ]; then
        echo "Error: No valid images found for '$field'. Skipping."
        rm "$list_file"
        continue
    fi

    # Generate movie using ffmpeg
    ffmpeg -r "$frame_rate" -fflags +genpts -f concat -safe 0 -i "$list_file" -fps_mode vfr -c:v libx264 -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "$output_movie"

    # Remove the temporary list file
    rm "$list_file"
done

echo "Movies generated successfully with frame rate: $frame_rate"
