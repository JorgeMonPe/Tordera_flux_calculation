#Library----
  library(tidyverse)
  library(goFlux)
  #Custom function to plot incubation start and end vertical lines, and CO2 and CH4 concentration at the same time
  source("https://raw.githubusercontent.com/JorgeMonPe/Functions_goflux_custom/refs/heads/main/my_functions_CO2CH4.R")

#Set TZ the default timezone to UTC----
Sys.setenv(TZ = "UTC")

#Set working directory----
folder_root <- "/home/jorge/Documentos/Postdoctoral/Onedrive_UB/UB/Tordera/2025_05_MAY" # Make sure this is the folder where you have information (rawdata and auxfile) for the campaign you want to analyse
setwd(folder_root)

#Folders----
  #The directory should contain 4 folder:
  #1. rawdata/ -> contains files downloaded from analyzers  
  #2. auxfile/ -> contains the auxiliary file  
  #3. Outputs/ -> where objects created during the workflow are saved  
  #4. Plots/ -> where output plots are saved

  #Folders 1 and 2 are mandatory; the others will be created if they do not exist

  #Rawdata
  folder_raw <- "rawdata" #contains raw files downloaded from licor
  #Auxfile
  folder_aux<- "auxfile" #contains raw files downloaded from licor
  
  #Folder for plots
  folder_plots <- file.path(getwd(), "Plots")
  if (!dir.exists(folder_plots)) {
    # If it doesn't exist, create the folder
    dir.create(folder_plots)
  }
  
  #Folder for outputs
  folder_outputs <- file.path(getwd(), "Outputs")
  if (!dir.exists(folder_outputs)) {
    # If it doesn't exist, create the folder
    dir.create(folder_outputs)
  }
  
#CO2 and CH4 raw file
  rawfiles<- list.files(path = folder_raw, pattern = "^TG10.*\\.data$")

#Import rawdata Licor CO2 adn CH4----
import.LI7810(inputfile = paste(folder_raw, rawfiles, sep = "/"),
             date.format = "ymd", keep_all = F,
             prec = c(3.5,0.6,45),
             save = TRUE)
load(paste0("RData/", list.files(path = "RData", pattern = "^LI7810.*\\.RData$")))

Licor <- data.raw

#Import auxfile-----
auxfile <- read_delim(paste0(folder_aux, "/aux_may.csv"), delim = ";")
auxfile <- auxfile %>% mutate(start.time = as.POSIXct(start.time, format = "%d/%m/%Y %H:%M", tz = "UTC"))

#Define observational window (end and start)----
  shoulder <- 90 #seconds
  incubation_length <- 300 #seconds
  #Define end and start
  ow.Licor7810 <- obs.win(Licor, auxfile, gastype = "CO2dry_ppm", obs.length = incubation_length, shoulder = shoulder)
  saveRDS(ow.Licor7810, "Outputs/ow.Licor7810.RDS")
#Plots----
#options(device = "x11") #Just for LINUX - I have to do this, if not, no windows will pop up to show you the plot where select the start and the end of the incubation
main.Licor1 <- click.peak_custom_CO2CH4(
  ow.Licor7810,
  gastype = "CO2dry_ppm",
  sleep = 3,
  plot.lim = c(200, 5000),
  seq = 1:20,
  warn.length = 60,
  save.plots = NULL
)
main.Licor2 <- click.peak_custom_CO2CH4(
  ow.Licor7810,
  gastype = "CO2dry_ppm",
  sleep = 3,
  plot.lim = c(200, 5000),
  seq = 21:40,
  warn.length = 60,
  save.plots = NULL
)
main.Licor3 <- click.peak_custom_CO2CH4(
  ow.Licor7810,
  gastype = "CO2dry_ppm",
  sleep = 3,
  plot.lim = c(200, 3000),
  seq = 41:45,
  warn.length = 60,
  save.plots = NULL
)

main.Licor <- main.Licor1 %>% bind_rows(main.Licor2) %>%
  bind_rows(main.Licor3)

# #Alternative: loop over 20 incubation----
# total <- length(ow.Licor7810)
# batch <- 20 #Number of incubation to process each time
# main.Licor <- data.frame()
# for (i in seq(1, total, by = batch)) {
#   first <- i
#   last <- i+batch-1
#   main.Licor1 <- click.peak_custom_CO2CH4(
#     ow.Licor7810,
#     gastype = "CO2dry_ppm",
#     sleep = 3,
#     plot.lim = c(200, 5000),
#     seq = first:last,
#     warn.length = 60,
#     save.plots = NULL
#   )
#   main.Licor <- main.Licor %>% bind_rows(main.Licor1)
# }

saveRDS(main.Licor, "Outputs/main.LicorCO2.RDS")

#Calculate the flux----
  ##CO2----
  CO2 <- goFlux(main.Licor, "CO2dry_ppm")
  CO2_best <- best.flux(CO2, criteria = c("MAE", "AICc", "g.factor", "MDF"), g.limit = 4)
  ##Save files----
  #CO2
  write_csv(CO2_best, "Outputs/CO2_flux_best.csv")
  write_csv(CO2, "Outputs/CO2_flux.csv")
  write_csv(main.Licor, "Outputs/main.Licor_CO2.csv")
  ##Save plots----
  #CO2
  CO2_plots <- flux.plot(CO2_best, main.Licor, "CO2dry_ppm", shoulder=20,
                         plot.legend = c("MAE", "RMSE", "AICc", "k.ratio", "g.factor"), 
                         plot.display = c("MDF", "prec", "nb.obs", "flux.term"), 
                         quality.check = TRUE)
  
  
  flux2pdf(CO2_plots, outfile = "Plots/CO2_plots.pdf")

  ##CH4----
  CH4 <- goFlux(main.Licor, "CH4dry_ppb")
  CH4_best <- best.flux(CH4, criteria = c("MAE", "AICc", "g.factor", "MDF"), g.limit = 4)

  ##Save files----
  #CH4
  write_csv(CH4_best, "Outputs/CH4_fux_best.csv")
  write_csv(CH4, "Outputs/CH4_flux.csv")
  write_csv(main.Picarro, "Outputs/main.Licor_CH4.csv")
  ##Save plots----
  #CH4
  CH4_plots <- flux.plot(CH4_best, main.Licor, "CH4dry_ppb", shoulder=20,
                         plot.legend = c("MAE", "RMSE", "AICc", "k.ratio", "g.factor"), 
                         plot.display = c("MDF", "prec", "nb.obs", "flux.term"), 
                         quality.check = TRUE)
  
  
  flux2pdf(CH4_plots, outfile = "Plots/CH4_flux.pdf")
