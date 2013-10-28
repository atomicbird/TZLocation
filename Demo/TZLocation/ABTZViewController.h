//
//  ABTZViewController.h
//  TZLocation
//
//  Created by Tom Harrington on 10/4/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface ABTZViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *showActualLocationButon;
@property (weak, nonatomic) IBOutlet UILabel *locationAccuracyLabel;
- (IBAction)showHideActualLocation:(id)sender;
@end
