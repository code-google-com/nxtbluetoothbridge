//
//  nxtController.m
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

#import "NXTController.h"
#import "NXTController+FileCommands.h"
#import "NXTController+SystemCommands.h"
#import "NXTController+SensorCommands.h"
#import "NXTModel.h"
#import "NXTConnection.h"
#import "NXTNetConnection.h"
#import "NXTFileController.h"

#import "NXTSensor.h"
#import "NXTMotor.h"
#import "NXTLowSpeed.h"
#import "NXTFile.h"

#ifndef TARGET_OS_IPHONE
#import "NXTBluetoothConnection.h"
#import "NXTUSBConnection.h"
#endif

#import <unistd.h>

@implementation NSMutableArray(Queue)
- (id)popObject
{
   id object=nil;
   if ([self count])
   {
      object=[self objectAtIndex:0];
      [object retain];
      [self removeObjectAtIndex:0];
   }
   return [object autorelease];
}

- (void)pushObject:(id)object
{
   [self addObject:object];
}

@end

@implementation NXTController

@synthesize nxtDelegate;
@synthesize serverMode;

+(NXTController*)sharedInstance
{
   static NXTController *_sharedInstance = nil;
   if (!_sharedInstance){
      _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
   }
   return _sharedInstance;
}


-(id)init{
   //NSLog(@"Trying to initialize an NXT Controller");
   if(self = [super init]){
      connected = NO;
      checkStatus = NO;
      serverMode = NO;
      
      for (int i = 0; i < 4; i++ )
         sensorTimers[i] = nil;
      
      lsGetStatusQueue = [[NSMutableArray alloc] init];
      lsReadQueue = [[NSMutableArray alloc] init];
            
      
      [NXTModel sharedInstance];
   }
   return self;
}

-(void)resetConnection
{
   [self stopAllTimers];
   [self clearPortQueues];
}

-(void)didConnect
{
   [self resetConnection];
}

-(void)didDisconnect
{
   [self resetConnection];
}

-(void)dealloc
{
   [nxtDelegate release];

   [batteryLevelTimer release];
   [keepAliveTimer release];
/*   [wildCard release];
   [localFilePath release];
   [localFileName release];
   [currentOpenFile release];*/
   [lsGetStatusQueue release];
   [lsReadQueue release];

//   [dataBuffer release];
   [super dealloc];
}

- (void)dumpMessage:(const void*)message length:(int)length prefix:(NSString*)prefix
{
   NSString *hexMessage = [NSString string];
   int i;
   for (i = 0; i < length; i++)
      hexMessage = [hexMessage stringByAppendingString:[NSString stringWithFormat:@"%.2p, ", *((unsigned char *)message+i)]];
   NSLog(@"%@%@", prefix, hexMessage);
}

- (void)dumpMessage:(NSData*)message prefix:(NSString*)prefix
{
   [self dumpMessage:[message bytes] length:[message length] prefix:prefix];
}

-(void)sendMessage:(void*)message length:(UInt8)length
{   
//   [self dumpMessage:message length:length prefix:@"-> "];
   if([[NXTConnection sharedConnection] connected])
   {
      char fullMessage[length + 2]; // maximum message size (64) + size (2)
      fullMessage[0] = length;
      fullMessage[1] = 0;
      memcpy(fullMessage+2, message, length);
      
      NSData *fullData = [[NSData alloc] initWithBytes:fullMessage length:length+2];
      [[NXTConnection sharedConnection] sendMessage:fullData];
      if(fullMessage[2] == kNXTSysOP || fullMessage[2] == kNXTRet)
         [[NXTConnection sharedConnection] scheduleRead];
      
      [fullData release];
   }else{
      [self resetConnection];
      //[self.nxtDelegate updateProgressBar];
   }
}

////////////////////////////////
#pragma mark -
#pragma mark Message Parsing
////////////////////////////////

