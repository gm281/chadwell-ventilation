//
//  CVCControllerConnection.h
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 09/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    CVCControllerConnectionStreamOpenFailed,
} CVCControllerConnectionErrorCode;

static NSString *const CVCControllerConnectionErrorDomain = @"CVCControllerConnectionErrorDomain";

@class CVCControllerConnection;
@protocol CVCControllerConnectionDelegate <NSObject>
- (void)connectionReady:(CVCControllerConnection *)connection;
- (void)connection:(CVCControllerConnection *)connection didError:(NSError *)error;
- (void)connectionClosed:(CVCControllerConnection *)connection;
@end

@interface CVCControllerConnection : NSObject <NSStreamDelegate>

@property (nonatomic, weak, readwrite) id<CVCControllerConnectionDelegate> delegate;
- (void)connect;
- (void)requestSensorReading:(NSString *)placeName;

@end
