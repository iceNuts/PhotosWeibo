#import "../WBEngine.h"
#import "../SinaWeiBoGetFriendslist.h"

//API key
#define AppKey @"972468350"
#define AppSecret @"a0aaeb3074a4ed4e0aa493c34084e046"

#define iPadKey @"1060116038"
#define iPadSecret @"26e38ca8fbbcc6ad235b04d72b03709a"

@interface CPDistributedMessagingCenter
+ (id)centerNamed:(id)arg1;
- (BOOL)sendMessageName:(id)arg1 userInfo:(id)arg2;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(id)arg1 target:(id)arg2 selector:(SEL)arg3;
@end

static id authEngine;

@interface PSSpecifier
@property(retain, nonatomic) NSDictionary *shortTitleDictionary; // @synthesize shortTitleDictionary=_shortTitleDict;
@property(retain, nonatomic) NSString *identifier;
@property(retain, nonatomic) NSString *name; // @synthesize name=_name;
@property(retain, nonatomic) NSArray *values; // @synthesize values=_values;
@property(retain, nonatomic) NSDictionary *titleDictionary; // @synthesize titleDictionary=_titleDict;
@property(retain, nonatomic) id userInfo; // @synthesize userInfo=_userInfo;
@end

@interface Photo2WeiboSettingsListController: PSListController
@end

@implementation Photo2WeiboSettingsListController
- (id)specifiers
{
    [authEngine setDelegate: self];
    if (_specifiers == nil)
    {
        _specifiers = [[self loadSpecifiersFromPlistName:@"Photo2Weibo" target:self] retain];
    }
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if(![fileManager fileExistsAtPath: @"/var/mobile/Documents/PhotosWeibo/weibodbv2.3.sql"]){
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.mkdir" userInfo: nil];
    }

    NSMutableArray *specs = [_specifiers mutableCopy];
    
    if([authEngine isLoggedIn] && ![authEngine isAuthorizeExpired]){
        
        NSString *userName = [authEngine getScreenName];
        
        PSSpecifier* user = [specs objectAtIndex: 2];
                
        NSLog(@"name: %@", [user name]);
        
        [user setName: [@"@" stringByAppendingString: userName]];
        
        [specs removeObjectAtIndex: 1];
        
    }else{
        [specs removeObjectAtIndex: 2]; //static label
        [specs removeObjectAtIndex: 2]; //delete account
        [specs removeObjectAtIndex: 3]; //update contacts
        //[specs removeObjectAtIndex: 3];
    }
    _specifiers = [specs copy];
    [specs release];
    return _specifiers;
}

-(void) addAccount:(PSSpecifier*)spec
{
    //[self removeSpecifierAtIndex:0 animated:YES];
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    if(!window){
        window = [[UIApplication sharedApplication].windows objectAtIndex: 0];
    }
    [authEngine setRedirectURI:@"http://www.weibotweak.com"];
    [authEngine setIsUserExclusive: NO];
    [authEngine logIn: [[window subviews] lastObject]];
    Photo2WeiboSettingsListController *tg = self;
    [authEngine setPreferenceObject: tg];
}

-(void) deleteAccount:(PSSpecifier*)spec{
    
    [authEngine deleteAuthorizeDataInKeychain];
    //update plist
    [self reloadSpecifiers];
}

-(void) updateContact:(PSSpecifier*)spec{
    
    if([authEngine isLoggedIn] && ![authEngine isAuthorizeExpired]){
        SinaWeiBoGetFriendslist *getFriendsEngine = [[SinaWeiBoGetFriendslist alloc] init];
        [getFriendsEngine startGetFriends]; //show hud
    }
}

-(void) followUs:(PSSpecifier*)spec{
    
    NSURL *url = [[NSURL alloc] initWithString: @"https://me.alipay.com/photo2weibo"];
    [[UIApplication sharedApplication] openURL:url];
}
-(void) jbguide:(PSSpecifier*)spec{
    
    NSURL *url = [[NSURL alloc] initWithString: @"http://jbguide.me/"];
    [[UIApplication sharedApplication] openURL:url];
}
-(void) dgtle:(PSSpecifier*)spec{
    
    NSURL *url = [[NSURL alloc] initWithString: @"http://www.dgtle.com/"];
    [[UIApplication sharedApplication] openURL:url];
}

-(void) igou:(PSSpecifier*)spec{
    
    NSURL *url = [[NSURL alloc] initWithString: @"http://shop60545953.m.taobao.com/"];
    [[UIApplication sharedApplication] openURL:url];
}

-(void) share2weibo:(PSSpecifier*)spec{
    
    NSURL *url = [[NSURL alloc] initWithString: @"cydia://package/org.thebigboss.share2weibo"];
    [[UIApplication sharedApplication] openURL:url];
}

-(void) getMore:(PSSpecifier*)spec{
    NSURL *url = [[NSURL alloc] initWithString: @"http://apt.thebigboss.org/packagesfordev.php?name=Photo2Weibo&uuid=&ua=Mozilla/5.0%20(iPhone;%20CPU%20iPhone%20OS%205_1%20like%20Mac%20OS%20X)%20AppleWebKit/534.46%20(KHTML,%20like%20Gecko)%20Version/5.1%20Mobile/9B179%20Safari/7534.48.3&ip=114.250.83.134&id=114.250.83.134"];
    [[UIApplication sharedApplication] openURL:url];
}
@end

%ctor{
	BOOL iPad = [[[UIDevice currentDevice] model] isEqualToString: @"iPad"];
	if(iPad){
		authEngine = [[WBEngine alloc] initWithAppKey: iPadKey appSecret: iPadSecret];
	}else{
		authEngine = [[WBEngine alloc] initWithAppKey: AppKey appSecret: AppSecret];
	}
}





