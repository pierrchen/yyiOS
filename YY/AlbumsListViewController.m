//
//  YYMasterViewController.m
//  YY
//
//  Created by Pierr Chen on 12-7-14.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#import "AlbumsListViewController.h"
#import "AlbumDetailViewController.h"

#import "Album.h"
#import "Artist.h"
#import "Config.h"

#import <SDWebImage/UIImageView+WebCache.h>

#import "MBProgressHUD.h"



@interface AlbumsListViewController ()
{
    NSMutableData *jsonData;
    NSURLConnection *connection;
    NSDateFormatter * rfc3339DateFormatter;
    NSDateFormatter * userVisiableDateFormatter;
    UIImage * placeHolderImage;
    NSIndexPath *currentViewedIndexPath;
    
    MBProgressHUD *HUD;
    
    long long expectedLength;
	long long currentLength;
    
}
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation AlbumsListViewController

@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize backgroundMOC = _backgroundMOC;


#pragma mark - view life cycle management
- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *updateButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
        target:self action:@selector(updateAlbums:)];
    self.navigationItem.rightBarButtonItem = updateButton;
    
    if([self isFreshInstall]){
        [self fetchUpdateFromServer];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark - update action
- (void)updateAlbums:(id)sender
{
    
    [self fetchUpdateFromServer];
}

- (void)insertAlbum:(NSDictionary*)album
{
    
    NSString *title = [album objectForKey:@"title"];
    NSString *detail = [album objectForKey:@"content"];
    NSString *releaseDate = [album objectForKey:@"happen_at"];
    NSString *coverThumbnailUrl = [album objectForKey:@"image_small"];
    NSString *coverBigUrl = [album objectForKey:@"image_big"];
    NSString *detailUrl = [album objectForKey:@"link_mobile"];
    
    NSManagedObjectContext *context = self.backgroundMOC;
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    Album *newAlbum = (Album*) [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];

    newAlbum.title = title;    
    newAlbum.detail = detail;
    newAlbum.releaseDate = [self.rfc3339DateFormatter dateFromString:releaseDate];
    newAlbum.coverThumbnailUrl = coverThumbnailUrl;
    newAlbum.coverBigUrl = coverBigUrl;
    newAlbum.detailUrl = detailUrl;
    
    NSString *singer = [album objectForKey:@"singer"];
    
    //hack
    if ([singer isEqualToString:@"窦唯"]) {
        newAlbum.rating = [NSNumber numberWithInt:5];
    }
    
    Artist *artist = (Artist *)[NSEntityDescription
                                insertNewObjectForEntityForName:@"Artist"
                                inManagedObjectContext:self.backgroundMOC]; 
   
    //TODO:find if singer exist ,if not create it
    artist.gerne = @"rock";
    artist.name  = singer;
    
    //an album MUST have a artist
    newAlbum.artist = artist;
}

//- (void) saveContext
//{
//    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
//    NSError *error = nil;
//    if (![context save:&error]) {
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
//    }
//    
//}

- (BOOL) albumDoesNotExsitByTitle:(NSString*)albumTitle
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:self.managedObjectContext];
    
    //can not use block predict with fetch request
    //check http://stackoverflow.com/questions/3543208/nsfetchrequest-and-predicatewithblock
//    NSPredicate *predict = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary * bindings){
//        Album * album = (Album*)evaluatedObject;
//        return [album.title isEqualToString:albumTitle];
//    }];
    
    NSPredicate *predict = [NSPredicate predicateWithFormat:@"title ==  %@",albumTitle];
    
    [request setEntity:entity];
    [request setPredicate:predict];
    
    NSError *error = nil;
    
    NSUInteger count = [self.backgroundMOC countForFetchRequest:request error:&error];
    
    if(error || (count == 0)){
        return YES;
    }
    return NO;
}

- (void)fetchUpdateFromServer
{
    
    jsonData = [[NSMutableData alloc] init];
    
    NSString *requestUrl = @"http://www.rock-n-folk.com/api?tag=album&since=";
    NSString *lastUpdateTime = [self getLastUpdateTime];
    requestUrl = [requestUrl stringByAppendingString:lastUpdateTime];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestUrl]];
    
    connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    
    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.delegate = self;
    HUD.labelText = @"Connecting..";
    NSLog(@"start connecting..");
    
    //[connection start];
    
}





