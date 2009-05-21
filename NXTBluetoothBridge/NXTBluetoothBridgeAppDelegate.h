//
//  NXTBluetoothBridgeAppDelegate.h
//  NXTBluetoothBridge
//
//  Created by Daniel Siemer on 4/4/09.
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

#import <Cocoa/Cocoa.h>

@class NXT;
@class RelayServer;

@interface NXTBluetoothBridgeAppDelegate : NSObject {
   IBOutlet NSButtonCell *toggleiPhone;
   IBOutlet NSButtonCell *toggleNXT;
   IBOutlet NSTextFieldCell *phoneName;
   IBOutlet NSTextFieldCell *connectMessage;
   IBOutlet NSTextFieldCell *portField;
   IBOutlet NSLevelIndicatorCell *batteryLevel;
   IBOutlet NSSecureTextFieldCell *passwordEntry;
   IBOutlet NSButtonCell *nxtRequiredCheck;
   IBOutlet NSButtonCell *keepNXTAliveCheck;
   RelayServer *relay;
   NXT *nxt;
   
   BOOL isRunning;
   BOOL requireNXT;
   BOOL keepNXTAlive;
}
@property (nonatomic, retain) IBOutlet NSButtonCell *toggleiPhone;
@property (nonatomic, retain) IBOutlet NSButtonCell *toggleNXT;
@property (nonatomic, retain) IBOutlet NSTextFieldCell *phoneName;
@property (nonatomic, retain) IBOutlet NSTextFieldCell *connectMessage;
@property (nonatomic, retain) IBOutlet NSTextFieldCell *portField;
@property (nonatomic, retain) IBOutlet NSSecureTextFieldCell *passwordEntry;
@property (nonatomic, retain) IBOutlet NSLevelIndicatorCell *batteryLevel;
@property (nonatomic, retain) IBOutlet NSButtonCell *nxtRequiredCheck;
@property (nonatomic, retain) IBOutlet NSButtonCell *keepNXTAliveCheck;
@property (nonatomic, retain) RelayServer *relay;
@property (nonatomic, retain) NXT *nxt;

@property (nonatomic) BOOL isRunning;
@property (nonatomic) BOOL requireNXT; 
@property (nonatomic) BOOL keepNXTAlive;

-(IBAction)toggleiPhone:(id)sender;
-(IBAction)toggleNXT:(id)sender;
-(IBAction)toggleRequireNXT:(id)sender;

-(IBAction)toggleKeepNXTAlive:(id)sender;

-(void)startServer;
-(void)stopServer;
-(void)turnOffServerControls;
-(void)turnOnServerControls;

-(void)didRelayMessage;

-(void)netDisconnected;
-(void)netConnected;

@end
