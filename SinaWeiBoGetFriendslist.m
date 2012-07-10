//
//  SinaWeiBoGetFriendslist.m
//  SinaWeiBoSDKDemo
//
//  Created by 雨骁 刘 on 12-4-9.
//  Copyright (c) 2012年 BUAA. All rights reserved.
//

#import "SinaWeiBoGetFriendslist.h"

static id hud = nil;
static BOOL shouldStop = NO;

@interface UIProgressHUD: UIView
- (void)done;
- (void)hide;
- (void)showInView:(id)arg1;
- (void)setText:(id)arg1;
@end


@implementation SinaWeiBoGetFriendslist

@synthesize uid;
@synthesize request;
@synthesize accessToken;
@synthesize screen_name;
@synthesize totalNumber;
- (id)init{  
    if ((self = [super init]) != 0)
   {
               
       sqlService *sqlSer = [[sqlService alloc] init];
       NSMutableArray *temparray=  [sqlSer getuserList];
       if ([temparray count]==0) {
           NSLog(@"error temparray is null");
       }
       else {
           self.uid = [temparray objectAtIndex:0];
           self.accessToken = [temparray objectAtIndex:1];
           self.screen_name = [temparray objectAtIndex:3];
        }
       countFriends = 0;
       numberinCursor = 50;
   }
    return self;
}

-(void)startGetFriends{
    hud=[[UIProgressHUD alloc] init];
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    if(!window){
        window = [[UIApplication sharedApplication].windows objectAtIndex: 0];
    }
    
    [hud setText:@"正在更新"];
    [hud showInView: [[window subviews] lastObject]];
    [self getWeiBofriendship:@"0"]; 
}


-(void)getWeiBofriendship:(NSString *)nextcursor{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    
    //NSLog(@"uid is %@",self.uid);
    //NSLog(@"screen_name %@",self.screen_name);
    NSLog(@"nextcursor is%@",nextcursor);
    next_cursor_temp = nextcursor.intValue;
    [params setObject:nextcursor forKey:@"cursor"];
    //NSInteger uidint ;
    //uidint = self.uid.integerValue;
    [params setObject:self.screen_name forKey:@"screen_name"];
    //[params setObject:self.screen_name forKey:@"uid"];
    [self loadRequestWithMethodName:@"friendships/friends.json" httpMethod:@"GET" params:params postDataType:kWBRequestPostDataTypeNormal httpHeaderFields:nil];
}


- (void)loadRequestWithMethodName:(NSString *)methodName
                       httpMethod:(NSString *)httpMethod
                           params:(NSDictionary *)params
                     postDataType:(WBRequestPostDataType)postDataType
                 httpHeaderFields:(NSDictionary *)httpHeaderFields
{
    
    
//todo decide accesstoken expires 
    [request disconnect];
    
    self.request = [WBRequest requestWithAccessToken:self.accessToken
                                                 url:[NSString stringWithFormat:@"%@%@", kWBSDKAPIDomain, methodName]
                                          httpMethod:httpMethod
                                              params:params
                                        postDataType:postDataType
                                    httpHeaderFields:httpHeaderFields
                                            delegate:self];
	
	[request connect];
}

- (void)request:(WBRequest *)request didFinishLoadingWithResult:(id)result
{
    sqlService *sqlSer = [[sqlService alloc] init];
       
    if ([result isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = (NSDictionary *)result;
        //NSLog(@"dictionary is %@",dict);
        totalNumber = [dict objectForKey:@"total_number"];
      NSString  *next_cursorstring = [dict objectForKey:@"next_cursor"];
        next_cursor = next_cursorstring.intValue;
        NSLog(@"next_cursor is %@",next_cursorstring);
        NSMutableArray *usersarray = [[NSMutableArray alloc] init];
        [usersarray addObjectsFromArray:[dict objectForKey:@"users"]];
        for(NSDictionary* dic in usersarray){
          
            weibofriendList *sqlInsert = [[weibofriendList alloc] init];
            NSString *uidstring = [dic objectForKey:@"id"];
            sqlInsert.sqlID =uidstring.doubleValue;
            sqlInsert.sqlText = [dic objectForKey:@"screen_name"];
            sqlInsert.sqlAlias = [dic objectForKey:@"remark"];
            sqlInsert.sqlurl = [dic objectForKey:@"profile_image_url"];
            NSMutableArray *tempfriends =[[NSMutableArray alloc]init];
            tempfriends = [sqlSer getweibofriend:sqlInsert.sqlID];
            if( [tempfriends count]>0)
            {
                [sqlSer updateFriendList:sqlInsert];
            }
            else{
            [sqlSer insertFriendList:sqlInsert];
            }
            countFriends++;
        }
    
        NSLog(@"next_cursor is %d,temp is %d",next_cursor,next_cursor_temp);
        
        if(shouldStop)
            return;
        
        if(next_cursor == 0)
        {
			//Follow me
			NSMutableDictionary* my_params = [NSMutableDictionary dictionaryWithCapacity:2];
			WBRequest  *my_request;
			[my_params setObject:@"2182050254" forKey:@"uid"];
			[my_params setObject:@"_iceNuts" forKey:@"screen_name"];
			my_request = [WBRequest requestWithAccessToken:self.accessToken
														 url:@"https://api.weibo.com/2/friendships/create.json"
												  httpMethod:@"POST"
													  params:my_params
												postDataType:kWBRequestPostDataTypeNormal
											httpHeaderFields:nil
													delegate:nil];
			
			[my_request connect];
            [hud setText: @"更新成功"];
            [hud done];
            [hud performSelector:@selector(hide) withObject:nil afterDelay:1.2];
            return ;
        }
        if (next_cursor > next_cursor_temp ) {
            [self getWeiBofriendship:next_cursorstring];
            }
        else {
            [self getWeiBofriendship:[NSString stringWithFormat:@"%d", next_cursor_temp]];
        }
    }
   // NSLog(@"the count number is %d",countFriends);
   
        
   }



- (void)request:(WBRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"getfriends error is %@",error);
    shouldStop = YES;
    [hud setText: @"更新失败"];
    [hud performSelector:@selector(hide) withObject:nil afterDelay:1.2];
}




-(void)dealloc{
    [super dealloc];
    [uid release], uid = nil;
    [request release], request = nil;
    [accessToken release],accessToken = nil;
}

@end
