//
//  NXTRelay.m
//  iNXT
//
//  Created by Daniel Siemer on 4/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NXTNetConnection.h"
#import "nxtController.h"
#import "AsyncSocket.h"
#import "NetConnectioh.h"

@implementation NXTNetConnection
@synthesize connection;

-(id)initWithDelegate:(id<NXTConnectionDelegate>)aDelegate{
   if(self = [super initWithDelegate:aDelegate]){
      self.connection = [[AsyncSocket alloc] initWithDelegate:(id)self];      

      [[NSNotificationCenter defaultCenter] addObserver:[DCSConnectionManager sharedInstance] 
                                               selector:@selector(didConnect:) 
                                                   name:kNXTConnectionConnectedNotification 
                                                 object:self];

      [[DCSConnectionManager sharedInstance] setNetConnectionController:self];
   }
   return self;
}

-(void)dealloc
{
   [self closeStreams];
   [super dealloc];
}

- (void)closeStreams {
   [connection disconnect];
   connected = NO;
}
-(void)sendPassword
{
   char buffer[MAX_PASSWORD_LENGTH + 1];
   
   [[[[DCSConnectionManager sharedInstance] currentServer] password] getCString:buffer maxLength:MAX_PASSWORD_LENGTH + 1 encoding:NSASCIIStringEncoding];
   [self sendMessage:buffer withLength:MAX_PASSWORD_LENGTH + 1];
   [self scheduleRead];
}

-(void)passwordReply:(NSData*)reply{
   char *data = (char*)reply.bytes;
   if(reply.length >= 5 && data[4]){
      NSLog(@"Password rejected");
      connected = NO;
      [self closeStreams];
   }else{
      NSLog(@"Password Accepted");
      connected = YES;
      
      [self didConnect];
      [[NXTController sharedInstance] pollBatteryLevel:60];
   }
}

-(void)sendMessage:(NSData*)dataToSend 
{
   [connection writeData:dataToSend withTimeout:10 tag:0];
}

-(void)scheduleRead
{
   [connection readDataWithTimeout:-1 tag:0];
}

///////////////////////////////////////////////
#pragma mark DCSNetConnectionProtocol Methods
///////////////////////////////////////////////

-(void)connectCurrentConnection
{
   if(connected)
   {
      [self closeStreams];
   }
   [self connect];
}

///////////////////////////////////////////////
#pragma mark Connection to selected services
///////////////////////////////////////////////

-(void)connect
{
   NSString *tempString;
   NSError *error = nil;
   
   [self closeStreams];
   DCSConnectionManager *manager = [DCSConnectionManager sharedInstance];
   [manager swapConnection];

   if([[manager currentServer] resolvedAddress] == nil)
   {
      if([[manager currentServer] ipAddress] == nil){
         tempString = [[manager currentServer] hostName];
      }else{
         tempString = [[manager currentServer] ipAddress];
      }
      
      [connection connectToHost:tempString onPort:[[manager currentServer] port] error:&error];
   }else {
      [connection connectToAddress:[[manager currentServer] resolvedAddress] error:&error];
   }
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTNetConnectionConnectingNotification 
                                                       object:self 
                                                     userInfo:nil];
   [self performSelector:@selector(sendPassword) withObject:nil afterDelay:0.0];
}

-(void)cancelNewConnection
{
   [[DCSConnectionManager sharedInstance] cancelNewConnection];
}
/*
//search for display name for last forwarder and let the didSelectKnownRow handle it from there
-(void)reconnect
{
   if(![[[NSUserDefaults standardUserDefaults] stringForKey:kForwarderNameKey] isEqualToString:@"unknown"])
   {               
     for(NetConnection* aConnection in [[DCSConnectionManager sharedInstance] knownForwarders])
     {
        if([[aConnection displayName] isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:kForwarderNameKey]])
        {
           [delegate NXTConnectionNeedsPasswordToConnect:self];
           [[DCSConnectionManager sharedInstance] didSelectKnownAtRow:[[[DCSConnectionManager sharedInstance] knownForwarders] indexOfObject:aConnection]];
           break;
        }
     }
   }else{
      NSLog(@"No forwarder saved");
   }
}
*/
-(void)stopConnection
{
   [self closeStreams];
   [[DCSConnectionManager sharedInstance] cancelCurrentConnection];
   [[DCSConnectionManager sharedInstance] cancelNewConnection];
}

///////////////////////////////////////////////
#pragma mark AsyncSocket Delegate Methods
///////////////////////////////////////////////

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err{
   if(err != nil)
   {
      NSLog(@"Did Disconnect: %@", err);
   }
   
   if(!connected)
   {
      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTNetConnectionConnectionFailedNotification
                                                          object:self
                                                        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[[DCSConnectionManager sharedInstance] currentServer], kNetConnectionKey , nil]];
   }
   [[DCSConnectionManager sharedInstance] cancelCurrentConnection];
   [[DCSConnectionManager sharedInstance] cancelNewConnection];
   connected = NO;
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock{
   if(connected)
   {
      connected = NO;
   }
   [[DCSConnectionManager sharedInstance] cancelCurrentConnection];
   [[DCSConnectionManager sharedInstance] cancelNewConnection];
   [self didDisconnect];
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket{
   
}

- (NSRunLoop *)onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket{
   return [NSRunLoop currentRunLoop];
}

- (BOOL)onSocketWillConnect:(AsyncSocket *)sock{
   return YES;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
   NSLog(@"Connected to host %@, on port %d", host, port);
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
   if(self.connected){
      [self didRecieveData:(void*)data.bytes length:data.length];
   }
   else
      [self passwordReply:data];
}


@end
