//
//  CVCUtils.h
//  ChadwellVentilation
//
//  Created by Grzegorz Milos on 09/10/2014.
//  Copyright (c) 2014 Grzegorz Miłoś. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CVC_ASSIGN_OUT_PTR(_var, ...) do { if ((_var)) { *(_var) = (__VA_ARGS__); } } while (false);

#define CVC_PRIMITIVE_JOIN(_a, _b) _a ## _b
#define CVC_EXPANDING_JOIN(_a, _b) CVC_PRIMITIVE_JOIN(_a, _b)

#define CVC_weakify(_var) /*
*/    __weak __typeof__(_var) CVC_EXPANDING_JOIN(_weak, _var) = (_var);


#define CVC_strongify(_var) /*
*/    _Pragma("clang diagnostic push"); /*
*/    _Pragma("clang diagnostic ignored \"-Wshadow\""); /*
*/    __strong __typeof__(_var) (_var) = CVC_EXPANDING_JOIN(_weak, _var); /*
*/    _Pragma("clang diagnostic pop");

#define CVC_if_strongify(_var, ...) /*
*/    { /*
*/        CVC_strongify(_var); /*
*/        if (_var) { /*
*/            __VA_ARGS__ /*
*/        } /*
*/    }