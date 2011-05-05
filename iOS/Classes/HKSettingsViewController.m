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

#import "HKSettingsViewController.h"

@interface HKSettingsViewController (HKPrivate)

- (void)setup;

- (UISwitch *)createNewSettingSwitchWithInitialOn:(BOOL)initialOn enabled:(BOOL)enabled forItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface HKSettingsViewController (HKActions)

- (IBAction)switchValueChanged:(id)sender;

@end

@implementation HKSettingsViewController

- (void)dealloc
{
#ifdef HK_DEBUG_DEALLOC
    NSLog(@"Dealloc: %@", self);
#endif
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

#pragma mark HKPrivate API

- (void)setup
{
    self.title = NSLocalizedString( @"Settings", @"Settings view title" );
}

- (UISwitch *)createNewSettingSwitchWithInitialOn:(BOOL)initialOn enabled:(BOOL)enabled forItemAtIndexPath:(NSIndexPath *)indexPath
{
    UISwitch    *swtch = [[UISwitch alloc] initWithFrame:CGRectZero];
    NSInteger   tag = (indexPath.section * 1000) + indexPath.row; 
    
    [swtch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    [swtch setOn:initialOn];
    [swtch setEnabled:enabled];
    [swtch setTag:tag];
    
#ifdef HK_DEBUG_SETTINGS_VIEW_EVENTS
    NSLog(@"HKSettingsViewController->Created switch with tag: %d", tag);
#endif
    
    return [swtch autorelease];
}

#pragma mark HKActions API

- (IBAction)switchValueChanged:(id)sender;
{
#ifdef HK_DEBUG_SETTINGS_VIEW_EVENTS
    NSLog(@"HKSettingsViewController->switchValueChanged:");
#endif
    
    UISwitch    *swtch = (UISwitch *) sender;
    NSInteger   tag = [swtch tag];
    NSInteger   section = (tag / 1000);
    NSInteger   row = tag - (section * 1000);
    
    id key = [[HKSettingsController defaultController] keyForItem:row inSection:section];
    
    [[HKSettingsController defaultController] setSetting:[NSNumber numberWithBool:[swtch isOn]] forKey:key];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( [[HKSettingsController defaultController] enabledForItem:indexPath.row inSection:indexPath.section] )
    {    
        switch ( [[HKSettingsController defaultController] typeForItem:indexPath.row inSection:indexPath.section] )
        {
            case kHKSettingSectionItemTypeFlag:
                break;
                
            case kHKSettingSectionItemTypeCustom:
            {
                id  target = self;
                SEL action = [[HKSettingsController defaultController] actionForItem:indexPath.row inSection:indexPath.section];
                
                if ( target && action )
                {
                    [target performSelector:action withObject:self];
                }
                
                break;
            }
                
            case kHKSettingSectionItemTypeOption:
            {
                id key = [[HKSettingsController defaultController] keyForItem:indexPath.row inSection:indexPath.section];
                id value = [[HKSettingsController defaultController] valueForItem:indexPath.row inSection:indexPath.section];
                
                [[HKSettingsController defaultController] setSetting:value forKey:key];
                
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
            }
                break;
                
            default:
                break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( [[HKSettingsController defaultController] sectionIsHidden:indexPath.section] )
    {
        return -22.0;
    }
    
    return 44.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( [[HKSettingsController defaultController] sectionIsHidden:indexPath.section] )
    {
        cell.alpha = 0.0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[HKSettingsController defaultController] numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[HKSettingsController defaultController] numberOfItemsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( [[HKSettingsController defaultController] sectionIsHidden:section] )
    {
        return nil;
    }
    
    return NSLocalizedString( [[HKSettingsController defaultController] headerForSection:section], @"" );
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedString( [[HKSettingsController defaultController] footerForSection:section], @"" );
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HK_TABLE_VIEW_CELL_IDENTIFIER_SETTINGS];
    NSString        *ctitle = nil;
    
    if ( cell == nil )
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:HK_TABLE_VIEW_CELL_IDENTIFIER_SETTINGS] autorelease];
    }
    
    id      key = [[HKSettingsController defaultController] keyForItem:indexPath.row inSection:indexPath.section];
    id      value = [[HKSettingsController defaultController] valueForItem:indexPath.row inSection:indexPath.section];
    id      svalue = [[HKSettingsController defaultController] settingForKey:key];
    BOOL    enabled = [[HKSettingsController defaultController] enabledForItem:indexPath.row inSection:indexPath.section];
    
    switch ( [[HKSettingsController defaultController] typeForItem:indexPath.row inSection:indexPath.section] )
    {
        case kHKSettingSectionItemTypeFlag:
            cell.accessoryView = [self createNewSettingSwitchWithInitialOn:[svalue boolValue] enabled:enabled forItemAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textAlignment = UITextAlignmentLeft;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.enabled = enabled;
            cell.selectionStyle = ( enabled ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone );
            break;
            
        case kHKSettingSectionItemTypeCustom:
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.textColor = HK_COLOR_IPHONE_BLUE;
            cell.textLabel.enabled = enabled;
            cell.selectionStyle = ( enabled ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone );
            break;
            
        case kHKSettingSectionItemTypeOption:
            cell.accessoryView = nil;
            cell.accessoryType = ( [value isEqual:svalue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone );
            cell.textLabel.textAlignment = UITextAlignmentLeft;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.enabled = enabled;
            cell.selectionStyle = ( enabled ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone );
            break;
            
        default:
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textAlignment = UITextAlignmentLeft;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.enabled = enabled;
            cell.selectionStyle = ( enabled ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone );
            break;
    }
    
    ctitle = [[HKSettingsController defaultController] titleForItem:indexPath.row inSection:indexPath.section];
    
    cell.textLabel.text = NSLocalizedString( ctitle, @"" );
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    return cell;
}

@end
