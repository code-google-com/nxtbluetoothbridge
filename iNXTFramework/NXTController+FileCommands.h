//
//  NXTController+FileComands.h
//  iNXT-Remote
//
//  Created by Daniel Siemer on 3/2/10.
//

#import <Foundation/Foundation.h>
#import "NXTController.h"


@interface NXTController (FileCommands)

-(void)startProgram:(NSString*)program;
-(void)stopProgram;
-(void)getCurrentProgramName;

-(void)getFirstFile:(NSString*)wildCard;
-(void)getNextFile:(NXTFile*)previous;

-(void)deleteFile:(NXTFile*)file;
-(void)closeFile:(NXTFile*)file;

-(void)openFile:(NXTFile*)file mode:(char)mode;
-(void)openRead:(NXTFile*)file;
-(void)openWrite:(NXTFile*)file type:(char)type;

-(void)readBytes:(UInt16)bytes fromFile:(NXTFile*)file;
-(void)writeData:(NSData*)dataToSend toFile:(NXTFile*)file;

#pragma mark -
#pragma mark Return Parser Methods

-(void)parseSysFindFirstFile:(NSData*)message;
-(void)parseSysFindNextFile:(NSData*)message;
-(void)parseSysFileClose:(NSData*)message;
-(void)parseSysFileOpenRead:(NSData*)message;
-(void)parseSysFileOpenWrite:(NSData*)message;
-(void)parseSysFileOpenWriteLinear:(NSData*)message;
-(void)parseSysFileOpenWriteData:(NSData*)message;
-(void)parseSysFileDeleted:(NSData*)message;
-(void)parseSysFileRead:(NSData*)message;
-(void)parseSysFileWrite:(NSData*)message;

@end
