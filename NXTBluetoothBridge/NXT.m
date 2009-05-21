//
//  NXT.m
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
 
#import "NXT.h"
#import "NXTBluetoothBridgeAppDelegate.h"
#import "RelayServer.h"

@implementation NXT
@synthesize appDelegate;
@synthesize keepAliveTimer;
@synthesize connected;
@synthesize checkStatus;

-(id)initWithDelegate:(NXTBluetoothBridgeAppDelegate *)delegate{
   self.appDelegate = delegate;
   return self;
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

- (void)sendMessage:(void*)message length:(UInt8)length
{   
   
//   [self dumpMessage:fullMessage length:length+2 prefix:@"-> "];
   [mRFCOMMChannel writeSync:message length:length];
}

//adds the precurssor bytes, which already sent by the phone, so it just needs the method above
//Any locally generated commands though need this method
-(void)formatAndSendMessage:(void*)message length:(UInt8)length
{
   char fullMessage[length + 2]; // maximum message size (64) + size (2)
   
   fullMessage[0] = length;
   fullMessage[1] = 0;
   memcpy(fullMessage+2, message, length);
   [self sendMessage:fullMessage length:length + 2];
}

#pragma mark -
#pragma mark Bluetooth Connection Methods

- (void)close:(IOBluetoothDevice*)device
{
   
   connected = NO;
      
   if ( mBluetoothDevice == device )
   {
      IOReturn error = [mBluetoothDevice closeConnection];
      if ( error != kIOReturnSuccess )
      {
         NSLog(@"Error - failed to close the device connection with error %08lx.\n", (UInt32)error);
         if ([appDelegate respondsToSelector:@selector(NXTCommunicationError:code:)])
            [appDelegate NXTCommunicationError:self code:error];
      }
      
      [mBluetoothDevice release];
   }
}

- (BOOL)connect
{
   IOBluetoothDeviceSelectorController	*deviceSelector;
	IOBluetoothSDPUUID					*sppServiceUUID;
	NSArray								*deviceArray;
   
   NSLog( @"Attempting to connect" );
	
   // The device selector will provide UI to the end user to find a remote device
   deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
	
	if ( deviceSelector == nil ) {
		NSLog( @"Error - unable to allocate IOBluetoothDeviceSelectorController.\n" );
		return FALSE;
	}
	sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
	[deviceSelector addAllowedUUID:sppServiceUUID];
	if ( [deviceSelector runModal] != kIOBluetoothUISuccess ) {
		NSLog( @"User has cancelled the device selection.\n" );
		return FALSE;
	}	
	deviceArray = [deviceSelector getResults];	
	if ( ( deviceArray == nil ) || ( [deviceArray count] == 0 ) ) {
		NSLog( @"Error - no selected device.  ***This should never happen.***\n" );
		return FALSE;
	}
	IOBluetoothDevice *device = [deviceArray objectAtIndex:0];
	IOBluetoothSDPServiceRecord	*sppServiceRecord = [device getServiceRecordForUUID:sppServiceUUID];
	if ( sppServiceRecord == nil ) {
		NSLog( @"Error - no spp service in selected device.  ***This should never happen since the selector forces the user to select only devices with spp.***\n" );
		return FALSE;
	}
	// To connect we need a device to connect and an RFCOMM channel ID to open on the device:
	UInt8	rfcommChannelID;
	if ( [sppServiceRecord getRFCOMMChannelID:&rfcommChannelID] != kIOReturnSuccess ) {
		NSLog( @"Error - no spp service in selected device.  ***This should never happen an spp service must have an rfcomm channel id.***\n" );
		return FALSE;
	}
	
	// Open asyncronously the rfcomm channel when all the open sequence is completed my implementation of "rfcommChannelOpenComplete:" will be called.
	if ( ( [device openRFCOMMChannelAsync:&mRFCOMMChannel withChannelID:rfcommChannelID delegate:self] != kIOReturnSuccess ) && ( mRFCOMMChannel != nil ) ) {
		// Something went bad (looking at the error codes I can also say what, but for the moment let's not dwell on
		// those details). If the device connection is left open close it and return an error:
		NSLog( @"Error - open sequence failed.***\n" );
		[self close:device];
		return FALSE;
	}
	
	mBluetoothDevice = device;
	[mBluetoothDevice  retain];
	[mRFCOMMChannel retain];
	return TRUE;
}


- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel *)rfcommChannel
{
	[self performSelector:@selector(close:) withObject:mBluetoothDevice afterDelay:1.0];
//   [self stopAllTimers];
   [appDelegate NXTClosed:self];
}

- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error
{
   connected = YES;
   
   [appDelegate NXTDiscovered:self];
   
	if ( error != kIOReturnSuccess ) {
		NSLog(@"Error - failed to open the RFCOMM channel with error %08lx.\n", (UInt32)error);
      if ([appDelegate respondsToSelector:@selector(NXTCommunicationError:code:)])
         [appDelegate NXTCommunicationError:self code:error];
		[self rfcommChannelClosed:rfcommChannel];
		return;
	}
}

//Forward the reply to any connected clients, and parse it locally incase its something the server needs to know about
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{   
//   [self dumpMessage:dataPointer length:dataLength prefix:@"<- "];

   [appDelegate.relay sendMessageToClient:dataPointer length:dataLength];
   [self parseMessage:dataPointer length:dataLength];
}

#pragma mark -
#pragma mark Message Parser

//Local parser, only handles a few command types, as needed by the server
-(void)parseMessage:(void*)message length:(int)length{
   int i = 0;
   
   //   [self dumpMessage:message length:length prefix:@"<- "];
   
   while ( i < length )
   {
      UInt16 messageLength = 0;
      UInt8  opCode = 0;
      UInt8 status = 0;
      
      // get the command length
      memcpy(&messageLength, message+i, 2);
      messageLength = OSSwapLittleToHostInt16(length);
      i += 2;
      
      // read the opcode and status
      memcpy(&opCode, message+i+1, 1);
      memcpy(&status, message+i+2, 1);
      i += 3;
		
      // report error status
      if ( status != kNXTSuccess && [appDelegate respondsToSelector:@selector(NXTOperationError:operation:status:)] ){
         [appDelegate NXTOperationError:self operation:opCode status:status];
         i += messageLength;
      }
      else
      {
         if ( opCode == kNXTGetBatteryLevel )
         {
            UInt16 batteryLevel;
            
            memcpy(&batteryLevel, message+i+0, 2); // 3
            i += 2;
            
            batteryLevel = OSSwapLittleToHostInt16(batteryLevel);
            
            if ( [appDelegate respondsToSelector:@selector(NXTBatteryLevel:batteryLevel:)] )
               [appDelegate NXTBatteryLevel:self batteryLevel:batteryLevel];
         }
         else if(opCode == kNXT_SYS_CLOSE){
            NSLog(@"File closed, moving on");
            i+= 2;
         }
         else if(opCode == kNXT_SYS_DELETE){
            NSLog(@"File deleted");
            i+=20;
         }         
         else if(opCode == kNXT_SYS_OPEN_READ){
            NSLog(@"File Opened properly");
            i+=5;
         }
         //if the reply is one the server doesn't need to know about, just skip ahead in the buffer
         else{
            i += messageLength;
         }
      }
   }   
}

#pragma mark -
#pragma mark NXT Command methods

- (void)doKeepAlivePoll:(NSTimer*)theTimer
{
   [self keepAlive];
}

- (void)keepAlive
{
   char message[] = {
      kNXTNoRet,
      kNXTKeepAlive
   };
   
   // send the message
   [self formatAndSendMessage:message length:2];
}

- (void)pollKeepAlive
{
   if ( keepAliveTimer == nil )
      self.keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                         target:self
                                                       selector:@selector(doKeepAlivePoll:)
                                                       userInfo:nil
                                                        repeats:YES];
}

-(void)stopKeepAlive
{
   [keepAliveTimer invalidate];
   [keepAliveTimer release];
   keepAliveTimer = nil;
}

@end