//
//  NSTimeZone+abtz_location.m
//  TZLocation
//
//  Created by Tom Harrington on 10/4/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import "NSTimeZone+abtz_location.h"
#import <objc/runtime.h>

const NSString *zonetabFilename = @"zone.tab";
const char *locationAssociatedObjectKey = "abtz_location";
const char *countryCodeAssociatedObjectKey = "abtz_countryCode";

@implementation NSTimeZone (abtz_location)

- (NSString *)abtz_countryCode
{
    @synchronized(self) {
        [self _scanZoneTabFile];
        NSString *countryCode = objc_getAssociatedObject(self, countryCodeAssociatedObjectKey);
        return countryCode;
    }
}

- (CLLocation *)abtz_location;
{
    @synchronized(self) {
        [self _scanZoneTabFile];
        CLLocation *location = objc_getAssociatedObject(self, locationAssociatedObjectKey);
        return location;
    }
}

- (void)_scanZoneTabFile
{
    CLLocation *location = objc_getAssociatedObject(self, locationAssociatedObjectKey);
    if (location == nil) {
        // zone.tab is available locally if you prefer, but "backward" (used below) is not.
        //NSURL *zonetabURL = [NSURL fileURLWithPath:@"/usr/share/zoneinfo/zone.tab"];
        NSURL *zonetabURL = [[NSBundle mainBundle] URLForResource:@"zone" withExtension:@"tab"];

        // Bugfix for using cocoapods with framework
        if (!zonetabURL) {
            zonetabURL = [[NSBundle bundleWithIdentifier:@"org.cocoapods.TZLocation"] URLForResource:@"zone" withExtension:@"tab"];
        }

        NSError *error = nil;
        NSString *zonetabContents = [NSString stringWithContentsOfURL:zonetabURL encoding:NSUTF8StringEncoding error:&error];

        // Find the line that contains self's timezone name
        __block NSString *matchingLine = nil;
        __block NSString *tzName = [self name];
        [zonetabContents enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            if ([line rangeOfString:tzName].location != NSNotFound) {
                matchingLine = [line copy];
                *stop = YES;
            }
        }];

        if (matchingLine == nil) {
            // Oh damn, self is using an older zone name. Get the backward compatibility file.
            NSURL *backwardURL = [[NSBundle mainBundle] URLForResource:@"backward" withExtension:nil];

            // Bugfix for using cocoapods with framework
            if (!backwardURL) {
                backwardURL = [[NSBundle bundleWithIdentifier:@"org.cocoapods.TZLocation"] URLForResource:@"backward" withExtension:nil];
            }

            NSError *error = nil;
            NSString *backwardContents = [NSString stringWithContentsOfURL:backwardURL encoding:NSUTF8StringEncoding error:&error];
            __block NSString *backwardLine = nil;
            [backwardContents enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                if ([line rangeOfString:tzName].location != NSNotFound) {
                    backwardLine = [line copy];
                    *stop = YES;
                }
            }];
            if (backwardLine != nil) {
                NSArray *backwardComponents = [backwardLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ([backwardComponents count] >= 2) {
                    tzName = backwardComponents[1];
                }
            }
            [zonetabContents enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                if ([line rangeOfString:tzName].location != NSNotFound) {
                    matchingLine = [line copy];
                    *stop = YES;
                }
            }];
        }
        // Get the location data from the line coontaining self's timezone name.
        NSMutableString *locationString = nil;
        NSString *countryCodeString = nil;
        if (matchingLine != nil) {
            // Expected format: something like (tab delimited):
            // US	+394421-1045903	America/Denver	Mountain Time
            NSArray *matchingLineElements = [matchingLine componentsSeparatedByString:@"\t"];
            if ([matchingLineElements count] >= 2) {
                countryCodeString = matchingLineElements[0];
                locationString = matchingLineElements[1];
            }
        }

        if (countryCodeString != nil) {
            objc_setAssociatedObject(self, countryCodeAssociatedObjectKey, countryCodeString, OBJC_ASSOCIATION_RETAIN);
        }
        // Parse the location data into a CLLocation
        if ([locationString length] > 0) {
            // Expected: something like "+394421-1045903"
            NSRange findLongitudeRange = [locationString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"+-"] options:0 range:NSMakeRange(1, ([locationString length] - 1))];
            if (findLongitudeRange.location != NSNotFound) {
                NSString *latitudeString = [locationString substringToIndex:findLongitudeRange.location];
                NSString *longitudeString = [locationString substringFromIndex:findLongitudeRange.location];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:[self _degreesForZomeTabLatLongString:latitudeString] longitude:[self _degreesForZomeTabLatLongString:longitudeString]];
                objc_setAssociatedObject(self, locationAssociatedObjectKey, location, OBJC_ASSOCIATION_RETAIN);
            }
        }
    }
}

- (CLLocationDegrees)_degreesForZomeTabLatLongString:(NSString *)latLongString
{
    /* From zone.tab:
     # 2.  Latitude and longitude of the area's principal location
     #     in ISO 6709 sign-degrees-minutes-seconds format,
     #     either +-DDMM+-DDDMM or +-DDMMSS+-DDDMMSS,
     #     first latitude (+ is north), then longitude (+ is east).
     */
    CLLocationDegrees degrees = 0.0;
    switch ([latLongString length]) {
        case 5:
        {
            // +-DDMM
            degrees = [[latLongString substringWithRange:NSMakeRange(1, 2)] doubleValue];
            degrees += [[latLongString substringWithRange:NSMakeRange(3, 2)] doubleValue] / 60.0;
            break;
        }
        case 6:
        {
            // +-DDDMM
            degrees = [[latLongString substringWithRange:NSMakeRange(1, 3)] doubleValue];
            degrees += [[latLongString substringWithRange:NSMakeRange(4, 2)] doubleValue] / 60.0;
            break;
        }
        case 7:
        {
            // +-DDMMSS
            degrees = [[latLongString substringWithRange:NSMakeRange(1, 2)] doubleValue];
            degrees += [[latLongString substringWithRange:NSMakeRange(3, 2)] doubleValue] / 60.0;
            degrees += [[latLongString substringWithRange:NSMakeRange(5, 2)] doubleValue] / 3600.0;
            break;
        }
        case 8:
        {
            // +-DDDMMSS
            degrees = [[latLongString substringWithRange:NSMakeRange(1, 3)] doubleValue];
            degrees += [[latLongString substringWithRange:NSMakeRange(4, 2)] doubleValue] / 60.0;
            degrees += [[latLongString substringWithRange:NSMakeRange(6, 2)] doubleValue] / 3600.0;
            break;
        }

        default:
            break;
    }
    if ([latLongString characterAtIndex:0] == '-') {
        degrees *= -1;
    }
    return degrees;
}

@end
