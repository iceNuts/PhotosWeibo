#import "WBEngine.h"
#import "Reachability.h"
#import "tweet2weibo/AudioServices.h"
#import <tweet2weibo/TWTweetComposeViewController.h>
#import "Global.h"


//IPC Declaration
@interface CPDistributedMessagingCenter
+ (id)centerNamed:(id)arg1;
- (BOOL)sendMessageName:(id)arg1 userInfo:(id)arg2;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(id)arg1 target:(id)arg2 selector:(SEL)arg3;
- (id)sendMessageAndReceiveReplyName:(id)arg1 userInfo:(id)arg2;
@end


@interface SendAgent: NSObject<WBEngineDelegate>{
    WBEngine *engine;
}

@property (nonatomic, retain) id imagePath;
@property (nonatomic, retain) id application;
@property (nonatomic, retain) id enteredText;
@property (nonatomic, retain) NSData *rawData;


- (void)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret text:(id)mytext imgPath: (id) path;
- (void)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret text:(id)mytext imgData: (id) data;
- (void) send;
- (void) sendWithData;
@end

