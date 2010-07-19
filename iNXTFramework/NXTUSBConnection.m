//
//  NXTUSBConnection.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NXTUSBConnection.h"
#import "NXTModel.h"

static IONotificationPortRef    gNotifyPort;
static io_iterator_t            gAddedIter;
static char                     gBuffer[64];

@implementation NXTUSBConnection
@synthesize theInterface;

-(void)sendMessage:(NSData*)dataToSend
{
   if(!connected){
      return;
   }
   
   IOReturn kr;
   UInt8 length = dataToSend.length;
   
   //Other communications requires this be pre appended, particularly the windows (third party) server
   //As a simplification for the rest of the library, we assume that, and simply recreate the message here
   length -= 2;
   char sent[length];
   memcpy(&sent, dataToSend.bytes+2, length);
      
/*   kr = (*theInterface)->WritePipeAsync(theInterface,
                                        outPipeRef,
                                        sent,
                                        length,
                                        WriteCompletion,
                                        (void *)self);*/
   kr = (*theInterface)->WritePipe(theInterface,
                                   outPipeRef,
                                   sent,
                                   length);
   
   if (kr != kIOReturnSuccess)
   {
      printf("Unable to send message (%08x)\n", kr);
      (void) (*theInterface)->USBInterfaceClose(theInterface);
      (void) (*theInterface)->Release(theInterface);
   }
}

-(void)scheduleRead
{
   if(!connected){
      return;
   }
   IOReturn kr;
   UInt32 numBytesRead;

   //NSLog(@"Queing async read for NXT Return");
   numBytesRead = sizeof(gBuffer);
   bzero(gBuffer, sizeof(gBuffer));
   kr = (*theInterface)->ReadPipeAsync(theInterface,
                                       inPipeRef,
                                       gBuffer,
                                       numBytesRead,
                                       ReadCompletion,
                                       (void*)self);
   if (kr != kIOReturnSuccess)
   {
      printf("Unable to perform asynchronous bulk read (%08x)\n", kr);
      (void) (*theInterface)->USBInterfaceClose(theInterface);
      (void) (*theInterface)->Release(theInterface);
      return;
   }
}

#pragma mark -
#pragma mark USB Methods

-(void)usbConnected:(IOUSBInterfaceInterface**)interface
{
   if(!connected)
   {
      connected = YES;
      theInterface = interface;
      [self didConnect];
   }
}

-(void)usbDisconnected
{
   if(connected){
      connected = NO;
      [self didDisconnect];
   }
}

-(void)connect
{
   mach_port_t             masterPort;
   CFMutableDictionaryRef 	matchingDict;
   CFRunLoopSourceRef		runLoopSource;
   CFNumberRef				numberRef;
   kern_return_t			kr;
   long					usbVendor = kLegoVendorID;
   long					usbProduct = kLegoProductID;
   CFRunLoopRef gRunLoop;
   
   kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
   if (kr || !masterPort)
   {
      printf("ERR: Couldn’t create a master I/O Kit port(%08x)\n", kr);
      return;
   }   
   
   matchingDict = IOServiceMatching(kIOUSBDeviceClassName);	// Interested in instances of class
   // IOUSBDevice and its subclasses
   if (matchingDict == NULL) {
      NSLog(@"IOServiceMatching returned NULL.");
      return;
   }
   
   numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbVendor);
   CFDictionarySetValue(matchingDict, 
                        CFSTR(kUSBVendorID), 
                        numberRef);
   CFRelease(numberRef);
   
   // Create a CFNumber for the idProduct and set the value in the dictionary
   numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbProduct);
   CFDictionarySetValue(matchingDict, 
                        CFSTR(kUSBProductID), 
                        numberRef);
   CFRelease(numberRef);
   numberRef = NULL;
   
   gNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
   runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
   
   gRunLoop = CFRunLoopGetCurrent();
   CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopCommonModes);
   
   kr = IOServiceAddMatchingNotification(gNotifyPort,					// notifyPort
                                         kIOFirstMatchNotification,	// notificationType
                                         matchingDict,					// matching
                                         DeviceAdded,					// callback
                                         (void*)self,							// refCon
                                         &gAddedIter					// notification
                                         );
   if(kr != KERN_SUCCESS)
   {
      NSLog(@"Error makign the service matching notification");
   }
   
   DeviceAdded((void*)self, gAddedIter);
}

-(void)stopConnection
{
   if(connected){
      connected = NO;
      (void) (*theInterface)->USBInterfaceClose(theInterface);
      (void) (*theInterface)->Release(theInterface);
      [self didDisconnect];
   }
}

