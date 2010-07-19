//
//  NXTLogController.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/26/10.
//

#import <Foundation/Foundation.h>

#define kNXTLoggingBeganNotification @"kNXTLoggingBeganNotification"
#define kNXTLoggingEndedNotification @"kNXTLoggingEndedNotification"
#define kNXTLogUpdateNotification @"kNXTLogUpdateNotification"
#define MAX_LOG_ENTRIES 2000
#define LOG_ENTRIES_BEFORE_WRITE 50

@class NXTSensor;

@interface NXTLogController : NSObject {
   NSString *filePath;
   NSFileHandle *logFileHandle;
   
   BOOL isSetup;
   BOOL isLogging;
   BOOL ignoreMaxEntries;
   int logEntries;
}

@property (nonatomic, readonly) NSString *filePath;
@property (nonatomic) BOOL ignoreMaxEntries;
@property (nonatomic, readonly) BOOL isLogging;
@property (nonatomic, readonly) int logEntries;

+(NXTLogController*)sharedInstance;
-(void)updateSensor:(NSNotification*)note;
-(void)updateServo:(NSNotification*)note;
-(void)addLogEntry:(NXTSensor*)sensor;

-(void)setupWithAbsolutePath:(NSString*)path;
-(void)startLogging;
-(void)stopLogging;

@end
