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

#import "HKFormController.h"

#import "HKFormTableViewCell.h"

@interface HKFormController (Private)

- (HKFormTableViewCell *)cellWithTextField:(UITextField *)textField;

- (void)updateModel;
- (void)ensureTableViewVisible;
- (void)ensureTableViewCellVisible:(UITableViewCell *)tableViewCell;

@end

@implementation HKFormController

+ (UINavigationController *)formNavigationControllerWithModel:(id)model definition:(NSDictionary *)definition
{
    HKFormController        *fc = [[[HKFormController alloc] initWithModel:model definition:definition] autorelease];
    UINavigationController  *rnc = [[[UINavigationController alloc] initWithRootViewController:fc] autorelease];
    
    rnc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    return rnc;
}

@synthesize model = _model, definition = _definition, tableView = _tableView, currentTextField = _currentTextField, currentKeyboardFrame = _currentKeyboardFrame;

- (id)initWithModel:(id)model definition:(NSDictionary *)definition
{
    if ( self = [super initWithNibName:@"Form" bundle:nil] )
    {
        self.model = model;
        self.definition = definition;
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_model release]; _model = nil;
    [_definition release]; _definition = nil;
    [_tableView release]; _tableView = nil;
    [_currentTextField release]; _currentTextField = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupEnclosingNavigationController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)setupEnclosingNavigationController
{    
    self.title = [self.definition objectForKey:@"title"];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self
                                                                                            action:@selector(handleDone:)] autorelease];
    
    if ( [self.navigationController.viewControllers count] == 1 )
    {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                               target:self
                                                                                               action:@selector(handleCancel:)] autorelease];
    }
}

- (NSString *)localize:(NSString *)string
{
    return NSLocalizedString(string, @"");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark Private API

- (HKFormTableViewCell *)cellWithTextField:(UITextField *)textField
{
    UIView *sview = [textField superview];
    
    while ( sview && ![sview isKindOfClass:[HKFormTableViewCell class]] )
    {
        sview = [sview superview];
    }
    
    return (HKFormTableViewCell *) sview;
}

- (void)updateModel
{
    if ( self.currentTextField )
    {
        NSInteger tag = self.currentTextField.tag - HK_FORM_TAG_OFFSET;
        NSInteger stag = tag / 1000;
        NSInteger rtag = tag - (stag * 1000);
        
        if ( stag < [[self.definition objectForKey:@"sections"] count] )
        {
            if ( rtag < [[[[self.definition objectForKey:@"sections"] objectAtIndex:stag] objectForKey:@"children"] count] )
            {
                NSDictionary *child = [[[[self.definition objectForKey:@"sections"] objectAtIndex:stag] objectForKey:@"children"] objectAtIndex:rtag];
                
                if ( child )
                {
                    NSString *key = [child objectForKey:@"key"];
                    
                    if ( key )
                    {
                        if ( [self.currentTextField.text isEqualToString:@""] )
                        {
                            [self.model setValue:nil forKeyPath:key];
                        }
                        else
                        {
                            [self.model setValue:self.currentTextField.text forKeyPath:key];
                        }
                    }
                }
            }
        }
    }
}

- (void)ensureTableViewVisible
{
    CGRect tframe = self.tableView.frame;
    CGRect kframe = [self.view convertRect:self.currentKeyboardFrame fromView:nil];
    CGRect intersect = CGRectIntersection( tframe, kframe );
        
    if ( CGRectIsNull( intersect ) )
        return;
    
    self.tableView.contentInset = UIEdgeInsetsMake( 0.0, 0.0, intersect.size.height, 0.0 );
}

- (void)ensureTableViewCellVisible:(UITableViewCell *)tableViewCell
{
    if ( tableViewCell == nil )
        return;
    
    [self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForCell:tableViewCell] atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

- (BOOL)ensureRequiredFieldsFilled
{
    UITextField *field;
    NSString    *title = nil;
    NSInteger   section = 0, row = 0;
    BOOL        filled = YES;
    
    for ( NSDictionary *sectionInfo in [self.definition objectForKey:@"sections"] )
    {
        for ( NSDictionary *childInfo in [sectionInfo objectForKey:@"children"] )
        {
            if ( [[childInfo objectForKey:@"required"] boolValue] )
            {
                NSString *key = [childInfo objectForKey:@"key"];
                
                if ( key )
                {
                    id value = [self.model valueForKey:key];
                    
                    if ( value == nil )
                    {
                        title = [childInfo objectForKey:@"title"];
                        
                        filled = NO;
                        
                        break;
                    }
                }
            }
            
            row += 1;
        }
        
        if ( filled == NO )
            break;
        
        section += 1;
        row = 0;
    }
    
    if ( filled == NO )
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[self localize:@"Required field"]
                                                            message:[NSString stringWithFormat:[self localize:@"'%@' is required."], [self localize:title]]
                                                           delegate:nil
                                                  cancelButtonTitle:[self localize:@"OK"]
                                                  otherButtonTitles:nil];
        NSInteger   tag = ( HK_FORM_TAG_OFFSET + section * 1000 + row );

        [alertView show];
        
        while ( alertView.visible && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]] )
        {
        }
        
        [alertView release];
                
        field = (UITextField *) [self.view viewWithTag:tag];
        
        if ( field )
        {
            [field becomeFirstResponder];
        }
    }
    
    return filled;
}

