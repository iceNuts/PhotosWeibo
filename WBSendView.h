//
//  WBSendView.h
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

#import <UIKit/UIKit.h>
#import <tweet2weibo/UIProgressHUD.h>
#import <QuartzCore/QuartzCore.h>

#import "WBEngine.h"

@interface CPDistributedMessagingCenter
+ (id)centerNamed:(id)arg1;
- (BOOL)sendMessageName:(id)arg1 userInfo:(id)arg2;
@end

@class WBSendView;

@protocol WBSendViewDelegate <NSObject>

@optional

- (void)sendViewWillAppear:(WBSendView *)view;
- (void)sendViewDidAppear:(WBSendView *)view;
- (void)sendViewWillDisappear:(WBSendView *)view;
- (void)sendViewDidDisappear:(WBSendView *)view;

- (void)sendViewDidFinishSending:(WBSendView *)view;
- (void)sendView:(WBSendView *)view didFailWithError:(NSError *)error;

- (void)sendViewNotAuthorized:(WBSendView *)view;
- (void)sendViewAuthorizeExpired:(WBSendView *)view;

@end


@interface WBSendView : UIView <UITextViewDelegate, WBEngineDelegate, WBSendViewDelegate> 
{
    
	UIView      *panelView;
    UITextView  *contentTextView;
    //UIImageView *contentImageView;
    
    UIButton    *sendButton;
    UIButton    *closeButton;
    UIButton    *atButton;
    //UIButton    *clearTextButton;
    //UIButton    *clearImageButton;
    //UIButton    *logoutButton;
    
    //UILabel     *titleLabel;
    UILabel     *wordCountLabel;
    
    UIImageView *panelImageView;
	
	UIButton* backgroundmaskButton;
    UIImageView *backgroundTitle;
    NSString    *contentText;
    UIImage     *contentImage;
    
    UIInterfaceOrientation previousOrientation;
    
    BOOL        isKeyboardShowing;
    
    WBEngine    *engine;
    
    id<WBSendViewDelegate> delegate;
	
	id myRootView;
		
	NSString* imagePath;
    
    id application;
}

@property (nonatomic, retain) NSString *contentText;
@property (nonatomic, retain) UIImage *contentImage;
@property (nonatomic, assign) id<WBSendViewDelegate> delegate;
@property (nonatomic, retain) id myRootView;
@property (nonatomic, retain) id imagePath;
@property (nonatomic, retain) NSString* application;
@property (nonatomic, retain) id PLViewController;

- (id)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret text:(NSString *)text image:(UIImage *)image view: (id) rootView engine: (id) myEngine imgPath: (id) path;

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;
- (void)appendContent:(NSString*) str;
- (void)textviewFirstResponder;
@end
