//
//  DataStore.m
//  FBParse
//
//  Created by Yi Wang on 12/23/13.
//  Copyright (c) 2013 Toby Stephens. All rights reserved.
//

#import "DataStore.h"

@implementation DataStore

static DataStore *instance = nil;
// calling [DataStore instance] anywhere in our code will return the shared instance of StasStore so everyone is working with the same data
+ (DataStore *) instance
{
    // @synchronized declares a critical section around the code block. Guarantees that only one thread can be executing that code in the block at any given time.
    @synchronized (self) {
        if (instance == nil) {
            instance = [[DataStore alloc] init];
        }
    }
    return instance;
}

- (id) init
{
    self = [super init];
    if (self) {
        _fbFriends = [[NSMutableDictionary alloc] init];
        _wallImages = [[NSMutableArray alloc] init];
        _wallImageMap = [[NSMutableDictionary alloc] init];
        
    }
    return self;
}

- (void) reset
{
    [_fbFriends removeAllObjects];
    [_wallImages removeAllObjects];
    [_wallImageMap removeAllObjects];
}


@end

#pragma mark WallImage
@implementation WallImage

-(id) init
{
    self = [super init];
    if (self) {
        //Init array of comments
         _comments = [[NSMutableArray alloc] init];
    }
    return self;
}


@end

#pragma mark WallImageComment
@implementation WallImageComment



@end
