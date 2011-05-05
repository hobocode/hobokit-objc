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

#import "HKSettingsController.h"

static HKSettingsController *gHKSettingsController = nil;

@interface HKSettingsController (HKPrivate)

- (void)setup;
- (void)load;
- (void)loadDefaultValues;

@end

@implementation HKSettingsController

#pragma mark HKSingleton

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if ( gHKSettingsController == nil )
        {
            gHKSettingsController = [super allocWithZone:zone];
            
            return gHKSettingsController;
        }
    }
    
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return UINT_MAX;
}

- (void)release
{
}

- (id)autorelease
{
    return self;
}

- (id)init
{
    if ( self = [super init] )
    {
        [self setup];
    }
    
    return self;
}

- (void)dealloc
{
#ifdef HK_DEBUG_DEALLOC
    NSLog(@"Dealloc: %@", self);
#endif
    [_definition release]; _definition = nil;
    [_settings release]; _settings = nil;
    [_callbacks release]; _callbacks = nil;
    [super dealloc];
}

#pragma mark HKPublic API

+ (HKSettingsController *)defaultController
{
    @synchronized ( self )
    {
        if ( gHKSettingsController == nil )
        {
            [[self alloc] init];
        }
    }
    
    return gHKSettingsController;
}

- (void)save
{
    NSMutableDictionary *settings;
    NSUserDefaults      *defaults = [NSUserDefaults standardUserDefaults];
    NSData              *sdata = nil;
    NSError             *error = nil;
    NSArray             *transformers = nil;
    NSValueTransformer  *transformer = nil;
    id                   name;
    id                   key;
    id                   value;
    id                   tvalue;
    
    @synchronized (self)
    {
        if ( _settings == nil )
        {
#ifdef HK_DEBUG_SETTINGS
            NSLog(@"HKSettingsController->Save: 'No settings available. Ignoring save.'");
#endif
            return;
        }
        
        settings = [NSMutableDictionary dictionaryWithDictionary:_settings];
    }
    
    transformers = [_definition objectForKey:HK_SETTINGS_DEFINITION_KEY_TRANSFORMERS];
        
    for ( NSDictionary *tinfo in transformers )
    {
        key = [tinfo objectForKey:HK_SETTINGS_DEFINITION_KEY_TRANSFORMER_KEY];
        
        if ( key == nil )
            continue;
        
        value = [settings objectForKey:key];
        
        if ( value == nil )
            continue;
        
        name = [tinfo objectForKey:HK_SETTINGS_DEFINITION_KEY_TRANSFORMER_NAME];
        
        if ( name == nil )
            continue;
        
        transformer = [NSValueTransformer valueTransformerForName:name];
        
        if ( transformer == nil )
            continue;
        
        tvalue = [transformer reverseTransformedValue:value];
        
        if ( tvalue == nil )
            continue;
        
        [settings setObject:tvalue forKey:key];
    }
    
    sdata = [NSPropertyListSerialization dataWithPropertyList:settings format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    
    if ( sdata == nil )
    {
#ifdef HK_DEBUG_SETTINGS
        NSLog(@"HKSettingsController->Error: '%@'", error);
#endif
        return;
    }
    
#ifdef HK_DEBUG_SETTINGS
    NSLog(@"HKSettingsController->Saved settings data size: %lu bytes", [sdata length] );
#endif
    
    [defaults setObject:sdata forKey:HK_USER_DEFAULTS_KEY_SETTINGS];
    [defaults synchronize];
}

- (void)restoreToDefaults
{
    @synchronized (self)
    {
        _settings = [[NSMutableDictionary alloc] init];
    }
    
    [self loadDefaultValues];
}

- (id)settingForKey:(id)key
{
    id value;
    
    @synchronized (self)
    {
        value = [_settings objectForKey:key];
    }
    
    return value;
}

- (void)setSetting:(id)setting forKey:(id)key
{
    @synchronized (self)
    {
        [_settings setObject:setting forKey:key];
    }
}

- (void)removeSettingForKey:(id)key
{
    @synchronized (self)
    {
        [_settings removeObjectForKey:key];
    }
}

- (id)addCallback:(HKSettingChangeCallback)callback forKey:(id)key
{
    NSDictionary *retval = nil;
    
    @synchronized (self)
    {
        NSMutableArray  *callbacks = nil;
        NSNumber        *identifier = nil;
        NSDictionary    *cinfo = nil;
        id               ccallback = nil;
        
        if ( (callbacks = [_callbacks objectForKey:key]) == nil )
        {
            callbacks = [NSMutableArray array];
            
            [_callbacks setObject:callbacks forKey:key];
        }
        
        ccallback = Block_copy( callback );
        identifier = [NSNumber numberWithUnsignedInteger:(NSUInteger) ccallback];
        cinfo = [NSDictionary dictionaryWithObjectsAndKeys:key, @"key", identifier, @"identifier", ccallback, @"callback", nil];
        
        [callbacks addObject:cinfo];
        [_settings addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
        
        retval = cinfo;
    }
    
    return retval;
}

- (void)removeCallbackForCallbackIdentifier:(id)identifier
{
    if ( ![identifier isKindOfClass:[NSDictionary class]] )
        return;
    
    id key = [identifier objectForKey:@"key"];
    
    if ( !key )
        return;
    
    id cidentifier = [identifier objectForKey:@"identifier"];
    
    if ( !cidentifier )
        return;
    
    NSMutableArray  *callbacks = nil;
    NSDictionary    *cinfo = nil;
    
    @synchronized (self)
    {
        if ( (callbacks = [_callbacks objectForKey:key]) != nil )
        {
            for ( cinfo in callbacks )
            {
                if ( [cidentifier isEqual:[cinfo objectForKey:@"identifier"]] )
                {
                    break;
                }
            }
            
            if ( cinfo != nil )
            {
                [callbacks removeObject:cinfo];
            }
        }
    }
}

- (void)switchToView:(NSString *)view
{
    id viewdef = [[_definition objectForKey:HK_SETTINGS_DEFINITION_KEY_VIEWS] objectForKey:view];
    
    if ( viewdef && viewdef != _view )
    {
        [_view release];
        _view = [viewdef retain];
    }
}

- (NSInteger)numberOfSections
{   
    return [[_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS] count];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    NSArray *sections = [_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS];
    
    if ( sections == nil || section < 0 || section >= [sections count] )
        return 0;
    
    NSArray *items = [[sections objectAtIndex:section] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEMS];
    
    return [items count];
}

- (NSString *)headerForSection:(NSInteger)section
{
    NSArray *sections = [_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS];
    
    if ( sections == nil || section < 0 || section >= [sections count] )
        return nil;
    
    return [NSString stringWithString:[[sections objectAtIndex:section] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_HEADER]];
}

- (NSString *)footerForSection:(NSInteger)section
{
    NSArray *sections = [_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS];
    
    if ( sections == nil || section < 0 || section >= [sections count] )
        return nil;
    
    return [NSString stringWithString:[[sections objectAtIndex:section] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_FOOTER]];
}

- (NSString *)titleForItem:(NSInteger)item inSection:(NSInteger)section
{
    NSArray *sections = [_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS];
    
    if ( sections == nil || section < 0 || section >= [sections count] )
        return nil;
    
    NSArray *items = [[sections objectAtIndex:section] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEMS];
    
    if ( items == nil || item < 0 || item >= [items count] )
        return nil;
    
    return [NSString stringWithString:[[items objectAtIndex:item] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_TITLE]];
}

- (HKSettingSectionItemType)typeForItem:(NSInteger)item inSection:(NSInteger)section
{
    NSArray *sections = [_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS];
    
    if ( sections == nil || section < 0 || section >= [sections count] )
        return kHKSettingSectionItemTypeUnknown;
    
    NSArray *items = [[sections objectAtIndex:section] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEMS];
    
    if ( items == nil || item < 0 || item >= [items count] )
        return kHKSettingSectionItemTypeUnknown;
    
    NSString *type = [[items objectAtIndex:item] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_TYPE];
    
    if ( type == nil )
        return kHKSettingSectionItemTypeUnknown;
    
    if ( [type isEqualToString:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_TYPE_STRING_FLAG] )
    {
        return kHKSettingSectionItemTypeFlag;
    }
    else if ( [type isEqualToString:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_TYPE_STRING_CUSTOM] )
    {
        return kHKSettingSectionItemTypeCustom;
    }
    else if ( [type isEqualToString:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_TYPE_STRING_OPTION] )
    {
        return kHKSettingSectionItemTypeOption;
    }
    
    return kHKSettingSectionItemTypeUnknown;
}

- (id)keyForItem:(NSInteger)item inSection:(NSInteger)section
{
    NSArray *sections = [_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS];
    
    if ( sections == nil || section < 0 || section >= [sections count] )
        return nil;
    
    NSArray *items = [[sections objectAtIndex:section] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEMS];
    
    if ( items == nil || item < 0 || item >= [items count] )
        return nil;
        
    return [[items objectAtIndex:item] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_KEY];
}

- (id)valueForItem:(NSInteger)item inSection:(NSInteger)section
{
    NSArray *sections = [_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS];
    
    if ( sections == nil || section < 0 || section >= [sections count] )
        return nil;
    
    NSArray *items = [[sections objectAtIndex:section] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEMS];
    
    if ( items == nil || item < 0 || item >= [items count] )
        return nil;
    
    return [[items objectAtIndex:item] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_VALUE];
}

- (SEL)actionForItem:(NSInteger)item inSection:(NSInteger)section
{
    NSArray *sections = [_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS];
    
    if ( sections == nil || section < 0 || section >= [sections count] )
        return nil;
    
    NSArray *items = [[sections objectAtIndex:section] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEMS];
    
    if ( items == nil || item < 0 || item >= [items count] )
        return nil;
    
    NSString *action = [[items objectAtIndex:item] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_ACTION];
    
    if ( action == nil )
        return nil;
    
    return NSSelectorFromString( action );
}

- (BOOL)enabledForItem:(NSInteger)item inSection:(NSInteger)section
{
    NSArray *sections = [_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS];
    
    if ( sections == nil || section < 0 || section >= [sections count] )
        return NO;
    
    NSArray *items = [[sections objectAtIndex:section] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEMS];
    
    if ( items == nil || item < 0 || item >= [items count] )
        return NO;
    
    NSArray *enabled = [[items objectAtIndex:item] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_ENABLED];
    BOOL     flag = YES;
    id       key;
    id       value;
    id       svalue;
    
    for ( NSDictionary *einfo in enabled )
    {
        key = [einfo objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_ENABLED_KEY];
        
        if ( key == nil )
            continue;
        
        value = [einfo objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_ITEM_ENABLED_VALUE];
        
        if ( value == nil )
            continue;
        
        svalue = [self settingForKey:key];
        
        flag = flag && ([value isEqual:svalue]);
    }
    
    return flag;
}

- (BOOL)sectionIsHidden:(NSInteger)section
{
    NSArray *sections = [_view objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTIONS];
    
    if ( sections == nil || section < 0 || section >= [sections count] )
        return YES;
    
    NSArray *hidden = [[sections objectAtIndex:section] objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_HIDDEN];
    
    if ( [hidden count] == 0 )
        return NO;
    
    BOOL     flag = YES;
    id       key;
    id       value;
    id       svalue;
    
    for ( NSDictionary *einfo in hidden )
    {
        key = [einfo objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_HIDDEN_KEY];
        
        if ( key == nil )
            continue;
        
        value = [einfo objectForKey:HK_SETTINGS_DEFINITION_KEY_SECTION_HIDDEN_VALUE];
        
        if ( value == nil )
            continue;
        
        svalue = [self settingForKey:key];
        
        flag = flag && ([value isEqual:svalue]);
    }
    
    return flag;
}

#pragma mark HKPrivate API

- (void)setup
{
    if ( _definition == nil )
    {
        _definition = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"HKSettings" ofType:@"plist"]];
    }
    
    if ( _callbacks == nil )
    {
        _callbacks = [[NSMutableDictionary alloc] init];
    }
    
    [self load];
    [self loadDefaultValues];
}

