export THEOS_PACKAGE_SCHEME=rootless
export TARGET = iphone:clang:13.7:13.0

PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)

export ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk
GO_EASY_ON_ME = 1

TWEAK_NAME = PerfectNetworkSpeedInfo
PerfectNetworkSpeedInfo_FILES = PerfectNetworkSpeedInfo.xm
PerfectNetworkSpeedInfo_CFLAGS += -fobjc-arc -Wno-logical-op-parentheses

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk