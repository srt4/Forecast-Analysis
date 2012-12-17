library(XML)
library(RMySQL)
library(ggplot2)
library(lubridate)
library(plyr)

url <- "http://wxweb.meteostar.com/sample/sample.shtml?text=ksea"
tbl <- readHTMLTable(url)

tbl1 <- tbl[1]$'NULL'[,-1]
nms <- sapply(tbl1[9,], as.character)
weather.data <- tbl1[-(1:9),]
names(weather.data) <- nms

normal.data <- weather.data[1:60, -2]
extended.data <- weather.data[65:81, -ncol(weather.data)]
names(extended.data) <- names(normal.data)
weather.data <- rbind(normal.data, extended.data)

## Convert all temperatures to ints
for (i in c(2, 3, 4, 12, 13, 14)) {
    temps <- unlist(strsplit(as.character(weather.data[,i]), split = " "))
    odds <- (1:length(temps) %% 2 == 1)
    weather.data[,i] <- as.numeric(temps[odds])
}

forecast.time <- substring(strsplit(as.character(tbl[4]$'NULL'$V1[2]), "\n")[[1]][5], 11, 24)
forecast.time <- gsub("Z", ":00:00 UTC", forecast.time)

valid.time <- unlist(strsplit(gsub("Z", ":00:00", weather.data$ValidTime), split = " "))

ind1 <- (1:length(valid.time) %% 3 == 2)
ind2 <- (1:length(valid.time) %% 3 == 0)
    
months <- unlist(strsplit(valid.time[ind1], split = "/"))
ind3 <- (1:length(months) %% 2 == 1)
months <- as.numeric(months[ind3])

## Edge Case: First month 12, Last month 1
yearList <- rep(year(Sys.Date()), times = length(months))
if (months[1] == 12 & months[length(months)] == 1) {
    yearList[which(months == 1)] <- year(Sys.Date()) + 1
}
    
valid.time <- paste(valid.time[ind1], "/", yearList, " ", valid.time[ind2], sep = "")
weather.data$ValidTime <- as.POSIXct(valid.time, format = "%m/%d/%Y %H:%M:%S")
weather.data$`500-1000THKNS` <- as.numeric(as.character(weather.data$`500-1000THKNS`))
weather.data$`TotalPrecip(")` <- as.numeric(as.character(weather.data$`TotalPrecip(")`))

time <- as.POSIXct(forecast.time, format = "%m/%d/%Y %H:%M:%S")
weather.data <- cbind(time, weather.data)
drv <- dbDriver("MySQL")
co <- dbConnect(drv, user = "minecraft", password = "toor", port = 6033, dbname = "gfsforecasts", host = "spencerrthomas.com")

dbMaxTime <- dbGetQuery(co, "SELECT max(time) FROM Forecasts")[1,1]
dbTemps <- dbGetQuery(co, paste("SELECT `MaxTemp__F` FROM Forecasts WHERE time =", "'", dbMaxTime, "'", sep = ""))
if (!is.na(dbMaxTime) & dbMaxTime >= time) {
    print(paste("Have already scraped data for", time))
} else if (!is.na(dbMaxTime) & all(weather.data$`MaxTemp °F` == dbTemps)) {
    print(paste("Server fails us: Have already scraped data for", time))
} else {
    dbWriteTable(co, "Forecasts", weather.data, append = TRUE, row.names = FALSE)
    print(paste("Successfully scraped data for", time))
}

weather.data <- dbReadTable(co, "Forecasts")
weather.data$ValidTime <- as.POSIXct(weather.data$ValidTime)
weather.data$TotalPrecip___ <- as.numeric(weather.data$TotalPrecip___)

addHour <- function(x) {
    xcpy <- x
    if (length(xcpy) == 1) {
        xcpy <- paste(xcpy, "00:00:00")
    } else {
        xcpy <- paste(xcpy, collapse = " ")
    }
    return(xcpy)
}

