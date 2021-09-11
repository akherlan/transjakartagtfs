library(dplyr)
library(tidyr)

rm(list = ls())

# read data
tj <- readRDS("data/tj_detail.rds")

# route_id, agency_id, route_short_name, route_long_name, route_color,
# route_type, route_text_color, route_sort_order

routes <- tj %>%
  select(route_id = scheduleId,
         agency_id = transportId,
         route_short_name = name,
         route_long_name = longName,
         route_color = color) %>%
  mutate(agency_id = gsub("idjkb_", "", .$agency_id),
         route_id = gsub("idjkb_", "", .$route_id),
         route_type = 3)

# route_type
# 0  : Tram, Streetcar, Light rail. Any light rail or street level system within a metropolitan area.
# 1  : Subway, Metro. Any underground rail system within a metropolitan area.
# 2  : Rail. Used for intercity or long-distance travel.
# 3  : Bus. Used for short- and long-distance bus routes.
# 4  : Ferry. Used for short- and long-distance boat service.
# 5  : Cable tram. Used for street-level rail cars where the cable runs beneath the vehicle (e.g., cable car in San Francisco).
# 6  : Aerial lift, suspended cable car (e.g., gondola lift, aerial tramway). Cable transport where cabins, cars, gondolas or open chairs are suspended by means of one or more cables.
# 7  : Funicular. Any rail system designed for steep inclines.
# 11 : Trolleybus. Electric buses that draw power from overhead wires using poles.
# 12 : Monorail. Railway in which the track consists of a single rail or a beam.

# save data
write.csv(routes, "data/gtfs/routes.txt", row.names = FALSE, na = "")
