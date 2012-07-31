//
//  RouteViewController.m
//  SoundGuide
//
//  Created by Joakim Bording on 17.02.12 - joakim@bording.no - joakim.bording.no
//  This work is shared under the creative common license: Attribution-NonCommercial ShareAlike 3.0 Unported 
//  http://creativecommons.org/licenses/by-nc-sa/3.0/
//
//  Author should always be credited 
//

#import "RouteViewController.h"

@implementation RouteViewController
@synthesize mapView;
@synthesize window;
@synthesize locationManager;
@synthesize openWaypoints;
@synthesize currentRoute;
@synthesize managedObjectContext;
@synthesize activityView;
@synthesize mapSwitch;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"...", @"...");
        NSLog(@"Route Init");
        displayNextWaypoint = NO;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    NSLog(@"Route Memory Warning");
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Route viewDidLoad");

    directionSet = NO;
    UINavigationBar *bar = [self.navigationController navigationBar]; 
    [bar setTintColor:[UIColor blackColor]];

    self.mapView.mapType = MKMapTypeStandard;   // also MKMapTypeSatellite or MKMapTypeHybrid
    [mapView setDelegate:self];
    [mapView setShowsUserLocation:YES];
    
    [self openRoute];
}

- (void) viewWillAppear:(BOOL)animated
{
    NSLog(@"Route viewWillAppear");
    soundView = [[SoundView alloc] initWithDistance:50.0f];    
   [self sensorSetup];
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSLog(@"Route viewWillDissaper");
    startDirection = NO;    
    [self sensorEnd]; 
    [self closeAllSounds];
    [soundView release];
}

- (void)viewDidUnload
{
    NSLog(@"Route viewDidUnload");
    [super viewDidUnload];

    mapView = nil;
}

-(void) displayWaypoints
{
    CLLocationCoordinate2D cord;
    
    for(Waypoint *wayp in openWaypoints){
        // Add the annotation to our map view
        cord.latitude = [wayp.latitude doubleValue];
        cord.longitude = [wayp.longitude doubleValue];
        MapAnnotation *newAnnotation = [[MapAnnotation alloc] initWithTitle:[[wayp.endPoint stringValue] retain] andCoordinate:cord];

        [self.mapView addAnnotation:newAnnotation];
        [newAnnotation release];
    }
}

-(void) setupNewSoundWaypoints {
    NSLog(@"FMOD SETUPNEWSOUNDSWAYPOINTS");
    // Setup sound if in the middle of the trip and you have minimum two waypoints left
    if(nextWaypointSoundType && nextNextWaypointSoundType && 
       ((routeDirectionForward && nextWaypoint.nextWaypoint) || (!routeDirectionForward && nextWaypoint.previousWaypoint))){
        
        //[soundView closeSound:nextWaypointSoundId];
        [nextWaypointSoundType release];
        nextWaypointSoundType = @"Waypoint";
        
        if((routeDirectionForward && [nextWaypoint.nextWaypoint.endPoint isEqualToNumber:[NSNumber numberWithInt:1]]) ||
           (!routeDirectionForward && [nextWaypoint.previousWaypoint.endPoint isEqualToNumber:[NSNumber numberWithInt:1]])
           ){
            [nextNextWaypointSoundType release];
            nextNextWaypointSoundType = @"Endpoint";
        } else {
            [nextNextWaypointSoundType release];
            nextNextWaypointSoundType = @"NextWaypoint";      
        }
    // Setups sound if you have only one waypoint left     
    } else if(nextWaypointSoundType && nextNextWaypointSoundType) {
        //[soundView closeSound:nextWaypointSoundId];
        [nextWaypointSoundType release];
        nextWaypointSoundType = @"Endpoint";
        [nextNextWaypointSoundType release];
        nextNextWaypointSoundType = nil;
    // Setup sounds if sounds have not been setup
    } else {
        if(((routeDirectionForward && nextWaypoint.nextWaypoint) || (!routeDirectionForward && nextWaypoint.previousWaypoint))){
            if((routeDirectionForward && [nextWaypoint.nextWaypoint.endPoint isEqualToNumber:[NSNumber numberWithInt:1]]) ||
               (!routeDirectionForward && [nextWaypoint.previousWaypoint.endPoint isEqualToNumber:[NSNumber numberWithInt:1]])
               ){
                nextWaypointSoundType = @"Waypoint";  
                nextNextWaypointSoundType = @"Endpoint";
            } else {
                nextWaypointSoundType = @"Waypoint"; 
                nextNextWaypointSoundType = @"NextWaypoint";            
            }
        } else {
            nextWaypointSoundType = @"Endpoint";  
            nextNextWaypointSoundType = nil;
        }
        NSLog(@"FMOD InitSet");
    }
}