-(IOReturn)configureDevice:(IOUSBDeviceInterface**)device
{
   UInt8                           numConfig;
   IOReturn                        kr;
   IOUSBConfigurationDescriptorPtr configDesc;
   
   //Get the number of configurations. The sample code always chooses
   //the first configuration (at index 0) but your code may need a
   //different one
   kr = (*device)->GetNumberOfConfigurations(device, &numConfig);
   if (!numConfig)
      return -1;
   
   //Get the configuration descriptor for index 0
   kr = (*device)->GetConfigurationDescriptorPtr(device, 0, &configDesc);
   if (kr)
   {
      printf("Couldn’t get configuration descriptor for index %d (err =%08x)\n", 0, kr);
      return -1;
   }
   
   //Set the device’s configuration. The configuration value is found in
   //the bConfigurationValue field of the configuration descriptor
   kr = (*device)->SetConfiguration(device, configDesc->bConfigurationValue);
   if (kr)
   {
      printf("Couldn’t set configuration to value %d (err = %08x)\n", 0, kr);
      return -1;
   }
   return kIOReturnSuccess;
}

-(IOReturn)findInterfaces:(IOUSBDeviceInterface **)device
{
   if(connected)
      return -1;
   
   IOReturn                    kr;
   IOUSBFindInterfaceRequest   request;
   io_iterator_t               iterator;
   io_service_t                usbInterface;
   IOUSBInterfaceInterface     **interface;
   IOCFPlugInInterface         **plugInInterface = NULL;
   HRESULT                     result;
   SInt32                      score;
   UInt8                       interfaceClass;
   UInt8                       interfaceSubClass;
   UInt8                       interfaceNumEndpoints;
   int                         pipeRef;
   
   
   CFRunLoopSourceRef          runLoopSource;
   
   //Placing the constant kIOUSBFindInterfaceDontCare into the following
   //fields of the IOUSBFindInterfaceRequest structure will allow you
   //to find all the interfaces
   request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
   request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
   request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
   request.bAlternateSetting = kIOUSBFindInterfaceDontCare;
   
   //Get an iterator for the interfaces on the device
   kr = (*device)->CreateInterfaceIterator(device, &request, &iterator);
   while ((usbInterface = IOIteratorNext(iterator)))
   {
      //Create an intermediate plug-in
      kr = IOCreatePlugInInterfaceForService(usbInterface,
                                             kIOUSBInterfaceUserClientTypeID,
                                             kIOCFPlugInInterfaceID,
                                             &plugInInterface, &score);
      //Release the usbInterface object after getting the plug-in
      kr = IOObjectRelease(usbInterface);
      if ((kr != kIOReturnSuccess) || !plugInInterface)
      {
         printf("Unable to create a plug-in (%08x)\n", kr);
         break;
      }
      
      //Now create the device interface for the interface
      result = (*plugInInterface)->QueryInterface(plugInInterface,
                                                  CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                                                  (LPVOID *) &interface);
      //No longer need the intermediate plug-in
      (*plugInInterface)->Release(plugInInterface);
      
      if (result || !interface)
      {
         printf("Couldn’t create a device interface for the interface(%08x)\n", (int) result);
         break;
      }
      
      //Get interface class and subclass
      kr = (*interface)->GetInterfaceClass(interface, &interfaceClass);
      kr = (*interface)->GetInterfaceSubClass(interface, &interfaceSubClass);
      
      printf("Interface class %d, subclass %d\n", interfaceClass, interfaceSubClass);
      
      //Now open the interface. This will cause the pipes associated with
      //the endpoints in the interface descriptor to be instantiated
      kr = (*interface)->USBInterfaceOpen(interface);
      if (kr != kIOReturnSuccess)
      {
         printf("Unable to open interface (%08x)\n", kr);
         (void) (*interface)->Release(interface);
         break;
      }
      
      //Get the number of endpoints associated with this interface
      kr = (*interface)->GetNumEndpoints(interface, &interfaceNumEndpoints);
      if (kr != kIOReturnSuccess)
      {
         printf("Unable to get number of endpoints (%08x)\n", kr);
         (void) (*interface)->USBInterfaceClose(interface);
         (void) (*interface)->Release(interface);
         break;
      }
      
      printf("Interface has %d endpoints\n", interfaceNumEndpoints);
      //Access each pipe in turn, starting with the pipe at index 1
      //The pipe at index 0 is the default control pipe and should be
      //accessed using (*usbDevice)->DeviceRequest() instead
      for (pipeRef = 1; pipeRef <= interfaceNumEndpoints; pipeRef++)
      {
         IOReturn        kr2;
         UInt8           direction;
         UInt8           number;
         UInt8           transferType;
         UInt16          maxPacketSize;
         UInt8           interval;
         
         kr2 = (*interface)->GetPipeProperties(interface,
                                               pipeRef, 
                                               &direction,
                                               &number, 
                                               &transferType,
                                               &maxPacketSize, &interval);
         if (kr2 != kIOReturnSuccess)
            printf("Unable to get properties of pipe %d (%08x)\n",pipeRef, kr2);
         else
         {
            if(direction == kUSBOut && transferType == kUSBBulk){
               outPipeRef = pipeRef;
            }else if(direction == kUSBIn && transferType == kUSBBulk){
               inPipeRef = pipeRef;
            }else{
               NSLog(@"Invalid pipe endpoint");
            }
         }
      }
      
      //Demonstrate asynchronous I/O
      //As with service matching notifications, to receive asynchronous
      //I/O completion notifications, you must create an event source and
      //add it to the run loop
      kr = (*interface)->CreateInterfaceAsyncEventSource(interface, &runLoopSource);
      
      if (kr != kIOReturnSuccess)
      {
         printf("Unable to create asynchronous event source(%08x)\n", kr);
         (void) (*interface)->USBInterfaceClose(interface);
         (void) (*interface)->Release(interface);
         break;
      }
      CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
      printf("Asynchronous event source added to run loop\n");
      
      [self usbConnected:(IOUSBInterfaceInterface**)interface];
      
      //For this test, just use first interface, so exit loop
      break;
   }
   return kr;
}

