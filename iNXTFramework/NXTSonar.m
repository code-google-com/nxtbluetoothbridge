//
//  NXTSonar.m
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/29/10.
//

#import "NXTSonar.h"
#import "NXTController.h"
#import "NXTController+SensorCommands.h"

@implementation NXTSonar
@synthesize value;

-(id)initWithPort:(UInt8)newPort
{
   if(self = [super initWithPort:newPort])
   {
      self.nxtType = kNXTLowSpeed9V;
      self.userType = kNXTSonarIndex;
   }
   return self;
}

-(BOOL)setupSensor
{
   [super setupSensor];

   char message[] = { 0x02, 0x41, 0x02 };
   [[NXTController sharedInstance] LSWrite:port txLength:3 rxLength:0 txData:message];
   return YES;
}

-(NSString*)valueString
{
   NSString *valString;
   
   // out of bounds
   if ( value >= 255 )
      valString = [NSString stringWithFormat:@"--"];
   else
      valString = [NSString stringWithFormat:@"%hu", value];
   return valString;
}

-(void)lowSpeedDataRecieved:(NSData *)data
{
   [data getBytes:&value length:1];
   [self valueUpdated];
}

@end
