//
//  NXTServer.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 4/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NXTServer.h"
#import "AsyncSocket.h"
#import "NXTConnection.h"

@implementation NXTServer
@synthesize broadcastSocket;
@synthesize connectedSocket;
@synthesize delegate;
@synthesize netService;
@synthesize domain;
@synthesize type;
@synthesize port;
@synthesize password;
@synthesize running;
@synthesize connected;

+(NXTServer*)sharedServer
{
   static NXTServer *_sharedServer = nil;
   if(!_sharedServer)
   {
      _sharedServer = [[NXTServer alloc] init];
   }
   return _sharedServer;
}

-(void)setSharedServerDomain:(NSString*)newDomain type:(NSString*)newType port:(int)newPort
{
   BOOL restart = NO;
   
   if(running){
      restart = YES;
      [self stopServer];
   }
   
   self.domain = newDomain;
   self.type = newType;
   self.port = newPort;
   
   if (restart) {
      [self startServer];
   }
}

-(id)init
{
   if(self = [super init])
   {
      connected = NO;
      running = NO;
      broadcastSocket = [[AsyncSocket alloc] initWithDelegate:self];
      password = [[NSString alloc] initWithCString:"LEGOCLIENT" encoding:NSASCIIStringEncoding];
   }
   return self;
}

-(void)startServer
{
   if(!running){
      NSError *error = nil;
      [broadcastSocket acceptOnPort:port error:&error];
      if(error != nil)
      {
         NSLog(@"Error broadcasting the socket: %@", [error domain]);
      }
      running = YES;
      
      if (nil != type) {
         NSString *publishingDomain = domain ? domain : @"";
         NSString *publishingName = nil;
         if (nil != name) {
            publishingName = name;
         } else {
            NSString * thisHostName = [[NSProcessInfo processInfo] hostName];
            if ([thisHostName hasSuffix:@".local"]) {
               publishingName = [thisHostName substringToIndex:([thisHostName length] - 6)];
            }
         }
         netService = [[NSNetService alloc] initWithDomain:publishingDomain type:type name:publishingName port:[broadcastSocket localPort]];
         [netService setDelegate:self];
         [netService publish];
      }
   }
}

-(void)stopServer
{
   if(running)
   {
      [netService stop];
      [netService release];
      netService = nil;
      [broadcastSocket disconnect];
      [connectedSocket disconnect];
      [connectedSocket release];
      connectedSocket = nil;
      running = NO;
      connected = NO;
   }
}

-(void)forwardData:(NSData*)data
{
   if(connected){
      [connectedSocket writeData:data withTimeout:10.0 tag:0];
   }
}

-(void)passwordRecieved:(NSData*)data
{
   NSString *sentPassword = [[NSString alloc] initWithCString:data.bytes encoding:NSASCIIStringEncoding];

   char message[9];
   memset(message, 0, 9);
   if([self.password isEqualToString:sentPassword]){
      connected = YES;
      if([delegate respondsToSelector:@selector(NXTServerConnected:)])
         [delegate NXTServerConnected:self];
      [connectedSocket writeData:[NSData dataWithBytes:message length:9] withTimeout:10.0 tag:0];
   }else {
      message[4] = 0x01;
      connected = NO;
      [connectedSocket writeData:[NSData dataWithBytes:message length:9] withTimeout:10.0 tag:0];
      [connectedSocket disconnectAfterWriting];
   }
   [sentPassword release];
}

///////////////////////////////////////////////
#pragma mark -
#pragma mark AsyncSocket Delegate Methods
///////////////////////////////////////////////

-(void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
   if(err != nil)
   {
      NSLog(@"Did Disconnect: %@", err);
   }
   
   connected = NO;
   if([delegate respondsToSelector:@selector(NXTServerDisconnected:)])
      [delegate NXTServerDisconnected:self];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
   if(connected)
   {
      connected = NO;
   }
   if([delegate respondsToSelector:@selector(NXTServerDisconnected:)])
      [delegate NXTServerDisconnected:self];
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
   NSLog(@"did accept new socket");
   self.connectedSocket = newSocket;
}

- (NSRunLoop *)onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket
{
   return [NSRunLoop currentRunLoop];
}

- (BOOL)onSocketWillConnect:(AsyncSocket *)sock
{
   return YES;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)aPort
{
   NSLog(@"Connected to host %@, on port %d, starting timeout on password", host, aPort);
   [connectedSocket readDataWithTimeout:10.0 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
   if(connected)
   {
      [[NXTConnection sharedConnection] sendMessage:data];
      UInt8 status = 0;
      memcpy(&status, data.bytes+2, 1);
      if(status == kNXTSysOP || status == kNXTRet)
      {
         [[NXTConnection sharedConnection] scheduleRead];
      }
   }else{
      [self passwordRecieved:data];
   }
   [connectedSocket readDataWithTimeout:-1.0 tag:0];
}

///////////////////////////////////////////////
#pragma mark -
#pragma mark NSNetServiceDelegate
///////////////////////////////////////////////

-(void)netService:(NSNetService *)sender didNotPublish:(NSDictionary*)errorDict
{
   NSLog(@"NetService failed to publish %@", [errorDict objectForKey:NSNetServicesErrorCode]);
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
   NSLog(@"NetService did publish");
}

@end
