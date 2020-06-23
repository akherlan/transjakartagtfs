library(tidyverse)
library(lubridate)
library(nusantr)
library(mrsq)
library(geosphere)
library(gganimate)


# prep --------------------------------------------------------------------
tj_all <- list.files("data", full.names = TRUE) %>%
  map_df(read_rds) %>%
  # filter(koridor == "T11") %>%
  mutate_at(vars(longitude, latitude, speed, course), as.numeric) %>%
  arrange(buscode, gpsdatetime)
  # group_by(buscode) %>%
  # arrange(desc(load_time)) %>%
  # mutate(r = row_number(),
  #        is_last = ifelse(r == 1, TRUE, FALSE)) %>%
  # arrange(load_time) %>%
  # mutate(r2 = row_number(),
  #        is_first = ifelse(r2 == 1, TRUE, FALSE)) %>%
  # ungroup() %>%
  # arrange(buscode, current_tripid, load_time)
tj_all <- tj_all %>%
  mutate(gpsdatetime = ymd_hms(gpsdatetime, tz = "Asia/Jakarta"))
tj_all <- tj_all %>%
  filter(gpsdatetime >= ymd_hms(20191126140000, tz = "Asia/Jakarta"))
tj_all %>%
  rename(bus_code = buscode,
         trip_id = current_tripid,
         gps_datetime = gpsdatetime,
         corridor = koridor) %>%
  select(-voiceno, -load_time, -trip_name) %>%
  filter(gps_datetime >= ymd_hms(20191126140000, tz = "Asia/Jakarta"),
         gps_datetime < ymd_hms(20191126180000, tz = "Asia/Jakarta")) %>%
  write.csv("data/transjakarta_gps.csv", row.names = FALSE)

# calculate speed and distance from previous longitude-latitude
tj_all <- tj_all %>%
  group_by(buscode) %>%
  mutate(time_diff = as.numeric(gpsdatetime - lag(gpsdatetime)) ,
         distance_diff = distHaversine(cbind(longitude, latitude),
                                       cbind(lag(longitude), lag(latitude))) / 1000,
         speed_derive = distance_diff / (time_diff/3600)) %>%
  filter(time_diff != 0) %>%
  ungroup() %>%
  # filter anomaly above 100 km/h
  mutate(is_speed_anomaly = ifelse(speed_derive >= 100 | speed >= 100, TRUE, FALSE),
         is_interval_high = ifelse(time_diff >= 60, TRUE, FALSE))

# wrangle -----------------------------------------------------------------
# bus summary
summary_tj_all <- tj_all %>%
  mutate(distance_diff = ifelse(speed_derive >= 100, mean(distance_diff), distance_diff),
         speed_derive = ifelse(speed_derive >= 100, mean(speed_derive), speed_derive),
         speed = ifelse(speed >= 100, mean(speed), speed)) %>%
  group_by(buscode, koridor, current_tripid) %>%
  summarise(data_cnt = n(),
            anomaly_cnt = sum(ifelse(is_speed_anomaly, 1, 0)),
            anomaly_pct = anomaly_cnt / data_cnt,
            highint_cnt = sum(ifelse(is_interval_high, 1, 0)),
            highint_pct = highint_cnt / data_cnt,
            start_time = min(gpsdatetime),
            end_time = max(gpsdatetime),
            speed_avg = mean(speed),
            speed_median = median(speed),
            speed2_avg = mean(speed_derive),
            speed2_median = median(speed_derive),
            distance_total = sum(distance_diff),
            duration = sum(time_diff)) %>%
  ungroup()

summary_trip <- summary_tj_all %>%
  group_by(koridor, current_tripid) %>%
  summarise(data_cnt = sum(data_cnt),
            anomaly_cnt = sum(anomaly_cnt),
            anomaly_pct = anomaly_cnt / data_cnt,
            highint_cnt = sum(highint_cnt),
            highint_pct = highint_cnt / data_cnt,
            trip_cnt = n_distinct(current_tripid),
            bus_cnt = n_distinct(buscode),
            speed_avg_avg = mean(speed_avg),
            speed_median_avg = mean(speed_median),
            speed2_avg_avg = mean(speed2_avg),
            speed2_median_avg = mean(speed2_median),
            distance_avg = mean(distance_total),
            distance_total = sum(distance_total))

