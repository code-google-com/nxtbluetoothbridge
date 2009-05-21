//
//  TCPServer.h
//  NXTBluetoothBridge
//
//  Created by Daniel Siemer on 4/4/09.
/*
 The MIT License
 
 Copyright (c) 2009 Daniel Siemer
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

@class NXTBluetoothBridgeAppDelegate;

NSString * const TCPServerErrorDomain;

typedef enum {
   kTCPServerCouldNotBindToIPv4Address = 1,
   kTCPServerCouldNotBindToIPv6Address = 2,
   kTCPServerNoSocketsAvailable = 3,
} TCPServerErrorCode;

@interface TCPServer : NSObject {
   NXTBluetoothBridgeAppDelegate *delegate;
   NSString *domain;
   NSString *name;
   NSString *type;
   uint16_t port;
   CFSocketRef ipv4socket;
   CFSocketRef ipv6socket;
   NSNetService *netService;
}
@property (nonatomic, retain) NXTBluetoothBridgeAppDelegate *delegate;
@property (nonatomic, retain) NSString *domain;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *type;
@property (nonatomic) uint16_t port;
@property (nonatomic) CFSocketRef ipv4socket;
@property (nonatomic) CFSocketRef ipv6socket;
@property (nonatomic, retain) NSNetService *netService;

- (BOOL)start:(NSError **)error;
- (BOOL)stop;

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
// called when a new connection comes in; by default, informs the delegate

@end

@interface TCPServer (TCPServerDelegateMethods)
- (void)TCPServer:(TCPServer *)server didReceiveConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
// if the delegate implements this method, it is called when a new  
// connection comes in; a subclass may, of course, change that behavior
@end
