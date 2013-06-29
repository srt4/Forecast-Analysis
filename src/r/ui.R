library(shiny)

source("Weather.R")

getRecentForecast <- function(value = "max", hrs = 192) {
    theValue <- ifelse(value == "max", "DESC", "ASC")
    conn <- dbConnect(MySQL(), user = "root", password = "toorpassword", dbname = "forecast_analysis", host = "forecast-analysis.cjswh8fnvy2j.us-west-2.rds.amazonaws.com")
    dbTbl <- dbSendQuery(conn, paste("SELECT DAT FROM forecast ORDER BY DAT", theValue, "LIMIT 1"))
    result <- fetch(dbTbl)
    
    if (theValue == "ASC") {
        return(as.POSIXct(result[1,1]))
    } else {
        return(as.POSIXct(result[1,1]) + hours(hrs))
    }
}

# Define UI for dataset viewer application
shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("Forecast"),
  
  # Sidebar with controls to select a dataset and specify the number
  # of observations to view
  sidebarPanel(
      textInput("station", "Choose a Station:", value = "KSEA"),
      selectInput("measure", "Choose a Variable:", c("Temperature" = "TMP", "Dew Point" = "DPT", "Wind" = "WND", "Precipitation Chance" = "P12", "Rainfall Amount" = "Q12", "Thunderstorm Chance" = "T12")),
      dateRangeInput("date_range", "Date Range:", start = today(), end = today() + days(7), min = getRecentForecast("min"), max = getRecentForecast("max")),
      br(),
      dateInput("forecast_date", "Forecast of Interest:", value = today() + days(1)),
      selectInput("forecast_hour", "Forecast Hour:", c("00:00:00 UTC", "12:00:00 UTC")),
      selectInput("temperature", "Temperatures:", c("High", "Low", "Both"))
  ),
  
  # Show a summary of the dataset and an HTML table with the requested
  # number of observations
  mainPanel(
      tabsetPanel(
          tabPanel("Table", textOutput("stationText"), br(), tableOutput("view")),
          tabPanel("Forecast", textOutput("stationText"), br(), plotOutput("forecastTemp")),
          tabPanel("Accuracy", textOutput("stationText"), br(), plotOutput("accuracy")),
          tabPanel("Extremes", tableOutput("extremes"), tableOutput("extremes_low"))
      )
  )
))
