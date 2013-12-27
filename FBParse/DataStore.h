//
//  DataStore.h
//  FBParse
//
//  Created by Yi Wang on 12/23/13.
//

#import <Foundation/Foundation.h>

@interface DataStore : NSObject

@property (nonatomic, strong) NSMutableDictionary *fbFriends;  // FBGraphUser objects of you and your friends, keyered on Facebook user ID
@property (nonatomic, strong) NSMutableArray *wallImages;  // Wall's image objects returned from Parse
@property (nonatomic, strong) NSMutableDictionary *wallImageMap;  // Wall images keyed on object ID returned from Parse. This allows us to look up a specific Wall Image and update the comments if Parse notifies you of a new comment on an image

+ (DataStore *)instance;
- (void) reset;

@end


@interface WallImage : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) id objectId;   // Parse objectId unique to each image
@property (nonatomic, strong) NSDictionary<FBGraphUser> *user;  // all pertinent Facebook data about user that uplaoded this image; it conforms to Facebook's FBGraphUser protocol
@property (nonatomic, strong) NSDate *createdDate;
@property (nonatomic, strong) NSMutableArray *comments;

@end


@interface WallImageComment : NSObject

@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSDictionary<FBGraphUser> *user; // user information detailing who submitted the comment, conforms to FBgraphUser
@property (nonatomic, strong) NSDate *createDate;

@end