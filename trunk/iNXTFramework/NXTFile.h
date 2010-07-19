//
//  NXTFile.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 6/19/10.
//

#import <Foundation/Foundation.h>


@interface NXTFile : NSObject
{
   NSString *fileName;
   NSString *localFilePath;
   UInt8 handle;
   UInt32 fileSize;
   BOOL transferring;
   BOOL localFile;
   
   UInt32 amountTransferred;
   
   NSData *outBuffer;
   NSMutableData *inBuffer;
}
@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, retain) NSString *localFilePath;
@property (nonatomic) UInt8 handle;
@property (nonatomic) UInt32 fileSize;
@property (nonatomic) BOOL transferring;
@property (nonatomic) BOOL localFile;
@property (nonatomic) UInt32 amountTransferred;
@property (nonatomic, retain) NSData *outBuffer;
@property (nonatomic, retain) NSMutableData *inBuffer;
-(id)initWithHandle:(UInt8) handle fileName:(NSString*)name size:(UInt32)size isTransferring:(BOOL)transfer isLocal:(BOOL)local;
@end
