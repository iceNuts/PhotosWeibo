//
//  WBEngine.m
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

#import "WBEngine.h"
#import "SFHFKeychainUtils.h"
#import "WBSDKGlobal.h"
#import "WBUtil.h"
#import "sqlService.h"

#define kWBURLSchemePrefix              @"WB_"

#define kWBKeychainServiceNameSuffix    @"_WeiBoServiceName"
#define kWBKeychainUserID               @"WeiBoUserID"
#define kWBKeychainAccessToken          @"WeiBoAccessToken"
#define kWBKeychainExpireTime           @"WeiBoExpireTime"
#define kWBAlertViewLogOutTag 100
#define kWBAlertViewLogInTag  101

@interface UIProgressHUD: UIView
- (void)done;
- (void)hide;
- (void)showInView:(id)arg1;
- (void)setText:(id)arg1;
@end

static id hud = nil;


@implementation WBEngine

@synthesize appKey;
@synthesize appSecret;
@synthesize userID;
@synthesize accessToken;
@synthesize expireTime;
@synthesize redirectURI;
@synthesize isUserExclusive;
@synthesize request;
@synthesize authorize;
@synthesize delegate;
@synthesize rootViewController;
@synthesize loginStatus;
@synthesize preferenceObject;

#pragma mark - WBEngine Life Circle

- (id)initWithAppKey:(NSString *)theAppKey appSecret:(NSString *)theAppSecret
{
    if ((self = [super init]) != 0 )
    {
        [self setLoginStatus: 0];
        self.appKey = theAppKey;
        self.appSecret = theAppSecret;

		self.delegate = self;
        
        isUserExclusive = NO;
        
        [self readAuthorizeDataFromKeychain];
    }
    
    return self;
}

- (void)dealloc
{
    [appKey release], appKey = nil;
    [appSecret release], appSecret = nil;
    
    [userID release], userID = nil;
    [accessToken release], accessToken = nil;
    
    [redirectURI release], redirectURI = nil;
    
    [request setDelegate:nil];
    [request disconnect];
    [request release], request = nil;
    
    [authorize setDelegate:nil];
    [authorize release], authorize = nil;
    
    delegate = nil;
    rootViewController = nil;
    
    [super dealloc];
}

#pragma mark - WBEngine Private Methods

- (NSString *)urlSchemeString
{
    return [NSString stringWithFormat:@"%@%@", kWBURLSchemePrefix, appKey];
}

- (void)saveAuthorizeDataToKeychain
{
    hud=[[UIProgressHUD alloc] init];
    [hud setText:@"正在获取用户信息"]; 
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    if(!window){
        window = [[UIApplication sharedApplication].windows objectAtIndex: 0];
    }
    [hud showInView: [[window subviews] lastObject]];
    sqlService *sqlSer = [[sqlService alloc] init];
    [sqlSer insertUserList:[userID doubleValue] userAccessToken:accessToken userExpireTime:expireTime ];
    [self getUserName];
}

- (void)readAuthorizeDataFromKeychain
{
    sqlService *sqlSer = [[sqlService alloc] init];
    NSMutableArray *temparray=  [sqlSer getuserList];
    if ([temparray count]==0) {
        NSLog(@"error temparray is null");
    }
    else {
        self.userID = [temparray objectAtIndex:0];
        self.accessToken = [temparray objectAtIndex:1];
        self.expireTime = [[temparray objectAtIndex:2] doubleValue];
        NSLog(@"expireTime from database is %f",self.expireTime);
    }


}

- (void)deleteAuthorizeDataInKeychain
{
    self.userID = nil;
    self.accessToken = nil;
    self.expireTime = 0;
    [self setLoginStatus: 0];
    sqlService *sqlSer = [[sqlService alloc] init];
    if([sqlSer deleteUserTable]){
        NSLog(@"------UserTable Deleted-------");
    };
    if([sqlSer deleteFriendTable]){
        NSLog(@"------Friends Deleted-------");

    }
}

#pragma mark - WBEngine Public Methods

#pragma mark Authorization

- (void)logIn : (id) view
{
    if ([self isLoggedIn])
    {
        if ([delegate respondsToSelector:@selector(engineAlreadyLoggedIn:)])
        {
            [delegate engineAlreadyLoggedIn:self];
        }
        if (isUserExclusive)
        {
            return;
        }
    }
    
    WBAuthorize *auth = [[WBAuthorize alloc] initWithAppKey:appKey appSecret:appSecret];
    //[auth setRootViewController:rootViewController];
    [auth setDelegate:self];
    self.authorize = auth;
    [auth release];
    
    if ([redirectURI length] > 0)
    {
        [authorize setRedirectURI:redirectURI];
    }
    else
    {
        [authorize setRedirectURI:@"http://"];
    }
    
    [authorize startAuthorize: view];
}

