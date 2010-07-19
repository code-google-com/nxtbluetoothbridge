//
//  NXTController+SensorCommands.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/26/10.
//

#import <Foundation/Foundation.h>
#import "NXTController.h"


@interface NXTController (SensorCommands)

-(void)getInputValues:(UInt8)port;
-(void)setInputMode:(UInt8)port type:(UInt8)type mode:(UInt8)mode;
-(void)resetInputScaledValue:(UInt8)port;
-(void)invalidateSensorTimer:(UInt8)port;

-(void)getUltrasoundByte:(UInt8)port byte:(UInt8)byte;
-(void)pollSensor:(UInt8)port interval:(NSTimeInterval)seconds;
-(void)pollUltrasoundSensor:(UInt8)port interval:(NSTimeInterval)seconds;

#pragma mark -
#pragma mark LS Methods
/*! Get Low-Speed Buffer Status.
 * Use this to determine if the LS device has data to send.  When requesting data with LSWrite, use this
 * method to determine when the data is ready.  This often results in a kNXTPendingCommunication error
 * status, which only means the data is not yet ready.  
 *
 * The easiest way to work with this method is to call LSRead within the delegate's NXTLSGetStatus
 * method.  To call LSGetStatus in loop when data is not ready, catch kNXTPendingCommunication in
 * delegate's NXTOperationError method and re-call LSGetStatus.
 */
- (void)LSGetStatus:(UInt8)port;

/*! Write Data to Low-Speed Device.
 * Writes data to the LS device.  Data length is liited to 16 bytes.  This
 * is usually followed by LSGetStatus:()port.
 */
- (void)LSWrite:(UInt8)port txLength:(UInt8)txLength rxLength:(UInt8)rxLength txData:(void*)txData;

/*! Read Data from Low-Speed Device.
 * Reads 16 bytes of 0-padded data from a low-speed device.  This is usually called from the delegate's
 * NXTLSGetStatus method when bytesReady is greater than 0.  Take care to always read data when it is
 * ready, as the buffer on the ultrasound sensor will overflow, resulting in a garbled message.
 */
-(void)LSRead:(UInt8)port;
-(void)pushLsGetStatusQueue:(UInt8)port;
-(UInt8)popLsGetStatusQueue;
-(void)pushLsReadQueue:(UInt8)port;
-(UInt8)popLsReadQueue;
-(void)clearPortQueues;

#pragma mark -
#pragma mark Parser methods

-(void)parseInputValues:(NSData*)message;
-(void)parseLSGetStatus:(NSData*)message;
-(void)parseLSRead:(NSData*)message;

@end
