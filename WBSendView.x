//
//  WBSendView.m
//  SinaWeiBoSDK
//  Based on OAuth 2.0
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
//  Copyright 2011 Sina. All rights reserved.
//

#import "WBSendView.h"
#import "tweet2weibo/BBBulletin.h"
#import "tweet2weibo/SBBulletinBannerItem.h"
#import "tweet2weibo/AudioServices.h"
#import "Reachability.h"
#import "sqlService.h"
#import "weiboSearchFriendsViewViewController.h"


@interface handleSendViewAlertView: NSObject<UIAlertViewDelegate>
@end

@implementation handleSendViewAlertView
- (void)alertView:(UIAlertView *)alertView  clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(alertView.tag == 100){
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.redirect" userInfo: nil];
	}
}
@end

static UIBackgroundTaskIdentifier bgTask;
static UIImage* cacheImage;
static NSString* remainText = nil;

static BOOL WBIsDeviceIPad()
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
		return YES;
	}
#endif
	return NO;
}

@interface WBSendView (Private)

- (void)onCloseButtonTouched:(id)sender;
- (void)onSendButtonTouched:(id)sender;
- (void)onClearTextButtonTouched:(id)sender;
- (void)onClearImageButtonTouched:(id)sender;
-(void)onLogoutButtonTouched:(id)sender;

- (void)sizeToFitOrientation:(UIInterfaceOrientation)orientation;
- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation;
- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation;

- (void)addObservers;
- (void)removeObservers;

- (UIInterfaceOrientation)currentOrientation;

- (void)bounceOutAnimationStopped;
- (void)bounceInAnimationStopped;
- (void)bounceNormalAnimationStopped;
- (void)allAnimationsStopped;

- (int)textLength:(NSString *)text;
- (void)calculateTextLength;

- (void)hideAndCleanUp;

@end

@implementation WBSendView

@synthesize contentText;
@synthesize contentImage;
@synthesize delegate;
@synthesize myRootView;
@synthesize imagePath;
@synthesize application;
@synthesize PLViewController;

#pragma mark - WBSendView Life Circle

