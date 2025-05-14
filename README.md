# Project Workflow: Incubation Analysis

This project is structured to process incubation data from Licor gas analyzers (Li-7810 and Li-7820). Below is a description of the folder structure and the purpose of the scripts used in the workflow.

## Folder Structure:

### Mandatory:
1. **rawdata/**
   - Contains raw files downloaded directly from the analyzers.

2. **auxfile/**
   - Stores auxiliary files needed to calculate fluxes (temperature, pressure, volume, surface, etc.).

### These will be created if they are not present in the working directory:
3. **Outputs/**
   - Where objects generated throughout the workflow are saved (e.g., R objects, processed data).

4. **Plots/**
   - Contains output plots used to visualize the fits.

## Scripts:

1. **1_define_incubations_CO2.R**
   - This script is used to manually define the start and end of incubations based on the CO₂ concentration plots. The user selects the appropriate regions for each incubation.
   - Both CO₂ and CH₄ fluxes are calculated based on the CO₂ selection.

2. **2_define_incubations_N2O.R**
   - This script defines N₂O incubation periods using the regions previously selected for CO₂. It assumes that N₂O incubations are aligned with the same time windows.
   - **Be careful!!!** You **must** specify the time delay between analyzers.

3. **3_edit_selected_incubations.R**
   - Use this script to manually adjust or correct specific incubations that require further modification after the initial selection.
