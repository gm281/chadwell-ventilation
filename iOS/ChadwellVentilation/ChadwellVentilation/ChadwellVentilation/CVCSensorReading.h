//
//  CVCSensorReading.h
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 12/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CVCPlace.h"

@interface CVCSensorReading : NSObject

@property (nonatomic, readonly, strong) CVCPlace *place;
@property (nonatomic, readonly, strong) NSDate *date;
@property (nonatomic, readonly, assign) float humididy;
@property (nonatomic, readonly, assign) float temperature;

- (instancetype)initWithPlace:(CVCPlace *)place
                         date:(NSDate *)date
                     humidity:(float)humidity
                  temperature:(float)temperature;

@end