# koridor summary
summary_koridor <- summary_tj_all %>%
  group_by(koridor) %>%
  summarise(data_cnt = sum(data_cnt),
            anomaly_cnt = sum(anomaly_cnt),
            anomaly_pct = anomaly_cnt / data_cnt,
            highint_cnt = sum(highint_cnt),
            highint_pct = highint_cnt / data_cnt,
            trip_cnt = n_distinct(current_tripid),
            bus_cnt = n_distinct(buscode),
            speed_avg_avg = mean(speed_avg),
            speed_median_avg = mean(speed_median),
            speed2_avg_avg = mean(speed2_avg),
            speed2_median_avg = mean(speed2_median),
            distance_avg = mean(distance_total),
            distance_total = sum(distance_total))

# viz ---------------------------------------------------------------------
smpl <- sample(unique(tj_all$buscode), 1)
smpl <- "TJ 0545"
smpl <- "MYS 17011"

# number of bus per 10 minutes
summary_time <- tj_all %>%
  filter(gpsdatetime < ymd_hms(20191126180000, tz = "Asia/Jakarta")) %>%
  mutate(time_group = floor_date(gpsdatetime, unit = "10 minutes")) %>%
  group_by(time_group) %>%
  summarise(bus_cnt = n_distinct(buscode),
            bus_onjob_cnt = length(unique(buscode[koridor != "0"])),
            speed_avg = mean(ifelse(koridor != "0", speed, NA), na.rm = TRUE),
            speed2_avg = mean(ifelse(koridor != "0", speed_derive, NA), na.rm = TRUE))

summary_time %>%
  ggplot() +
  geom_line(aes(time_group, speed_avg), color = "steelblue", alpha = 0.7) +
  geom_line(aes(time_group, speed2_avg), color = "black", alpha = 0.7) +
  theme_nunito()

summary_time %>%
  ggplot(aes(time_group, bus_onjob_cnt)) +
  geom_line() +
  theme_nunito()

# speed
tj_all %>%
  filter(buscode == smpl) %>%
  ggplot() +
  geom_line(aes(gpsdatetime, speed),
            color = "black",
            alpha = 0.7) +
  geom_line(aes(gpsdatetime, speed_derive),
            color = "steelblue",
            alpha = 0.7) +
  theme_nunito()

# radius
tj_all %>%
  filter(buscode == smpl) %>%
  ggplot(aes(gpsdatetime, course)) +
  geom_line() +
  theme_nunito()

# longitude-latitude
tj_all %>%
  filter(buscode == smpl) %>%
  ggplot(aes(longitude, latitude)) +
  geom_point() +
  theme_nunito()

transjakarta_route %>%
  filter(is_main) %>%
  ggplot() +
  geom_sf(size = 0.05) +
  geom_point(data = tj_all %>%
               filter(buscode == smpl),
             aes(longitude, latitude),
             color = "steelblue",
             size = 0.1,
             alpha = 0.8) +
  coord_sf(datum = NA) +
  theme_nunito() +
  labs(x = NULL, y = NULL) +
  guides(color = FALSE)

smpl_time <- sample(unique(tj_all$load_time), 1)
transjakarta_route %>%
  filter(is_main) %>%
  ggplot() +
  geom_sf(size = 0.05) +
  geom_point(data = tj_all %>%
               filter(load_time == smpl_time, koridor != "0"),
             aes(longitude, latitude),
             color = "red",
             size = 0.1,
             alpha = 0.8) +
  coord_sf(datum = NA) +
  theme_nunito() +
  labs(x = NULL, y = NULL) +
  guides(color = FALSE)

# animation
library(gganimate)
tj_all %>%
  filter(buscode == smpl) %>%
  filter(gpsdatetime >= ymd_hms(20191126140000, tz = "Asia/Jakarta"),
         gpsdatetime <= ymd_hms(20191126180000, tz = "Asia/Jakarta")) %>%
  ggplot(aes(longitude, latitude)) +
  geom_point(color = "red",
             size = 0.05,
             alpha = 0.8) +
  transition_time(gpsdatetime) +
  theme_nunito()

## speed exploration
summary_tj_all <- tj_all %>%
  group_by(buscode, current_tripid, koridor) %>%
  summarise(data_cnt = n(),
            speed_avg = mean(speed),
            speed_median = median(speed),
            speed_max = max(speed))

summary_koridor <- summary_tj_all %>%
  group_by(koridor) %>%
  summarise(data_cnt = n(),
            bus_cnt = n_distinct(buscode),
            speed_avg_all = mean(speed_avg),
            speed_median_all = median(speed_avg),
            speed_max_all = max(speed_avg))

# all viz