-(void) closeAllSounds {
    NSLog(@"FMOD CLOSEALLSOUNDS");    
    [playSoundBeacon invalidate];
    if(nextWaypointSoundType && nextNextWaypointSoundType){
      //  [soundView closeSound:nextWaypointSoundId];
      //  [soundView closeSound:nextNextWaypointSoundId];  
        
    } else if(nextWaypointSoundType){
      //  [soundView closeSound:nextWaypointSoundId];
    }
}

- (float) getRouteHeadingFrom:(CLLocationCoordinate2D)fromLoc to:(CLLocationCoordinate2D)toLoc
{
    float fLat = fromLoc.latitude * M_PI/180.0;
    float fLng = fromLoc.longitude * M_PI/180.0;
    float tLat = toLoc.latitude * M_PI/180.0;
    float tLng = toLoc.longitude * M_PI/180.0;
    
    return atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng))*180.0/M_PI;         
}


-(void) updateSoundPosition {  
    CLLocation *locationMe = [[CLLocation alloc] initWithLatitude:currentLocation.latitude longitude:currentLocation.longitude];
    CLLocation *locationNext = [[CLLocation alloc] initWithLatitude:[nextWaypoint.latitude doubleValue] longitude:[nextWaypoint.longitude doubleValue]];
    CLLocation *locationNextNext; 
    
    distanceNext = [locationMe distanceFromLocation:locationNext];
    angleNext = [self getRouteHeadingFrom:currentLocation to:locationNext.coordinate];
    
    distanceNextNext = 0.0f;    
    angleNextNext = 0.0f;
    
    // Calculate angle and distance
    if(routeDirectionForward && nextWaypoint.nextWaypoint){ 
        locationNextNext = [[CLLocation alloc] initWithLatitude:[nextWaypoint.nextWaypoint.latitude doubleValue] longitude:[nextWaypoint.nextWaypoint.longitude doubleValue]]; 
        distanceNextNext = [locationMe distanceFromLocation:locationNextNext];
        angleNextNext = [self getRouteHeadingFrom:currentLocation to:locationNextNext.coordinate];
        [locationNextNext release];
    } else if(!routeDirectionForward && nextWaypoint.previousWaypoint){     
        locationNextNext = [[CLLocation alloc] initWithLatitude:[nextWaypoint.nextWaypoint.latitude doubleValue] longitude:[nextWaypoint.nextWaypoint.longitude doubleValue]]; 
        distanceNextNext = [locationMe distanceFromLocation:locationNextNext];
        angleNextNext = [self getRouteHeadingFrom:currentLocation to:locationNextNext.coordinate];  
        [locationNextNext release];
    }    
    
    // Update sounds position
    if(startDirection && nextWaypointSoundType && nextNextWaypointSoundType){
        [soundView updateSound:nextWaypointSoundType fromAngle:compiledHeading fromDistance:distanceNext minVolume:0.4f];
        [soundView updateSound:nextNextWaypointSoundType fromAngle:(trueHeading + angleNextNext) fromDistance:49.5 minVolume:0.05f]; 
    } else if(startDirection && nextWaypointSoundType){
        [soundView updateSound:nextWaypointSoundType fromAngle:compiledHeading fromDistance:distanceNext minVolume:0.4f];
    }
    
    [locationMe release];
    [locationNext release];
}

- (void)playNextSoundBeacon:(NSTimer *)timer {
    [self updateSoundPosition];    
    [soundView playSound:nextNextWaypointSoundType fromAngle:(trueHeading + angleNextNext) fromDistance:49.5f minVolume:0.05f];
}

