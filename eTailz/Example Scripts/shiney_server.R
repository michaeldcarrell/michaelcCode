library(shiny)
library(xlsx)
library(RMySQL)
library(rlang)
library(shinyjs)

source("P:/Employees/MichaelC/R/Compliance_Product_Tracking MySQL Connect.R")
crude_sku_status<-fetch(dbSendQuery(compliance_product_tracking, "SELECT * FROM crude_sku_status"),n=-1)
dbDisconnect(compliance_product_tracking)
source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")
UnityVendors<-fetch(dbSendQuery(unity, 'Select v.name, v.id From vendors v Order By v.name'), n=-1)
dbDisconnect(unity)

crude_sku_status<-c("multi-asin",
                    "multi-asin-denied",
                    "mpn-select",
                    "mpn-denied",
                    "manual-compliance-review",
                    "compliance-approved",
                    "compliance-denied",
                    "product-created")

vendors<-c("vendor1",
           "vendor2",
           "vendor3",
           "vendor4",
           "vendor5",
           "vendor6",
           "vendor7",
           "vendor8",
           "vendor9")

ui<-fluidPage(
  shinyjs::useShinyjs(),
  headerPanel(title = "Upload into Compliance Product Tracking"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload the File"),
      selectInput("vendorProduct", "Select Vendor Part Number:", c("Load Review File")),
      selectInput("statusSelect", "Proucts Status:", prepend(crude_sku_status, "Select Status", 1)),
      selectInput("vendorChoice", "Choose Vendor:", prepend(vendors, "Select Vendor", 1)),
      actionButton("commitData", "Upload To Database"),
      br(),
      br(),
      textOutput("uploadStatus")
    ),
    mainPanel(
      tableOutput("input_file")
    )
  )
)

server<-function(input, output, session){
  getData<-reactive({
    inFile<-input$file
    if(is.null(inFile)){
      return()
    }
    ProductFile<-read.xlsx(inFile$datapath, sheetIndex = 1)
    updateSelectInput(session, "vendorProduct", choices = prepend(colnames(ProductFile), "Select Part Number", 1))
    shinyjs::enable("commitData")
    updateActionButton(session, "commitData", "Upload To Database")
    ProductFile
  })
  
  output$input_file<-renderTable(
    getData()
  )
  
  observeEvent(input$commitData, {
    shinyjs::disable("commitData")
    ProductFile<-getData()
    UploadFrame<-data.frame(crude_skusNew=paste(UnityVendors$id[UnityVendors$name==input$vendorChoice], 
                                                ProductFile[,input$vendorProduct], sep = '-'))
    crude_skus_toLoad<-paste0("'", UploadFrame$crude_skusNew[1], "', ")
    for(i in 2:nrow(UploadFrame)-1){
      crude_skus_toLoad<-paste0(crude_skus_toLoad, "'", UploadFrame$crude_skusNew[i], "', ")
    }
    crude_skus_toLoad<-paste0(crude_skus_toLoad, "'", UploadFrame$crude_skusNew[nrow(UploadFrame)], "'")
    status_id<-crude_sku_status$id[crude_sku_status$crude_sku_status==input$statusSelect]
    
    print(paste0("UPDATE crude_skus
                 SET crude_sku_status = ", status_id, ", current_file_path = '", input$file$name,
                 "' WHERE crude_sku in (", crude_skus_toLoad, ");"))
    
    source("P:/Employees/MichaelC/R/Compliance_Product_Tracking MySQL Connect.R")
    dbSendStatement(compliance_product_tracking, paste0("UPDATE crude_skus
                                                        SET crude_sku_status = ", status_id, ", current_file_path = '", input$file$name,
                                                        "' WHERE crude_sku in (", crude_skus_toLoad, ");"))
    dbDisconnect(compliance_product_tracking)
    updateActionButton(session, "commitData", "Upload Complete")
    showModal(modalDialog(
      title = "Upload has Completed",
      'To upload a new set of products select another file and press "Upload To Database"\n WARNING: Filters will not reset'
    ))
  })
}

shinyApp(ui = ui, server = server)
