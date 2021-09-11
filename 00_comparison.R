library(dplyr)
library(tidyr)
library(stringr)

rm(list = ls())

# read saved data
tj <- readRDS("data/tj_detail.rds") %>% select(-load_date)
sc <- readRDS("data/tj_schedule.rds") %>% select(-load_date)

# trafi data for routes and stops
trafi <- tj %>%
  mutate(trip = map(tj$route_info, "tracks")) %>%
  select(route_id = scheduleId,
         route_color = color,
         trip) %>%
  unnest(trip) %>%
  mutate(route_id = str_remove(route_id, "idjkb_"),
         route_id = str_remove(route_id, "brt_"),
         route_id = str_remove(route_id, "_royaltrans"),
         direction = direction - 1,
         shape_id = paste0("shp_", gsub("\\.", "_", .$id))) %>%
  rename("trip_id" = "id",
         "trip_headsign" = "name",
         "direction_id" = "direction") %>%
  # select(route_id, trip_id, trip_headsign, direction_id, shape_id, shape) %>%
  select(route_id, trip_headsign, direction_id, trip_id) %>%
  # create id for join
  mutate(trip_headsign = str_to_lower(trip_headsign),
         trip_headsign = str_squish(trip_headsign)) %>%
  mutate(id_join = paste(route_id, direction_id, sep = "_"),
         .before = "trip_id")
  # filtering JAK, OK
  # filter(!str_detect(route_id, "JAK"), !str_detect(route_id, "OK"))

# moovit data for scheduling
moovit <- sc %>%
  select(route_id, trip_headsign, direction_id) %>%
  mutate(id_join = paste(route_id, direction_id, sep = "_")) %>%
  distinct() %>%
  mutate(trip_headsign = str_to_lower(trip_headsign),
         trip_headsign = str_squish(trip_headsign))

# side by side table
o <- full_join(moovit, trafi, by = "id_join", suffix = c("_mo", "_tr")) %>%
  select(direction_id_mo, route_id_mo, trip_headsign_mo,
         trip_headsign_tr, route_id_tr, direction_id_tr, trip_id)

# save data for open in sheet
write.csv(o, "data/comparing.csv", row.names = FALSE)

