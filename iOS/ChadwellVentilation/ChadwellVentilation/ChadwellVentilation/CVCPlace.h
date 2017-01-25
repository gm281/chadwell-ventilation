//
//  CVCPlace.h
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 12/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CVCSensorReading;

@interface CVCPlace : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, assign) BOOL hasRelay;
@property (atomic, readwrite, strong) CVCSensorReading *latestSensorReading;

+ (NSArray *)places;
+ (CVCPlace *)placeByName:(NSString *)name;
- (void)handleNewSensorReading:(CVCSensorReading *)sensorReading;

@end
