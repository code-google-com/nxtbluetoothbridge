//
//  NXTBluetoothBridgeAppDelegate.m
//  NXTBluetoothBridge
//
//  Created by Daniel Siemer on 4/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NXTBluetoothBridgeAppDelegate.h"
#import "NXTModel.h"
#import "NXTController.h"
#import "NXTController+SystemCommands.h"
#import "NXTConnection.h"
#import "NXTUSBConnection.h"
#import "NXTBluetoothConnection.h"

@implementation NXTBluetoothBridgeAppDelegate

@synthesize window;

#pragma mark -
#pragma mark NSApplicationDelegate Methods

-(void)applicationWillTerminate:(NSNotification *)notification
{
   [[NXTServer sharedServer] stopServer];
   [[NXTConnection sharedConnection] stopConnection];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
   return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   [[NXTController sharedInstance] setNxtDelegate:(id)self];
   [[NXTController sharedInstance] setServerMode:YES];
   [NXTModel sharedInstance];
   
   [NXTConnection initSharedConnectionWithClass:[NXTUSBConnection class] andDelegate:self];
   currentConnectionType = 0;
   [[NXTServer sharedServer] setDelegate:self];
   
   [[NSNotificationCenter defaultCenter] addObserver:self 
                                            selector:@selector(updateInformation:) 
                                                name:kNXTInformationUpdateNotification 
                                              object:[NXTController sharedInstance]];   
}

#pragma mark -
#pragma mark Interface actions

-(IBAction)swapConnectionTypes:(id)sender
{
}

-(IBAction)toggleServer:(id)sender
{
   if(![[NXTServer sharedServer] running])
   {
      if ([requireNXT intValue] == 1 && ![[NXTConnection sharedConnection] connected])
      {
         NSLog(@"NXT not connected");
         return;
      }
      
      [portField setEditable:NO];
      int port = [portField intValue];
      if(port < 1023)
         port = 8884;
      
      [portField setTitle:[NSString stringWithFormat:@"%d", port]];

      [password setEditable:NO];
      if([[password title] isEqualToString:@""])
         [password setTitle:@"LEGOCLIENT"];
      
      [keepAliveButton setEnabled:NO];
      [requireNXT setEnabled:NO];
      
      [[NXTServer sharedServer] setPassword:[password title]];
      
      [[NXTServer sharedServer] setSharedServerDomain:@"local." type:@"_inxtrelay._tcp." port:port];
      [[NXTServer sharedServer] startServer];
      [serverButton setTitle:@"Stop Server"];
   }else {
      [[NXTServer sharedServer] stopServer];
      [portField setEditable:YES];
      [password setEditable:YES];
      [keepAliveButton setEnabled:YES];
      [requireNXT setEnabled:YES];
      [serverButton setTitle:@"Start Server"];
   }
}

-(IBAction)toggleNXT:(id)sender
{
   if(![[NXTConnection sharedConnection] connected])
   {
      if([connectionType selectedSegment] != currentConnectionType)
      {
         [[NXTConnection sharedConnection] stopConnection];
         switch ([connectionType selectedSegment]) {
            case 0:
               [NXTConnection initSharedConnectionWithClass:[NXTUSBConnection class] andDelegate:self];
               break;
            case 1:
               [NXTConnection initSharedConnectionWithClass:[NXTBluetoothConnection class] andDelegate:self];
               break;
            default:
               [NXTConnection initSharedConnectionWithClass:[NXTUSBConnection class] andDelegate:self];
               break;
         }
         currentConnectionType = [connectionType selectedSegment];
      }
      [[NXTConnection sharedConnection] connect];
   }else {
      [[NXTConnection sharedConnection] stopConnection];
      [sender setTitle:@"Connect NXT"];

      if([requireNXT intValue] == 1 && [[NXTServer sharedServer] running])
      {
         [self toggleServer:nil];
      }
   }
}

-(void)updateInformation:(NSNotification*)note
{

   [firmwareLabel setTitle:[NSString stringWithFormat:@"%d.%02d", [[NXTModel sharedInstance] majorFirmwareVer],
                                                                  [[NXTModel sharedInstance] minorFirmwareVer]]];
   [protocolLabel setTitle:[NSString stringWithFormat:@"%d.%02d", [[NXTModel sharedInstance] majorProtocolVer],
                                                                  [[NXTModel sharedInstance] minorProtocolVer]]];
   if ([[NXTModel sharedInstance] nxtName]) {
      [nxtName setTitle:[[NXTModel sharedInstance] nxtName]];
   }
   
   [batteryIndicator setIntValue:([[NXTModel sharedInstance] batteryLevel] - 6000) / 15];
   //NSLog(@"battery level: %d%%", ([[NXTModel sharedInstance] batteryLevel] - 6000) / 15);
}

#pragma mark -
#pragma mark NXTConnectionDelegate Methods

-(void)NXTConnectionDidConnect:(NXTConnection*)connection
{
   NSLog(@"Connected");
   [connectNXTButton setTitle:@"Disconnect NXT"];
   [nxtConnectionLabel setTitle:@"Connected"];
   [connectionType setEnabled:NO];
   
   if([keepAliveButton intValue] == 1)
      [[NXTController sharedInstance] pollKeepAlive];
}

-(void)NXTConnectionDidDisconnect:(NXTConnection*)connection
{
   NSLog(@"Disconnected");
   [connectNXTButton setTitle:@"Connect NXT"];
   [nxtConnectionLabel setTitle:@"Disconnected"];
   [connectionType setEnabled:YES];
   
   if([requireNXT intValue] == 1 && [[NXTServer sharedServer] running])
   {
      [self toggleServer:nil];
   }
}

-(void)NXTConnection:(NXTConnection*)connection didRecieveData:(void*)data withLength:(UInt8)length
{
   
}

-(void)NXTConnectionNeedsPasswordToConnect:(NXTConnection*)connection
{
   
}

#pragma mark -
#pragma mark NXTServer delegate methods

-(void)NXTServerConnected:(NXTServer*)aServer
{
   NSLog(@"Client connected");
   [serverConnectionLabel setTitle:@"Connected"];
}

-(void)NXTServerDisconnected:(NXTServer*)aServer
{
   NSLog(@"Client disconnected");
   [serverConnectionLabel setTitle:@"Disconnected"];
}

#pragma mark -
#pragma mark NXTController Delegate methods

-(void)NXTBatteryLevel:(NXTController*)nxt batteryLevel:(UInt16)batteryLevel
{
}

@end
