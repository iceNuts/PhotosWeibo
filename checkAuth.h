#import <sqlite3.h>


#define PrefFilePath @"/var/mobile/Documents/PhotosWeibo/PhotosWeibo.plist" 

@interface checkAuth : NSObject
-(BOOL) isAuthorized;
@end