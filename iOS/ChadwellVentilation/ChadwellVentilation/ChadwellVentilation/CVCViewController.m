//
//  CVCViewController.m
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 09/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import "CVCViewController.h"
#import "CVCControllerConnection.h"
#import "CVCUtils.h"
#import "CVCPlace.h"

#define FIRST_Y                     30
#define Y_STEP                      30

@interface CVCViewController () <CVCControllerConnectionDelegate>
@property (nonatomic, readwrite, strong) CVCControllerConnection *connection;
@property (atomic, readwrite, strong) CVCControllerConnection *activeConnection;
@property (nonatomic, readwrite, strong) NSArray *placesUI;
@end

@implementation CVCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self establishConnection];
    [self recheckLoop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)establishConnection
{
    self.connection = [[CVCControllerConnection alloc] init];
    self.connection.delegate = self;
    [self.connection connect];
}

- (void)teardownAndRetryConnection
{
    self.activeConnection = nil;
    CVC_weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^CVC_if_strongify(self, {
        [self establishConnection];
    }));
}

- (void)connection:(CVCControllerConnection *)connection didError:(NSError *)error
{
    NSLog(@"=======> GOT CONNECTION ERROR: %@", error);
    [self teardownAndRetryConnection];
}

- (void)connectionClosed:(CVCControllerConnection *)connection
{
    NSLog(@"=======> GOT CONNECTION CLOSED");
    [self teardownAndRetryConnection];
}

- (void)connectionReady:(CVCControllerConnection *)connection
{
    self.activeConnection = connection;

    NSLog(@"=======> GOT CONNECTION READY");

}

- (void)requestSensorReadings
{
    CVCControllerConnection *connection = self.activeConnection;
    if (connection == nil) {
        return;
    }

    NSArray *places = [CVCPlace places];
    [places enumerateObjectsUsingBlock:^(CVCPlace *place, NSUInteger idx, BOOL *stop) {
        [connection requestSensorReading:place.name];
    }];
}

- (void)recheckLoop
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self requestSensorReadings];
        for (CVCPlaceUIElements *placeUI in self.placesUI) {
            [placeUI refresh];
        }
        [self recheckLoop];
    });
}

- (void)setupViews
{
    NSArray *places = [CVCPlace places];

    CGFloat y = FIRST_Y;
    NSMutableArray *placesUI = [[NSMutableArray alloc] init];
    for (CVCPlace *place in places) {
        CVCPlaceUIElements *placeUIElements = [[CVCPlaceUIElements alloc] initWithPlace:place y:y];
        placeUIElements.delegate = self;
        [placesUI addObject:placeUIElements];
        [self.view addSubview:placeUIElements.name];
        [self.view addSubview:placeUIElements.humidity];
        [self.view addSubview:placeUIElements.temperature];
        [self.view addSubview:placeUIElements.on];
        [self.view addSubview:placeUIElements.off];

        y += Y_STEP;
    }
    self.placesUI = placesUI;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@""];
}

- (void)place:(CVCPlace *)place relayAction:(CVCPlaceUIElementsAction)action
{
    NSLog(@"==> got action, %p", self.activeConnection);
    switch (action) {
        case CVCPlaceUIElementsActionOn:
            [self.activeConnection relayForPlace:place.name switchOn:YES];
            break;

        case CVCPlaceUIElementsActionOff:
            [self.activeConnection relayForPlace:place.name switchOn:NO];
            break;

        default:
            NSLog(@"Unknown action requested: %d", action);
            break;
    }
}

@end
