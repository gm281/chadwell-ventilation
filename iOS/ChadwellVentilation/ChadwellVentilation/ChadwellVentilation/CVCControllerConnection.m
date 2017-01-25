//
//  CVCControllerConnection.m
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 09/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import "CVCControllerConnection.h"
#import "CVCUtils.h"
#import "CVCSensorReading.h"

@interface CVCControllerConnection ()
@property (nonatomic, readwrite, assign) BOOL inputStreamOpened;
@property (nonatomic, readwrite, strong) NSInputStream *inputStream;
@property (nonatomic, readwrite, strong) NSData *messageBuffer;
@property (nonatomic, readwrite, assign) BOOL outputStreamOpened;
@property (nonatomic, readwrite, strong) NSOutputStream *outputStream;
@property (nonatomic, readwrite, strong) NSMutableData *outputStreamBuffer;
@end

@implementation CVCControllerConnection

- (instancetype)init
{
    self = [super init];
    if (self) {
        _inputStreamOpened = NO;
        _outputStreamOpened = NO;
        _outputStreamBuffer = [[NSMutableData alloc] init];
        _messageBuffer = [NSData data];
    }
    return self;
}

- (void)connect
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)@"192.168.0.101", 12400, &readStream, &writeStream);
    //CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)@"localhost", 12400, &readStream, &writeStream);

    if(!CFWriteStreamOpen(writeStream)) {
        NSError *error = [NSError errorWithDomain:CVCControllerConnectionErrorDomain
                                             code:CVCControllerConnectionStreamOpenFailed
                                         userInfo:@{}];
        [self.delegate connection:self didError:error];
		return;
	}

    self.inputStream = (__bridge NSInputStream *)readStream;
	self.outputStream = (__bridge NSOutputStream *)writeStream;

    [self.inputStream setDelegate:self];
	[self.outputStream setDelegate:self];

	[self.inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	[self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

	[self.inputStream open];
	[self.outputStream open];
}

- (void)handleInputStreamEvent:(NSStreamEvent)event
{
    NSLog(@"=> IS %d", event);
    // I'm assuming events won't be ORred together
    switch (event) {
        case NSStreamEventNone:
            break;
        case NSStreamEventOpenCompleted:
            self.inputStreamOpened = YES;
            if (self.outputStreamOpened) {
                [self.delegate connectionReady:self];
            }
            break;
        case NSStreamEventHasBytesAvailable:
            [self readMessage];
            break;
        case NSStreamEventHasSpaceAvailable:
            break;
        case NSStreamEventErrorOccurred:
            [self.delegate connection:self didError:[self.inputStream streamError]];
            break;
        case NSStreamEventEndEncountered:
            self.inputStreamOpened = NO;
            [self.delegate connectionClosed:self];
            break;
        default:
            NSLog(@"Unknown event on input stream: %d", event);
            break;
    }
}

- (void)handleOutputStreamEvent:(NSStreamEvent)event
{
    NSLog(@"=> OS %d", event);
    switch (event) {
        case NSStreamEventNone:
            break;
        case NSStreamEventOpenCompleted:
            self.outputStreamOpened = YES;
            if (self.inputStreamOpened) {
                [self.delegate connectionReady:self];
            }
            break;
        case NSStreamEventHasBytesAvailable:
            break;
        case NSStreamEventHasSpaceAvailable:
            [self drainMessageBuffer];
            break;
        case NSStreamEventErrorOccurred:
            [self.delegate connection:self didError:[self.outputStream streamError]];
            break;
        case NSStreamEventEndEncountered:
            self.outputStreamOpened = NO;
            [self.delegate connectionClosed:self];
            break;
        default:
            NSLog(@"Unknown event on input stream: %d", event);
            break;
    }
}

- (void)queueMessageString:(NSString *)messageString
{
    CVC_weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^CVC_if_strongify(self, {
        NSLog(@"Queing message: %@", messageString);
        NSMutableData *newMessageBuffer = [[NSMutableData alloc] init];
        [newMessageBuffer appendData:self.messageBuffer];
        [newMessageBuffer appendData:[messageString dataUsingEncoding:NSUTF8StringEncoding]];
        self.messageBuffer = newMessageBuffer;
        [self drainMessageBuffer];
    }));
}

- (void)requestSensorReading:(NSString *)placeName
{
    NSString *messageString = [NSString stringWithFormat:@"sensor,%@$", placeName];
    [self queueMessageString:messageString];
}

- (void)relayForPlace:(NSString *)placeName switchOn:(BOOL)on
{
    NSString *messageString = [NSString stringWithFormat:@"relay,%@,%d$", placeName, on ? 1 : 0];
    [self queueMessageString:messageString];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event
{
    if (stream == self.outputStream) {
        [self handleOutputStreamEvent:event];
        return;
    }

    if (stream == self.inputStream) {
        [self handleInputStreamEvent:event];
        return;
    }

    NSLog(@"Event for unknown stream");
}

- (void)drainMessageBuffer
{
    if (self.messageBuffer.length <= 0) {
        return;
    }
    NSInteger bytesWritten = [self.outputStream write:[self.messageBuffer bytes] maxLength:self.messageBuffer.length];
    if (bytesWritten > 0) {
        NSRange reminderRange = {bytesWritten + 1, self.messageBuffer.length - bytesWritten};
        self.messageBuffer = [self.messageBuffer subdataWithRange:reminderRange];
    }
}

- (void)processMessageData:(NSData *)messageData
{
    NSString *message = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];
    NSLog(@"==> Got message: %@", message);
    NSArray *tokens = [message componentsSeparatedByString:@","];
    if ([tokens count] <= 0) {
        return;
    }
    NSString *messageType = tokens[0];
    if ([messageType isEqualToString:@"sensor_reading"]) {
        if ([tokens count] != 5) {
            NSLog(@"Wrong number of tokens in sensor_reading: %d", [tokens count]);
            return;
        }
        NSString *placeName = tokens[1];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSSSS"];
        NSDate *date = [dateFormat dateFromString:tokens[2]];
        double humidity = [tokens[3] doubleValue];
        double temperature = [tokens[4] doubleValue];

        CVCPlace *place = [CVCPlace placeByName:placeName];
        if (place == nil) {
            NSLog(@"Got reading: %@, %@, %f, %f, but place unknown", placeName, date, humidity, temperature);
        }
        CVCSensorReading *reading = [[CVCSensorReading alloc] initWithPlace:place
                                                                       date:date
                                                                   humidity:humidity
                                                                temperature:temperature];
        [place handleNewSensorReading:reading];
    }

}

- (void)readMessage
{
    uint8_t buf[1024];
    unsigned int len = 0;

    len = [self.inputStream read:buf maxLength:sizeof(buf)];
    if (len <= 0) {
        return;
    }

    [self.outputStreamBuffer appendBytes:buf length:len];

    while (true) {
        NSData *messageTerminator = [@"$" dataUsingEncoding:NSUTF8StringEncoding];
        NSRange range = [self.outputStreamBuffer rangeOfData:messageTerminator options:0 range:NSMakeRange(0, self.outputStreamBuffer.length)];
        if (range.location == NSNotFound) {
            return;
        }

        NSData *messageData = nil;
        if (range.location != 0) {
            NSRange messageRange = {0, range.location + 1};
            messageData = [self.outputStreamBuffer subdataWithRange:messageRange];
            [self processMessageData:messageData];
        }

        NSRange remainderRange = {range.location + 1, [self.outputStreamBuffer length] - range.location - 1};
        self.outputStreamBuffer = [NSMutableData dataWithData:[self.outputStreamBuffer subdataWithRange:remainderRange]];
    }
}

@end
