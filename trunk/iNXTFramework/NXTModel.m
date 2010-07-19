//
//  nxtModel.m
//  iNXT
//
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

#import "NXTModel.h"
#import "NXTController.h"
#import "NXTController+FileCommands.h"
#import "NXTController+SystemCommands.h"
#import "NXTController+SensorCommands.h"
#import "NXTSensor.h"
#import "NXTSonar.h"
#import "NXTGenericSensor.h"
#import "NXTMotor.h"
#import "NXTFile.h"
#import <unistd.h>


@implementation NXTModel

@synthesize appDelegate;
@synthesize batteryLevel;
@synthesize sensorTypes;

@synthesize nxtName;
@synthesize freeFlash;
@synthesize majorFirmwareVer;
@synthesize minorFirmwareVer;
@synthesize majorProtocolVer;
@synthesize minorProtocolVer;

@synthesize rightMotor;
@synthesize leftMotor;
@synthesize rightReverse;
@synthesize leftReverse;

+ (NXTModel*)sharedInstance
{
   static NXTModel *_sharedInstance = nil;
   if (!_sharedInstance){
      _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
   }
   return _sharedInstance;
}

-(void)refreshNXTData
{
   [[NXTController sharedInstance] getNXTInfo];
   [[NXTController sharedInstance] getNXTFirmware];
   [[NXTController sharedInstance] getBatteryLevel];
}

-(void)pollSensor:(UInt8)port toggle:(BOOL)toggle{
   NXT_ASSERT_SENSOR_PORT(port);
   [[sensors objectAtIndex:port] setIsPolling:toggle];
   
   BOOL isUltrasound = [self setupSensorPort:port];

   if(toggle)
   {
      if(isUltrasound)
         [[NXTController sharedInstance] pollUltrasoundSensor:port interval:1];
      else
         [[NXTController sharedInstance] pollSensor:port interval:1];
   }
   else
   {
      if(isUltrasound)
         [[NXTController sharedInstance] pollUltrasoundSensor:port interval:0];
      else
         [[NXTController sharedInstance] pollSensor:port interval:0];
   }
}

-(void)pollServo:(UInt8)port toggle:(BOOL)toggle
{
   NXT_ASSERT_MOTOR_PORT(port);
   [[motors objectAtIndex:port] setIsPolling:toggle];
   
   if(toggle)
      [[NXTController sharedInstance] pollServo:port interval:1];
   else
      [[NXTController sharedInstance] pollServo:port interval:0];
}

-(BOOL)isPollingSensor:(UInt8)port{
   NXT_ASSERT_SENSOR_PORT(port);
   return [[sensors objectAtIndex:port] isPolling];
}
-(BOOL)isPollingServo:(UInt8)port{
   NXT_ASSERT_MOTOR_PORT(port)
   return [[motors objectAtIndex:port] isPolling];
}

-(NSString*)typeStringForSensor:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   return [[sensors objectAtIndex:port] typeString];
}

-(void)setMinorFirmwareVer:(UInt8)newVer
{
   if(newVer != minorFirmwareVer)
   {
      minorFirmwareVer = newVer;
      NSArray *newTypes;
      [sensorTypes release];
      sensorTypes = nil;
      if (minorFirmwareVer >= 28) 
      {
         newTypes = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:kNXTTouchIndex],
                                                     [NSNumber numberWithInt:kNXTSoundIndex],
                                                     [NSNumber numberWithInt:kNXTLightActiveIndex],
                                                     [NSNumber numberWithInt:kNXTLightPassiveIndex],
                                                     [NSNumber numberWithInt:kNXTSonarIndex],
                                                     [NSNumber numberWithInt:kNXTColorFullIndex],
                                                     [NSNumber numberWithInt:kNXTColorRedIndex],
                                                     [NSNumber numberWithInt:kNXTColorGreenIndex],
                                                     [NSNumber numberWithInt:kNXTColorBlueIndex],
                                                     [NSNumber numberWithInt:kNXTColorNoneIndex], nil];
      }else{
         newTypes = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:kNXTTouchIndex],
                                                     [NSNumber numberWithInt:kNXTSoundIndex],
                                                     [NSNumber numberWithInt:kNXTLightActiveIndex],
                                                     [NSNumber numberWithInt:kNXTLightPassiveIndex],
                                                     [NSNumber numberWithInt:kNXTSonarIndex], nil];         
      }
      sensorTypes = [newTypes retain];
      [newTypes release];
   }
}

