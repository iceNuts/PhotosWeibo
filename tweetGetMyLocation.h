//
//  tweetGetMyLocation.h
//  locationTest
//
//  Created by 雨骁 刘 on 12-4-23.
//  Copyright (c) 2012年 BUAA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLGeocoder.h>

@interface tweetGetMyLocation : NSObject <CLLocationManagerDelegate>{
    CLLocationManager *myLocationmanager;
    NSString *myLat;
    NSString *myLon;
}
@property (nonatomic, retain) NSString *myLat;
@property (nonatomic, retain) NSString *myLon;
@end
