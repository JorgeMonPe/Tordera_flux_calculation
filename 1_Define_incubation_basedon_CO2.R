##Testing GoFLux package
library(tidyverse)
library(goFlux)
source("https://raw.githubusercontent.com/JorgeMonPe/Functions_goflux_custom/refs/heads/main/my_functions_CO2CH4.R")

#Set the default timezone to UTC
Sys.setenv(TZ = "UTC")

#Import rawdata Picarro----
import2RData(path = "rawdata", instrument = "LI-7810",
             date.format = "ymd", keep_all = F,
             prec = c(3.5,0.6,45))
load("RData/LI7810_TG10-01932-2025-05-05T000000_imp.RData")

Licor <- data.raw

#Import auxfile-----
auxfile <- read_delim("auxfile/aux_may.csv", delim = ";")
auxfile <- auxfile %>% mutate(start.time = as.POSIXct(start.time, format = "%d/%m/%Y %H:%M", tz = "UTC"))


#Define ow (end and start)----
  shoulder <- 90
#Define end and start
ow.Picarro <- obs.win(Licor, auxfile, gastype = "CO2dry_ppm", obs.length = 300, shoulder = shoulder)
saveRDS(ow.Picarro, "Outputs/ow.Picarro_Botanic.RDS")
#Plots----
#options(device = "x11") #Just for LINUX - I have to do this, if not, no windows will pop up to show you the plot where select the start and the end of the incubation
main.Picarro1 <- click.peak_custom_CO2CH4(
  ow.Picarro,
  gastype = "CO2dry_ppm",
  sleep = 3,
  plot.lim = c(200, 5000),
  seq = 1:20,
  warn.length = 60,
  save.plots = NULL
)
main.Picarro2 <- click.peak_custom_CO2CH4(
  ow.Picarro,
  gastype = "CO2dry_ppm",
  sleep = 3,
  plot.lim = c(200, 5000),
  seq = 21:40,
  warn.length = 60,
  save.plots = NULL
)
main.Picarro3 <- click.peak_custom_CO2CH4(
  ow.Picarro,
  gastype = "CO2dry_ppm",
  sleep = 3,
  plot.lim = c(200, 3000),
  seq = 41:45,
  warn.length = 60,
  save.plots = NULL
)

main.Licor <- main.Picarro1 %>% bind_rows(main.Picarro2) %>%
  bind_rows(main.Picarro3)

saveRDS(main.Licor, "main.LicorCO2.RDS")

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
