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

#import <UIKit/UIKit.h>

#define HK_FORM_TVC_FORM_LABEL_WIDTH						100.0
#define HK_FORM_TVC_FORM_LABEL_X_OFFSET						10.0
#define HK_FORM_TVC_FORM_FIELD_X_OFFSET						130.0
#define HK_FORM_TVC_FORM_FIELD_Y_OFFSET						1.0
#define HK_FORM_TVC_FORM_SEPARATOR_X_OFFSET					120.0

@interface HKFormTableViewCell : UITableViewCell <UITextFieldDelegate>
{
 @private
	UILabel		*_formLabel;
	UITextField	*_formField;
	UIView		*_formSeparator;
}

@property (retain) UILabel *formLabel;
@property (retain) UITextField *formField;
@property (retain) UIView *formSeparator;

@end