- (void)logInUsingUserID:(NSString *)theUserID password:(NSString *)thePassword
{
    self.userID = theUserID;
    
    if ([self isLoggedIn])
    {
        if ([delegate respondsToSelector:@selector(engineAlreadyLoggedIn:)])
        {
            [delegate engineAlreadyLoggedIn:self];
        }
        if (isUserExclusive)
        {
            return;
        }
    }
    
    WBAuthorize *auth = [[WBAuthorize alloc] initWithAppKey:appKey appSecret:appSecret];
    [auth setRootViewController:rootViewController];
    [auth setDelegate:self];
    self.authorize = auth;
    [auth release];
    
    if ([redirectURI length] > 0)
    {
        [authorize setRedirectURI:redirectURI];
    }
    else
    {
        [authorize setRedirectURI:@"http://"];
    }
    
    [authorize startAuthorizeUsingUserID:theUserID password:thePassword];
}

- (void)logOut
{
    [self deleteAuthorizeDataInKeychain];
    
    if ([delegate respondsToSelector:@selector(engineDidLogOut:)])
    {
        [delegate engineDidLogOut:self];
    }
}

- (BOOL)isLoggedIn
{
    //    return userID && accessToken && refreshToken;
    return userID && accessToken && (expireTime > 0);
}

- (BOOL)isAuthorizeExpired
{
    if ([[NSDate date] timeIntervalSince1970] > expireTime)
    {
        // force to log out
        [self deleteAuthorizeDataInKeychain];
        return YES;
    }
    return NO;
}

#pragma mark Request

- (void)loadRequestWithMethodName:(NSString *)methodName
                       httpMethod:(NSString *)httpMethod
                           params:(NSDictionary *)params
                     postDataType:(WBRequestPostDataType)postDataType
                 httpHeaderFields:(NSDictionary *)httpHeaderFields
{
    // Step 1.
    // Check if the user has been logged in.
	if (![self isLoggedIn])
	{
        if ([delegate respondsToSelector:@selector(engineNotAuthorized:)])
        {
            [delegate engineNotAuthorized:self];
        }
        return;
	}
    
	// Step 2.
    // Check if the access token is expired.
    if ([self isAuthorizeExpired])
    {
        if ([delegate respondsToSelector:@selector(engineAuthorizeExpired:)])
        {
            [delegate engineAuthorizeExpired:self];
        }
        return;
    }
    
    [request disconnect];
    self.request = [WBRequest requestWithAccessToken:accessToken
                                                 url:[NSString stringWithFormat:@"%@%@", kWBSDKAPIDomain, methodName]
                                          httpMethod:httpMethod
                                              params:params
                                        postDataType:postDataType
                                    httpHeaderFields:httpHeaderFields
                                            delegate:self];
	
	[request connect];
}

-(void)getUserName{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    if(self.userID != @""&&self.accessToken!=@"")
    {
        [params setObject:self.userID forKey:@"uid"];
        [params setObject:self.accessToken forKey:@"access_token"];
        NSLog(@"getusername ");
        [self loadRequestWithMethodName:@"users/show.json" httpMethod:@"GET" params:params postDataType:kWBRequestPostDataTypeNormal httpHeaderFields:nil];
        
        
    }
    else {
        
        NSLog(@"uid &accessToken null");
        
    }
}
-(NSString *) getScreenName
{
    sqlService *sqlSer = [[sqlService alloc] init];
    NSMutableArray *temparray=  [sqlSer getuserList];
    if ([temparray count]==0) {
        NSLog(@"error temparray is null");
        return NULL;
    }
    else {
        return  [temparray objectAtIndex:3];
    }
}


- (void)sendWeiBoWithText:(NSString *)text image:(UIImage *)image url:(NSString *)URL
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];

    //NSString *sendText = [text URLEncodedString];
	    
	[params setObject:(text ? text : @"") forKey:@"status"];
	
    if (image)
    {
		[params setObject:image forKey:@"pic"];
		NSLog(@"image is not null");
        [self loadRequestWithMethodName:@"statuses/upload.json"
                             httpMethod:@"POST"
                                 params:params
                           postDataType:kWBRequestPostDataTypeMultipart
                       httpHeaderFields:nil];
    }
    if (URL) {
        NSURL *imagepathurl = [[NSURL alloc] initWithString:URL];
        [params setObject:imagepathurl forKey:@"pic"];
		NSLog(@"url is not null");
        [self loadRequestWithMethodName:@"statuses/upload.json"
                             httpMethod:@"POST"
                                 params:params
                           postDataType:kWBRequestPostDataTypeMultipart
                       httpHeaderFields:nil];
    }
    if(!URL && !image){
        [self loadRequestWithMethodName:@"statuses/update.json"
                             httpMethod:@"POST"
                                 params:params
                           postDataType:kWBRequestPostDataTypeNormal
                       httpHeaderFields:nil];
    }
}

