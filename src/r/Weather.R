library(XML)
library(RMySQL)
library(lubridate)
library(plyr)
library(RCurl)

getForecastTable <- function(station) {
    ## Grab the data
    webpage <- getURL(paste("http://www.nws.noaa.gov/cgi-bin/mos/getmex.pl?sta=", station, sep = ""))
    webpage <- readLines(tc <- textConnection(webpage)); close(tc)
    
    ## Choose only the relevant lines
    date.text <- webpage[6]
    forecast.text <- webpage[c(7, 9:13, 15, 17)]
    
    ## Parse the date
    fixed.date <- strsplit(date.text, split = " ")[[1]]
    fixed.date <- fixed.date[-which(fixed.date == "")]
    forecast.date.temp <- paste(fixed.date[5:6], collapse = " ")
    forecast.date <- as.POSIXct(strptime(forecast.date.temp, format = "%m/%d/%Y %H%M"))
    
    ## Strip out unwanted characters
    fixed <- strsplit(forecast.text, split = " |\\|")
    fixed.list <- lapply(1:length(forecast.text), function(x){fixed[[x]][-which(fixed[[x]] %in% c(""))]})
    final.list <- lapply(fixed.list, function(col){col[2:16]})
    
    ## Convert to a data frame
    table.names <- unlist(lapply(fixed.list, function(col){col[1]}))
    forecast.table <- data.frame(final.list)
    names(forecast.table) <- table.names
    forecast.table[,1:ncol(forecast.table)] <- sapply(forecast.table[,1:ncol(forecast.table)], function(x){as.numeric(as.character(x))})
    
    ## Add Date
    final.table <- cbind(STA = station, DAT = rep(forecast.date, 15), forecast.table)
    
    return(final.table)
}

writeToDB <- function(tbl, conn) {
    dbWriteTable(conn, "forecast", tbl, row.names = FALSE, append = TRUE)
}


writeForecast <- function(station, conn) {
    tbl <- getForecastTable(station)
    writeToDB(tbl, conn)
}

readForecast <- function(station = "", conn) {    
    dbTbl <- dbReadTable(conn, "forecast")
    #dbTbl$DAT <- as.POSIXct(dbTbl$DAT)
    #dbTbl$STA <- factor(dbTbl$STA)
    
    if (station == "") station <- unique(dbTbl$STA)
    
    return(subset(dbTbl, STA == station))
}