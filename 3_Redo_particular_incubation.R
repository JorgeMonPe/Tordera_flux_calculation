#N2O
#library----
  library(goFlux)
  library(tidyverse)
  #Custom function to plot incubation start and end vertical lines, and CO2 and CH4 concentration at the same time
  source("https://raw.githubusercontent.com/JorgeMonPe/Functions_goflux_custom/refs/heads/main/my_functions_CO2CH4.R")

#Set TZ the default timezone to UTC----
Sys.setenv(TZ = "UTC")

#Set working directory----
folder_root <- "/home/jorge/Documentos/Postdoctoral/Onedrive_UB/UB/Tordera/2025_05_MAY" # Make sure this is the folder where you have information (rawdata and auxfile) for the campaign you want to analyse
setwd(folder_root)

#Import CO2 observational windows
ow.Licor <- readRDS("Outputs/ow.Licor7810.RDS")
#Import original selection----
  old <- read_csv("Outputs/main.Licor_CO2.csv", col_types = cols(Species = col_character()))
  old <- old %>% mutate(DATE = as.character(DATE),
                        TIME = as.character(TIME))

#Now we redo just the incubation identified as "strange"----
#The position is not the same that the plot number (there is one repeated) so I have to extract the positions in the list.
  IDs <- do.call(rbind, ow.Licor) %>% summarise(UniqueID = unique(UniqueID))
  reanalyse_name <-c("Q3.6_50_May")
  reanalyse <- which(IDs$UniqueID %in% reanalyse_name)
#clic
options(device = "x11") #Just for LINUX - I have to do this, if not, no windows will pop up to show you the plot where select the start and the end of the incubation
main.Licor1 <- click.peak_custom_CO2CH4(
  ow.Licor,
  gastype = "CO2dry_ppm",
  sleep = 3,
  plot.lim = c(200, 5000),#c(200, 1000) para CO2 c(1900, 80000) para CH4
  seq = reanalyse,
  warn.length = 60,
  save.plots = NULL
)

#Now, replace the newone in the old file
main.Licor <- old %>% filter(!UniqueID %in% c(reanalyse_name))  %>% bind_rows(main.Licor1)

#Calculate the flux----
##CO2----
CO2 <- goFlux(main.Licor, "CO2dry_ppm")
CO2_best <- best.flux(CO2, criteria = c("MAE", "AICc", "g.factor", "MDF"), g.limit = 4)
##Save files----
#CO2
write_csv(CO2_best, "Outputs/CO2_flux_best_redone.csv")
write_csv(CO2, "Outputs/CO2_flux_redone.csv")
write_csv(main.Licor, "Outputs/main.Licor_CO2_redone.csv")
##Save plots----
#CO2
CO2_plots <- flux.plot(CO2_best, main.Licor, "CO2dry_ppm", shoulder=20,
                       plot.legend = c("MAE", "RMSE", "AICc", "k.ratio", "g.factor"), 
                       plot.display = c("MDF", "prec", "nb.obs", "flux.term"), 
                       quality.check = TRUE)


flux2pdf(CO2_plots, outfile = "Plots/CO2_plots_redone.pdf")

##CH4----
CH4 <- goFlux(main.Licor, "CH4dry_ppb")
CH4_best <- best.flux(CH4, criteria = c("MAE", "AICc", "g.factor", "MDF"), g.limit = 4)

##Save files----
#CH4
write_csv(CH4_best, "Outputs/CH4_fux_best_redone.csv")
write_csv(CH4, "Outputs/CH4_flux_redone.csv")
write_csv(main.Picarro, "Outputs/main.Licor_CH4_redone.csv")
##Save plots----
#CH4
CH4_plots <- flux.plot(CH4_best, main.Licor, "CH4dry_ppb", shoulder=20,
                       plot.legend = c("MAE", "RMSE", "AICc", "k.ratio", "g.factor"), 
                       plot.display = c("MDF", "prec", "nb.obs", "flux.term"), 
                       quality.check = TRUE)


flux2pdf(CH4_plots, outfile = "Plots/CH4_flux_redone.pdf")
