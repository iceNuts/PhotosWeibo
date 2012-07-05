GO_EASY_ON_ME=1
ARCHS=armv7
include theos/makefiles/common.mk

TWEAK_NAME = tweet2Weibo
tweet2Weibo_FILES = Tweak.xm GTMBase64.m NSObject+SBJSON.m NSString+SBJSON.m SBJSON.m SBJsonBase.m SBJsonParser.m SBJsonWriter.m SFHFKeychainUtils.m WBAuthorize.m WBAuthorizeWebView.m WBEngine.m WBRequest.m SendAgent.mm WBUtil.m NSBanner.x Reachability.m sqlService.m SinaWeiBoGetFriendslist.m checkAuth.mm 
tweet2Weibo_FRAMEWORKS=CoreGraphics UIKit QuartzCore Security Foundation AudioToolBox SystemConfiguration Twitter CoreLocation MessageUI
tweet2Weibo_PRIVATE_FRAMEWORKS=BulletinBoard AppSupport SpringBoardServices
SUBPROJECTS = Photo2WeiboSettings photosweibodaemon

tweet2Weibo_LDFLAGS= -lsqlite3

TARGET_IPHONEOS_DEPLOYMENT_VERSION = 5.0

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk