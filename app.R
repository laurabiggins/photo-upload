library(shiny)
library(rdrop2)

danger_colour <- "yellow"
warning_colour <- "#9fd463"
options(shiny.maxRequestSize = 10 *1024^2)

#test 

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
        actionButton(inputId = "Go", "Go")
      ),

      mainPanel(
         textOutput("msg"),
         actionButton("browser", "browser")
      )
  )
)


# disable Go button until all fields have been completed

server <- function(input, output) {

    observeEvent(input$browser, browser())
  
    shinyjs::disable(id = "Go")
  
    observeEvent(input$Go, {
      
      if(nchar(input$name1) > 1) {
        
        shinyFeedback::hideFeedback("name1")
      } else {
        shinyFeedback::feedbackDanger(
          inputId = "Go",
          show = nchar(input$name1) <= 1,
          text = "Please enter your name",
          color = danger_colour
        )
      }
      
      ## dataset ----
      if(!isTruthy(input$file_upload)){
        shinyFeedback::feedbackDanger(
          inputId = "file_upload",
          show = !isTruthy(input$file_upload),
          text = "Please select a data file.",
          color = danger_colour
        )
      } 
      
      req(nchar(input$name1) > 1)
      req(isTruthy(input$file_upload))
      
      # observe({
      # 
      #   if(tools::file_ext(input$file_upload$datapath) %in% c("png", "jpg")){
      #     shinyFeedback::feedbackSuccess(
      #       inputId = "metadata_filepath",
      #       show = TRUE,
      #       text = "Happy with the file type"
      #     )
      #   } else {
      #     shinyFeedback::feedbackDanger(
      #       inputId = "metadata_filepath",
      #       show = !tools::file_ext(input$metadata_filepath$datapath) %in% c("tsv", "txt", "csv"),
      #       text = paste0(
      #         "Metadata file type must be one of tsv, txt or csv, file type specified was ",
      #         tools::file_ext(input$metadata_filepath$datapath)
      #       ),
      #       color = danger_colour
      #     )
      #   }
      # })
      
      drop_auth(rdstoken = "droptoken.rds")
      
      current_records <- drop_read_csv(file="records.csv")
      
     # as_tibble(current_records)
      
      fileName <- sprintf("%s_%s_%s.png", input$name1, input$name2, input$dog)
      # Write the data to a temporary file locally
      
      # ==================#
      # this worked
       filePath <- file.path(tempdir(), fileName)
      # 
       file.copy(input$file_upload$datapath, filePath)
      # 
      # # Upload the file to Dropbox
       drop_upload(filePath, path = "test_uploads")
      # =========================
      
      
      # this works and uploads directly but I can't control the file name - it's 0.png, 
      # then 0 (1).png, 0(2).png etc. not great, so I think we'll have to upload to the 
      # server then upload to dropbox. Not ideal.
      # But I guess it could go into a folder with the name
      #x <- drop_upload(input$file_upload$datapath, mode="add", verbose = TRUE, path = "test_uploads")
      
      # this also works
      #path_upload <- paste0("test_uploads/", fileName)
      #drop_upload(input$file_upload$datapath, mode="add", verbose = TRUE, path = path_upload)
      
      
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
