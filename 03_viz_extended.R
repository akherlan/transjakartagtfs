library(tidyverse)
library(sf)
library(mrsq)
library(googleway)
library(nusantr)
library(lubridate)

# extended version
# add halte
# add number of halte or route per area (kecamatan)

# get route
tj <- read_rds("data/tj_route.rds") %>%
  filter(direction == 1,
         is_main == TRUE)

# get halte (convert to sf class)
tjh <- read_rds("data/tj_halte.rds") %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# peta jakarta
jkt <- id_map("jakarta", level = "kecamatan") %>%
  filter(kota != "Kepulauan Seribu")

# color palette
tj_color <- paste0("#", tj$corridor_color)
names(tj_color) <- tj$corridor_id
bg_color <- "gray10"


# viz route ---------------------------------------------------------------
ggplot() +
  geom_sf(data = tj, aes(color = corridor_id)) +
  geom_sf(data = tjh, color = "black", size = 0.05, alpha = 0.5) +
  coord_sf(datum = NA) +
  theme_nunito() +
  guides(color = FALSE) +
  scale_color_manual(values = tj_color) +
  labs(caption = "Rasyid Ridha (rasyidridha.com)
       source: trafi.com\ndate: 7 November 2019")
ggsave("figs/tj_route_20191107_extended.png", width = 8, height = 6, bg = "transparent")


# viz jkt map -------------------------------------------------------------
jkt_tjh <- jkt %>%
  st_join(tjh) %>%
  count(provinsi_id, provinsi, kota_id, kota, kecamatan_id, kecamatan)

ggplot() +
  geom_sf(data = jkt_tjh, aes(fill = n), color = "grey10", size = 0.05) +
  geom_sf(data = tj, color = "white", size = 0.05, alpha = 0.2) +
  coord_sf(datum = NA) +
  theme_nunito() +
  scale_fill_viridis_c("# of Halte") +
  theme(legend.position = "bottom")
ggsave("figs/tj_halte_kecamatan.png", width = 8, height = 6, bg = "transparent")



# 2018 vs 2019 ------------------------------------------------------------
tj_2018 <- read_rds("data/20180625/tj_route.rds")
tjh_2018 <- read_rds("data/20180625/tj_halte.rds")

bind_rows(tj %>%
            mutate(dt = ymd(20191107),
                   route_length = as.numeric(st_length(geometry)) * 10^-3) %>%
            as_tibble() %>%
            select(-geometry),
          tj_2018 %>%
            mutate(dt = ymd(20180625),
                   route_length = as.numeric(st_length(geometry)) * 10^-3) %>%
            as_tibble() %>%
            select(-geometry)) %>%
  select(dt, corridor_id, corridor_name, route_length) %>%
  arrange(desc(corridor_name)) %>%
  group_by(dt, corridor_id, corridor_name) %>%
  summarise(n = n(), route_length = max(route_length)) %>%
  ungroup() %>%
  group_by(dt) %>%
  arrange(desc(n), desc(route_length)) %>%
  summarise(corridor_n = n(),
            route_length_median = median(route_length),
            route_length_avg = mean(route_length),
            route_length_sum = sum(route_length)) %>%
  ungroup()

n_distinct(tjh_2018$halte_name)
n_distinct(tjh$halte_name)
