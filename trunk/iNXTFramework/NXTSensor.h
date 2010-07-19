//
//  NXTSensor.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/21/10.
//

#import <Foundation/Foundation.h>

@interface NXTSensor : NSObject {
   UInt8 port;
   UInt8 nxtType;
   UInt8 userType;
   UInt8 mode;
   
   BOOL isPolling;
}
@property (nonatomic) UInt8 port;
@property (nonatomic) UInt8 nxtType;
@property (nonatomic) UInt8 userType;
@property (nonatomic) UInt8 mode;

@property (nonatomic) BOOL isPolling;

-(id)initWithPort:(UInt8)newPort;

-(BOOL)setupSensor;
-(void)valueUpdated;

-(NSString*)valueString;
-(NSString*)typeString;
+(NSString*)displayStringForType:(UInt8)type;

@end
