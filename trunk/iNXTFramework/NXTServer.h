//
//  NXTServer.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 4/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AsyncSocket;
@class NXTServer;

@protocol NXTServerDelegate <NSObject>
@optional
-(void)NXTServerConnected:(NXTServer*)aServer;
-(void)NXTServerDisconnected:(NXTServer*)aServer;
@end

#ifdef TARGET_OS_IPHONE
@interface NXTServer : NSObject <NSNetServiceDelegate>
#else
@interface NXTServer : NSObject
#endif
{
   AsyncSocket *broadcastSocket;
   AsyncSocket *connectedSocket;
   id<NXTServerDelegate> delegate;
   
   NSNetService *netService;
   
   NSString *type;
   NSString *domain;
   NSString *password;
   NSString *name;
   int port;
   
   BOOL connected;
   BOOL running;
}
@property (nonatomic, retain) AsyncSocket *broadcastSocket;
@property (nonatomic, retain) AsyncSocket *connectedSocket;
@property (nonatomic, retain) id<NXTServerDelegate> delegate;
@property (nonatomic, retain) NSNetService *netService;
@property (nonatomic, retain) NSString* type;
@property (nonatomic, retain) NSString* domain;
@property (nonatomic, retain) NSString* password;
@property (nonatomic) int port;
@property (nonatomic, readonly) BOOL running;
@property (nonatomic, readonly) BOOL connected;

+(NXTServer*)sharedServer;
-(void)setSharedServerDomain:(NSString*)newDomain type:(NSString*)newType port:(int)newPort;
-(void)startServer;
-(void)stopServer;

-(void)forwardData:(NSData*)data;

@end

