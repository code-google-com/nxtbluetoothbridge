//
//  NetConnectioh.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNetConnectionKey @"kNetConnectionKey"
#define kDCSDefaultPassword @"LEGOCLIENT"

@interface NetConnection : NSObject <NSCoding, NSCopying> {
   BOOL isManual;
   NSString *displayName;
   NSString *hostName;
   NSString *ipAddress;
   NSString *password;
   NSData *resolvedAddress;
   int port;
}
@property (nonatomic) BOOL isManual;
@property (nonatomic, retain) NSString *displayName;
@property (nonatomic, retain) NSString *hostName;
@property (nonatomic, retain) NSString *ipAddress;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSData *resolvedAddress;
@property (nonatomic) int port;

+(NSString*)displayNameForHost:(NSString*)host ip:(NSString*)ip andPort:(int)port;
-(id)initIsManual:(BOOL)manual displayName:(NSString*)display hostName:(NSString*)host ipAddress:(NSString*)ip port:(int)portNum;

@end
