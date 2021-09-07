library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(rvest)

rm(list = ls())

# data
sch_url <- readRDS("data/schedule_list.rds")

# function
get_schedule <- function(url_char) {
  read_html(url_char) %>%
    # html_table() %>%
    # .[[1]]
    html_table()
}

trans_schedule <- function(t) {
  t %>%
    rename("day" = "Day", "oh" = "Operating Hours") %>%
    mutate(oh = ifelse(oh == "Not Operational", NA, oh)) %>%
    separate(col = "oh", into = c("start_time", "end_time"), sep = " - ") %>%
    mutate(start_time = ifelse(str_detect(start_time, "AM"),
                               str_remove(start_time, "\\s?AM"),
                               paste(as.numeric(gsub(pattern = "^(\\d{1,2})\\:\\d{2}\\sPM$",
                                                     replacement = "\\1",
                                                     x = .$start_time)) + 12,
                                     gsub(pattern = "^\\d{1,2}:(\\d{2})\\sPM$",
                                          replacement = "\\1",
                                          x = .$start_time),
                                     sep = ":")),
           start_time = ifelse(!is.na(start_time), paste(start_time, "00", sep = ":"), start_time),
           end_time = ifelse(str_detect(end_time, "AM"),
                             str_remove(end_time, "\\s?AM"),
                             paste(as.numeric(gsub(pattern = "^(\\d{1,2})\\:\\d{2}\\sPM$",
                                                   replacement = "\\1",
                                                   x = .$end_time)) + 12,
                                   gsub(pattern = "^\\d{1,2}:(\\d{2})\\sPM$",
                                        replacement = "\\1",
                                        x = .$end_time),
                                   sep = ":")),
           end_time = ifelse(!is.na(end_time), paste(end_time, "00", sep = ":"), end_time))
}


sch_list <- sch_url %>%
  pivot_longer(cols = 3:4, names_to = "direction", values_to = "url") %>%
  select(-matches("alert_")) %>%
  mutate(schedule = map(url, get_schedule))

cal <- sch_list %>%
  select(name, route, direction, schedule) %>%
  unnest(schedule) %>%
  unnest(schedule) %>%
  distinct() %>%
  trans_schedule() %>%
  mutate(day = tolower(day))

cal <- cal %>%
  select(name, direction, day, start_time) %>%
  mutate(id = paste(name, direction, sep = "_"),
         start_time = ifelse(!is.na(start_time), 1, 0)) %>%
  pivot_wider(id_cols = "id",
              names_from = "day",
              values_from = "start_time") %>%
  select(monday, tuesday, wednesday, thursday, friday, saturday, sunday) %>%
  distinct() %>%
  mutate(service_id = c("full", "wday", "wend", "sat", "wend_mon", "sun"),
         .before = "monday") %>%
  mutate(start_date = as.character(format(Sys.Date(), "%Y%m%d")),
         end_date = "20211231") # PPKM level 3 until ????

# save data
write.csv(cal, "data/gtfs/calendar.txt", row.names = FALSE)
