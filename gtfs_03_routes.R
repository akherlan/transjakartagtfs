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
         route_id = gsub("idjkb_", "", .$route_id))

# save data
write.csv(routes, "data/gtfs/routes.txt", row.names = FALSE)
