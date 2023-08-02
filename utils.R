library(rdrop2)
outputDir <- "test_uploads"

saveData <- function(data) {
  data <- t(data)
  # Create a unique file name
  fileName <- sprintf("%s_%s.csv", as.integer(Sys.time()), digest::digest(data))
  # Write the data to a temporary file locally
  filePath <- file.path(tempdir(), fileName)
  write.csv(data, filePath, row.names = FALSE, quote = TRUE)
  # Upload the file to Dropbox
  drop_upload(filePath, path = outputDir)
}

#drop_auth(new_user = TRUE) # this pops up in a browser asking for authentication - not quite sure how this works on a server - will need to try it.

# write.csv(mtcars, 'mtcars2.csv')
# #drop_upload('mtcars.csv')
# # or upload to a specific folder
# drop_upload('mtcars2.csv', path = "test_uploads")
# 
# name1 <- "Polly"
# name2 <- "Rocket"
# email <- "polrock@email.org"
# picname <- "dogpic1"
# 
# line <- paste(name1, name2, email, picname, sep = ",")
# cat(line, file = "records.csv", append = TRUE)
# drop_upload("records.csv")


