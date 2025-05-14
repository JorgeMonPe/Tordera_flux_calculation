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

## Setup Instructions:

To use this workflow, follow these steps:
  
  1. **Download the repository:**
  - It is recommended to clone the repository using SSH.

  - Alternatively, you can download the repository manually as a ZIP file from GitHub and extract it into a folder on your computer.

2. **Software Requirements:**
  - You need to have **RStudio** and **Git** installed on your computer. 
- A **GitHub account** is required if you want to clone the repository using SSH or push changes directly from Rstudio.

**For more information on how to connect and work with RStudio and GitHub, you can visit the following link:

[Happy Git with R - RStudio, Git, and GitHub](https://happygitwithr.com/rstudio-git-github.html)

3. **Set the working directory:**
  - Define the path to your working directory by setting the variable `folder_root` in the scripts. This directory should contain the data and auxfile for the specific campaign you are analyzing.
- To analyze data from different campaigns, simply change the `folder_root` path to point to the folder where the data for the new campaign is stored.

By setting `folder_root`, you make the workflow adaptable to different data campaigns, and it simplifies the process of switching between projects.