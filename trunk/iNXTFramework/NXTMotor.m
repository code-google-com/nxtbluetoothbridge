//
//  NXTMotor.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/28/10.
//

#import "NXTMotor.h"
#import "NXTModel.h"

@implementation NXTMotor
@synthesize power;
@synthesize regulationMode;
@synthesize turnRatio;
@synthesize runState;
@synthesize tachoLimit;
@synthesize tachoCount;
@synthesize blockTachoCount;
@synthesize rotationCount;

@synthesize displayType;

-(id)initWithPort:(UInt8)newPort
{
   if(self = [super initWithPort:newPort])
   {
      power = 0;
      regulationMode = 0;
      turnRatio = 0;
      runState = 0;
      tachoLimit = 0;
      tachoCount = 0;
      blockTachoCount = 0;
      rotationCount = 0;
      
      userType = kNXTMotorIndex;
      displayType = kNXTTachoCount;
   }
   return self;
}

-(void)valueUpdated
{
   [[NXTModel sharedInstance] motorValueUpdated:port];
}

-(NSString*)valueString
{
   NSString *retVal;
   switch (displayType) {
      case kNXTTachoCount:
         retVal = [NSString stringWithFormat:@"%d", tachoCount];
         break;
      case kNXTBlockTachoCount:
         retVal = [NSString stringWithFormat:@"%d", blockTachoCount];
         break;
      case kNXTRotationCount:
         retVal = [NSString stringWithFormat:@"%d", rotationCount];
         break;
      default:
         retVal = @"Error";
         break;
   }
   return retVal;
}

//Overrride because motor isnt quite the same as the other sensors
-(BOOL)setupSensor
{
   return NO;
}

@end
