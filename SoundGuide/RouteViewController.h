//
//  RouteViewController.h
//  SoundGuide
//
//  Created by Joakim Bording on 17.02.12 - joakim@bording.no - joakim.bording.no
//  This work is shared under the creative common license: Attribution-NonCommercial ShareAlike 3.0 Unported 
//  http://creativecommons.org/licenses/by-nc-sa/3.0/
//
//  Author should always be credited 
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import "MapAnnotation.h"
#import "Route.h"
#import "Waypoint.h"
#import "SoundView.h"

@interface RouteViewController : UIViewController <CLLocationManagerDelegate,MKMapViewDelegate> {
    
    CLLocationManager       *locationManager;
    CMDeviceMotionHandler   motionHandler;
    CMMotionManager         *motionManager;
    NSOperationQueue        *opQ;    
    
    IBOutlet MKMapView      *mapView;
    IBOutlet UIImageView    *arrowImage;
    IBOutlet UILabel        *distanceLabel;  
    IBOutlet UILabel        *accuracyLabel;
    IBOutlet UILabel        *calibrateLabel;     
    IBOutlet UISwitch       *mapSwitch;
    IBOutlet UISwitch       *arrowSwitch;
    IBOutlet UISwitch       *nextWaypointSwitch;
    IBOutlet UISwitch       *magnetSwitch;    
    
    NSManagedObjectContext  *managedObjectContext;
    BOOL                    directionSet; // If direction calculation has initiated   
    BOOL                    routeDirectionForward; // Direction of the route to follow
    BOOL                    startDirection; // If the application should start to give direction clues to the user 
    BOOL                    displayNextWaypoint; // If two waypoints should be heard at once. 
    BOOL                    useOnlyMagnet; // Use only the magnetometer for direction
    Waypoint                *nextWaypoint; // The next waypoint to go to
    Waypoint                *previousWaypoint; // The previous waypoint we walk from
    SoundView               *soundView;
    UIView                  *activityView;
    NSString                *nextWaypointSoundType;
    NSString                *nextNextWaypointSoundType;  
    
    double                  distanceNext;
    double                  angleNext;
    double                  distanceNextNext;    
    double                  angleNextNext;    
    
    CLLocationCoordinate2D  currentLocation;
    double                  locationAccuracy;
    NSMutableArray          *openWaypoints;
    Route                   *currentRoute;
    NSString                *fromTitle, *toTitle;      
    
    NSTimer                 *playSoundBeacon;     
    NSTimer                 *magnetCalibrationTimer; 
    
    float                   currentYaw; // Current relativ gyroscop yaw value with respect to gravity    
    float                   updatedMagneticHeading; // Magnetic heading
    float                   oldMagneticHeading; // Old magneting heading for calibration
    float                   updatedGPSHeading; // GPS Heading
    float                   oldGPSHeading; // Old GPS heading for calibration
    bool                    firstCheckGpsCalibrationPositive; // If the first GPS calibration cycle returned positive (hack to get calibration each 4 second)  
    float                   lastCalibratedYawReading; // Latest gyroscope offset relative to magnetic heading
    float                   lastCalibratedHeading; // Latest updated magnetic reading included northOffset
    float                   trueHeading; // Device heading calculated bu updatedHeading with currentYaw
    float                   compiledHeading; // Device heading calculated by updatedHeading - northOffset with currentYaw
    float                   beaconOffset; // Current offset of beacon
    float                   northOffset; // Offset of north direction
    bool                    updateCompass;    
}

@property (nonatomic, retain) CLLocationManager         *locationManager;  
@property (nonatomic, retain) NSMutableArray            *openWaypoints;
@property (nonatomic, retain) NSManagedObjectContext    *managedObjectContext;
@property (nonatomic, retain) IBOutlet UIWindow         *window;
@property (nonatomic, retain) IBOutlet MKMapView        *mapView;
@property (nonatomic, retain) Route                     *currentRoute;
@property (nonatomic, retain) UIView                    *activityView;
@property (nonatomic, retain) UISwitch                  *mapSwitch;

- (void)                    sensorSetup;
- (void)                    sensorEnd;
- (void)                    openRoute;
- (void)                    closeAllSounds;
- (void)                    setArrowDirection:(double) angle withAnimation:(BOOL) anim;
- (float)                   getRouteHeadingFrom:(CLLocationCoordinate2D)fromLoc to:(CLLocationCoordinate2D)toLoc;
- (void)                    calibrationUpdater:(NSTimer *)timer;
- (IBAction)                toggleEnabledForMapSwitch: (id) sender; 
- (IBAction)                toggleEnabledForArrowSwitch: (id) sender; 
- (IBAction)                toggleEnabledForNextWaypointSwitch: (id) sender; 
- (IBAction)                toggleEnabledForMagnetSwitch: (id) sender; 

@end