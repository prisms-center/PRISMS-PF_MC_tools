# PRISMS-PF_MC_tools
**Tools for integration between PRISMS-PF and Materials Commons**

The script files in this repository can be used to assist with automation of the following tasks:
- Locally importing PRISMS-PF code files and simulation results into a Materials Commons project directory
- For each calculation (simulation) directory, sorting the different file types into different subdirectories
- Creating a yaml file containing data and metadata for each simulation and adding these data to an ETL spreadsheet associated with an Experiment in Materials Commons
- Generating image frames and movies for different field variables within a phase-field simulation

To take full advantage of these tools you should:

1) [Create an account in Materials Commons](https://materialscommons.org/register) if you do not already have one
2) [Install and configure the Materials Commons Command Line Interface (CLI)](https://materials-commons.github.io/materials-commons-cli/html/install.html) in the  computer where you usually run PRISMS-PF.
3) Create a *project* directory in your computer to compile all the data files to be uploaded into a Materials Commons *project*. To be able to use the CLI, the name of the Materials Commons project should match that of the project locally. Read more about Materials Commons projects [here](https://materialscommons.org/docs/docs/getting-started/). It is recommended that the project directory is outside you phaseField directory.
4) Within the project directory, create a corresponding project within Materials Commons by typing
```
$ mc init
```
**Importing simulation data**

The script <code>importsim.sh</code> copies data from a source directory where the simulation code and results files are located into a new target directory whithin your project directory
Usage
```
$ ./importsim.sh [--move_vtk] <source directory> [--rename] <target directory>
```
This will copy most of the contents of <code><source directory></code> into <code><target directory></code> but orgazing the files the following way