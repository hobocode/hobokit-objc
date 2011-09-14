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

#import "HKHook.h"

#import <objc/runtime.h>

@interface HKHook : NSObject
{
@private
    NSString        *_hook;
    HKHookHandler    _handler;
    id               _registrant;
}

@property (copy) NSString *hook;
@property (copy) HKHookHandler handler;
@property (assign) id registrant;

+ (HKHook *)hookWithHook:(NSString *)hook handler:(HKHookHandler)handler registrant:(id)registrant;

- (id)initWithHook:(NSString *)hook handler:(HKHookHandler)handler registrant:(id)registrant;

@end

@implementation HKHook

+ (HKHook *)hookWithHook:(NSString *)hook handler:(HKHookHandler)handler registrant:(id)registrant
{
    return [[[HKHook alloc] initWithHook:hook handler:handler registrant:registrant] autorelease];
}

@synthesize hook = _hook, handler = _handler, registrant = _registrant;

- (id)initWithHook:(NSString *)hook handler:(HKHookHandler)handler registrant:(id)registrant
{
    if ( self = [super init] )
    {
        self.hook = hook;
        self.handler = handler;
        self.registrant = registrant;
    }
    
    return self;
}

- (void)dealloc
{    
    [_hook release]; _hook = nil;
    [_handler release]; _handler = nil;
    [super dealloc];
}

@end

void HKHookRegister ( NSString *hook, id object, id registrant, HKHookHandler handler )
{
    const char          *chook = [hook UTF8String];
    NSMutableDictionary *hooks = objc_getAssociatedObject( object, chook );
    HKHook              *h = [HKHook hookWithHook:hook handler:handler registrant:registrant];
    NSString            *key = [NSString stringWithFormat:@"%@_%p", hook, registrant];
    
    if ( hooks == nil )
    {
        hooks = [NSMutableDictionary dictionary];
        
        objc_setAssociatedObject( object, chook, hooks, OBJC_ASSOCIATION_RETAIN );
    }
    
    [hooks setObject:h forKey:key];
}

void HKHookUnregister ( NSString *hook, id object, id registrant )
{
    const char          *chook = [hook UTF8String];
    NSMutableDictionary *hooks = objc_getAssociatedObject( object, chook );
    NSString            *key = [NSString stringWithFormat:@"%@_%p", hook, registrant];

    if ( hooks == nil )
        return;
    
    [hooks removeObjectForKey:key];
}

void HKHookBroadcast ( NSString *hook, id context, id broadcaster )
{
    const char *chook = [hook UTF8String];
    NSArray    *hooks = [objc_getAssociatedObject( broadcaster, chook ) allValues];
    
    if ( hooks == nil )
        return;
    
    for ( HKHook *h in hooks )
    {
        h.handler( context );
    }
}