-(void)writeCompletion:(IOReturn)result argument:(void*)arg0
{
   //UInt32                  numBytesWritten = (UInt32) arg0;
   
   //printf("Asynchronous write complete\n");
   if (result != kIOReturnSuccess)
   {
      NSLog(@"error from asynchronous bulk write (%08x)\n", result);
      (void) (*theInterface)->USBInterfaceClose(theInterface);
      (void) (*theInterface)->Release(theInterface);
      return;
   }
   //printf("Wrote (%ld bytes) to bulk endpoint\n", numBytesWritten);
}

-(void)readCompletion:(IOReturn)result argument:(void*)arg0
{
   size_t numBytesRead = (size_t)arg0;
   
   //NSLog(@"Asynchronous bulk read complete, read %ld bytes\n", numBytesRead);
   if (result != kIOReturnSuccess) {
      NSLog(@"error from async bulk read (%08x)\n", result);
      (void) (*theInterface)->USBInterfaceClose(theInterface);
      (void) (*theInterface)->Release(theInterface);
      return;
   }
      
   char read[numBytesRead+2];
   read[0] = numBytesRead;
   read[1] = 0;
   memcpy(read+2, gBuffer, numBytesRead);
   
   [self didRecieveData:(void*)read length:numBytesRead+2];
}

