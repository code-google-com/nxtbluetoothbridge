//
//  DCSConnectionManager.h
//  iNXT-Remote
//
//  Created by Daniel Siemer on 3/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kForwarderNameKey @"forwarderName"
#define kNumberOfKnownForwardersKey @"numberOfForwarders"
#define kDCSNetServiceHostNameKey @"kDCSNetServiceHostNameKey"

#define kNXTNetConnectionKnownForwardersUpdated @"kNXTNetConnectionKnownForwardersUpdated"
#define kNXTNetConnectionFoundForwardersUpdated @"kNXTNetConnectionFoundForwardersUpdated"
#define kDCSConnectionManagerResolvedAddress @"kDCSConnectionManagerResolvedAddress"
#define kDCSConnectionManagerFailedToResolve @"kDCSConnectionManagerFailedToResolve"
#define kDCSConnectionManagerResolvingAddress @"kDCSConnectionManagerResolvingAddress"


@class NetConnection;

@protocol DCSNetConnectionProtocol <NSObject>
   -(void)connectCurrentConnection;
@end

@protocol DCSConnectionManagerDelegate <NSObject>
   -(void)needPasswordToConnect;
@end


#ifdef TARGET_OS_IPHONE
@interface DCSConnectionManager : NSObject <NSNetServiceDelegate, NSNetServiceBrowserDelegate>
#else
@interface DCSConnectionManager : NSObject
#endif
{
   NSString *baseFilePath;
   NSString *serviceType;
   NSString *domain;

   NSNetServiceBrowser *serviceBrowser;
   NSMutableArray *serviceList;
   NSMutableArray *knownForwarders;
   
   NetConnection *currentServer;
   NetConnection *newServer;
   NSNetService *newService;
   
   id<DCSNetConnectionProtocol> netConnectionController;
   id<DCSConnectionManagerDelegate> managerDelegate;
   BOOL attemptingToResolve;
}
@property (nonatomic, retain)NSString *baseFilePath;
@property (nonatomic, retain)NSString *serviceType;
@property (nonatomic, retain)NSString *domain;

@property (nonatomic, retain)NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, retain)NSMutableArray *serviceList;
@property (nonatomic, retain)NSMutableArray *knownForwarders;

@property (nonatomic, retain)NetConnection *currentServer;
@property (nonatomic, retain)NetConnection *newServer;
@property (nonatomic, retain)NSNetService *newService;

@property (nonatomic, retain)id<DCSNetConnectionProtocol> netConnectionController;
@property (nonatomic, retain)id<DCSConnectionManagerDelegate> managerDelegate;

+(DCSConnectionManager*)sharedInstance;

-(void)setDocumentsPath:(NSString*)path serviceType:(NSString*)type andDomain:(NSString*)aDomain;

-(void)saveKnownForwarders:(BOOL)connected;
-(void)deleteKnownForwarder:(NetConnection*)toDelete;

-(NSString*)pathForForwarderFile;
-(NSString*)keyForForwarder:(int)numberForwarder;

-(void)startSearching;
-(void)stopSearching;

-(void)setPassword:(NSString*)password;
-(void)didSelectServiceAtRow:(int)row;
-(void)didSelectKnownAtRow:(int)row;
-(void)didSelectNewManualConnection;

-(void)newConnection:(NetConnection*)newConnection;
-(void)swapConnection;
-(void)cancelNewConnection;
-(void)cancelCurrentConnection;

-(void)didConnect:(NSNotification*)note;

@end
