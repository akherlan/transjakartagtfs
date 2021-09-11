library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(googleway)
library(sf)

rm(list = ls())

# read data
tj <- readRDS("data/tj_detail.rds") %>% select(-load_date)
sc <- readRDS("data/tj_schedule.rds") %>% select(-load_date)

# trips -----
trips <- tj %>%
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
  select(route_id, trip_id, trip_headsign, direction_id, shape_id, shape) %>%
  # create id for join
  mutate(id_join = paste(route_id, direction_id, sep = "_"))

# calendar -----
# create service_id and calendar.txt
cal <- sc %>%
  mutate(day = tolower(day),
         id_join = paste(route_id, direction_id, sep = "_"),
         start_time = ifelse(!is.na(start_time), 1, 0)) %>%
  pivot_wider(id_cols = "id_join",
              names_from = "day",
              values_from = "start_time") %>%
  # create service_id
  pivot_longer(cols = matches("day"),
               names_to = "day",
               values_to = "operation") %>%
  mutate(initial = ifelse(operation == 1, day, "x"),
         initial = str_extract(initial, "^\\w{1}")) %>%
  pivot_wider(id_cols = "id_join",
              names_from = "day",
              values_from = "initial") %>%
  mutate(service_id = paste0(monday, tuesday, wednesday,
                             thursday, friday, saturday, sunday),
         service_id = ifelse(service_id == "mtwtfss", "fullday",
                             ifelse(service_id == "mtwtfxx", "weekday",
                                    ifelse(service_id == "xxxxxss", "weekend",
                                           service_id))),
         .after = id_join) %>%
  mutate(# back to operation = 1 and not operation = 0
         monday    = ifelse(monday == "x", 0L, 1L),
         tuesday   = ifelse(tuesday == "x", 0L, 1L),
         wednesday = ifelse(wednesday == "x", 0L, 1L),
         thursday  = ifelse(thursday == "x", 0L, 1L),
         friday    = ifelse(friday == "x", 0L, 1L),
         saturday  = ifelse(saturday == "x", 0L, 1L),
         sunday = ifelse(sunday == "x", 0L, 1L),
         # applied days
         start_date = as.character(format(Sys.Date(), "%Y%m%d")),
         end_date = "20211231")

# cal >< trips -->> new trips with service_id
# tj data from Trafi is main
trips <- trips %>%
  left_join(cal %>% select(id_join, service_id), by = "id_join")

# shapes -----
# function
convert_shape <- function(x, y) {
  x %>%
    st_as_sf(coords = c("lon", "lat")) %>%
    group_by(gr = y) %>%
    summarise(do_union = FALSE) %>%
    st_cast("LINESTRING") %>%
    ungroup() %>%
    select(geometry)
}

# shape_id, shape_pt_lat, shape_pt_lon, shape_pt_sequence,
# shape_dist_traveled

shapes <- trips %>%
  mutate(shape_decode = map(shape, decode_pl)) # decode polyline

# form geometry sf
# shapes <- shapes %>%
#   st_as_sf(coords = c("lon", "lat")) %>%
#   group_by_at(vars(-geometry, -stops)) %>%
#   summarise(do_union = FALSE, .groups = "drop") %>%
#   st_cast("LINESTRING")

shapes$shape_decode <- map(shapes$shape_decode, function(x) {
  mutate(x, shape_pt_sequence = 1:n())
})

shapes <- shapes %>%
  unnest(shape_decode) %>%
  select(shape_id,
         shape_pt_lat = lat,
         shape_pt_lon = lon,
         shape_pt_sequence)

# save data shapes
write.csv(shapes, "data/gtfs/shapes.txt", row.names = FALSE, na = "")

# save data trips
# route_id, service_id, trip_id, trip_headsign, trip_short_name,
# direction_id, shape_id
trips <- trips %>%
  select(route_id,
         service_id,
         trip_id,
         trip_headsign,
         direction_id,
         shape_id)

write.csv(trips, "data/gtfs/trips.txt", row.names = FALSE, na = "")

# save data calendar
cal <- cal %>%
  select(service_id,
         monday, tuesday, wednesday, thursday, friday, saturday, sunday,
         start_date, end_date) %>%
  distinct()

write.csv(cal, "data/gtfs/calendar.txt", row.names = FALSE, na = "")

