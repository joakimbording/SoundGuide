//
//  Route.h
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


@interface Route : NSManagedObject

@property (nonatomic, retain) NSString * from;
@property (nonatomic, retain) NSString * to;
@property (nonatomic, retain) NSNumber * useLog;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSSet *waypoints;
@end

@interface Route (CoreDataGeneratedAccessors)

- (void)addWaypointsObject:(NSManagedObject *)value;
- (void)removeWaypointsObject:(NSManagedObject *)value;
- (void)addWaypoints:(NSSet *)values;
- (void)removeWaypoints:(NSSet *)values;

@end
