#!/usr/bin/env python3

import sys
import os

# Check if running inside Visit
if "VISITDIR" not in os.environ:
    # Relaunch the script using Visit CLI
    visit_cmd = f"visit -cli -nowin -s {sys.argv[0]} " + " ".join(sys.argv[1:])
    print(f"Running Visit CLI: {visit_cmd}")
    os.system(visit_cmd)
    sys.exit(0)  # Exit after launching Visit

# Now inside Visit CLI, import Visit modules
from visit import *

# Check for required arguments
if len(sys.argv) < 3:
    print("Usage: script.py <var1> <var2> ... <sim_dir>")
    sys.exit(1)

# The last argument is the simulation directory
sim_dir = sys.argv[-1]

# Variables to plot (all arguments except the last one)
variables = sys.argv[1:-1]

print(f"Simulation directory: {sim_dir}")
print(f"Variables to plot: {variables}")

# Step 1: Open a database (the whole .vtu time series)
dbname_pf = sim_dir + "/data/vtk/solution-*.vtu database"
OpenDatabase(dbname_pf)

for var in variables:
    print(f"Plotting variable: {var}")

    # Delete previous plots before adding a new one
    DeleteAllPlots()

    # Add plot for the current variable
    AddPlot("Pseudocolor", var)
    DrawPlots()

    # Animate through time and save results
    for states in range(TimeSliderGetNStates()):
        # Set slider to state
        SetTimeSliderState(states)
        # Get the time corresponding to the state
        Query("Time")
        # Assign this time to the variable "t"
        t = GetQueryOutputValue()
        print(f"Saving frame {states}, time {t:.1f} for variable {var}")

        # Set save window attributes
        SaveWindowAtts = SaveWindowAttributes()
        SaveWindowAtts.fileName = f"{sim_dir}/data/images/{var}_frame_{states}"
        SetSaveWindowAttributes(SaveWindowAtts)
        SaveWindow()

# Cleanup
DeleteAllPlots()
CloseDatabase(dbname_pf)

sys.exit()
