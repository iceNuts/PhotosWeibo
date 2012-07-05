#import "tweet2weibo/AudioServices.h"
#import "tweet2weibo/BulletinBoard.h"
#import "WBEngine.h"
#import "sqlService.h"
#import "SendAgent.h"
#import <sys/stat.h>
#import <sqlite3.h>

NSDictionary *mDictionary;
CPDistributedMessagingCenter *mCenter;
id fullPath;

//API key
#define AppKey @"972468350"
#define AppSecret @"a0aaeb3074a4ed4e0aa493c34084e046"

#define iPadKey @"1060116038"
#define iPadSecret @"26e38ca8fbbcc6ad235b04d72b03709a"

#define initializer __attribute__((constructor)) extern

@interface SBBulletinBannerController  
+ (id)sharedInstance;
- (void)_presentBannerForItem:(id)arg1;
@end

@interface SBBulletinBannerItem
+ (id)itemWithBulletin:(id)arg1;
@end

@interface BBSound
+ (id)alertSoundWithSystemSoundID:(unsigned long)arg1;
@end

@interface SBUserAgent
+ (id)sharedUserAgent;
- (BOOL)openURL:(id)arg1 allowUnlock:(BOOL)arg2 animated:(BOOL)arg3;
@end

%config(generator=internal)
__attribute__((visibility("hidden")))
@interface PWBannerProvider: NSObject<BBDataProvider>{	
@private
	BBBulletinRequest *bulletin;
	NSString* bannerTitle;
	NSString* bannerMsg;
	UIImage * bannerImage;
}
- (void)loadDataProviderWithOptions: (NSInteger) type Message: (NSString*) msg UserInfo: (NSDictionary*) dictionary;
@end

@implementation PWBannerProvider
static PWBannerProvider *sharedProvider;
+(PWBannerProvider*) sharedProvider{
	return [[sharedProvider retain] autorelease];
}

- (id)init
{
	if ((self = [super init])) {
		sharedProvider = self;
	}
	return self;
}

- (void)dealloc
{
	sharedProvider = nil;
	[bannerTitle release];
	[bannerMsg release];
	[bannerImage release];
	[super dealloc];
}

- (NSString *)sectionIdentifier
{
	return @"com.apple.mobileslideshow";
}

- (NSArray *)sortDescriptors
{
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
}

- (NSArray *)bulletinsFilteredBy:(unsigned)by count:(unsigned)count lastCleared:(id)cleared
{
	return nil;
}

- (NSString *)sectionDisplayName
{
	return @"Photos Weibo";
}

- (BBSectionInfo *)defaultSectionInfo
{
	BBSectionInfo *sectionInfo = [BBSectionInfo defaultSectionInfoForType:0];
	sectionInfo.notificationCenterLimit = 10;
	sectionInfo.sectionID = [self sectionIdentifier];
	return sectionInfo;
}

-(void) handleAction{
	NSLog(@"-----CALLBLOCK------");
	NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [mDictionary valueForKey: @"msg"], @"text", fullPath, @"imgPath",nil ];
	mCenter = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	[mCenter sendMessageName:@"com.icenuts.photo2weibo.send" userInfo: dictionary];
	//remove bulletin
	CPDistributedMessagingCenter *
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bbserver"];
	[center sendMessageName:@"com.icenuts.photo2weibo.bbserver.remove" userInfo: nil];
}

- (void)loadDataProviderWithOptions: (NSInteger) type Message: (NSString*) msg UserInfo: (NSDictionary*) dictionary
{
	UIImage *image = [UIImage imageWithData: [dictionary valueForKey: @"image"]];
	bannerImage = [image retain];
	BBDataProviderWithdrawBulletinsWithRecordID(self, @"com.apple.mobileslideshow/banner");
	if(bulletin){
		[bulletin release];
		bulletin = nil;
	}
	if(!bulletin){
		NSLog(@"---NEW ITEM---");
		bulletin = [[BBBulletinRequest alloc] init];
		bulletin.sectionID = @"com.apple.mobileslideshow/banner";
		bulletin.bulletinID = @"com.apple.mobileslideshow/banner";
		bulletin.defaultAction = [BBAction actionWithCallblock:^{
			mDictionary = [dictionary retain];
			[self handleAction];
		}];
		bulletin.publisherBulletinID = @"com.apple.mobileslideshow/banner";
		bulletin.recordID = @"com.apple.mobileslideshow/banner";
		bulletin.showsUnreadIndicator = NO;
	} 

	bulletin.title = @"Photos Weibo";
	bulletin.subtitle = msg;
	bulletin.message = [dictionary valueForKey: @"msg"];
	NSDate *date = [NSDate date];
	bulletin.date = date;
	bulletin.lastInterruptDate = date;
	bulletin.primaryAttachmentType = image ? 2 : 0;
	[sharedProvider dataProviderDidLoad];
}

- (CGFloat)attachmentAspectRatioForRecordID:(NSString *)recordID
{
	if (bannerImage) {
		CGSize size = bannerImage.size;
		if (size.height > 0.0f)
			return size.width / size.height;
	}
	return 1.0f;
}

