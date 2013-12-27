//
//  NSOperationQueue+SharedQueue.h
//  FBParse
//
//  Created by Yi Wang on 12/24/13.
//  Copyright (c) 2013 Toby Stephens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOperationQueue (SharedQueue)
+ (NSOperationQueue *) pffileOperationQueue;
+ (NSOperationQueue *) profilePictureOperationQueue;
@end
