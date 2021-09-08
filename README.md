## GTFS Transjakarta

**Create Transjakarta BRT datasets using General Transit Feed Specification (GTFS) format**

The GTFS defines a common format for public transportation schedules and associated geographic information. GTFS "feeds" let public transit agencies publish their transit data and developers write applications that consume that data in an interoperable way ([Google Transit](https://developers.google.com/transit/gtfs)).

Description about files in this repository:

-   **00_get.R** for getting Transjakarta routes and stops details
-   **00_schedule.R** for getting current schedules
-   **01_agency.R**, **02_stops.R**, **03_routes.R**, **04_trips-shapes.R**, **05_stop_times.R**, **06_calendar.R** for creating GTFS formatted txt files

### Todo

-   [ ] Add `trips.service_id` based on **calendar.txt** and data from Moovit
-   [ ] Create `stop_times.stop_sequence` with correct value (now, still replacement data)
-   [ ] Add `stop_times.arrival_time` and `stop_times.departure_time` from where?
-   [x] ~~Create one of **calendar.txt** or **calendar_dates.txt**~~
-   [ ] Validate GTFS transit feeds
-   [ ] Add a license??
-   [ ] Add **frequencies.txt** (optional, based on schedule data and **stop_times.txt**)

### Data Sources

-   [Trafi](https://www.trafi.com/)
-   [Moovit](https://moovitapp.com/)
-   [Transjakarta](https://transjakarta.co.id)
-   [BRTData.net](https://www.brtdata.net/city?c=jakarta) (not yet)
-   [Global BRT Data](https://brtdata.org/location/asia/indonesia/jakarta) (not yet)

### Related Project

-   [Bogor Angkot GTFS](https://github.com/michielbdejong/bogor-angkot-gtfs) by Michiel de Jong

### References

-   [GTFS Specification](https://github.com/google/transit/blob/master/gtfs/spec/en/reference.md) by Google Transit

### Contribution

This repository was a clone project from [Rasyid Ridha](https://github.com/rasyidstat/transjakarta). For further contribution, kindly email me on [andi.herlan\@pm.me](mailto:andi.herlan@protonmail.com) or open an issue or pull request.
