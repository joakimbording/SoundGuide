//
//  CreateViewController.m
//  SoundGuide
//
//  Created by Joakim Bording on 17.02.12 - joakim@bording.no - joakim.bording.no
//  This work is shared under the creative common license: Attribution-NonCommercial ShareAlike 3.0 Unported 
//  http://creativecommons.org/licenses/by-nc-sa/3.0/
//
//  Author should always be credited 
//

#import "CreateViewController.h"

@implementation CreateViewController
@synthesize mapView;
@synthesize window;
@synthesize locationManager;
@synthesize openWaypoints;
@synthesize  managedObjectContext;
@synthesize fromTitle, toTitle;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"New Route", @"New Route");
        
        //self.openWaypoints = [[NSMutableArray alloc] initWithObjects:nil];        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    UINavigationBar *bar = [self.navigationController navigationBar]; 
    [bar setTintColor:[UIColor blackColor]];
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveRoute:)];
    saveButton.enabled = YES;
    self.navigationItem.rightBarButtonItem = saveButton;
    
    self.mapView.mapType = MKMapTypeStandard;   // also MKMapTypeSatellite or MKMapTypeHybrid
    [mapView setDelegate:self];
    [mapView setShowsUserLocation:YES];    
    
    // Set up location manager
    locationManager=[[CLLocationManager alloc] init];
    [locationManager setDistanceFilter:kCLDistanceFilterNone];    
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // We listen to events from the locationManager 
    locationManager.delegate=self;
    
    // Start listening to events from locationManager
    [locationManager startUpdatingLocation];  
    
    [self setupRoute];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [mapView release];
    mapView = nil;    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Route handling

- (void) createRoute {
    // Save data
    CLLocationCoordinate2D wayp =[self createWaypoint];
    
    Waypoint *waypData = [NSEntityDescription insertNewObjectForEntityForName:@"Waypoint" inManagedObjectContext:self.managedObjectContext];
    Route *routeData = [NSEntityDescription insertNewObjectForEntityForName:@"Route" inManagedObjectContext:self.managedObjectContext];

    waypData.latitude = [NSNumber numberWithDouble:wayp.latitude];
    waypData.longitude =  [NSNumber numberWithDouble:wayp.longitude];
    waypData.endPoint = [NSNumber numberWithInt:1];   
    waypData.route = routeData; 
    
    routeData.from = self.fromTitle;
    routeData.to =  self.toTitle;
    routeData.created = [NSDate dateWithTimeIntervalSinceNow:0];
    routeData.useLog = [NSNumber numberWithInt:0];
    [routeData addWaypointsObject:waypData];
    
    self->previousWaypoint = waypData;
    self->currentRoute = routeData;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{ 
    if(alertView.title == @"Ny Rute 1" && buttonIndex == 1){ // If next is pressed and not cancel
        NSLog(@"Waypoint");
        self.fromTitle = [[alertView textFieldAtIndex:0] text];
        // VALIDER INPUT!!!
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Route 2" message:@"Where do you go to?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Next", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
        [alert release];
        
    } else if(alertView.title == @"New Route 2" && buttonIndex == 1){ // If next is pressed and not cancel
        self.toTitle = [[alertView textFieldAtIndex:0] text];
        // VALIDER INPUT!!!
        
        //SJEKK HVIS VI HAR GPS POSISJON
        if(currentLocation.latitude){
            [self createRoute];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Saving cancelled" message:@"No GPS-position detectable. Please try again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            [alert release];
            [self.navigationController popViewControllerAnimated:YES]; 
        }
        
         NSLog(@"Create route: %@ to %@", self.fromTitle,  self.toTitle);
        
    } else if ((alertView.title == @"New Route 1" || alertView.title == @"New Route 2") && buttonIndex == 0){
        [self.navigationController popViewControllerAnimated:YES]; 
    }
    
}

- (void)setupRoute
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Route 1" message:@"Where are you now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Next", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    [alert release];
}

#pragma mark - Map handling

-(CLLocationCoordinate2D) createWaypoint
{
    CLLocationCoordinate2D ny;
    ny.latitude = currentLocation.latitude;// + 0.01;
    ny.longitude = currentLocation.longitude;// + 0.01;
    
    // Add the annotation to our map view
    MapAnnotation *newAnnotation = [[MapAnnotation alloc] initWithTitle:@"Waypoint" andCoordinate:ny];
    [self.mapView addAnnotation:newAnnotation];
    [newAnnotation release];
    
    // STORE WAYPOINT IN ARRAY
    CLLocation *wayp = [[CLLocation alloc] initWithLatitude:ny.latitude longitude:ny.longitude];
    [self.openWaypoints addObject:wayp];
    [wayp release];
    return ny;
}

-(void) saveWaypoint:(CLLocationCoordinate2D) wayp{
    Waypoint *waypData = [NSEntityDescription insertNewObjectForEntityForName:@"Waypoint" inManagedObjectContext:self.managedObjectContext];
    
    waypData.latitude = [NSNumber numberWithDouble:wayp.latitude];
    waypData.longitude =  [NSNumber numberWithDouble:wayp.longitude];
    waypData.endPoint = [NSNumber numberWithInt:0];   
    waypData.route = currentRoute; 
    waypData.previousWaypoint = self->previousWaypoint;
    [currentRoute addWaypointsObject:waypData];
    self->previousWaypoint.nextWaypoint = waypData;
    self->previousWaypoint = waypData;
}

- (IBAction)addWaypoint:(id)sender
{
    
    if(currentLocation.latitude){
        NSLog(@"Waypoint");
        CLLocationCoordinate2D wayp = [self createWaypoint];
        [self saveWaypoint:wayp];
        // LAGRE WAYPOINT
        //NSNumber *lat = [NSNumber numberWithFloat:(currentLocation.latitude)];
        //NSNumber *lon = [NSNumber numberWithFloat:(currentLocation.longitude)];
        
    } else {
        // Error
    }
}

- (IBAction)saveRoute:(id)sender
{
    self->previousWaypoint.endPoint = [NSNumber numberWithInt:1];

    NSError *error;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    
    [self.navigationController popViewControllerAnimated:YES]; 
}

- (void)mapView:(MKMapView *)mv didAddAnnotationViews:(NSArray *)views
{    
    MKAnnotationView *annotationView = [views objectAtIndex:0];
    id<MKAnnotation> mp = [annotationView annotation];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([mp coordinate] ,200,200);
    
    [mv setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];        
    [mv setRegion:region animated:YES];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    
    NSLog(@"Loca update ");
    currentLocation.latitude = newLocation.coordinate.latitude;
    currentLocation.longitude = newLocation.coordinate.longitude;
    accuracyLabel.text = [NSString stringWithFormat:@"%0.1f m",newLocation.horizontalAccuracy];     
    
    /*
     int degrees = newLocation.coordinate.latitude;
     double decimal = fabs(newLocation.coordinate.latitude - degrees);
     int minutes = decimal * 60;
     double seconds = decimal * 3600 - minutes * 60;
     NSString *lat = [NSString stringWithFormat:@"%d° %d' %1.4f\"", degrees, minutes, seconds];
     
     degrees = newLocation.coordinate.longitude;
     decimal = fabs(newLocation.coordinate.longitude - degrees);
     minutes = decimal * 60;
     seconds = decimal * 3600 - minutes * 60;
     NSString *longt = [NSString stringWithFormat:@"%d° %d' %1.4f\"", degrees, minutes, seconds];
     */
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"Error: %@", [error description]);
}

- (void)dealloc {
    //self.openWaypoints release];
    [mapView release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
