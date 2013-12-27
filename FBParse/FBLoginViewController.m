//
//  FBLoginViewController.m
//  FBParse
//

#import "FBLoginViewController.h"

@interface FBLoginViewController () <CommsDelegate>
@property (nonatomic, strong) IBOutlet UIButton *btnLogin;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityLogin;
@end

@implementation FBLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
    // Ensure the User is logged out when loading this View Controller
    // Going forward, we would check th state of the current user and bypass the Lpgin Screen
    // but here, the Login screen is an important part of the tutorial
    
    //[PFUser logOut];
    
}

// Outlet for FBLogin button
- (IBAction) loginPressed:(id)sender
{
    // Disable the Login button to prevent multiple touches
    [_btnLogin setEnabled:NO];
    
    // Show and activity indicator
    [_activityLogin startAnimating];
    
    //Reset the DataStore so that we are starting from a fresh Login
    [[DataStore instance] reset];
    
    // Do the login
    [Comms login:self];
}


#pragma mark Comms delegate
- (void) commsDidLogin:(BOOL)loggedIn
{
    // Re-enable the login button
    [_btnLogin setEnabled:YES];
    
    // Stop activity indicator
    [_activityLogin stopAnimating];
    
    // Did we login successfully?
    if(loggedIn) {
        // Segue to Image Wall
        [self performSegueWithIdentifier:@"LoginSuccessful" sender:self];
    } else {
        // Show error alert
        [[[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Facbeook Login failed. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

@end