- (void)playSoundBeacon:(NSTimer *)timer {
    NSLog(@"FMOD PLAYSOUNDBEACOn");
    [self updateSoundPosition];
    if(startDirection && nextWaypointSoundType && nextNextWaypointSoundType){
        NSLog(@"FMOD Two");
        if(fabs(beaconOffset) < 20.0f){
            [soundView playClick];
        } else {
            [soundView playSound:nextWaypointSoundType fromAngle:compiledHeading fromDistance:distanceNext minVolume:0.4f];            
        }
        if(displayNextWaypoint) [NSTimer scheduledTimerWithTimeInterval:0.75f target:self selector:@selector(playNextSoundBeacon:) userInfo:nil repeats:NO];
    } else if(startDirection && nextWaypointSoundType){
        NSLog(@"FMOD One");
        if(fabs(beaconOffset) < 20.0f){
            [soundView playClick];
        } else {
            [soundView playSound:nextWaypointSoundType fromAngle:compiledHeading fromDistance:distanceNext minVolume:0.4f];
        }
    } 
}

-(CLLocationCoordinate2D) determineNextPoint
{

    CLLocation *locationMe = [[CLLocation alloc] initWithLatitude:currentLocation.latitude longitude:currentLocation.longitude];
    CLLocation *locationNext = [[CLLocation alloc] initWithLatitude:[nextWaypoint.latitude doubleValue] longitude:[nextWaypoint.longitude doubleValue]];
    CLLocation *locationPrevious; 
    
    double distanceMeNext = [locationMe distanceFromLocation:locationNext];
    double distanceMePrevious, distanceNextPrevious;
    
    if(routeDirectionForward && nextWaypoint.previousWaypoint){
        locationPrevious = [[CLLocation alloc] initWithLatitude:[nextWaypoint.previousWaypoint.latitude doubleValue] longitude:[nextWaypoint.previousWaypoint.longitude doubleValue]];
        
        distanceMePrevious = [locationMe distanceFromLocation:locationPrevious];   
        distanceNextPrevious = [locationNext distanceFromLocation:locationPrevious];  
        [locationPrevious release];
        
    } else if(nextWaypoint.nextWaypoint){
        locationPrevious = [[CLLocation alloc] initWithLatitude:[nextWaypoint.nextWaypoint.latitude doubleValue] longitude:[nextWaypoint.nextWaypoint.longitude doubleValue]];
        
        distanceMePrevious = [locationMe distanceFromLocation:locationPrevious];   
        distanceNextPrevious = [locationNext distanceFromLocation:locationPrevious]; 
        [locationPrevious release];
        
    } else {
        distanceMePrevious = 0.0f;   
        distanceNextPrevious = 1.0f;         
    }
    
    distanceLabel.text = [NSString stringWithFormat:@"%0.1f m",distanceMeNext];
    
    if(distanceMeNext < 1.0f || distanceMePrevious > distanceNextPrevious){ // 10 meter eller gått forebi
        if(routeDirectionForward){
            if(nextWaypoint.nextWaypoint){
                previousWaypoint = nextWaypoint;
                nextWaypoint = nextWaypoint.nextWaypoint;
                [self setupNewSoundWaypoints];
            } else {
                startDirection = NO;
                [soundView playSuccess];
                [self closeAllSounds];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Route completed" message:@"You are now close to your target." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
                [alert release];
            }
        } else {
            if(nextWaypoint.previousWaypoint){
                previousWaypoint = nextWaypoint;
                nextWaypoint = nextWaypoint.previousWaypoint;
                [self setupNewSoundWaypoints];
            } else {
                startDirection = NO;
                [soundView playSuccess];                
                [self closeAllSounds];                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Route completed" message:@"You are now close to your target." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
                [alert release];
            }            
        }
    }

    [locationMe release];
    [locationNext release];   
    
    CLLocationCoordinate2D _wayp;
     _wayp.latitude = [nextWaypoint.latitude doubleValue];
     _wayp.longitude = [nextWaypoint.longitude doubleValue];
    return _wayp;
}

-(void) openRoute
{
    // Åpne route
    self->fromTitle = currentRoute.from;
    self->toTitle = currentRoute.to;
    
    // DETERMINE DIRECTION
    self.title = [NSString stringWithFormat:@"Wait for fix..."];
     
    // Update useLog
    NSLog(@"Read currentRoute");
    currentRoute.useLog = [NSNumber numberWithInt:([currentRoute.useLog integerValue] + 1)]; //[currentRoute.useLog integerValue]
    
    // Commit the change.
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        // Handle the error.
        NSLog(@"Error!");
    }
    
    // Open Waypoints
    NSMutableArray *_openWayp = [[NSMutableArray alloc] initWithArray:[currentRoute.waypoints allObjects]];
    [self setOpenWaypoints:_openWayp];
    [_openWayp release];
    
    
    // Legg til annotations
    [self displayWaypoints];
    
}

