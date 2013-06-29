library(shiny)
library(ggplot2)

source("Weather.R")

conn <- dbConnect(MySQL(), user = "root", password = "toorpassword", dbname = "forecast_analysis", host = "forecast-analysis.cjswh8fnvy2j.us-west-2.rds.amazonaws.com")

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
        return(readForecast(input$station, conn))
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
        return(paste("Displaying ", input$date_range[1], " to ", input$date_range[2], " forecast for ", input$station, " (", getStationName(input$station, conn), ")", sep = ""))
    })
    
    output$stationStabilityText <- renderText({
        return(paste("Displaying ", input$forecast_date, " forecast stability for ", input$station, " (", getStationName(input$station, conn), ")", sep = ""))
    })
    
    output$forecastTemp <- renderPlot({
        tbl <- forecastTable()
                        
        tbl$VTM <- tbl$DAT + hours(tbl$FHR)
        if (input$temperature == "High" & input$measure == "TMP") tbl <- subset(tbl, substr(VTM, 12, 16) == "00:00")
        if (input$temperature == "Low" & input$measure == "TMP") tbl <- subset(tbl, substr(VTM, 12, 16) == "12:00")
        
        tbl$DAT_fac <- factor(tbl$DAT)
        
        tbl <- subset(tbl, VTM >= as.POSIXct(input$date_range[1]) & VTM <= as.POSIXct(input$date_range[2]))
        
        thisPlot <- ggplot(tbl, aes_string(x = "VTM", y = input$measure, group = "DAT_fac", colour = "DAT_fac")) + 
            geom_line() +
            xlab("Valid Date for Forecast") +
            ylab(getMeasureName(input$measure))
        
        print(thisPlot)
    })
    
    output$stability <- renderPlot({
        tbl <- forecastTable()
        tbl$VTM <- tbl$DAT + hours(tbl$FHR)
        
        validTbl <- subset(tbl, VTM == as.POSIXct(paste(input$forecast_date, input$forecast_hour)))
        
        thisPlot <- ggplot(validTbl, aes_string(x = "DAT", y = input$measure)) + 
            geom_line() +
            xlab("Date of Forecast") +
            ylab(getMeasureName(input$measure))
        
        print(thisPlot)
    })
    
    output$extremesText <- renderText({
        return(paste("Displaying the top 10 and bottom 10 stations by average ", getMeasureName(input$measure), sep = ""))
    })
    
    output$extremes <- renderTable({
        dbTbl <- dbSendQuery(conn, paste("SELECT STA, AVG(", input$measure, ") FROM forecast WHERE ", input$measure, " < 150 GROUP BY STA ORDER BY AVG(", input$measure, ") DESC LIMIT 10", sep = ""))
        tbl <- fetch(dbTbl)
        
        station.names <- sapply(tbl$STA, getStationName, conn = conn)
        
        return(cbind(Name = station.names, tbl))
    }, include.rownames = FALSE)
    
    output$extremes_low <- renderTable({
        dbTbl <- dbSendQuery(conn, paste("SELECT STA, AVG(", input$measure, ") FROM forecast WHERE ", input$measure, " < 150 GROUP BY STA ORDER BY AVG(", input$measure, ") ASC LIMIT 10", sep = ""))
        tbl <- fetch(dbTbl)
        
        station.names <- sapply(tbl$STA, getStationName, conn = conn)
        
        return(cbind(Name = station.names, tbl))
    }, include.rownames = FALSE)
})

