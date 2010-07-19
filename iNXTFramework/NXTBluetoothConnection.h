//
//  NXTBluetoothConnection.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "NXTConnection.h"

@class IOBluetoothDevice;
@class IOBluetoothRFCOMMChannel;

@interface NXTBluetoothConnection : NXTConnection 
{
   IOBluetoothDevice *mBluetoothDevice;
	IOBluetoothRFCOMMChannel *mRFCOMMChannel;
}
- (void)close:(IOBluetoothDevice*)device;

@end
