library(tidyverse)

# read data
df_tj <- readRDS("tj_detail.rds")

# checking
df_tj %>%
  filter(name == "2B") %>%
  .$route_info %>%
  .[[1]] %>%
  .$stops %>%
  View()

df_tj$route_info[[1]]

map(df_tj$route_info, "id")
map(df_tj$route_info, "name")
map(df_tj$route_info, "stops")
map(df_tj$route_info, "tracks")

# create halte data
df_tj <- df_tj %>%
  as.tibble() %>%
  mutate(halte_detail = map(df_tj$route_info, "stops"))

df_halte <- df_tj %>%
  select(schedule_id = scheduleId,
         transport_id = transportId,
         validity,
         name, long_name = longName, color,
         halte_detail) %>%
  unnest() %>%
  rename(halte_id = id,
         halte_name = name1,
         area_name = areaName,
         direction_name = directionName)

df_halte_final <- df_halte %>%
  group_by(halte_id, halte_name, lat, lng) %>%
  summarise(route_cnt = n_distinct(schedule_id),
            schedule_id = list(unique(schedule_id))) %>%
  ungroup() %>%
  rename(latitude = lat, longitude = lng)

# finalization
transjakarta <- df_halte_final %>%
  select(everything(), schedule_id, corridor_cnt = route_cnt)

# save halte data to nusantr
devtools::use_data(transjakarta,
                   pkg = "data",
                   internal = FALSE,
                   overwrite = TRUE)
