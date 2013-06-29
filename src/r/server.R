library(shiny)
library(ggplot2)

source("Weather.R")

conn <- dbConnect(MySQL(), user = "root", password = "toorpassword", dbname = "forecast_analysis", host = "forecast-analysis.cjswh8fnvy2j.us-west-2.rds.amazonaws.com")

# Define server logic required to summarize and view the selected dataset
shinyServer(function(input, output) {
    # Show the first "n" observations
    
    forecastTable <- reactive({
        return(readForecast(input$station, conn))
    })
    
    output$view <- renderTable({
        tbl <- forecastTable()
        tbl$DAT <- as.character(tbl$DAT)        
        
        return(Name = station.names, tbl)
    })
    
    output$stationText <- renderText({
        return(paste("Displaying results for ", input$station, " (", getStationName(input$station, conn), ")" sep = ""))
    })
    
    output$forecastTemp <- renderPlot({
        tbl <- forecastTable()
                        
        tbl$VTM <- tbl$DAT + hours(tbl$FHR)
        if (input$temperature == "High" & input$measure == "TMP") tbl <- subset(tbl, substr(VTM, 12, 16) == "00:00")
        if (input$temperature == "Low" & input$measure == "TMP") tbl <- subset(tbl, substr(VTM, 12, 16) == "12:00")
        
        tbl$DAT_fac <- factor(tbl$DAT)
        
        tbl <- subset(tbl, VTM > as.POSIXct(input$date_range[1]) & VTM < as.POSIXct(input$date_range[2]))
        
        thisPlot <- ggplot(tbl, aes_string(x = "VTM", y = input$measure, group = "DAT_fac", colour = "DAT_fac")) + 
            geom_line()
        
        print(thisPlot)
    })
    
    output$accuracy <- renderPlot({
        tbl <- forecastTable()
        tbl$VTM <- tbl$DAT + hours(tbl$FHR)
        
        validTbl <- subset(tbl, VTM == as.POSIXct(paste(input$forecast_date, input$forecast_hour)))
        
        thisPlot <- ggplot(validTbl, aes_string(x = "DAT", y = input$measure)) + 
            geom_line()
        
        print(thisPlot)
    })
    
    output$extremes <- renderTable({
        dbTbl <- dbSendQuery(conn, paste("SELECT STA, AVG(", input$measure, ") FROM forecast WHERE ", input$measure, " < 150 GROUP BY STA ORDER BY AVG(", input$measure, ") DESC LIMIT 10", sep = ""))
        tbl <- fetch(dbTbl)
        
        station.names <- sapply(tbl$STA, getStationName, conn = conn)
        
        return(cbind(Name = station.names, tbl))
    })
    
    output$extremes_low <- renderTable({
        dbTbl <- dbSendQuery(conn, paste("SELECT STA, AVG(", input$measure, ") FROM forecast WHERE ", input$measure, " < 150 GROUP BY STA ORDER BY AVG(", input$measure, ") ASC LIMIT 10", sep = ""))
        
        tbl <- fetch(dbTbl)
        
        station.names <- sapply(tbl$STA, getStationName, conn = conn)
        
        return(cbind(Name = station.names, tbl))
    })
})

