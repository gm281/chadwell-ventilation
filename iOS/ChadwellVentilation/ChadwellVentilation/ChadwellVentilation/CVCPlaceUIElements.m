//
//  CVCPlaceUIElements.m
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 12/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import "CVCPlaceUIElements.h"
#import "CVCSensorReading.h"

#define PLACE_LABEL_X               10
#define PLACE_LABEL_WIDTH           80
#define PLACE_LABEL_HEIGHT          20
#define HUMIDITY_LABEL_X            (PLACE_LABEL_X + PLACE_LABEL_WIDTH  + 10)
#define HUMIDITY_LABEL_WIDTH        50
#define HUMIDITY_LABEL_HEIGHT       PLACE_LABEL_HEIGHT
#define TEMPERATURE_LABEL_X         (HUMIDITY_LABEL_X + HUMIDITY_LABEL_WIDTH  + 5)
#define TEMPERATURE_LABEL_WIDTH     55
#define TEMPERATURE_LABEL_HEIGHT    PLACE_LABEL_HEIGHT
#define ON_BUTTON_X                 (TEMPERATURE_LABEL_X + TEMPERATURE_LABEL_WIDTH  + 10)
#define ON_BUTTON_WIDTH             40
#define ON_BUTTON_HEIGHT            PLACE_LABEL_HEIGHT
#define OFF_BUTTON_X                (ON_BUTTON_X + ON_BUTTON_WIDTH + 10)
#define OFF_BUTTON_WIDTH            40
#define OFF_BUTTON_HEIGHT           PLACE_LABEL_HEIGHT


@interface  CVCPlaceUIElements ()
@property (nonatomic, readonly, strong) CVCPlace *place;
@end

@implementation CVCPlaceUIElements

- (instancetype)initWithPlace:(CVCPlace *)place y:(CGFloat)y
{
    self = [super init];
    if (self) {
        _place = place;
        _name = [[UILabel alloc] initWithFrame:CGRectMake(PLACE_LABEL_X, y, PLACE_LABEL_WIDTH, PLACE_LABEL_HEIGHT)];
        [_name setText:_place.name];
        _humidity = [[UILabel alloc] initWithFrame:CGRectMake(HUMIDITY_LABEL_X, y, HUMIDITY_LABEL_WIDTH, HUMIDITY_LABEL_HEIGHT)];
        [_humidity setText:@"0%"];
        _temperature = [[UILabel alloc] initWithFrame:CGRectMake(TEMPERATURE_LABEL_X, y, TEMPERATURE_LABEL_WIDTH, TEMPERATURE_LABEL_HEIGHT)];
        [_temperature setText:@"0℃"];
        if (place.hasRelay) {
            _on = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [_on setFrame:CGRectMake(ON_BUTTON_X, y, ON_BUTTON_WIDTH, ON_BUTTON_HEIGHT)];
            [_on setTitle:@"ON" forState:UIControlStateNormal];
            [_on setTitle:@".ON." forState:UIControlStateHighlighted];
            [_on setTitle:@"ON" forState:UIControlStateSelected];
            [_on addTarget:self action:@selector(on:) forControlEvents:UIControlEventTouchDown];
            _off = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [_off setFrame:CGRectMake(OFF_BUTTON_X, y, OFF_BUTTON_WIDTH, OFF_BUTTON_HEIGHT)];
            [_off setTitle:@"OFF" forState:UIControlStateNormal];
            [_off setTitle:@".OFF." forState:UIControlStateHighlighted];
            [_off setTitle:@"OFF" forState:UIControlStateSelected];
            [_off addTarget:self action:@selector(off:) forControlEvents:UIControlEventTouchDown];
        }
        [self refresh];
    }
    return self;
}

- (void)refresh
{
    CVCSensorReading *latestReading = [self.place latestSensorReading];
    if (latestReading != nil) {
        [self.humidity setText:[NSString stringWithFormat:@"%.0f%%", latestReading.humididy]];
        [self.temperature setText:[NSString stringWithFormat:@"%.1f℃", latestReading.temperature]];
    }
}

- (void)on:(id)sender
{
    [self.delegate place:self.place relayAction:CVCPlaceUIElementsActionOn];
}

- (void)off:(id)sender
{
    [self.delegate place:self.place relayAction:CVCPlaceUIElementsActionOff];
}

@end
