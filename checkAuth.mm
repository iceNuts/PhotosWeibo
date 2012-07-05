#import "checkAuth.h"

id preferences;
sqlite3 *_database;

static BOOL open_db(){
	//获取数据库路径
	NSString *path = @"/var/mobile/Documents/PhotosWeibo/weibodbv2.3.sql";
	
	//文件管理器
	NSFileManager *fileManager = [NSFileManager defaultManager];
	//判断数据库是否存在
	BOOL find = [fileManager fileExistsAtPath:path];
	
	//如果数据库存在，则用sqlite3_open直接打开（不要担心，如果数据库不存在sqlite3_open会自动创建）
	if (find) {
		
		//打开数据库，这里的[path UTF8String]是将NSString转换为C字符串，因为SQLite3是采用可移植的C(而不是
		//Objective-C)编写的，它不知道什么是NSString.
		if(sqlite3_open([path UTF8String], &_database) != SQLITE_OK) {			
			//如果打开数据库失败则关闭数据库
			sqlite3_close(_database);
			NSLog(@"Error: open database file.");
			return NO;
		}
		return YES;
	}
	return NO;
}

@implementation checkAuth

-(BOOL) isAuthorized{
	if(open_db()){
		
		sqlite3_stmt *statement = nil;
		
		char * sql = "select authID from authTable";
		if(_database){
			NSLog(@"db done!");
		}
		if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
			NSLog(@"Error: failed to prepare statement with message:get authlist.");
			sqlite3_finalize(statement);
			sqlite3_close(_database);
			return NO;
		}else{
			NSString *authID = nil;
			while(sqlite3_step(statement) == SQLITE_ROW){
				if(sqlite3_column_text(statement, 0))
					authID =[[NSString alloc] initWithFormat:@"%s", sqlite3_column_text(statement, 0)];
			}
			sqlite3_finalize(statement);
			sqlite3_close(_database);
			preferences = [[NSDictionary alloc] initWithContentsOfFile: PrefFilePath];
			id code = [preferences objectForKey:@"sql"];
			if(code && authID && [code isEqualToString: authID]){
				return YES;
			}else{
				return NO;
			}
		}
	}
	return NO;
}

@end