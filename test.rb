require "google_drive"

# Creates a session. This will prompt the credential via command line for the
# first time and save it to config.json file for later usages.
# See this document to learn how to create config.json:
# https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md
session = GoogleDrive::Session.from_config("config.json")


ws = session.spreadsheet_by_key("1HndlZySAJ2M1mq9YS4H3pALq7mi3VXSIiR_ELgFJ7tI").worksheets[0]

# Gets content of A2 cell.
p ws[2, 1]  #==> "hoge"
