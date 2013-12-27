//
//  ImageWallViewController.m
//  FBParse
//

#import "ImageWallViewController.h"

@interface ImageWallTableImageCell ()
@property (nonatomic, strong) IBOutlet UIImageView *image;
@property (nonatomic, strong) IBOutlet UIImageView *profilePicture;
@property (nonatomic, strong) IBOutlet UILabel *lblUploadedBy;
@property (nonatomic, strong) IBOutlet UILabel *lblUploadedDate;
@end

@implementation ImageWallTableImageCell
- (IBAction) shareImage:(id)sender
{
}
@end

@interface ImageWallTableCommentCell ()
@property (nonatomic, strong) IBOutlet UIImageView *profilePicture;
@property (nonatomic, strong) IBOutlet UILabel *comment;
@end

@implementation ImageWallTableCommentCell

@end

@interface ImageWallTableNewCommentCell () <UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UITextField *txtComment;
@property (nonatomic, strong) WallImage *wallImage;
@end

@implementation ImageWallTableNewCommentCell
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (_txtComment.text.length == 0) return YES;
	
    // We have a new comment, so send it off
    [_txtComment resignFirstResponder];
    [Comms addComment:_txtComment.text toWallImage:_wallImage];
    [_txtComment setText:@""];
}
@end


@interface ImageWallViewController () <CommsDelegate>{
    NSDate *_lastImageUpdate;
    NSDate *_lastCommentUpdate;
    NSDateFormatter *_dateFormatter;
}

@end

@implementation ImageWallViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create a re-usable NSDateFormatter
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"MMM d, h:mm a"];
    
    
    // Initialize the last updated dates
    _lastImageUpdate = [NSDate distantPast];
    _lastCommentUpdate = [NSDate distantPast];
    
    // If we are using iOS6+, put a pull to refresh control in the table
    if (NSClassFromString(@"UIRefreshControl") != Nil) {  //check to see if UIRefreshControl is supported in the OS
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
        [refreshControl addTarget:self action:@selector(refreshImageWall:) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refreshControl;
    }
    
    
    
    // Get the Wall Images from Parse
    [self refreshImageWall:nil];
    
    
    // Listen for image downloads so we can refresh the image wall
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imageDownloaded:)
                                                 name:N_ImageDownloaded
                                               object:nil];
    // lets NSNotificationCenter know that the ImageWallViewController class is interested in knowing when an image is downloaded from Parse.
    
    // Listen for profile picture downlaods so that we an refresh image wall
    // The imageDownloaded: is the same as the other notification for images downlaoded from Parse, since the behavior is the same - it reloads the table data.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:N_ProfilePictureLoaded object:nil];

    // Listen for uploaded comments so that we can refresh the image wall table
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentUploaded:) name:N_CommentUploaded object:nil];
    
    // Listen for new images uploades so that we can refresh the image wall table
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageUploaded:) name:N_ImageUploaded object:nil];
    
}

#pragma mark UI Actions from Storyboard

- (IBAction) logoutPressed:(id)sender
{
    [PFUser logOut];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) uploadPressed:(id)sender
{
	// Seque to the Image Uploader
	[self performSegueWithIdentifier:@"UploadImage" sender:self];
}


#pragma mark Table View Datasource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    // One section per wall Image
	return [DataStore instance].wallImages.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// One row per WallImage comment
    WallImage *wallImage = [DataStore instance].wallImages[section];
    return wallImage.comments.count + 1;  // Add a row for the New Comment cell
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 100;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
	// The header View is actually a UITableViewCell defined in the Storyboard
	static NSString *ImageCellIdentifier = @"ImageCell";
    ImageWallTableImageCell *imageCell = (ImageWallTableImageCell *)[tableView dequeueReusableCellWithIdentifier:ImageCellIdentifier];
    
    WallImage *wallImage = [DataStore instance].wallImages[section];
    [imageCell.image setImage:wallImage.image];
    [imageCell.lblUploadedBy setText:wallImage.user.name];
    [imageCell.lblUploadedDate setText:[_dateFormatter stringFromDate:wallImage.createdDate]];
    
    // Add the user's profile picture to the header cell
    [imageCell.profilePicture setImage:wallImage.user[@"fbProfilePicture"]];
    
    return imageCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CommentCellIdentifier = @"CommentCell";
	ImageWallTableCommentCell *commentCell = (ImageWallTableCommentCell *)[tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier];
	
    // Get the WallImage from the indexPath.section
    WallImage *wallImage = [DataStore instance].wallImages[indexPath.section];
    
    static NSString *NewCommentCellIdentifier = @"NewCommentCell";
    if (indexPath.row >= wallImage.comments.count) {
        // If this is the last row in the section, create a NewCommentCell
        ImageWallTableNewCommentCell *newCommentCell = (ImageWallTableNewCommentCell *)[tableView dequeueReusableCellWithIdentifier:NewCommentCellIdentifier];
        
        // Set the WallImage on the cell so that new comments an be associated with the correct WallImage
        newCommentCell.wallImage = wallImage;
        
        return newCommentCell;
    }
    
    
    
    // Get the associated WallImageComment from the indexPath.row
    WallImageComment *wallImageComment = wallImage.comments[indexPath.row];
    [commentCell.profilePicture setImage:wallImageComment.user[@"fbProfilePicture"]];
    [commentCell.comment setText:wallImageComment.comment];
    
    return commentCell;
}

#pragma mark Comms delegate
- (void) commsDidGetNewWallImages:(NSDate *)updated
{
    // Update the update timestamp
    _lastImageUpdate = updated;
    
    // Get the latest WallImageComments from Parse
    [Comms getWallImageCommentsSince:_lastCommentUpdate forDelegate:self];
    
    
    // Refresh the tale data to show the new images
    [self.tableView reloadData];
    
}

- (void) commsDidGetWallImageComments:(NSDate *)updated
{
    // Update the update timestamp
    _lastCommentUpdate = updated;
    
    // Refresh the image wall table
    [self.tableView reloadData];
    
    // Update the refresh control if we have one
    if (self.refreshControl) {
        NSString *lasteUpdated = [NSString stringWithFormat:@"Last updated on %@",[_dateFormatter stringFromDate:[NSDate date]]];
        [self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:lasteUpdated]];
        [self.refreshControl endRefreshing];
        
    }
}

- (void) imageDownloaded: (NSNotification *) notification
{
    [self.tableView reloadData];
}

- (void) imageUploaded: (NSNotification *) notification
{
    [self refreshImageWall:nil];
}

- (void) commentUploaded:(NSNotification *)notification
{
    [self refreshImageWall:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) refreshImageWall:(UIRefreshControl *)refreshControl
{
    if (refreshControl){
        [refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Refreshing data..." ]];
        [refreshControl setEnabled:NO];
    }
    
    // Get any new Images since the last update
    [Comms getWallImagesSince:_lastImageUpdate forDelegate:self];
}


@end
