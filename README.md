#  William Thompson Tech Demo


## Built to demonstrate Core Motion retrieving along with some simple math for bumps.
Bump the side of your iPhone to see a Warning that the limit's were exceeded.


## Location Tracking and showing on a map.
- Uses CoreData to track location GeoEvents.
Speed
GPS  location coordinates
Time

- 

### Two different view controllers
Map View - Shows pins on the map of the Core Data GeoEvents
LocationsTableViewController - shows the data points, delete, clear all events from CoreData. 

#### Map View shows bread crumbs from CoreData
- Maps up to 20 of the last pins of location change.
- KVO added for HomeLocation to allow enabling/disabling the Reset Home Button.
- NSFetchedResultsController  - gets GeoEvents

#### Table View shows actual Location data that is tracked.
- Clearing location data is allowed from this view.

### Instructions
- Move to a view controller where GPS data would display, this is when authorization is requested, and location updates start.
