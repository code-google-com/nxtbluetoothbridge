//
//  NXTLowSpeed.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/29/10.
//

#import "NXTLowSpeed.h"
#import "NXTController.h"
#import "NXTController+SensorCommands.h"

@implementation NXTLowSpeed

-(id)initWithPort:(UInt8)newPort
{
   if(self = [super initWithPort:newPort])
   {
      self.nxtType = kNXTLowSpeed;
      self.mode = kNXTRawMode;
   }
   return self;
}

-(void)lowSpeedError:(UInt8)status;
{
   if(status == kNXTPendingCommunication)
      [[NXTController sharedInstance] LSGetStatus:port];
}

-(void)lowSpeedBytesAvailable:(UInt8)bytes
{
   [[NXTController sharedInstance] LSRead:port];
}

-(void)lowSpeedDataRecieved:(NSData*)data
{
   //abstract
}

@end
