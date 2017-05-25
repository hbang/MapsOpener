TARGET = iphone:clang:latest:5.1

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MapsOpener
MapsOpener_FILES = HBLOMapsOpenerHandler.x QueryString.x
MapsOpener_INSTALL_PATH = /Library/Opener
MapsOpener_PRIVATE_FRAMEWORKS = MobileCoreServices
MapsOpener_WEAK_FRAMEWORKS = MapKit
MapsOpener_EXTRA_FRAMEWORKS = Opener
MapsOpener_CFLAGS = -include Global.h -fobjc-arc

TWEAK_NAME = MapsOpenerHooks
MapsOpenerHooks_FILES = Tweak.x QueryString.x
MapsOpenerHooks_EXTRA_FRAMEWORKS = Opener
MapsOpenerHooks_CFLAGS = -include Global.h -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
ifneq ($(RESPRING),0)
	install.exec spring
endif

test::
	install.exec "cycript -p SpringBoard" < test.cy