checkHour <- strsplit(weather.data$time, split = " ")
checkHour1 <- sapply(checkHour, addHour)
weather.data$FormattedTime <- as.POSIXct(checkHour1, format = "%Y-%m-%d %H:%M:%S")

qplot(ValidTime, `MaxTemp__F`, data = weather.data, colour = time, geom = "line", fill = time, group = time, alpha = time) + 
    geom_hline(yintercept = 32) + 
    #geom_ribbon(alpha = 0.4, aes(fill = time, ymin = min(`MinTemp__F`) - 2, ymax = `MaxTemp__F`)) +
    geom_point()

qplot(ValidTime, `MaxTemp__F`, data = weather.data, geom = "smooth", group = time, colour = time, alpha = time) + 
    geom_hline(yintercept = 32) +
    scale_alpha_discrete(range = c(0, .8))

qplot(ValidTime, `MaxTemp__F`, data = weather.data, geom = "line", fill = time, group = time, alpha = time, size = time, colour = time) + 
    geom_hline(yintercept = 32) +
    scale_size_discrete(range = c(.5, 2)) +
    #geom_ribbon(alpha = 0.4, aes(fill = time, ymin = min(`MinTemp__F`) - 2, ymax = `MaxTemp__F`)) +
    geom_point(colour = I("black")) +
    geom_smooth(linetype = 3, alpha = .15)

qplot(ValidTime, `MaxTemp__F`, data = subset(weather.data, FormattedTime >= as.POSIXct(dbMaxTime) - (60 * 60 * 36)), geom = "line", fill = time, group = time, alpha = time, size = time, colour = time) + 
    geom_hline(yintercept = 32) +
    scale_size_discrete(range = c(.5, 2)) +
    #geom_ribbon(alpha = 0.4, aes(fill = time, ymin = min(`MinTemp__F`) - 2, ymax = `MaxTemp__F`)) +
    geom_point(colour = I("black")) +
    geom_smooth(linetype = 3, alpha = .15)

qplot(ValidTime, `TotalPrecip___`, data = subset(weather.data, FormattedTime >= as.POSIXct(dbMaxTime) - (60 * 60 * 36)), geom = "line", fill = time, group = time, alpha = time, size = time, colour = time) + 
    geom_hline(yintercept = 0) +
    scale_size_discrete(range = c(.5, 2)) +
    #geom_ribbon(alpha = 0.4, aes(fill = time, ymin = min(`MinTemp__F`) - 2, ymax = `MaxTemp__F`)) +
    geom_point(colour = I("black")) +
    geom_smooth(linetype = 3, alpha = .15)

maxmin.sub <- ddply(weather.data, .(Day = day(ValidTime)), summarise, MinTemp = min(MaxTemp__F), MaxTemp = max(MaxTemp__F))
qplot(Day, MinTemp, data = maxmin.sub, geom = "line") + 
    geom_line(aes(Day, MaxTemp)) +
    geom_ribbon(aes(ymin = MinTemp, ymax = MaxTemp))

# Get only days which are in all the models
weather.sub <- subset(weather.data, as.POSIXct(time) >= max(FormattedTime) - (60 * 60 * 24))
summary.weather <- ddply(weather.sub, .(ValidTime), summarise, MeanMaxTemp = mean(MaxTemp__F), MeanPrecip = mean(TotalPrecip___), sdMaxTemp = sd(MaxTemp__F))
qplot(ValidTime, MeanMaxTemp, data = summary.weather, geom = "line") +
    geom_hline(yintercept = 32) +
    geom_point(colour = I("black")) +
    geom_smooth(linetype = 3, alpha = .15)

qplot(ValidTime, MeanPrecip, data = summary.weather, geom = "line") +
    geom_hline(yintercept = 0) +
    geom_point(colour = I("black")) +
    geom_smooth(linetype = 3, alpha = .15)