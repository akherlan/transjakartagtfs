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

alternate <- gsub("\\d{1}$", "1", link)

route_name <- gsub("^.+line-(\\w+)-Jakarta.+", "\\1", link)

sch_url <- bind_cols(route_name, route, link, alternate)
names(sch_url) <- c("name", "route", "url_direction", "url_alternate")

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
alert_alternate <- map(sch_url$url_alternate, get_alert)
alert_alternate <- map_chr(alert_alternate, length)
alert_alternate <- ifelse(alert_alternate > 0, "No Service", "Operation")

# add alert column
sch_url <- bind_cols(sch_url, alert_direction, alert_alternate) %>%
  rename("alert_direction" = "...5",
         "alert_alternate" = "...6")

# get schedules
get_schedule <- function(url_char) {
  read_html(url_char) %>%
    html_table() %>%
    .[[1]]
}

trans_schedule <- function(t) {
  t %>%
  rename("day" = "Day", "oh" = "Operating Hours") %>%
  mutate(oh = ifelse(oh == "Not Operational", NA, oh)) %>%
  separate(col = 2, into = c("start_time", "end_time"), sep = " - ") %>%
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

# to be continue

saveRDS(sch_url, "data/schedule_list.rds")
