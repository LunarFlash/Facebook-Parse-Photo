//
//  AppDelegate.m
//  FBParse
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Register Parse Application
    [Parse setApplicationId:@"HlymoqBM2Z4RgEX8ANEvWfvxrIVHUIQphYRNweqd" clientKey:@"0qTPrqie3gn2xyilfIhazuPvSsryCmWMSd0mvevZ"];
    
    // Initialize Parse's FB Utilities Singleton. This uses the FacebookAppID we specified in ur App bundle's plist.
    [PFFacebookUtils initializeFacebook];
    
	return YES;
}
//These methods are required for your app to handle the URL callbacks that are part of OAuth authentication. You simply call a helper method in PDFFacebookUtils and it takes care of the rest.
- (BOOL) application: (UIApplication *) application handleOpenURL:(NSURL *)url
{
    return [PFFacebookUtils handleOpenURL:url];
}



- (BOOL) application: (UIApplication *) application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    return [PFFacebookUtils handleOpenURL:url];
}


@end
