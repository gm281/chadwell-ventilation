//
//  CVCPlaceUIElements.h
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 12/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CVCPlace.h"

typedef enum {
    CVCPlaceUIElementsActionOn,
    CVCPlaceUIElementsActionOff,
} CVCPlaceUIElementsAction;

@protocol CVCPlaceUIElementsDelegate <NSObject>
- (void)place:(CVCPlace *)place relayAction:(CVCPlaceUIElementsAction)action;
@end

@interface CVCPlaceUIElements : NSObject

@property (nonatomic, readonly, strong) UILabel *name;
@property (nonatomic, readonly, strong) UILabel *humidity;
@property (nonatomic, readonly, strong) UILabel *temperature;
@property (nonatomic, readonly, strong) UIButton *on;
@property (nonatomic, readonly, strong) UIButton *off;
@property (atomic, readwrite, weak) id<CVCPlaceUIElementsDelegate> delegate;

- (instancetype)initWithPlace:(CVCPlace *)place y:(CGFloat)y;
- (void)refresh;

@end
