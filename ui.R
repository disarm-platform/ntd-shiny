library(leaflet)
library(lubridate)
library(shinyBS)


library(shinydashboard)

dashboardPage(
  dashboardHeader(),
  dashboardSidebar(fileInput("File", "Observations"),
                   fileInput("predFile", "Villages")),
  dashboardBody(
    fluidRow(
      column(width = 12,
             #box(width = NULL, solidHeader = TRUE,
              #leafletOutput("prob_map", 
              #              height = 500)),
      
      tabBox(width = 12, 
             tabPanel("Hotspots",    #title = "Villages to target for further surveys",
        dataTableOutput('pred_table'),
        leafletOutput("hotspot_map", height = 500)
      ),
      
      tabPanel("Adaptive sampling",
               dataTableOutput('pred_table'),
               leafletOutput("prob_map", height = 500)
               )
      )
)
)
)
)

# shinyUI(bootstrapPage(
#   tags$style(type = "text/css", "html, body {width:100%;height:100%}", 
#              HTML('#logo_plot {background-color: rgba(0,0,255,0);;}
#                   #sel_date {background-color: rgba(0,0,255,1);}')),
#   
#   # bsModal("table_modal", "Table", "viewTable", size = "large",
#   #         dataTableOutput("pred_table")),
#   
#   leafletOutput("prob_map", width = "100%", height = "100%"),
#   
#   absolutePanel(style="opacity: 1; padding: 6px; border-bottom: 0px solid #CCC;background-color: rgba(235,235,235,0.9);",
#                 
#                 fileInput("File", "Observations"),
#                 fileInput("predFile", "Villages"),
#                 draggable = TRUE, top = 50, left = 150,
#                 width = 250, height = 330
#                 
#                 #actionButton("viewTable", "View predictions"),
#                 
#                 #sliderInput("prevalence", "Probability that prevalence is between:", min=0, max=1, value=c(0,0.5), ticks = F),
#                 
#                 # sliderInput("pop", tags$div(
#                 #   HTML(paste("Population/km", tags$sup(2), " above:",sep = ""))), 
#                 #   min=0, max=150, value=0, ticks = F),
#                 
#                 #actionButton("go", "Recalculate"),
#                 
#                 #downloadLink('downloadData', 'Download map')
#   ),
#   
#   absolutePanel(style="opacity: 1; padding: 4px; border-bottom: 1px solid #CCC; background-color: rgba(0,0,0,0.7);",
#                 imageOutput("logo", height=2, width=3),
#                 top = 15, right = 180,
#                 width = 120, height = 40
#   ),
#   
#   absolutePanel(style="opacity: 0.9; padding: 4px; border-bottom: 1px solid #CCC; background-color: rgba(0,0,255,0);",
#                 imageOutput("EE_logo", height=2, width=3),
#                 bottom = 3, left = 25,
#                 width = 0, height = 50
#   )
#   
#              ))