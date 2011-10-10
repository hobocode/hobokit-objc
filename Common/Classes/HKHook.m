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
    const char      *_hook;
    dispatch_queue_t _queue;
    HKHookHandler    _handler;
    id               _registrant;
}

@property (assign) const char *hook;
@property (assign) dispatch_queue_t queue;
@property (copy) HKHookHandler handler;
@property (assign) id registrant;

+ (HKHook *)hookWithHook:(const char *)hook handler:(HKHookHandler)handler queue:(dispatch_queue_t)queue registrant:(id)registrant;

- (id)initWithHook:(const char *)hook handler:(HKHookHandler)handler queue:(dispatch_queue_t)queue registrant:(id)registrant;

@end

@implementation HKHook

+ (HKHook *)hookWithHook:(const char *)hook handler:(HKHookHandler)handler queue:(dispatch_queue_t)queue registrant:(id)registrant
{
    return [[[HKHook alloc] initWithHook:hook handler:handler queue:queue registrant:registrant] autorelease];
}

@synthesize hook = _hook, handler = _handler, registrant = _registrant;

- (id)initWithHook:(const char *)hook handler:(HKHookHandler)handler queue:(dispatch_queue_t)queue registrant:(id)registrant
{
    if ( self = [super init] )
    {
        self.hook = hook;
        self.handler = handler;
        self.queue = queue;
        self.registrant = registrant;
    }
    
    return self;
}

- (void)dealloc
{    
    [_handler release]; _handler = nil;
    
    if ( _queue )
    {
        dispatch_release( _queue );
    }
    [super dealloc];
}

- (dispatch_queue_t)queue
{
    return _queue;
}

- (void)setQueue:(dispatch_queue_t)value
{
    @synchronized( self )
    {
        if ( _queue != value )
        {
            if ( _queue )
            {
                dispatch_release( _queue );
            }
            
            _queue = value;
            
            if ( _queue )
            {
                dispatch_retain( _queue );
            }
        }
    }
}

@end

void HKHookRegister ( const char *hook, id object, id registrant, HKHookHandler handler )
{
    NSMutableDictionary *hooks = objc_getAssociatedObject( object, hook );
    HKHook              *h = [HKHook hookWithHook:hook handler:handler queue:dispatch_get_current_queue() registrant:registrant];
    NSString            *key = [NSString stringWithFormat:@"%s_%p", hook, registrant];
    
    if ( hooks == nil )
    {
        hooks = [NSMutableDictionary dictionary];
        
        objc_setAssociatedObject( object, hook, hooks, OBJC_ASSOCIATION_RETAIN );
    }
        
    [hooks setObject:h forKey:key];
}

void HKHookUnregister ( const char *hook, id object, id registrant )
{
    NSMutableDictionary *hooks = objc_getAssociatedObject( object, hook );
    NSString            *key = [NSString stringWithFormat:@"%s_%p", hook, registrant];
        
    if ( hooks == nil )
        return;
    
    [hooks removeObjectForKey:key];
}

void HKHookBroadcast ( const char *hook, id context, id broadcaster )
{
    NSDictionary    *hooks = objc_getAssociatedObject( broadcaster, hook );
    NSArray         *hvalues = [hooks allValues];
    HKHook          *h;
            
    if ( hvalues == nil )
        return;
    
    for ( h in hvalues )
    {
        dispatch_async( h.queue, ^{
            h.handler( context );
        });
    }
}
