TARGET = iphone:clang

include theos/makefiles/common.mk

TWEAK_NAME = MapsOpener
MapsOpener_FILES = Tweak.xm
MapsOpener_FRAMEWORKS = UIKit
MapsOpener_LDFLAGS = -lopener

include $(THEOS_MAKE_PATH)/tweak.mk