#pragma mark - WBAuthorizeDelegate Methods

- (void)authorize:(WBAuthorize *)authorize didSucceedWithAccessToken:(NSString *)theAccessToken userID:(NSString *)theUserID expiresIn:(NSInteger)seconds
{
    self.accessToken = theAccessToken;
    self.userID = theUserID;
    self.expireTime = [[NSDate date] timeIntervalSince1970] + seconds;
    
    [self saveAuthorizeDataToKeychain];
    /*
    if ([delegate respondsToSelector:@selector(engineDidLogIn:)])
    {
        [delegate engineDidLogIn:self];
    }
	*/
}

- (void)authorize:(WBAuthorize *)authorize didFailWithError:(NSError *)error
{
    if ([delegate respondsToSelector:@selector(engine:didFailToLogInWithError:)])
    {
        [delegate engine:self didFailToLogInWithError:error];
    }
}

#pragma mark - WBRequestDelegate Methods

- (void)request:(WBRequest *)request didFinishLoadingWithResult:(id)result
{
    if ([delegate respondsToSelector:@selector(engine:requestDidSucceedWithResult:)])
    {
        [delegate engine:self requestDidSucceedWithResult:result];
    }
    else {
        
        if([result isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *dict = (NSDictionary *)result;
            NSString *screen_name = [dict objectForKey:@"screen_name"];
            NSLog(@"screen_name is %@",screen_name);
            sqlService *sqlSer = [[sqlService alloc] init];
            [sqlSer updateUserScreenName:screen_name uid:self.userID.doubleValue];
        }
        [self setLoginStatus: 1];
        [preferenceObject reloadSpecifiers];
        NSLog(@"------Success Being Called--------");
        [hud setText: @"登陆成功"];
        [hud done];
        [hud performSelector:@selector(hide) withObject:nil afterDelay:1.2];
    }

}

- (void)request:(WBRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    if ([delegate respondsToSelector:@selector(engine:requestDidFailWithError:)])
    {
        [delegate engine:self requestDidFailWithError:error];
    }
    else
    {
        NSLog(@"getUserScreenName Error is %@",error);
        [hud setText: @"登陆失败"];
        [hud done];
        [hud performSelector:@selector(hide) withObject:nil afterDelay:1.2];
        [self deleteAuthorizeDataInKeychain];

    }
}

#pragma mark - WBEngineDelegate Methods

#pragma mark Authorize

- (void)engineAlreadyLoggedIn:(WBEngine *)engine
{
    //[indicatorView stopAnimating];
    if ([engine isUserExclusive])
    {
        UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil 
                                                           message:@"请先登出！" 
                                                          delegate:nil
                                                 cancelButtonTitle:@"确定" 
                                                 otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    }
}

- (void)engineDidLogIn:(WBEngine *)engine
{
    //[indicatorView stopAnimating];
    /*
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil 
													   message:@"登录成功！" 
													  delegate:self
											 cancelButtonTitle:@"确定" 
											 otherButtonTitles:nil];
    [alertView setTag:kWBAlertViewLogInTag];
	[alertView show];
	[alertView release];
     */
}

- (void)engine:(WBEngine *)engine didFailToLogInWithError:(NSError *)error
{
    [self setLoginStatus: -1];
    //[indicatorView stopAnimating];
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil 
													   message:@"登录失败！" 
													  delegate:nil
											 cancelButtonTitle:@"确定" 
											 otherButtonTitles:nil];
	[alertView show];
	[alertView release];
     
}

- (void)engineDidLogOut:(WBEngine *)engine
{
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil 
													   message:@"登出成功！" 
													  delegate:self
											 cancelButtonTitle:@"确定" 
											 otherButtonTitles:nil];
    [alertView setTag:kWBAlertViewLogOutTag];
	[alertView show];
	[alertView release];
}

- (void)engineNotAuthorized:(WBEngine *)engine
{
    
}

- (void)engineAuthorizeExpired:(WBEngine *)engine
{
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil 
													   message:@"请重新登录！" 
													  delegate:nil
											 cancelButtonTitle:@"确定" 
											 otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


@end


