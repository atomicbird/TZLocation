//
//  ABTZViewController.m
//  TZLocation
//
//  Created by Tom Harrington on 10/4/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import "ABTZViewController.h"
#import "NSTimeZone+abtz_location.h"
#import "ABTZTimezoneAnnotation.h"
#import <CoreLocation/CoreLocation.h>

@interface ABTZViewController ()
@property (readwrite, retain) ABTZTimezoneAnnotation *timeZoneAnnotation;
@property (readwrite, assign) BOOL updateMapRegionForUserLocation;
@end

@implementation ABTZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    CLLocation *timezoneLocation = [[NSTimeZone localTimeZone] abtz_location];
    MKCoordinateRegion mapRegion;
    mapRegion.center = timezoneLocation.coordinate;
    mapRegion.span.latitudeDelta = 1.0;
    mapRegion.span.longitudeDelta = 1.0;
    
    [self.mapView setRegion:mapRegion];
    
    self.timeZoneAnnotation = [[ABTZTimezoneAnnotation alloc] initWithTimeZone:[NSTimeZone localTimeZone]];
    [self.mapView addAnnotation:self.timeZoneAnnotation];
    
    [self.locationAccuracyLabel setText:@""];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showHideActualLocation:(id)sender {
    if ([self.mapView showsUserLocation]) {
        [self.mapView setShowsUserLocation:NO];
    } else {
        [self.mapView setShowsUserLocation:YES];
    }
    [self.showActualLocationButon setTitle:[NSString stringWithFormat:@"%@ actual location", [self.mapView showsUserLocation] ? @"Hide" : @"Show"] forState:UIControlStateNormal];
}

#pragma mark - MKMapViewDelegate
- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    self.updateMapRegionForUserLocation = YES;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLLocation *location = userLocation.location;
    NSLog(@"Got user location: %@", location);
    CLLocationDistance distanceToTimeZone = [[[NSTimeZone localTimeZone] abtz_location] distanceFromLocation:location];
    
    NSString *localizedDistance;
    if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        localizedDistance = [NSString stringWithFormat:@"%.1f km", distanceToTimeZone / 1000.0];
    } else {
        localizedDistance = [NSString stringWithFormat:@"%.1f miles", distanceToTimeZone / 1609.344];
    }
    [self.locationAccuracyLabel setText:localizedDistance];
    
    if (self.updateMapRegionForUserLocation) {
        // Update the map region to show both the time zone location and the user location, with some padding.
        MKMapRect newMapRect = MKMapRectNull;
        
        MKMapPoint tzMapPoint = MKMapPointForCoordinate([[NSTimeZone localTimeZone] abtz_location].coordinate);
        MKMapPoint userMapPoint = MKMapPointForCoordinate(location.coordinate);
        
        double paddingInMeters = distanceToTimeZone / 2.0;
        
        double userMapPointsPerMeter = MKMapPointsPerMeterAtLatitude(location.coordinate.latitude);
        double userPaddingMapPoints = paddingInMeters * userMapPointsPerMeter;
        MKMapRect userMapRect = MKMapRectMake(userMapPoint.x - (userPaddingMapPoints / 2.0), userMapPoint.y - (userPaddingMapPoints / 2.0), userPaddingMapPoints, userPaddingMapPoints);
        newMapRect = MKMapRectUnion(newMapRect, userMapRect);
        
        double tzMapPointsPerMeter = MKMapPointsPerMeterAtLatitude([[NSTimeZone localTimeZone] abtz_location].coordinate.latitude);
        double tzPaddingMapPoints = paddingInMeters * tzMapPointsPerMeter;
        MKMapRect tzMapRect = MKMapRectMake(tzMapPoint.x - (tzPaddingMapPoints / 2.0), tzMapPoint.y - (tzPaddingMapPoints / 2.0), tzPaddingMapPoints, tzPaddingMapPoints);
        newMapRect = MKMapRectUnion(newMapRect, tzMapRect);
        
        MKCoordinateRegion newRegion = MKCoordinateRegionForMapRect(newMapRect);
        [self.mapView setRegion:newRegion animated:YES];
        
        self.updateMapRegionForUserLocation = NO;
    }
}

- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
    [self.locationAccuracyLabel setText:@""];
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"Location failure: %@", error);
    
    if ([[error localizedRecoverySuggestion] length] > 0) {
        UIAlertView *noLocationAlert = [[UIAlertView alloc] initWithTitle:@"Couldn't get location"
                                                                  message:[error localizedRecoverySuggestion]
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
        [noLocationAlert show];
    }
    [self.showActualLocationButon setTitle:@"Actual location unavailable" forState:UIControlStateNormal];
    [self.showActualLocationButon setEnabled:NO];
}
@end
