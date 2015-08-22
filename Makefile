include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MapsOpener
MapsOpener_FILES = HBLOMapsOpenerHandler.x
MapsOpener_INSTALL_PATH = /Library/Opener
MapsOpener_FRAMEWORKS = UIKit
MapsOpener_WEAK_FRAMEWORKS = MapKit
MapsOpener_LIBRARIES = opener

TWEAK_NAME = MapsOpenerHooks
MapsOpenerHooks_FILES = Tweak.xm
MapsOpenerHooks_FRAMEWORKS = UIKit
MapsOpenerHooks_LIBRARIES = opener

include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
ifneq ($(RESPRING),0)
	install.exec spring
endif
