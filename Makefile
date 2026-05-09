TARGET := iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES = YeepsCompanion

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YeepsCompanion
YeepsCompanion_FILES = Tweak.x Overlay.mm
YeepsCompanion_FRAMEWORKS = UIKit SceneKit AVFoundation AudioToolbox
YeepsCompanion_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-stage::
	mkdir -p $(THEOS_STAGING_DIR)/var/mobile/Documents/YeepsPlus/Sounds/
	cp BlueBands.mp3 $(THEOS_STAGING_DIR)/var/mobile/Documents/YeepsPlus/Sounds/
