#
# Copyright (C) 2012 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This file does the bulk of the work to auto post-process kernel headers
# provided by the device, board, and/or product.
#
# The build system exposes several variables for where to find the kernel
# headers:
#   TARGET_DEVICE_KERNEL_HEADERS is automatically created for the current
#       device being built. It is set as $(TARGET_DEVICE_DIR)/kernel-headers,
#       e.g. device/samsung/tuna/kernel-headers. This directory is not
#       explicitly set by anyone, the build system always adds this subdir.
#
#   TARGET_BOARD_KERNEL_HEADERS is specified by the BoardConfig.mk file
#       to allow other directories to be included. This is useful if there's
#       some common place where a few headers are being kept for a group
#       of devices. For example, device/<vendor>/common/kernel-headers could
#       contain some headers for several of <vendor>'s devices.
#
#   TARGET_PRODUCT_KERNEL_HEADERS is generated by the product inheritance
#       graph. This allows architecture products to provide headers for the
#       devices using that architecture. For example,
#       hardware/ti/omap4xxx/omap4.mk will specify
#       PRODUCT_VENDOR_KERNEL_HEADERS variable that specify where the omap4
#       specific headers are, e.g. hardware/ti/omap4xxx/kernel-headers.
#       The build system then combines all the values specified by all the
#       PRODUCT_VENDOR_KERNEL_HEADERS directives in the product inheritance
#       tree and then exports a TARGET_PRODUCT_KERNEL_HEADERS variable.
#
# The directories specified in these three variables are scanned for header
# files (files with .h suffix), processed with the clean_header.py script,
# and dumped under TARGET_OUT_KERNEL_HEADERS
# (typically $OUT/obj/kernel-headers). This subdirectory is then
# automatically added to the include path.
#
# The files to be generated are added as a dependency to the
# all_copied_headers rule to make sure that they are generated before
# any C/C++ file that may need them.
#
#

LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)

_all_kernel_header_dirs := \
	$(TARGET_DEVICE_KERNEL_HEADERS) \
	$(TARGET_BOARD_KERNEL_HEADERS) \
	$(TARGET_PRODUCT_KERNEL_HEADERS)

define add-kernel-header-dir
$(eval _headers := $(patsubst $(1)/%.h,%.h,$(shell find $(1)/ -type f -name '*.h')))
$(eval GEN := $(addprefix $(TARGET_OUT_KERNEL_HEADERS)/,$(_headers)))
$(GEN) : PRIVATE_PATH := $(LOCAL_PATH)
$(GEN) : PRIVATE_MODULE := kernel-headers
$(GEN) : PRIVATE_CUSTOM_TOOL = \
					$$(LOCAL_PATH)/tools/clean_header.py \
						-k $(1) -d $$(TARGET_OUT_KERNEL_HEADERS) $$< > $$@
$(GEN) : $$(LOCAL_PATH)/tools/clean_header.py
$(GEN) : $$(TARGET_OUT_KERNEL_HEADERS)/%.h : $(1)/%.h
	$$(transform-generated-source)
all_copied_headers: $(GEN)
$(eval GEN :=)
$(eval _headers :=)
endef

$(foreach d,$(_all_kernel_header_dirs),\
    $(eval $(call add-kernel-header-dir,$(d))))
