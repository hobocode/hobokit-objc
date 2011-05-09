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

#import "HKFormTableViewCell.h"

@implementation HKFormTableViewCell

@synthesize formLabel = _formLabel, formField = _formField, formSeparator = _formSeparator;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ( self = [super initWithStyle:style reuseIdentifier:reuseIdentifier] )
	{
		CGRect fsf = CGRectMake( HK_FORM_TVC_FORM_SEPARATOR_X_OFFSET, 0.0, 1.0, self.contentView.bounds.size.height );
		CGRect flf = CGRectMake( HK_FORM_TVC_FORM_LABEL_X_OFFSET, (self.contentView.bounds.size.height - 16.0) / 2.0, HK_FORM_TVC_FORM_LABEL_WIDTH, 16.0 );
		CGRect fff = CGRectMake( HK_FORM_TVC_FORM_FIELD_X_OFFSET, HK_FORM_TVC_FORM_FIELD_Y_OFFSET + (self.contentView.bounds.size.height - 20.0) / 2.0, self.contentView.bounds.size.width - HK_FORM_TVC_FORM_FIELD_X_OFFSET, 20.0 );
		
		self.formSeparator = [[[UIView alloc] initWithFrame:fsf] autorelease];
		self.formSeparator.backgroundColor = [UIColor lightGrayColor];
		
		self.formLabel = [[[UILabel alloc] initWithFrame:flf] autorelease];
		self.formLabel.textAlignment = UITextAlignmentRight;
		self.formLabel.textColor = [UIColor colorWithRed:(56.0 / 255.0) green:(77.0 / 255.0) blue:(130.0 / 255.0) alpha:1.0];
		self.formLabel.backgroundColor = [UIColor clearColor];
		self.formLabel.font = [UIFont boldSystemFontOfSize:14.0];
		self.formLabel.numberOfLines = 0;
		self.formLabel.lineBreakMode = UILineBreakModeWordWrap;
		
		self.formField = [[[UITextField alloc] initWithFrame:fff] autorelease];
		self.formField.font = [UIFont boldSystemFontOfSize:14.0];
		self.formField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		
		[self.contentView addSubview:self.formLabel];
		[self.contentView addSubview:self.formSeparator];
		[self.contentView addSubview:self.formField];
    }
	
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
	
	if ( selected )
	{
		[self.formField becomeFirstResponder];
	}
}

- (void)dealloc
{
	[_formLabel release]; _formLabel = nil;
	[_formField release]; _formField = nil;
	[_formSeparator release]; _formSeparator = nil;
    [super dealloc];
}


@end
