ARCHS=armv7
include theos/makefiles/common.mk

BUNDLE_NAME = Photo2WeiboSettings
Photo2WeiboSettings_FILES = Photo2WeiboSettings.xm Photo2WeiboHelp.mm Photo2WeiboImage.mm
Photo2WeiboSettings_INSTALL_PATH = /Library/PreferenceBundles
Photo2WeiboSettings_FRAMEWORKS = UIKit MessageUI
Photo2WeiboSettings_PRIVATE_FRAMEWORKS = Preferences AppSupport

Photo2WeiboSettings_LDFLAGS=../obj/tweet2Weibo.dylib

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Photo2WeiboSettings.plist$(ECHO_END)