-(void)parseMessage:(NSData*)message
{
   //[self dumpMessage:message length:length prefix:@"<- "];
   
   UInt16 messageLength = 0;
   UInt8  opCode = 0;
   UInt8 status = 0;
   
   // get the command length
   memcpy(&messageLength, message.bytes, 2);
   messageLength = message.length;
   
   // read the opcode and status
   memcpy(&opCode, message.bytes+3, 1);
   memcpy(&status, message.bytes+4, 1);
   
   if ( status != kNXTSuccess){
      [self errorWithOperation:opCode status:status];
      if([nxtDelegate respondsToSelector:@selector(NXTOperationError:operation:status:)])
         [nxtDelegate NXTOperationError:self operation:opCode status:status];
   }else {
      switch (opCode) {
         case kNXTGetOutputState:
            [self parseOutputState:message];
            break;
         case kNXTGetInputValues:
            [self parseInputValues:message];
            break;
         case kNXTGetBatteryLevel:
            [self parseBatteryLevel:message];
            break;
         case kNXTKeepAlive:
            [self parseKeepAlive:message];
            break;
         case kNXTLSGetStatus:
            if(!serverMode)
               [self parseLSGetStatus:message];
            break;
         case kNXTLSRead:
            [self parseLSRead:message];
            break;
         case kNXTGetCurrentProgramName:
            [self parseCurrentProgram:message];
            break;
         case kNXTMessageRead:
            [self parseMessageRead:message];
            break;
         case kNXT_SYS_FIND_FIRST:
            if(!serverMode)
               [self parseSysFindFirstFile:message];
            break;
         case kNXT_SYS_FIND_NEXT:
            if(!serverMode)
               [self parseSysFindNextFile:message];
            break;
         case kNXT_SYS_CLOSE:
            if(!serverMode)
               [self parseSysFileClose:message];
            break;
         case kNXT_SYS_OPEN_READ:
            if(!serverMode)
               [self parseSysFileOpenRead:message];
            break;
         case kNXT_SYS_OPEN_WRITE:
            if(!serverMode)
               [self parseSysFileOpenWrite:message];
            break;
         case kNXT_SYS_OPEN_WRITE_LINEAR:
            if(!serverMode)
               [self parseSysFileOpenWriteLinear:message];
            break;
         case kNXT_SYS_OPEN_WRITE_DATA:
            if(!serverMode)
               [self parseSysFileOpenWriteData:message];
            break;
         case kNXT_SYS_DELETE:
            if(!serverMode)
               [self parseSysFileDeleted:message];
            break;
         case kNXT_SYS_READ:
            if(!serverMode)
               [self parseSysFileRead:message];
            break;
         case kNXT_SYS_WRITE:
            if(!serverMode)
               [self parseSysFileWrite:message];
            break;
         case kNXT_SYS_GET_FIRMWARE_VERSION:
            [self parseNXTFirmwareVersion:message];
            break;
         case kNXT_SYS_GET_DEVICE_INFO:
            [self parseNXTInformation:message];
            break;
         default:
            break;
      }
   }
}

-(void)parseOutputState:(NSData*)message
{
   UInt8 port;
   SInt8 power;
   UInt8 mode;
   UInt8 regulationMode;
   SInt8 turnRatio;
   UInt8 runState;
   UInt32 tachoLimit;
   SInt32 tachoCount;
   SInt32 blockTachoCount;
   SInt32 rotationCount;
   
   memcpy(&port,            message.bytes+5,  1); // 3
   memcpy(&power,           message.bytes+6,  1); // 4
   memcpy(&mode,            message.bytes+7,  1); // 5
   memcpy(&regulationMode,  message.bytes+8,  1); // 6
   memcpy(&turnRatio,       message.bytes+9,  1); // 7
   memcpy(&runState,        message.bytes+10,  1); // 8
   memcpy(&tachoLimit,      message.bytes+11,  4); // 9
   memcpy(&tachoCount,      message.bytes+15, 4); // 13
   memcpy(&blockTachoCount, message.bytes+19, 4); // 17
   memcpy(&rotationCount,   message.bytes+23, 4); // 21
   
   tachoLimit      = OSSwapLittleToHostInt32(tachoLimit);
   tachoCount      = OSSwapLittleToHostInt32(tachoCount);
   blockTachoCount = OSSwapLittleToHostInt32(blockTachoCount);
   rotationCount   = OSSwapLittleToHostInt32(rotationCount);
   
   
   NXTMotor *motor = [[NXTModel sharedInstance] motorForPort:port];
   [motor setPower:power];
   [motor setTachoCount:tachoCount];
   [motor setBlockTachoCount:blockTachoCount];
   [motor setRotationCount:rotationCount];
   [motor valueUpdated];
}

