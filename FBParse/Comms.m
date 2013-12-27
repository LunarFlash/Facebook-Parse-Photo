//
//  Comms.m
//  FBParse
//
//  Created by Terry Wang on 12/23/13.
//  Copyright (c) 2013 Toby Stephens. All rights reserved.
//

#import "Comms.h"
#import "NSOperationQueue+SharedQueue.h"

NSString * const N_ImageDownloaded = @"N_ImageDownloaded";
NSString * const N_ProfilePictureLoaded = @"N_ProfilePictureLoaded";  //set notification name for downloaded Facebook profile pictures
NSString * const N_CommentUploaded = @"N_CommentUploaded";
NSString * const N_ImageUploaded = @"N_ImageUploaded";


@implementation Comms

+ (void) login:(id<CommsDelegate>)delegate
{
	// Basic User information and your friends are part of the standard permissions
	// so there is no reason to ask for additional permissions
	[PFFacebookUtils logInWithPermissions:nil block:^(PFUser *user, NSError *error) {
		// Was login successful ?
		if (!user) {
			if (!error) {
				NSLog(@"The user cancelled the Facebook login.");
			} else {
				NSLog(@"An error occurred: %@", error.localizedDescription);
			}
			
			// Callback - login failed
			if ([delegate respondsToSelector:@selector(commsDidLogin:)]) {
				[delegate commsDidLogin:NO];
			}
		} else {
			if (user.isNew) {
				NSLog(@"User signed up and logged in through Facebook!");
			} else {
				NSLog(@"User logged in through Facebook!");
			}
			
			[FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
				if (!error) {
					NSDictionary<FBGraphUser> *me = (NSDictionary<FBGraphUser> *)result;
					// Store the Facebook Id
					[[PFUser currentUser] setObject:me.id forKey:@"fbId"];
					[[PFUser currentUser] saveInBackground];
                    
                    // 1 Build a Facebook Request object to retrive your friends from Facebook.
                    FBRequest *friendsRequest = [FBRequest requestForMyFriends];
                    [friendsRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                        
                        // 2 Loop through the array of FBGraphUser objects data returned from the Facebook request
                        NSArray *friends = result[@"data"];
                        for (NSDictionary<FBGraphUser>* friend in friends) {
                            NSLog(@"Found a friend: %@", friend.name);
                            
                            // Launch another thread to handle the download of the user's Facbeook profile picture
                            [[NSOperationQueue profilePictureOperationQueue] addOperationWithBlock:^{
                                // Build a profile picture URL from the user's Facebook user id
                                NSString *profilePictureURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", friend.id];
                                NSData *profilePictureData = [NSData dataWithContentsOfURL:[NSURL URLWithString:profilePictureURL]];
                                UIImage *profilePicture = [UIImage imageWithData:profilePictureData];
                                
                                // Set the profile picture into the user object
                                if (profilePicture) [friend setObject:profilePicture forKey:@"fbProfilePicture"];
                                
                                // Notify that the profile picture has been downloaded, using NSNotificationCenter
                                [[NSNotificationCenter defaultCenter] postNotificationName:N_ProfilePictureLoaded object:nil];
                            }];
                            
                            
                            // 3 Add each friend's FBGraphUser objects to the friends list in the DataStore
                            [[DataStore instance].fbFriends setObject:friend forKey:friend.id];
                        }
                        // 4 success callback delegate is now only called once the friends request has been made
                        // Callback - login successful
                        if ([delegate respondsToSelector:@selector(commsDidLogin:)]){
                            [delegate commsDidLogin:YES];
                        }
                        
                    }];
                    
                    // Launch another thread to handle the dlownload of the user's Facebook profile picture
                    [[NSOperationQueue profilePictureOperationQueue] addOperationWithBlock:^{
                       // Build a profile picture URL from the user's Facbeook user id
                        NSString *profilePictureURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture",me.id];
                        NSData *profilePictureData = [NSData dataWithContentsOfURL:[NSURL URLWithString:profilePictureURL]];
                        UIImage *profilePicture = [UIImage imageWithData:profilePictureData];
                        
                        // Set the prifile picture to the user obejct
                        if (profilePicture) [me setObject:profilePicture forKey:@"fbProfilePicture"];
                        
                        // Notify that the profile picture has beeb downloaded, using NSNotificationCenter
                        [[NSNotificationCenter defaultCenter] postNotificationName:N_ProfilePictureLoaded object:nil];
                    }];
                    
                    // Add the User to the list of friends in the DataStore, stores the FBGraphUser object into DataStore's fbFriends list. Yes you are not really your own friend, but it's much easier to retrieve all the images from Parse when everyone is grouped into one list.
                    [[DataStore instance].fbFriends setObject:me forKey:me.id];
                    
				}
				
                
                
			}];
		}
	}];
}


