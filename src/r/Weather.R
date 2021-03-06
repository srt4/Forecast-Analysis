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
    date.text <- webpage[grep(" UTC ", webpage)]
    forecast.text.tmp <- webpage[grep(" FHR | X/N | N/X | TMP | DPT | WND | P12 | Q12 | T12 ", webpage)]
    forecast.text <- gsub(" N/X | X/N ", " HLT ", forecast.text.tmp)
    
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


writeForecast <- function(station, conn = NULL) {
    closeConn <- FALSE
    if (is.null(conn)) {
        closeConn <- TRUE
        conn <- dbConnect(MySQL(), user = "root", password = "toorpassword", dbname = "forecast_analysis", host = "forecast-analysis.cjswh8fnvy2j.us-west-2.rds.amazonaws.com")
    }
    tbl <- getForecastTable(station)
    writeToDB(tbl, conn)

    if (closeConn) {
        dbDisconnect(conn)
    }
}

getStationName <- function(station) {
    conn <- dbConnect(MySQL(), user = "root", password = "toorpassword", dbname = "forecast_analysis", host = "forecast-analysis.cjswh8fnvy2j.us-west-2.rds.amazonaws.com")
    
    dbTbl <- dbSendQuery(conn, paste("SELECT description FROM stations WHERE STA = '", station, "'", sep = ""))
    
    returnTable <- fetch(dbTbl)

    dbDisconnect(conn)    

    if (is.null(returnTable[1,1])) {
        return("Station Name Unknown")
    } else {
        return(returnTable[1,1])
    }
}

readForecast <- function(station, startdate, enddate) {    
    conn <- dbConnect(MySQL(), user = "root", password = "toorpassword", dbname = "forecast_analysis", host = "forecast-analysis.cjswh8fnvy2j.us-west-2.rds.amazonaws.com")
    
    dbTbl <- dbSendQuery(conn, paste("SELECT * FROM forecast WHERE DAT BETWEEN '", as.character(as.POSIXct(startdate) - days(10)), "' AND '", enddate, "' AND STA = '", station, "'", sep = ""))
    
    returnTable <- fetch(dbTbl)
    returnTable$DAT <- as.POSIXct(returnTable$DAT)
    returnTable$STA <- factor(returnTable$STA)
    
    dbDisconnect(conn)

    return(returnTable)
}
