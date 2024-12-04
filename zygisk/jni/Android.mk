LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := bash-example-name
LOCAL_SRC_FILES := bash-example-name.cpp
LOCAL_STATIC_LIBRARIES := libcxx
LOCAL_LDLIBS := -llog

include $(BUILD_SHARED_LIBRARY)
include jni/libcxx/Android.mk
