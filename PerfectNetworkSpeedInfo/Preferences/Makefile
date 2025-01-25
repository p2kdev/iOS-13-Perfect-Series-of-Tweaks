export TARGET = iphone:clang:13.7:13.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PerfectNetworkSpeedInfoPrefs
PerfectNetworkSpeedInfoPrefs_FILES = NSPRootListController.xm
PerfectNetworkSpeedInfoPrefs_INSTALL_PATH = /Library/PreferenceBundles
PerfectNetworkSpeedInfoPrefs_FRAMEWORKS = UIKit
PerfectNetworkSpeedInfoPrefs_PRIVATE_FRAMEWORKS = Preferences
PerfectNetworkSpeedInfoPrefs_CFLAGS += -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PerfectNetworkSpeedInfoPrefs.plist$(ECHO_END)
