---
editor_options: 
  markdown: 
    wrap: 72
---

# Photo-upload

This is a small Shiny app consisting of a form for uploading photos to a
dropbox account.

## Dropbox access and authentication

The R package rdrop2 has been used to access dropbox.

The authentication is done interactively so needs to be carried out on a
desktop machine. The token can be saved as an .rds object and then used
on the server. A pop up appears in a browser asking for authentication -
as long as you're logged in to dropbox, this should be a simple click of
a button to authorise.\
However, dropbox have stopped using long-lived tokens so we need to use
a workaround so that it doesn't stop working after a few hours. I used
the solution as described here:
<https://github.com/karthik/rdrop2/issues/201>

`After calling drop_auth() in R, in the pop-up webpage, add "&token_access_type=offline" to the end of the URL, then hit enter to refresh the page, then authorize as usual. In this way, there should be "a long-lived refresh_token that can be used to request a new, short-lived access token" generated to your app folder.`

``` r
library(rdrop2)
token <- drop_auth(new_user = TRUE)
```

Add `&token_access_type=offline` to the end of the URL.

``` r
saveRDS(token, "droptoken.rds")
```

Token refresh at the start of the app.R code

``` r
token <- readRDS("droptoken.rds")
new_token <- token$refresh()
saveRDS(new_token, "droptoken.rds")
```

Then use `new_token` in the server code.

## Records.csv file

To enable manual checking of whether someone's photo has been uploaded,
the names entered into the form are saved in a records.csv file. This is
not include in this repository so may need to be created manually.
