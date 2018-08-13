library(jsonlite)
library(tidyverse)

# get route info
main_url <- "https://www.trafi.com/api/schedules/jakarta/"
route <- paste0(main_url, "all?transportType=")

df_tj <- fromJSON(paste0(route, "transjakarta"))[[1]] %>% unnest()
df_krl <- fromJSON(paste0(route, "train"))[[1]] %>% unnest()

# get details for each route
route_det <- function(schedule_id, transport) {
  paste0(main_url, "schedule?scheduleId=", schedule_id, "&transportType=", transport)
}

# wait a while looping around with purrr::map (use base looping for managable iteration)
df_tj <- df_tj %>%
  mutate(route_url = map2_chr(scheduleId, "transjakarta", route_det),
         route_info = map(route_url, fromJSON),
         load_date = Sys.Date())

# save data (latest 25 June 2018)
saveRDS(df_tj, "tj_detail.rds")




