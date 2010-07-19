//
//  NXTFileController.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 6/19/10.
//

#import "NXTFileController.h"
#import "NXTConnection.h"
#import "NXTController.h"
#import "NXTController+FileCommands.h"
#import "NXTModel.h"
#import "NXTFile.h"

@implementation NXTFileController

@synthesize localDirectory;
@synthesize buildingFileList;
@synthesize nxtListLoaded;

+(NXTFileController*)sharedInstance
{
   static NXTFileController *_sharedInstance = nil;
   if (!_sharedInstance){
      _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
   }
   return _sharedInstance;
}

-(id)init
{
   if (self = [super init]) 
   {
      nxtFileList = [[NSMutableArray alloc] initWithCapacity:15];
      
      nxtRXEFiles = [[NSMutableArray alloc] initWithCapacity:5];
      
      nxtRSOFiles = [[NSMutableArray alloc] initWithCapacity:5];
      
      nxtRICFiles = [[NSMutableArray alloc] initWithCapacity:5];

#ifdef TARGET_OS_IPHONE
      localRXEFiles = [[NSMutableArray alloc] initWithCapacity:5];
      
      localRSOFiles = [[NSMutableArray alloc] initWithCapacity:5];
      
      localRICFiles = [[NSMutableArray alloc] initWithCapacity:5];
      
      localLogFiles = [[NSMutableArray alloc] initWithCapacity:5];
#endif //TARGET_OS_IPHONE

      buildingFileList = NO;
      transferringFile = NO;
      nxtListLoaded = NO;
      
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(connected:) 
                                                   name:kNXTConnectionConnectedNotification
                                                 object:[NXTConnection sharedConnection]];
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(disconnected:) 
                                                   name:kNXTConnectionDisconnectedNotification
                                                 object:[NXTConnection sharedConnection]];
   }
   return self;
}

-(BOOL)managingLocalFiles
{
#ifdef TARGET_OS_IPHONE
   return YES;
#else
   return NO;
#endif
}

-(void)connected:(NSNotification*)note
{
   buildingFileList = NO;
   [self resetNXTFiles];
}
-(void)disconnected:(NSNotification*)note
{
   buildingFileList = NO;
   [self cancelTransfer];
   [self resetNXTFiles];
}

-(void)reloadLocalFiles
{
   [localLogFiles removeAllObjects];
   [localRICFiles removeAllObjects];
   [localRXEFiles removeAllObjects];
   [localRSOFiles removeAllObjects];
   [self generateLocalFileList];
}

-(void)resetNXTFiles
{
   nxtListLoaded = NO;
   [nxtRXEFiles removeAllObjects];
   [nxtRSOFiles removeAllObjects];
   [nxtRICFiles removeAllObjects];
   [nxtFileList removeAllObjects];
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTFileListMajorChangeNotification object:self];
}

-(void)generateLocalFileList
{
   if(![self managingLocalFiles])
      return;
   
   for(NSString *fileName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:localDirectory error:nil]){
      [self newLocalFileName:fileName];
   }
}

-(void)generateFileList
{
   if(!buildingFileList)
   {
      [self resetNXTFiles];
      [self generateFileList:nil isFirstCall:YES];
   }
}
-(void)generateFileList:(NXTFile*)file isFirstCall:(BOOL)firstCall
{
   if(firstCall)
   {
      buildingFileList = YES;
      [[NXTController sharedInstance] getFirstFile:@"*.*"];
   }else{
      [[NXTController sharedInstance] getNextFile:file];
      [self addNXTFile:file];
   }
}
-(void)fileListFinished
{
   buildingFileList = NO;
   nxtListLoaded = YES;
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTFileListFinishedNotification object:self];
}

-(void)setCurrentTransferHandle:(UInt8)handle
{
   [currentTransfer setHandle:handle];
}

-(void)cancelTransfer
{
   if (currentTransfer != nil) {
      transferringFile = NO;
      if([currentTransfer localFile]) {
         [self removeLocalFile:currentTransfer];
      }else {
         [self removeNXTFile:currentTransfer];
      }
      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTFileTransferFailedNotification object:self userInfo:[NSDictionary dictionaryWithObject:[currentTransfer fileName] forKey:kNXTFileNameKey]];
      [currentTransfer release];
      currentTransfer = nil;
   }
}