- (id)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret text:(NSString *)text image:(UIImage *)image view: (id) rootView engine: (id) myEngine imgPath: (id) pathForImage
{
    
    if ((self = [super initWithFrame:[rootView frame]]) != 0)
    {
        application = [UIApplication sharedApplication];
        engine = myEngine;
        [engine setDelegate:self];
        
		[self setDelegate: self];
					
		imagePath = pathForImage;
					
		myRootView = rootView;
        
        // add the panel view
        panelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        panelImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
		panelImageView.image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/Photo2Weibo/mask.png"];
	
				
        [panelView addSubview:panelImageView];
        [self addSubview:panelView];

		//set the background top
		backgroundTitle = [[UIImageView alloc] initWithFrame: CGRectMake(0,20,320, 170)];
		backgroundTitle.image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/Photo2Weibo/bg.png"];
		
		//closeButton
		closeButton = [UIButton buttonWithType: 102];
		sendButton = [UIButton buttonWithType: 102];
		[closeButton setFrame: CGRectMake(10,30,45,30)];
		[closeButton setTintColor:[UIColor lightGrayColor]];
		[closeButton setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
		closeButton.titleLabel.font = [UIFont systemFontOfSize: 16];
		[closeButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Photo2Weibo/cancel.png"] forState:UIControlStateNormal];
		//[closeButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Photo2Weibo/cancel_button_push.png"] forState:UIControlEventTouchUpInside];
	 	[closeButton setTitle: @"取消" forState: UIControlStateNormal];
		[closeButton addTarget:self action:@selector(onCloseButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
	 	//SendButton
		[sendButton setFrame: CGRectMake(260,29,45,30)];
		//[sendButton setTintColor:[UIColor whiteColor]];
		sendButton.titleLabel.font = [UIFont systemFontOfSize: 16];
		[sendButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Photo2Weibo/send_button_normal.png"] forState:UIControlStateNormal];
		[sendButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Photo2Weibo/send_button_push.png"] forState:UIControlEventTouchUpInside];
		[sendButton setTitle: @"发送" forState: UIControlStateNormal];
		[sendButton addTarget:self action:@selector(onSendButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
		
		//atButton
		atButton = [UIButton buttonWithType: UIButtonTypeCustom];
		[atButton setTintColor:[UIColor clearColor]];
		[atButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Photo2Weibo/lightBlue.png"] forState:UIControlStateNormal];
		//[atButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Photo2Weibo/lightBlue.png"] forState:UIControlEventTouchUpInside];
        [atButton setFrame: CGRectMake(10,156,30,32)];
		[atButton addTarget:self action:@selector(onAtButtonTouched:) forControlEvents:UIControlEventTouchUpInside];

        contentTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, 75, 275, 80)];
		[contentTextView setEditable:YES];
		[contentTextView setDelegate:self];
		contentTextView.userInteractionEnabled = YES;
		[contentTextView setScrollEnabled: YES];
		if(remainText && ![remainText isEqualToString: @"分享图片"]){
			[contentTextView setText:remainText];
		}else{
			[contentTextView setText:text];
		}
		contentTextView.returnKeyType = UIReturnKeyDone;
        [contentTextView setKeyboardType: UIKeyboardTypeTwitter];
		[contentTextView setBackgroundColor:[UIColor clearColor]];
		[contentTextView setFont:[UIFont systemFontOfSize:18]];
		[[contentTextView layer] setBorderColor:[[UIColor grayColor] CGColor]];
        
		[[contentTextView layer] setBorderWidth:1.2];
		[[contentTextView layer] setCornerRadius:6.0f];
		CALayer *txtlayer = [contentTextView layer];
		txtlayer.shadowColor = [UIColor grayColor].CGColor;
		txtlayer.shadowOffset = CGSizeMake(0, 1);
		txtlayer.shadowOpacity = 1;
		txtlayer.shadowRadius = 9.0;
		        
        wordCountLabel =  [[UILabel alloc] initWithFrame: CGRectMake(270,165,30,15)];
		[wordCountLabel setBackgroundColor:[UIColor clearColor]];
		[wordCountLabel setTextColor:[UIColor darkGrayColor]];
		[wordCountLabel setFont:[UIFont systemFontOfSize:16]];
		[wordCountLabel setTextAlignment:UITextAlignmentCenter];
        
        [panelView addSubview:backgroundTitle];
		[panelView addSubview:closeButton];
		[panelView addSubview:sendButton];
		[panelView addSubview:contentTextView];
		[panelView addSubview:wordCountLabel];
		[panelView addSubview:atButton];
		
		
		backgroundmaskButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 230, 320, 250)];
		[backgroundmaskButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchDown];
		[backgroundmaskButton addTarget:self action:@selector(maskshow:) forControlEvents:UIControlEventTouchUpInside];

		[panelView addSubview:backgroundmaskButton];
		
        // calculate the text length
        [self calculateTextLength];
        
        self.contentText = contentTextView.text;
        
        // image(if attachted)
        if (image)
        {   
            self.contentImage = image;
        }
        
    }
    return self;
}

- (void)textviewFirstResponder{
	[contentTextView becomeFirstResponder];
}

- (void)appendContent: (NSString*) str{
	[contentTextView setText: [[contentTextView.text stringByAppendingString: @"@"] stringByAppendingString: str]];
}

- (void)dealloc
{
    [panelView release], panelView = nil;
    [panelImageView release], panelImageView = nil;
    [contentTextView release], contentTextView = nil;
    [wordCountLabel release], wordCountLabel = nil;
	[backgroundTitle release],backgroundTitle = nil;
    
    [contentText release], contentText = nil;
    [contentImage release], contentImage = nil;
    
    delegate = nil;
    
    [super dealloc];
}

- (IBAction) dismiss: (id) sender{
    
    self.alpha = 100;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    self.alpha = 0;
    

    [UIView commitAnimations];
 
}

- (IBAction) maskshow: (id) sender{
    
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
	self.alpha = 100;
	[UIView commitAnimations];
    
}



#pragma mark - WBSendView Private Methods

#pragma mark Actions

- (void)onAtButtonTouched: (id)sender{
	sqlService *sqlSer = [[sqlService alloc] init];
	NSMutableArray *temparray=  [sqlSer getweibofriendList];
	NSLog(@"the temparray friends list is %@",temparray);
	if([temparray count] == 0){
	    NSLog(@"error when read friends list");
		handleSendViewAlertView *handle = [[handleSendViewAlertView alloc] init];
		UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil 
														   message:@"请更新@联系人列表" 
														  delegate:handle
												 cancelButtonTitle:@"好" 
												 otherButtonTitles:nil];
	    [alertView setTag:100];
		[alertView show];
		[alertView release];
	}else{
		weiboSearchFriendsViewViewController *searchView = [[weiboSearchFriendsViewViewController alloc] init];
		[searchView setPLViewController: PLViewController];
		[searchView setMySendView: self];
		[PLViewController presentModalViewController:searchView animated:YES];
		[self setHidden: YES];
	}
}

- (void)onCloseButtonTouched:(id)sender
{
    [self hide:YES];
}

- (void)onSendButtonTouched:(id)sender
{
 
	[contentTextView resignFirstResponder];
	        
    bgTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.timeout" userInfo:nil];
        //Avoid killing app
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;        
    }];
    
    NSString *text_message =contentTextView.text;
	contentText = [text_message copy];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Do the work associated with the task, preferably in chunks.
        if(contentImage != nil)
        {
            UIImage *original = [UIImage imageWithContentsOfFile: imagePath];
            
            CGFloat width = original.size.width;
            CGFloat height = original.size.height;
            
            CGFloat ratio = height/width;

			if([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] == ReachableViaWiFi){
				NSLog(@"-----Wifi-----");
				if(width > 800){
					width = 800;
					height = width*ratio;
				}
			}else{
				if(width > 450){
					width = 450;
					height = width*ratio;
				}
			}
			
            CGSize newSize = CGSizeMake(width, height);
            
            UIGraphicsBeginImageContext(newSize);
            [original drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
            UIImage* tmp = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
			
			//Assign Data
			cacheImage = [tmp retain];
			
            UIImage *send = nil;
            
            NSArray *suffix = [imagePath componentsSeparatedByString: @"."];
            NSString *fix = [[suffix lastObject] lowercaseString];
            if(!([fix isEqualToString: @"png"] || [fix isEqualToString: @"jpg"] || [fix isEqualToString: @"gif"])){
                NSData *imageData = UIImagePNGRepresentation(tmp);
                send = [UIImage imageWithData: imageData];
            }
            if(send == nil){
                send = [tmp retain];
            }
			if([contentTextView.text isEqualToString:@""]){
				  [engine sendWeiBoWithText: @"分享图片" image:send];
			}else{
            	[engine sendWeiBoWithText: text_message image:send];
			}
        }else{
			if([contentTextView.text isEqualToString:@""]){
				  [engine sendWeiBoWithText: @"分享图片" image:nil];
			}else{
            	[engine sendWeiBoWithText: text_message image:nil];
			}
		}
        
    });
    [self hide: YES];
}

#pragma mark Orientations

- (UIInterfaceOrientation)currentOrientation
{
    return [UIApplication sharedApplication].statusBarOrientation;
}

- (void)sizeToFitOrientation:(UIInterfaceOrientation)orientation
{

    if (UIInterfaceOrientationIsLandscape(orientation))
    {
		[self setHidden:YES];    
    }
    else
    {
		[self setHidden: NO];
		
    }
    
    [self setTransform:[self transformForOrientation:orientation]];
    
    previousOrientation = orientation;
}

- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation
{  
	if (orientation == UIInterfaceOrientationLandscapeLeft)
    {
		return CGAffineTransformMakeRotation(-M_PI / 2);
	}
    else if (orientation == UIInterfaceOrientationLandscapeRight)
    {
		return CGAffineTransformMakeRotation(M_PI / 2);
	}
    else if (orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
		return CGAffineTransformMakeRotation(-M_PI);
	}
    else
    {
		return CGAffineTransformIdentity;
	}
}

- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation 
{
	if (orientation == previousOrientation)
    {
		return NO;
	}
    else
    {
		return orientation == UIInterfaceOrientationLandscapeLeft
		|| orientation == UIInterfaceOrientationLandscapeRight
		|| orientation == UIInterfaceOrientationPortrait
		|| orientation == UIInterfaceOrientationPortraitUpsideDown;
	}
    return YES;
}

#pragma mark Obeservers

- (void)addObservers
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:) name:@"UIKeyboardWillShowNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:) name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)removeObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIKeyboardWillShowNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIKeyboardWillHideNotification" object:nil];
}