+ (void) uploadImage:(UIImage *)image withComment:(NSString *)comment forDelegate:(id<CommsDelegate>)delegate
{
    // 1 Get image data for uploading
    NSData *imageData = UIImagePNGRepresentation(image);
	
    // 2 Convert the image data into a Parse file type PFFile and save the file asynchronously.
    PFFile *imageFile = [PFFile fileWithName:@"img" data:imageData];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
			// 3 If the save was successful, create a new Parse object to contain the image and all the relevant data (the user’s name and Facebook user ID). The timestamp is saved automatically with the object when it is sent to Parse. Save this new object asynchronously.
            PFObject *wallImageObject = [PFObject objectWithClassName:@"WallImage"];
            wallImageObject[@"image"] = imageFile;
            wallImageObject[@"userFBId"] = [[PFUser currentUser] objectForKey:@"fbId"];
            wallImageObject[@"user"] = [PFUser currentUser].username;
			
            [wallImageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
					// 4 If the save was successful, save the comment in another new Parse object. Again, save the user’s name and Facebook user ID along with the comment string.
					PFObject *wallImageCommentObject = [PFObject objectWithClassName:@"WallImageComment"];
					wallImageCommentObject[@"comment"] = comment;
					wallImageCommentObject[@"userFBId"] = [[PFUser currentUser] objectForKey:@"fbId"];
					wallImageCommentObject[@"user"] = [PFUser currentUser].username;
					wallImageCommentObject[@"imageObjectId"] = wallImageObject.objectId;
					
					[wallImageCommentObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
						// 5 Once this is all done, report success back to the delegate class.
						if ([delegate respondsToSelector:@selector(commsUploadImageComplete:)]) {
							[delegate commsUploadImageComplete:YES];
						}
					}];
                } else {
					// 6 If there was an error saving the wallImage Parse object, report the failure back to the delegate class.
					if ([delegate respondsToSelector:@selector(commsUploadImageComplete:)]) {
						[delegate commsUploadImageComplete:NO];
					}
                }
            }];
        } else {
			// 7 If there was an error saving the image to Parse, report the failure back to the delegate class.
			if ([delegate respondsToSelector:@selector(commsUploadImageComplete:)]) {
				[delegate commsUploadImageComplete:NO];
			}
        }
    } progressBlock:^(int percentDone) {
		// 8 During the image upload, report progress back to the delegate class.
		if ([delegate respondsToSelector:@selector(commsUploadImageProgress:)]) {
			[delegate commsUploadImageProgress:percentDone];
		}
    }];
}

+ (void) getWallImagesSince:(NSDate *)lastUpdate forDelegate:(id<CommsDelegate>)delegate
{
    // 1 get complete collectin of friends' Facebook user IDs. This is the key part of the query to Parse
    NSArray *meAndMyFriends = [DataStore instance].fbFriends.allKeys;
    
    // 2 Build Parse query with arguments:
    PFQuery *imageQuery = [PFQuery queryWithClassName:@"WallImage"]; // retireve WallImages
    [imageQuery orderByAscending:@"createdAt"]; // order by creattion date
    [imageQuery whereKey:@"updatedAt" greaterThan:lastUpdate]; // since last update
    [imageQuery whereKey:@"userFBId" containedIn:meAndMyFriends]; // only wall images from me and my friends
    
    [imageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       // 3 in the callback to the delegate you provide a new last update timestamp. Since all Parse objects are handled in blocks, you need to use the __block storage type modifer here so that you can update the variable within the block and use it outisde of the block
        __block NSDate *newLastUpdate = lastUpdate;
        
        if (error){
            NSLog(@"Objects error: %@", error.localizedDescription);
        } else {

            // 4 Loop through the returned WallImages objects array
            [objects enumerateObjectsUsingBlock:^(PFObject *wallImageObject, NSUInteger idx, BOOL *stop) {
                // 5 WallImages object contains Facebook user ID of the usr that uploaded the image. This statement looks up the user from the list of friends to resolve the full FBGraphUser object
                NSDictionary<FBGraphUser> *user = [[DataStore instance].fbFriends objectForKey:wallImageObject[@"userFBId"]];
                // 6 Create the WallImage object defined in the DataStore containing relevant info for the image
                WallImage *wallImage = [[WallImage alloc] init];
                wallImage.objectId = wallImageObject.objectId;
                wallImage.user = user;
                wallImage.createdDate = wallImageObject.updatedAt;
                // passing the image download to your shared queue, so that you’re not doing the heavy lifting on the main UI thread.
                [[NSOperationQueue pffileOperationQueue] addOperationWithBlock:^{
                    wallImage.image = [UIImage imageWithData:[(PFFile *)wallImageObject[@"image"] getData]];
                    // Notify - Image downloaded from Parse, informing all interested classes the download is complete.
                    [[NSNotificationCenter defaultCenter] postNotificationName:N_ImageDownloaded object:nil];
                }];
                
                
                // 7 If created date of this image is greater than current last update date, set new last update date so you always have the most recent timestamp.
                // Update the last update timeStamp with the most recent update
                if ([wallImageObject.updatedAt compare:newLastUpdate] == NSOrderedDescending) {
                    newLastUpdate = wallImageObject.updatedAt;
                }
                
                // 8 Store the new WallImage object in the collections in the DataStore
                [[DataStore instance].wallImages insertObject:wallImage atIndex:0];
                [[DataStore instance].wallImageMap setObject:wallImage forKey:wallImage.objectId];
                
            }]; //done looping through objects
        }
        
        // Callback
        if ([delegate respondsToSelector:@selector(commsDidGetNewWallImages:)]){
            [delegate commsDidGetNewWallImages:newLastUpdate];
        }
        
    }];
}

