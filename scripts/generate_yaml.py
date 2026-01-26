#!/usr/bin/env python3

# Script to generate a yaml containing the parameters for a specific simulation
# Run as generate_yaml.py <target_dir>
# where target_dir is where the file parameters.prm is located
# and where the yaml file will be placed
# This path should be relative to where the current script is executed

import re
from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedMap
import argparse


def parse_prm_file(prm_path):
    """
    Parses the parameters.prm file and extracts key-value-type triples,
    including handling of nested subsections while preserving order.
    """
    parameters = CommentedMap()
    current_section = parameters
    section_stack = []

    with open(prm_path, "r") as file:
        for line in file:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            # Detect subsection start
            subsection_match = re.match(r"subsection\s+(.+)", line)
            if subsection_match:
                subsection_name = subsection_match.group(1).strip()
                # Create a new subsection if not present
                if subsection_name not in current_section:
                    current_section[subsection_name] = CommentedMap()
                # Move into the new subsection
                section_stack.append(current_section)
                current_section = current_section[subsection_name]
                continue

            # Detect end of subsection
            if line == "end":
                if section_stack:
                    current_section = section_stack.pop()
                continue

            # Match the pattern for `set <key> = <value> [type]`
            match = re.match(r"set\s+(.+?)\s*=\s*(.+?)(?:\s*,\s*(\S+))?$", line)
            if match:
                key = match.group(1).strip()
                value = match.group(2).strip()
                value_type = match.group(3).strip() if match.group(3) else None
                current_section[key] = CommentedMap(
                    {"value": value, "type": value_type}
                )
            else:
                print(f"Unmatched line: {line}")

    return parameters


def convert_to_yaml(parameters, prm_file_path, output_yaml_path):
    """
    Converts the extracted parameters into a YAML structure and writes to a file,
    while preserving the order of entries.
    """
    yaml_structure = CommentedMap(
        {
            "inputs": [
                CommentedMap(
                    {
                        "path": prm_file_path,
                        "encodingFormat": "text",
                        "name": "parameters.prm",
                        "description": "Parameter file required to run simulation",
                        "download": False,
                        "parameters": parameters,
                    }
                )
            ]
        }
    )

    # Use ruamel.yaml to write YAML
    yaml = YAML()
    yaml.default_flow_style = False
    yaml.indent(mapping=2, sequence=4, offset=2)  # Optional: Adjust indentation

    with open(output_yaml_path, "w") as yaml_file:
        yaml.dump(yaml_structure, yaml_file)


if __name__ == "__main__":

    # Use argparse to handle command-line arguments
    parser = argparse.ArgumentParser(
        description="Parse a .prm file and convert it to YAML."
    )
    parser.add_argument(
        "path", help="Path to the input parameters.prm and YAML output file"
    )

    args = parser.parse_args()

    prm_file_path = args.path + "/input/parameters.prm"
    yaml_output_path = args.path + "/simlog.yaml"

    # Parse the .prm file
    parameters = parse_prm_file(prm_file_path)

    # Generate and write the YAML file
    convert_to_yaml(parameters, prm_file_path, yaml_output_path)
    print(f"YAML file has been generated at: {yaml_output_path}")
