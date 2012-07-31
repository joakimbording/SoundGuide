//
//  RoutesViewController.h
//  SoundGuide
//
//  Created by Joakim Bording on 17.02.12 - joakim@bording.no - joakim.bording.no
//  This work is shared under the creative common license: Attribution-NonCommercial ShareAlike 3.0 Unported 
//  http://creativecommons.org/licenses/by-nc-sa/3.0/
//
//  Author should always be credited 
//

#import <UIKit/UIKit.h>

@interface RoutesViewController : UITableViewController
{
    NSMutableArray *routesArray;
    NSManagedObjectContext *managedObjectContext;
    UIBarButtonItem *addButton;    
}

@property (nonatomic, retain) NSMutableArray *routesArray;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) UIBarButtonItem *addButton;

- (IBAction)addButtonTouched:(id)sender;


@end
