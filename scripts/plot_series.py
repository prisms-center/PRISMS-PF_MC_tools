#!/usr/bin/env python3

import sys
import os
import glob

# Check if running outside Visit and relaunch using Visit CLI
if "VISITDIR" not in os.environ:
    visit_cmd = "visit -cli -nowin -s {} {}".format(sys.argv[0], " ".join(sys.argv[1:]))
    print("Running Visit CLI: {}".format(visit_cmd))
    os.system(visit_cmd)
    sys.exit(0)

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

print("Simulation directory: {}".format(sim_dir))
print("Variables to plot: {}".format(variables))

# Step 1: Open a database (the whole .vtu time series)
# Step 1: Detect available .vtu database pattern
vtk_dir = os.path.join(sim_dir, "data", "vtk")

if len(glob.glob(os.path.join(vtk_dir, "solution_*.vtu"))) > 0:
    dbname_pf = f"{vtk_dir}/solution_*.vtu database"
elif len(glob.glob(os.path.join(vtk_dir, "solution-*.vtu"))) > 0:
    dbname_pf = f"{vtk_dir}/solution-*.vtu database"
else:
    print("Error: No .vtu files found matching either 'solution_*.vtu' or 'solution-*.vtu'")
    sys.exit(1)

print(f"Opening database: {dbname_pf}")
OpenDatabase(dbname_pf)

for var in variables:
    print("Plotting variable: {}".format(var))

    # Delete previous plots before adding a new one
    DeleteAllPlots()

    # Add plot for the current variable
    AddPlot("Pseudocolor", var)
    DrawPlots()

    # Animate through time and save results
    for state in range(TimeSliderGetNStates()):
        # Set slider to state
        SetTimeSliderState(state)

        # Get the time corresponding to the state
        Query("Time")
        t = GetQueryOutputValue()

        print("Saving frame {}, time {:.1f} for variable {}".format(state, t, var))

        # Set save window attributes
        SaveWindowAtts = SaveWindowAttributes()
        SaveWindowAtts.fileName = "{}/data/images/{}_frame_{}".format(sim_dir, var, state)
        SetSaveWindowAttributes(SaveWindowAtts)
        SaveWindow()

# Cleanup
DeleteAllPlots()
CloseDatabase(dbname_pf)

sys.exit()
