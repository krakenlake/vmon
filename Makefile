.PHONY: clean default all

default: this


#TARGET ?= qemu-32i
#TARGET ?= qemu-32ic
#TARGET ?= qemu-32i-mini
#TARGET ?= qemu-32ic-mini
TARGET ?= qemu-64g
#TARGET ?= qemu-64gqc
#TARGET ?= qemu-64gc
#TARGET ?= vf2


DEBUG ?= -DDEBUG

ifeq ($(TARGET), qemu-32i)
	TARGET_START_ADDR	= 0x80000000
	TARGET_XLEN			= 32
	CFLAGS				+= -march=rv$(TARGET_XLEN)i -mabi=ilp32
	QEMU_FLAGS	= -machine virt -cpu rv$(TARGET_XLEN),pmp=false -smp 1 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
	RUN			= qemu-system-riscv$(TARGET_XLEN) $(QEMU_FLAGS) 
endif 

ifeq ($(TARGET), qemu-32ic)
	TARGET_START_ADDR	= 0x80000000
	TARGET_XLEN			= 32
	CFLAGS				+= -march=rv$(TARGET_XLEN)ic -mabi=ilp32
	QEMU_FLAGS	= -machine virt -cpu rv$(TARGET_XLEN),pmp=false -smp 1 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
	RUN			= qemu-system-riscv$(TARGET_XLEN) $(QEMU_FLAGS) 
endif 

ifeq ($(TARGET), qemu-32i-mini)
	TARGET_START_ADDR	= 0x80000000
	TARGET_XLEN			= 32
	CFLAGS				+= -march=rv$(TARGET_XLEN)i -mabi=ilp32
	QEMU_FLAGS	= -machine virt -cpu rv$(TARGET_XLEN),pmp=false -smp 1 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
	RUN			= qemu-system-riscv$(TARGET_XLEN) $(QEMU_FLAGS) 
endif 

ifeq ($(TARGET), qemu-32ic-mini)
	TARGET_START_ADDR	= 0x80000000
	TARGET_XLEN			= 32
	CFLAGS				+= -march=rv$(TARGET_XLEN)ic -mabi=ilp32
	QEMU_FLAGS	= -machine virt -cpu rv$(TARGET_XLEN),pmp=false -smp 1 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
	RUN			= qemu-system-riscv$(TARGET_XLEN) $(QEMU_FLAGS) 
endif 

ifeq ($(TARGET), qemu-64g)
	TARGET_START_ADDR	= 0x80000000
	TARGET_XLEN			= 64
	CFLAGS				+= -march=rv$(TARGET_XLEN)g
	QEMU_FLAGS	= -machine virt -cpu rv$(TARGET_XLEN),pmp=false -smp 2 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
	RUN			= qemu-system-riscv$(TARGET_XLEN) $(QEMU_FLAGS) 
endif 

ifeq ($(TARGET), qemu-64gc)
	TARGET_START_ADDR	= 0x80000000
	TARGET_XLEN			= 64
	CFLAGS				+= -march=rv$(TARGET_XLEN)gc	
	QEMU_FLAGS	= -machine virt -cpu rv$(TARGET_XLEN),pmp=false -smp 2 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
	RUN			= qemu-system-riscv$(TARGET_XLEN) $(QEMU_FLAGS) 
endif 

ifeq ($(TARGET), qemu-64gqc)
	TARGET_START_ADDR	= 0x80000000
	TARGET_XLEN			= 64
	CFLAGS				+= -march=rv$(TARGET_XLEN)gqc
	QEMU_FLAGS	= -machine virt -cpu rv$(TARGET_XLEN),pmp=false -smp 2 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
	RUN			= qemu-system-riscv$(TARGET_XLEN) $(QEMU_FLAGS) 
endif 

ifeq ($(TARGET), vf2)
	TARGET_START_ADDR	= 0x44000000
	TARGET_XLEN			= 64
	CFLAGS				+= -march=rv$(TARGET_XLEN)gc
