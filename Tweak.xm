#import "Global.h"
#import <tweet2weibo/UIPushButton.h>
#import <tweet2weibo/UIActionSheet-Private.h>
#import <tweet2weibo/QuartzCore.h>
#import <tweet2weibo/GSEvent.h>
#import <tweet2weibo/TWTweetComposeViewController.h>
#import <tweet2weibo/TWUserRecord.h>
#import <tweet2weibo/TWMentionTableViewCell.h>
#import <tweet2weibo/TWTweetSheetLocationAssembly.h>
#import <tweet2weibo/TWTweetComposeViewController-TWTweetComposeViewControllerMentionAdditions.h>
#import "weiboSearchFriendsViewViewController.h"
#import "WBAuthorize.h"
#import "SendAgent.h"
#import "substrate.h"
#import "sqlService.h"

//API key
#define AppKey @"972468350"
#define AppSecret @"a0aaeb3074a4ed4e0aa493c34084e046"

//////////////////////////
/////// IPC LOGIN////////
//////////////////////////
BOOL getStatus(){
	CPDistributedMessagingCenter *center;
	center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	NSDictionary* reply = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.login" userInfo: nil];
	if([[reply valueForKey: @"msg"] isEqualToString: @"1"]){
		return YES;
	}else{
		return NO;
	}
}

//////////////////////////
/////// IPC LOGIN////////
//////////////////////////

//Variables for runtime Objects 
static id mySheet = nil;
static id rootView = nil;
static id myView = nil;
static id fullPath = nil;
static id PLViewController = nil;
static BOOL pwflag = false;
static TWTweetComposeViewController *sendView = nil;

//////////////////////////
/////// Twitter UI////////
//////////////////////////

//Hook for twitter UI
id cell;
id searchBarText = [[NSString alloc] init];
BOOL isCancelTapped = NO;

%hook UIButton
- (void)setEnabled:(BOOL)arg1{
	if(pwflag){
		%orig(YES);
		return;
	}
	%orig(arg1);
}
%end

%hook TWTweetComposeViewController

+ (BOOL)canSendTweet{
	if(pwflag){
		return true;
	}
	return %orig;
}
+ (BOOL)canSendTweetViaTwitterd{
	if(pwflag){
		return true;
	}
	return %orig;
}
- (void)send:(id)arg1{
	if(pwflag){
		NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [self enteredText], @"text", fullPath, @"imgPath",nil ];
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.send" userInfo: dictionary];
		pwflag = false;
		[self complete: 0];
	}else{
		%orig;
	}
}
- (void)sendButtonTapped:(id)arg1{
	isCancelTapped = NO;
	if(pwflag){
		[self send: arg1];
		return;
	}
	%orig;
}

- (void)cancelButtonTapped:(id)arg1{
	NSLog(@"----%@----", [self class]);
	isCancelTapped = YES;
	%orig;
}

- (void)viewWillDisappear:(BOOL)arg1{
	if(arg1 && pwflag && isCancelTapped){
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.cleardb" userInfo: nil];
		pwflag = false;
		isCancelTapped = NO;
	}
	%orig;
}

- (void)textViewDidChange:(id)arg1{
	//B: IPC For Renew Content
	if(pwflag){
		NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [self enteredText], @"text", nil ];
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.renew" userInfo: dictionary];
	}
	//E: IPC For Renew Content
	%orig;
}

//hook to grab the superclass's variable
- (void)viewDidAppear:(BOOL)arg1{
	if(pwflag){
		Ivar var;
		const char *name = "_tweetTitleLabel";
		var = class_getInstanceVariable([self class], name);
		id label = object_getIvar(self, var);
		if([[label text] isEqualToString:@"Tweet"] || [[label text] isEqualToString:@"Weibo"]){
			[label setText: @"Weibo"];
		}else{
			[label setText: @"新浪微博"];
		}
		var = class_getInstanceVariable([self class], "_locationAssembly");
		id assembly = object_getIvar(self, var);
		var = class_getInstanceVariable([TWTweetSheetLocationAssembly self], "_assemblyView");
		id geo = object_getIvar(assembly, var);
		[geo setHidden: YES];
		var = class_getInstanceVariable([self class], "_sendButton");
		id sendButton = object_getIvar(self, var);
		[sendButton setEnabled: YES];
	}
	%orig;
}

/////////////////////////
//HOOK FOR MULTIACCOUNTS
/////////////////////////
- (BOOL)showAccountFieldForOrientation:(int)arg1{
	//get account number
	return NO;
}
/////////////////////////
//HOOK FOR MULTIACCOUNTS
/////////////////////////

