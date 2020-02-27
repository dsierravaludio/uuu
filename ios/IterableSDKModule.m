//
//  IterableSDKModule.m
//  examples
//
//  Created by DI on 25/11/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IterableSDKModule.h"
@import IterableSDK;

#define KEY_PUSH_INTEGRATION_NAME @"pushIntegrationName"
#define KEY_API_KEY @"apiKey"
#define KEY_USER_EMAIL @"email"
#define KEY_USER_ID @"id"
#define KEY_DEBUG_LOGGING @"debugLogging"

#define ERROR_DOMAIN @"lingoda.iterable.sdk"

@implementation IterableSDKModule

static NSDictionary* _launchOptions;

+ (void)initWithLaunchOptions:(NSDictionary*)launchOptions {
  _launchOptions = [launchOptions copy];
}

+ (void)setDeviceToken:(NSData*)token {
  [IterableAPI registerToken:token];
}

+ (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  [IterableAppIntegration application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

+ (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
  [IterableAppIntegration userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}

BOOL debugLogging;

RCT_EXPORT_MODULE(IterableSDK);

RCT_EXPORT_METHOD(init:(NSDictionary *) properties resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject) {
  @try {
    
    debugLogging = [self parseDebugLogging:properties];
    
    if (debugLogging) {
      NSLog(@"IterableSDK#init: %@", properties);
    }
    
    NSString* pushIntegrationName = [properties objectForKey:KEY_PUSH_INTEGRATION_NAME];
    NSString* apiKey = [properties objectForKey:KEY_API_KEY];
    
    if (!pushIntegrationName || !apiKey) {
      @throw [NSError errorWithDomain:ERROR_DOMAIN code:1 userInfo:nil];
    }
    
    IterableConfig* config = [[IterableConfig alloc] init];
    config.pushIntegrationName = pushIntegrationName;
    
    // seems to be available for swift only...
//    if (debugLogging) {
//      config.logDelegate = [[AllLogDelegate alloc] init];
//    }
    
    // IterableAPI expects launchOptions passed here...
    // It might be useful for deeplinks (I think, but maybe push messages in general)
    [IterableAPI initializeWithApiKey:apiKey launchOptions:_launchOptions config:config];
    
    resolve(nil);
  } @catch (id e) {
    reject(@"1", @"Error initializing IterableSDK", e);
  } @finally {
    // we had created a copy of launchOptions and it must be released
    _launchOptions = nil;
  }
}

RCT_EXPORT_METHOD(login:(NSDictionary *) properties resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject) {
  
  @try {
    
    if (debugLogging) {
      NSLog(@"IterableSDK#login, properties %@", properties);
    }
    
    NSString* userEmail = [properties objectForKey:KEY_USER_EMAIL];
    
    if (userEmail != nil) {
      IterableAPI.email = userEmail;
    } else {
      NSString* userId = [properties objectForKey:KEY_USER_ID];
      if (userId != nil) {
        IterableAPI.userId = userId;
      } else {
        @throw [NSError errorWithDomain:ERROR_DOMAIN code:2 userInfo:nil];
      }
    }
    
    [IterableAPI updateUser:@{} mergeNestedObjects:0 onSuccess:nil onFailure:nil];
    
    resolve(nil);
    
  } @catch (id e) {
    reject(@"2", @"Error logging in", e);
  }
}

RCT_EXPORT_METHOD(logout:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject) {
  [IterableAPI disableDeviceForCurrentUser];
  resolve(nil);
}

RCT_EXPORT_METHOD(checkPermission:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject) {
  
  // this method does not indicate if success or not -> need to determine
  // but, in general, what _can_ be done even if there is no permission?
  
  if (debugLogging) {
    NSLog(@"IterableSDK#checkPermission");
  }
  
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
    if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
      // not authorized, ask for permission
      [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication.sharedApplication registerForRemoteNotifications];
          });
        }
        resolve(nil);
      }];
    } else {
      // already authorized
      dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication.sharedApplication registerForRemoteNotifications];
      });
      resolve(nil);
    }
  }];
}

-(BOOL)parseDebugLogging:(NSDictionary *) props {
  id value = [props objectForKey:KEY_DEBUG_LOGGING];
  if (!value) {
    return NO;
  }
  if (![value isKindOfClass:[NSNumber class]]) {
    return NO;
  }
  NSNumber* number = (NSNumber *) value;
  return [number intValue] == 1;
}

@end
