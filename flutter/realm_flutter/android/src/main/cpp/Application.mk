APP_BUILD_SCRIPT := Android.mk

APP_ABI := armeabi-v7a x86
APP_PLATFORM := android-16

APP_MK_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

NDK_MODULE_PATH := $(APP_MK_DIR)$(HOST_DIRSEP)$(THIRD_PARTY_NDK_DIR)$(HOST_DIRSEP)$(APP_MK_DIR)

APP_STL := c++_static
APP_CPPFLAGS := -std=c++14
APP_CPPFLAGS += -frtti
APP_CPPFLAGS += -fexceptions
APP_CPPFLAGS += -DREALM_HAVE_CONFIG
APP_CPPFLAGS += -fomit-frame-pointer
APP_CPPFLAGS += -fvisibility=hidden

# Make sure every shared lib includes a .note.gnu.build-id header
APP_LDFLAGS := -Wl,--build-id
APP_LDFLAGS += -llog
APP_LDFLAGS += -landroid
# APP_LDFLAGS += -llibc++_static
APP_LDFLAGS += -fvisibility=hidden

# Workaround for getting UINT64_MAX defined
# https://stackoverflow.com/questions/16748392/cant-find-symbols-in-stdint-h
APP_CPPFLAGS += -D__STDC_LIMIT_MACROS=1


NDK_TOOLCHAIN_VERSION := clang