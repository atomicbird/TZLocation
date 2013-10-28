//
//  ABTZTimezoneAnnotation.m
//  TZLocation
//
//  Created by Tom Harrington on 10/4/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import "ABTZTimezoneAnnotation.h"
#import "NSTimeZone+abtz_location.h"

@interface ABTZTimezoneAnnotation ()
@property (readwrite, strong) NSTimeZone *timeZone;
@end

@implementation ABTZTimezoneAnnotation

- (instancetype)initWithTimeZone:(NSTimeZone *)timeZone;
{
    if ((self = [super init])) {
        _timeZone = timeZone;
    }
    return self;
}

#pragma mark - MKAnnotation methods
- (CLLocationCoordinate2D) coordinate
{
    return [[[self timeZone] abtz_location] coordinate];
}

- (NSString *)title
{
    return [NSString stringWithFormat:@"%@: %@", [[self timeZone] abtz_countryCode], [[self timeZone] name]];
}

- (NSString *)subtitle
{
    return @"Time zone location";
}
@end
