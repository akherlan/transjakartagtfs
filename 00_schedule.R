library(dplyr)
library(tidyr)
library(purrr)
library(rvest)
library(stringr)

rm(list = ls())

# get html
url <- "https://moovitapp.com/index/en/public_transit-lines-Jakarta-2044-851786"
h <- read_html(url)

# forming a list url table
link <- h %>%
  html_elements("div.lines-container") %>%
  html_elements("li.line-item") %>%
  html_elements("a") %>%
  html_attr("href")

route <- h %>%
  html_elements("div.lines-container") %>%
  html_elements("li.line-item") %>%
  html_elements("strong.line-title") %>%
  html_text()

contra <- gsub("\\d{1}$", "1", link)

route_name <- gsub("^.+line-(\\w+)-Jakarta.+", "\\1", link)

sch_url <- bind_cols(route_name, route, link, contra)
names(sch_url) <- c("name", "route", "url_direction", "url_contra")

# get alert
get_alert <- function(x){
  x %>%
    read_html() %>%
    html_elements("label.alert-header") %>%
    html_text() %>%
    str_squish()
}

# caution: takes time!
alert_direction <- map(sch_url$url_direction, get_alert)
alert_direction <- map_chr(alert_direction, length)
alert_direction <- ifelse(alert_direction > 0, "No Service", "Operation")

# caution: takes time!
alert_contra <- map(sch_url$url_contra, get_alert)
alert_contra <- map_chr(alert_contra, length)
alert_contra <- ifelse(alert_contra > 0, "No Service", "Operation")

# add alert column
sch_url <- bind_cols(sch_url, alert_direction, alert_contra) %>%
  rename("alert_direction" = "...5",
         "alert_contra" = "...6") %>%
  mutate(load_date = Sys.Date())

# save url list
saveRDS(sch_url, "data/schedule_list.rds")

# sch_url <- readRDS("data/schedule_list.rds")

# function for pull schedules
get_schedule <- function(url_char) {
  read_html(url_char) %>%
    # html_table() %>%
    # .[[1]]
    html_table()
}

# function for time transformation
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

# gather schedule tables
sch_list <- sch_url %>%
  pivot_longer(cols = 3:4, names_to = "direction", values_to = "url") %>%
  select(-matches("alert_")) %>%
  mutate(schedule = map(url, get_schedule))

sch_list <- sch_list %>%
  select(name, route, direction, schedule, load_date) %>%
  mutate(direction == "url_contra", 1, 0) %>%
  unnest(schedule) %>%
  distinct()

# time transformation
sch_list <- sch_list %>%
  select(name, route, direction, schedule, load_date) %>%
  unnest(schedule) %>%
  trans_schedule()

# save data
saveRDS(sch_list, "data/tj_schedule.rds")

