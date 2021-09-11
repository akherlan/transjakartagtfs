library(dplyr)
library(tidyr)

rm(list = ls())

# read data
sc <- readRDS("data/tj_schedule.rds")

# available weekly schedule, may various according to pull-data day
cal <- sc %>%
  select(route_id, direction_id, day, start_time) %>%
  mutate(day = tolower(day),
         id = paste(route_id, direction_id, sep = "_"),
         start_time = ifelse(!is.na(start_time), 1, 0)) %>%
  pivot_wider(id_cols = "id",
              names_from = "day",
              values_from = "start_time") %>%
  select(monday, tuesday, wednesday, thursday, friday, saturday, sunday) %>%
  distinct()

# calendar
cal <- cal %>%
  mutate(service_id = 1:n()) %>%
  pivot_longer(cols = -8, names_to = "day", values_to = "operation") %>%
  mutate(initial = ifelse(operation == 1, day, "x")) %>%
  mutate(initial = gsub("^(\\w{1}).+$", "\\1", .$initial)) %>%
  pivot_wider(id_cols = "service_id",
              names_from = "day",
              values_from = "initial") %>%
  mutate(service_id = paste0(monday, tuesday, wednesday,
                             thursday, friday, saturday, sunday),
         service_id = ifelse(service_id == "mtwtfss", "fullday",
                        ifelse(service_id == "mtwtfxx", "weekday",
                          ifelse(service_id == "xxxxxss", "weekend",
                             service_id))),
         # back to operation = 1 and not operation = 0
         monday    = ifelse(monday == "x", 0L, 1L),
         tuesday   = ifelse(tuesday == "x", 0L, 1L),
         wednesday = ifelse(wednesday == "x", 0L, 1L),
         thursday  = ifelse(thursday == "x", 0L, 1L),
         friday    = ifelse(friday == "x", 0L, 1L),
         saturday  = ifelse(saturday == "x", 0L, 1L),
         sunday    = ifelse(sunday == "x", 0L, 1L),
         # applied days
         start_date = as.character(format(Sys.Date(), "%Y%m%d")),
         end_date = "20211231") # PPKM level 3 until ????

# save data
write.csv(cal, "data/gtfs/calendar.txt", row.names = FALSE, na = "")
