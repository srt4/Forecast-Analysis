.libPaths("/home/erichare/R/x86_64-pc-linux-gnu-library/3.0")

source("Weather.R", chdir = TRUE)

## Hack
stations.list.temp <- read.csv("../../stations.csv")
stations.list <- names(stations.list.temp)

## DB Loop
conn <- dbConnect(MySQL(), user = "root", password = "toorpassword", dbname = "forecast_analysis", host = "forecast-analysis.cjswh8fnvy2j.us-west-2.rds.amazonaws.com")

lapply(1:length(stations.list), 
       function(i) {
           sta <- stations.list[i]
           cat(paste("Processing Station ", sta, " (", i, "/", length(stations.list), ")\n", sep = ""))
           try(writeForecast(sta, conn = conn))
       })
    
