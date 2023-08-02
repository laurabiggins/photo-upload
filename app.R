library(shiny)
library(rdrop2)

# https://github.com/karthik/rdrop2/issues/180

ui <- fluidPage(

  titlePanel("Upload photo for calendar"),

  sidebarLayout(
      sidebarPanel(
        textInput(inputId = "name1", label = "Enter first name"),
        textInput(inputId = "name2", label = "Enter surname"),
        textInput(inputId = "email", label = "email address"),
        textInput(inputId = "dog", label = "dog name??"),
        fileInput(inputId = "file_upload", label = "choose photo"),
        actionButton("Go", "Go")
      ),

      mainPanel(
         textOutput("msg"),
         actionButton("browser", "browser")
      )
  )
)


server <- function(input, output) {

    observeEvent(input$browser, browser())
  
    observeEvent(input$Go, {
      
      current_records <- drop_read_csv(file="records.csv")
      
      as_tibble(current_records)
      
      fileName <- sprintf("%s_%s_%s.jpg", input$name1, input$name2, input$dog)
      # Write the data to a temporary file locally
      
      # ==================#
      # this worked
      # filePath <- file.path(tempdir(), fileName)
      # 
      # file.copy(input$file_upload$datapath, filePath)
      # 
      # # Upload the file to Dropbox
      # drop_upload(filePath, path = "test_uploads")
      # =========================
      
      
      # this works and uploads directly but I can't control the file name - it's 0.png, 
      # then 0 (1).png, 0(2).png etc. not great, so I think we'll have to upload to the 
      # server then upload to dropbox. Not ideal.
      # But I guess it could go into a folder with the name
      #x <- drop_upload(input$file_upload$datapath, mode="add", verbose = TRUE, path = "test_uploads")
      path_upload <- paste0("test_uploads/", fileName)
      drop_upload(input$file_upload$datapath, mode="add", verbose = TRUE, path = path_upload)
      # validation checks
      # 
      line <- paste(paste(input$name1, input$name2, input$email, input$dog, sep = ","), "\n")
      cat(line, file = "records.csv", append = TRUE)
      drop_upload("records.csv") 
      
    })
  
    output$msg <- renderText({
        "We'll try uploading the pic, it'll take a little while but please be patient...dancing dog."
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
