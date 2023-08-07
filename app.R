library(shiny)
library(rdrop2)
library(shinyFeedback)
library(shinyjs)
library(shinyvalidate)
library(promises)
library(future)
plan(multisession)

# js message when button has been pressed and waiting for upload

danger_colour <- "#D62828"
warning_colour <- "#9fd463"
options(shiny.maxRequestSize = 10 *1024^2)
accepted_filetypes <- c("png", "jpg", "jpeg", "PNG", "JPG", "JPEG", "Png", "Jpg", "Jpeg")
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
  h4("The photo can be up to 5Mb in size, any more instructions here?"),

  sidebarLayout(
      sidebarPanel(
        textInput(inputId = "name1", label = "First name"),
        textInput(inputId = "name2", label = "Surname"),
        textInput(inputId = "facebook_name", label = "Facebook name"),
        textInput(inputId = "email", label = "Email address"),
        textInput(inputId = "dog", label = "Dog name"),
        fileInput(inputId = "file_upload", label = "Choose photo")
        
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
     # actionButton("browser", "browser"),
    )
  )
)

server <- function(input, output, session) {

    observeEvent(input$browser, browser())

    iv <- InputValidator$new()
    
    # Add validation rules
    iv$add_rule("name1", sv_required())
    iv$add_rule("name2", sv_required())
    iv$add_rule("facebook_name", sv_required())
    iv$add_rule("email", sv_required())
    iv$add_rule("email", sv_email())
    iv$add_rule("dog", sv_required())
    
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
    })
  
    observeEvent(input$Go, {
      
      disable(id= "Go")
      
      shinyalert::shinyalert(
        paste0(
          "Thank you, just running some checks..."
        ),
        closeOnClickOutside = TRUE,
        #imageUrl = "http://143.110.172.117/images/pup.jpg",
        className = "shinyalertmodal"
      )
      
      if(!isTruthy(input$file_upload)){
        shinyFeedback::feedbackDanger(
          inputId = "file_upload",
          show = !isTruthy(input$file_upload),
          text = "Please select a data file.",
          color = danger_colour
        )
        enable(id= "Go")
      }
    
      if(iv$is_valid()){
        
        req(isTruthy(input$file_upload))
        req(tools::file_ext(input$file_upload$datapath) %in% accepted_filetypes)
        
        shinyalert::shinyalert(
          paste0(
            "Thank you, we'll try uploading the file, \n it may take a few minutes so bear with us."
          ),
          imageUrl = "images/pup1.jpg",
          closeOnClickOutside = TRUE,
          className = "shinyalertmodal"
        )
        
        fileName <- sprintf("%s_%s.png", input$dog, input$name2)
        filePath <- file.path(tempdir(), fileName)
        user_datapath <- input$file_upload$datapath
        contact_info <- paste(paste(input$name1, input$name2, input$facebook_name, input$email, input$dog, sep = ","), "\n")
        
        future_promise({
        
          drop_auth(rdstoken = "droptoken.rds")
          
          # In order to create a custom name for the file, it needs to be saved 
          # locally and then uploaded to dropbox.
          # Write the data to a temporary file locally
          file.copy(user_datapath, filePath)
          
          # Upload the file to Dropbox
           drop_upload(filePath, path = "test_uploads")
           
           dropbox_records <- drop_read_csv(file = "records.csv")
           # add contact info to records file
           cat(contact_info, file = "records.csv", append = TRUE) # I'm not sure how this will work if 2 sessions are run simultaneously
           cat(contact_info, file = "../records.csv", append = TRUE)
           drop_upload("records.csv") 

           "Thank you, please look out for an email over the next couple of days to confirm that we've received your photo."
           
        }) %...>%
          msg_text()
        
        updateTabsetPanel(session, "main_panel", selected = "confirm_panel")
        
      } else {
        
        iv$enable()
        showNotification(
          "Please correct the errors in the form and try again",
          id = "submit_message", type = "error")
        enable(id= "Go")
      }
    })
    
    msg_text <- reactiveVal("")
    
    output$msg <- renderText({
        msg_text()
    })
}

# Run the application 
shinyApp(ui = ui, server = server)