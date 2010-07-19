//
//  NXTMotor.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/28/10.
//

#import <Foundation/Foundation.h>
#import "NXTSensor.h"

@interface NXTMotor : NXTSensor {
   SInt8 power;
   UInt8 regulationMode;
   SInt8 turnRatio;
   UInt8 runState;
   UInt32 tachoLimit;
   SInt32 tachoCount;
   SInt32 blockTachoCount;
   SInt32 rotationCount;
   
   UInt8 displayType;
}
@property (nonatomic) SInt8 power;
@property (nonatomic) UInt8 regulationMode;
@property (nonatomic) SInt8 turnRatio;
@property (nonatomic) UInt8 runState;
@property (nonatomic) UInt32 tachoLimit;
@property (nonatomic) SInt32 tachoCount;
@property (nonatomic) SInt32 blockTachoCount;
@property (nonatomic) SInt32 rotationCount;

@property (nonatomic) UInt8 displayType;

@end