-(void)parseBatteryLevel:(NSData*)message
{
   UInt16 batteryLevel;
   
   memcpy(&batteryLevel, message.bytes+5, 2); // 3
   
   batteryLevel = OSSwapLittleToHostInt16(batteryLevel);
   
   [[NXTModel sharedInstance] setBatteryLevel:batteryLevel];
   
   if ( [nxtDelegate respondsToSelector:@selector(NXTBatteryLevel:batteryLevel:)] )
      [nxtDelegate NXTBatteryLevel:self batteryLevel:batteryLevel];

   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTInformationUpdateNotification object:self];
}

-(void)parseKeepAlive:(NSData*)message
{
   UInt32 sleepTime;
   
   memcpy(&sleepTime, message.bytes+5, 4); // 3
   
   sleepTime = OSSwapLittleToHostInt32(sleepTime);
   
   if ( [nxtDelegate respondsToSelector:@selector(NXTSleepTime:sleepTime:)] )
      [nxtDelegate NXTSleepTime:self sleepTime:sleepTime];
}

-(void)parseCurrentProgram:(NSData*)message
{
   NSString *currentProgramName = [[NSString stringWithCString:(message.bytes+5) encoding:NSASCIIStringEncoding] retain]; // 3-22
   
   if ( [nxtDelegate respondsToSelector:@selector(NXTCurrentProgramName:currentProgramName:)] )
      [nxtDelegate NXTCurrentProgramName:self currentProgramName:currentProgramName];
   [currentProgramName release];
}

-(void)parseMessageRead:(NSData*)message
{
   UInt8 localInbox;
   UInt8 messageSize;
   NSData *nxtMessage;
   
   memcpy(&localInbox, message.bytes+5, 1); // 3
   memcpy(&messageSize, message.bytes+6, 1); // 4
   nxtMessage = [NSData dataWithBytes:message.bytes+7 length:messageSize-1];
   
   if ( [nxtDelegate respondsToSelector:@selector(NXTMessageRead:message:localInbox:)] )
      [nxtDelegate NXTMessageRead:self message:nxtMessage localInbox:localInbox];
}

-(void)parseNXTFirmwareVersion:(NSData*)message
{
   UInt8 majorFirmwareVer;
   UInt8 minorFirmwareVer;
   UInt8 majorProtocolVer;
   UInt8 minorProtocolVer;
   memcpy(&minorProtocolVer, message.bytes+5, 1); // 3
   memcpy(&majorProtocolVer, message.bytes+6, 1); // 4
   memcpy(&minorFirmwareVer, message.bytes+7, 1); // 5
   memcpy(&majorFirmwareVer, message.bytes+8, 1); // 6

   [[NXTModel sharedInstance] setMajorFirmwareVer:majorFirmwareVer];
   [[NXTModel sharedInstance] setMinorFirmwareVer:minorFirmwareVer];
   [[NXTModel sharedInstance] setMajorProtocolVer:majorProtocolVer];
   [[NXTModel sharedInstance] setMinorProtocolVer:minorProtocolVer];
   
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTInformationUpdateNotification object:self];
}

-(void)parseNXTInformation:(NSData*)message
{
   char cNXTName[15];
   UInt32 freeMemory;
   memcpy(cNXTName, message.bytes+5, 15);  //3
   memcpy(&freeMemory, message.bytes+31, 4); //29

   freeMemory = OSSwapLittleToHostInt32(freeMemory);
   NSString *nxtName = [[NSString alloc] initWithCString:cNXTName encoding:NSASCIIStringEncoding];
   
   [[NXTModel sharedInstance] setFreeFlash:freeMemory];
   [[NXTModel sharedInstance] setNxtName:nxtName];
   [nxtName release];

   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTInformationUpdateNotification object:self];
}