- (NSData *)attachmentPNGDataForRecordID:(NSString *)recordID sizeConstraints:(BBThumbnailSizeConstraints *)constraints
{
	if (constraints && bannerImage) {
		CGSize imageSize = bannerImage.size;
		CGSize maxSize;
		maxSize.width = constraints.fixedWidth;
		maxSize.height = constraints.fixedHeight;
		// Doesn't properly check constraintType, but this is good enough for now
		if (maxSize.width > 0.0f) {
			if (maxSize.height > 0.0f) {
				if (imageSize.width *maxSize.height > maxSize.width * imageSize.height)
					maxSize.height = maxSize.width * imageSize.height /  imageSize.width;
				else
					maxSize.width = maxSize.height * imageSize.width / imageSize.height;
			} else {
				maxSize.height = maxSize.width * imageSize.height /  imageSize.width;
			}
		} else {
			if (maxSize.height > 0.0f) {
				maxSize.width = maxSize.height * imageSize.width / imageSize.height;
			} else {
				// Fit image in 0x0? Wat.
				return nil;
			}
		}
		UIGraphicsBeginImageContextWithOptions(maxSize, NO, constraints.thumbnailScale);
		CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationDefault);
		[bannerImage drawInRect:(CGRect){{0.0f,0.0f},maxSize}];
		UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		return UIImagePNGRepresentation(result);
	}
	return nil;
}


- (void) dataProviderDidLoad{
	BBDataProviderAddBulletin(self, bulletin);	
}

@end

static int isStart = 0;

%hook SBApplicationController
- (id)init{
	NSLog(@"----I am HERE-----");
	if(isStart)
		return %orig;
	isStart = 1;
CPDistributedMessagingCenter *
	center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	
	[center runServerOnCurrentThread];
		
	[center registerForMessageName:@"com.icenuts.photo2weibo.failure" target:self selector:@selector(handleMessageNamed:userInfo:)];
	[center registerForMessageName:@"com.icenuts.photo2weibo.success" target:self selector:@selector(handleMessageNamed:userInfo:)];
	[center registerForMessageName:@"com.icenuts.photo2weibo.timeout" target:self selector:@selector(handleMessageNamed:userInfo:)];
	[center registerForMessageName:@"com.icenuts.photo2weibo.redirect" target:self selector:@selector(handleMessageNamed:userInfo:)];
	[center registerForMessageName:@"com.icenuts.photo2weibo.mkdir" target:self selector:@selector(handleMessageNamed:userInfo:)];
	[center registerForMessageName:@"com.icenuts.photo2weibo.renew" target:self selector:@selector(handleMessageNamed:userInfo:)];
	[center registerForMessageName:@"com.icenuts.photo2weibo.cleardb" target:self selector:@selector(handleMessageNamed:userInfo:)];
	[center registerForMessageName:@"com.icenuts.photo2weibo.login" target:self selector:@selector(handleTwoWayMessage:userInfo:)];
	[center registerForMessageName:@"com.icenuts.photo2weibo.query" target:self selector:@selector(handleQuery:userInfo:)];
	[center registerForMessageName:@"com.icenuts.photo2weibo.send" target:self selector:@selector(handleMessageNamed:userInfo:)];
	[center registerForMessageName:@"com.icenuts.photo2weibo.remnant" target:self selector:@selector(handleQuery:userInfo:)];
	return %orig;
}

