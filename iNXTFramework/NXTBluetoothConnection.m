//
//  NXTBluetoothConnection.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NXTBluetoothConnection.h"
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>
#import "NXTConnection.h"


@implementation NXTBluetoothConnection

-(void)sendMessage:(NSData *)dataToSend
{
   [mRFCOMMChannel writeSync:(void*)dataToSend.bytes length:dataToSend.length];
}

-(void)connect
{
   IOBluetoothDeviceSelectorController	*deviceSelector;
	IOBluetoothSDPUUID					*sppServiceUUID;
	NSArray								*deviceArray;
   
   NSLog( @"Attempting to connect" );
	
   // The device selector will provide UI to the end user to find a remote device
   deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
	
	if ( deviceSelector == nil ) {
		NSLog( @"Error - unable to allocate IOBluetoothDeviceSelectorController.\n" );
		return;
	}
	sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
	[deviceSelector addAllowedUUID:sppServiceUUID];
	if ( [deviceSelector runModal] != kIOBluetoothUISuccess ) {
		NSLog( @"User has cancelled the device selection.\n" );
		return;
	}	
	deviceArray = [deviceSelector getResults];	
	if ( ( deviceArray == nil ) || ( [deviceArray count] == 0 ) ) {
		NSLog( @"Error - no selected device.  ***This should never happen.***\n" );
		return;
	}
	IOBluetoothDevice *device = [deviceArray objectAtIndex:0];
	IOBluetoothSDPServiceRecord	*sppServiceRecord = [device getServiceRecordForUUID:sppServiceUUID];
	if ( sppServiceRecord == nil ) {
		NSLog( @"Error - no spp service in selected device.  ***This should never happen since the selector forces the user to select only devices with spp.***\n" );
		return;
	}
	// To connect we need a device to connect and an RFCOMM channel ID to open on the device:
	UInt8	rfcommChannelID;
	if ( [sppServiceRecord getRFCOMMChannelID:&rfcommChannelID] != kIOReturnSuccess ) {
		NSLog( @"Error - no spp service in selected device.  ***This should never happen an spp service must have an rfcomm channel id.***\n" );
		return;
	}
	
	// Open asyncronously the rfcomm channel when all the open sequence is completed my implementation of "rfcommChannelOpenComplete:" will be called.
	if ( ( [device openRFCOMMChannelAsync:&mRFCOMMChannel withChannelID:rfcommChannelID delegate:self] != kIOReturnSuccess ) && ( mRFCOMMChannel != nil ) ) {
		// Something went bad (looking at the error codes I can also say what, but for the moment let's not dwell on
		// those details). If the device connection is left open close it and return an error:
		NSLog( @"Error - open sequence failed.***\n" );
		[self close:device];
		return;
	}
	
	mBluetoothDevice = device;
	[mBluetoothDevice  retain];
	[mRFCOMMChannel retain];
}

-(void)stopConnection
{
   [self close:mBluetoothDevice];
}

- (void)close:(IOBluetoothDevice*)device
{
   
   connected = NO;
   
   if ( mBluetoothDevice == device )
   {
      IOReturn error = [mBluetoothDevice closeConnection];
      if ( error != kIOReturnSuccess )
      {
         NSLog(@"Error - failed to close the device connection with error %08lx.\n", (unsigned long)error);
      }
      
      [mBluetoothDevice release];
   }
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel *)rfcommChannel
{
	[self performSelector:@selector(close:) withObject:mBluetoothDevice afterDelay:1.0];
   [self didDisconnect];
}

- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error
{
   connected = YES;
   
   
	if ( error != kIOReturnSuccess ) {
		NSLog(@"Error - failed to open the RFCOMM channel with error %08lx.\n", (unsigned long)error);
		[self rfcommChannelClosed:rfcommChannel];
		return;
	}
   
   [self didConnect];
}

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{   
   [self didRecieveData:dataPointer length:dataLength];
}

@end
