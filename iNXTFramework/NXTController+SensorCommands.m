//
//  NXTController+SensorCommands.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/26/10.
//

#import "NXTController+SensorCommands.h"
#import "NXTModel.h"
#import "NXTSensor.h"
#import "NXTGenericSensor.h"
#import "NXTLowSpeed.h"

@implementation NXTController (SensorCommands)
////////////////////////
#pragma mark -
#pragma mark Sensor setup methods
////////////////////////

-(void)setInputMode:(UInt8)port type:(UInt8)type mode:(UInt8)mode
{
   NXT_ASSERT_SENSOR_PORT(port);
   
   // construct the message
   char message[] = {
      [self doReturn],
      kNXTSetInputMode,
      port,
      type,
      mode
   };
   
   // send the message
   [self sendMessage:message length:5];
}

////////////////////////
#pragma mark -
#pragma mark Sensor polling methods
////////////////////////

-(void)doSensorPoll:(NSTimer*)theTimer
{
   UInt8 port = [[theTimer userInfo] unsignedIntValue];
   [self getInputValues:port];
}

-(void)doUltrasoundPoll:(NSTimer*)theTimer
{
   UInt8 port = [[theTimer userInfo] unsignedIntValue];
   //NSLog(@"polling port %d\n", port);
   
   //
   [self getUltrasoundByte:port byte:0];
   [self LSGetStatus:port];
}

-(void)pollSensor:(UInt8)port interval:(NSTimeInterval)seconds
{
   NXT_ASSERT_SENSOR_PORT(port);
   [self invalidateSensorTimer:port];
   
   if ( seconds > 0 )
   {
      NSLog(@"pollSensor: starting poll timer");
      sensorTimers[port] = [[NSTimer scheduledTimerWithTimeInterval:seconds
                                                             target:self
                                                           selector:@selector(doSensorPoll:)
                                                           userInfo:[NSNumber numberWithUnsignedInt:port]
                                                            repeats:YES] retain];
   }
}

-(void)pollUltrasoundSensor:(UInt8)port interval:(NSTimeInterval)seconds
{
   NXT_ASSERT_SENSOR_PORT(port);
   [self invalidateSensorTimer:port]; 
   
   if ( seconds > 0 )
      sensorTimers[port] = [[NSTimer scheduledTimerWithTimeInterval:seconds
                                                             target:self
                                                           selector:@selector(doUltrasoundPoll:)
                                                           userInfo:[NSNumber numberWithUnsignedInt:port]
                                                            repeats:YES] retain];
}

- (void)invalidateSensorTimer:(UInt8)port
{
   if ( sensorTimers[port] != nil )
   {
      [sensorTimers[port] invalidate];
      sensorTimers[port] = nil;
   }
}

- (void)getInputValues:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   
   // construct the message
   char message[] = {
      kNXTRet,
      kNXTGetInputValues,
      port
   };
   
   // send the message
   [self sendMessage:message length:3];
}

- (void)getUltrasoundByte:(UInt8)port byte:(UInt8)byte
{
   if ( byte > 7 )
      return;
   char message[] = { 0x02, 0x42+byte };
   [self LSWrite:port txLength:2 rxLength:1 txData:message];
}

-(void)resetInputScaledValue:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   
   // construct the message
   char message[] = {
      [self doReturn],
      kNXTResetScaledInputValue,
      port
   };
   
   // send the message
   [self sendMessage:message length:3];
}

////////////////////////////
#pragma mark -
#pragma mark LS Methods
////////////////////////////

- (void)LSGetStatus:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   
   char message[] = {
      kNXTRet,
      kNXTLSGetStatus,
      port
   };
   
   // send the message
   [self pushLsGetStatusQueue:port];
   [self sendMessage:message length:3];
}

- (void)LSWrite:(UInt8)port txLength:(UInt8)txLength rxLength:(UInt8)rxLength txData:(void*)txData
{
   NXT_ASSERT_SENSOR_PORT(port);
   char message[5+txLength];
   
   message[0] = kNXTRet;
   message[1] = kNXTLSWrite;
   message[2] = port;
   message[3] = txLength;
   message[4] = rxLength;
   
   memcpy(message+5, txData, txLength);
   
   [self sendMessage:message length:(5+txLength)];
}

- (void)LSRead:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   
   char message[] = {
      kNXTRet,
      kNXTLSRead,
      port
   };
   
   [self pushLsReadQueue:port];
   [self sendMessage:message length:3];
}

