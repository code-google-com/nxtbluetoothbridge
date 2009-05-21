//
//  NXT.h
//  NXTBluetoothBridge
//
//  Created by Daniel Siemer on 4/9/09.
/*
 The MIT License
 
 Copyright (c) 2009 Daniel Siemer
 
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
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

@class NXTBluetoothBridgeAppDelegate;

@interface NXT : NSObject {
   IOBluetoothDevice *mBluetoothDevice;
	IOBluetoothRFCOMMChannel *mRFCOMMChannel;
   NXTBluetoothBridgeAppDelegate *appDelegate;

   NSTimer *keepAliveTimer;
   
   BOOL connected;
   BOOL checkStatus;
}
@property (nonatomic, retain) NXTBluetoothBridgeAppDelegate *appDelegate;
@property (nonatomic, retain) NSTimer *keepAliveTimer;
@property (nonatomic) BOOL connected;
@property (nonatomic) BOOL checkStatus;

-(id)initWithDelegate:(NXTBluetoothBridgeAppDelegate *)delegate;
-(BOOL)connect;
-(void)sendMessage:(void*)message length:(UInt8)length;
-(void)formatAndSendMessage:(void*)message length:(UInt8)length;
-(void)parseMessage:(void*)message length:(int)length;

- (void)doKeepAlivePoll:(NSTimer*)theTimer;
- (void)keepAlive;
- (void)pollKeepAlive;
-(void)stopKeepAlive;

@end

@interface NSObject( NXTDelegate )
- (void)NXTDiscovered:(NXT*)nxt;
- (void)NXTClosed:(NXT*)nxt;
- (void)NXTCommunicationError:(NXT*)nxt code:(int)code;
- (void)NXTOperationError:(NXT*)nxt operation:(UInt8)operation status:(UInt8)status;
- (void)NXTBatteryLevel:(NXT*)nxt batteryLevel:(UInt16)batteryLevel;
- (void)NXTSleepTime:(NXT*)nxt sleepTime:(UInt32)sleepTime;
@end

