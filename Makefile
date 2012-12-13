TARGET = iphone::5.1:5.0

include theos/makefiles/common.mk

TWEAK_NAME = MapsOpener
MapsOpener_FILES = Tweak.xm
MapsOpener_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