define VF2_RUN_MSG

	running on VF2:
	- set TARGET = vf2 in this Makefile
	- make clean; make
	- create a FAT filesystem on SD card
	- copy build/vf2/vmon.img to SD card
	- insert SD card into VF2
	- attach GPIO-to-USB serial terminal to VF2 (e.g. minicom, 115200 baud)
	- boot into U-Boot from SPI (both dip-switches to L)
	- in U-Boot command line, load and run vmon.img:
	StarFive # fatload mmc 1:2  0x43fff000 vmon.img
	StarFive # go 44000000

endef
	export VF2_RUN_MSG 
	RUN			= @echo "$$VF2_RUN_MSG"

endif


# tools
ARCH    ?= riscv$(TARGET_XLEN)-unknown-elf
TOOLBIN ?= /opt/riscv/rv$(TARGET_XLEN)g/bin
CC      = $(TOOLBIN)/$(ARCH)-gcc
CPP     = $(TOOLBIN)/$(ARCH)-cpp
CFLAGS	+= $(DEBUG) -nostartfiles -g -I"src/include"
LD		= $(TOOLBIN)/$(ARCH)-ld
LDFLAGS = --no-warn-rwx-segments
OBJCOPY = $(TOOLBIN)/$(ARCH)-objcopy
OBJDUMP = $(TOOLBIN)/$(ARCH)-objdump
STRIP   = $(TOOLBIN)/$(ARCH)-strip
GDB		= $(TOOLBIN)/$(ARCH)-gdb


# directories
SRCD	= src
LOGD	= log


# names
NAME = vmon
CONFIG = config
BUILDROOT = build
BUILD = $(BUILDROOT)/$(TARGET)
RELEASE = release
SRC = $(wildcard $(SRCD)/*.S)
OBJ = $(SRC:$(SRCD)/%.S=$(BUILD)/%.o)
DEP = $(OBJ:%.o=%.d)


# dependencies
-include $(DEP)


# targets
this: $(BUILD)/$(NAME).img $(BUILD)/$(NAME)-stripped.elf
	ls -al $(BUILD)/$(NAME).img $(BUILD)/$(NAME)-stripped.elf

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/$(NAME).img: $(BUILD)/$(NAME).elf
	$(OBJCOPY) $(BUILD)/$(NAME).elf -O binary $@

$(BUILD)/$(NAME).elf: $(BUILD)/link.ld Makefile $(OBJ)
	$(LD) -T $(BUILD)/link.ld $(LDFLAGS) -o $@ $(OBJ)

$(BUILD)/link.ld: linker/link.ld.in Makefile $(BUILD)
	$(CPP) $(CFLAGS) -DPATH_TO_MAIN_O=$(BUILD)/main.o -DTARGET_START_ADDR=$(TARGET_START_ADDR) -E -P -x c $< > $@ 

$(BUILD)/config.h: $(CONFIG)/config.$(TARGET).h
	cp $< $@

$(BUILD)/%.o: $(SRCD)/%.S Makefile $(BUILD)/config.h
	$(CC) $(CFLAGS) -I$(BUILD) -MMD -c $< -o $@

$(BUILD)/$(NAME)-stripped.elf: $(BUILD)/$(NAME).elf
	$(STRIP) $< -o $@

$(RELEASE)/vmon-$(TARGET).img: $(BUILD)/$(NAME).img
	mkdir -p $(RELEASE)
	cp $< $@
	ls -al $(RELEASE)/*.img

release: $(RELEASE)/vmon-$(TARGET).img

clean:
	rm -fr $(BUILD)

veryclean:
	rm -fr $(BUILDROOT) $(RELEASE)

run: $(BUILD)/$(NAME).img
	$(RUN)

debug:
	$(GDB) entry -ex "target remote :1234"

device-tree:
	qemu-system-riscv$(TARGET_XLEN) $(QEMU_FLAGS) -machine dumpdtb=$(BUILD)/qemu.dtb
	dtc -I dtb -O dts $(BUILD)/qemu.dtb -o $(BUILD)/qemu-device-tree.dts
	less $(BUILD)/qemu-device-tree.dts

all: 
	make TARGET=qemu-32i release
	make TARGET=qemu-32ic release
	make TARGET=qemu-32i-mini release
	make TARGET=qemu-32ic-mini release
	make TARGET=qemu-64g release
	make TARGET=qemu-64gc release
	make TARGET=qemu-64gqc release
	make TARGET=vf2 release


