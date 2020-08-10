# this scripts downloads the data from google sheets
# It can't be run from Rmd because requires manual input

# install packages if not already installed
if (!requireNamespace("googlesheets4")) install.packages("googlesheets4")
if (!requireNamespace("here")) install.packages("here")

url <- "https://docs.google.com/spreadsheets/d/1Jhu67QhyVskP4S50HM1dIkFZL8oe6PVAFV-ODyIBP-k/edit?ts=5f2da4eb"
sheet_names <-  googlesheets4::gs4_get(url)$sheets$name
# use  sapply to with simplify = FALSE to get named elements
sheets <- sapply(sheet_names, googlesheets4::read_sheet, ss = url, 
                 simplify = FALSE, na = c("", "-"))
sheets <- sheets[startsWith(names(sheets), "Q")]

saveRDS(sheets, here::here("proc_data/fetched_data.RDS"))
