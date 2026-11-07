TARGET := iphone:clang:9.3:8.0
INSTALL_TARGET_PROCESSES = AppStore MobileStore itunesstored
BUNDLE_NAME = com.skyglow.itunesstorex

ARCHS = armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iTunesStoreX

iTunesStoreX_FILES = Tweak.x CustomURLProtocol.m
iTunesStoreX_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

