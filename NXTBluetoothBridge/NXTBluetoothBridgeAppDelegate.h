//
//  NXTBluetoothBridgeAppDelegate.h
//  NXTBluetoothBridge
//
//  Created by Daniel Siemer on 4/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NXTConnection.h"
#import "NXTServer.h"

@interface NXTBluetoothBridgeAppDelegate : NSObject <NXTConnectionDelegate, NXTServerDelegate> {
    NSWindow *window;
    IBOutlet NSTextFieldCell *nxtName;
    IBOutlet NSSecureTextFieldCell *password;
    IBOutlet NSTextFieldCell *portField;
    IBOutlet NSTextFieldCell *nxtConnectionLabel;
    IBOutlet NSTextFieldCell *serverConnectionLabel;
    IBOutlet NSTextFieldCell *firmwareLabel;
    IBOutlet NSTextFieldCell *protocolLabel;
    IBOutlet NSLevelIndicator *batteryIndicator;
    IBOutlet NSButtonCell *connectNXTButton;
    IBOutlet NSButtonCell *serverButton;
    IBOutlet NSButtonCell *keepAliveButton;
    IBOutlet NSButtonCell *requireNXT;
    IBOutlet NSSegmentedControl *connectionType;
    
    int currentConnectionType;
}

@property (assign) IBOutlet NSWindow *window;

-(IBAction)swapConnectionTypes:(id)sender;
-(IBAction)toggleServer:(id)sender;
-(IBAction)toggleNXT:(id)sender;
-(void)updateInformation:(NSNotification*)note;

@end
