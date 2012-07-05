//
//  sqlService.h
//  SQLite3Test
//
//  Created by fengxiao on 11-11-28.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define kFilename  @"weibodbv2.3.sql"
@class weibofriendList;
@class userList;
@interface sqlService : NSObject {

	sqlite3 *_database;

}

@property (nonatomic) sqlite3 *_database;
-(BOOL) createUserList:(sqlite3 *)db; //创建用户数据表
-(BOOL) deleteUserTable; //删除用户数据表
- (NSMutableArray*)getuserList; //获取用户数据
-(BOOL) createFriendList:(sqlite3 *)db;//创建friends关系数据库
-(BOOL) insertFriendList:(weibofriendList *)insertList;//插入friends数据									
-(BOOL) updateFriendList:(weibofriendList *)updateList;//更新数据
-(BOOL)updateUserScreenName:(NSString*) screen_name uid:(double)userid;
-(NSMutableArray*)getweibofriendList;//获取全部数据
- (BOOL) deleteFriendTable;
-(BOOL)insertUserList: (double)uID userAccessToken:(NSString*) accessToken userExpireTime:(double) expireTime;
-(NSMutableArray *) getweibofriend:(double)theuid;
-(NSDictionary *) getweibofriendHead: (NSString *)nametitle;
-(BOOL)updateTweetText:(NSString*)text;
-(BOOL)deleteTweetText;
-(double)getUserID;
-(NSDictionary*) getTweetText; //key 是msg

@end

@interface weibofriendList : NSObject
{
	double sqlID;
	NSString *sqlText;
    NSString *sqlAlias;
    NSString *sqlurl;
}
@property (nonatomic) double sqlID;
@property (nonatomic, retain) NSString *sqlText;
@property (nonatomic, retain) NSString *sqlurl;
@property (nonatomic, retain) NSString *sqlAlias;
@end

