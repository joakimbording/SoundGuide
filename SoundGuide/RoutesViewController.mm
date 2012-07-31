//
//  RoutesViewController.m
//  SoundGuide
//
//  Created by Joakim Bording on 17.02.12 - joakim@bording.no - joakim.bording.no
//  This work is shared under the creative common license: Attribution-NonCommercial ShareAlike 3.0 Unported 
//  http://creativecommons.org/licenses/by-nc-sa/3.0/
//
//  Author should always be credited 
//

#import "RoutesViewController.h"
#import "CreateViewController.h"
#import "RouteViewController.h"
#import "Route.h"

@implementation RoutesViewController

@synthesize routesArray;
@synthesize managedObjectContext;
@synthesize addButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    UINavigationBar *bar = [self.navigationController navigationBar]; 
    [bar setTintColor:[UIColor blackColor]];
    self.title = @"Routes";
    // Set title on the backbutton
    UIBarButtonItem * tempButtonItem = [[ UIBarButtonItem alloc] init];
    tempButtonItem .title = @"Cancel";
    self.navigationItem.backBarButtonItem = tempButtonItem ;
    [tempButtonItem release];
    
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTouched:)];
    addButton.enabled = YES;
    self.navigationItem.rightBarButtonItem = addButton;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    // Fetch data
    routesArray = [[NSMutableArray alloc] init];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Route" inManagedObjectContext:managedObjectContext];
    [request setEntity:entity];
    
    //Sort data (sorter etter flere ved å putte i array)
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"useLog" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    [sortDescriptors release];
    [sortDescriptor release];
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        NSLog(@"Yo! Error in fetching data");
    }
    
    [self setRoutesArray:mutableFetchResults];
    [mutableFetchResults release];
    [request release];

}

-(void) viewWillAppear:(BOOL)animated
{
        NSLog(@"Reload");

        [self.tableView reloadData];
}


- (void)viewDidUnload
{
    //self.routesArray = nil;
    //self.addButton = nil;
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction)addButtonTouched:(id)sender {
    NSLog(@"Add!");
    CreateViewController *viewController = [[CreateViewController alloc] initWithNibName:@"CreateViewController" bundle:nil];

    NSManagedObjectContext *context = [self managedObjectContext];
    if (!context) {
        // Handle the error.
        NSLog(@"ERROR addButtonTouched!");
    }
    // Pass the managed object context to the view controller.
    viewController.managedObjectContext = context;
    [self.navigationController pushViewController:viewController animated:YES];  
    [viewController release];
    
}

// The editButtonItem will invoke this method.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
         NSLog(@"Edit if yes!");
        // Execute tasks for editing status
    } else {
        NSLog(@"Edit if no!");
        // Execute tasks for non-editing status.
    }
}

- (void) getDataOnNewThread
{
    // code here to populate your data source
    // call refreshTableViewOnMainThread like below:
    [self performSelectorOnMainThread:@selector(refreshTableView) withObject:nil waitUntilDone:NO];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [routesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    Route *_routesData = (Route *)[routesArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ to %@", [_routesData from], [_routesData to]]; 
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
   // NSString *string = [NSString stringWithFormat:@"%@ Off: %.1f Ang: %.1f Sec: %.1f", [testData setupType], [[testData beaconOffsett] floatValue], [[testData beaconEndAngle] floatValue], [[testData timeSinceLast] floatValue]];
    //cell.detailTextLabel.text = string;
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", [_routesData useLog], [[_routesData created] description]];     
    return cell;
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // If row is deleted, remove it
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //[self removeObjectFromListAtIndex:indexPath];
        // Delete the managed object at the given index path.
        NSManagedObject *routeToDelete = [routesArray objectAtIndex:indexPath.row];
        [managedObjectContext deleteObject:routeToDelete];
        
        [routesArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        // Commit the change.
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            // Handle the error.
            NSLog(@"Error!");
        }
       
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Route *_routeData = (Route *) [routesArray objectAtIndex:[indexPath row]];
    
    RouteViewController *viewController = [[RouteViewController alloc] initWithNibName:@"RouteViewController" bundle:nil];
    
    NSManagedObjectContext *context = [self managedObjectContext];
    if (!context) {
        // Handle the error.
        NSLog(@"ERROR openTouched!");
    }
    // Pass the managed object context to the view controller.
    viewController.managedObjectContext = context;
    [viewController setCurrentRoute:_routeData];
    
    UIView *view = [[UIView alloc] init];
    view.frame = viewController.view.frame;
    [view setBackgroundColor:[UIColor blackColor]]; 
    view.alpha = 0.5f;
    
    UIActivityIndicatorView *ac = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGRect frame = viewController.view.frame;
    ac.center = CGPointMake(frame.size.width/2, frame.size.height/2);
    [view addSubview:ac];
    [ac startAnimating];
    [ac release];
    [viewController.view addSubview:view];
    [viewController setActivityView:view];
    
    [view release];
    [self.navigationController pushViewController:viewController animated:YES];  
    [viewController release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
