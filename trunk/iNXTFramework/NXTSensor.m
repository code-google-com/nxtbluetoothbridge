//
//  NXTSensor.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/21/10.
//

#import "NXTSensor.h"
#import "NXTModel.h"
#import "NXTController.h"
#import "NXTController+SensorCommands.h"

@implementation NXTSensor
@synthesize port;
@synthesize nxtType;
@synthesize userType;
@synthesize mode;

@synthesize isPolling;

-(id)initWithPort:(UInt8)newPort
{
   if(self = [super init])
   {
      self.port = newPort;
      isPolling = NO;
   }
   return self;
}

-(BOOL)setupSensor
{
   [[NXTController sharedInstance] setInputMode:port type:nxtType mode:mode];
   return NO;
}

-(void)valueUpdated
{
   [[NXTModel sharedInstance] sensorValueUpdated:port];
}

-(NSString*)valueString
{
   return @"Base class error";
}

-(NSString*)typeString
{
   return [NXTSensor displayStringForType:userType];
}

+(NSString*)displayStringForType:(UInt8)type
{
   switch (type) {
      case kNXTTouchIndex:
         return @"Touch";
         break;
      case kNXTLightActiveIndex:
         return @"Light Active";
         break;
      case kNXTLightPassiveIndex:
         return @"Light Passive";
         break;
      case kNXTSoundIndex:
         return @"Sound";
         break;
      case kNXTSonarIndex:
         return @"Sonar";
         break;
      case kNXTColorFullIndex:
         return @"Color Full";
         break;
      case kNXTColorRedIndex:
         return @"Color Red";
         break;
      case kNXTColorBlueIndex:
         return @"Color Blue";
         break;
      case kNXTColorGreenIndex:
         return @"Color Green";
         break;
      case kNXTColorNoneIndex:
         return @"Color None";
         break;
      case kNXTMotorIndex:
         return @"Motor";
         break;
      case kNXTCustomIndex:
         return @"Custom";
         break;
      default:
         return @"Error";
         break;
   }
}

@end
