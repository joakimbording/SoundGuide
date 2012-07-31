//
//  Waypoint.h
//  SoundGuide
//
//  Created by Joakim Bording on 17.02.12 - joakim@bording.no - joakim.bording.no
//  This work is shared under the creative common license: Attribution-NonCommercial ShareAlike 3.0 Unported 
//  http://creativecommons.org/licenses/by-nc-sa/3.0/
//
//  Author should always be credited 
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Route, Waypoint;

@interface Waypoint : NSManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * endPoint;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) Route *route;
@property (nonatomic, retain) Waypoint *previousWaypoint;
@property (nonatomic, retain) Waypoint *nextWaypoint;

@end
