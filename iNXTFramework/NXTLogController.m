//
//  NXTLogController.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/26/10.
//

#import "NXTLogController.h"
#import "NXTModel.h"
#import "NXTSensor.h"
#import "NXTFileController.h"

@implementation NXTLogController

@synthesize logEntries;
@synthesize filePath;
@synthesize isLogging;
@synthesize ignoreMaxEntries;

+(NXTLogController*)sharedInstance
{
   static NXTLogController *_sharedInstance = nil;
   if (!_sharedInstance){
      _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
   }
   return _sharedInstance;
}

-(id)init
{
   if(self = [super init])
   {
      isLogging = NO;
      ignoreMaxEntries = NO;
   }
   return self;
}

-(void)updateSensor:(NSNotification*)note
{
   UInt8 port = [[[note userInfo] objectForKey:kNXTSensorPortKey] unsignedIntValue];
   [self addLogEntry:[[NXTModel sharedInstance] sensorForPort:port]];
}

-(void)updateServo:(NSNotification*)note
{
   UInt8 port = [[[note userInfo] objectForKey:kNXTMotorPortKey] unsignedIntValue];
   [self addLogEntry:(NXTSensor*)[[NXTModel sharedInstance] motorForPort:port]];
}

-(void)addLogEntry:(NXTSensor*)sensor
{
   if(isLogging)
   {
      NSString *logEntry = [NSString stringWithFormat:@"%@\t%@\t%d\t%@\n", [NSDate date], 
                                                                           [NXTSensor displayStringForType:[sensor userType]], 
                                                                           [sensor port],
                                                                           [sensor valueString]];
      
      logEntries++;
      
      if(logEntries < MAX_LOG_ENTRIES || ignoreMaxEntries)
      {
         if(logFileHandle != nil)
         {
            [logFileHandle writeData:[logEntry dataUsingEncoding:NSASCIIStringEncoding]];
         }else{
            logFileHandle = [[NSFileHandle fileHandleForWritingAtPath:filePath] retain];
            if(logFileHandle != nil)
            {
               NSLog(@"File exists, seeking for appending");
               [logFileHandle seekToEndOfFile];
               [logFileHandle writeData:[logEntry dataUsingEncoding:NSASCIIStringEncoding]];
            }else {
               NSLog(@"Creating new file for log");
               [[NSFileManager defaultManager] createFileAtPath:filePath contents:[logEntry dataUsingEncoding:NSASCIIStringEncoding] attributes:nil];
               logFileHandle = [[NSFileHandle fileHandleForWritingAtPath:self.filePath] retain];
               [logFileHandle seekToEndOfFile];
               if(logFileHandle == nil)
               {
                  NSLog(@"For some reason we cant create or open the logfile at all.");
                  [self stopLogging];
                  return;
               }
            }
         }
         
         if(logEntries % LOG_ENTRIES_BEFORE_WRITE == 0)
         {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNXTLogUpdateNotification object:self];
         }
      }
      else
      {
         NSLog(@"Max number of entries reached");
         [[NSNotificationCenter defaultCenter] postNotificationName:kNXTLoggingEndedNotification 
                                                             object:self];      
         [self stopLogging];
      }
   }
}

-(void)setupWithAbsolutePath:(NSString*)path
{
   if(!isLogging)
   {
      filePath = [path retain];
      isSetup = YES;
   }
}

-(void)startLogging
{
   if(!isLogging && isSetup)
   {
      isLogging = YES;
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(updateSensor:) 
                                                   name:kNXTSensorUpdatedNotification 
                                                 object:[NXTModel sharedInstance]];
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(updateServo:) 
                                                   name:kNXTMotorUpdatedNotification 
                                                 object:[NXTModel sharedInstance]];
      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTLoggingBeganNotification 
                                                          object:self];
   }else{
      NSLog(@"Already logging, or not setup");
   }
}

-(void)stopLogging
{
   if(isLogging)
   {
      isLogging = NO;
      isSetup = NO;
      [[NSNotificationCenter defaultCenter] removeObserver:self];
      if (logEntries > 0) {
         [[NXTFileController sharedInstance] newLocalFileName:[[filePath pathComponents] lastObject]];
      }
      [logFileHandle closeFile];
      
      //if(logEntries > 0)
         //[[NSNotificationCenter defaultCenter] postNotificationName:kNXTNewLocalFileNotification object:[NXTModel sharedInstance]];

      [[NSNotificationCenter defaultCenter] postNotificationName:kNXTLoggingEndedNotification 
                                                          object:self];      
   }else {
      NSLog(@"Not logging, so nothing to stop");
   }
}

@end
