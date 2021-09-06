# GTFS Transjakarta

Create Transjakarta datasets in GTFS format using R.

-   `00_get.R` for getting Transjakarta routes and stops details
-   `01_agency.R`, `02_stops.R`, `03_routes.R`, `04_trips_shapes.R` for creating GTFS txt files
-   `01_get_realtime.R` for getting real-time Transjakarta GPS data
-   `03_viz.R` for Transjakarta dataset visualization
-   `playground_realtime.R` for play around with real-time data (need to run `01_get_realtime.R` first)

Reference: [GTFS Specification](https://github.com/google/transit/blob/master/gtfs/spec/en/reference.md)
