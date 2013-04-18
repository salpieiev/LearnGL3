//
//  AppDelegate.m
//  LearnGL3
//
//  Created by Sergey Alpeev on 4/18/13.
//  Copyright (c) 2013 Sergey Alpeev. All rights reserved.
//

#import "AppDelegate.h"
#import "GLView.h"



@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    GLView *glView = [[GLView alloc] initWithFrame:screenBounds];
    
    self.window = [[UIWindow alloc] initWithFrame:screenBounds];
    [self.window addSubview:glView];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
