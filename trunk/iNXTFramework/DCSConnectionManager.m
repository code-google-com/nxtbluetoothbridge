//
//  DCSConnectionManager.m
//  iNXT-Remote
//
//  Created by Daniel Siemer on 3/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DCSConnectionManager.h"
#import "NetConnectioh.h"

#define kKnownForwardersFileName @"knownForwarders.archive"
#define kKnownForwardersKey @"knownForwarders"
#define kKnownForwarderKey @"knownForwarder"

@implementation DCSConnectionManager
@synthesize baseFilePath;
@synthesize serviceType;
@synthesize domain;

@synthesize serviceBrowser;
@synthesize serviceList;
@synthesize knownForwarders;

@synthesize currentServer;
@synthesize newServer;
@synthesize newService;

@synthesize netConnectionController;
@synthesize managerDelegate;

+(void)initialize
{
   if ([self class] == [DCSConnectionManager class])
   {
      NSString *defaultForwarder = [NSString stringWithString:@"unknown"];
      NSNumber *defaultNumberOfForwarders = [NSNumber numberWithInt:0];
      
      NSDictionary *resourceDict = [NSDictionary dictionaryWithObjectsAndKeys:defaultForwarder, kKnownForwarderKey,
                                                                              defaultNumberOfForwarders, kNumberOfKnownForwardersKey, nil];
      
      
		[[NSUserDefaults standardUserDefaults] registerDefaults:resourceDict];
   }
}

+(DCSConnectionManager*)sharedInstance
{
   static DCSConnectionManager *_sharedInstance = nil;
   if (!_sharedInstance){
      _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
   }
   return _sharedInstance;
}

-(id)init
{
   if(self = [super init])
   {
      attemptingToResolve = NO;
      
      serviceBrowser = [[NSNetServiceBrowser alloc] init];
      self.serviceList = [NSMutableArray arrayWithCapacity:5];
      [serviceBrowser setDelegate:self];   }
   return self;
}

-(void)setDocumentsPath:(NSString*)path serviceType:(NSString*)type andDomain:(NSString*)aDomain
{
   self.baseFilePath = path;
   self.serviceType = type;
   self.domain = aDomain;
   
   NSData *data = [[NSMutableData alloc] initWithContentsOfFile:[self pathForForwarderFile]];
   if([data length] > 0)
   {
      NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
      
      int tempKnown = [[NSUserDefaults standardUserDefaults] integerForKey:kNumberOfKnownForwardersKey];
      NSLog(@"%@, %d", kNumberOfKnownForwardersKey, tempKnown);
      
      self.knownForwarders = [NSMutableArray arrayWithCapacity:tempKnown];
      for(int i = 0; i < tempKnown; i++){
         NetConnection *connection = [unarchiver decodeObjectForKey:[self keyForForwarder:i]];
         if([connection isManual])
            [knownForwarders addObject:connection];
      }
      [unarchiver finishDecoding];
      [unarchiver release];
      NSLog(@"known forwarders added, %d", [knownForwarders count]);
   }else{
      NSLog(@"Error Reading from file");
      self.knownForwarders = [NSMutableArray arrayWithCapacity:5];
   }
   
   [data release];
}

-(void)saveKnownForwarders:(BOOL)connected
{
   
   if(connected)
      [[NSUserDefaults standardUserDefaults] setObject:[currentServer displayName] forKey:kForwarderNameKey];
   else
      [[NSUserDefaults standardUserDefaults] setObject:@"unknown" forKey:kForwarderNameKey];
   
   NSMutableData *data = [[NSMutableData alloc] init];
   NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
   
   int i = 0;
   for(NetConnection *connection in knownForwarders)
   {
      if([connection isManual]){
         [archiver encodeObject:connection forKey:[self keyForForwarder:i]];
         i++;
      }
   }
   [archiver finishEncoding];
   [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kNumberOfKnownForwardersKey];
   
   if([data writeToFile:[self pathForForwarderFile] atomically:YES])
      NSLog(@"Known Forwarders written to file");
   else
      NSLog(@"Error in writing known forwarders to file");
   
   [archiver release];
   [data release];
}

-(void)deleteKnownForwarder:(NetConnection*)toDelete
{
   if([toDelete isEqual:currentServer]){
      [currentServer release];
      currentServer = nil;
   }
   [self.knownForwarders removeObject:toDelete];
}

-(NSString*)pathForForwarderFile
{
   return  [baseFilePath stringByAppendingPathComponent:kKnownForwardersFileName];
}

