library(jsonlite)
library(tidyverse)
library(lubridate)

url <- "http://202.51.117.212/transjakarta_bus_ops_api_unified_with_tripdata_master.php"

tj_ingest <- function() {
  tryCatch(fromJSON(url)[[1]] %>%
             mutate(load_time = current_time) %>%
             as_tibble() %>%
             saveRDS(paste0("data/realtime/transjakarta_realtime_",
                            format(current_time, "%Y%m%d%H%M%S"),
                            ".rds")),
           error = function(e) {
             tibble(load_time = current_time) %>%
               saveRDS(paste0("data/realtime/transjakarta_realtime_",
                              format(current_time, "%Y%m%d%H%M%S"),
                              "_FAIL.rds"))
           })
}

# current_time <- Sys.time()
# tj_ingest()
# Sys.sleep(30) # wait 30 seconds
# tj_ingest()
# Sys.sleep(30)

# execution example
while (ymd_hms(20191126180000, tz = "Asia/Jakarta") > Sys.time()) {
  current_time <- Sys.time()
  tj_ingest()
  message("Data is ingested at ", current_time)
  Sys.sleep(30)
}
