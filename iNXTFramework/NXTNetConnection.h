//
//  NXTRelay.h
//  iNXT
//
//  Created by Daniel Siemer on 4/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXTConnection.h"
#import "DCSConnectionManager.h"

#define MAX_PASSWORD_LENGTH 10
#define kNXTNetConnectionResolvedNotification @"kNXTNetConnectionResolvedNotification"
#define kNXTNetConnectionResolvingNotification @"kNXTNetConnectionResolvingNotification"
#define kNXTNetConnectionConnectingNotification @"kNXTNetConnectionConnectingNotification"
#define kNXTNetConnectionConnectionFailedNotification @"kNXTNetConnectionConnectionFailedNotification"

@class NXTNetConnection;
@class iNXTAppDelegate;
@class AsyncSocket;

@interface NXTNetConnection : NXTConnection <DCSNetConnectionProtocol> {
   AsyncSocket *connection;
}
@property (nonatomic, retain)AsyncSocket *connection;
-(void)closeStreams;
-(void)sendPassword;
-(void)passwordReply:(NSData*)reply;
-(void)scheduleRead;
-(void)cancelNewConnection;

@end
