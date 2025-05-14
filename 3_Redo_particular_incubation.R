#Library
library(tidyverse)
library(goFlux)
library(hms)

#Set the default timezone to UTC
Sys.setenv(TZ = "UTC")

#Licor
import2RData(path = "rawdata_N2O", instrument = "LI-7820",
             date.format = "ymd", keep_all = F,
             prec = c(0.4, 45))
load("RData/LI7820_TG20-01377-2025-05-06T000000_imp.RData")
Licor <- data.raw


##------Enees----------
  #Import auxfile-----
  auxfile <- read_delim("auxfile/aux_may.csv", delim = ";")
  auxfile <- auxfile %>% mutate(start.time = as.POSIXct(start.time, format = "%d/%m/%Y %H:%M", tz = "UTC"))
  auxfile <- auxfile %>% mutate(start.time = start.time-158)
  
  #Define end and start
  ow.Licor <- obs.win(Licor, auxfile, gastype = "N2Odry_ppb", obs.length = 300, shoulder = 180)
  ow.Licor <- ow.Licor %>% bind_rows() %>% 
    mutate(DATE = as.Date(DATE),
           TIME.x = as_hms(TIME))
  
  #Import Picarro 
  #Import main CO2 for Enees
  main.Licor_CO2 <- read_csv("Outputs/main.Licor_may_CO2.csv")
  
  
  ow.Licor_filter <- ow.Licor %>%  select(any_of(c(colnames(main.Licor_CO2),"N2Odry_ppb","N2O_prec")))
  
  main.Picarro_selection <- main.Licor_CO2 %>% group_by(UniqueID) %>% slice_head(n = 1) %>% select(UniqueID, start.time_corr, end.time_corr) %>% 
    mutate(start.time_corr = start.time_corr-158, 
           end.time_corr = end.time_corr-158,
           obs.length_corr = as.numeric(end.time_corr - 
                                          start.time_corr, units = "secs"))
  #if I have enough points I will remove 10 secs at the begining and at the end
  main.Picarro_selection <- main.Picarro_selection %>% mutate(start.time_corr = case_when(obs.length_corr >= 180 ~  start.time_corr+10,
                                                                TRUE ~ start.time_corr),
                                    end.time_corr = case_when(obs.length_corr >= 180 ~ end.time_corr-10,
                                                              TRUE ~ end.time_corr))
  
  main.Licor <- ow.Licor_filter %>% left_join(main.Picarro_selection) %>% 
    mutate(flag = case_when(between(POSIX.time, start.time_corr, end.time_corr) ~ 1,
                            TRUE ~ 0),
           Etime = as.numeric(POSIX.time - start.time_corr))
  
  #Let's calculate the flux
  #NO2
  N2O <- goFlux(main.Licor, "N2Odry_ppb")
  N2O_best <- best.flux(N2O, criteria = c("MAE", "AICc", "g.factor", "MDF"), g.limit = 4)
  #When R2 is lower than 0.99 in HM flux, then I select LM
  N2O_best <- N2O_best %>% mutate(best.flux = case_when(HM.r2 < 0.99 ~ LM.flux,
                                                        TRUE ~ best.flux),
                                  model = case_when(HM.r2 < 0.99 ~ "LM",
                                                    TRUE ~ model),
                                  quality.check = case_when(HM.r2 < 0.99 ~ paste(quality.check, "lowR2", sep = " | "),
                                                            TRUE ~ quality.check))
  N2O_plots <- flux.plot(N2O_best, main.Licor, "N2Odry_ppb", shoulder=20,
                         plot.legend = c("MAE", "RMSE", "AICc", "k.ratio", "g.factor"), 
                         plot.display = c("MDF", "prec", "nb.obs", "flux.term"), 
                         quality.check = TRUE)
  
  flux2pdf(N2O_plots, outfile = "Plots/May_N2O_1_45_CO2_selection.pdf")
  
  #Save files
  write_csv(N2O_best, "Outputs/N2O_bests_CO2_selection.csv")
  write_csv(N2O, "Outputs/N2O_CO2_selection.csv")
  write_csv(main.Licor, "Outputs/main.Licor_CO2_selection.csv")
  