#pragma mark Text Length

- (int)textLength:(NSString *)text
{
    float number = 0.0;
    for (int index = 0; index < [text length]; index++)
    {
        NSString *character = [text substringWithRange:NSMakeRange(index, 1)];
        
        if ([character lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 3)
        {
            number++;
        }
        else
        {
            number = number + 0.5;
        }
    }
    return ceil(number);
}

- (void)calculateTextLength
{
    if (contentTextView.text.length > 0) 
	{ 
		[sendButton setEnabled:YES];
		[sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	}
	else 
	{
		[sendButton setEnabled:NO];
		[sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
	}
	
	int wordcount = [self textLength:contentTextView.text];
	NSInteger count  = 140 - wordcount;
	if (count < 0)
    {
		[wordCountLabel setTextColor:[UIColor redColor]];
		[sendButton setEnabled:NO];
		[sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
	}
	else
    {
		[wordCountLabel setTextColor:[UIColor darkGrayColor]];
		[sendButton setEnabled:YES];
		[sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	}
	
	[wordCountLabel setText:[NSString stringWithFormat:@"%i",count]];
}

#pragma mark Animations

- (void)bounceOutAnimationStopped
{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.13];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounceInAnimationStopped)];
    [panelView setAlpha:0.8];
	[panelView setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9)];
	[UIView commitAnimations];
}

- (void)bounceInAnimationStopped
{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.13];
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounceNormalAnimationStopped)];
    [panelView setAlpha:1.0];
	[panelView setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)];
	[UIView commitAnimations];
}

