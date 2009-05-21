//
//  NXTBluetoothBridgeAppDelegate.m
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

#import "NXTBluetoothBridgeAppDelegate.h"
#import "RelayServer.h"
#import "NXT.h";

@implementation NXTBluetoothBridgeAppDelegate
@synthesize toggleiPhone;
@synthesize toggleNXT;
@synthesize phoneName;
@synthesize connectMessage;
@synthesize portField;
@synthesize passwordEntry;
@synthesize batteryLevel;
@synthesize nxtRequiredCheck;
@synthesize keepNXTAliveCheck;

@synthesize relay;
@synthesize nxt;

@synthesize isRunning;
@synthesize requireNXT;
@synthesize keepNXTAlive;

#pragma mark -
#pragma mark Interface Actions

-(IBAction)toggleiPhone:(id)sender
{
   if(!isRunning)
   {
      if(!requireNXT || nxt.connected)
      {
         [self startServer];
      }else{
         NSLog(@"Please connect an NXT before starting the server with require nxt checked");
      }
   }else{
      [self stopServer];
   }
}

-(IBAction)toggleNXT:(id)sender{
   [nxt connect];
}

-(IBAction)toggleRequireNXT:(id)sender
{
   if([sender intValue] == 0)
      requireNXT = NO;
   else
      requireNXT = YES;
}

-(IBAction)toggleKeepNXTAlive:(id)sender
{
   if([sender intValue] == 0)
      keepNXTAlive = NO;
   else
      keepNXTAlive = YES;
}

#pragma mark -
#pragma mark Methods for controlling the server

-(void)startServer
{
   isRunning = YES;
   
   [self turnOffServerControls];
   
   if([portField integerValue] < 1023){
      relay.port = 8884;
      [self.portField setStringValue:@"8884"];
   }
   else
      relay.port = [portField integerValue];
      
   if(keepNXTAlive)
      [nxt pollKeepAlive];
   
   [relay performSelectorInBackground:(@selector(startUp)) withObject:nil];
   [toggleiPhone setTitle:@"Stop Server"];   
}

-(void)stopServer
{
   isRunning = NO;
   [self turnOnServerControls];
   [relay shutdownInputStream];
   [relay stop];
   [nxt stopKeepAlive];
   [toggleiPhone setTitle:@"Start Server"];   
}

-(void)turnOffServerControls
{
   [portField setEditable:NO];
   [passwordEntry setEditable:NO];
   [nxtRequiredCheck setEnabled:NO];   
}

-(void)turnOnServerControls
{
   [portField setEditable:YES];
   [passwordEntry setEditable:YES];
   [nxtRequiredCheck setEnabled:YES];
}

-(void)didRelayMessage{
//   NSLog(@"Server did relay a message, and informed delegate");
}

-(void)netConnected{
   [self.phoneName setStringValue:@"Connected"];
}

-(void)netDisconnected{
   [self.phoneName setStringValue:@"Disconnected"];
}

#pragma mark -
#pragma mark NXTDelegate methods

- (void)NXTBatteryLevel:(NXT*)nxt batteryLevel:(UInt16)level
{
   NSLog(@"Battery Level: %d milivolts", level);
   int adjusted = level - 6000;
   [batteryLevel setIntValue:(adjusted)];
}

- (void) NXTDiscovered:(NXT*)nxt
{
   [connectMessage setStringValue:@"Connected"];
   [toggleNXT setEnabled:NO];
}


// disconnected
- (void) NXTClosed:(NXT*)nxt
{
   [connectMessage setStringValue:@"Disconnected"];
   [toggleNXT setEnabled:YES];
   if(requireNXT)
   {
      [self stopServer];
   }
}


// NXT delegate methods
- (void) NXTError:(NXT*)nxt code:(int)code
{
   [connectMessage setIntValue:code];
}


// handle errors, special case ls pending communication
- (void)NXTOperationError:(NXT*)nxt operation:(UInt8)operation status:(UInt8)status
{
   if(operation == kNXT_SYS_FIND_NEXT || operation == kNXT_SYS_FIND_FIRST){
      if(status == kNXTFileNotFound){
         NSLog(@"For better or worse, we are at the end of the file list");
      }else{
         NSLog(@"nxt error: operation=0x%x status=0x%x", operation, status);         
      }
   }else if(operation == kNXT_SYS_CLOSE && status == kNXTHandleAllReadyClosed){
      ;//ignore this since its a nothing to worry about kind of thing generally;
   }else
		NSLog(@"nxt error: operation=0x%x status=0x%x", operation, status);
}


#pragma mark -
#pragma mark NSApplicationDelegate Methods

-(void)applicationWillTerminate:(NSNotification *)notification{
   [relay shutdownInputStream];
   NSLog(@"Application should terminate now");
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
   return YES;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification{
   isRunning = NO;
   requireNXT = NO;

   relay = [[RelayServer alloc] init];
   [relay setDelegate:self];
   nxt = [[NXT alloc] initWithDelegate:self];
}

@end
