library(tidyverse)
library(sf)
library(mrsq)
library(googleway)

# get route
tj <- read_rds("data/tj_route.rds") %>%
  filter(direction == 1,
         is_main == TRUE)

# get halte (convert to sf class)
tjh <- read_rds("data/tj_halte.rds") %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# color palette
tj_color <- paste0("#", tj$corridor_color)
names(tj_color) <- tj$corridor_id
bg_color <- "gray10"

# viz route data
ggplot() +
  geom_sf(data = tj, aes(color = corridor_id)) +
  coord_sf(datum = NA) +
  theme_nunito() +
  guides(color = FALSE) +
  scale_color_manual(values = tj_color) +
  labs(caption = "Rasyid Ridha (rasyidridha.com)
       source: trafi.com\ndate: 7 November 2018")
  # theme(panel.background = element_rect(fill = bg_color, color = bg_color),
  #       plot.background = element_rect(fill = bg_color, color = bg_color),
  #       strip.background = element_rect(fill = bg_color, color = bg_color),
  #       plot.caption = element_text(color = "white"))
ggsave("figs/tj_route_20191107.png", width = 8, height = 6, bg = "transparent")

# EDA
# longest / shortest route
tj <- tj %>%
  mutate(route_length = as.numeric(st_length(geometry)) * 10^-3)
tj_top10 <- tj %>%
  top_n(10, route_length)
tj_bottom10 <- tj %>%
  top_n(-10, route_length)

# viz top
tj_color <- paste0("#", tj_top10$corridor_color)
names(tj_color) <- tj_top10$corridor_id

tj_top10 %>%
  mutate(corridor_name = paste0(corridor_name, " [", corridor_id, "]")) %>%
  ggplot(aes(reorder(corridor_name, route_length), route_length, fill = corridor_id)) +
  geom_col() +
  coord_flip() +
  theme_nunito(grid = "") +
  labs(x = NULL, y = NULL) +
  guides(fill = FALSE) +
  scale_fill_manual(values = tj_color) +
  geom_text(aes(label = paste(round(route_length, 2), "km")),
            color = "white",
            family = "Neo Sans Pro",
            hjust = 1.2) +
  theme(axis.text.x = element_blank())
ggsave("figs/tj_top10.png", width = 10, height = 4, bg = "transparent", dpi = 150)

ggplot() +
  geom_sf(data = tj, color = "grey95") +
  geom_sf(data = tj_top10, aes(color = corridor_id)) +
  coord_sf(datum = NA) +
  theme_nunito() +
  guides(color = FALSE) +
  scale_color_manual(values = tj_color)
ggsave("figs/tj_route_top10.png", width = 8, height = 6, bg = "transparent", dpi = 200)

# viz bottom
tj_color <- paste0("#", tj_bottom10$corridor_color)
names(tj_color) <- tj_bottom10$corridor_id
tj_bottom10 %>%
  mutate(corridor_name = paste0(corridor_name, " [", corridor_id, "]")) %>%
  ggplot(aes(reorder(corridor_name, -route_length), route_length, fill = corridor_id)) +
  geom_col() +
  coord_flip() +
  theme_nunito(grid = "") +
  labs(x = NULL, y = NULL) +
  guides(fill = FALSE) +
  scale_fill_manual(values = tj_color) +
  geom_text(aes(label = paste(round(route_length, 2), "km")),
            color = "white",
            family = "Neo Sans Pro",
            hjust = 1.2) +
  theme(axis.text.x = element_blank())
ggsave("figs/tj_bottom10.png", width = 10, height = 4, bg = "transparent", dpi = 150)

ggplot() +
  geom_sf(data = tj, color = "grey95") +
  geom_sf(data = tj_bottom10, aes(color = corridor_id)) +
  coord_sf(datum = NA) +
  theme_nunito() +
  guides(color = FALSE) +
  scale_color_manual(values = tj_color)
ggsave("figs/tj_route_bottom10.png", width = 8, height = 6, bg = "transparent", dpi = 200)