-(void)downloadFile:(NXTFile*)file localPath:(NSString*)localPath
{
   if(transferringFile)
      return;

   transferringFile = YES;
   
   [[NXTController sharedInstance] openFile:file mode:kNXTRead];
   
   currentTransfer = [[NXTFile alloc] initWithHandle:0 
                                            fileName:[file fileName] 
                                                size:[file fileSize]
                                      isTransferring:YES
                                             isLocal:YES];
   [currentTransfer setInBuffer:[NSMutableData dataWithCapacity:[file fileSize]]];
   [currentTransfer setLocalFilePath:localPath];
   [self addLocalFile:currentTransfer];
}
-(void)downloadFileError:(BOOL)error data:(NSData*)data
{
   if (error) 
   {
      //reset transfer states and inform the UI
      [self cancelTransfer];
      return;
   }
   
   if([data length] != 0)
   {
      [[currentTransfer inBuffer] appendData:data];
      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTFileTransferUpdatedNotification object:self];
      currentTransfer.amountTransferred += data.length;
   }
   
   if(currentTransfer.fileSize - currentTransfer.amountTransferred > MAX_READ_BYTES)
   {
      //NSLog(@"downloading full packet");
      [[NXTController sharedInstance] readBytes:MAX_READ_BYTES fromFile:currentTransfer];
   }
   else if(currentTransfer.amountTransferred < currentTransfer.fileSize)
   {
      //NSLog(@"downloading last packet");
      [[NXTController sharedInstance] readBytes:currentTransfer.fileSize - currentTransfer.amountTransferred fromFile:currentTransfer];
   }
   else
   {
      NSLog(@"Writing out and closing out files");
      
      if(![[currentTransfer inBuffer] writeToFile:[currentTransfer localFilePath] atomically:YES])
      {
         NSLog(@"Error in writing the file");
         [[NSNotificationCenter defaultCenter] postNotificationName:kNXTFileTransferFailedNotification object:self userInfo:[NSDictionary dictionaryWithObject:[currentTransfer fileName] forKey:kNXTFileNameKey]];
         [self removeLocalFile:currentTransfer];
         [currentTransfer release];
         currentTransfer = nil;
      }
      
      [[NXTController sharedInstance] closeFile:currentTransfer];
      
      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTFileTransferCompleteNotification 
                                                          object:self];
      currentTransfer.transferring = NO;
      transferringFile = NO;
      [currentTransfer release];
      currentTransfer = nil;
   }
}

-(void)uploadFile:(NSString*)localPath
{
   if(transferringFile)
      return;
   
   transferringFile = YES;
   NSData *dataBuffer = [NSData dataWithContentsOfFile:localPath];
   if(dataBuffer.length < [[NXTModel sharedInstance] freeFlash])
   {         
      currentTransfer = [[NXTFile alloc] initWithHandle:0 
                                               fileName:[[localPath pathComponents] lastObject] 
                                                   size:dataBuffer.length
                                         isTransferring:YES
                                                isLocal:NO];
      
      
      if([[localPath pathExtension] isEqualToString:@"rxe"] || [[localPath pathExtension] isEqualToString:@"ric"])
         [[NXTController sharedInstance] openFile:currentTransfer mode:kNXTWriteLinear];
      else
         [[NXTController sharedInstance] openFile:currentTransfer mode:kNXTWrite];
      
      [currentTransfer setOutBuffer:dataBuffer];
      [currentTransfer setLocalFilePath:localPath];
      [self addNXTFile:currentTransfer];      
   }
}

-(void)uploadFileWasError:(BOOL)error amountUploaded:(UInt16)amount
{
   if (error) 
   {
      //reset transfer states and inform the UI
      [self cancelTransfer];
      return;
   }
   
   if(amount != 0){
      currentTransfer.amountTransferred += amount;
      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTFileTransferUpdatedNotification object:self];
   }
   
   if(currentTransfer.fileSize - currentTransfer.amountTransferred > MAX_WRITE_BYTES )
   {
      NSRange range = {currentTransfer.amountTransferred, MAX_WRITE_BYTES};
      [[NXTController sharedInstance] writeData:[[currentTransfer outBuffer] subdataWithRange:range] toFile:currentTransfer];
   }
   else if(currentTransfer.amountTransferred < currentTransfer.fileSize)
   {
      NSRange range = {currentTransfer.amountTransferred, (currentTransfer.fileSize - currentTransfer.amountTransferred)};
      [[NXTController sharedInstance] writeData:[[currentTransfer outBuffer] subdataWithRange:range] toFile:currentTransfer];
   }
   else
   {
      NSLog(@"File Uploaded succesfully");
      [[NXTController sharedInstance] closeFile:currentTransfer];
      currentTransfer.transferring = NO;
      transferringFile = NO;
      
      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTFileTransferCompleteNotification object:self];
      
      [currentTransfer release];
      currentTransfer = nil;
   }
}

-(void)newLocalFileName:(NSString*)fileName
{
   if (![self managingLocalFiles])
      return;
   
   NXTFile *newFile = [[NXTFile alloc] initWithHandle:0 
                                    fileName:fileName
                                        size:[[[[NSFileManager defaultManager] attributesOfItemAtPath:[localDirectory stringByAppendingPathComponent:fileName] 
                                                                                                error:nil] objectForKey:@"NSFileSize"] intValue]
                              isTransferring:NO 
                                     isLocal:YES];
   [newFile setLocalFilePath:[localDirectory stringByAppendingPathComponent:fileName]];
   [self addLocalFile:newFile];
   [newFile release];
}

