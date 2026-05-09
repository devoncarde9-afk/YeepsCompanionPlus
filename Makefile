TARGET := iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES = YeepsCompanion

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YeepsCompanion
YeepsCompanion_FILES = Tweak.x Overlay.mm
YeepsCompanion_FRAMEWORKS = UIKit SceneKit
YeepsCompanion_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
