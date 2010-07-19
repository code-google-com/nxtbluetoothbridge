//
//  NXTGenericSensor.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/29/10.
//

#import "NXTGenericSensor.h"


@implementation NXTGenericSensor

@synthesize isValid;
@synthesize isCalibrated;
@synthesize rawValue;
@synthesize normalizedValue;
@synthesize scaledValue;
@synthesize calibratedValue;

-(id)initWithPort:(UInt8)newPort andUserType:(UInt8)type
{
   if(self = [super initWithPort:newPort])
   {
      userType = type;
      switch (userType) {
         case kNXTTouchIndex:
            nxtType = kNXTSwitch;
            mode = kNXTBooleanMode;
            break;
         case kNXTSoundIndex:
            nxtType = kNXTSoundDBA;
            mode = kNXTPCTFullScaleMode;
            break;
         case kNXTLightActiveIndex:
            nxtType = kNXTLightActive;
            mode = kNXTPCTFullScaleMode;
            break;
         case kNXTLightPassiveIndex:
            nxtType = kNXTLightInactive;
            mode = kNXTPCTFullScaleMode;
            break;
         case kNXTColorFullIndex:
            nxtType = kNXTColorFull;
            mode = kNXTRawMode;
            break;
         case kNXTColorRedIndex:
            nxtType = kNXTColorRed;
            mode = kNXTRawMode;
            break;
         case kNXTColorGreenIndex:
            nxtType = kNXTColorGreen;
            mode = kNXTRawMode;
            break;
         case kNXTColorBlueIndex:
            nxtType = kNXTColorBlue;
            mode = kNXTRawMode;
            break;
         case kNXTColorNoneIndex:
            nxtType = kNXTColorNone;
            mode = kNXTRawMode;
            break;            
         default:
            break;
      }
      
      isValid = NO;
      isCalibrated = NO;
      rawValue = 0;
      normalizedValue = 0;
      scaledValue = 0;
      calibratedValue = 0;
   }
   return self;
}

-(id)initWithPort:(UInt8)newPort NXTType:(UInt8)type mode:(UInt8)nxtMode
{
   if(self = [super initWithPort:newPort])
   {
      userType = kNXTCustomIndex;
      nxtType = type;
      mode = nxtMode;
   }
   return self;
}

-(NSString*)valueString
{
   NSString* retVal;
   switch (userType) {
      case kNXTTouchIndex:
         retVal = scaledValue == 0 ? @"open": @"closed";
         break;
      case kNXTColorFullIndex:
         switch (scaledValue) {
            case kNXTColorConstBlack:
               retVal = @"black";
               break;
            case kNXTColorConstBlue:
               retVal = @"blue";
               break;
            case kNXTColorConstGreen:
               retVal = @"green";
               break;
            case kNXTColorConstYellow:
               retVal = @"yellow";
               break;
            case kNXTColorConstRed:
               retVal = @"red";
               break;
            case kNXTColorConstWhite:
               retVal = @"white";
               break;               
            default:
               retVal = @"error";
               break;
         }
         break;
      case kNXTColorRedIndex:
      case kNXTColorGreenIndex:
      case kNXTColorBlueIndex:
      case kNXTColorNoneIndex:
         retVal = [NSString stringWithFormat:@"%d", rawValue];
         break;
      default:
         retVal = [NSString stringWithFormat:@"%d", scaledValue];
         break;
   }
   return retVal;
}

@end
