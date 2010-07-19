//
//  NetConnectioh.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NetConnectioh.h"


#define kIsManualKey @"isManual"
#define kDisplayNameKey @"displayName"
#define kHostNameKey @"hostName"
#define kIPAddress @"ipAddress"
#define kPortKey @"port"

@implementation NetConnection
@synthesize displayName;
@synthesize isManual;
@synthesize hostName;
@synthesize ipAddress;
@synthesize password;
@synthesize resolvedAddress;
@synthesize port;

+(NSString*)displayNameForHost:(NSString*)host ip:(NSString*)ip andPort:(int)port
{
   NSString *tempString;
   
   if(ip == nil && host != nil){
      tempString = host;
   }else{
      if(host == nil)
         tempString = [NSString stringWithFormat:@"%@:%d", ip, port];
      else
         tempString = host;
   }
   return tempString;
}

-(id)initIsManual:(BOOL)manual 
      displayName:(NSString*)display 
         hostName:(NSString*)host
        ipAddress:(NSString*)ip 
             port:(int)portNum
{
   if(self = [super init]){
      self.isManual = manual;
      self.displayName = display;
      self.hostName = host;
      self.ipAddress = ip;
      self.port = portNum;
      self.password = kDCSDefaultPassword;
      self.resolvedAddress = nil;
   }
   return self;
}

-(id)initWithCoder:(NSCoder*)decoder
{
   //   NSLog(@"Init with coder");
   if(self = [super init]){
      self.isManual = [decoder decodeBoolForKey:kIsManualKey];
      self.displayName = [decoder decodeObjectForKey:kDisplayNameKey];
      self.hostName = [decoder decodeObjectForKey:kHostNameKey];
      self.ipAddress = [decoder decodeObjectForKey:kIPAddress];
      self.port = [decoder decodeIntForKey:kPortKey];
   }
   return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder
{
   //   NSLog(@"encode with coder");
   [encoder encodeBool:self.isManual forKey:kIsManualKey];
   [encoder encodeObject:self.displayName forKey:kDisplayNameKey];
   [encoder encodeObject:self.hostName forKey:kHostNameKey];
   [encoder encodeObject:self.ipAddress forKey:kIPAddress];
   [encoder encodeInt:self.port forKey:kPortKey];
}

-(BOOL)isEqual:(id)anObject{
   if([anObject isMemberOfClass:[NetConnection class]]){
      NetConnection *temp = (NetConnection*)anObject;
      return [self.displayName isEqualToString:temp.displayName];
   }else{
      return NO;
   }
}

-(id)copyWithZone:(NSZone*)zone
{
   NetConnection *copy = [[[self class] allocWithZone:zone] init];
   copy.isManual = self.isManual;
   copy.displayName = [self.displayName copy];
   copy.hostName = [self.hostName copy];
   copy.ipAddress = [self.ipAddress copy];
   copy.port = self.port;
   
   return copy;
}

-(void)setPassword:(NSString*)new
{
   if(![new isEqualToString:@""])
   {
      [password release];
      password = new;
      [password retain];
   }else{
      [password release];
      password = kDCSDefaultPassword;
   }
}

@end
