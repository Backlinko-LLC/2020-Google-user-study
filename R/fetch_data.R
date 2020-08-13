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



## tidy the data into one clean table

sheets <- readRDS(here::here("proc_data/fetched_data.RDS"))

#Check consistency of column names

name_summary <- 
  sheets %>% 
  map_dfr(~ tibble(nm = colnames(.)), .id = "sheet_name") %>%
  spread(nm, nm) %>%
  mutate_at(-1, ~ !is.na(.))

inconsistent_cols <- Filter(Negate(all), name_summary[-1])

# show columns that are not on every question
inconsistent_cols


# We need to fix typos and harmonise some names, we also remove the col "..19" as it's just an unnamed empty column.


for (nm in names(sheets)) {
sheets[[nm]][["...19"]] <- NULL
names(sheets[[nm]]) <- sub("organis ", "organic ", names(sheets[[nm]]))
names(sheets[[nm]]) <- sub("different ULRs/pages", "pages", names(sheets[[nm]]))
}

# now we try again
name_summary <- 
sheets %>% 
map_dfr(~ tibble(nm = colnames(.)), .id = "sheet_name") %>%
spread(nm, nm) %>%
mutate_at(-1, ~ !is.na(.))

inconsistent_cols <- Filter(Negate(all), name_summary[-1])
if (ncol(inconsistent_cols)) stop("we still have inconsistent column names")

#Now that we have consistent column names, we must ensure we have consistent type.

type_summary <- 
  sheets %>% 
  map_dfr(summarize_all, typeof, .id = "sheet_name")

inconsistent_cols <- Filter(function(x) n_distinct(x) != 1, type_summary[-1])

if (ncol(inconsistent_cols)) stop("we have inconsistent columns types")

# We can now concatenate the data of all questions in a single table


full_data <- bind_rows(sheets, .id = "question")
# remove row containing only NAs appart from é first columns
full_data <- full_data[rowSums(is.na(full_data)) != ncol(full_data) - 2,]
# convert Y/N/y/n to TRUE/FALSE
full_data <- modify_if(full_data, ~all(tolower(unique(.)) %in% c("y","n")), ~ tolower(.) == "y")

# We observe that item "If clicked on Google Maps/local listing, did they click on 
# one of the first three listings?" was assigned "N" when it is not relevant 
# (no click on google map listing) so we fix by setting those to `NA`.

full_data[["If clicked on Google Maps/local listing, did they click on one of the first three listings?"]] <- 
ifelse(full_data[["Clicks on Google Maps/local listings"]],
full_data[["If clicked on Google Maps/local listing, did they click on one of the first three listings?"]],
NA)

saveRDS(full_data, here::here("proc_data/clean_data.RDS"))