%new(v@:@@)
- (void) handleMessageNamed:(NSString *)name userInfo:(NSDictionary *)userInfo{
		
	if([name isEqualToString: @"com.icenuts.photo2weibo.failure"]){
		//show a notification, if being tapped, resend it.
		[sharedProvider loadDataProviderWithOptions:2 Message: @"发送失败－点击重新发送" UserInfo: userInfo];
		
	}else if([name isEqualToString: @"com.icenuts.photo2weibo.success"]){
		//Only shows a banner

		Class $SBBulletinBannerController = objc_getClass("SBBulletinBannerController");
		Class $SBBulletinBannerItem = objc_getClass("SBBulletinBannerItem");
		Class $BBBulletin = objc_getClass("BBBulletin");
		id bulletin = [[$BBBulletin alloc] init];
		id showBanner = [$SBBulletinBannerController sharedInstance];
		[bulletin setMessage: @"发送成功!"];
		[bulletin setTitle: @"Photos Weibo"];
		[bulletin setRecordID: @"com.apple.mobileslideshow"];
		[bulletin setPublisherBulletinID: @"com.apple.mobileslideshow"];
		[bulletin setSectionID: @"com.apple.mobileslideshow"];
		
		id item = [$SBBulletinBannerItem itemWithBulletin: bulletin];
		[showBanner _presentBannerForItem: item];
		
		//B: Clear Sql Content
		sqlService *sql = [[sqlService alloc] init];
		[sql deleteTweetText];
		//E: Clear Sql Content
	}else if([name isEqualToString: @"com.icenuts.photo2weibo.timeout"]){
		
		[sharedProvider loadDataProviderWithOptions:3 Message: @"发送失败－点击重新发送" UserInfo: userInfo];
						
	}else if([name isEqualToString:@"com.icenuts.photo2weibo.redirect"]){
		[[%c(SBUserAgent) sharedUserAgent] openURL:[NSURL URLWithString:@"prefs:root=PhotosWeibo"] allowUnlock:true animated:true];
	}else if([name isEqualToString:@"com.icenuts.photo2weibo.mkdir"]){
		NSLog(@"----I am making dir-----");
		mkdir("/var/mobile/Documents/",0777);
		mkdir("/var/mobile/Documents/PhotosWeibo/",0777);
		sqlite3 *_database;
		NSString* path = @"/var/mobile/Documents/PhotosWeibo/weibodbv2.3.sql";
		sqlite3_open([path UTF8String], &_database);
	}else if([name isEqualToString:@"com.icenuts.photo2weibo.send"]){
		BOOL iPad = [[[UIDevice currentDevice] model] isEqualToString: @"iPad"];
		SendAgent *myAgent = [[SendAgent alloc] init];
		//Check Piracy
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if([fileManager fileExistsAtPath: @"/var/lib/dpkg/info/com.xsellize.share2weibo.list"]){
			[myAgent initWithAppKey: AppKey appSecret: AppSecret text: @"请购买正版#Share2Weibo#"  imgPath: [userInfo valueForKey:@"imgPath"]];
			[myAgent send];
			return;
	    }
		
		if(iPad){
			[myAgent initWithAppKey: iPadKey appSecret: iPadSecret text: [userInfo valueForKey:@"text"]  imgPath: [userInfo valueForKey:@"imgPath"]];
		}else{
			[myAgent initWithAppKey: AppKey appSecret: AppSecret text: [userInfo valueForKey:@"text"]  imgPath: [userInfo valueForKey:@"imgPath"]];
		}
		fullPath = [[userInfo valueForKey:@"imgPath"] copy];
		[myAgent send];
	}else if([name isEqualToString:@"com.icenuts.photo2weibo.renew"]){
		sqlService *sql = [[sqlService alloc] init];
		NSString* remain = [userInfo valueForKey:@"text"];
		[sql updateTweetText: remain];
	}else if([name isEqualToString:@"com.icenuts.photo2weibo.cleardb"]){
		//B: Clear Sql Content
		sqlService *sql = [[sqlService alloc] init];
		[sql deleteTweetText];
		//E: Clear Sql Content
	}
}

%new(@@:@@)
- (NSDictionary*)handleTwoWayMessage:(NSString *)name userInfo:(NSDictionary *)userInfo{
	if([name isEqualToString:@"com.icenuts.photo2weibo.login"]){
		id authEngine = [[WBEngine alloc] initWithAppKey: AppKey appSecret: AppSecret];
		[authEngine setRedirectURI:@"http://www.weibotweak.com"];
		[authEngine setIsUserExclusive: NO];
		NSDictionary* reply;
		if([authEngine isLoggedIn] && ![authEngine isAuthorizeExpired]){
			reply = [NSDictionary dictionaryWithObjectsAndKeys: @"1", @"msg",nil ];
		}else{
			reply = [NSDictionary dictionaryWithObjectsAndKeys: @"0", @"msg",nil ];
		}
		return reply;
	}
}
%new(@@:@@)
- (NSDictionary*)handleQuery:(NSString *)name userInfo:(NSDictionary *)userInfo{
	if([name isEqualToString:@"com.icenuts.photo2weibo.query"]){
		sqlService *sql = [[sqlService alloc] init];
		NSDictionary *Result = [[NSDictionary alloc]init];	
		Result = [sql getweibofriendHead: [userInfo valueForKey: @"msg"]];
		return Result;
	}else if([name isEqualToString:@"com.icenuts.photo2weibo.remnant"]){
	//Renew Content
		sqlService *sql = [[sqlService alloc] init];
		NSDictionary *Result = [[NSDictionary alloc]init];	
		Result = [sql getTweetText];
		return Result;
	}
}

%end

static BOOL BBStart = NO;

%hook BBServer
- (id)init{
	NSLog(@"-----BBServer-------");
	if(BBStart){
		return %orig;
	}
	BBStart = YES;
	CPDistributedMessagingCenter *
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bbserver"];

		[center runServerOnCurrentThread];
		[center registerForMessageName:@"com.icenuts.photo2weibo.bbserver.remove" target:self selector:@selector(handleBBServer:userInfo:)];
	return %orig;
}

%new(v@:@@)
- (void) handleBBServer:(NSString *)name userInfo:(NSDictionary *)userInfo{
	if([name isEqualToString: @"com.icenuts.photo2weibo.bbserver.remove"]){
		[self _clearSection: @"com.apple.mobileslideshow"];
	}
}

- (void)_loadAllDataProviderPluginBundles{
	%orig;
	PWBannerProvider *p = [[PWBannerProvider alloc] init];
	[self _addDataProvider:p sortSectionsNow:YES];
	[p release];
}
%end













