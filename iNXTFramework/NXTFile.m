//
//  NXTFile.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 6/19/10.
//

#import "NXTFile.h"


@implementation NXTFile

@synthesize fileName;
@synthesize localFilePath;
@synthesize handle;
@synthesize fileSize;
@synthesize transferring;
@synthesize localFile;
@synthesize amountTransferred;
@synthesize inBuffer;
@synthesize outBuffer;

-(id)initWithHandle:(UInt8)newHandle fileName:(NSString*)name size:(UInt32)size isTransferring:(BOOL)transfer isLocal:(BOOL)local{
   self.fileName = name;
   self.handle = newHandle;
   self.fileSize = size;
   self.transferring = transfer;
   self.localFile = local;
   return self;
}

-(BOOL)isEqual:(id)anObject
{
   if([anObject isMemberOfClass:[self class]])
   {
      NXTFile *aFile = (NXTFile*)anObject;
      return [fileName isEqualToString:aFile.fileName];
      
   }
   else return NO;
}

-(NSUInteger)hash
{
   return [self.fileName hash];
}

@end
