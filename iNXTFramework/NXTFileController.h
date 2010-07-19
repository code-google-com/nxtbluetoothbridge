//
//  NXTFileController.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 6/19/10.
//

#import <Foundation/Foundation.h>

#define MAX_READ_BYTES 0x003A
#define MAX_WRITE_BYTES 0x3D

#define kNXTNewLocalFileNotification            @"kNXTNewLocalFileNotification"
#define kNXTNewNXTFileNotification              @"kNXTNewNXTFileNotification"
#define kNXTDeletedLocalFileNotification        @"kNXTDeletedLocalFileNotification"
#define kNXTDeletedNXTFileNotification          @"kNXTDeletedNXTFileNotification"

#define kNXTFileTransferFailedNotification      @"kNXTFileTransferFailedNotification"
#define kNXTFileTransferUpdatedNotification     @"kNXTFileTransferUpdatedNotification"
#define kNXTFileTransferCompleteNotification    @"kNXTFileTransferCompleteNotification"

#define kNXTFileListFinishedNotification        @"kNXTFileListFinishedNotification"
#define kNXTFileListMajorChangeNotification     @"kNXTFileListMajorChangeNotification"

#define kNXTFileRowKey                          @"kNXTFileRowKey"
#define kNXTFileSectionKey                      @"kNXTFileSectionKey"

#define kNXTFileNameKey                         @"kNXTFileNameKey"

@class NXTFile;

@interface NXTFileController : NSObject {
   NSMutableArray *nxtFileList;
   NSMutableArray *nxtRXEFiles;
   NSMutableArray *nxtRSOFiles;
   NSMutableArray *nxtRICFiles;

   NSMutableArray *localRXEFiles;
   NSMutableArray *localRSOFiles;
   NSMutableArray *localRICFiles;
   NSMutableArray *localLogFiles;
   
   NSString *localDirectory;
   
   BOOL buildingFileList;
   BOOL nxtListLoaded;
   BOOL transferringFile;
   NXTFile *currentTransfer;
}
@property (nonatomic, retain) NSString *localDirectory;
@property (nonatomic, readonly, getter=isBuildingFileList) BOOL buildingFileList;
@property (nonatomic, readonly, getter=isNXTListLoaded) BOOL nxtListLoaded;

+(NXTFileController*)sharedInstance;

-(BOOL)managingLocalFiles;

-(void)connected:(NSNotification*)note;
-(void)disconnected:(NSNotification*)note;
-(void)reloadLocalFiles;
-(void)resetNXTFiles;

-(void)generateLocalFileList;
-(void)generateFileList;
-(void)generateFileList:(NXTFile*)file isFirstCall:(BOOL)firstCall;
-(void)fileListFinished;

-(void)setCurrentTransferHandle:(UInt8)handle;

-(void)cancelTransfer;

-(void)downloadFile:(NXTFile*)file localPath:(NSString*)localPath;
-(void)downloadFileError:(BOOL)error data:(NSData*)data;

-(void)uploadFile:(NSString*)localPath;
-(void)uploadFileWasError:(BOOL)error amountUploaded:(UInt16)amount;

-(void)newLocalFileName:(NSString *)fileName;
-(void)addLocalFile:(NXTFile*)file;
-(void)removeLocalFile:(NXTFile*)file;
-(void)addNXTFile:(NXTFile*)file;
-(void)removeNXTFile:(NXTFile*)file;

-(NSArray*)arrayForNXTSection:(int)section;
-(NSArray*)arrayForLocalSection:(int)section;

-(void)deleteLocalFile:(NXTFile*)file;
-(void)deleteNXTFile:(NXTFile *)file;

@end
