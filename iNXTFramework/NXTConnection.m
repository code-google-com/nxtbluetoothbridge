//
//  NXTConnection.m
//  iNXT-Remote
//
//  Created by Daniel Siemer on 2/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NXTConnection.h"
#import "NXTModel.h"
#import "NXTController.h"
#import "NXTServer.h"

@implementation NXTConnection
@synthesize delegate;
@synthesize connected;

static NXTConnection *_sharedConnection = nil;
static Class currentConnectionClass = nil;

+(BOOL)initSharedConnectionWithClass:(Class)theClass andDelegate:(id<NXTConnectionDelegate>)aDelegate
{
   if([theClass isSubclassOfClass:[self class]] && theClass != currentConnectionClass)
   {
      currentConnectionClass = theClass;
      [_sharedConnection release];
      _sharedConnection = nil;
      _sharedConnection = [[theClass alloc] initWithDelegate:aDelegate];
      return YES;
   }
   return NO;
}

+(NXTConnection*)sharedConnection
{
   return _sharedConnection;
}

-(id)initWithDelegate:(id<NXTConnectionDelegate>)theDelegate
{
   if(self = [super init]){
      delegate = theDelegate;
      connected = NO;
   }
   return self;
}

/* Override this to start a connection, varies for each how this handles */
-(void)connect
{
   
}

/* Override this to stop an active connection */
-(void)stopConnection
{
   
}

/* This send message is the same across all connection types, it does formatting */
-(void)sendMessage:(void*)message withLength:(UInt8)length{
   NSData * dataToSend = [[NSData alloc] initWithBytes:message length:length];
   [self sendMessage:dataToSend];
   [dataToSend release];
}

/* Override this for each type of connection */
-(void)sendMessage:(NSData*)dataToSend
{
   
}

-(void)scheduleRead
{
   
}

-(void)didRecieveData:(void*)data length:(UInt8)length
{
   NSData *message = [[NSData alloc] initWithBytes:data length:length];
   
   if ([[NXTController sharedInstance] serverMode])
   {
      [[NXTServer sharedServer] forwardData:(NSData*)message];
   }
   [[NXTController sharedInstance] parseMessage:message];
   [message release];
}

-(void)didConnect
{
   connected = YES;
   if([delegate respondsToSelector:@selector(NXTConnectionDidConnect:)])
      [delegate NXTConnectionDidConnect:self];
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTConnectionConnectedNotification 
                                                       object:self
                                                     userInfo:nil];
   [[NXTModel sharedInstance] didConnect];
   [[NXTController sharedInstance] didConnect];
}

-(void)didDisconnect
{
   connected = NO;
   if([delegate respondsToSelector:@selector(NXTConnectionDidDisconnect:)])
      [delegate NXTConnectionDidDisconnect:self];
   [[NXTModel sharedInstance] didDisconnect];
   [[NXTController sharedInstance] didDisconnect];
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTConnectionDisconnectedNotification 
                                                       object:self
                                                     userInfo:nil];
}

@end
