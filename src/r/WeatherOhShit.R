library(XML)
library(RMySQL)
library(ggplot2)
library(lubridate)
library(plyr)

getCurrentData <- function() {
    url <- "http://wxweb.meteostar.com/sample/sample.shtml?text=ksea"
    tbl <- readHTMLTable(url)
    
    tbl1 <- tbl[1]$'NULL'[,-1]
    nms <- sapply(tbl1[9,], as.character)
    weather.data <- tbl1[-(1:9),]
    names(weather.data) <- nms
    
    return(weather.data)
}

url <- "http://wxweb.meteostar.com/sample/archive.shtml?text=KSEA&run=2012121006"
tbl <- readHTMLTable(url)

curData <- getCurrentData()

tbl1 <- tbl[1]$'NULL'[,-1]
nms <- sapply(tbl1[3,], as.character)
weather.data <- tbl1[-(1:3),]
names(weather.data) <- nms

normal.data <- weather.data[1:60, -2]
extended.data <- weather.data[65:81, -ncol(weather.data)]

# Get missing columns
normal.data <- cbind(normal.data[,1:5], rep(NA, nrow(normal.data)), normal.data[,6:10], normal.data[,12], normal.data[,11], rep(NA, nrow(normal.data)), normal.data[,13:14])
names(normal.data) <- names(curData)[-2]

extended.data <- cbind(extended.data[,1:5], rep(NA, nrow(extended.data)), extended.data[,6:10], extended.data[,12], extended.data[,11], rep(NA, nrow(extended.data)), extended.data[,13:14])
names(extended.data) <- names(normal.data)
weather.data <- rbind(normal.data, extended.data)

## Convert all temperatures to ints
for (i in c(2, 3, 4, 12, 13)) {
    temps <- unlist(strsplit(as.character(weather.data[,i]), split = " "))
    odds <- (1:length(temps) %% 2 == 1)
    weather.data[,i] <- as.numeric(temps[odds])
}

###
### TYPE MANUALLY
###
forecast.time <- "12/10/2012 06:00:00 UTC"

valid.time <- unlist(strsplit(gsub("Z", ":00:00", weather.data$ValidTime), split = " "))
ind1 <- (1:length(valid.time) %% 3 == 2)
ind2 <- (1:length(valid.time) %% 3 == 0)
valid.time <- paste(valid.time[ind1], "/", year(Sys.Date()), " ", valid.time[ind2], sep = "")
weather.data$ValidTime <- as.POSIXct(valid.time, format = "%m/%d/%Y %H:%M:%S")
weather.data$`500-1000THKNS` <- as.numeric(as.character(weather.data$`500-1000THKNS`))
weather.data$`TotalPrecip(")` <- as.numeric(as.character(weather.data$`TotalPrecip(")`))

time <- as.POSIXct(forecast.time, format = "%m/%d/%Y %H:%M:%S")
weather.data <- cbind(time, weather.data)
drv <- dbDriver("MySQL")
co <- dbConnect(drv, user = "minecraft", password = "toor", port = 6033, dbname = "gfsforecasts", host = "spencerrthomas.com")

dbWriteTable(co, "Forecasts", weather.data, append = TRUE, row.names = FALSE)
print(paste("Successfully scraped data for", time))

weather.data <- dbReadTable(co, "Forecasts")
weather.data$ValidTime <- as.POSIXct(weather.data$ValidTime)
weather.data$TotalPrecip___ <- as.numeric(weather.data$TotalPrecip___)

weather.data$FormattedTime <- as.POSIXct(weather.data$time, format = "%Y-%m-%d %H:%M:%S")