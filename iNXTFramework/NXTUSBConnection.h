//
//  NXTUSBConnection.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NXTConnection.h"

#import <IOKit/IOKitLib.h>
#import <IOKit/IOMessage.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>

#define USE_ASYNC_IO
#define kLegoVendorID        1684    //Vendor ID of the USB device
#define kLegoProductID       2    //Product ID of device AFTER it is

@class NXTUSBConnection;

typedef struct MyPrivateData {
   io_object_t             notification;
   IOUSBDeviceInterface    **deviceInterface;
   CFStringRef             deviceName;
   UInt32                  locationID;
   NXTUSBConnection        *connection;
} MyPrivateData;

@interface NXTUSBConnection : NXTConnection {
   int inPipeRef;
   int outPipeRef;
   //Global variables
   IOUSBInterfaceInterface **theInterface;
}
@property (nonatomic) IOUSBInterfaceInterface **theInterface;

-(void)usbConnected:(IOUSBInterfaceInterface**)interface;
-(void)usbDisconnected;

-(IOReturn)configureDevice:(IOUSBDeviceInterface**)device;
-(IOReturn)findInterfaces:(IOUSBDeviceInterface**)device;

-(void)writeCompletion:(IOReturn)result argument:(void*)arg0;
-(void)readCompletion:(IOReturn)result argument:(void*)arg0;

void DeviceAdded(void *refCon, io_iterator_t iterator);
void DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument);
void WriteCompletion(void *refCon, IOReturn result, void *arg0);
void ReadCompletion(void *refCon, IOReturn result, void *arg0);

@end
