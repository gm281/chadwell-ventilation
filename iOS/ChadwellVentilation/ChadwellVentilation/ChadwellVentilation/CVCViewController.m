//
//  CVCViewController.m
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 09/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import "CVCViewController.h"
#import "CVCControllerConnection.h"

@interface CVCViewController () <CVCControllerConnectionDelegate>
@property (nonatomic, readwrite, strong) CVCControllerConnection *connectionController;
@end

@implementation CVCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.connectionController = [[CVCControllerConnection alloc] init];
    self.connectionController.delegate = self;
    [self.connectionController connect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)connection:(CVCControllerConnection *)connection didError:(NSError *)error
{
    NSLog(@"=======> GOT CONNECTION ERROR: %@", error);
}

- (void)connectionClosed:(CVCControllerConnection *)connection
{
    NSLog(@"=======> GOT CONNECTION CLOSED");
}

- (void)connectionReady:(CVCControllerConnection *)connection
{
    NSLog(@"=======> GOT CONNECTION READY");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [connection requestSensorReading:@"Outside"];
        [connection requestSensorReading:@"Bathroom"];
        [connection requestSensorReading:@"Bedroom"];
        [connection requestSensorReading:@"Jasiu"];
    });
}

@end
