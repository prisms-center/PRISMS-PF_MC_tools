import os
import sys
import yaml
import pandas as pd

def read_yaml_parameters(file_path, source_directory):
    """Read parameters from the YAML file and add Calculation and Description columns."""
    with open(file_path, 'r') as file:
        data = yaml.safe_load(file)

    parameters = data.get("inputs", [])[0].get("parameters", {})

    # Extract only the last part of the source directory
    calculation_name = os.path.basename(os.path.normpath(source_directory))

    # Prompt user for description with a default value
    user_description = input(f"Enter a description for {calculation_name} (press Enter to use default: '{calculation_name}'): ").strip()
    if not user_description:
        user_description = calculation_name  # Default to calculation name

    # Add columns: c:Calculation, p:Description, and parameters with "p:" prefix
    param_dict = {
        "c:Calculation": calculation_name,
        "p:Description": user_description
    }
    param_dict.update({f"p:{key}": value.get("value", "") for key, value in parameters.items()})
    
    return param_dict

def write_to_excel(param_dict, target_file):
    """Write parameters to an Excel file, creating headers if the file does not exist."""
    df_new = pd.DataFrame([param_dict])

    if not os.path.exists(target_file):
        # Create a new file with headers
        df_new.to_excel(target_file, index=False)
        print(f"Created new file: {target_file}")
    else:
        # Append without writing headers again
        existing_df = pd.read_excel(target_file)

        # Ensure the new data matches the existing columns
        if not set(df_new.columns).issubset(set(existing_df.columns)):
            print("Error: New parameters do not match existing file structure.")
            return

        with pd.ExcelWriter(target_file, mode="a", engine="openpyxl", if_sheet_exists="overlay") as writer:
            df_new.to_excel(writer, index=False, header=False, startrow=writer.sheets['Sheet1'].max_row)
        
        print(f"Appended data to: {target_file}")

def main():
    if len(sys.argv) != 3:
        print("Usage: python yaml_to_excel.py <source_directory> <target_excel_file>")
        sys.exit(1)

    source_directory = sys.argv[1]
    target_file = sys.argv[2]

    yaml_file = os.path.join(source_directory, "simlog.yaml")

    if not os.path.exists(yaml_file):
        print(f"Error: YAML file not found in {source_directory}")
        sys.exit(1)

    param_dict = read_yaml_parameters(yaml_file, source_directory)
    write_to_excel(param_dict, target_file)

if __name__ == "__main__":
    main()
