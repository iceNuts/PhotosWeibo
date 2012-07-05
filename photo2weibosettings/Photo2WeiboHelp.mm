
@interface PSListController{
    NSArray *_specifiers;
}
- (id)loadSpecifiersFromPlistName:(id)arg1 target:(id)arg2;
- (void)removeSpecifierAtIndex:(int)arg1 animated:(BOOL)arg2;
- (void)removeSpecifierAtIndex:(int)arg1;
- (void)removeSpecifierID:(id)arg1 animated:(BOOL)arg2;
- (void)beginUpdates;
- (void)endUpdates;
- (void)reloadSpecifiers;
- (void)reloadSpecifierAtIndex:(int)arg1 animated:(BOOL)arg2;
- (void)reloadSpecifierID:(id)arg1 animated:(BOOL)arg2;
- (int)indexOfSpecifierID:(id)arg1;
- (id)specifierAtIndex:(int)arg1;

@end

@interface PSSpecifier
@property(retain, nonatomic) NSDictionary *shortTitleDictionary; // @synthesize shortTitleDictionary=_shortTitleDict;
@property(retain, nonatomic) NSString *identifier;
@property(retain, nonatomic) NSString *name; // @synthesize name=_name;
@property(retain, nonatomic) NSArray *values; // @synthesize values=_values;
@property(retain, nonatomic) NSDictionary *titleDictionary; // @synthesize titleDictionary=_titleDict;
@property(retain, nonatomic) id userInfo; // @synthesize userInfo=_userInfo;
@end

@interface Photo2WeiboSettingsHelp: PSListController
@end

@implementation Photo2WeiboSettingsHelp
- (id)specifiers
{
    if (_specifiers == nil)
    {
        _specifiers = [[self loadSpecifiersFromPlistName:@"Photo2WeiboHelp" target:self] retain];
    }
    return _specifiers;
}
@end




