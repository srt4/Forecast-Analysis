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
    date.text <- webpage[grep("UTC", webpage)]
    forecast.text <- webpage[grep("FHR|TMP|DPT|WND|P12|Q12|T12", webpage)]
    
    ## Parse the date
    fixed.date <- strsplit(date.text, split = " ")[[1]]
    fixed.date <- fixed.date[-which(fixed.date == "")]
    forecast.date.temp <- paste(fixed.date[5:6], collapse = " ")
    forecast.date <- as.POSIXct(strptime(forecast.date.temp, format = "%m/%d/%Y %H%M"), tz = "GMT")
    
    ## Strip out unwanted characters
    fixed <- strsplit(forecast.text, split = " |\\|")
    fixed.list <- lapply(1:length(forecast.text), function(x){fixed[[x]][-which(fixed[[x]] %in% c(""))]})
    final.list.tmp <- lapply(fixed.list, function(col){col[-1]})
    
    ## Truncate to 15
    final.list <- lapply(final.list.tmp, function(col){
        if (length(col) > 15) col[1:15]
        else if (length(col) < 15) c(col, rep(NA, 15 - length(col)))
        else col
    })
    
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