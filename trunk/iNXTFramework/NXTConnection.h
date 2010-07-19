//
//  NXTConnection.h
//  iNXT-Remote
//
//  Created by Daniel Siemer on 2/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNXTConnectionConnectedNotification @"kNXTConnectionConnectedNotification"
#define kNXTConnectionDisconnectedNotification @"kNXTConnectionDisconnectedNotification"

#define kNXTConnectionTypeNone 0
#define kNXTConnectionTypeNetwork 1
#define kNXTConnectionTypeBluetooth 2
#define kNXTConnectionTypeUSB 3

#pragma mark -
#pragma mark NXTConnectionDelegate Protocol
@class NXTConnection;

@protocol NXTConnectionDelegate <NSObject>

@optional
-(void)NXTConnectionDidConnect:(NXTConnection*)connection;

-(void)NXTConnectionDidDisconnect:(NXTConnection*)connection;

-(void)NXTConnection:(NXTConnection*)connection didRecieveData:(void*)data withLength:(UInt8)length;

@end

#pragma mark -
#pragma mark NXTConnection interface
@interface NXTConnection : NSObject {
   id<NXTConnectionDelegate> delegate;

   BOOL connected;
}
@property (nonatomic, retain) id delegate;
@property (nonatomic, readonly) BOOL connected;

+(BOOL)initSharedConnectionWithClass:(Class)theClass andDelegate:(id<NXTConnectionDelegate>)aDelegate;
+(NXTConnection*)sharedConnection;

-(id)initWithDelegate:(id<NXTConnectionDelegate>)theDelegate;

-(void)sendMessage:(void*)message withLength:(UInt8)length;
-(void)sendMessage:(NSData*)dataToSend;
-(void)scheduleRead;

-(void)didRecieveData:(void*)data length:(UInt8)length;

-(void)connect;
-(void)stopConnection;

-(void)didDisconnect;
-(void)didConnect;

@end

