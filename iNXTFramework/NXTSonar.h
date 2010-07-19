//
//  NXTSonar.h
//  iNXTFramework
//
//  Created by Daniel Siemer on 5/29/10.
//

#import <Foundation/Foundation.h>
#import "NXTLowSpeed.h"

@interface NXTSonar : NXTLowSpeed {
   UInt8 value;
}
@property (nonatomic) UInt8 value;

@end