- (void)load
{
    NSUserDefaults  *defaults = [NSUserDefaults standardUserDefaults];
    NSData          *sdata = [defaults objectForKey:HK_USER_DEFAULTS_KEY_SETTINGS];
    
    if ( sdata == nil )
    {
#ifdef HK_DEBUG_SETTINGS
        NSLog(@"HKSettingsController->Load: 'No settings found in user defaults. Creating a new settings dictionary.'");
#endif
        @synchronized (self)
        {
            _settings = [[NSMutableDictionary alloc] init];
        }
        
        return;
    }
    
    NSMutableDictionary *settings = nil;
    NSError             *error = nil;
    
    settings = (NSMutableDictionary *) [NSPropertyListSerialization propertyListWithData:sdata options:NSPropertyListMutableContainers format:NULL error:&error];
    
    if ( settings == nil )
    {
#ifdef HK_DEBUG_SETTINGS
        NSLog(@"HKSettingsController->Error: '%@'", error);
#endif
        @synchronized (self)
        {
            _settings = [[NSMutableDictionary alloc] init];
        }
    }
    else
    {
        NSArray             *transformers = nil;
        NSValueTransformer  *transformer = nil;
        id                   name;
        id                   key;
        id                   value;
        id                   tvalue;
        
        transformers = [_definition objectForKey:HK_SETTINGS_DEFINITION_KEY_TRANSFORMERS];
        
        for ( NSDictionary *tinfo in transformers )
        {
            key = [tinfo objectForKey:HK_SETTINGS_DEFINITION_KEY_TRANSFORMER_KEY];
            
            if ( key == nil )
                continue;
            
            value = [settings objectForKey:key];
            
            if ( value == nil )
                continue;
            
            name = [tinfo objectForKey:HK_SETTINGS_DEFINITION_KEY_TRANSFORMER_NAME];
            
            if ( name == nil )
                continue;
            
            transformer = [NSValueTransformer valueTransformerForName:name];
            
            if ( transformer == nil )
                continue;
            
            tvalue = [transformer transformedValue:value];
            
            if ( tvalue == nil )
                continue;
            
            [settings setObject:tvalue forKey:key];
        }
        
        @synchronized (self)
        {
            _settings = [settings retain];
        }
    }
}