- (void)appWillMoveToBackground:(id)arg1{
	pwflag = false;
	%orig;
}
- (void)presentNoAccountsDialog{
	if(!pwflag){
		%orig;
	}
}
- (int)characterCountForEnteredText:(id)arg1 attachments:(id)arg2 allImagesDownsampled:(char *)arg3{
	if(pwflag){
		arg2 = nil;
	}
	return %orig;
}
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2{
	cell = [arg1 cellForRowAtIndexPath:arg2];
	%orig;
}
- (void)searchBar:(id)arg1 textDidChange:(id)arg2{
	searchBarText = [arg2 copy];
	if(pwflag){
		[self noteMentionsResultsChanged];
	}
	%orig;
}
- (void)searchBarWillClear:(id)arg1{
	%orig;
}
- (id)currentResults{
	if(pwflag){
		//Use weibodb
		
		NSMutableArray *specs = [NSMutableArray array];
		
		if([searchBarText isEqualToString: @""]){
			NSLog(@"------CLEAR------");
			return nil;
		}
						
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		NSDictionary *Result = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.query" userInfo: [NSDictionary dictionaryWithObjectsAndKeys: searchBarText, @"msg",nil ]];
		
		TWUserRecord *item1 = [TWUserRecord userRecordWithScreenName: searchBarText];
		
		[specs addObject: item1];
		int number = [Result count];
		
		NSString *object;
		NSRange myRange;
		NSString *screenName = nil;
		NSString *alias = nil;
		NSString *sqlAliasdelete1;
		NSString *screenAliasTemp;
		
		for(int i = 0; i < number; i++){
			object = [Result valueForKey:[NSString stringWithFormat:@"%i",i]];
			myRange = [object rangeOfString:@"("];
			if(myRange.length > 0){
				screenName = [object substringToIndex: myRange.location];
				screenAliasTemp = [object substringFromIndex:myRange.location];
				sqlAliasdelete1 = [screenAliasTemp stringByReplacingOccurrencesOfString:@"("  withString:@""];
				alias = [sqlAliasdelete1 stringByReplacingOccurrencesOfString:@")"  withString:@""];
			}else{
				screenName = [object copy];
			}
			TWUserRecord *item = [TWUserRecord userRecordWithScreenName: screenName];
			[item setName: alias];
			[specs addObject: item];
		}
		
		return [specs retain];
	}else{
		return %orig;
	}
}
- (struct _NSRange)applyMention:(id)arg1{
	if(pwflag && [[cell userRecord] screen_name] != nil){
		arg1 = [[[cell userRecord] screen_name] stringByAppendingString: @" "];
	}else if(arg1 == nil){
		Ivar var;
		const char *name = "_searchField";
		var = class_getInstanceVariable([self class], name);
		id searchBar = object_getIvar(self, var);
		arg1 = [searchBar text];
	}
	return %orig;
}
%end

//////////////////////////
/////// Twitter UI////////
//////////////////////////

@interface handleAlertView: NSObject<UIAlertViewDelegate>
@end

@implementation handleAlertView
- (void)alertView:(UIAlertView *)alertView  clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(alertView.tag == 100){
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.redirect" userInfo: nil];
	}
}
@end

//Basic hook method for PhotoBrowser
@interface PLPhotoBrowserController
- (id)_actionViewRootView;
@end

//Basic hook for adding button in ActionSheet
%hook UIActionSheet

- (void)presentSheetInView:(id)arg1{
	
	NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
		
	if ([bundleId isEqualToString:@"com.apple.mobileslideshow"] || [bundleId isEqualToString:@"com.apple.camera"]);
		
		id button = [self buttons];
		BOOL x1 = [[[button objectAtIndex:0] title] isEqualToString: @"Email Photo"];
		BOOL x2 = [[[button objectAtIndex:0] title] isEqualToString: @"用电子邮件发送照片"];
		BOOL x3 = [[[button objectAtIndex:0] title] isEqualToString: @"透過電子郵件傳送照片"];
		if(x1 || x2 || x3){
			NSLog(@"----I INJECT U-----");
			if(x1){
				[self addButtonWithTitle:@"Weibo"];
			}else if(x2){
				[self addButtonWithTitle:@"新浪微博"];
			}else if(x3){
				[self addButtonWithTitle:@"新浪微薄"];
			}
			
			[button exchangeObjectAtIndex:[button count] - 2 withObjectAtIndex:[button count] - 1];

			id cancelButton = [button objectAtIndex:[button count] - 1];
			if (cancelButton) {
						[cancelButton setTag:[button count]];
			}

			id weiboButton = [button objectAtIndex:[button count] - 2];
			if (weiboButton) {
						[weiboButton setTag:[button count] - 1];
			}
			self.cancelButtonIndex = [button count] - 1;
			//Get sheet
			mySheet = self;
		}
		%orig;
}	

