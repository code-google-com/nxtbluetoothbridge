//
//  NXTController+FileComands.m
//  iNXT-Remote
//
//  Created by Daniel Siemer on 3/2/10.
//

#import "NXTController+FileCommands.h"
#import "NXTModel.h"
#import "NXTNetConnection.h"
#import "NXTFile.h"
#import "unistd.h"
#import "NXTFileController.h"

@implementation NXTController (FileCommands)

- (void)startProgram:(NSString*)program
{
   [self stopProgram];
   sleep(1);
   char message[22] = {
      [self doReturn],
      kNXTStartProgram
   };
   
   [program getCString:(message+2) maxLength:20 encoding:NSASCIIStringEncoding];
   message[21] = '\0';
   
   // send the message
   [self sendMessage:message length:22];
}


- (void)stopProgram
{
   // construct the message
   char message[] = {
      [self doReturn],
      kNXTStopProgram
   };
   
   // send the message
   [self sendMessage:message length:2];
}

- (void)getCurrentProgramName
{
   char message[] = {
      kNXTRet,
      kNXTGetCurrentProgramName
   };
   
   // send the message
   [self sendMessage:message length:2];
}

-(void)getFirstFile:(NSString*)wildCard
{
   char message[22] = {
      kNXTSysOP,
      kNXT_SYS_FIND_FIRST
   };
   
   [wildCard getCString:(message+2) maxLength:20 encoding:NSASCIIStringEncoding];
   message[21] = '\0';
   
//   NSLog(@"Asking for first file");
// send the message
   [self sendMessage:message length:22];
}

-(void)getNextFile:(NXTFile*)previousFile
{
   char message[3] = {
      kNXTSysOP,
      kNXT_SYS_FIND_NEXT,
      [previousFile handle]
   };
//   NSLog(@"Asking for next file");
   [self sendMessage:message length:3];
}

-(void)deleteFile:(NXTFile*)file{
   char message[22] = {
      kNXTSysOP,
      kNXT_SYS_DELETE
   };
   [file.fileName getCString:(message+2) maxLength:20 encoding:NSASCIIStringEncoding];
   message[21] = '\0';
   [self sendMessage:message length:22];
}

-(void)closeFile:(NXTFile*)file
{
   char message[3] = {
      kNXTSysOP,
      kNXT_SYS_CLOSE,
      file.handle
   };
   
//  NSLog(@"Closing file: %@, at handle: %c", file.fileName, file.handle);
   [self sendMessage:message length:3];
}

-(void)openFile:(NXTFile*)file mode:(char)mode{
   switch (mode) {
      case kNXTRead:
         [self openRead:file];
         break;
      case kNXTWrite:
         [self openWrite:file type:kNXT_SYS_OPEN_WRITE];
         break;
      case kNXTWriteLinear:
         [self openWrite:file type:kNXT_SYS_OPEN_WRITE_LINEAR];
         break;
      case kNXTWriteLinearData:
         [self openWrite:file type:kNXT_SYS_OPEN_WRITE_DATA];
         break;
      default:
         NSLog(@"Invalid file mode");
         file.handle = -1;
         break;
   }
}

-(void)openRead:(NXTFile*)file{
   char message[22] = {
      kNXTSysOP,
      kNXT_SYS_OPEN_READ
   };
   [file.fileName getCString:(message+2) maxLength:20 encoding:NSASCIIStringEncoding];
   message[21] = '\0';
   
   [self sendMessage:message length:22];
}

-(void)openWrite:(NXTFile*)file type:(char)type{
   char message[26] = {
      kNXTSysOP,
      type
   };
   [file.fileName getCString:(message+2) maxLength:20 encoding:NSASCIIStringEncoding];
   message[21] = '\0';
   message[22] = file.fileSize & 0xff;
   message[23] = (file.fileSize >> 8 ) & 0xff;
   message[24] = (file.fileSize >> 16) & 0xff;
   message[25] = (file.fileSize >> 24) & 0xff;
   
   [self sendMessage:message length:26];
}

-(void)readBytes:(UInt16)bytes fromFile:(NXTFile*)file{
   char message [5] = {
      kNXTSysOP,
      kNXT_SYS_READ,
      file.handle,
      (bytes & 0x00ff),
      (bytes & 0xff00) >> 8,
   };
   [self sendMessage:message length:5];
}

-(void)writeData:(NSData*)dataToSend toFile:(NXTFile*)file {
   if(dataToSend.length <= MAX_WRITE_BYTES){
//      NSLog(@"Writing %d bytes", dataToSend.length);
      char message[64] = {
         kNXTSysOP,
         kNXT_SYS_WRITE,
         file.handle
      };
      memcpy(message + 3, dataToSend.bytes, dataToSend.length);
      [self sendMessage:message length:3 + dataToSend.length];
   }else{
      NSLog(@"Packet Size too large.");
   }
}

