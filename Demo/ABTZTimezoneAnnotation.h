//
//  ABTZTimezoneAnnotation.h
//  TZLocation
//
//  Created by Tom Harrington on 10/4/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface ABTZTimezoneAnnotation : NSObject <MKAnnotation>

- (instancetype)initWithTimeZone:(NSTimeZone *)timeZone;
@end