-(NSString*)keyForForwarder:(int)numberForwarder
{
   return [NSString stringWithFormat:@"%@%d", kKnownForwarderKey, numberForwarder];
}

-(void)startSearching
{
   [serviceList removeAllObjects];
   [serviceBrowser searchForServicesOfType:self.serviceType inDomain:self.domain];
}

-(void)stopSearching{
   [serviceBrowser stop];
   [serviceList removeAllObjects];
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTNetConnectionFoundForwardersUpdated object:self];
}

-(void)newConnection:(NetConnection *)newConnection
{
   [self cancelNewConnection];
   [self setNewServer:newConnection];
}

-(void)swapConnection
{
   //[currentServer release];
   self.currentServer = newServer;
   [newServer release];
   newServer = nil;
}

-(void)cancelNewConnection
{
   [newServer release];
   newServer = nil;
   [newService stop];
   [newService release];
   newService = nil;
   attemptingToResolve = NO;
}

-(void)cancelCurrentConnection
{
   [currentServer release];
   currentServer = nil;
}

-(void)setPassword:(NSString*)password
{
   [newServer setPassword:password];
   [netConnectionController connectCurrentConnection];
}

-(void)didSelectServiceAtRow:(int)row
{
   NSNetService *selectedService = [serviceList objectAtIndex:row];
   NetConnection *tempConnection = [[NetConnection alloc] initIsManual:NO
                                                           displayName:selectedService.name 
                                                              hostName:selectedService.name
                                                             ipAddress:nil
                                                                  port:0];

   [self newConnection:tempConnection];
   self.newService = selectedService;
   [newService setDelegate:self];
   [newService resolveWithTimeout:0];
   [tempConnection release];
   attemptingToResolve = YES;
   [[NSNotificationCenter defaultCenter] postNotificationName:kDCSConnectionManagerResolvingAddress
                                                       object:self
                                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys: newServer, kNetConnectionKey, nil]];
}

-(void)didSelectKnownAtRow:(int)row{
   NetConnection *temp = [knownForwarders objectAtIndex:row];
   if(![temp isEqual:currentServer]){
      [self newConnection:[knownForwarders objectAtIndex:row]];
      [managerDelegate needPasswordToConnect];
   }else{
      NSLog(@"Already connected to %@", temp.displayName);
   }
}

-(void)didSelectNewManualConnection
{
   [managerDelegate needPasswordToConnect];
}


///////////////////////////////////////////////
#pragma mark NSNetServiceDelegate
///////////////////////////////////////////////
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
   if (![serviceList containsObject:aNetService]) {
      [self willChangeValueForKey:@"serviceList"];
      [serviceList addObject:aNetService];
      [self didChangeValueForKey:@"serviceList"];
   }
   if(!moreComing){
      
      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTNetConnectionFoundForwardersUpdated object:self];
   }
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
   if ([serviceList containsObject:aNetService]) {
      [self willChangeValueForKey:@"serviceList"];
      [serviceList removeObject:aNetService];
      [self didChangeValueForKey:@"serviceList"];
   }
   if(!moreComing){
      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTNetConnectionFoundForwardersUpdated object:self];
   }   
}

-(void)netService:(NSNetService*)sender didNotResolve:(NSDictionary*)errorDict
{
   attemptingToResolve = NO;
   NSLog(@"Could not resolve address for the selected service.");
   [[NSNotificationCenter defaultCenter] postNotificationName:kDCSConnectionManagerFailedToResolve object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newServer, kNetConnectionKey, nil]];
}

-(void)netServiceDidResolveAddress:(NSNetService*)sender
{
   if(!attemptingToResolve)
      return;
   
   NSLog(@"Netservice did resolve address");
   
   attemptingToResolve = NO;
   [newServer setResolvedAddress:[[sender addresses] objectAtIndex:0]];
   [[NSNotificationCenter defaultCenter] postNotificationName:kDCSConnectionManagerResolvedAddress object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newServer, kNetConnectionKey, nil]];
   [managerDelegate needPasswordToConnect];
}

-(void)didConnect:(NSNotification*)note
{
   NSLog(@"Adding connection");
   if(![knownForwarders containsObject:currentServer] && [currentServer isManual])
   {
      [knownForwarders addObject:currentServer];
      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTNetConnectionKnownForwardersUpdated object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newServer, kNetConnectionKey, nil]];
   }
}

@end
