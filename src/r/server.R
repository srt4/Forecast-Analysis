library(shiny)

source("Weather.R")

# Define server logic required to summarize and view the selected dataset
shinyServer(function(input, output) {
  # Show the first "n" observations
  output$view <- renderTable({
      conn <- dbConnect(MySQL(), user = "root", password = "toor", dbname = "forecast_analysis", host = "localhost")
      tbl <- readForecast(input$station, conn)
      
      return(tbl)
  })
})

