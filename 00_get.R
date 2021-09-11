library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)

rm(list = ls())

# get route info
main_url <- "https://web.trafi.com/api/schedules/jakarta/"
tj <- paste0(main_url, "all?transportType=")
tj <- fromJSON(paste0(tj, "transjakarta"))[[1]]

tj <- tj[,2:3] %>% unnest("schedules")

# get details for each route
tj <- tj %>%
  mutate(path = sprintf("schedule?scheduleId=%s&transportType=transjakarta",
                        scheduleId))

# wait a while looping around with purrr::map (use base looping for managable iteration)
tj <- tj %>%
  mutate(route_info = map(paste0(main_url, .$path), fromJSON),
         load_date = Sys.Date())

# save data
saveRDS(tj, "data/tj_detail.rds")