#pragma mark -
#pragma mark Return Parser Methods

-(void)parseSysFindFirstFile:(NSData*)message
{
   char cFileName[20];
   UInt8 handle;
   UInt32 size;
   memcpy(&handle, message.bytes+5,  1);
   memcpy(cFileName, message.bytes+6, 20);
   memcpy(&size, message.bytes+26, 4);
   
   NSString *fileName = [NSString stringWithCString:cFileName encoding:NSASCIIStringEncoding];
   size = OSSwapLittleToHostInt32(size);
   NXTFile *temp = [[NXTFile alloc] initWithHandle:handle 
                                          fileName:fileName 
                                              size:size
                                    isTransferring:NO
                                           isLocal:NO];
   //NSLog(@"FileName: %@, Handle: %d, Size:%d", fileName, handle, size);
   [[NXTFileController sharedInstance] generateFileList:temp isFirstCall:NO];
   
   [temp release];
}

-(void)parseSysFindNextFile:(NSData*)message
{
   char cFileName[20];
   UInt8 handle;
   UInt32 size;
   memcpy(&handle, message.bytes+5,  1);
   memcpy(cFileName, message.bytes+6, 20);
   memcpy(&size, message.bytes+26, 4);
   
   NSString *fileName = [NSString stringWithCString:cFileName encoding:NSASCIIStringEncoding];
   size = OSSwapLittleToHostInt32(size);
   //            NSLog(@"FileName: %@, Handle: %d, Size:%d", fileName, handle, size);
   
   NXTFile *temp = [[NXTFile alloc] initWithHandle:handle 
                                          fileName:fileName
                                              size:size
                                    isTransferring:NO
                                           isLocal:NO];
   [[NXTFileController sharedInstance] generateFileList:temp isFirstCall:NO];
   
   [temp release];
}

-(void)parseSysFileClose:(NSData*)message
{
   //If we needed to handle this down the road, this is where it would go
}

-(void)parseSysFileOpenRead:(NSData*)message
{
   NSLog(@"File Opened properly");
   UInt8 handle;
   UInt32 size;
   memcpy(&handle, message.bytes+5,  1);
   memcpy(&size, message.bytes+6, 4);
   size = OSSwapLittleToHostInt32(size);
   
   [[NXTFileController sharedInstance] setCurrentTransferHandle:handle];
   [[NXTFileController sharedInstance] downloadFileError:NO data:nil];
}

-(void)parseSysFileOpenWrite:(NSData*)message
{
   UInt8 handle;
   memcpy(&handle, message.bytes+5,  1);
   
   [[NXTFileController sharedInstance] setCurrentTransferHandle:handle];
   [[NXTFileController sharedInstance] uploadFileWasError:NO amountUploaded:0];
}

-(void)parseSysFileOpenWriteLinear:(NSData*)message
{
   UInt8 handle;
   memcpy(&handle, message.bytes+5,  1);
   
   [[NXTFileController sharedInstance] setCurrentTransferHandle:handle];
   [[NXTFileController sharedInstance] uploadFileWasError:NO amountUploaded:0];
}

-(void)parseSysFileOpenWriteData:(NSData*)message
{
   UInt8 handle;
   memcpy(&handle, message.bytes+5,  1);
   
   [[NXTFileController sharedInstance] setCurrentTransferHandle:handle];
   [[NXTFileController sharedInstance] uploadFileWasError:NO amountUploaded:0];
}

-(void)parseSysFileDeleted:(NSData*)message
{
   char cFileName[20];
   memcpy(cFileName, message.bytes+5, 20);
   
   NSString *fileName = [[NSString alloc] initWithCString:cFileName encoding:NSASCIIStringEncoding];
   NSLog(@"File: %@ deleted", fileName);
   [fileName release];
}

-(void)parseSysFileRead:(NSData*)message
{
   UInt16 readBytes;
   memcpy(&readBytes, message.bytes+6,  2);
   readBytes = OSSwapLittleToHostInt16(readBytes);
   
   NSData *dataPacket = [[NSData alloc] initWithBytes:message.bytes+8 length:readBytes];
   
   [[NXTFileController sharedInstance] downloadFileError:NO data:dataPacket];
   [dataPacket release];
}

-(void)parseSysFileWrite:(NSData*)message
{
   UInt16 wroteBytes;
   memcpy(&wroteBytes, message.bytes+6,  2);
   
   wroteBytes = OSSwapLittleToHostInt16(wroteBytes);
   [[NXTFileController sharedInstance] uploadFileWasError:NO amountUploaded:wroteBytes];
}

@end
