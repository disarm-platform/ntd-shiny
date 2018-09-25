library(leaflet)
library(lubridate)
library(shinyBS)


library(shinydashboard)

dashboardPage(
  dashboardHeader(),
  dashboardSidebar(disable = T),
  dashboardBody(
    fluidRow(
      #column(width = 12,
             box(width = 12, 
                    h3("NTD mapping app"), h4(p("This application is designed to help understand whether having village level
                                              predictions of hotspots is useful to NTD programs. Given an input of infection/sero 
                                              prevalence at villages, and locations of all other villages, the app is designed 
                                              to automatically fit a geospatial model using climatological variables to provide two outputs. 
                                              1) Location of likely hotspot villages and 2) locations to next visit to collect more data in
                                              order to update your hotspot prediction map. To test the app, you can download the 
                                              demo files below to see their structure and then upload using the upload box."),
                 
                                            p('Once the data are uploaded, the two tabs below show the two outputs. The', strong('Hotspots'), 'tab
                                              allows hotspot villages to be identified. The ', strong('Adaptive sampling'), 
                                              'tab provides guidance on where to survey next in order to survey 
                                              a village that will provide the most valuable data.')),
                 
                                             
                 
                 helpText(a("Demo survey data",     
                            href="https://www.dropbox.com/s/dxpdwvqez2pvszm/Sm_cdi_observations.csv?dl=1"),
                          target="_blank"), 
                 
                 helpText(a("Demo village data",     
                            href="https://www.dropbox.com/s/tn4lmpvlgubtrey/Sm_cdi_villages.csv?dl=1"),
                          target="_blank"), 
                 
                        fileInput("File", "Survey data", width = "20%"),
                        fileInput("predFile", "Villages", width = "20%")),
            
             
             tabBox(width = 12, height = 1000,
                    tabPanel(title = strong("Hotspots"), width = 12, 
                             
                             p('The', strong('Hotspots'), 'tab allows hotspot villages to be identified by choosing the predicted 
                                probability that a village 
                                is a hotspot (where a hotspot is defined as a location where infection/sero prevalence 
                               is greater than 2%). For example, if the slider is at 50%, the map will show all those
                               villages where the probability the village is a hotspot is at least 50%. For a more conservative
                               estimate of hotspots, a lower threshold can be used. For example, a program might be willing to 
                               classify a village as a hotspot if they are only 30% sure the village is actually a hotspot. 
                               In that case, the slider should be moved to 30% and the map and table will update.'),
                             
                             box(leafletOutput("hotspot_map", height = 500), width = 8),
                             box(sliderInput("prob_threshold", 
                                             "Select areas where the probability of being a hotspot is at least",
                                             min = 0, max= 100, value=50, post = "%"), width = 4),
                             box(dataTableOutput('hotspot_table'), width = 4)),
                    
                    tabPanel(title = strong("Adaptive sampling"),

                             p('The ', strong('Adaptive sampling'), 'tab provides guidance on where to survey next in order to survey 
                                              a village that will provide the most valuable data. In this case, the village at which the 
                               algorithm is least certain about whether it is a hotspot or not is the most sensible location
                               to collect more data. Rather than identifying the single most valuable village to visit, the 
                               application provides 5 village to choose from. Once data at one of these 5 villages is collected
                               the application can be updated and the hotspot and adaptive sampling maps will update.'),
                             
                             box(leafletOutput("prob_map", height = 500), width = 8),
                             box(dataTableOutput('pred_table'), width = 4))
                    
             )
             )

      )
)
      

