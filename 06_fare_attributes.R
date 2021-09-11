library(tibble)

rm(list = ls())

# https://transjakarta.co.id/produk-dan-layanan/info-tiket/
# 05:00-07:00 IDR 2000
# 07:00-24:00 IDR 3500
# 24:00-05:00 IDR 3500

fare <- tibble::tribble(
  ~fare_id,     ~price, ~currency_type, ~payment_method, ~transfers, ~agency_id,
  "brt-pagi",    2000,   "IDR",          1,               NA,         "brt",
  "brt-regular", 3500,   "IDR",          1,               NA,         "brt",
  "brt-malam",   3500,   "IDR",          1,               NA,         "brt",
  "brt-free",    0,      "IDR",          1,               NA,         "freebus",
  "tj-angkot",   NA,     "IDR",          0,               NA,         "jaklingko",
  "tj-royal",    NA,     "IDR",          1,               NA,         "royaltrans"
)

# save data
write.csv(fare, "data/gtfs/fare_attributes.txt", row.names = FALSE, na = "")
