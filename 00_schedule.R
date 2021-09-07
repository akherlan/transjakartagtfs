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

