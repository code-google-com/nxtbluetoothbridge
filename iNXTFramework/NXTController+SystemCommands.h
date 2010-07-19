//
//  NXTController+SystemCommands.h
//  iNXT-Remote
//
//  Created by Daniel Siemer on 3/2/10.
//

#import <Foundation/Foundation.h>
#import "NXTController.h"

@interface NXTController (SystemCommands) 

-(void)getNXTInfo;
-(void)getNXTFirmware;
-(void)changeNXTName:(NSString*)newNXTName;
-(void)pollKeepAlive;
-(void)keepAlive;

-(void)messageWrite:(UInt8)inbox message:(void*)message size:(int)size;
-(void)messageRead:(UInt8)remoteInbox localInbox:(UInt8)localInbox remove:(BOOL)remove;

@end
