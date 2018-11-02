library(raster)
library(sp)
library(leaflet)
library(RANN)
library(rgeos)
#library(geosphere)
library(rjson)
library(httr)
library(wesanderson)
library(readr)
library(stringi)
library(DT)
library(ggplot2)

source("buff_voronoi.R")

# Define map

map <- leaflet(max) %>%
  addTiles(
    "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png"
  )

shinyServer(function(input, output) {
  map_data <- reactive({
    inFile <- input$File
    inFile_pred <- input$predFile
    if (is.null(inFile))
      return(NULL)
    
    if (is.null(inFile_pred))
      return(NULL)
    
    # Give loading bar
    withProgress(message = 'Hold on',
                 detail = 'Crunching data..',
                 value = 5,
                 {
                   points <- read.csv(inFile$datapath)
                   pred_points <- read.csv(inFile_pred$datapath)
                   
                   # Prepare input as JSON
                   input_data_list <-
                     list(
                       region_definition = list(
                         lng = pred_points$lng,
                         lat = pred_points$lat,
                         id = pred_points$ID
                       ),
                       train_data = list(
                         lng = points$lng,
                         lat = points$lat,
                         n_trials = points$Nex,
                         n_positive = points$Npos
                       ),
                       request_parameters = list(threshold = input$threshold /
                                                   100)
                     )
                   
                   # Make call to algorithm
                   print("Making request")
                   
                   response <-  httr::POST(url = "http://srv.tmpry.com:8080/function/fn-hotspot-gears_0-0-2",
                                           body = toJSON(input_data_list),
                                           content_type_json())
                   
                   print("Got response")
                   print(response$status_code)
                   # Check it ran. If not, run again.
                   if (response$status_code != 200) {
                     print("Trying again")
                     response <- request_call()
                     print("Got second response")
                   }
                   
                   # parse result
                   json_response <-
                     httr::content(response, as = 'text') # this extracts the response from the request object
                   
                   result <<-
                     rjson::fromJSON(json_response) # this will put the response in a useful format
                   
                   # Create buffered polygons
                   sp_Polygons <-
                     buff_voronoi_test(
                       data.frame(
                         x = pred_points$lng,
                         y = pred_points$lat,
                         id = pred_points$ID
                       ),
                       w_buff = 0.3
                     )
                   
                   # create spdf
                   spdf_data <-
                     data.frame(
                       probability = result$estimates$exceedance_prob,
                       id = result$estimates$id,
                       class = result$estimates$category
                     )
                   
                   return(
                     list(
                       points = points,
                       pred_points = pred_points,
                       sp_Polygons = sp_Polygons,
                       spdf_data = spdf_data
                     )
                   )
                 })
  })
  
  output$pred_table <- DT::renderDT({
    if (is.null(map_data())) {
      return(NULL)
    }
    uncertainty <- abs(map_data()$spdf_data$probability - 0.5)
    output_table <-
      map_data()$spdf_data[order(uncertainty),][1:5, c(2, 1)]
    output_table[, 2] <- round(output_table[, 2], 2)
    names(output_table) <-
      c("Village ID", "Probability of being a hotspot")
    DT::datatable(output_table,
                  options = list(pageLength = 15),
                  rownames = F)
  })
  
  output$hotspot_table <- DT::renderDT({
    if (is.null(map_data())) {
      return(NULL)
    }
    hotspot_index <-
      which(map_data()$spdf_data$probability >= input$prob_threshold / 100)
    hotspot_table <- map_data()$spdf_data[hotspot_index, 2:1]
    hotspot_table[, 2] <- round(hotspot_table[, 2], 2)
    names(hotspot_table) <-
      c("Village ID", "Probability of being a hotspot")
    DT::datatable(
      hotspot_table,
      options = list(pageLength = 10,
                     columnDefs = list(
                       list(className = 'dt-center',
                            target = 1:2)
                     )),
      rownames = F
    )
  })
  
  output$hotspot_map <- renderLeaflet({
    if (is.null(map_data())) {
      return(map %>% setView(0, 0, zoom = 2))
    }
    
    # Define color palette
    pal <-
      colorNumeric(wes_palette("Zissou1", 10, type = "continuous")[1:10],
                   seq(0, 1, 0.01))
    
    labels <- sprintf(
      "<strong>%s</strong><br/>Hotspot probability %g",
      map_data()$spdf_data$id,
      round(map_data()$spdf_data$probability, 3)
    ) %>% lapply(htmltools::HTML)
    
    # Map
    hotspot_class <-
      ifelse(map_data()$spdf_data$probability >= input$prob_threshold / 100,
             1,
             0)
    map %>% addPolygons(
      data = map_data()$sp_Polygons,
      color = pal(hotspot_class),
      fillOpacity = 0.6,
      weight = 1,
      highlightOptions = highlightOptions(
        weight = 5,
        color = "#666",
        bringToFront = TRUE,
        fillOpacity = 0.7
      ),
      label = labels
    ) %>%
      
      addCircleMarkers(
        map_data()$points$lng,
        map_data()$points$lat,
        group = "Survey points",
        col = "black",
        radius = 2
      ) %>%
      
      addLegend(colors = pal(c(0, 1)),
                labels = c("Not hotspot", "Hotspot")) %>%
      
      addLayersControl(overlayGroups = c("Survey points"),
                       options = layersControlOptions(collapsed = F))
  })
  
  output$prob_map <- renderLeaflet({
    if (is.null(map_data())) {
      return(map %>% setView(0, 0, zoom = 2))
    }
    
    # Define color palette
    pal <-
      colorNumeric(wes_palette("Zissou1", 10, type = "continuous")[1:10],
                   seq(0, 1, 0.01))
    
    # define uncertainty
    uncertainty <- abs(map_data()$spdf_data$probability - 0.5)
    
    # map
    labels <- sprintf(
      "<strong>%s</strong><br/>Hotspot probability %g",
      map_data()$spdf_data$id,
      round(map_data()$spdf_data$probability, 3)
    ) %>% lapply(htmltools::HTML)
    
    map %>% addPolygons(
      data = map_data()$sp_Polygons,
      color = pal(map_data()$spdf_data$probability),
      fillOpacity = 0.6,
      weight = 1,
      highlightOptions = highlightOptions(
        weight = 5,
        color = "#666",
        bringToFront = TRUE,
        fillOpacity = 0.7
      ),
      label = labels
    ) %>%
      
      addPolygons(
        data = map_data()$sp_Polygons[order(uncertainty)[1:5],],
        col = "deeppink",
        opacity = 1,
        fillOpacity = 0.1,
        group = "Villages to sample",
        highlightOptions = highlightOptions(
          weight = 5,
          color = "#666",
          bringToFront = TRUE,
          fillOpacity = 0.7
        ),
        label = labels[order(uncertainty)[1:5]]
      ) %>%
      
      addCircleMarkers(
        map_data()$points$lng,
        map_data()$points$lat,
        # popup = paste0("<p><strong>Name: </strong>", map_data()$points$ID,
        #                                        "<br><strong>Prevalence </strong>",
        #                                        c(map_data()$points$Npos / map_data()$points$Nex),
        #                                        "<br><strong>N = </strong>",
        #                                        map_data()$points$Nex),
        group = "Survey points",
        col = "black",
        radius = 2
      ) %>%
      
      addLegend(
        colors = wes_palette("Zissou1", 10, type = "continuous")[1:10],
        labels = seq(0.1, 1, 0.1),
        title = "Hotspot probability"
      ) %>%
      
      addLayersControl(
        overlayGroups = c("Villages to sample", "Survey points"),
        options = layersControlOptions(collapsed = F)
      )
    
  }) # end loading bar
  
  output$posterior <- renderPlot({
    set.seed(1981)
    sample <- rbinom(500, 100, 0.10)
    binom <- density(sample, 0.9)
    binom <- data.frame(x = binom$x, y = binom$y)
    plot(
      binom$x,
      binom$y,
      type = "l",
      lwd = 4,
      axes = F,
      xlab = "Infection prevalence (%)",
      ylab = ""
    )
    axis(1)
    polygon(c(binom$x, min(binom$x)),
            c(binom$y, binom$y[1]),
            col = "gray80",
            border = NA)
    lines(binom$x, binom$y, type = "l", lwd = 4,)
    
    
    #lines(rep(mean(sample),2),c(0,1))
    lines(rep(10, 2), c(0, 0.12), col = "red", lwd = 3)
    polygon(
      c(10, 10, binom$x[binom$x > 10], 10),
      c(0, 0.11, binom$y[binom$x > 10], 0),
      col = rgb(1, 0.2, 0.1, 0.5),
      border = NA
    )
  })
  
  # logos
  output$logo <- renderImage({
    # Return a list containing the filename
    list(src = "logo_transparent.png")
  }, deleteFile = FALSE)
  
  #output$Instructions <- textOutput("File with 'lng' and 'lat' columns")
  
  output$EE_logo <- renderImage({
    # Return a list containing the filename
    list(src = "GoogleEarthEngine_logo.png")
  }, deleteFile = FALSE)
  
})