void DeviceAdded(void *refCon, io_iterator_t iterator)
{
   IOReturn           kr;
   io_service_t            usbDevice;
   IOUSBDeviceInterface    **deviceInterface=NULL;
   IOCFPlugInInterface         **plugInInterface = NULL;
   SInt32                      score;
   UInt16                      vendor;
   UInt16                      product;
   HRESULT                     result;
   
   NXTUSBConnection *connection = [(NXTUSBConnection*)refCon retain];
   
   
   while ((usbDevice = IOIteratorNext(iterator)))
   {
      io_name_t       deviceName;
      CFStringRef     deviceNameAsCFString;   
      UInt32          locationID;
      MyPrivateData   *privateDataRef = NULL;
      
      // Add some app-specific information about this device.
      // Create a buffer to hold the data.
      privateDataRef = malloc(sizeof(MyPrivateData));
      bzero(privateDataRef, sizeof(MyPrivateData));      
      
      privateDataRef->connection = connection;
      
      // Get the USB device's name.
      kr = IORegistryEntryGetName(usbDevice, deviceName);
      if (KERN_SUCCESS != kr) {
         deviceName[0] = '\0';
      }
      
      deviceNameAsCFString = CFStringCreateWithCString(kCFAllocatorDefault, 
                                                       deviceName, 
                                                       kCFStringEncodingASCII);      
      
      // Dump our data to stderr just to see what it looks like.
      NSLog(@"deviceName: %@", deviceNameAsCFString);
      
      //Create an intermediate plug-in using the
      //IOCreatePlugInInterfaceForService function
      kr = IOCreatePlugInInterfaceForService(usbDevice,
                                             kIOUSBDeviceUserClientTypeID, 
                                             kIOCFPlugInInterfaceID,
                                             &plugInInterface, 
                                             &score);
      
      //Release the device object after getting the intermediate plug-in
      //kr = IOObjectRelease(usbDevice);
      if ((kIOReturnSuccess != kr) || !plugInInterface)
      {
         NSLog(@"Unable to create a plug-in (%08x)\n", kr);
         continue;
      }
      //Create the device interface using the QueryInterface function
      result = (*plugInInterface)->QueryInterface(plugInInterface,
                                                  CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                  (LPVOID *)&deviceInterface);
      privateDataRef->deviceInterface = deviceInterface;
      //Release the intermediate plug-in object
      (*plugInInterface)->Release(plugInInterface);
      
      if (result || !deviceInterface)
      {
         NSLog(@"Couldn’t create a device interface (%08x)\n",(int) result);
         continue;
      }
      
      // Now that we have the IOUSBDeviceInterface, we can call the routines in IOUSBLib.h.
      // In this case, fetch the locationID. The locationID uniquely identifies the device
      // and will remain the same, even across reboots, so long as the bus topology doesn't change.      
      
      kr = (*privateDataRef->deviceInterface)->GetLocationID(privateDataRef->deviceInterface, &locationID);
      if (KERN_SUCCESS != kr) {
         NSLog(@"GetLocationID returned 0x%08x.\n", kr);
         continue;
      }
      else {
         NSLog(@"Location ID: 0x%lx\n\n", (unsigned long)locationID);
      }
      
      privateDataRef->locationID = locationID;
      
      //Check the vendor, product, and release number values to
      //confirm we’ve got the right device
      kr = (*deviceInterface)->GetDeviceVendor(deviceInterface, &vendor);
      kr = (*deviceInterface)->GetDeviceProduct(deviceInterface, &product);
      if ((vendor != kLegoVendorID) || (product != kLegoProductID))
      {
         NSLog(@"Found unwanted device (vendor = %d, product = %d)\n",vendor, product);
         (void) (*deviceInterface)->Release(deviceInterface);
         continue;
      }
      
      //Open the device before configuring it
      kr = (*deviceInterface)->USBDeviceOpen(deviceInterface);
      if (kr != kIOReturnSuccess)
      {
         NSLog(@"Unable to open device: %08x\n", kr);
         (void) (*deviceInterface)->Release(deviceInterface);
         continue;
      }
      
      //Configure the device by calling ConfigureDevice
      
      kr = [connection configureDevice:deviceInterface];
      if (kr != kIOReturnSuccess)
      {
         NSLog(@"Unable to configure device: %08x\n", kr);
         (void) (*deviceInterface)->USBDeviceClose(deviceInterface);
         (void) (*deviceInterface)->Release(deviceInterface);
         continue;
      }
      
      
      //Close the device and release the device interface object if
      //the configuration is unsuccessful
      
      //Get the interfaces
      kr = [connection findInterfaces:deviceInterface];
      if (kr != kIOReturnSuccess)
      {
         NSLog(@"Unable to find interfaces on device: %08x\n", kr);
         (*deviceInterface)->USBDeviceClose(deviceInterface);
         (*deviceInterface)->Release(deviceInterface);
         continue;
      }else{
         kr = IOServiceAddInterestNotification(gNotifyPort,                      // notifyPort
                                               usbDevice,                        // service
                                               kIOGeneralInterest,               // interestType
                                               DeviceNotification,               // callback
                                               privateDataRef,                   // refCon
                                               &(privateDataRef->notification)   // notification
                                               );
         
         if (KERN_SUCCESS != kr) {
            NSLog(@"IOServiceAddInterestNotification returned 0x%08x.\n", kr);
         }
      }
      kr = IOObjectRelease(usbDevice);
      if ([connection connected]) {
         break;
      }
   }
   
   // Done with this USB device; release the reference added by IOIteratorNext
   //kr = IOObjectRelease(usbDevice);
   
   [connection release];
}

void DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument)
{
   kern_return_t   kr;
   MyPrivateData   *privateDataRef = (MyPrivateData *) refCon;
   
   NXTUSBConnection *connection = [privateDataRef->connection retain];
   
   if (messageType == kIOMessageServiceIsTerminated) {
      NSLog(@"Device removed.\n");
      
      // Dump our private data to stderr just to see what it looks like.
      NSLog(@"privateDataRef->deviceName: %@", privateDataRef->deviceName);
      NSLog(@"privateDataRef->locationID: 0x%lx.\n\n", (unsigned long)privateDataRef->locationID);
      
      // Free the data we're no longer using now that the device is going away
      //CFRelease(privateDataRef->deviceName);
      
      if (privateDataRef->deviceInterface) {
         kr = (*privateDataRef->deviceInterface)->Release(privateDataRef->deviceInterface);
      }
      
      kr = IOObjectRelease(privateDataRef->notification);
      
      free(privateDataRef);
      
      [connection didDisconnect];
   }
   [connection release];
}

void WriteCompletion(void *refCon, IOReturn result, void *arg0)
{
   NXTUSBConnection *connection = [(NXTUSBConnection*)refCon retain];
   [connection writeCompletion:result argument:arg0];
   [connection release];
}


void ReadCompletion(void *refCon, IOReturn result, void *arg0)
{
   NXTUSBConnection *connection = [(NXTUSBConnection*)refCon retain];
   [connection readCompletion:result argument:arg0];
   [connection release];
}

@end
