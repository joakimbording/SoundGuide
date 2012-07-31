//
//  CreateViewController.h
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
#import <CoreLocation/CoreLocation.h>
#import "MapAnnotation.h"
#import "Route.h"
#import "Waypoint.h"

@interface CreateViewController : UIViewController <CLLocationManagerDelegate,MKMapViewDelegate> {
    CLLocationManager       *locationManager;
    IBOutlet MKMapView      *mapView;
    IBOutlet UIButton       *addWaypointButton;   
    IBOutlet UILabel        *accuracyLabel;
    
    UIBarButtonItem         *saveButton;      
    NSManagedObjectContext *managedObjectContext;  
    NSString                *fromTitle, *toTitle;
    Route                   *currentRoute;
    Waypoint                *previousWaypoint;
    //IBOutlet UIImageView *arrowImage;
    //IBOutlet UILabel    *headingLabel; 
    //IBOutlet UILabel    *distanceLabel; 
    
    CLLocationCoordinate2D  currentLocation;
    NSMutableArray          *openWaypoints;
}

@property (nonatomic, retain) CLLocationManager *locationManager;  
@property (nonatomic,retain) NSMutableArray *openWaypoints;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic,retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) NSString *fromTitle; 
@property (nonatomic, retain) NSString *toTitle; 

- (IBAction)addWaypoint:(id)sender;
- (IBAction)saveRoute:(id)sender;
//- (float) getRouteHeadingFrom:(CLLocationCoordinate2D)fromLoc to:(CLLocationCoordinate2D)toLoc;
- (void)setupRoute;
-(CLLocationCoordinate2D) createWaypoint;

@end
