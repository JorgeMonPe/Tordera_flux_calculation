#N2O bubbling interaction

#library
library(goFlux)
library(tidyverse)
source("https://raw.githubusercontent.com/JorgeMonPe/Functions_goflux_custom/refs/heads/main/my_functions_general.R")
#Set the default timezone to UTC
Sys.setenv(TZ = "UTC")
#Cargo el ow.Picarro
ow.Licor <- readRDS("Outputs/ow.Picarro_Botanic.RDS")
#Rehago los que quiero rehacer de CO2
old <- read_csv("Outputs/main.Licor_may_CO2.csv")
old <- old %>% mutate(DATE = as.character(DATE),
                      TIME = as.character(TIME))

#New ones
#The position is not the same that the plot number (there is one repeated) so I have to extract the positions in the list.
IDs <- do.call(rbind, ow.Licor) %>% summarise(UniqueID = unique(UniqueID))
reanalyse <-c("Q3.6_50_May")
reanalyse <- which(IDs$UniqueID %in% reanalyse)
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
main.Licor <- old %>% filter(!UniqueID %in% c("Q3.6_50_May"))  %>% bind_rows(main.Licor1)

#Calculate the flux----
##CO2----
CO2 <- goFlux(main.Licor, "CO2dry_ppm")
CO2_best <- best.flux(CO2, criteria = c("MAE", "AICc", "g.factor", "MDF"), g.limit = 4)
#When R2 is lower than 0.99 in HM flux, then I select LM
CO2_best <- CO2_best %>% mutate(best.flux = case_when(HM.r2 < 0.99 ~ LM.flux,
                                                      TRUE ~ best.flux),
                                model = case_when(HM.r2 < 0.99 ~ "LM",
                                                  TRUE ~ model),
                                quality.check = case_when(HM.r2 < 0.99 ~ paste(quality.check, "lowR2", sep = " | "),
                                                          TRUE ~ quality.check))
CO2_plots <- flux.plot(CO2_best, main.Licor, "CO2dry_ppm", shoulder=20,
                       plot.legend = c("MAE", "RMSE", "AICc", "k.ratio", "g.factor"), 
                       plot.display = c("MDF", "prec", "nb.obs", "flux.term"), 
                       quality.check = TRUE)


flux2pdf(CO2_plots, outfile = "Plots/May_CO2_1_45.pdf")
##Save files----
#CO2
write_csv(CO2_best, "Outputs/CO2_best_may.csv")
write_csv(CO2, "Outputs/CO2_may.csv")
write_csv(main.Licor, "Outputs/main.Licor_may_CO2.csv")

##CH4----
CH4 <- goFlux(main.Licor, "CH4dry_ppb")
CH4_best <- best.flux(CH4, criteria = c("MAE", "AICc", "g.factor", "MDF"), g.limit = 4)
#When R2 is lower than 0.99 in HM flux, then I select LM
CH4_best <- CH4_best %>% mutate(best.flux = case_when(HM.r2 < 0.99 ~ LM.flux,
                                                      TRUE ~ best.flux),
                                model = case_when(HM.r2 < 0.99 ~ "LM",
                                                  TRUE ~ model),
                                quality.check = case_when(HM.r2 < 0.99 ~ paste(quality.check, "lowR2", sep = " | "),
                                                          TRUE ~ quality.check))
CH4_plots <- flux.plot(CH4_best, main.Licor, "CH4dry_ppb", shoulder=20,
                       plot.legend = c("MAE", "RMSE", "AICc", "k.ratio", "g.factor"), 
                       plot.display = c("MDF", "prec", "nb.obs", "flux.term"), 
                       quality.check = TRUE)


flux2pdf(CH4_plots, outfile = "Plots/Licor_may_CH4_1-45.pdf")

##Save files----
#CH4
write_csv(CH4_best, "Outputs/CH4_best_Botanic.csv")
write_csv(CH4, "Outputs/CH4_Botanic.csv")
write_csv(main.Picarro, "Outputs/main.Picarro_Botanic_CH4.csv")
