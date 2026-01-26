#!/usr/bin/env python3

import os
import sys
import yaml
import pandas as pd
from materials_commons.cli.file_functions import make_mcpath
from materials_commons.cli.functions import project_path


def read_yaml_parameters(file_path, abs_source_directory):
    """Read parameters from the YAML file and add Calculation, Description, Observations, and additional file paths."""
    with open(file_path, "r") as file:
        data = yaml.safe_load(file)

    parameters = data.get("inputs", [])[0].get("parameters", {})

    # Extract only the last part of the source directory
    calculation_name = os.path.basename(os.path.normpath(abs_source_directory))

    # Prompt user for Description
    user_description = input(
        f"Enter a description for {calculation_name} (press Enter to skip): "
    ).strip()

    # Prompt user for Observations
    user_observations = input(
        f"Enter observations for {calculation_name} (press Enter to skip): "
    ).strip()

    # Define project relative source directory
    proj_local_path = project_path(abs_source_directory)
    calc_rel_path=make_mcpath(proj_local_path,abs_source_directory)
    # Write both to Info.md
    info_file_path = os.path.join(abs_source_directory, "Info.md")
    info_relative_path = os.path.join(calc_rel_path, "Info.md")
    with open(info_file_path, "w") as info_file:
        info_file.write(f"# Description\n{user_description}\n\n")
        info_file.write(f"# Observations\n{user_observations}\n")

    # Automatically set additional file paths
    code_relative_path = os.path.join(calc_rel_path, "code")
    vtk_relative_path = os.path.join(calc_rel_path, "results", "vtk")
    postprocess_relative_path = os.path.join(
        calc_rel_path, "results", "postprocess"
    )
    images_relative_path = os.path.join(calc_rel_path, "results", "images")
    movies_relative_path = os.path.join(calc_rel_path, "results", "movies")

    # Add columns: c:Calculation, file:Info:, file paths, and parameters with "p:" prefix
    param_dict = {
        "c:Calculation": calculation_name,
        "file:Info:": info_relative_path,
        "file:Code:": code_relative_path,
        "file:vtk_files:": vtk_relative_path,
        "file:Postprocess_files:": postprocess_relative_path,
        "file:Images:": images_relative_path,
        "file:Movies": movies_relative_path,
    }
    param_dict.update(
        {f"p:{key}": value.get("value", "") for key, value in parameters.items()}
    )

    return param_dict


def write_to_excel(param_dict, target_file):
    """Write parameters to an Excel file, creating headers if the file does not exist."""
    df_new = pd.DataFrame([param_dict])

    # Sheet name = file name without extension
    sheet_name1 = os.path.splitext(os.path.basename(target_file),)[0]

    if not os.path.exists(target_file):
        # Create a new file with headers
        df_new.to_excel(target_file, index=False, sheet_name=sheet_name1)
        print(f"Created new file: {target_file}")
        return

    with pd.ExcelWriter(
        target_file, mode="a", engine="openpyxl", if_sheet_exists="overlay"
    ) as writer:
        # If the sheet doesn't exist, create it with headers
        if sheet_name1 not in writer.book.sheetnames:
            df_new.to_excel(writer, index=False, sheet_name=sheet_name1)
            print(f"Added new sheet '{sheet_name}' in: {target_file}")
            return
        
        # Sheet exists: read existing sheet to check columns
        existing_df = pd.read_excel(target_file, sheet_name=sheet_name1)

        # Ensure the new data matches the existing columns
        if not set(df_new.columns).issubset(set(existing_df.columns)):
            print("Error: New parameters do not match existing file structure.")
            return
        
        startrow = writer.sheets[sheet_name1].max_row
        
        df_new.to_excel(
            writer,
            index=False,
            header=False,
            sheet_name=sheet_name1,
            startrow=writer.sheets[sheet_name1].max_row,
        )

    print(f"Appended data to: {target_file}")

def main():
    if len(sys.argv) != 3:
        print("Usage: python yaml_to_excel.py <source_directory> <target_excel_file>")
        sys.exit(1)

    source_directory = sys.argv[1]
    target_file = sys.argv[2]

    # Get absolute path of source directory
    abs_source_directory = os.path.abspath(source_directory)

    yaml_file = os.path.join(source_directory, "simlog.yaml")

    if not os.path.exists(yaml_file):
        print(f"Error: YAML file not found in {source_directory}")
        sys.exit(1)

    #defining parameter dictionary
    param_dict = read_yaml_parameters(yaml_file, abs_source_directory)
    write_to_excel(param_dict, target_file)


if __name__ == "__main__":
    main()