+ (void) getWallImageCommentsSince:(NSDate *)lastUpdate forDelegate:(id<CommsDelegate>)delegate
{
    // Get all the Wall Image object Ids
    NSArray *wallImageObjectIds = [DataStore instance].wallImageMap.allKeys;
    
    // Execute the PFQuery to get the Wall Images Comments for all the Wall Images
    PFQuery *commentQuery = [PFQuery queryWithClassName:@"WallImageComment"];
    [commentQuery orderByAscending:@"createdAt"];
    [commentQuery whereKey:@"updatedAt" greaterThan:lastUpdate];
    [commentQuery whereKey:@"imageObjectId" containedIn:wallImageObjectIds];
    [commentQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        // In the callback, we will return the latest update timestamp with this request
        __block NSDate *newLastUpdate = lastUpdate;
        if (error) {
            NSLog(@"Objects error: %@", error.localizedDescription);
        }
        else {
            [objects enumerateObjectsUsingBlock:^(PFObject *wallImageCommentObject, NSUInteger idx, BOOL *stop) {
               // Look up the user's Facebook Graph User
                NSDictionary<FBGraphUser> *user = [[DataStore instance].fbFriends objectForKey:wallImageCommentObject[@"userFBId"]];
                
                // 1
                // Look up the Wall Image
                WallImage *wallImage = [[DataStore instance].wallImageMap objectForKey:wallImageCommentObject[@"imageObjectId"]];
                // Add the Comment to the Wall Image
                if (wallImage) {
                    WallImageComment *wallImageComment = [[WallImageComment alloc] init];
                    wallImageComment.user = user;
                    wallImageComment.createDate = wallImageCommentObject.updatedAt;
                    wallImageComment.comment = wallImageCommentObject[@"comment"];
                    if ([wallImageCommentObject.updatedAt compare:newLastUpdate] == NSOrderedDescending) {
                        newLastUpdate = wallImageCommentObject.updatedAt;
                    }
                    
                    // 2
                    [wallImage.comments addObject:wallImageComment];
                }
                
            }];
        }
        
        // Callback
        if ([delegate respondsToSelector:@selector(commsDidGetWallImageComments:)]) {
            [delegate commsDidGetWallImageComments:newLastUpdate];
        }
        
    }];
    
}

+ (void) addComment:(NSString *)comment toWallImage:(WallImage *)wallImage
{
    // Save the new Comment to the Wall Image
    PFObject *wallImageCommentObject = [PFObject objectWithClassName:@"WallImageComment"];
    wallImageCommentObject[@"comment"] = comment;
    wallImageCommentObject[@"userFBId"] = [[PFUser currentUser] objectForKey:@"fbId"];
    wallImageCommentObject[@"user"] = [PFUser currentUser].username;
    
    // Set the object id for the ascoiated WallImage
    wallImageCommentObject[@"imageObjectId"] = wallImage.objectId;
    
    // Save the comment to Parse
    [wallImageCommentObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
       //Notify that the comment has been uploaded, using NSNotificationCenter
        [[NSNotificationCenter defaultCenter] postNotificationName:N_CommentUploaded object:nil];
    }];
    
}

@end
