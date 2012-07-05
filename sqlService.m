//
//  sqlService.m
//  SQLite3Test
//
//  Created by fengxiao on 11-11-28.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "sqlService.h"
#import <string.h>
@implementation weibofriendList

@synthesize sqlID;
@synthesize sqlText;
@synthesize sqlAlias;
@synthesize sqlurl;
-(id) init
{
	sqlID = (double)0;
	sqlText = @"";
    sqlAlias = @"";
    sqlurl = @"";
	return self;
};
-(void) dealloc
{
	if (sqlText != nil) {
		[sqlText release];
	}
    if(sqlAlias !=nil){
        [sqlAlias release];
    }
	[super dealloc];
}

@end


@implementation sqlService

@synthesize _database;

- (id)init
{
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

//获取document目录并返回数据库目录
- (NSString *)dataFilePath{
    
	NSString *documentsDirectory = @"/var/mobile/Documents/PhotosWeibo/";
	return [documentsDirectory stringByAppendingPathComponent:kFilename];
	
}

//创建，打开数据库
- (BOOL)openDB {
	
	//获取数据库路径
	NSString *path = [self dataFilePath];
    
    //NSLog(@"data file path is %@",path);
    
	//文件管理器
	NSFileManager *fileManager = [NSFileManager defaultManager];
	//判断数据库是否存在
	BOOL find = [fileManager fileExistsAtPath:path];
	
	//如果数据库存在，则用sqlite3_open直接打开（不要担心，如果数据库不存在sqlite3_open会自动创建）
	if (find) {
		
		//NSLog(@"Database file have already existed.");
		
		//打开数据库，这里的[path UTF8String]是将NSString转换为C字符串，因为SQLite3是采用可移植的C(而不是
		//Objective-C)编写的，它不知道什么是NSString.
		if(sqlite3_open([path UTF8String], &_database) != SQLITE_OK) {
			
			//如果打开数据库失败则关闭数据库
			sqlite3_close(self._database);
			NSLog(@"Error: open database file.");
			return NO;
		}
		
		//创建一个新表
		[self createFriendList:self._database];
		[self createUserList:self._database];
		return YES;
	}
	//如果发现数据库不存在则利用sqlite3_open创建数据库（上面已经提到过），与上面相同，路径要转换为C字符串
	if(sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
		
		//创建一个新表
		[self createFriendList:self._database];
		[self createUserList:self._database];
        return YES;
    } else {
		//如果创建并打开数据库失败则关闭数据库
		sqlite3_close(self._database);
		NSLog(@"Error: open database file.");
		return NO;
    }
	return NO;
}

//创建用户信息表
-(BOOL) createUserList:(sqlite3 *)db{

    char *sql = "create table if not exists UsersTable(uID double PRIMARY KEY,accessToken text,expireTime double,screenName text,tweetText text)";
    sqlite3_stmt *statement;
    NSInteger sqlReturn = sqlite3_prepare_v2(_database, sql, -1, &statement, nil);

    if(sqlReturn != SQLITE_OK) {
		NSLog(@"Error: failed to prepare statement:create user table");
		return NO;
	}

    int success = sqlite3_step(statement);

    sqlite3_finalize(statement);
	
	//执行SQL语句失败
	if ( success != SQLITE_DONE) {
		NSLog(@"Error: failed to dehydrate:create table test");
		return NO;
	}
    //NSLog(@"Create table 'UsersTable' successed.");
	return YES;
}

//创建用户关注表
- (BOOL) createFriendList:(sqlite3*)db {
	
	//这句是大家熟悉的SQL语句
	char *sql = "create table if not exists friendsTable(uID double PRIMARY KEY,screenName text,url text)";
	
	sqlite3_stmt *statement;
	//sqlite3_prepare_v2 接口把一条SQL语句解析到statement结构里去. 使用该接口访问数据库是当前比较好的的一种方法
	NSInteger sqlReturn = sqlite3_prepare_v2(_database, sql, -1, &statement, nil);
	//第一个参数跟前面一样，是个sqlite3 * 类型变量，
	//第二个参数是一个 sql 语句。
	//第三个参数我写的是-1，这个参数含义是前面 sql 语句的长度。如果小于0，sqlite会自动计算它的长度（把sql语句当成以\0结尾的字符串）。
	//第四个参数是sqlite3_stmt 的指针的指针。解析以后的sql语句就放在这个结构里。
	//第五个参数我也不知道是干什么的。为nil就可以了。
	//如果这个函数执行成功（返回值是 SQLITE_OK 且 statement 不为NULL ），那么下面就可以开始插入二进制数据。
	
	
	//如果SQL语句解析出错的话程序返回
	if(sqlReturn != SQLITE_OK) {
		NSLog(@"Error: failed to prepare statement:create friends table");
		return NO;
	}
	
	//执行SQL语句
	int success = sqlite3_step(statement);
	//释放sqlite3_stmt 
	sqlite3_finalize(statement);
	
	//执行SQL语句失败
	if ( success != SQLITE_DONE) {
		NSLog(@"Error: failed to dehydrate:create table test");
		return NO;
	}
	//NSLog(@"Create table 'friendsTable' successed.");
	return YES;
}

-(BOOL) deleteUserTable{
    NSString *path = [self dataFilePath];
    if(sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
		
		
		NSString *DeleteTable=@"DROP TABLE IF EXISTS UsersTable";
        
        char *errorMsg;
        
        if (sqlite3_exec(_database, [DeleteTable UTF8String], NULL, NULL, &errorMsg)==SQLITE_OK) {
            
            sqlite3_close(_database);
          //  NSLog(@"delect  user  table------------------------");
            return YES;
        }
        else {
            NSLog(@"errro msg is %s",errorMsg);
            return NO;
        }
        
    } 
    else {
        NSLog(@"open db failed");
        return NO;
    }
}
- (BOOL) deleteFriendTable{

    NSLog(@"Delete tabel start");
    NSString *path = [self dataFilePath];
    if(sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
		
		
		NSString *DeleteTable=@"DROP TABLE IF EXISTS friendsTable";
        
        char *errorMsg;
        
        if (sqlite3_exec(_database, [DeleteTable UTF8String], NULL, NULL, &errorMsg)==SQLITE_OK) {
            
            sqlite3_close(_database);
           // NSLog(@"delect  friends table------------------------");
            return YES;
        }
        else {
            NSLog(@"errro msg is %s",errorMsg);
            return NO;
        }

    } 
      else {
            NSLog(@"open db failed");
              return NO;
            }
}

-(BOOL)insertUserList: (double)uID userAccessToken:(NSString*) accessToken userExpireTime:(double) expireTime{
if ([self openDB]) {
   // NSLog(@"whether openDb");
    sqlite3_stmt *statement;
    
    //这个 sql 语句特别之处在于 values 里面有个? 号。在sqlite3_prepare函数里，?号表示一个未定的值，它的值等下才插入。
    static char *sql = "INSERT INTO UsersTable(uID,accessToken,expireTime) VALUES(?, ?, ?)";
    
    int success2 = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
    if (success2 != SQLITE_OK) {
        NSLog(@"Error: failed to insert:testTable");
        sqlite3_close(_database);
        return NO;
    }
    
    //这里的数字1，2，3代表第几个问号，这里将两个值绑定到两个绑定变量
    sqlite3_bind_double(statement, 1, uID);
    sqlite3_bind_text(statement, 2, [accessToken UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_double(statement,3,expireTime);
    
    //执行插入语句
    success2 = sqlite3_step(statement);
    //释放statement
    sqlite3_finalize(statement);
    
    //如果插入失败
    if (success2 == SQLITE_ERROR) {
        NSLog(@"Error: failed to insert into the UsersLists with message.");
        //关闭数据库
        sqlite3_close(_database);
        return NO;
    }
    //关闭数据库
    sqlite3_close(_database);
    return YES;
}
return NO;

}

//插入数据
-(BOOL) insertFriendList:(weibofriendList *)insertList {
	
	//先判断数据库是否打开
	if ([self openDB]) {
		//NSLog(@"whether openDb");
		sqlite3_stmt *statement;
		
		//这个 sql 语句特别之处在于 values 里面有个? 号。在sqlite3_prepare函数里，?号表示一个未定的值，它的值等下才插入。
		static char *sql = "INSERT INTO friendsTable(uID, screenName,url) VALUES(?, ?, ?)";
		
		int success2 = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
		if (success2 != SQLITE_OK) {
			NSLog(@"Error: failed to insert:friends table");
			sqlite3_close(_database);
			return NO;
		}
		
		//这里的数字1，2，3代表第几个问号，这里将两个值绑定到两个绑定变量
        sqlite3_bind_double(statement, 1, insertList.sqlID);
        NSLog(@"insert sqlAlias is %@",insertList.sqlAlias);
        
         if(![insertList.sqlAlias isEqualToString:@""])
         {
             NSString * tempString = [insertList.sqlText stringByAppendingString:[@"(" stringByAppendingString:[insertList.sqlAlias stringByAppendingString:@")"]]];
             sqlite3_bind_text(statement, 2, [tempString UTF8String], -1, SQLITE_TRANSIENT);
             sqlite3_bind_text(statement, 3, [insertList.sqlurl UTF8String], -1, SQLITE_TRANSIENT);
         }
        else
        {
            sqlite3_bind_text(statement, 2, [insertList.sqlText UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [insertList.sqlurl UTF8String], -1, SQLITE_TRANSIENT);
        }
		
		//执行插入语句
		success2 = sqlite3_step(statement);
		//释放statement
		sqlite3_finalize(statement);
		
		//如果插入失败
		if (success2 == SQLITE_ERROR) {
			NSLog(@"Error: failed to insert into the database friends table with message.");
			//关闭数据库
			sqlite3_close(_database);
			return NO;
		}
		//关闭数据库
		sqlite3_close(_database);
		return YES;
	}
	return NO;
}

-(BOOL)updateUserScreenName:(NSString*) screen_name uid:(double)userid{
    
    if ([self openDB]) {
        // NSLog(@"whether openDb");
        sqlite3_stmt *statement;
        
        //这个 sql 语句特别之处在于 values 里面有个? 号。在sqlite3_prepare函数里，?号表示一个未定的值，它的值等下才插入。
        static char *sql = "update UsersTable set screenName = ?  WHERE uID = ?";
        
        int success2 = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
        if (success2 != SQLITE_OK) {
            NSLog(@"Error: failed to insert:testTable");
            sqlite3_close(_database);
            return NO;
        }
        
        //这里的数字1，2，3代表第几个问号，这里将两个值绑定到两个绑定变量
        sqlite3_bind_text(statement, 1, [screen_name UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_double(statement, 2, userid);
        
        
        //执行插入语句
        success2 = sqlite3_step(statement);
        //释放statement
        sqlite3_finalize(statement);
        
        //如果插入失败
        if (success2 == SQLITE_ERROR) {
            NSLog(@"Error: failed to insert into the UsersLists with screen_name.");
            //关闭数据库
            sqlite3_close(_database);
            return NO;
        }
        //关闭数据库
        sqlite3_close(_database);
        return YES;
    }
    return NO;
}

// 获取用户信息数据
- (NSMutableArray*)getuserList{
	
	NSMutableArray *array = [[NSMutableArray alloc] init];
	//判断数据库是否打开
	if ([self openDB]) {
		
		sqlite3_stmt *statement = nil;
		//sql语句
        char *sql = "SELECT uID,accessToken,expireTime,screenName FROM UsersTable";
		
		if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
			NSLog(@"Error: failed to prepare statement with message:get userList.");
			return NO;
		}
		else {
			//查询结果集中一条一条的遍历所有的记录，这里的数字对应的是列值。
			while (sqlite3_step(statement) == SQLITE_ROW) {
				//weibofriendList* sqlList = [[weibofriendList alloc] init] ;
				//[array addObject:sqlite3_column_int(statement,0)];
                NSNumber *uid = [[NSNumber alloc] initWithDouble:sqlite3_column_double(statement, 0)];
				[array insertObject:uid atIndex:0];
               NSString* strText   = [[NSString alloc] initWithFormat:@"%s", sqlite3_column_text(statement, 1)];
                [array insertObject:strText atIndex:1];
                NSNumber *expireTime = [[NSNumber alloc]initWithDouble:sqlite3_column_double(statement, 2)];
                [array insertObject:expireTime atIndex:2];
                char* strText1   = (char*)sqlite3_column_text(statement, 3);
                NSString *temp = [NSString stringWithUTF8String:strText1];
                [array insertObject:temp atIndex:3];
                //NSLog(@"sqlist sqltext is %d",sqlList.sqlID);
			}
		}
		sqlite3_finalize(statement);
		sqlite3_close(_database);
	}
	
	return [array retain];
}

-(double)getUserID
{
    NSMutableArray *array = [[NSMutableArray alloc] init];

    if ([self openDB]) {
		
		sqlite3_stmt *statement = nil;
		//sql语句
        char *sql = "SELECT uID FROM UsersTable";
		
		if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
			NSLog(@"Error: failed to prepare statement with message:get userList.");
			return NO;
		}
		else {
			//查询结果集中一条一条的遍历所有的记录，这里的数字对应的是列值。
			while (sqlite3_step(statement) == SQLITE_ROW) {
                NSNumber *uid = [[NSNumber alloc] initWithDouble:sqlite3_column_double(statement, 0)];
				[array insertObject:uid atIndex:0];
            }
		}
		sqlite3_finalize(statement);
		sqlite3_close(_database);
	}
    double a= [[array objectAtIndex:0] doubleValue];
    NSLog(@"userID is %f",a);
    return [[array objectAtIndex:0] doubleValue];
}

-(BOOL)updateTweetText:(NSString*)text{
    double uid = [self getUserID]; 
    if ([self openDB]) {
        // NSLog(@"whether openDb");
        sqlite3_stmt *statement;
        
        //这个 sql 语句特别之处在于 values 里面有个? 号。在sqlite3_prepare函数里，?号表示一个未定的值，它的值等下才插入。
        static char *sql = "update UsersTable set tweetText = ?  WHERE uID = ?";
        
        int success2 = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
        if (success2 != SQLITE_OK) {
            NSLog(@"Error: failed to update:tweetText");
            sqlite3_close(_database);
            return NO;
        }
        
        //这里的数字1，2，3代表第几个问号，这里将两个值绑定到两个绑定变量
        sqlite3_bind_text(statement, 1, [text UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_double(statement, 2, uid);
        
        
        //执行插入语句
        success2 = sqlite3_step(statement);
        //释放statement
        sqlite3_finalize(statement);
        
        //如果插入失败
        if (success2 == SQLITE_ERROR) {
            NSLog(@"Error: failed to insert into the UsersLists with screen_name.");
            //关闭数据库
            sqlite3_close(_database);
            return NO;
        }
        //关闭数据库
        sqlite3_close(_database);
        return YES;
    }
    return NO;
}

-(BOOL)deleteTweetText{
    double uid = [self getUserID]; 
    if ([self openDB]) {
        // NSLog(@"whether openDb");
        sqlite3_stmt *statement;
        
        //这个 sql 语句特别之处在于 values 里面有个? 号。在sqlite3_prepare函数里，?号表示一个未定的值，它的值等下才插入。
        static char *sql = "update UsersTable set tweetText = ?  WHERE uID = ?";
        
        int success2 = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
        if (success2 != SQLITE_OK) {
            NSLog(@"Error: failed to delete:tweetText");
            sqlite3_close(_database);
            return NO;
        }
        
        //这里的数字1，2，3代表第几个问号，这里将两个值绑定到两个绑定变量
        sqlite3_bind_text(statement, 1, [@"" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_double(statement, 2, uid);
        
        
        //执行插入语句
        success2 = sqlite3_step(statement);
        //释放statement
        sqlite3_finalize(statement);
        
        //如果插入失败
        if (success2 == SQLITE_ERROR) {
            NSLog(@"Error: failed to delete  the UsersLists' tweetText");
            //关闭数据库
            sqlite3_close(_database);
            return NO;
        }
        //关闭数据库
        sqlite3_close(_database);
        return YES;
    }
    return NO;
}

-(NSDictionary*) getTweetText
{
     double uid = [self getUserID]; 
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	//判断数据库是否打开
	if ([self openDB]) {
		sqlite3_stmt *statement = nil;
		//sql语句
        //sql语句
        NSString *sqlString = @"SELECT tweetText FROM UsersTable WHERE uID =match";
        NSString *sqlfinalString = [sqlString stringByReplacingOccurrencesOfString:@"match"  withString:[NSString stringWithFormat:@"%f", uid]];        
        char *sql = (char *)[sqlfinalString UTF8String];
        if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
			NSLog(@"Error: failed to prepare statement with message:get tweetText.");
			return nil;
		}
		else {
			while (sqlite3_step(statement) == SQLITE_ROW) {
				char* strText   = (char*)sqlite3_column_text(statement, 0);
                NSString *temp = [[NSString alloc] initWithString:@""];
                if(strText != nil)
                {
                    temp = [NSString stringWithUTF8String:strText];
                }
                [dictionary setValue:temp forKey:@"msg"];
            }
            // NSLog(@"-----LENGTH: %i------",[array count]);
		}
		sqlite3_finalize(statement);
		sqlite3_close(_database);
	}
    return [dictionary retain];
}

//获取friends数据
- (NSMutableArray*)getweibofriendList{
	
	NSMutableArray *array = [[NSMutableArray alloc] init];
	//判断数据库是否打开
	if ([self openDB]) {
		
		sqlite3_stmt *statement = nil;
		//sql语句
		char *sql = "SELECT uID, screenName FROM friendsTable";
		
		if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
			NSLog(@"Error: failed to prepare statement with message:get testValue.");
			return NO;
		}
		else {
			//查询结果集中一条一条的遍历所有的记录，这里的数字对应的是列值。
			while (sqlite3_step(statement) == SQLITE_ROW) {
				char* strText   = (char*)sqlite3_column_text(statement, 1);
                NSString *temp = [NSString stringWithUTF8String:strText];
                [array addObject:temp];
            }
            NSLog(@"-----LENGTH: %i------",[array count]);
		}
		sqlite3_finalize(statement);
		sqlite3_close(_database);
	}
	
	return [array retain];
}


//根据uid取出用户关注人数据
-(NSMutableArray*) getweibofriend:(double)theuid
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:10];
	//判断数据库是否打开
	if ([self openDB]) {
		
		sqlite3_stmt *statement = nil;
		//sql语句
		char *sql = "SELECT screenName FROM friendsTable WHERE uID = ?";
		
		if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
			NSLog(@"Error: failed to prepare statement with message:search testValue.");
			return NO;
		}
		else {
			sqlite3_bind_double(statement, 1, theuid);
			//查询结果集中一条一条的遍历所有的记录，这里的数字对应的是列值。
			while (sqlite3_step(statement) == SQLITE_ROW) {
				weibofriendList* sqlList = [[weibofriendList alloc] init] ;
				sqlList.sqlID    = theuid;
				char* strText   = (char*)sqlite3_column_text(statement, 0);
                sqlList.sqlText = [[NSString alloc] initWithCString: strText encoding:NSUTF8StringEncoding];
                [array addObject:sqlList];
				[sqlList release];
			}
		}
		sqlite3_finalize(statement);
		sqlite3_close(_database);
	}
	
	return [array retain];

}

//以字符串作为开头搜索friends数据库
-(NSDictionary *) getweibofriendHead: (NSString *)nametitle
{
    //NSMutableArray *array = [[NSMutableArray alloc] init];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	//判断数据库是否打开
	if ([self openDB]) {
		int count = 0;
		sqlite3_stmt *statement = nil;
		//sql语句
        NSString *sqlString = @"SELECT screenName,url FROM friendsTable WHERE screenName LIKE '%match%'";
        NSString *sqlfinalString = [sqlString stringByReplacingOccurrencesOfString:@"match"  withString:nametitle];
        char *sql = (char *)[sqlfinalString UTF8String];
        if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
			NSLog(@"Error: failed to prepare statement with message:get testValue.");
			return NO;
		}
		else {
			while (sqlite3_step(statement) == SQLITE_ROW) {
                weibofriendList *friendTemp = [[weibofriendList alloc]init];
				char* strText   = (char*)sqlite3_column_text(statement, 0);
                NSString *temp = [NSString stringWithUTF8String:strText];
                
                char* strTextUrl = (char*)sqlite3_column_text(statement, 1);
                NSString *tempUrl  = [NSString stringWithUTF8String:strTextUrl];
                
                friendTemp.sqlurl = tempUrl;
                [dictionary setValue:temp forKey:[NSString stringWithFormat:@"%i",count]];
                count++;
            }
            // NSLog(@"-----LENGTH: %i------",[array count]);
		}
		sqlite3_finalize(statement);
		sqlite3_close(_database);
	}
    return [dictionary retain];
}

//更新数据
-(BOOL) updateFriendList:(weibofriendList *)updateList{
	
	if ([self openDB]) {
		
		//我想下面几行已经不需要我讲解了，嘎嘎 
		sqlite3_stmt *statement;
		//组织SQL语句
		char *sql = "update friendsTable set screenName = ? ,url = ? WHERE uID = ?";
		
		//将SQL语句放入sqlite3_stmt中
		int success = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
		if (success != SQLITE_OK) {
			NSLog(@"Error: failed to update:testTable");
			sqlite3_close(_database);
			return NO;
		}
		
		//这里的数字1，2，3代表第几个问号。这里只有1个问号，这是一个相对比较简单的数据库操作，真正的项目中会远远比这个复杂
		//当掌握了原理后就不害怕复杂了
        
        if(![updateList.sqlAlias isEqualToString:@""])
        {
            NSString * tempString = [updateList.sqlText stringByAppendingString:[@"(" stringByAppendingString:[updateList.sqlAlias stringByAppendingString:@")"]]];
            NSLog(@"temp string is %@",tempString);
            sqlite3_bind_text(statement, 1, [tempString UTF8String], -1, SQLITE_TRANSIENT);
        }
        else
        {
            sqlite3_bind_text(statement, 1, [updateList.sqlText UTF8String], -1, SQLITE_TRANSIENT);
        }
        sqlite3_bind_text(statement, 2, [updateList.sqlurl UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_double(statement, 3, updateList.sqlID);
		
		//执行SQL语句。这里是更新数据库
		success = sqlite3_step(statement);
		//释放statement
		sqlite3_finalize(statement);
		
		//如果执行失败
		if (success == SQLITE_ERROR) {
			NSLog(@"Error: failed to update the database with message.");
			//关闭数据库
			sqlite3_close(_database);
			return NO;
		}
		//执行成功后依然要关闭数据库
		sqlite3_close(_database);
		return YES;
	}
	return NO;
}



@end



