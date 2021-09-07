## GTFS Transjakarta

Create Transjakarta BRT datasets in GTFS format.

-   **00_get.R** for getting Transjakarta routes and stops details
-   **00_schedule.R** for getting current schedules
-   **01_agency.R**, **02_stops.R**, **03_routes.R**, **04_trips-shapes.R**, **05_stop_times.R** for creating GTFS formatted txt files

### Todo

-   [] Add `trips.service_id` based on schedule from Moovit
-   [] Create `stop_times.stop_sequence` with correct value
-   [] Add `stop_times.arrival_time` and `stop_times.departure_time` from where?
-   [] Create **calendar.txt** and **calendar_dates.txt**
-   [] Validate GTFS transit feeds
-   [] Add a license??

### Data Sources

-   [Trafi.com](https://www.trafi.com/)

-   [Moovit.com](https://moovitapp.com/)

-   [BRTData.net](https://www.brtdata.net/city?c=jakarta) (not yet)

-   [Global BRT Data](https://brtdata.org/location/asia/indonesia/jakarta) (not yet)

### Related Project

-   [Bogor Angkot GTFS](https://github.com/michielbdejong/bogor-angkot-gtfs) by Michiel de Jong

### References

-   [GTFS Specification](https://github.com/google/transit/blob/master/gtfs/spec/en/reference.md) by Google Transit

### Contribution

This repository was a clone project from [Rasyid Ridha](https://github.com/rasyidstat/transjakarta). For any contribution, kindly email me on [andi.herlan\@pm.me](mailto:andi.herlan@protonmail.com) or open an issue or pull request.