- (void)mapView:(MKMapView *)mv didAddAnnotationViews:(NSArray *)views
{    
    MKAnnotationView *annotationView = [views objectAtIndex:0];
    id<MKAnnotation> mp = [annotationView annotation];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([mp coordinate] ,200,200);
    
    [mv setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];        
    [mv setRegion:region animated:YES];
}

#pragma mark - Sensor handling


// Is called every other second for calibrating the gyro with the magnetometer or gps (gps is calibrated each 4 second) - Started from sensorSetup -ended from sensorEnd
- (void)calibrationUpdater:(NSTimer *)timer 
{
    updateCompass = NO;
    
     // If the compass hasn't moved in a while we can calibrate the gyro 
    if(updatedGPSHeading > 0.0f && oldGPSHeading > 0.0f && fabs(updatedGPSHeading - oldGPSHeading) < 10.0f){
        if(firstCheckGpsCalibrationPositive){
            if(fabs(lastCalibratedYawReading - currentYaw) < 10.0f){
                NSLog(@"Update gyro from GPS");
                // Populate lastCalibratedHeading with new compass value
                lastCalibratedHeading = (0 - updatedGPSHeading);
                
                //compassFault.text = [NSString stringWithFormat:@"lastCalibratedHeading: %f",lastCalibratedHeading]; // Debug
                lastCalibratedYawReading = currentYaw;
                updateCompass = YES;       
                calibrateLabel.text = @"GPS";   
                firstCheckGpsCalibrationPositive = NO;
            } else {
                calibrateLabel.text = @"X";                 
                firstCheckGpsCalibrationPositive = NO;                
            }
        } else {
            firstCheckGpsCalibrationPositive = YES;
        }
        
    } else if(fabs(updatedMagneticHeading - oldMagneticHeading) < 10.0f) {
         NSLog(@"Update gyro from magnet");
         // Populate lastCalibratedHeading with new compass value
         lastCalibratedHeading = (0 - updatedMagneticHeading);
     
         //compassFault.text = [NSString stringWithFormat:@"lastCalibratedHeading: %f",lastCalibratedHeading]; // Debug
         lastCalibratedYawReading = currentYaw;
         updateCompass = YES;
         //calibrateLabel.text = @"MAG";       
         firstCheckGpsCalibrationPositive = NO;
     } else {
         updateCompass = NO;
         firstCheckGpsCalibrationPositive = NO;
         //calibrateLabel.text = @"";
     }
     
     if(!firstCheckGpsCalibrationPositive) oldGPSHeading = updatedGPSHeading;
     oldMagneticHeading = updatedMagneticHeading;
}


- (double) distanceFromTheLineBetween: (CLLocationCoordinate2D) a andPoint: (CLLocationCoordinate2D) b andOurPosisitionAt: (CLLocationCoordinate2D) c {

    // return atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng))*180.0/M_PI;
    MKMapPoint a2 = MKMapPointForCoordinate(a);
    MKMapPoint c2 = MKMapPointForCoordinate(c);
    
    double distanceAtoC = (double) MKMetersBetweenMapPoints(a2, c2); // sqrt(pow((a.latitude - c.latitude),2) + pow((a.longitude - c.longitude),2)); //a.latitude - c.latitude 
    double angleB = [self getRouteHeadingFrom:a to:b];
    double angleC = [self getRouteHeadingFrom:a to:c];
    
    // sin([self getRouteHeadingFrom:a to:c])
    return sin(fabs(angleB - angleC))*distanceAtoC;
}

/*
 * Starts the sound and log setup for each round
 *
 */

