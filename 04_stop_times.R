library(dplyr)
library(tidyr)
library(purrr)

rm(list = ls())

# read data
tj <- readRDS("data/tj_detail.rds")

# trip_id, arrival_time, departure_time, stop_id, stop_sequence

stimes <- tj %>%
  mutate(trip = map(tj$route_info, "tracks")) %>%
  select(route_id = scheduleId,
         route_color = color,
         trip) %>%
  unnest(trip) %>%
  select(trip_id = id, stops)

# add stop_sequence
stimes$stops <- map(stimes$stops, function(ls_stop) {
  mutate(ls_stop, stop_sequence = 1:n())
})

stimes <- stimes %>%
  unnest(stops) %>%
  mutate(stop_id = gsub("idjkb_", "", .$stopId)) %>%
  select(trip_id, stop_id, stop_sequence)

# save data
write.csv(stimes, "data/gtfs/stop_times.txt", row.names = FALSE, na = "")