#pragma mark URLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    expectedLength = [response expectedContentLength];
    currentLength = 0;
    NSLog(@"get response");
    
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [jsonData appendData:data];
}

- (NSDateFormatter*) rfc3339DateFormatter
{    
    if (rfc3339DateFormatter == nil) {
        NSLocale *                  enUSPOSIXLocale;
        
        rfc3339DateFormatter = [[NSDateFormatter alloc] init];
        enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
        [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    return rfc3339DateFormatter;
}


/**
 * This method will be run in a background thread started by MBProgressHD.
 * And we have to use backgroundMOC to insert/update and finnaly merge the
 * backgoundMOC with the mainMOC.
 *
 */
 

- (void)updateLocalDatabase
{
    
    NSError *error = nil;
    NSArray *posts = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if(error){
        abort();
    }
    
    if(![NSJSONSerialization isValidJSONObject:posts]){
        NSLog(@"Not valid JSON object");
        return;
    }
    
    NSUInteger totalUpdate = [posts count];
    NSLog(@"get %d posts" , totalUpdate);
    
    if(totalUpdate == 0){
        //no update
        [self showNoUpdateHud];
        return;
        
    }

    //go and update
    self.backgroundMOC = [[NSManagedObjectContext alloc] init];
    
    [self.backgroundMOC setPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundMOCDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.backgroundMOC];  
    
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.labelText = @"Update..";
    
    int count = 0 ;
    
    //save those posts
    for (NSDictionary *post in posts){
        NSDictionary *album = (NSDictionary*)[post objectForKey:@"post"];
        NSString *title = [album objectForKey:@"title"];
        
        //To reduce the time needed to check if the album exsit,
        //we have to make sure we only insert but not update in the server 
        //check:
        //http://stackoverflow.com/questions/3446983/collection-was-mutated-while-being-enumerated-on-executefetchrequest
        
        if([self albumDoesNotExsitByTitle:title]){
            [self insertAlbum:album ];
        }
        count += 1;
        //save every 10 items to reduce the save latency
        if((count % 10) == 0){
            //save context in batch is much fast than save context for each insert
            //This will trigger NSManagedObjectContextDidSaveNotification and  
            //self.backgroundMOCDidSave will be called to merge the change
            [self.backgroundMOC save:NULL];
        }
        
        HUD.progress = (float)count / totalUpdate; 
    }

    NSLog(@"finish update");
    //save remaining posts & update config
    [self.backgroundMOC save:NULL];
    
    
    [self showDoneHud];
   
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.backgroundMOC];
    
    //clean up
    [self.backgroundMOC reset]; 
     self.backgroundMOC = nil;
   

}

- (void)showDoneHud
{
    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.labelText = @"Done";
    sleep(2);
    //[HUD hide:YES afterDelay:2];
}


- (void)showNoUpdateHud
{
    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.labelText = @"No Update";
    //[HUD hide:YES afterDelay:2];
    sleep(2);
}





- (void)backgroundMOCDidSave:(NSNotification*)notification {    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(backgroundMOCDidSave:) withObject:notification waitUntilDone:YES];
        return;
    }
    
    // We merge the background moc changes in the main moc
    
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"finish download the data ,will update local db");
    [HUD showWhileExecuting:@selector(updateLocalDatabase) onTarget:self withObject:nil animated:YES];
    [self updateLastUpdteTime];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"error when updating");
    
    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error.png"]];
	HUD.mode = MBProgressHUDModeCustomView;
    HUD.labelText = @"Update Error";
	[HUD hide:YES afterDelay:2];
    
}


