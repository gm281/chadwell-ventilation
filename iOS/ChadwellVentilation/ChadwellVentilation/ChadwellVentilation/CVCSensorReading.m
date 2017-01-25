//
//  CVCSensorReading.m
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 12/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import "CVCSensorReading.h"

@implementation CVCSensorReading

- (instancetype)initWithPlace:(CVCPlace *)place
                         date:(NSDate *)date
                     humidity:(float)humidity
                  temperature:(float)temperature
{
    self = [super init];
    if (self) {
        _place = place;
        _date = date;
        _humididy = humidity;
        _temperature = temperature;
    }
    return self;
}
@end