- (void)errorWithOperation:(UInt8)operation status:(UInt8)status
{
   // if communication is pending on the LS port, just keep polling
   if (operation == kNXTLSGetStatus)
   {
      if(serverMode)
         return;
      
      UInt8 port = [self popLsGetStatusQueue];
      if([[[NXTModel sharedInstance] sensorForPort:port] isKindOfClass:[NXTLowSpeed class]])
         [(NXTLowSpeed*)[[NXTModel sharedInstance] sensorForPort:port] lowSpeedError:status];
      
   }else if(operation == kNXT_SYS_FIND_NEXT || operation == kNXT_SYS_FIND_FIRST){
      if(serverMode)
         return;
      
      if(status == kNXTFileNotFound){
         [[NXTFileController sharedInstance] fileListFinished];
//         NSLog(@"For better or worse, we are at the end of the file list");
      }else{
         NSLog(@"nxt error: operation=0x%x status=0x%x", operation, status);         
      }
   }else if(operation == kNXT_SYS_CLOSE && status == kNXTHandleAllReadyClosed){
      if(serverMode)
         return;
      
      //ignore this since its a nothing to worry about kind of thing generally;
   }else if(operation == kNXT_SYS_OPEN_READ){
      if(serverMode)
         return;
      
      NSLog(@"Error opening file for read");
      [[NXTFileController sharedInstance] cancelTransfer];
   }else if(operation == kNXT_SYS_OPEN_WRITE || operation == kNXT_SYS_OPEN_WRITE_LINEAR || operation == kNXT_SYS_OPEN_WRITE_DATA){
      if(serverMode)
         return;
      
      NSLog(@"Error opening file for write");
      [[NXTFileController sharedInstance] cancelTransfer];
      if(status == kNXTFileExists)
         NSLog(@"File already exists");
   }else if(operation == kNXT_SYS_READ){
      if(serverMode)
         return;
      
      [[NXTFileController sharedInstance] downloadFileError:YES data:nil];
   }else if(operation == kNXT_SYS_WRITE){
      if(serverMode)
         return;
      
      [[NXTFileController sharedInstance] uploadFileWasError:YES amountUploaded:0];
   }else
      NSLog(@"nxt error: operation=0x%x status=0x%x", operation, status);
   
}

//////////////////////////
#pragma mark -
//////////////////////////

- (UInt8)doReturn;
{
   return checkStatus ? kNXTRet : kNXTNoRet;
}

- (void)doKeepAlivePoll:(NSTimer*)theTimer
{
   [self keepAlive];
}

- (void)doBatteryPoll:(NSTimer*)theTimer
{
   [self getBatteryLevel];
}

- (void)doServoPoll:(NSTimer*)theTimer
{
   UInt8 port = *((UInt8*) [[theTimer userInfo] bytes]);
   [self getOutputState:port];
}

- (void)playSoundFile:(NSString*)soundfile loop:(BOOL)loop
{
   char message[23] = {
      [self doReturn],
      kNXTPlaySoundFile,
      (loop ? 1 : 0)
   };
   
   [soundfile getCString:(message+3) maxLength:20 encoding:NSASCIIStringEncoding];
   
   // send the message
   [self sendMessage:message length:23];
}

- (void)playTone:(UInt16)tone duration:(UInt16)duration
{
   // construct the message
   char message[] = {
      [self doReturn],
      kNXTPlayTone,
      (tone & 0x00ff),
      (tone & 0xff00) >> 8,
      (duration & 0x00ff),
      (duration & 0xff00) >> 8
   };
   
   // send the message
   [self sendMessage:message length:6];
}

- (void)stopSoundPlayback
{
   // construct the message
   char message[] = {
      [self doReturn],
      kNXTStopSoundPlayback
   };
   
   // send the message
   [self sendMessage:message length:2];
}

- (void)setOutputState:(UInt8)port
                 power:(SInt8)power
                  mode:(UInt8)mode
        regulationMode:(UInt8)regulationMode
             turnRatio:(SInt8)turnRatio
              runState:(UInt8)runState
            tachoLimit:(UInt32)tachoLimit
{
   NXT_ASSERT_MOTOR_PORT(port);
   
   // construct the message
   char message[] = {
      [self doReturn],
      kNXTSetOutputState,
      port,
      power,
      mode,
      regulationMode,
      turnRatio,
      runState,
      (tachoLimit & 0x000000ff),
      (tachoLimit & 0x0000ff00) >> 8,
      (tachoLimit & 0x00ff0000) >> 16,
      (tachoLimit & 0xff000000) >> 24
   };
   
   // send the message
   [self sendMessage:message length:12];
}

