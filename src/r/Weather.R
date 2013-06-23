library(XML)
library(RMySQL)
library(ggplot2)
library(lubridate)
library(plyr)
library(RCurl)

getForecastTable <- function(station) {
    ## Grab the data
    webpage <- getURL(paste("http://www.nws.noaa.gov/cgi-bin/mos/getmex.pl?sta=", station, sep = ""))
    webpage <- readLines(tc <- textConnection(webpage)); close(tc)
    
    ## Choose only the relevant lines
    forecast.text <- webpage[c(7, 9:13)]
    
    ## Strip out unwanted characters
    fixed <- strsplit(forecast.text, split = " |\\|")
    fixed.list <- lapply(1:length(forecast.text), function(x){fixed[[x]][-which(fixed[[x]] %in% c(""))]})
    final.list <- lapply(fixed.list, function(col){col[2:16]})
    
    ## Convert to a data frame
    table.names <- unlist(lapply(fixed.list, function(col){col[1]}))
    forecast.table <- data.frame(final.list)
    names(forecast.table) <- table.names
    forecast.table[,1:ncol(forecast.table)] <- sapply(forecast.table[,1:ncol(forecast.table)], function(x){as.numeric(as.character(x))})
    
    return(forecast.table)
}