//
//  EchoServer.m
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

#import "TCPServer.h"
#import "RelayServer.h"
#import "NXTBluetoothBridgeAppDelegate.h"
#import "NXT.h"

@implementation RelayServer
@synthesize istream;
@synthesize ostream;
@synthesize isAuthenticated;

- (void)setupInputStream {
   [istream setDelegate:self];
   [ostream setDelegate:self];
   [istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
   [ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
   [istream open];
   [ostream open];
   [self.delegate netConnected];
   NSLog(@"Added connection.");
}

- (void)shutdownInputStream {
   [istream close];
   [ostream close];
   [istream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
   [ostream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
   [self.delegate netDisconnected];
   self.isAuthenticated = NO;
   NSLog(@"Connection closed.");
}

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
   if(!isAuthenticated)
   {
      self.istream = istr;
      self.ostream = ostr;
      [self setupInputStream];
   }else{
      NSLog(@"Server full, connection rejected");
   }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent {
   switch(streamEvent) {
      case NSStreamEventHasBytesAvailable:;
         char buffer[2048];
         int actuallyRead = [istream read:(unsigned char*)buffer maxLength:2048];
         if(actuallyRead > 0){
            if(self.isAuthenticated)
               [delegate.nxt sendMessage:buffer length:actuallyRead];
            else
               [self handlePassword:buffer length:actuallyRead];
         }
         break;
      case NSStreamEventEndEncountered:
            [self shutdownInputStream];
         break;
      case NSStreamEventHasSpaceAvailable:
      case NSStreamEventErrorOccurred:
      case NSStreamEventOpenCompleted:
      case NSStreamEventNone:
      default:
         break;
   }
}

-(void)handlePassword:(char*)password length:(int)actuallyRead{
   char message[9];
   NSString *tempPass = self.delegate.passwordEntry.stringValue;
   if([tempPass isEqualToString:@""])
      tempPass = @"LEGOCLIENT";
   
   if([tempPass isEqualToString:[NSString stringWithCString:password encoding:NSASCIIStringEncoding]]){
      message[4] = 0x00;
      self.isAuthenticated = YES;
      [self sendMessageToClient:message length:9];
   }else{
      message[4] = 0x01;
      self.isAuthenticated = NO;
      [self sendMessageToClient:message length:9];
      [self shutdownInputStream];
   }
}


//This message is what forwards replies from the NXT to the connected client
-(void)sendMessageToClient:(void*)message length:(UInt8)length{
   NSData * dataToSend = [[NSData alloc] initWithBytes:message length:length];
   if (ostream) {
      int remainingToWrite = [dataToSend length];
      void * marker = (void *)[dataToSend bytes];
      while (0 < remainingToWrite) {
         int actuallyWritten = 0;
         actuallyWritten = [ostream write:marker maxLength:remainingToWrite];
         remainingToWrite -= actuallyWritten;
         marker += actuallyWritten;
      }
   }
}

-(void)startUp{
   NSLog(@"Trying to start server in background");
   self.isAuthenticated = NO;
   NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
   NSRunLoop *rl = [NSRunLoop currentRunLoop];
   
   self.type = @"_inxtrelay._tcp.";
   
   NSError *startError = nil;
   if (![self start:&startError] ) {
      NSLog(@"Error starting server: %@", startError);
   } else {
      NSLog(@"Starting server on port %d", self.port);
   }
   [rl run];
   [pool release];
}

@end