-(void)setSensorUserType:(UInt8)port type:(UInt8)type
{
   NXT_ASSERT_SENSOR_PORT(port);
   if([self sensorUserType:port] != type)
   {
      [self setSensor:[self sensorForPort:port withType:type] forPort:port];
   }
}

-(void)setSensor:(NXTSensor*)sensor forPort:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   [sensors replaceObjectAtIndex:port withObject:sensor];
}

-(NXTSensor*)sensorForPort:(UInt8)port withType:(UInt8)type
{
   NXT_ASSERT_SENSOR_PORT(port);
   switch (type)
   {
      case kNXTSonarIndex:
         return [[[NXTSonar alloc] initWithPort:port] autorelease];
         break;
      default:
         return [[[NXTGenericSensor alloc] initWithPort:port andUserType:type] autorelease];
         break;
   }
}

-(NXTSensor*)sensorForPort:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   return [sensors objectAtIndex:port];
}

-(NXTMotor*)motorForPort:(UInt8)port
{
   NXT_ASSERT_MOTOR_PORT(port);
   return [motors objectAtIndex:port];
}

-(UInt8)sensorUserType:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   return [[sensors objectAtIndex:port] userType];
}

-(BOOL)setupSensorPort:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   return [[sensors objectAtIndex:port] setupSensor];
}

-(void)sensorValueUpdated:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTSensorUpdatedNotification 
                                                       object:self 
                                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:port], kNXTSensorPortKey, nil]];
}

-(void)motorValueUpdated:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTMotorUpdatedNotification 
                                                       object:self 
                                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:port], kNXTMotorPortKey, nil]];
}

+(void)initialize
{
   if ([self class] == [NXTModel class])
   {
      NSNumber *defaultLeftMotorPort      = [NSNumber numberWithInt:kNXTMotorC];
      NSNumber *defaultRightMotorPort     = [NSNumber numberWithInt:kNXTMotorB];
      NSNumber *defaultLeftReverse        = [NSNumber numberWithBool:NO];
      NSNumber *defaultRightReverse       = [NSNumber numberWithBool:NO];
      NSNumber *defaultSensorOneType      = [NSNumber numberWithInt:kNXTTouchIndex];
      NSNumber *defaultSensorTwoType      = [NSNumber numberWithInt:kNXTSoundIndex];
      NSNumber *defaultSensorThreeType    = [NSNumber numberWithInt:kNXTLightActiveIndex];
      NSNumber *defaultSensorFourType     = [NSNumber numberWithInt:kNXTSonarIndex];
      
      NSDictionary *resourceDict = [NSDictionary dictionaryWithObjectsAndKeys:defaultLeftMotorPort, kLeftMotorPortKey,
                                                                              defaultRightMotorPort, kRightMotorPortKey,
                                                                              defaultLeftReverse, kLeftMotorReverseKey,
                                                                              defaultRightReverse, kRightMotorReversKey,
                                                                              defaultSensorOneType, kSensorOneTypeKey,
                                                                              defaultSensorTwoType, kSensorTwoTypeKey,
                                                                              defaultSensorThreeType, kSensorThreeTypeKey,
                                                                              defaultSensorFourType, kSensorFourTypeKey, nil];
      
      
		[[NSUserDefaults standardUserDefaults] registerDefaults:resourceDict];
   }
}

