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

#ifdef HK_DEBUG
# define HK_DEBUG_SETTINGS
#endif

#define HK_USER_DEFAULTS_KEY_SETTINGS											@"HKUserDefaultsKeySettings"

#define HK_SETTINGS_DEFINITION_KEY_DEFAULT_VALUES								@"HKSettingDefaultValues"
#define HK_SETTINGS_DEFINITION_KEY_DEFAULT_VALUE_KEY							@"HKSettingDefaultValueKey"
#define HK_SETTINGS_DEFINITION_KEY_DEFAULT_VALUE_VALUE							@"HKSettingDefaultValueValue"

#define HK_SETTINGS_DEFINITION_KEY_VIEWS										@"HKSettingViews"
#define HK_SETTINGS_DEFINITION_KEY_SECTIONS										@"HKSettingSections"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEMS								@"HKSettingSectionItems"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_HEADER								@"HKSettingSectionHeader"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_FOOTER								@"HKSettingSectionFooter"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_HIDDEN                               @"HKSettingSectionHidden"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_HIDDEN_KEY                           @"HKSettingSectionHiddenKey"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_HIDDEN_VALUE                         @"HKSettingSectionHiddenValue"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_TITLE							@"HKSettingSectionItemTitle"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_ACTION							@"HKSettingSectionItemAction"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_KEY                             @"HKSettingSectionItemKey"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_VALUE                           @"HKSettingSectionItemValue"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_TYPE							@"HKSettingSectionItemType"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_TYPE_STRING_FLAG				@"HKSettingSectionItemTypeFlag"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_TYPE_STRING_CUSTOM				@"HKSettingSectionItemTypeCustom"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_TYPE_STRING_OPTION				@"HKSettingSectionItemTypeOption"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_ENABLED                         @"HKSettingSectionItemEnabled"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_ENABLED_KEY                     @"HKSettingSectionItemEnabledKey"
#define HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_ENABLED_VALUE                   @"HKSettingSectionItemEnabledValue"

#define HK_SETTINGS_DEFINITION_KEY_TRANSFORMERS                                 @"HKSettingTransformers"
#define HK_SETTINGS_DEFINITION_KEY_TRANSFORMER_KEY                              @"HKSettingTransformerKey"
#define HK_SETTINGS_DEFINITION_KEY_TRANSFORMER_NAME                             @"HKSettingTransformerName"

typedef enum
{
	kHKSettingSectionItemTypeUnknown,
	kHKSettingSectionItemTypeFlag,
	kHKSettingSectionItemTypeCustom,
	kHKSettingSectionItemTypeOption,
} HKSettingSectionItemType;

typedef void (^HKSettingChangeCallback)( id key, id newvalue, id oldvalue );

@interface HKSettingsController : NSObject
{
@private
	NSDictionary		*_definition;
	NSDictionary		*_view;
	NSMutableDictionary *_settings;
    NSMutableDictionary *_callbacks;
}

@end

@interface HKSettingsController (HKPublic)

+ (HKSettingsController *)defaultController;

- (void)save;

- (void)restoreToDefaults;

- (id)settingForKey:(id)key;
- (void)setSetting:(id)setting forKey:(id)key;
- (void)removeSettingForKey:(id)key;

- (id)addCallback:(HKSettingChangeCallback)callback forKey:(id)key;
- (void)removeCallbackForCallbackIdentifier:(id)identifier;

- (void)switchToView:(NSString *)view;

- (NSInteger)numberOfSections;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (NSString *)headerForSection:(NSInteger)section;
- (NSString *)footerForSection:(NSInteger)section;
- (NSString *)titleForItem:(NSInteger)item inSection:(NSInteger)section;
- (HKSettingSectionItemType)typeForItem:(NSInteger)item inSection:(NSInteger)section;
- (id)keyForItem:(NSInteger)item inSection:(NSInteger)section;
- (id)valueForItem:(NSInteger)item inSection:(NSInteger)section;
- (SEL)actionForItem:(NSInteger)item inSection:(NSInteger)section;
- (BOOL)enabledForItem:(NSInteger)item inSection:(NSInteger)section;
- (BOOL)sectionIsHidden:(NSInteger)section;

@end