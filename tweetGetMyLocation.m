//
//  tweetGetMyLocation.m
//  locationTest
//
//  Created by 雨骁 刘 on 12-4-23.
//  Copyright (c) 2012年 BUAA. All rights reserved.
//

#import "tweetGetMyLocation.h"

@implementation tweetGetMyLocation

@synthesize myLat;
@synthesize myLon;

+(id)init{
     if ((self = [super init]) != 0 )
     {
         if([CLLocationManager locationServicesEnabled])
         {
             myLocationmanager = [[CLLocationManager alloc] init];
             myLocationmanager.delegate = self;
             myLocationmanager.desiredAccuracy = kCLLocationAccuracyBest;
             myLocationmanager.distanceFilter = 1000.0f;
             [myLocationmanager startUpdatingLocation];
         }
     }
     return  self;
}

#pragma CLLocationmanager delegate

-(void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    NSString *latitude = [[NSString alloc]initWithFormat:@"%g",newLocation.coordinate.latitude];
    myLat = latitude;
    
    NSString *longitude = [[NSString alloc]initWithFormat:@"%g",newLocation.coordinate.longitude];
    myLon = longitude;
    
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSString *errormsg = [[NSString alloc] initWithFormat:@"error like this:"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errormsg delegate:nil cancelButtonTitle:@"Done" otherButtonTitles:nil, nil];
    [alert show];
}

@end
