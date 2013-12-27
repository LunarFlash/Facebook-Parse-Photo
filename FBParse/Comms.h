//
//  Comms.h
//  FBParse
//
//  Created by Terry Wang on 12/23/13.
//  Copyright (c) 2013 Toby Stephens. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const N_ImageDownloaded;
extern NSString * const N_ProfilePictureLoaded;
extern NSString * const N_CommentUploaded;
extern NSString * const N_ImageUploaded;

@protocol CommsDelegate <NSObject>
@optional
- (void) commsDidLogin:(BOOL)loggedIn;
- (void) commsUploadImageProgress:(short)progress;
- (void) commsUploadImageComplete:(BOOL)success;
- (void) commsDidGetNewWallImages:(NSDate *)updated;
- (void) commsDidGetWallImageComments:(NSDate *)updated;
@end


@interface Comms : NSObject

+ (void) login:(id<CommsDelegate>)delegate;
+ (void) uploadImage:(UIImage *)image withComment:(NSString *)comment forDelegate:(id<CommsDelegate>)delegate;
+ (void) getWallImagesSince:(NSDate *)lastUpdate forDelegate:(id<CommsDelegate>)delegate;
+ (void) getWallImageCommentsSince: (NSDate *)lastUpdate forDelegate:(id<CommsDelegate>)delegate;
+ (void) addComment:(NSString *)comment toWallImage:(WallImage *)WallImage;
@end
