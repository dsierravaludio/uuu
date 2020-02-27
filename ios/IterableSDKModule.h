//
//  IterableSDKModule.m
//  examples
//
//  Created by DI on 25/11/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@interface IterableSDKModule: NSObject <RCTBridgeModule>
+ (void)initWithLaunchOptions:(NSDictionary*)launchOptions;
+ (void)setDeviceToken:(NSData*)token;
+ (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
+ (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler;
@end
