library(dplyr)
library(tidyr)
library(purrr)
library(googleway)
# library(sf)

rm(list = ls())

# read data
tj <- readRDS("data/tj_detail.rds")

# trips -----

# route_id, service_id, trip_id, trip_headsign, trip_short_name,
# direction_id, shape_id

trips <- tj %>%
  mutate(trip = map(tj$route_info, "tracks")) %>%
  select(route_id = scheduleId,
         route_color = color,
         trip) %>%
  unnest(trip) %>%
  mutate(route_id = gsub("idjkb_", "", .$route_id),
         direction = direction - 1,
         shape_id = paste0("shp_", gsub("\\.", "_", .$id))) %>%
  rename("trip_id" = "id",
         "trip_headsign" = "name",
         "direction_id" = "direction") %>%
  select(route_id, trip_id, trip_headsign, direction_id, shape_id, shape)

# add service_id based on schedule from moovit

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
write.csv(shapes, "data/gtfs/shapes.txt", row.names = FALSE)

# save data trips
trips <- trips %>% select(-shape)
write.csv(trips, "data/gtfs/trips.txt", row.names = FALSE)

