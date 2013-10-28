# Probably Approximately Correct Location for iOS and Mac OS X

This project demonstrates how to get a rough approximation of an iOS or Mac OS X device's location using only data stored on the device. No GPS or internet lookups are involved. The resulting data is only approximately accurate, but probably good enough to determine the country or continent where the device is located.

### Theory of operation

The approach is to look up the local time zone name and to then correlate that with data from [IANA](http://www.iana.org/time-zones) which gives a country code and lat/long pair for each zone. As of this writing there are several hundred time zones around the world, so the resulting data can identify the approximate region of the user without giving their exact location.

For example, in the Rocky Mountain region of the USA, the time zone name is `America/Denver`. Using IANA's data gives a country code of `US` and a lat/long pair represented as `+394421-1045903`. The lat/long information is converted to a `CLLocation`, and the country code is left as an `NSString`.

This is implemented as a category on `NSZimeZone`, which adds two methods:

    - (CLLocation *)abtz_location;
    - (NSString *)abtz_countryCode;

This should work equally well for both Mac OS X and iOS devices. The general principle applies to any computing system using IANA time zone data, which is quite common.

A possible use case: Your app is for a country that has support phone numbers in a multiple countries. You'd like to have a "call us" button that would initiate a phone call, and you'd like to automatically select a phone number in the same country as the user. But aside from that you never use location data. If you start using Core Location, your users might reasonably be suspicious of why you suddenly want to know where they are. But you don't actually care where they are, not exactly at least. A rough approximate is plenty.

### Demo app

The project includes a demo app that shows your current time zone's location on a map view. If you tap the "show actual location" button, the app will use Core Location to get your actual location and show both locations. The app won't ask for permission to use your location until you press this button.

### Some notes on the code

The code includes two files available from IANA:

* `zone.tab`, which contains the country code and lat/long details. This file is already present on both iOS and Mac OS X at `/usr/share/zoneinfo/zone.tab` but is included in the project for completeness.
* `backward`, which maps older time zone names to current names. This is needed since some older names are still commonly used, for example `US/Pacific` instead of `America/Los_Angeles`, while `zone.tab` only includes the current names. Unlike `zone.tab`, this file is not normally present on iOS or Mac OS X.

These two files are included in their original format, so that newer versions can be simply dropped in at any time. Both the format and the naming are less than ideal, but updates should be trivial.

Scanning these files is a rather expensive operation and is not optimized. However, each time zone instance caches its country code and location via Objective-C attached objects. If you use the code for the local time zone only, caching the contents of the lookup files would not be useful. On the other hand if you expect to look up this data for many different time zones, some optimization would be an extremely good idea.

### License

MIT-style license, see LICENSE for details.

### Credits

By Tom Harrington, @atomicbird on most social networks.