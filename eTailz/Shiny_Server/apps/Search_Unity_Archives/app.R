library(shiny)
library(RMySQL)

source("~/lib/Unity_MySQL_Connect.R")

ui<-fluidPage(
  shinyjs::useShinyjs(),
  headerPanel(title = "Unity Archive Search"),
  mainPanel(
    textInput("unityParam", "Input Search Value:"),
    selectInput("unityWhere", "Select Field to Search By:", c("Site Order ID", "Sales Order ID", "PO ID")),
    actionButton("searchUnity", "Search Unity"),
    br(),
    br(),
    dataTableOutput("input_file")
  )
)

server<-function(input, output, session){
  getData<-eventReactive(input$searchUnity, {
    SelectionControl<-data.frame(UnityField=c("so.ca_site_order_id", "so.id", "po.id"), UserField=c("Site Order ID", "Sales Order ID", "PO ID"))
    UserSelectedField<-SelectionControl$UnityField[SelectionControl$UserField==input$unityWhere]
    
    fetch(dbSendQuery(unity, paste0("Select po.id PoId, so.id SalesOrderId, v.name Vendor, vw.name VendorWarehouse, so.ca_site_name SiteName, so.ca_site_order_id SiteOrderId, so.ca_shipping_status ShippingStatus, so.ca_shipping_first_name CustomerFirstName,
      so.ca_shipping_last_name CustomerLastName, so.ca_shipping_address_1 ShippingAddress1, so.ca_shipping_address_2 ShippingAddress2, so.ca_shipping_city ShipCity, so.ca_shipping_state ShipState,
      so.ca_shipping_postal_code Zip, so.total_price TotalPrice, so.shipping_cost Shipping, so.commission_cost Commission, so.created_at OrderCreatedAt
      From sales_orders so 
      Join purchase_orders po on po.sales_order_id = so.id
      Join vendors v on v.id = po.vendor_id
      Join vendor_warehouses vw on vw.id = po.vendor_warehouse_id
      Where ", UserSelectedField," = '", input$unityParam,"'")), n=-1)
  })
  
  output$input_file<-renderDataTable(
    getData()
  )
}

shinyApp(ui = ui, server = server)