- (void)getOutputState:(UInt8)port
{
   NXT_ASSERT_SENSOR_PORT(port);
   
   char message[] = {
      kNXTRet,
      kNXTGetOutputState,
      port
   };
   
   // send the message
   [self sendMessage:message length:3];
}

- (void)resetMotorPosition:(UInt8)port relative:(BOOL)relative
{
   // construct the message
   char message[] = {
      [self doReturn],
      kNXTResetMotorPosition,
      port,
      (relative ? 1 : 0)
   };
   
   // send the message
   [self sendMessage:message length:4];
}


- (void)getBatteryLevel
{
   char message[] = {
      kNXTRet,
      kNXTGetBatteryLevel
   };
   
   // send the message
   [self sendMessage:message length:2];
}

///////////////////////////////
#pragma mark -
#pragma mark high-level nxt interfaces
///////////////////////////////


- (void)pollBatteryLevel:(NSTimeInterval)seconds
{
   if ( batteryLevelTimer != nil )
   {
      [batteryLevelTimer invalidate];
      batteryLevelTimer = nil;
   }
   
   if ( seconds > 0 )
      batteryLevelTimer = [[NSTimer scheduledTimerWithTimeInterval:seconds
                                                            target:self
                                                          selector:@selector(doBatteryPoll:)
                                                          userInfo:nil
                                                           repeats:YES] retain];
}

- (void)pollServo:(UInt8)port interval:(NSTimeInterval)seconds
{
   NXT_ASSERT_MOTOR_PORT(port);
   
   if ( motorTimers[port] != nil )
   {
      [motorTimers[port] invalidate];
      motorTimers[port] = nil;
   }
   
   if ( seconds > 0 )
      motorTimers[port] = [[NSTimer scheduledTimerWithTimeInterval:seconds
                                                            target:self
                                                          selector:@selector(doServoPoll:)
                                                          userInfo:[NSData dataWithBytes:&port length:1]
                                                           repeats:YES] retain];
}

- (void)stopAllTimers
{
   int i;
   
   for ( i = 0; i < 4; i++ )
      [self pollSensor:i interval:0];
   for ( i = 0; i < 3; i++ )
      [self pollServo:i interval:0];
   
   if ( keepAliveTimer != nil )
   {
      [keepAliveTimer invalidate];
      keepAliveTimer = nil;
   }
   
   [self pollBatteryLevel:0];
}

-(void)stopServo:(UInt8)port
{
   NXT_ASSERT_MOTOR_PORT(port);
   [self setOutputState:port
                  power:0 
                   mode:0
         regulationMode:kNXTRegulationModeIdle
              turnRatio:0
               runState:kNXTMotorRunStateIdle 
             tachoLimit:0];
}

- (void)moveServo:(UInt8)port power:(SInt8)power tacholimit:(UInt32)tacholimit
{
   NXT_ASSERT_MOTOR_PORT(port);
   
   [self setOutputState:port
                  power:power
                   mode:(kNXTMotorOn | kNXTRegulated)
         regulationMode:kNXTRegulationModeMotorSpeed
              turnRatio:0
               runState:kNXTMotorRunStateRunning
             tachoLimit:tacholimit];
}

- (void)stopServos
{
   [self setOutputState:kNXTMotorAll
                  power:0
                   mode:0
         regulationMode:kNXTRegulationModeIdle
              turnRatio:0
               runState:kNXTMotorRunStateIdle
             tachoLimit:0];
}

- (BOOL)isConnected
{
   return connected;
}

- (void)alwaysCheckStatus:(BOOL)check
{
   checkStatus = check;
}

#pragma mark -
#pragma mark NXTConnectionDelegate

-(void)NXTConnectionDidConnect:(NXTConnection*)connection
{
   [[NXTModel sharedInstance] refreshNXTData];
}

-(void)NXTConnectionDidDisconnect:(NXTConnection*)connection
{
   
}

-(void)NXTConnection:(NXTConnection*)connection didRecieveData:(void*)data withLength:(UInt8)length
{

}

-(void)NXTConnectionWantsPasswordToConnect:(NXTConnection*)connection
{
}


@end
