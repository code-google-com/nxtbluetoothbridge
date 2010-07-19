//
//  nxtController.h
//  iNXT
//  nxtController loads up an nxtModel, and then sends/recieves messages from that nxt's communications methods
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

#define kNXTInformationUpdateNotification       @"kNXTInformationUpdateNotification"

@class NXTController;
@class NXTConnection;
@class NXTModel;
@class iNXTAppDelegate;
@class NXTFile;

@protocol NXTDelegate <NSObject>
@optional
-(void)NXTCommunicationError:(NXTController*)nxt code:(int)code;
-(void)NXTOperationError:(NXTController*)nxt operation:(UInt8)operation status:(UInt8)status;
-(void)NXTBatteryLevel:(NXTController*)nxt batteryLevel:(UInt16)batteryLevel;
-(void)NXTSleepTime:(NXTController*)nxt sleepTime:(UInt32)sleepTime;
-(void)NXTCurrentProgramName:(NXTController*)nxt currentProgramName:(NSString*)currentProgramName;
-(void)NXTLSRead:(NXTController*)nxt port:(UInt8)port bytesRead:(UInt8)bytesRead data:(NSData*)data;
-(void)NXTMessageRead:(NXTController*)nxt message:(NSData*)message localInbox:(UInt8)localInbox;
@end

@interface NSMutableArray(Queue)
- (id)popObject;
- (void)pushObject:(id)object;
@end

@interface NXTController : NSObject {
   id<NXTDelegate> nxtDelegate;

   BOOL connected;
   BOOL serverMode;
   BOOL checkStatus;
   
   NSTimer *sensorTimers[4];
   NSTimer *motorTimers[3];
   NSTimer *batteryLevelTimer;
   NSTimer *keepAliveTimer;
      
   NSMutableArray *lsGetStatusQueue;
   NSMutableArray *lsReadQueue;
}

@property (nonatomic, retain) id<NXTDelegate> nxtDelegate;
@property (nonatomic) BOOL serverMode;

+(NXTController*)sharedInstance;

-(void)didConnect;
-(void)didDisconnect;

-(UInt8)doReturn;
-(void)doBatteryPoll:(NSTimer*)theTimer;

-(void)sendMessage:(void*)message length:(UInt8)length;

-(void)parseMessage:(NSData*)message;
-(void)parseOutputState:(NSData*)message;
-(void)parseBatteryLevel:(NSData*)message;
-(void)parseKeepAlive:(NSData*)message;
-(void)parseCurrentProgram:(NSData*)message;
-(void)parseMessageRead:(NSData*)message;
-(void)parseNXTFirmwareVersion:(NSData*)message;
-(void)parseNXTInformation:(NSData*)message;

-(void)errorWithOperation:(UInt8)operation status:(UInt8)status;

-(void)playSoundFile:(NSString*)soundfile loop:(BOOL)loop;
-(void)playTone:(UInt16)tone duration:(UInt16)duration;
-(void)stopSoundPlayback;

-(void)setOutputState:(UInt8)port
                 power:(SInt8)power
                  mode:(UInt8)mode
        regulationMode:(UInt8)regulationMode
             turnRatio:(SInt8)turnRatio
              runState:(UInt8)runState
            tachoLimit:(UInt32)tachoLimit;
-(void)resetMotorPosition:(UInt8)port relative:(BOOL)relative;
-(void)getOutputState:(UInt8)port;


-(void)pollBatteryLevel:(NSTimeInterval)seconds;
-(void)getBatteryLevel;

-(void)pollServo:(UInt8)port interval:(NSTimeInterval)seconds;
-(void)stopAllTimers;

-(void)stopServo:(UInt8)port;
-(void)moveServo:(UInt8)port power:(SInt8)power tacholimit:(UInt32)tacholimit;

-(void)stopServos;
@end

