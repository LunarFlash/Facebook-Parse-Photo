//
//  NSOperationQueue+SharedQueue.m
//  FBParse
//
//  Created by Yi Wang on 12/24/13.
//  Copyright (c) 2013 Toby Stephens. All rights reserved.
//

#import "NSOperationQueue+SharedQueue.h"

@implementation NSOperationQueue (SharedQueue)
// Now, when you call [NSOperationQueue pffileOperationQueue] you will receive a shared NSOperationQueue which you can use for all of your Parse downloads.
// When you initialize a new NSOperationQueue, you are basically creating a new background thread. You can call [NSOperationQueue mainQueue] to run code on the main thread as well.
+ (NSOperationQueue *) pffileOperationQueue
{
    static NSOperationQueue *pffileQueue = nil;
    if (pffileQueue == nil){
        pffileQueue = [[NSOperationQueue alloc] init];
        [pffileQueue setName:@"com.yi.pffilequeue"];
    }
    return pffileQueue;
}

// This queue is for loading facebook profile pictures
+ (NSOperationQueue *) profilePictureOperationQueue
{
    static NSOperationQueue *profilePictureQueue = nil;
    if (profilePictureQueue == nil) {
        profilePictureQueue = [[NSOperationQueue alloc] init];
        [profilePictureQueue setName:@"com.yi.profilepicturequeue"];
        
    }
    return profilePictureQueue;
}

@end
