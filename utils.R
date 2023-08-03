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

#drop_auth(new_user = TRUE) # this pops up in a browser asking for authentication - we need to save this as an rds object to use on the server
#

#token <- drop_auth(new_user = TRUE)
# then because dropbox have stopped using long-lived tokens, we need to use a workaround
# https://github.com/karthik/rdrop2/issues/201
# After calling drop_auth() in R, in the pop-up webpage, I added "&token_access_type=offline" to the end of the URL, then hit enter to refresh the page, then authorize as usual. In this way, there should be "a long-lived refresh_token that can be used to request a new, short-lived access token" generated to your app folder. Then I published the app as usual, my authorization problem was solved.
#saveRDS(token, "droptoken.rds")
#&token_access_type=offline



