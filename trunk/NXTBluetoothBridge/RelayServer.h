//
//  EchoServer.h
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

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "TCPServer.h"

@interface RelayServer : TCPServer {
   NSInputStream *istream;
   NSOutputStream *ostream;
   BOOL isAuthenticated;
}
@property (nonatomic, retain) NSInputStream *istream;
@property (nonatomic, retain) NSOutputStream *ostream;
@property (nonatomic) BOOL isAuthenticated;

-(void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
-(void)setupInputStream;
-(void)shutdownInputStream;
-(void)startUp;
-(void)sendMessageToClient:(void*)message length:(UInt8)length;
-(void)handlePassword:(char*)password length:(int)length;

@end