//  Copyright (c) 2011 HoboCode
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>

typedef void(^HKHookHandler)(id context);

void HKHookRegister ( const char *hook, id object, id registrant, HKHookHandler handler );
void HKHookUnregister ( const char *hook, id object, id registrant );
void HKHookBroadcast ( const char *hook, id context, id broadcaster );

#define $hook( hook, object, handler ) ({ \
    __block __typeof(self) __hook_self = self; \
    __block const char *__hook_hook = hook; \
    __block id __hook_object = object; \
    HKHookRegister( (__hook_hook), (__hook_object), (__hook_self), (handler) ); \
})

#define $uhook(...) ({ \
    HKHookUnregister( __hook_hook, __hook_object, __hook_self ); \
})

#define $unhook( hook, object ) ({ \
    HKHookUnregister( hook, object, self ); \
})

#define $bcast( hook, context ) ({ \
    HKHookBroadcast( hook, context, __hook_self ); \
})

#define $broadcast( hook, context ) ({ \
    HKHookBroadcast( hook, context, self ); \
})