- (void)bounceNormalAnimationStopped
{
    [self allAnimationsStopped];
}

- (void)allAnimationsStopped
{
    [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0f]];
    if ([delegate respondsToSelector:@selector(sendViewDidAppear:)])
    {
        [delegate sendViewDidAppear:self];
    }
}

#pragma mark Dismiss

- (void)hideAndCleanUp
{
    [self removeObservers];
	[self removeFromSuperview];	
    
    if ([delegate respondsToSelector:@selector(sendViewDidDisappear:)])
    {
        [delegate sendViewDidDisappear:self];
    }
}

#pragma mark - WBSendView Public Methods

- (void)show:(BOOL)animated
{
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
	if (!window)
    {
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
  	[window addSubview:self];
    
    if ([delegate respondsToSelector:@selector(sendViewWillAppear:)])
    {
        [delegate sendViewWillAppear:self];
    }
    
    if (animated)
    {
        CATransition *animation = [CATransition animation];
	        //animation.delegate = self;
	        animation.duration = 0.3f;
	        animation.timingFunction = UIViewAnimationCurveEaseInOut;
	        animation.fillMode = kCAFillModeForwards;
	        animation.type = kCATransitionMoveIn;
	        animation.subtype = kCATransitionFromTop;
	        [self.layer addAnimation:animation forKey:@"animation"];
	 
    }
    else
    {
        [self allAnimationsStopped];
    }
	
	[self addObservers];
    
}

- (void)hide:(BOOL)animated
{
    if ([delegate respondsToSelector:@selector(sendViewWillDisappear:)])
    {
        [delegate sendViewWillDisappear:self];
    }
    
	if (animated)
    {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(hideAndCleanUp)];
		self.alpha = 0;
		[UIView commitAnimations];
	} else {
		
		[self hideAndCleanUp];
	}
}

