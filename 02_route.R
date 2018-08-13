library(tidyverse)
library(googleway)
library(sf)
library(stringr)

# read data
df_tj <- readRDS("tj_detail.rds")

# transform data
df_tj <- df_tj %>%
  as.tibble() %>%
  mutate(halte_detail = map(df_tj$route_info, "stops"),
         route = map(df_tj$route_info, "tracks")) %>%
  select(-route_info)

df_route <- df_tj %>%
  select(schedule_id = scheduleId,
         transport_id = transportId,
         validity,
         name, long_name = longName, color,
         route) %>%
  unnest() %>%
  rename(route_name = name1,
         is_hidden = isHidden)

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

# decode polyline
df_route <- df_route %>%
  mutate(shape_decode = map(shape, decode_pl)) %>%
  unnest(shape_decode)

# form geometry
df_route <- df_route %>%
  st_as_sf(coords = c("lon", "lat")) %>%
  group_by_at(vars(-geometry)) %>%
  summarise(do_union = FALSE) %>%
  st_cast("LINESTRING")

# viz test
ggplot() +
  geom_sf(data = df_route %>%
            filter(is_hidden == FALSE,
                   direction == 1),
          aes(color = route_name)) +
  guides(color = FALSE)

# finalization
transjakarta_route <- df_route %>%
  select(transport_id,
         schedule_id,
         corridor_id = name,
         corridor_name = long_name,
         corridor_color = color,
         route_id = id,
         route_name,
         direction,
         validity,
         is_hidden)

transjakarta_route <- transjakarta_route %>%
  as.tibble() %>%
  st_as_sf()

st_crs(transjakarta_route) <- 4326

# set main route
transjakarta_route <- transjakarta_route %>%
  group_by(corridor_id, direction) %>%
  mutate(n = n()) %>%
  ungroup() %>%
  mutate(is_main = ifelse(corridor_name == route_name, TRUE, FALSE),
         is_main_reverse = ifelse(corridor_name ==
                                    paste0(str_extract(route_name, "(?<=- ).*$"),
                                           " - ",
                                           str_extract(route_name, "^.*(?= -)")),
                                  TRUE, FALSE)) %>%
  mutate(is_main = ifelse(n == 1 & direction == 1, TRUE, is_main),
         is_main_reverse = ifelse(n == 1 & direction == 2, TRUE, is_main_reverse))

# listed corridor_id
ua <- filter(transjakarta_route, is_main == TRUE | is_main_reverse == TRUE)$corridor_id %>%
  unique()
ua_neg <- setdiff(unique(transjakarta_route$corridor_id), ua)
n_distinct(transjakarta_route$corridor_id) - n_distinct(ua) # 7 corridor id do not have main
transjakarta_route %>%
  filter(corridor_id %in% ua_neg, is_hidden == FALSE) %>%
  .$corridor_id %>%
  n_distinct() # still 7 use is_hidden argument

transjakarta_route <- transjakarta_route %>%
  mutate(is_main = ifelse(corridor_id %in% ua_neg &
                            is_hidden == FALSE &
                            direction == 1, TRUE, is_main),
         is_main_reverse = ifelse(corridor_id %in% ua_neg &
                                    is_hidden == FALSE &
                                    direction == 2, TRUE, is_main_reverse)) %>%
  select(-n, -is_hidden)


# save route data to nusantr
devtools::use_data(transjakarta_route,
                   pkg = "data",
                   internal = FALSE,
                   overwrite = TRUE)

# others exploration
transjakarta_route %>%
  as.data.frame() %>%
  select(-geometry) %>%
  count(corridor_id, corridor_name) %>%
  select(-n) %>%
  group_by(corridor_name) %>%
  mutate(n = n()) %>%
  filter(n >= 2) %>%
  arrange(corridor_name)