- (void)_presentFromBarButtonItem:(id)arg1 orFromRect:(struct CGRect)arg2 inView:(id)arg3 direction:(int)arg4 allowInteractionWithViews:(id)arg5 backgroundStyle:(int)arg6 animated:(BOOL)arg7{
	NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
	BOOL iPad = [[[UIDevice currentDevice] model] isEqualToString: @"iPad"];
	if (([bundleId isEqualToString:@"com.apple.mobileslideshow"] || [bundleId isEqualToString:@"com.apple.camera"]) && iPad){
		
		id button = [self buttons];
		BOOL x1 = [[[button objectAtIndex:0] title] isEqualToString: @"Email Photo"];
		BOOL x2 = [[[button objectAtIndex:0] title] isEqualToString: @"用电子邮件发送照片"];
		BOOL x3 = [[[button objectAtIndex:0] title] isEqualToString: @"透過電子郵件傳送照片"];
		if(x1 || x2 || x3){
			NSLog(@"----I INJECT U-----");
			if(x1){
				[self addButtonWithTitle:@"Weibo"];
			}else if(x2){
				[self addButtonWithTitle:@"新浪微博"];
			}else if(x3){
				[self addButtonWithTitle:@"新浪微薄"];
			}
			//Get sheet
			mySheet = self;
		}
	}
	%orig;	
}