- (void)loadDefaultValues
{
    if ( _definition != nil )
    {
        id key, value;
        
        for ( NSDictionary *dvalue in [_definition objectForKey:HK_SETTINGS_DEFINITION_KEY_DEFAULT_VALUES] )
        {
            key = [dvalue objectForKey:HK_SETTINGS_DEFINITION_KEY_DEFAULT_VALUE_KEY];
            
            if ( key )
            {
                value = [self settingForKey:key];
                
                if ( value == nil )
                {
                    value = [dvalue objectForKey:HK_SETTINGS_DEFINITION_KEY_DEFAULT_VALUE_VALUE];
                    
                    if ( value != nil )
                    {
                        [self setSetting:value forKey:key];
                    }
                }
            }
        }
    }
}

#pragma mark Observation

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSArray                 *callbacks = nil;
    HKSettingChangeCallback  callback = nil;
    
    @synchronized (self)
    {
        callbacks = [_callbacks objectForKey:keyPath];
        
        if ( callbacks == nil )
            return;
                
        for ( NSDictionary *cinfo in callbacks )
        {
            if ( (callback = [cinfo objectForKey:@"callback"]) )
            {
                callback( keyPath, [change objectForKey:NSKeyValueChangeNewKey], [change objectForKey:NSKeyValueChangeOldKey] );
            }
        }
    }
}

@end
