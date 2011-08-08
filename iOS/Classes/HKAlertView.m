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

#import "HKAlertView.h"

@implementation HKAlertView

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
    if ( self = [self init] )
    {
        [self setTitle:title];
        [self setMessage:message];
    }

    return self;
}

- (id)init
{
    if ( self = [super init] )
    {
        self.delegate = self;
    }

    return self;
}

- (void)dealloc
{
    [_buttonHandlers release];

    [_cancelHandler release];
    [_willPresentHandler release];
    [_didPresentHandler release];
    [_willDismissHandler release];
    [_didDismissHandler release];

    [super dealloc];
}

#pragma mark Buttons

- (void)addButtonWithTitle:(NSString *)title clickedHandler:(void(^)(HKAlertView *))handler
{
    if ( !_buttonHandlers )
    {
        _buttonHandlers = [[NSMutableDictionary alloc] init];
    }

    [_buttonHandlers setObject:Block_copy( handler ) forKey:[NSNumber numberWithInt:[self numberOfButtons]]];
    [self addButtonWithTitle:title];
}

- (void)addCancelButtonWithTitle:(NSString *)title clickedHandler:(void(^)(HKAlertView *))handler
{
    if ( _cancelHandler )
    {
        Block_release( _cancelHandler );
    }

    _cancelHandler = Block_copy( handler );

    [self addButtonWithTitle:title];
    self.cancelButtonIndex = [self numberOfButtons]-1;
}


#pragma mark Handlers

- (void)setWillDismissHandler:(void(^)(HKAlertView *, NSInteger))handler
{
    if ( _willDismissHandler )
    {
        Block_release( _willDismissHandler );
    }

    _willDismissHandler = Block_copy( handler );
}

- (void)setAlertViewDidDismissWithButtonIndexBlock:(void(^)(HKAlertView *, NSInteger))handler
{
    if ( _didDismissHandler )
    {
        Block_release( _didDismissHandler );
    }

    _didDismissHandler = Block_copy( handler );
}

- (void)setWillPresentHandler:(void(^)(HKAlertView *))handler
{
    if ( _willPresentHandler )
    {
        Block_release( _willPresentHandler );
    }

    _willPresentHandler = Block_copy( handler );
}

- (void)setDidPresentHandler:(void(^)(HKAlertView *))handler
{
    if ( _didPresentHandler )
    {
        Block_release( _didPresentHandler );
    }

    _didPresentHandler = Block_copy( handler );
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == self.cancelButtonIndex )
    {
        if ( _cancelHandler )
        {
            _cancelHandler( self );
        }
    }
    else
    {
        void (^handler)(HKAlertView *) = [_buttonHandlers objectForKey:[NSNumber numberWithInt:buttonIndex]];

        if ( handler )
        {
            handler( (HKAlertView *)alertView );
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ( _didDismissHandler )
    {
        _didDismissHandler( (HKAlertView *)alertView, buttonIndex );
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ( _willDismissHandler )
    {
        _willDismissHandler( (HKAlertView *)alertView, buttonIndex );
    }
}

- (void)didPresentAlertView:(UIAlertView *)alertView
{
    if ( _didPresentHandler )
    {
        _didPresentHandler( (HKAlertView *)alertView );
    }
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    if ( _willPresentHandler )
    {
        _willPresentHandler( (HKAlertView *)alertView );
    }
}

@end