- (void)dismissWithClickedButtonIndex:(int)arg1 animated:(BOOL)arg2{
	if(arg1 == -1){
		%orig(-1,1);
		return;
	}
	NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
	BOOL iPad = [[[UIDevice currentDevice] model] isEqualToString: @"iPad"];
	if ((([bundleId isEqualToString:@"com.apple.mobileslideshow"] || [bundleId isEqualToString:@"com.apple.camera"]) && iPad)){
		BOOL x1 = [[self buttonTitleAtIndex: arg1] isEqualToString: @"Weibo"];
		BOOL x2 = [[self buttonTitleAtIndex: arg1] isEqualToString: @"新浪微博"];
		BOOL x3 = [[self buttonTitleAtIndex: arg1] isEqualToString: @"新浪微薄"];
		if(x1 || x2 || x3){
			NSLog(@"----I CREATE------");
			pwflag = true;
			UIImage *tmp = [UIImage imageWithContentsOfFile: fullPath];

			CGSize newSize = CGSizeMake(100, 100);

	        UIGraphicsBeginImageContext(newSize);
	        [tmp drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	        UIImage* myImage = UIGraphicsGetImageFromCurrentImageContext();
	        UIGraphicsEndImageContext();
	
			NSLog(@"-----LOGIN? %i-----", getStatus());
			if(getStatus()){
					Class $TWTweetComposeViewController = objc_getClass("TWTweetComposeViewController");
					if(sendView == nil){
						sendView = [[$TWTweetComposeViewController alloc] init];
					}
					[sendView addImage: myImage];	
					//B: IPC For Remnant
					CPDistributedMessagingCenter *center;
					center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
					NSDictionary* reply = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.remnant" userInfo: nil];
					[sendView _setText: [reply valueForKey: @"msg"]];
					//E: IPC For Remnant
					[PLViewController presentModalViewController: sendView animated: NO];
					[sendView noteStatusChanged];	
					[sendView noteCheckedInWithDaemon];
				}else{
				//redirect
				CPDistributedMessagingCenter *center;
				center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
				[center sendMessageName:@"com.icenuts.photo2weibo.redirect" userInfo: nil];
			}
		}else{
			pwflag = false;
		}
	}	
	%orig;
}
%end
//For iPad
%hook PLPhotoBrowserController
- (void)viewWillAppear{
	PLViewController = self;
	%orig;
}
%end

//Basic hook for fetching the image
@interface PLManagedAsset
@property(retain, nonatomic) NSString *originalPath;
@property int originalFilesizeValue;
@property(retain, nonatomic) NSString *filename; // @dynamic filename;
@property(retain, nonatomic) NSString *directory; // @dynamic directory;
@end

@interface PLPhotoTileViewController
@property(readonly, nonatomic) PLManagedAsset *photo;
- (id)imageView;
@end

%hook PLPhotoTileViewController
- (void)viewDidAppear:(BOOL)arg1{
	PLManagedAsset *info = [self photo];
	NSString *filename = [info filename];
	NSString *directory = [info directory];
	NSString *path = [[@"/User/Media/" stringByAppendingString: directory] stringByAppendingString: @"/"];
	fullPath = [[path stringByAppendingString: filename] copy];
	NSLog(@"PATH: %@ : I am here to fetch your photo", fullPath);
	myView = [self imageView];
	%orig;
}
%end


//Basic hook for 
@interface PLPhotoScrollerViewController
- (id)_actionViewRootView;
- (void)disableAutohideControls;
- (void)enableAutohideControls;
- (void)setRotationDisabled:(BOOL)arg1;
- (void)_cancelToolbarTimer;
- (void)_setAutohidesControls:(BOOL)arg1;
- (void)setStatusBarIsLocked:(BOOL)arg1;
- (BOOL)autohideControlsIsEnabled;
- (void)hideOverlaysWithDuration:(float)arg1 hideStatusBar:(BOOL)arg2;
- (id)_currentToolbarItems;
@property(nonatomic) BOOL isCameraApp; // @synthesize isCameraApp=_isCameraApp;
@end

%hook PLPhotoScrollerViewController

- (void)actionSheet:(id)sheet clickedButtonAtIndex:(int)index{
	
	BOOL x1 = [[sheet buttonTitleAtIndex: index] isEqualToString: @"Weibo"];
	BOOL x2 = [[sheet buttonTitleAtIndex: index] isEqualToString: @"新浪微博"];
	BOOL x3 = [[sheet buttonTitleAtIndex: index] isEqualToString: @"新浪微薄"];

	if([sheet isEqual: mySheet] && (x1 || x2 || x3)){
		rootView = [self _actionViewRootView];
		
		PLViewController = self;
		
		NSLog(@"----I CREATE------");
		
		pwflag = true;
		UIImage *tmp = [UIImage imageWithContentsOfFile: fullPath];
		
		CGSize newSize = CGSizeMake(100, 100);
        
        UIGraphicsBeginImageContext(newSize);
        [tmp drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
        UIImage* myImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
		
		
		NSLog(@"-----LOGIN? %i-----", getStatus());
		if(getStatus()){
				Class $TWTweetComposeViewController = objc_getClass("TWTweetComposeViewController");
				if(sendView == nil){
					sendView = [[$TWTweetComposeViewController alloc] init];
				}
				[sendView addImage: myImage];	
				//B: IPC For Remnant
				CPDistributedMessagingCenter *center;
				center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
				NSDictionary* reply = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.remnant" userInfo: nil];
				[sendView _setText: [reply valueForKey: @"msg"]];
				//E: IPC For Remnant
				[PLViewController presentViewController: sendView animated: NO completion: NULL];
				[sendView noteStatusChanged];	
				[sendView noteCheckedInWithDaemon];
			}else{
			//redirect
			//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Photo2Weibo"]];
			CPDistributedMessagingCenter *center;
			center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
			[center sendMessageName:@"com.icenuts.photo2weibo.redirect" userInfo: nil];
		}
	}else{
		pwflag = false;
	}
	%orig;
}

%end

//Hook for Keyboard

static CGPoint myAtArea;
static CGPoint myAtRadii;
static CGPoint myHitPoint;

static CGPoint mySArea;
static CGPoint mySRadii;

@interface UIKeyboardImpl
-(int)returnKeyType;
@end

%hook UIKeyboardImpl
-(void)longPressAction{

	if(!pwflag){
		%orig;
		return;
	}
	NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
	
	if ([bundleId isEqualToString:@"com.apple.mobileslideshow"] || [bundleId 	isEqualToString:@"com.apple.camera"]){
	//judge for @
	int Atmax_x = myAtArea.x + myAtRadii.x;
	int Atmin_x = myAtArea.x - myAtRadii.x;
	int Atmax_y = myAtArea.y + myAtRadii.y;
	int Atmin_y = myAtArea.y - myAtRadii.y;
	
	//judge for S
	int Smax_x = mySArea.x + mySRadii.x;
	int Smin_x = mySArea.x - mySRadii.x;
	int Smax_y = mySArea.y + mySRadii.y;
	int Smin_y = mySArea.y - mySRadii.y;
	
	BOOL isAt = NO;
	BOOL isS = NO;
		if(myHitPoint.x <= Atmax_x && myHitPoint.x >= Atmin_x && myHitPoint.y <= Atmax_y && myHitPoint.y >= Atmin_y){
		isAt = YES;
	}
	
	if(myHitPoint.x <= Smax_x && myHitPoint.x >= Smin_x && myHitPoint.y <= Smax_y && myHitPoint.y >= Smin_y){
		isS = YES;
	}	
	
	if(isAt)
	{
		
	}else if(isS){
	
		//Redirect to preference
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.redirect" userInfo: nil];		
	}else{
		%orig;
	}
	}else{
		%orig;
	}
}

-(void)setInputPoint:(CGPoint)point{
	myHitPoint = point;
	%orig;
}
-(void)registerKeyArea:(CGPoint)area withRadii:(CGPoint)radii forKeyCode:(unsigned short)keyCode forLowerKey:(id)lowerKey forUpperKey:(id)upperKey{
	if([upperKey isEqualToString: @"@"]){
		myAtArea = area;
		myAtRadii = radii;
	}
	if([upperKey isEqualToString: @"S"] || [lowerKey isEqualToString: @"s"]){
		mySArea = area;
		mySRadii = radii;
	}
	%orig;
}
%end







