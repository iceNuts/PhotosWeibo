//
//  SinaWeiBoGetFriendslist.h
//  SinaWeiBoSDKDemo
//
//  Created by 雨骁 刘 on 12-4-9.
//  Copyright (c) 2012年 BUAA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBEngine.h"
#import "sqlService.h"
#import "WBSDKGlobal.h"
@interface SinaWeiBoGetFriendslist : NSObject <WBEngineDelegate,WBRequestDelegate>{
    //NSString *appKey;
    //NSString *appSecret;
  
    //WBEngine *engine;
    NSString *uid;
    WBRequest  *request;
    NSString *accessToken;
    NSString *screen_name;
    NSInteger countFriends;
    NSInteger next_cursor;
    NSString *totalNumber;
    NSInteger numberinCursor;
    NSInteger next_cursor_temp;
}

@property (nonatomic, retain) NSString *uid;
@property (nonatomic, retain) NSString *totalNumber;
@property (nonatomic, retain) NSString *screen_name;
@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, retain) WBRequest *request;
- (id)init;
-(void)getWeiBofriendship:(NSString *)nextcursor;
-(void)startGetFriends;
- (void)loadRequestWithMethodName:(NSString *)methodName
                       httpMethod:(NSString *)httpMethod
                           params:(NSDictionary *)params
                     postDataType:(WBRequestPostDataType)postDataType
                 httpHeaderFields:(NSDictionary *)httpHeaderFields;
@end
