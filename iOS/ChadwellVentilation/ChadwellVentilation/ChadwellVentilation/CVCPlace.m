//
//  CVCPlace.m
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 12/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import "CVCPlace.h"
#import "CVCSensorReading.h"

static dispatch_once_t onceToken;
static NSArray *places;

@interface CVCPlace ()
@end


@implementation CVCPlace

- (instancetype)initWithName:(NSString *)name hasRelay:(BOOL)hasRelay
{
    self = [super init];
    if (self) {
        _name = name;
        _hasRelay = hasRelay;
    }
    return self;
}

- (void)handleNewSensorReading:(CVCSensorReading *)sensorReading
{
    if (self.latestSensorReading == nil ||
        [self.latestSensorReading.date compare:sensorReading.date] == NSOrderedAscending) {
        self.latestSensorReading = sensorReading;
    }
}

+ (NSArray *)places
{
    dispatch_once(&onceToken, ^{
        CVCPlace *outside = [[CVCPlace alloc] initWithName:@"Outside" hasRelay:NO];
        CVCPlace *bathroom = [[CVCPlace alloc] initWithName:@"Bathroom" hasRelay:YES];
        CVCPlace *hall = [[CVCPlace alloc] initWithName:@"Hall" hasRelay:YES];
        CVCPlace *jasiu = [[CVCPlace alloc] initWithName:@"Jasiu" hasRelay:YES];
        CVCPlace *study = [[CVCPlace alloc] initWithName:@"Study" hasRelay:YES];
        CVCPlace *bedroom = [[CVCPlace alloc] initWithName:@"Bedroom" hasRelay:YES];

        places = @[outside, bathroom, hall, jasiu, study, bedroom];
    });

    return places;
}

+ (CVCPlace *)placeByName:(NSString *)name
{
    NSArray *places = [self places];
    for (CVCPlace *place in places) {
        if ([place.name isEqualToString:name]) {
            return place;
        }
    }
    return nil;
}

@end