#pragma mark - Table View data source delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section { 
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    
        return [NSString stringWithFormat:NSLocalizedString(@"%@", @"%@"), [sectionInfo name]];
   
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumCell"];
    
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AlbumCell"];
        [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (NSDateFormatter*)userVisiableDateFormatter
{
    if(userVisiableDateFormatter == nil){
        userVisiableDateFormatter = [[NSDateFormatter alloc] init];
        [userVisiableDateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    
    return userVisiableDateFormatter;
    
}

/**
 * coverthumbnail place holder image
 */
- (UIImage *)placeHolderImage
{
    if(placeHolderImage == nil){
        NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"album1" ofType:@"jpg"];
        placeHolderImage = [[UIImage alloc] initWithContentsOfFile:imagePath];
    }
    return placeHolderImage;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [album.title description];    
    cell.detailTextLabel.text = [self.userVisiableDateFormatter stringFromDate:album.releaseDate];
    
    
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    [cell.imageView setImageWithURL:[NSURL URLWithString:album.coverThumbnailUrl]
                placeholderImage:[self placeHolderImage]];
   
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

//alternating the backgound color
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 || indexPath.row%2 == 0) {
        UIColor *altCellColor = [UIColor colorWithWhite:0.7 alpha:0.1];
        cell.backgroundColor = altCellColor;
    }
}


//TODO:fix table view selectable index

//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)table {
//    // return list of section titles to display in section index view (e.g. "ABCD...Z#")
//    return [self.fetchedResultsController sectionIndexTitles];
//    
//}
//
//- (NSInteger)tableView:(UITableView *)table sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
//    // tell table which section corresponds to section title/index (e.g. "B",1))
//    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
//}

//do it in the storyboard
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return tableView.bounds.size.height / 4 ;
//}

#pragma mark - segue management

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        currentViewedIndexPath = indexPath;
        Album * album = (Album *)[[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDelegate:self];
        [[segue destinationViewController] setAlbum:album];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    
    NSSortDescriptor *sortByAuthorDescriptor = [[NSSortDescriptor alloc] initWithKey:@"artist.name" ascending:NO];
    
    NSSortDescriptor *sortByReleaseDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"releaseDate" ascending:NO];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortByAuthorDescriptor,sortByReleaseDateDescriptor, nil];
    
   [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"artist.name" cacheName:@"AlbumList"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */


#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
    NSLog(@"hud hide");
	[HUD removeFromSuperview];
	 HUD = nil;
}


//used to implement swipe in the detail page
#pragma mark - albumDateListDelegate 

- (Album*)getAlbumAtIndex:(NSIndexPath*)indexPath
{
    NSLog(@"AlbumDateListDelegate is called");
    //return (Album*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    return nil;
}


/**
 *get next in current section
 */
 

-(Album*)getNext
{
    
    
    NSInteger nextRow = currentViewedIndexPath.row + 1;
    NSInteger numberOfRowInSection = [self tableView:self.tableView numberOfRowsInSection:currentViewedIndexPath.section];
    
    if(nextRow >= numberOfRowInSection - 1 ){
        nextRow = numberOfRowInSection - 1;
    }
   
    NSIndexPath *next = [NSIndexPath indexPathForRow:nextRow inSection:currentViewedIndexPath.section];  
    
    currentViewedIndexPath = next;
    
    return (Album*)[self.fetchedResultsController objectAtIndexPath:next];
  
    
}

/**
 *get previous in current section
 */

-(Album*)getPrevious
{
    NSInteger nextRow = currentViewedIndexPath.row - 1;
    if(nextRow <0 ){
        nextRow = 0;
    }
    NSIndexPath *next = [NSIndexPath indexPathForRow:nextRow inSection:currentViewedIndexPath.section];  
    
    currentViewedIndexPath = next;
    return (Album*)[self.fetchedResultsController objectAtIndexPath:next];

}


#pragma mark - config stuff

-(Config*)getConfig
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Config" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:entity];
    NSError *error = nil;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    if ([array count] != 1) {
        NSLog(@"should have only one config object");
        abort();
        return nil;
        
    }
    
    return (Config*)[array objectAtIndex:0];

    
}

-(BOOL)isFreshInstall
{    
    Config *config = [self getConfig];
    
    NSNumber *isFreshInstall = config.isFreshInstall;
    
    if ([isFreshInstall isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        return YES;
    }
    
    return NO;
    
}

/**
 *Intend to be called in the main thread. So managedObjectContext was used.
 *
 */
 
-(void)updateLastUpdteTime
{
   
    Config *config = [self getConfig];
    
    config.lastUpdateTime = [NSDate date];
    config.isFreshInstall = [NSNumber numberWithBool:NO];
    
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    
    if(error){
        NSLog(@"update config error %@",error);
    }
    
   NSLog(@"intend to update lastUpateTime to %@ ,result %@ " ,
           config.lastUpdateTime,[self getLastUpdateTime]);

}


-(NSString*)getLastUpdateTime
{
 
    Config *config = [self getConfig];
    NSString *l = @"1900-00";
    if(config != nil && config.lastUpdateTime != nil){
        l = [self.userVisiableDateFormatter stringFromDate:config.lastUpdateTime];
    }
    
    NSLog(@"lastUpdateTime is %@",l );
    return l;
}



@end
