library(shiny)
library(ggplot2)
library(plyr)

source("Weather.R")

#conn <- dbConnect(MySQL(), user = "root", password = "toorpassword", dbname = "forecast_analysis", host = "forecast-analysis.cjswh8fnvy2j.us-west-2.rds.amazonaws.com")

getMeasureName <- function(measure) {
    if (measure == "TMP") {
        return("Temperature (F)")
    } else if (measure == "DPT") {
        return("Dew Point")
    } else if (measure == "WND") {
        return("Wind (MPH)")
    } else if (measure == "P12") {
        return("Chance of Precipitation (12 Hours)")
    } else if (measure == "Q12") {
        return("Total Precipitation (12 Hours)")
    } else if (measure == "T12") {
        return("Chance of Thunderstorms (12 Hours)")
    } else {
        return("")
    }
}

# Define server logic required to summarize and view the selected dataset
shinyServer(function(input, output) {
    # Show the first "n" observations
    
    forecastTable <- reactive({
        return(readForecast(input$station, input$date_range[1], input$date_range[2]))
    })
    
    output$viewForecast <- renderTable({
        tbl <- forecastTable()
        
        tbl$VTM <- tbl$DAT + hours(tbl$FHR)
        tbl$DAT <- as.character(tbl$DAT)
        
        validTbl <- subset(tbl, VTM >= as.POSIXct(input$date_range[1]) & VTM <= as.POSIXct(input$date_range[2]))
        validTbl$VTM <- as.character(validTbl$VTM)
        
        return(validTbl[,-1])
    }, include.rownames = FALSE)
    
    output$viewStability <- renderTable({
        tbl <- forecastTable()
        
        tbl$VTM <- tbl$DAT + hours(tbl$FHR)
        tbl$DAT <- as.character(tbl$DAT)
        
        validTbl <- subset(tbl, VTM == as.POSIXct(paste(input$forecast_date, input$forecast_hour)))
        validTbl$VTM <- as.character(validTbl$VTM)
        
        return(validTbl[,-1])
    }, include.rownames = FALSE)
    
    output$stationForecastText <- renderText({
        return(paste("Displaying ", input$date_range[1], " to ", input$date_range[2], " forecast for ", input$station, " (", getStationName(input$station), ")", sep = ""))
    })
    
    output$stationStabilityText <- renderText({
        return(paste("Displaying ", input$forecast_date, " forecast stability for ", input$station, " (", getStationName(input$station), ")", sep = ""))
    })
    
    output$forecastPlot <- renderPlot({
        tbl <- forecastTable()
        
        tbl$VTM <- tbl$DAT + hours(tbl$FHR)
        if (input$temperature == "High" & input$measure == "TMP") tbl <- subset(tbl, substr(VTM, 12, 16) == "00:00")
        if (input$temperature == "Low" & input$measure == "TMP") tbl <- subset(tbl, substr(VTM, 12, 16) == "12:00")
        
        tbl$DAT_fac <- factor(tbl$DAT)
        
        tbl <- subset(tbl, VTM >= as.POSIXct(input$date_range[1]) & VTM <= as.POSIXct(input$date_range[2]))
        
        if (input$means) {
            newData <- ddply(tbl, .(VTM), summarise, TMP = mean(TMP, na.rm = TRUE), DPT = mean(DPT, na.rm = TRUE), WND = mean(WND, na.rm = TRUE), P12 = mean(P12, na.rm = TRUE), Q12 = mean(Q12, na.rm = TRUE), T12 = mean(T12, na.rm = TRUE))
            thisPlot <- ggplot(newData, aes_string(x = "VTM", y = input$measure)) + 
                geom_line(size = 1.5) +
                geom_point(size = 3) +
                xlab("Valid Date for Forecast") +
                ylab(paste("Average", getMeasureName(input$measure))) +
                theme_bw() +
                theme(legend.position = "off")
        } else {
            thisPlot <- ggplot(tbl, aes_string(x = "VTM", y = input$measure, group = "DAT_fac", colour = "DAT_fac")) + 
                geom_line(size = 1.5) +
                geom_point(size = 3) +
                xlab("Valid Date for Forecast") +
                ylab(getMeasureName(input$measure)) + 
                theme_bw() +
                theme(legend.position = "off")
        }
        
        print(thisPlot)
    })
    
    output$stability <- renderPlot({
        tbl <- forecastTable()
        tbl$VTM <- tbl$DAT + hours(tbl$FHR)
        
        validTbl <- subset(tbl, VTM == as.POSIXct(paste(input$forecast_date, input$forecast_hour)))
        
        thisPlot <- ggplot(validTbl, aes_string(x = "DAT", y = input$measure)) + 
            geom_line(size = 1.5) +
            geom_point(size = 3) +
            xlab("Date of Forecast") +
            ylab(getMeasureName(input$measure)) +
            theme_bw()
        
        print(thisPlot)
    })
    
    output$extremesText <- renderText({
        return(paste("Displaying the top 10 and bottom 10 stations by average ", getMeasureName(input$measure), sep = ""))
    })
    
    output$extremes <- renderTable({
        
        conn <- dbConnect(MySQL(), user = "root", password = "toorpassword", dbname = "forecast_analysis", host = "forecast-analysis.cjswh8fnvy2j.us-west-2.rds.amazonaws.com")
        
        
        dbTbl <- dbSendQuery(conn, paste("SELECT STA, AVG(", input$measure, ") FROM forecast WHERE DAT BETWEEN '", as.character(as.POSIXct(input$date_range[1]) - days(7)), "' AND '", input$date_range[1], "' AND  ", input$measure, " < 150 GROUP BY STA ORDER BY AVG(", input$measure, ") DESC LIMIT 10", sep = ""))
        tbl <- fetch(dbTbl)
        
        station.names <- sapply(tbl$STA, getStationName)
        
        dbDisconnect(conn)
        
        return(cbind(Name = station.names, tbl))
    }, include.rownames = FALSE)
    
    output$extremes_low <- renderTable({
        
        conn <- dbConnect(MySQL(), user = "root", password = "toorpassword", dbname = "forecast_analysis", host = "forecast-analysis.cjswh8fnvy2j.us-west-2.rds.amazonaws.com")
        
        dbTbl <- dbSendQuery(conn, paste("SELECT STA, AVG(", input$measure, ") FROM forecast WHERE DAT BETWEEN '", as.character(as.POSIXct(input$date_range[1]) - days(7)), "' AND '", input$date_range[2], "'  AND ", input$measure, " < 150 GROUP BY STA ORDER BY AVG(", input$measure, ") ASC LIMIT 10", sep = ""))
        tbl <- fetch(dbTbl)
        
        station.names <- sapply(tbl$STA, getStationName)
        
        dbDisconnect(conn)
        
        return(cbind(Name = station.names, tbl))
    }, include.rownames = FALSE)
})