- (void) sensorSetup
{
    // Heading variables
    oldMagneticHeading              = 0;
    lastCalibratedYawReading        = 0;
    lastCalibratedHeading           = 0;
    northOffset                     = 0;
    
    // Set up location manager
    locationManager=[[CLLocationManager alloc] init];
    [locationManager setDistanceFilter:kCLDistanceFilterNone];    
	locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    	
    // We listen to events from the locationManager 
    locationManager.delegate=self;
	
	if([CLLocationManager headingAvailable] == YES){
		//NSLog(@"Heading is available");
	} else {
		NSLog(@"Heading isn't available");
	}
    
    // Start listening to events from locationManager
    [locationManager startUpdatingHeading];
    [locationManager startUpdatingLocation];    
    
    // Set up motionManager
    motionManager = [[CMMotionManager alloc]  init];
    motionManager.deviceMotionUpdateInterval = 0.02; //50Hz
    opQ = [[NSOperationQueue currentQueue] retain];
    
    if(motionManager.isDeviceMotionAvailable) {
        
        // Listen to events from the motionManager
        motionHandler = ^ (CMDeviceMotion *motion, NSError *error) {
            CMAttitude *currentAttitude = motion.attitude;
            float yawValue = currentAttitude.yaw; // Use the yaw value relative to gravity
                       
            // Yaw values are in radians (-180 - 180), here we convert to degrees
            float yawDegrees = yawValue*180.0/M_PI;
            currentYaw = yawDegrees;
            
            // We add new compass value together with new yaw value
            yawDegrees = lastCalibratedHeading + (yawDegrees - lastCalibratedYawReading);
            
            // Degrees should always be between 0 and 360
            if(yawDegrees < 0) yawDegrees = yawDegrees + 360;
            if(yawDegrees > 360) yawDegrees = yawDegrees - 360;
            
            // The resulting heading that is used for main target sound
            compiledHeading = yawDegrees + northOffset; 
            if(compiledHeading > 360) compiledHeading = compiledHeading - 360;
            
            // The resulting baseline heading that is used to calculate other directions
            trueHeading  = yawDegrees;
            if(trueHeading > 360) trueHeading = trueHeading - 360;            
            
            // The heading offset that is used for measures and sound choice
            float frontBackAngle = compiledHeading;
            if(frontBackAngle > 180.0f) frontBackAngle = 360.0f - frontBackAngle;
            beaconOffset = frontBackAngle;
            
            //locationLabel.text = [NSString stringWithFormat:@"Compiled: %.1f", compiledHeading];
            //northLabel.text = [NSString stringWithFormat:@"Offset: %.1f", beaconOffset];
            
            float gyroDegrees = compiledHeading*M_PI/180.0;

            if(updateCompass && startDirection) {               
                [self setArrowDirection:gyroDegrees withAnimation:YES];
                 updateCompass = NO;

            } else if (startDirection) {
                [self setArrowDirection:gyroDegrees withAnimation:NO];
                [self setArrowDirection:gyroDegrees withAnimation:YES];
                [self updateSoundPosition];
            }
                
            if(directionSet == NO && [openWaypoints count] != 0){
                //[activityView removeFromSuperview];
                if(currentLocation.latitude && locationAccuracy < 10.0f && locationAccuracy > 0.0f){
                    CLLocation *current = [[CLLocation alloc] initWithLatitude:currentLocation.latitude longitude:currentLocation.longitude];
                    double shortesDistance, dist;
                    shortesDistance = -1.0f;
                    Waypoint *closestWaypoint;
                    for(Waypoint *wayp in openWaypoints){
                        dist = [current distanceFromLocation:[[[CLLocation alloc] initWithLatitude:[wayp.latitude doubleValue] longitude:[wayp.longitude doubleValue]] autorelease]];
                        NSLog(@"Dist: %0.1f",dist);
                        if(shortesDistance == -1.0f || dist < shortesDistance){
                            shortesDistance = dist;
                            closestWaypoint = wayp;
                        }
                    }
                    NSLog(@"Dist Closest: %0.1f",shortesDistance);
                    if(closestWaypoint != nil){
                        nextWaypoint = closestWaypoint;
                        closestWaypoint = nil;
                    }
                        
                    if([nextWaypoint.endPoint isEqualToNumber:[NSNumber numberWithInt:1]]){
                        NSLog(@"Endpoint!!");
                        if(nextWaypoint.nextWaypoint){
                            routeDirectionForward = YES;
                            previousWaypoint = nextWaypoint;
                            nextWaypoint = nextWaypoint.nextWaypoint;
                            self.title = [NSString stringWithFormat:@"Til %@", toTitle];

                        } else {
                            routeDirectionForward = NO;
                            previousWaypoint = nextWaypoint;
                            nextWaypoint = nextWaypoint.previousWaypoint;
                            self.title = [NSString stringWithFormat:@"Til %@", fromTitle]; 

                        }
                        startDirection = YES;
                        directionSet = YES;
                        [self setupNewSoundWaypoints];  
                        
                        [activityView removeFromSuperview];
                        
                        playSoundBeacon = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(playSoundBeacon:) userInfo:nil repeats:YES];
                        NSLog(@"Sound timer set");

                    } else {
                        //headingLabel.text = [NSString stringWithFormat:@"%0.1f m",shortesDistance];
                        distanceLabel.text = @"Gå til start!";
                    }
                    [current release];
                }
            }
                
                
            if(startDirection){
                CLLocationCoordinate2D nextW,previousW;
                nextW = [self determineNextPoint];
                previousW.latitude = [previousWaypoint.latitude doubleValue];
                previousW.longitude = [previousWaypoint.longitude doubleValue];
                
                double dist = [self distanceFromTheLineBetween:previousW andPoint:nextW andOurPosisitionAt:currentLocation];
                calibrateLabel.text = [NSString stringWithFormat:@"%0.1f m", dist];
                northOffset = [self getRouteHeadingFrom:previousW to:nextW];

            }
        };

        
        // Start listening to motionManager events
        [motionManager startDeviceMotionUpdatesToQueue:opQ withHandler:motionHandler];

        // Start interval to run every other second
        magnetCalibrationTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(calibrationUpdater:) userInfo:nil repeats:YES];
        
    } else {
        NSLog(@"No Device Motion on device.");
    } 
}