#pragma mark - UIDeviceOrientationDidChangeNotification Methods

- (void)deviceOrientationDidChange:(id)object
{
	UIInterfaceOrientation orientation = [self currentOrientation];
	if ([self shouldRotateToOrientation:orientation])
    {
        NSTimeInterval duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[self sizeToFitOrientation:orientation];
		[UIView commitAnimations];
	}
}

#pragma mark - UIKeyboardNotification Methods

- (void)keyboardWillShow:(NSNotification*)notification
{
    if (isKeyboardShowing)
    {
        return;
    }
	
	isKeyboardShowing = YES;
	
	if (WBIsDeviceIPad())
    {
		// iPad is not supported in this version
		return;
	}
}

- (void)keyboardWillHide:(NSNotification*)notification
{
	isKeyboardShowing = NO;
	
	if (WBIsDeviceIPad())
    {
		return;
	}
}

#pragma mark - UITextViewDelegate Methods

- (void)textViewDidChange:(UITextView *)textView
{
	[self calculateTextLength];
}

- (BOOL)textView:(UITextView *)mytextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{	
          
        if([text isEqualToString:@"\n"]) {
            [mytextView resignFirstResponder];
            return NO;
        }
        return YES;
}


#pragma mark - WBEngineDelegate Methods

- (void)engineDidLogOut:(WBEngine *)engine
{
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil 
													   message:@"登出成功！" 
													  delegate:self
											 cancelButtonTitle:@"确定" 
											 otherButtonTitles:nil];
    [alertView setTag:100];
	[alertView show];
	[alertView release];
}


- (void)engine:(WBEngine *)engine requestDidSucceedWithResult:(id)result
{
    if ([delegate respondsToSelector:@selector(sendViewDidFinishSending:)])
    {
        [delegate sendViewDidFinishSending:self];
    }
}

- (void)engine:(WBEngine *)engine requestDidFailWithError:(NSError *)error
{
    if ([delegate respondsToSelector:@selector(sendView:didFailWithError:)])
    {
        [delegate sendView:self didFailWithError:error];
    }
}

- (void)engineNotAuthorized:(WBEngine *)engine
{
    if ([delegate respondsToSelector:@selector(sendViewNotAuthorized:)])
    {
        [delegate sendViewNotAuthorized:self];
    }
}

- (void)engineAuthorizeExpired:(WBEngine *)engine
{
    if ([delegate respondsToSelector:@selector(sendViewAuthorizeExpired:)])
    {
        [delegate sendViewAuthorizeExpired:self];
    }
}

#pragma mark - WBSendViewDelegate Methods
- (void)sendViewDidFinishSending:(WBSendView *)view
{   	
	SystemSoundID sound;
	NSURL *url = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/tweet_sent.caf" isDirectory: NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url,&sound);
	AudioServicesPlaySystemSound(sound);
	
	[NSThread sleepForTimeInterval:0.001];

	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: UIImagePNGRepresentation(cacheImage), @"image", contentText, @"msg",nil ];
	remainText = nil;
    CPDistributedMessagingCenter *center;
	center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	[center sendMessageName:@"com.icenuts.photo2weibo.success" userInfo: dictionary];
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}

- (void)sendView:(WBSendView *)view didFailWithError:(NSError *)error
{
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: UIImagePNGRepresentation(cacheImage), @"image", contentText, @"msg",nil ];
	
	SystemSoundID sound;
	NSURL *url = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/Tink.caf" isDirectory: NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url,&sound);
	AudioServicesPlaySystemSound(sound);
	
	[NSThread sleepForTimeInterval:0.001];
	
	remainText = [contentText copy];
   	CPDistributedMessagingCenter *center;
	center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	[center sendMessageName:@"com.icenuts.photo2weibo.failure" userInfo: dictionary];

    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}

@end




