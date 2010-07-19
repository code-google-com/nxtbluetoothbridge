//
//  NXTGenericSensor.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/29/10.
//

#import <Foundation/Foundation.h>
#import "NXTSensor.h"

@interface NXTGenericSensor : NXTSensor {
   BOOL isValid;
   BOOL isCalibrated;
   UInt16 rawValue;
   UInt16 normalizedValue;
   SInt16 scaledValue;
   SInt16 calibratedValue;   
}
@property (nonatomic) BOOL isValid;
@property (nonatomic) BOOL isCalibrated;
@property (nonatomic) UInt16 rawValue;
@property (nonatomic) UInt16 normalizedValue;
@property (nonatomic) SInt16 scaledValue;
@property (nonatomic) SInt16 calibratedValue;

-(id)initWithPort:(UInt8)newPort andUserType:(UInt8)type;
-(id)initWithPort:(UInt8)newPort NXTType:(UInt8)type mode:(UInt8)nxtMode;

@end
