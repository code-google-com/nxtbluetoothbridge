//
//  nxtModel.h
//  iNXT
//  This file maintains the data about the currently connected NXT, and provides the throughport for messages
//  Created by Daniel Siemer on 3/26/09.
//

/*
   Most of the NXT Code is derived from Matt Harrington's LegoNXTRemote project
   Liscenced under the MIT Liscence
   
 The MIT License
 
 Copyright (c) 2009 Matt Harrington
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

#import <Foundation/Foundation.h>

#define kLeftMotorPortKey @"leftMotorPort"
#define kRightMotorPortKey @"rightMotorPort"
#define kLeftMotorReverseKey @"leftMotorReverse"
#define kRightMotorReversKey @"rightMotorReverse"
#define kSensorOneTypeKey @"sensorOneType"
#define kSensorTwoTypeKey @"sensorTwoType"
#define kSensorThreeTypeKey @"sensorThreeType"
#define kSensorFourTypeKey @"sensorFourType"

#define kNXTSensorUpdatedNotification @"kNXTSensorUpdatedNotification"
#define kNXTSensorPortKey @"kNXTSensorPortKey"
#define kNXTMotorUpdatedNotification @"kNXTMotorUpdatedNotification"
#define kNXTMotorPortKey @"kNXTMotorPortKey"


@class iNXTAppDelegate;
@class NXTController;
@class NXTSensor;
@class NXTMotor;
@class NXTFile;

@interface NXTModel : NSObject {
   iNXTAppDelegate *appDelegate;
         
   NSMutableArray *sensors;
   NSArray *motors;
   NSArray *sensorTypes;
      
   UInt16 batteryLevel;
   
   NSString *nxtName;
   UInt32 freeFlash;
   UInt8 majorFirmwareVer;
   UInt8 minorFirmwareVer;
   UInt8 majorProtocolVer;
   UInt8 minorProtocolVer;   

   NSInteger leftMotor;
   NSInteger rightMotor;
   BOOL rightReverse;
   BOOL leftReverse;
   
}
@property (nonatomic, retain) iNXTAppDelegate *appDelegate;

@property (nonatomic, readonly) NSArray *sensorTypes;

@property (nonatomic) UInt16 batteryLevel;
@property (nonatomic, retain) NSString *nxtName;
@property (nonatomic) UInt32 freeFlash;
@property (nonatomic) UInt8 majorFirmwareVer;
@property (nonatomic) UInt8 minorFirmwareVer;
@property (nonatomic) UInt8 majorProtocolVer;
@property (nonatomic) UInt8 minorProtocolVer;

@property (nonatomic) NSInteger leftMotor;
@property (nonatomic) NSInteger rightMotor;
@property (nonatomic) BOOL rightReverse;
@property (nonatomic) BOOL leftReverse;

+(NXTModel*)sharedInstance;
-(void)saveDefaults;
-(id)init;
-(void)didConnect;
-(void)didDisconnect;

-(void)refreshNXTData;

-(NSString*)typeStringForSensor:(UInt8)port;
-(void)pollSensor:(UInt8)port toggle:(BOOL)toggle;
-(void)pollServo:(UInt8)port toggle:(BOOL)toggle;
-(BOOL)isPollingSensor:(UInt8)port;
-(BOOL)isPollingServo:(UInt8)port;

-(void)setSensorUserType:(UInt8)port type:(UInt8)type;
-(void)setSensor:(NXTSensor*)sensor forPort:(UInt8)port;
-(NXTSensor*)sensorForPort:(UInt8)port withType:(UInt8)type;
-(NXTSensor*)sensorForPort:(UInt8)port;
-(NXTMotor*)motorForPort:(UInt8)port;
-(UInt8)sensorUserType:(UInt8)port;

-(BOOL)setupSensorPort:(UInt8)port;
-(void)sensorValueUpdated:(UInt8)port;
-(void)motorValueUpdated:(UInt8)port;

@end
