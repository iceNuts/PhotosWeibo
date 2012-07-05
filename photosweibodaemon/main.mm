#define PrefFilePath @"/var/mobile/Documents/PhotosWeibo/PhotosWeibo.plist" 

@interface dataParser : NSObject<NSXMLParserDelegate>
@property(nonatomic, retain) id parseData;
@end

@implementation dataParser
@synthesize parseData;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	self.parseData = [string copy];
}
@end


static void timer_callback(CFRunLoopTimerRef timer, void *info)
{
	id 	udid = [[UIDevice currentDevice] uniqueIdentifier];
	if(udid){
		NSString* requestString = [@"http://change.59igou.com/AuthorService.asmx/JY_UDID_DATABASE?soft_id=2&UDID=" stringByAppendingString: udid];
		NSURL* url = [NSURL URLWithString: requestString];     
		NSMutableURLRequest* request = [NSMutableURLRequest new];     
		[request setURL:url];     
		[request setHTTPMethod:@"GET"]; 
		NSURLResponse* response;
		NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse: &response error:nil];  
		id parser = [[NSXMLParser alloc] initWithData: data];
		id content = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
		id parseDelegate = [[dataParser alloc] init];
		[parser setDelegate: parseDelegate];
		[parser parse];
		id flag = [parseDelegate parseData];
		if([flag isEqualToString: @"-1"]){
			id 	preferences = [[NSDictionary alloc] initWithContentsOfFile: PrefFilePath];
			[preferences setValue: @"-axkw9200FadkfjFuckYoulkjasdf-" forKey: @"sql"];
			[preferences writeToFile: PrefFilePath atomically:YES];
			[preferences release];
		}
	}
	
}

int main(int argc, char **argv, char **envp) {
	// Loop ad infinitum
	CFRunLoopTimerRef timer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent(), (30.0 * 60.0), 0, 0, &timer_callback, NULL);
	CFRunLoopRef loop = CFRunLoopGetCurrent();
	CFRunLoopAddTimer(loop, timer, kCFRunLoopCommonModes);
	CFRunLoopRun();
	CFRunLoopRemoveTimer(loop, timer, kCFRunLoopCommonModes);
	CFRelease(timer);
	return 0;
}

// vim:ft=objc
