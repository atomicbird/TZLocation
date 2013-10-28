//
//  NSTimeZone+abtz_location.h
//  TZLocation
//
//  Created by Tom Harrington on 10/4/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface NSTimeZone (abtz_location)

- (CLLocation *)abtz_location;
- (NSString *)abtz_countryCode;

@end
