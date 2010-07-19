//
//  NXTLowSpeed.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/29/10.
//

#import <Foundation/Foundation.h>
#import "NXTSensor.h"

@interface NXTLowSpeed : NXTSensor {

}

-(void)lowSpeedError:(UInt8)status;
-(void)lowSpeedBytesAvailable:(UInt8)bytes;
-(void)lowSpeedDataRecieved:(NSData*)data;

@end
