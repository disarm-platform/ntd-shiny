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

# Define map

map <- leaflet() %>%
  addTiles("https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png") 

shinyServer(function(input, output){
  
  output$prob_map <- renderLeaflet({
    
  # Get input data
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
    
    points<-read.csv(inFile$datapath)
    pred_points <- read.csv(inFile_pred$datapath)
    
    # Prepare input as JSON
    input_data_list <- list(region_definition = list(lng = pred_points$lng, 
                                                     lat = pred_points$lat, 
                                                     id = pred_points$ID), 
                            train_data = list(lng = points$lng, 
                                              lat = points$lat, 
                                              n_trials = points$Nex, 
                                              n_positive = points$Npos),
                            request_parameters = list(threshold = 0.02))
    
    # input_data_list <- list(region_definition = list(lng = c(0.41961288542311925, 0.18906410255646722, 0.28459859634266227, 0.4242991908752115, 0.6633205520904977, 0.8929262847444361, 0.3294623351747279, 0.3796878949749375, 0.043705505169881365, 0.4513919139455935, 0.29814194311583564, 0.42858005596322757, 0.581719352682603, 0.13180956009918654, 0.7895660117233481, 0.9260908769683664, 0.1686112616658748, 0.44587922164801497, 0.18158098696427105, 0.3194724964111755, 0.6349483496577522, 0.376007314484723, 0.4522417845716924, 0.5829863419706718, 0.6542124016762011, 0.016956969184878212, 0.5853024947105006, 0.8299679018672481, 0.8908387433194993, 0.49041350502737047, 0.801549613721692, 0.7652525086294667, 0.6888748003587736, 0.2932884564342809, 0.7952340774775175, 0.6523363624563364, 0.26953460910298443, 0.8207926965108429, 0.337985247027917, 0.8354420204696813, 0.5025562064514039, 0.8105777302071269, 0.10791442628334802, 0.6570496387596693, 0.44789926755554765, 0.3352403434300978, 0.4673643891108987, 0.2543969574881051, 0.12997632983719698, 0.9169844080787043), 
    #                                                  lat = c(0.036757367175033084, 0.8945530883664937, 0.660215487405479, 0.8615402598408436, 0.7300787736365303, 0.5937677219795177, 0.33008453616298494, 0.6692979560344186, 0.39203178436924035, 0.020832773786447545, 0.006588915180536281, 0.9534199091004621, 0.7785069955122649, 0.6726148718207801, 0.3319177801827269, 0.843501320840565, 0.08846732897975007, 0.2489994301924755, 0.8367447446430297, 0.7750640445109902, 0.8909574684784164, 0.23151907510955216, 0.06240070739467796, 0.07782402030359581, 0.3648093821803664, 0.4740677727437592, 0.03945855501489093, 0.1846043009705305, 0.020691486638861, 0.29349350378780004, 0.9017688922301088, 0.472223155496173, 0.9588137961351211, 0.4697033602186357, 0.5184948673533167, 0.15919689077303767, 0.48840305019281194, 0.6706887746196288, 0.08555666460855305, 0.950978249078421, 0.607562787812027, 0.6671832604941045, 0.5092310575387087, 0.8881479792115166, 0.9467670341263885, 0.5773382474735516, 0.8739814963600939, 0.4182662230325259, 0.06823996953254563, 0.8193521201553062), 
    #                                                  id = c("village_100", "village_101", "village_102", "village_103", "village_104", "village_105", "village_106", "village_107", "village_108", "village_109", "village_110", "village_111", "village_112", "village_113", "village_114", "village_115", "village_116", "village_117", "village_118", "village_119", "village_120", "village_121", "village_122", "village_123", "village_124", "village_125", "village_126", "village_127", "village_128", "village_129", "village_130", "village_131", "village_132", "village_133", "village_134", "village_135", "village_136", "village_137", "village_138", "village_139", "village_140", "village_141", "village_142", "village_143", "village_144", "village_145", "village_146", "village_147", "village_148", "village_149")), 
    #                         train_data = list(lng = c(0.41961288542311925, 0.18906410255646722, 0.28459859634266227, 0.4242991908752115, 0.6633205520904977, 0.8929262847444361, 0.3294623351747279, 0.3796878949749375, 0.043705505169881365, 0.4513919139455935, 0.29814194311583564, 0.42858005596322757, 0.581719352682603, 0.13180956009918654, 0.7895660117233481, 0.9260908769683664, 0.1686112616658748, 0.44587922164801497, 0.18158098696427105, 0.3194724964111755, 0.6349483496577522, 0.376007314484723, 0.4522417845716924, 0.5829863419706718, 0.6542124016762011), 
    #                                           lat = c(0.036757367175033084, 0.8945530883664937, 0.660215487405479, 0.8615402598408436, 0.7300787736365303, 0.5937677219795177, 0.33008453616298494, 0.6692979560344186, 0.39203178436924035, 0.020832773786447545, 0.006588915180536281, 0.9534199091004621, 0.7785069955122649, 0.6726148718207801, 0.3319177801827269, 0.843501320840565, 0.08846732897975007, 0.2489994301924755, 0.8367447446430297, 0.7750640445109902, 0.8909574684784164, 0.23151907510955216, 0.06240070739467796, 0.07782402030359581, 0.3648093821803664), 
    #                                           n_trials = c(35, 30, 16, 33, 39, 27, 34, 24, 27, 18, 21, 38, 25, 34, 17, 20, 38, 34, 33, 15, 35, 22, 39, 28, 39), 
    #                                           n_positive = c(5.0, 20.0, 1.0, 20.0, 28.0, 12.0, 2.0, 20.0, 16.0, 2.0, 3.0, 17.0, 19.0, 5.0, 15.0, 0.0, 27.0, 26.0, 29.0, 3.0, 17.0, 8.0, 25.0, 7.0, 35.0)), 
    #                         request_parameters = list(threshold = 0.5))

    
    # Save json
    json_to_post <- toJSON(input_data_list)
    json_to_post <- stri_escape_unicode(json_to_post)
    write(paste0('"', json_to_post, '"'), file="test3.json")
    
    # Make call to algorithm
    print("Making request")
    request <- httr::POST(url = "http://ric70x7.pythonanywhere.com/post",
                          body = httr::upload_file("test3.json"),
                          #encode = "json",#this is the path to the json file used as input
                          httr::content_type("application/json"))
    
    print("Got response")
    response <- httr::content(request, as='text') # this extracts the response from the request object
    
    result <<- rjson::fromJSON(response) # this will put the response in a useful format
    
    # Plot the result back on the map
    Poly_list <- list()
    
    for (i in 1:length(result$polygons)){
      Poly_list[[i]] <- Polygons(list(Polygon(cbind(result$polygons[[i]]$lng,
                                                    result$polygons[[i]]$lat))), i)
    }
    sp_Polygons <- SpatialPolygons(Poly_list, 1:length(Poly_list))
    
    # Create sp
    sp_Polygons <- SpatialPolygons(Poly_list, 1:length(Poly_list))
    
    # create spdf
    spdf_data <- data.frame(probability = result$estimates$prevalence,
                            id = result$estimates$id,
                            class = result$estimates$category)
    
    # Define color palette
    pal <- colorNumeric(wes_palette("Zissou1", 10, type = "continuous")[1:10], seq(0,1,0.01))
    
    # define modal table
    uncertainty <- abs(spdf_data$probability - 0.5)
    output_table <- spdf_data[order(uncertainty),][1:5,]
    names(output_table) <- c("Probability of being a hotspot", "Village ID", "Hotspot prediction")
    output$pred_table <- renderDataTable({output_table})
    
    # map
    labels <- sprintf(
      "<strong>%s</strong><br/>Hotspot probability %g",
      spdf_data$id, round(spdf_data$probability,3)
    ) %>% lapply(htmltools::HTML)
    
    map %>% addPolygons(data=sp_Polygons, color = pal(spdf_data$probability), fillOpacity = 0.6, weight = 1,
                        highlightOptions = highlightOptions(
                           weight = 5,
                           color = "#666",
                           bringToFront = TRUE,
                           fillOpacity = 0.7),
                         label = labels
                        ) %>%
      
      addPolygons(data=sp_Polygons[order(uncertainty)[1:5],], col = "deeppink", opacity = 1,
                  fillOpacity = 0.1,
                  group = "Villages to sample",
                  highlightOptions = highlightOptions(
                    weight = 5,
                    color = "#666",
                    bringToFront = TRUE,
                    fillOpacity = 0.7),
                  label = labels[order(uncertainty)[1:5]]) %>% 
      
    addLegend(colors= wes_palette("Zissou1", 10, type = "continuous")[1:10], labels = seq(0.1,1,0.1), 
              title = "Hotspot probability") %>%
      
      addLayersControl(overlayGroups = "Villages to sample", options = layersControlOptions(collapsed = F))
      
                 }) # end loading bar
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