-(void)addLocalFile:(NXTFile*)file
{
   if(![self managingLocalFiles])
      return;

   int section = -1;
   int row = -1;
   if([@"rxe" isEqualToString:[[file fileName] pathExtension]]){
      [localRXEFiles addObject:file];
      section = 0;
      row = [localRXEFiles count] - 1;
   }
   if([@"rso" isEqualToString:[[file fileName] pathExtension]]){
      [localRSOFiles addObject:file];
      section = 1;
      row = [localRSOFiles count] - 1;
   }
   if([@"ric" isEqualToString:[[file fileName] pathExtension]]){
      [localRICFiles addObject:file];
      section = 2;
      row = [localRICFiles count] - 1;
   }
   if([@"nxtlog" isEqualToString:[[file fileName] pathExtension]]){
      [localLogFiles addObject:file];
      section = 3;
      row = [localLogFiles count] - 1;
   }
   
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTNewLocalFileNotification 
                                                       object:self
                                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:section], kNXTFileSectionKey, 
                                                               [NSNumber numberWithInt:row], kNXTFileRowKey, nil]];
}

-(void)removeLocalFile:(NXTFile*)file
{
   if(![self managingLocalFiles])
      return;

   int row = -1;
   int section = -1;
   if([localRXEFiles containsObject:file]){
      row = [localRXEFiles indexOfObject:file];
      section = 0;
      [localRXEFiles removeObject:file];
   }else if([localRSOFiles containsObject:file]){
      row = [localRSOFiles indexOfObject:file];
      section = 1;
      [localRSOFiles removeObject:file];
   }else if ([localRICFiles containsObject:file]) {
      row = [localRICFiles indexOfObject:file];
      section = 2;
      [localRICFiles removeObject:file];
   }else if ([localLogFiles containsObject:file]) {
      row = [localLogFiles indexOfObject:file];
      section = 3;
      [localLogFiles removeObject:file];
   }
   
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTDeletedLocalFileNotification
                                                       object:self
                                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:section], kNXTFileSectionKey, 
                                                               [NSNumber numberWithInt:row], kNXTFileRowKey, nil]];
}

-(void)addNXTFile:(NXTFile*)file
{
   int section = -1;
   int row = -1;
   if([@"rxe" isEqualToString:[[file fileName] pathExtension]]){
      [nxtRXEFiles addObject:file];
      section = 0;
      row = [nxtRXEFiles count] - 1;
   }
   if([@"rso" isEqualToString:[[file fileName] pathExtension]]){
      [nxtRSOFiles addObject:file];
      section = 1;
      row = [nxtRSOFiles count] - 1;
   }
   if([@"ric" isEqualToString:[[file fileName] pathExtension]]){
      [nxtRICFiles addObject:file];
      section = 2;
      row = [nxtRICFiles count] - 1;
   }
   [nxtFileList addObject:file];
   
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTNewNXTFileNotification 
                                                       object:self
                                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:section], kNXTFileSectionKey, 
                                                                                                         [NSNumber numberWithInt:row], kNXTFileRowKey, nil]];
}

-(void)removeNXTFile:(NXTFile*)file
{
   [nxtFileList removeObject:file];
   int row = -1;
   int section = -1;
   if([nxtRXEFiles containsObject:file]){
      row = [nxtRXEFiles indexOfObject:file];
      section = 0;
      [nxtRXEFiles removeObject:file];
   }else if([nxtRSOFiles containsObject:file]){
      row = [nxtRSOFiles indexOfObject:file];
      section = 1;
      [nxtRSOFiles removeObject:file];
   }else if ([nxtRICFiles containsObject:file]) {
      row = [nxtRICFiles indexOfObject:file];
      section = 2;
      [nxtRICFiles removeObject:file];
   }
   
   [[NSNotificationCenter defaultCenter] postNotificationName:kNXTDeletedNXTFileNotification
                                                       object:self
                                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:section], kNXTFileSectionKey, 
                                                               [NSNumber numberWithInt:row], kNXTFileRowKey, nil]];
}

-(NSArray*)arrayForNXTSection:(int)section
{
   switch (section) {
      case 0:
         return [[nxtRXEFiles copy] autorelease];
         break;
      case 1:
         return [[nxtRSOFiles copy] autorelease];
         break;
      case 2:
         return [[nxtRICFiles copy] autorelease];
         break;
      default:
         NSLog(@"This error should never happen! Returning nil array for invalid section");
         return nil;
         break;
   }
}

-(NSArray*)arrayForLocalSection:(int)section
{
   if(![self managingLocalFiles])
      return nil;
   
   switch (section) {
      case 0:
         return [[localRXEFiles copy] autorelease];
         break;
      case 1:
         return [[localRSOFiles copy] autorelease];
         break;
      case 2:
         return [[localRICFiles copy] autorelease];
         break;
      case 3:
         return [[localLogFiles copy] autorelease];
         break;
      default:
         NSLog(@"This error should never happen! Returning nil array for invalid section");
         return nil;
         break;
   }
}

-(void)deleteLocalFile:(NXTFile*)file
{
   [self removeLocalFile:file];
   [[NSFileManager defaultManager] removeItemAtPath:[file localFilePath] error:nil];
}

-(void)deleteNXTFile:(NXTFile*)file
{
   [[NXTController sharedInstance] deleteFile:file];
   [self removeNXTFile:file];
}

@end