-(id)init
{
   if(self = [super init])
   {
      //NSLog(@"Trying to init an NXT Model");
      
      self.batteryLevel = 0;
            
      NSArray *typeArray = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:kNXTTouchIndex],
                                                            [NSNumber numberWithInt:kNXTSoundIndex],
                                                            [NSNumber numberWithInt:kNXTLightActiveIndex],
                                                            [NSNumber numberWithInt:kNXTLightPassiveIndex],
                                                            [NSNumber numberWithInt:kNXTSonarIndex],
                                                            [NSNumber numberWithInt:kNXTColorFullIndex],
                                                            [NSNumber numberWithInt:kNXTColorRedIndex],
                                                            [NSNumber numberWithInt:kNXTColorGreenIndex],
                                                            [NSNumber numberWithInt:kNXTColorBlueIndex],
                                                            [NSNumber numberWithInt:kNXTColorNoneIndex], nil];
      sensorTypes = [typeArray retain];
      [typeArray release];
      
      
      NSMutableArray *sensorArray = [[NSMutableArray alloc] initWithCapacity:4];
      sensors = [sensorArray retain];
      [sensorArray release];
      
      NXTSensor *sensorOne;
      sensorOne = [self sensorForPort:kNXTSensor1 withType:[[NSUserDefaults standardUserDefaults] integerForKey:kSensorOneTypeKey]];
      [sensors addObject:sensorOne];
      
      NXTSensor *sensorTwo;
      sensorTwo = [self sensorForPort:kNXTSensor2 withType:[[NSUserDefaults standardUserDefaults] integerForKey:kSensorTwoTypeKey]];
      [sensors addObject:sensorTwo];
      
      NXTSensor *sensorThree;
      sensorThree = [self sensorForPort:kNXTSensor3 withType:[[NSUserDefaults standardUserDefaults] integerForKey:kSensorThreeTypeKey]];
      [sensors addObject:sensorThree];
      
      NXTSensor *sensorFour;
      sensorFour = [self sensorForPort:kNXTSensor4 withType:[[NSUserDefaults standardUserDefaults] integerForKey:kSensorFourTypeKey]];
      [sensors addObject:sensorFour];
      
      NSArray *motorArray = [[NSArray alloc] initWithObjects:[[[NXTMotor alloc] initWithPort:kNXTMotorA] autorelease],
                                                             [[[NXTMotor alloc] initWithPort:kNXTMotorB] autorelease],
                                                             [[[NXTMotor alloc] initWithPort:kNXTMotorC] autorelease], nil];
      motors = [motorArray retain];
      [motorArray release];
      
      leftMotor = [[NSUserDefaults standardUserDefaults] integerForKey:kLeftMotorPortKey];
      rightMotor = [[NSUserDefaults standardUserDefaults] integerForKey:kRightMotorPortKey];
      leftReverse = [[NSUserDefaults standardUserDefaults] boolForKey:kLeftMotorReverseKey];
      rightReverse = [[NSUserDefaults standardUserDefaults] boolForKey:kRightMotorReversKey];      
   }
   
   return self;
}

-(void)didConnect
{
   [self refreshNXTData];
   [[NXTController sharedInstance] doBatteryPoll:nil];
   if(![[NXTController sharedInstance] serverMode])
   {
      [[NXTController sharedInstance] pollBatteryLevel:10];
   }
}

-(void)didDisconnect
{
   minorFirmwareVer = 0;
   majorFirmwareVer = 0;
   minorProtocolVer = 0;
   majorProtocolVer = 0;
   batteryLevel = 0;
   freeFlash = 0;
   [nxtName release];
   nxtName = nil;
}

-(void)saveDefaults
{
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   
   [defaults setInteger:leftMotor forKey:kLeftMotorPortKey];
   [defaults setInteger:rightMotor forKey:kRightMotorPortKey];
   [defaults setBool:leftReverse forKey:kLeftMotorReverseKey];
   [defaults setBool:rightReverse forKey:kRightMotorReversKey];
   
   [defaults setInteger:[self sensorUserType:kNXTSensor1] forKey:kSensorOneTypeKey];
   [defaults setInteger:[self sensorUserType:kNXTSensor2] forKey:kSensorTwoTypeKey];
   [defaults setInteger:[self sensorUserType:kNXTSensor3] forKey:kSensorThreeTypeKey];
   [defaults setInteger:[self sensorUserType:kNXTSensor4] forKey:kSensorFourTypeKey];
}

-(void)dealloc{
   [appDelegate release];

   [sensors release];
   [motors release];
   [sensorTypes release];
   [nxtName release];   
   [super dealloc];
}

@end
