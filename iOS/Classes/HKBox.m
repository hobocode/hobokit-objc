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

#import "HKBox.h"

@interface HKBox (HKPrivate)

@end

@implementation HKBox

@synthesize type = _type, horizontalAlign = _horizontalAlign, verticalAlign = _verticalAlign;

- (id)initWithFrame:(CGRect)frame type:(HKBoxType)type
{
    if ( self = [super initWithFrame:frame] )
    {
        _type = type;
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)layoutSubviews
{
    _update = YES;
    
    CGRect  bounds = [self bounds];
    CGFloat xoffset = 0.0f;
    CGFloat yoffset = 0.0f;
    CGFloat wmax = 0.0f;
    CGFloat hmax = 0.0f;
    
    for ( UIView *view in [self subviews] )
    {
        switch ( _type )
        {
            case kHKBoxTypeHorizontal:
                wmax += view.frame.size.width;
                hmax = MAX( hmax, view.frame.size.height );
                break;
                
            case kHKBoxTypeVertical:
                wmax = MAX( wmax, view.frame.size.width );
                hmax += view.frame.size.height;
                break;
        }
    }
    
    switch ( _type )
    {
        case kHKBoxTypeHorizontal:
        {
            switch ( _horizontalAlign )
            {
                case kHKBoxHorizontalAlignmentLeft:
                    xoffset = 0.0;
                    break;
                    
                case kHKBoxHorizontalAlignmentCenter:
                    xoffset = (bounds.size.width - wmax) / 2.0f;
                    break;
                    
                case kHKBoxHorizontalAlignmentRight:
                    xoffset = (bounds.size.width - wmax);
                    break;
            }
        }
            break;
            
        case kHKBoxTypeVertical:
        {
            switch ( _verticalAlign )
            {
                case kHKBoxVerticalAlignmentTop:
                    yoffset = 0.0;
                    break;
                    
                case kHKBoxVerticalAlignmentMiddle:
                    yoffset = (bounds.size.height - hmax) / 2.0f;
                    break;
                    
                case kHKBoxVerticalAlignmentBottom:
                    yoffset = (bounds.size.height - hmax);
                    break;
            }
        }
            break;
    }
    
    for ( UIView *view in [self subviews] )
    {
        switch ( _type )
        {
            case kHKBoxTypeHorizontal:
            {
                switch ( _verticalAlign )
                {
                    case kHKBoxVerticalAlignmentTop:
                        yoffset = 0.0;
                        break;
                        
                    case kHKBoxVerticalAlignmentMiddle:
                        yoffset = (bounds.size.height - view.frame.size.height) / 2.0f;
                        break;
                        
                    case kHKBoxVerticalAlignmentBottom:
                        yoffset = (bounds.size.height - view.frame.size.height);
                        break;
                }
                
                view.frame = CGRectMake( xoffset, yoffset, view.frame.size.width, view.frame.size.height );
            
                xoffset += view.frame.size.width;
            }
                break;
                
            case kHKBoxTypeVertical:
            {
                switch ( _horizontalAlign )
                {
                    case kHKBoxHorizontalAlignmentLeft:
                        xoffset = 0.0;
                        break;
                        
                    case kHKBoxHorizontalAlignmentCenter:
                        xoffset = (bounds.size.width - view.frame.size.width) / 2.0f;
                        break;
                        
                    case kHKBoxHorizontalAlignmentRight:
                        xoffset = (bounds.size.width - view.frame.size.width);
                        break;
                }
                
                view.frame = CGRectMake( xoffset, yoffset, view.frame.size.width, view.frame.size.height );
                
                yoffset += view.frame.size.height;
            }
                break;
        }
    }
    
    _update = NO;
}

- (void)didAddSubview:(UIView *)subview
{
    $depends( @"view_frame", subview, @"frame", ^{
        if ( _update )
            return;
        
        [selff setNeedsLayout];
    });
}

- (void)willRemoveSubview:(UIView *)subview
{
    SPRemoveAssociatedDependencies( subview );
    
    [self setNeedsLayout];
}

@end