#pragma mark Actions

- (IBAction)handleDone:(id)sender
{
    if ( self.currentTextField )
    {
        [self.currentTextField resignFirstResponder];
    }
    
    if ( [self ensureRequiredFieldsFilled] )
    {
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    
        [[NSNotificationCenter defaultCenter] postNotificationName:HK_FORM_NOTIFICATION_DONE_EDITING object:self];
    }
}

- (IBAction)handleCancel:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HK_FORM_NOTIFICATION_CANCELED_EDITING object:self];
}

#pragma mark Notifications

- (void)keyboardDidShowNotification:(NSNotification *)notification
{
    NSDictionary *ui = [notification userInfo];
    
    if ( ui )
    {
        NSValue *rvalue = [ui objectForKey:UIKeyboardFrameEndUserInfoKey];
        
        if ( rvalue )
        {
            self.currentKeyboardFrame = [rvalue CGRectValue];
        }
    }
    
    [self ensureTableViewVisible];
    [self ensureTableViewCellVisible:[self cellWithTextField:self.currentTextField]];
}

#pragma mark UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{    
    self.currentTextField = textField;
    
    [self ensureTableViewCellVisible:[self cellWithTextField:self.currentTextField]];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{    
    [self updateModel];
}

#pragma mark UITableViewDelegate & DataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.definition objectForKey:@"sections"] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return [[[[self.definition objectForKey:@"sections"] objectAtIndex:section] objectForKey:@"children"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self localize:[[[self.definition objectForKey:@"sections"] objectAtIndex:section] objectForKey:@"header"]];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [self localize:[[[self.definition objectForKey:@"sections"] objectAtIndex:section] objectForKey:@"footer"]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HKFormTableViewCell *cell = (HKFormTableViewCell *) [tableView dequeueReusableCellWithIdentifier:HK_FORM_TVC_IDENTIFIER];
    NSDictionary        *child = [[[[self.definition objectForKey:@"sections"] objectAtIndex:indexPath.section] objectForKey:@"children"] objectAtIndex:indexPath.row];
    NSInteger           tag = ( HK_FORM_TAG_OFFSET + indexPath.section * 1000 + indexPath.row );
    BOOL                required = [[child objectForKey:@"required"] boolValue];
    
    if ( cell == nil )
    {
        cell = [[[HKFormTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:HK_FORM_TVC_IDENTIFIER] autorelease];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.formLabel.text = [[self localize:[child objectForKey:@"title"]] lowercaseString];
    
    cell.formField.placeholder = [NSString stringWithFormat:@"%@%@%@", [self localize:[child objectForKey:@"placeholder"]], ( required ? @"" : @" " ), ( required ? @"" : [self localize:@"(optional)"] )];
    
    if ( [[child objectForKey:@"type"] isEqualToString:@"secure"] )
    {
        cell.formField.secureTextEntry = YES;
    }
    else
    {
        cell.formField.secureTextEntry = NO;
    }
    
    if ( [[child objectForKey:@"keyboard"] isEqualToString:@"email"] )
    {
        cell.formField.keyboardType = UIKeyboardTypeEmailAddress;
        cell.formField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
    else if ( [[child objectForKey:@"keyboard"] isEqualToString:@"phone"] )
    {
        cell.formField.keyboardType = UIKeyboardTypePhonePad;
    }
    else
    {
        cell.formField.keyboardType = UIKeyboardTypeASCIICapable;
    }
    
    cell.formField.text = [self.model valueForKey:[child objectForKey:@"key"]];
    
    cell.formField.delegate = self;
    cell.formField.tag = tag;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

