#import "SendAgent.h"

static UIBackgroundTaskIdentifier bgTask;
static UIImage* cacheImage;

@implementation SendAgent

@synthesize imagePath;
@synthesize application;
@synthesize enteredText;
@synthesize rawData;

- (void)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret text:(id)mytext imgPath: (id) path{
    
    application = [UIApplication sharedApplication];
    
    //Parse engine
    engine = [[WBEngine alloc] initWithAppKey: appKey appSecret: appSecret];
    [engine setDelegate: self];
    imagePath = [path copy];
    enteredText = [mytext copy];
}

- (void)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret text:(id)mytext imgData: (id) data{
	
	application = [UIApplication sharedApplication];
    
    //Parse engine
    engine = [[WBEngine alloc] initWithAppKey: appKey appSecret: appSecret];
    [engine setDelegate: self];
    rawData = [[NSData alloc] initWithData: data];
    enteredText = [mytext copy];
}

- (void)sendWithData{
	//Background handler
    bgTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.timeout" userInfo:nil];
        //Avoid killing app
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;        
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *raw_image = [UIImage imageWithData: rawData];
	
		if([enteredText isEqualToString:@""]){
			[engine sendWeiBoWithText: @"分享图片" image: raw_image url:nil];
		}else{
			[engine sendWeiBoWithText: enteredText image: raw_image url:nil];
		}    
	});
}

- (void) send{
    //Background handler
    bgTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.timeout" userInfo:nil];
        //Avoid killing app
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;        
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
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
       
        if(!imagePath){
            [engine sendWeiBoWithText: enteredText image:nil url:nil];
            
        }else if([fix isEqualToString: @"gif"])
        {
            if([enteredText isEqualToString:@""]){
                [engine sendWeiBoWithText: @"分享图片" image:nil url:imagePath];
            }
            else
            {
                [engine sendWeiBoWithText: enteredText image:nil url:imagePath];
            }
        }else{
            
            if([enteredText isEqualToString:@""]){
                [engine sendWeiBoWithText: @"分享图片" image:send url:nil];
            }else{
                [engine sendWeiBoWithText: enteredText image:send url:nil];
            }
        }
    });
    
}

- (void)engine:(WBEngine *)engine requestDidSucceedWithResult:(id)result
{
    SystemSoundID sound;
	NSURL *url = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/tweet_sent.caf" isDirectory: NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url,&sound);
	AudioServicesPlaySystemSound(sound);
	    
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: UIImagePNGRepresentation(cacheImage), @"image", enteredText, @"msg",nil ];
    CPDistributedMessagingCenter *center;
	center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	[center sendMessageName:@"com.icenuts.photo2weibo.success" userInfo: dictionary];
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}

- (void)engine:(WBEngine *)engine requestDidFailWithError:(NSError *)error
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: UIImagePNGRepresentation(cacheImage), @"image", enteredText, @"msg",nil ];
        
	SystemSoundID sound;
	NSURL *url = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/Tink.caf" isDirectory: NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url,&sound);
	AudioServicesPlaySystemSound(sound);
		
   	CPDistributedMessagingCenter *center;
	center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	[center sendMessageName:@"com.icenuts.photo2weibo.failure" userInfo: dictionary];
    
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}

- (void)engineNotAuthorized:(WBEngine *)engine
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: UIImagePNGRepresentation(cacheImage), @"image", @"发送失败，您还没有设置帐户", @"msg",nil ];
        
	SystemSoundID sound;
	NSURL *url = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/Tink.caf" isDirectory: NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url,&sound);
	AudioServicesPlaySystemSound(sound);
		
   	CPDistributedMessagingCenter *center;
	center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	[center sendMessageName:@"com.icenuts.photo2weibo.failure" userInfo: dictionary];
    
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}

- (void)engineAuthorizeExpired:(WBEngine *)engine
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: UIImagePNGRepresentation(cacheImage), @"image", @"发送失败，帐户已过期，请重新登陆", @"msg",nil ];
        
	SystemSoundID sound;
	NSURL *url = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/Tink.caf" isDirectory: NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url,&sound);
	AudioServicesPlaySystemSound(sound);
		
   	CPDistributedMessagingCenter *center;
	center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	[center sendMessageName:@"com.icenuts.photo2weibo.failure" userInfo: dictionary];
    
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}

@end