library(shiny)
library(rdrop2)
library(shinyFeedback)
library(shinyjs)

danger_colour <- "#D62828"
warning_colour <- "#9fd463"
options(shiny.maxRequestSize = 10 *1024^2)
accepted_filetypes <- c("png", "jpg", "jpeg", "PNG", "JPG", "JPEG", "Png", "Jpg", "Jpeg",)
token <- readRDS("droptoken.rds")
new_token <- token$refresh()
saveRDS(new_token, "droptoken.rds")
  
# https://github.com/karthik/rdrop2/issues/180

ui <- fluidPage(
  
  shinyFeedback::useShinyFeedback(),
  shinyjs::useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),

  titlePanel("Upload photo for calendar"),

  sidebarLayout(
      sidebarPanel(
        textInput(inputId = "name1", label = "Enter first name"),
        textInput(inputId = "name2", label = "Enter surname"),
        textInput(inputId = "email", label = "email address"),
        textInput(inputId = "dog", label = "dog name??"),
        fileInput(inputId = "file_upload", label = "choose photo")
        
      ),
      mainPanel(
        
        tabsetPanel(
          id="main_panel",
          type="hidden",
          tabPanelBody(
            "load_button",
            br(), br(),
            fluidRow(
              column(
                width = 10, offset = 1,
                actionButton(
                  inputId = "Go", 
                  HTML("I've filled in the information <br/> and am ready to submit")
                )
              )
            )
          ),
          tabPanelBody(
            "confirm_panel",
            br(), br(),
            fluidRow(
              column(
                width = 8, offset = 2,
                textOutput("msg"),
              )
            )
          )
      )#,
      #actionButton("browser", "browser"),
      #actionButton("sleep", "sleep"),
    )
  )
)


# disable Go button until all fields have been completed

server <- function(input, output, session) {

    observeEvent(input$browser, browser())

    observeEvent(input$sleep, Sys.sleep(10))
  
    observe({
      
      # highlight input boxes if file type isn't right
      if(isTruthy(input$file_upload)){
        shinyFeedback::hideFeedback("file_upload")
        
        if(tools::file_ext(input$file_upload$datapath) %in% accepted_filetypes){
          shinyFeedback::feedbackSuccess(
            inputId = "file_upload",
            show = TRUE,
            text = "Compatible file type"
            
          )
        } else {
          shinyFeedback::feedbackDanger(
            inputId = "file_upload",
            show = !tools::file_ext(input$file_upload$datapath) %in% accepted_filetypes,
            text = paste0(
              "File type must be one of png or jpg, file type specified was ",
              tools::file_ext(input$file_upload$datapath)
            ),
            color = danger_colour
          )
        }
      }
      
      if(nchar(input$name1) > 1) {
        shinyFeedback::hideFeedback("name1")
      }
      
      
    })
  
    observeEvent(input$Go, {
      
      if(nchar(input$name1) > 1) {
        
        shinyFeedback::hideFeedback("name1")
      } else {
        shinyFeedback::feedbackDanger(
          inputId = "name1",
          show = nchar(input$name1) <= 1,
          text = "Please enter your name",
          color = danger_colour
        )
      }
      
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
      req(tools::file_ext(input$file_upload$datapath) %in% accepted_filetypes)
      
      msg_text("Thank you, we're trying to upload your photo.")
      
      #Sys.sleep(10)
      
      drop_auth(rdstoken = "droptoken.rds")
      
      #current_records <- drop_read_csv(file="records.csv")
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
      
      
      # add contact info to records file
      line <- paste(paste(input$name1, input$name2, input$email, input$dog, sep = ","), "\n")
      cat(line, file = "records.csv", append = TRUE)
      drop_upload("records.csv") 
      
      msg_text("Thank you, please look out for an email over the next couple of days to confirm that we've received your photo.")
      
      updateTabsetPanel(session, "main_panel", selected = "confirm_panel")
    })
  
    msg_text <- reactiveVal("")
    
    output$msg <- renderText({
        msg_text()
    })
}

# Run the application 
shinyApp(ui = ui, server = server)