- (void) sensorEnd 
{
    [motionManager stopDeviceMotionUpdates];
    [locationManager stopUpdatingHeading];
    [locationManager stopUpdatingLocation];
    [magnetCalibrationTimer invalidate];
    //[locationManager release];
    [motionManager release];
    updateCompass = NO;
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    return YES; // Må testes hvordan denne fungerer i voice over
}


- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    // Update variable updateHeading to be used in updater method
    updatedMagneticHeading = newHeading.trueHeading;    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{

    NSLog(@"Location update ");
    currentLocation.latitude = newLocation.coordinate.latitude;
    currentLocation.longitude = newLocation.coordinate.longitude;
    locationAccuracy = (double) newLocation.horizontalAccuracy;
    double gpsSpeed = (double) newLocation.speed;
    
    if(locationAccuracy < 10.0f && gpsSpeed > 0.3f){ 
        updatedGPSHeading = (double) newLocation.course;
    } else {
        updatedGPSHeading = -0.0f;
    }

    accuracyLabel.text = [NSString stringWithFormat:@"%0.1f m",locationAccuracy];    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"Error: %@", [error description]);
}


#pragma mark - Interface handling

-(void) setArrowDirection:(double) angle withAnimation:(BOOL) anim {
    if(useOnlyMagnet) {
        double rad = (updatedMagneticHeading + northOffset)*M_PI/180.0;
        arrowImage.transform = CGAffineTransformMakeRotation(rad);
    } else {
        if(anim){
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.25];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [arrowImage setTransform:CGAffineTransformMakeRotation(angle)];
            [UIView commitAnimations];
        } else {
            arrowImage.transform = CGAffineTransformMakeRotation(angle);
        }
    }
}

- (IBAction) toggleEnabledForMapSwitch: (id) sender {
    
    if (mapSwitch.on){
        NSLog(@"PÅ");
        mapView.hidden = NO;          
    } else {  
        NSLog(@"AV");
        mapView.hidden = YES;
    }  
}

- (IBAction) toggleEnabledForArrowSwitch: (id) sender {
    
    if (arrowSwitch.on){
        NSLog(@"PÅ");
        arrowImage.hidden = NO;          
    } else {  
        NSLog(@"AV");
        arrowImage.hidden = YES;
    }  
}

- (IBAction) toggleEnabledForNextWaypointSwitch: (id) sender {
    
    if (nextWaypointSwitch.on){
        NSLog(@"PÅ");
        displayNextWaypoint = YES;      
    } else {  
        NSLog(@"AV");
        displayNextWaypoint = NO;
    }  
}

- (IBAction) toggleEnabledForMagnetSwitch: (id) sender {
    if (nextWaypointSwitch.on){
        NSLog(@"PÅ");
        useOnlyMagnet = NO;      
    } else {  
        NSLog(@"AV");
        useOnlyMagnet = YES;
    }    
}

- (void)dealloc {
    [opQ release];
    [arrowImage release];
    [accuracyLabel release];
    [distanceLabel release];
    //[nextWaypoint release];
    [super dealloc]; 
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
