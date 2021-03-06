//
//  YYAppDelegate.m
//  YY
//
//  Created by Pierr Chen on 12-7-14.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#import "YYAppDelegate.h"
#import "Artist.h"
#import "Album.h"
#import "Config.h"

#import "AlbumsListViewController.h"

@implementation YYAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //embeded Navigation Controller in the tab bar controller
//    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
//    NSArray *viewControllers = tabBarController.viewControllers;
//    
//    AlbumsListViewController *albumListViewController = (AlbumsListViewController*)[(UINavigationController*)[viewControllers objectAtIndex:0] topViewController];
//
//    albumListViewController.managedObjectContext = self.managedObjectContext;
    
    UINavigationController * albumNavigationController = (UINavigationController*)self.window.rootViewController;
    
    //[albumNavigationController setEditing:NO];
    AlbumsListViewController * albumListViewController = (AlbumsListViewController*)[albumNavigationController topViewController];
    
    albumListViewController.managedObjectContext = self.managedObjectContext;
    
    NSLog(@"Registering for push notifications...");    
    [[UIApplication sharedApplication] 
     registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert | 
      UIRemoteNotificationTypeBadge | 
      UIRemoteNotificationTypeSound)];

    
    [self checkConfig];
    //[self populateData];
    return YES;
}

- (void) checkConfig
{
    //if no Config , it is a fresh install ,initialize it
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Config" inManagedObjectContext:self.managedObjectContext];
    
    [request setEntity:entity];
    
    NSError *error = nil;

    NSUInteger count =[self.managedObjectContext countForFetchRequest:request error:&error];
    
    if (count == 0 ) {
        NSLog(@"it is a fresh install");
        //create and init
        Config * config = [NSEntityDescription insertNewObjectForEntityForName:@"Config" inManagedObjectContext:self.managedObjectContext];
        
        config.isFreshInstall = [NSNumber numberWithBool:YES];
        
        [self saveContext];
    }
    
    
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken { 
   // NSLog(@"Notification registered. Device Token %@",deviceToken);
    
    [self registerDeviceToServer:[NSString stringWithFormat:@"%@",deviceToken]];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err { 
    NSLog(@"failed to register, error = %@", err);    
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    NSLog(@"Notification received:");
    for (id key in userInfo) {
        NSLog(@"key: %@, value: %@", key, [userInfo objectForKey:key]);
    }    
    
    if ( application.applicationState == UIApplicationStateActive ){
        NSLog(@"application is in foreground");
    }else{
        NSLog(@"app was just brought from background to foreground");
    }
    
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }

    //[self populateData];

    //[self populateData];
    return __managedObjectContext;
}


#pragma mark - populate data

/**
 * to do populate it from JSON file
 */

- (void) populateData
{
    NSLog(@"will populate the database");
    //populate the data
    Artist *artist = (Artist *)[NSEntityDescription
                               insertNewObjectForEntityForName:@"Artist"
                               inManagedObjectContext:self.managedObjectContext]; 
    
    
    artist.gerne = @"rock";
    artist.name  = @"窦唯";
    
    //UIImage *coverThumbnail 
  
    //populate the data
    NSArray *albums = [NSArray arrayWithObjects:@"album1",@"album2",@"album3", nil];
    for (NSString *title in albums){
        //populate the data
        Album *album = (Album *)[NSEntityDescription
                                  insertNewObjectForEntityForName:@"Album"
                                  inManagedObjectContext:self.managedObjectContext]; 
        
        
        NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"album1" ofType:@"jpg"];
        UIImage* coverThumbnail = [[UIImage alloc] initWithContentsOfFile:imagePath];
        
        album.title = title;
        album.artist = artist;
        album.coverThumbnail = coverThumbnail;
        album.coverThumbnailUrl = @"http://yaogun.com/artist/magic3/douwei_1zc.jpg";
        album.coverBigUrl = album.coverThumbnailUrl;
        album.downloadUrl = @"http://www.baidu.com";
        album.listenUrl = @"http://www.baidu.com";
    }

    //When following is excuted, the sample data will be persitented and accmulated.
    //[self saveContext];
    
    //print out the data
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entry = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:self.managedObjectContext];
//    [request setEntity:entry];
//    NSError *error = nil;
//    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
//    
//    if(error){
//        abort();
//    }
//    
//    for(NSManagedObject *obj in results){
//       NSLog(@"album %@ artist %@",[obj valueForKey:@"title"] , 
//                                    [[obj valueForKey:@"artist"] valueForKey:@"name"]);
//        
//        if([obj valueForKey:@"artist"] == nil){
//            NSLog(@"artist for album %@ is nil" , [obj valueForKey:@"title"]);
//        }
//    }
}


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"YY" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"YY.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}



#pragma mark - notification handling

-(void)registerDeviceToServer:(NSString*)token
{
    
    NSString *apiStringPrefix = @"http://www.rock-n-folk.com/nc?func=registerDevice&&token=";
    NSString *apiString = [apiStringPrefix stringByAppendingString:[token stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:apiString]];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
                            
    [connection start];
}



-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"register successed");
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"register failed %@" , error);
}

@end
