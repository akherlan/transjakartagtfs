library(dplyr)

rm(list = ls())

tj <- readRDS("data/tj_detail.rds")

# agency_id, agency_name, agency_url, agency_timezone

agency <- tj %>%
  select(agency_id = transportId,
         agency_name = transportName) %>%
  distinct() %>%
  mutate(agency_id = gsub("idjkb_", "", .$agency_id),
         agency_url = c("https://transjakarta.co.id",
                        "https://transjakarta.co.id",
                        "https://www.jaklingkoindonesia.co.id/id",
                        "https://transjakarta.co.id"),
         agency_timezone = "Asia/Jakarta") %>%
  mutate(agency_id = gsub("tj-", "", .$agency_id))

# save data
write.csv(agency, "data/gtfs/agency.txt", row.names = FALSE, na = "")