-(void)pushLsGetStatusQueue:(UInt8)port
{
   [lsGetStatusQueue pushObject:[NSNumber numberWithUnsignedShort:port]];
}

-(UInt8)popLsGetStatusQueue
{
   id object = [lsGetStatusQueue popObject];
   return [object unsignedShortValue];
}

-(void)pushLsReadQueue:(UInt8)port
{
   [lsReadQueue pushObject:[NSNumber numberWithUnsignedShort:port]];
}

-(UInt8)popLsReadQueue
{
   id object = [lsReadQueue popObject];
   return [object unsignedShortValue];
}

-(void)clearPortQueues
{
   [lsReadQueue removeAllObjects];   
   [lsGetStatusQueue removeAllObjects];
}

///////////////////////
#pragma mark -
#pragma mark Parser methods
///////////////////////

-(void)parseInputValues:(NSData*)message
{
   UInt8  port;
   UInt8  valid;
   UInt8  isCalibrated;
   UInt8  sensorType;
   SInt8  sensorMode;
   UInt16 rawValue;
   UInt16 normalizedValue;
   SInt16 scaledValue;
   SInt16 calibratedValue;
   
   memcpy(&port,               message.bytes+5,  1); // 3
   memcpy(&valid,              message.bytes+6,  1); // 4
   memcpy(&isCalibrated,       message.bytes+7,  1); // 5
   memcpy(&sensorType,         message.bytes+8,  1); // 6
   memcpy(&sensorMode,         message.bytes+9,  1); // 7
   memcpy(&rawValue,           message.bytes+10, 2); // 8
   memcpy(&normalizedValue,    message.bytes+12, 2); // 10
   memcpy(&scaledValue,        message.bytes+14, 2); // 12
   memcpy(&calibratedValue,    message.bytes+16, 2); // 14
   
   rawValue        = OSSwapLittleToHostInt16(rawValue);
   normalizedValue = OSSwapLittleToHostInt16(normalizedValue);
   scaledValue     = OSSwapLittleToHostInt16(scaledValue);
   calibratedValue = OSSwapLittleToHostInt16(calibratedValue);
   
   NXTSensor *sensor = [[NXTModel sharedInstance] sensorForPort:port];
   if([sensor isKindOfClass:[NXTGenericSensor class]])
   {
      [(NXTGenericSensor*)sensor setIsValid:valid == 1 ? YES : NO];
      [(NXTGenericSensor*)sensor setIsCalibrated:isCalibrated == 1 ? YES : NO];
      [(NXTGenericSensor*)sensor setRawValue:rawValue];
      [(NXTGenericSensor*)sensor setNormalizedValue:normalizedValue];
      [(NXTGenericSensor*)sensor setScaledValue:scaledValue];
      [(NXTGenericSensor*)sensor setCalibratedValue:calibratedValue];
      [sensor valueUpdated];
   }
}

-(void)parseLSGetStatus:(NSData*)message
{
   UInt8 port = [self popLsGetStatusQueue];
   UInt8 bytesReady;
   memcpy(&bytesReady, message.bytes+5, 1); // 3
   //NSLog(@"Bytes ready: %d", bytesReady);
       
   if([[[NXTModel sharedInstance] sensorForPort:port] isKindOfClass:[NXTLowSpeed class]])
       [(NXTLowSpeed*)[[NXTModel sharedInstance] sensorForPort:port] lowSpeedBytesAvailable:bytesReady];
}


-(void)parseLSRead:(NSData*)message
{
   UInt8 bytesRead;
   NSData *data;
   int port = [self popLsReadQueue];
   
   memcpy(&bytesRead, message.bytes+5, 1); // 3
   
   data = [[NSData dataWithBytes:(message.bytes+6) length:bytesRead] retain];
   
   if ([nxtDelegate respondsToSelector:@selector(NXTLSRead:port:bytesRead:data:)] )
      [nxtDelegate NXTLSRead:self port:port bytesRead:bytesRead data:data];
   
   
   if([[[NXTModel sharedInstance] sensorForPort:port] isKindOfClass:[NXTLowSpeed class]])
      [(NXTLowSpeed*)[[NXTModel sharedInstance] sensorForPort:port] lowSpeedDataRecieved:data];
   
   [data release];
}

@end
