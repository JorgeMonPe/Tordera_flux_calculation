#Library----
  library(tidyverse)
  library(goFlux)
  library(hms)

#Set TZ the default timezone to UTC----
  Sys.setenv(TZ = "UTC")

#Set working directory----
  folder_root <- "/home/jorge/Documentos/Postdoctoral/Onedrive_UB/UB/Tordera/2025_05_MAY" # Make sure this is the folder where you have information (rawdata and auxfile) for the campaign you want to analyse
  setwd(folder_root)

  #Rawdata
  folder_raw <- "rawdata" #contains raw files downloaded from licor
  #Auxfile
  folder_aux<- "auxfile" #contains raw files downloaded from licor  
  
#Licor N2O
  #CO2 and CH4 raw file
  rawfiles<- list.files(path = folder_raw, pattern = "^TG20.*\\.data$")
  
  #Import rawdata Licor N2O----
  import.LI7820(inputfile = paste(folder_raw, rawfiles, sep = "/"),
                date.format = "ymd", keep_all = F,
                prec = c(0.4, 45),
                save = TRUE)
  load(paste0("RData/", list.files(path = "RData", pattern = "^LI7820.*\\.RData$")))
  
  Licor <- data.raw

  #Import auxfile-----
  auxfile <- read_delim(paste0(folder_aux, "/aux_may.csv"), delim = ";")
  auxfile <- auxfile %>% mutate(start.time = as.POSIXct(start.time, format = "%d/%m/%Y %H:%M", tz = "UTC"))
  
  #Time delay
  Delay <- 158 #seconds
  auxfile <- auxfile %>% mutate(start.time = start.time-Delay)
  
  #Define observational window (end and start)----
  shoulder <- 90 #seconds
  incubation_length <- 300 #seconds
  ow.Licor <- obs.win(Licor, auxfile, gastype = "N2Odry_ppb", obs.length = incubation_length, shoulder = shoulder)
  ow.Licor <- ow.Licor %>% bind_rows() %>% 
    mutate(DATE = as.Date(DATE),
           TIME.x = as_hms(TIME))
  
  #Import CO2 selection----
  main.Licor_CO2 <- read_csv("Outputs/main.Licor_CO2.csv")
  
  
  ow.Licor_filter <- ow.Licor %>%  select(any_of(c(colnames(main.Licor_CO2),"N2Odry_ppb","N2O_prec")))
  
  #Correct start and end time to use the time in Licor 7820
  main.Licor_selection <- main.Licor_CO2 %>% group_by(UniqueID) %>% slice_head(n = 1) %>% select(UniqueID, start.time_corr, end.time_corr) %>% 
    mutate(start.time_corr = start.time_corr-Delay, 
           end.time_corr = end.time_corr-Delay,
           obs.length_corr = as.numeric(end.time_corr - 
                                          start.time_corr, units = "secs"))

  main.Licor <- ow.Licor_filter %>% left_join(main.Licor_selection) %>% 
    mutate(flag = case_when(between(POSIX.time, start.time_corr, end.time_corr) ~ 1,
                            TRUE ~ 0),
           Etime = as.numeric(POSIX.time - start.time_corr))
  
  #Let's calculate the flux
  #NO2
  N2O <- goFlux(main.Licor, "N2Odry_ppb")
  N2O_best <- best.flux(N2O, criteria = c("MAE", "AICc", "g.factor", "MDF"), g.limit = 4)
  
  #Save files----
  write_csv(N2O_best, "Outputs/N2O_flux_best_CO2_selection.csv")
  write_csv(N2O, "Outputs/N2O_flux_CO2_selection.csv")
  write_csv(main.Licor, "Outputs/main.Licor_N2O_CO2_selection.csv")
  #Save plots----
  N2O_plots <- flux.plot(N2O_best, main.Licor, "N2Odry_ppb", shoulder=20,
                         plot.legend = c("MAE", "RMSE", "AICc", "k.ratio", "g.factor"), 
                         plot.display = c("MDF", "prec", "nb.obs", "flux.term"), 
                         quality.check = TRUE)
  
  flux2pdf(N2O_plots, outfile = "Plots/N2O_plots_CO2_selection.pdf")
  