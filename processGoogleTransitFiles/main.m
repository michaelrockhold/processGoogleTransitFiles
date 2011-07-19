//
//  main.m
//  processGoogleTransitFiles
//
//  Created by Michael Rockhold on 7/17/11.
//  Copyright 2011 The Rockhold Company. All rights reserved.
//


NSManagedObjectModel *managedObjectModel();
NSManagedObjectContext *managedObjectContext();

NSURL* g_dbURL = nil;
NSString* g_storeType = nil;

int main (int argc, const char * argv[])
{
    int exitCode = 0;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSArray* args = [[NSProcessInfo processInfo] arguments];
    if ( [args count] < 3 )
    {
        NSLog(@"Error not enough arguments");
        exitCode = 2; goto exit;
    }
    
    NSString* dbPath = [args objectAtIndex:1];
    NSString* googleTransitDirPath = [args objectAtIndex:2];
    
    if ( [dbPath hasSuffix:@".sqlite"] )
    {
        g_storeType = NSSQLiteStoreType;
    }
    else if ( [dbPath hasSuffix:@".bin"] )
    {
        g_storeType = NSBinaryStoreType;
    }
    else if ( [dbPath hasSuffix:@".xml"] )
    {
        g_storeType = NSXMLStoreType;
    }
    else
    {
        NSLog(@"Error: arg 1 (%@) should be a file name ending with .sqlite, .bin, or .xml", dbPath);
        exitCode = 3; goto exit;
    }
    g_dbURL = [NSURL fileURLWithPath:dbPath];
    
    // check that the googleTransitDirPath actually exists and contains all the required files
    BOOL isDir = NO;
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    
    if ( [googleTransitDirPath hasPrefix:@"~"] )
        googleTransitDirPath = [googleTransitDirPath stringByExpandingTildeInPath];
    
    if ( !([fileManager fileExistsAtPath:googleTransitDirPath isDirectory:&isDir] && isDir) )
    {
        NSLog(@"Error: arg 2 must be a directory containing a Google Transit database");
        exitCode = 5; goto exit;
    }
    
    static NSString* gtFiles[] = {
        @"agency.txt", @"pattern_pairs.txt", @"stops.txt", @"calendar_dates.txt", 
        @"routes.txt", @"trips.txt", @"fare_attributes.txt", @"shapes.txt", 
        @"fare_rules.txt", @"stop_times.txt",
        NULL
    };
    
    NSString** gtFile = gtFiles;
    while ( *gtFile )
    {
        if ( ![fileManager fileExistsAtPath:[googleTransitDirPath stringByAppendingPathComponent:*gtFile]] )
            break;
        gtFile++;
    }
    if ( *gtFile != NULL )
    {
        NSLog(@"Error: required Google Transit file %@ is missing from input directory", *gtFile);
        exitCode = 5; goto exit;
    }
    
    // Create the managed object context
    NSManagedObjectContext *context = managedObjectContext();

    // Custom code here...
    
    
    // Save the managed object context
    NSError *error = nil;    
    if ( ![context save:&error] )
    {
        NSLog(@"Error while saving %@", ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
        exitCode = 1;
        goto exit;
    }
exit:
    [pool drain];
    return exitCode;
}

NSManagedObjectModel *managedObjectModel() {
    
    static NSManagedObjectModel *model = nil;
    
    if (model != nil) {
        return model;
    }
    
    NSString *path = [[[NSProcessInfo processInfo] arguments] objectAtIndex:0];
    path = [path stringByDeletingPathExtension];
    NSURL *modelURL = [NSURL fileURLWithPath:[path stringByAppendingPathExtension:@"momd"]];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return model;
}

NSManagedObjectContext *managedObjectContext() {

    static NSManagedObjectContext *context = nil;
    if (context != nil)
    {
        return context;
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];        
    context = [[NSManagedObjectContext alloc] init];
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: managedObjectModel()];
    [context setPersistentStoreCoordinator: coordinator];
    
    NSError* error;
    NSPersistentStore* newStore = [coordinator addPersistentStoreWithType:g_storeType configuration:nil URL:g_dbURL options:nil error:&error];
    
    if (newStore == nil)
    {
        NSLog(@"Store Configuration Failure %@",
              ([error localizedDescription] != nil) ?
              [error localizedDescription] : @"Unknown Error");
    }
    [pool drain];
    return context;
}

