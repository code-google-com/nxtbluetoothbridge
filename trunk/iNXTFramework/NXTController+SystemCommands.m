//
//  NXTController+SystemCommands.m
//  iNXT-Remote
//
//  Created by Daniel Siemer on 3/2/10.
//

#import "NXTController+SystemCommands.h"
#import "NXTModel.h"


@implementation NXTController (SystemCommands)

-(void)getNXTInfo{
   char message[2] = {
      kNXTSysOP,
      kNXT_SYS_GET_DEVICE_INFO
   };
   [self sendMessage:message length:2];
}

-(void)getNXTFirmware{
   char message[2] = {
      kNXTSysOP,
      kNXT_SYS_GET_FIRMWARE_VERSION
   };
   [self sendMessage:message length:2];
}

-(void)changeNXTName:(NSString*)newNXTName
{
   char message[18] = {
      kNXTSysOP,
      kNXT_SYS_SET_BRICK_NAME
   };
   [newNXTName getCString:(message+2) maxLength:15 encoding:NSASCIIStringEncoding];
   [self sendMessage:message length:18];
   [[NXTModel sharedInstance] setNxtName:newNXTName];
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTInformationUpdateNotification object:self];
}

-(void)pollKeepAlive
{
   if ( keepAliveTimer == nil )
      keepAliveTimer = [[NSTimer scheduledTimerWithTimeInterval:60
                                                         target:self
                                                       selector:@selector(doKeepAlivePoll:)
                                                       userInfo:nil
                                                        repeats:YES] retain];
}

-(void)keepAlive
{
   char message[] = {
      [self doReturn],
      kNXTKeepAlive
   };
   
   // send the message
   [self sendMessage:message length:2];
}

- (void)messageWrite:(UInt8)inbox message:(void*)string size:(int)size
{
   char message[size+4];
   
   message[0] = [self doReturn];
   message[1] = kNXTMessageWrite;
   message[2] = inbox;
   message[3] = size;
   
   memcpy(message+4, string, size);
   
   [self sendMessage:message length:size+4];
}

- (void)messageRead:(UInt8)remoteInbox localInbox:(UInt8)localInbox remove:(BOOL)remove
{
   char message[] = {
      kNXTRet,
      kNXTMessageRead,
      remoteInbox,
      localInbox,
      (remove ? 1 : 0)
   };
   
   [self sendMessage:message length:5];
}

@end
