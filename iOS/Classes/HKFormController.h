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

#define HK_FORM_TVC_IDENTIFIER                              @"HKFormTableViewCellIdentifier"

#define HK_FORM_NOTIFICATION_DONE_EDITING                   @"HKFormNotificationDoneEditing"
#define HK_FORM_NOTIFICATION_CANCELED_EDITING               @"HKFormNotificationCanceledEditing"

#define HK_FORM_TAG_OFFSET                                  300

@interface HKFormController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIScrollViewDelegate>
{
 @private
    id              _model;
    NSDictionary    *_definition;
    UITableView     *_tableView;
    UITextField     *_currentTextField;
    CGRect          _currentKeyboardFrame;
}

@property (retain) id model;
@property (retain) NSDictionary *definition;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (retain) UITextField *currentTextField;
@property (assign) CGRect currentKeyboardFrame;

+ (UINavigationController *)formNavigationControllerWithModel:(id)model definition:(NSDictionary *)definition;

- (id)initWithModel:(id)model definition:(NSDictionary *)definition;

- (IBAction)handleDone:(id)sender;

@end
