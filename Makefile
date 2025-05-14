.PHONY: clean default

default: all


TARGET 		?= qemu
#TARGET 	?= vf2

#XLEN 		?= 32
XLEN 		?= 64

#FLEN 		?= 32
FLEN 		?= 64

#ISA_STRING	?= g
ISA_STRING	?= gc
#ISA_STRING	?= gqc


DEBUG ?= -DDEBUG


ifeq ($(TARGET), qemu)
	ARCH    	?= riscv$(XLEN)-unknown-elf
	TOOLBIN 	?= /opt/riscv/rv$(XLEN)g/bin
	ADDFLAGS	= -DHW_QEMU -DXLEN=$(XLEN) -DFLEN=$(FLEN) -march=rv$(XLEN)$(ISA_STRING) 
	QEMU_FLAGS	= -machine virt -cpu rv$(XLEN),pmp=false,f=true -smp 2 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
	RUN			= qemu-system-riscv$(XLEN) $(QEMU_FLAGS) 
endif


ifeq ($(TARGET), vf2)
	ARCH    	?= riscv64-unknown-elf
	XLEN		= 64
	TOOLBIN 	?= /opt/riscv/rv64g/bin
	ADDFLAGS	= -DHW_VF2 -DXLEN=$(XLEN) -DFLEN=$(FLEN) -march=rv64gc
	PLATFORM	= vf2
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
CC      = $(TOOLBIN)/$(ARCH)-gcc
CFLAGS	= $(DEBUG) $(ADDFLAGS) -nostartfiles -g -I"src/include"
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
PLATFORM	?= $(TARGET)-rv$(XLEN)$(ISA_STRING)
BUILD		= build/$(PLATFORM)
SRC = $(wildcard $(SRCD)/*.S)
OBJ = $(SRC:$(SRCD)/%.S=$(BUILD)/%.o)
DEP = $(OBJ:%.o=%.d)


# dependencies
-include $(DEP)


#targets
all: $(BUILD) $(BUILD)/$(NAME).img $(BUILD)/$(NAME)-stripped.elf
	ls -al $(BUILD)/$(NAME).img $(BUILD)/$(NAME)-stripped.elf

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/$(NAME).img: $(BUILD)/$(NAME).elf
	$(OBJCOPY) $(BUILD)/$(NAME).elf -O binary $@

$(BUILD)/$(NAME)-stripped.elf: $(BUILD)/$(NAME).elf
	$(STRIP) $< -o $@

$(BUILD)/$(NAME).elf: linker/link.ld.$(PLATFORM) Makefile $(OBJ)
	$(LD) -T linker/link.ld.$(PLATFORM) $(LDFLAGS) -o $@ $(OBJ)

$(BUILD)/%.o: $(SRCD)/%.S Makefile
	$(CC) $(CFLAGS) -MMD -c $< -o $@

clean:
	rm -f $(BUILD)/*.o $(BUILD)/*.d $(BUILD)/*.elf $(BUILD)/*.img $(BUILD)/*.log $(BUILD)/*.objdump

run: $(BUILD)/$(NAME).img
	$(RUN)

debug:
	$(GDB) entry -ex "target remote :1234"

device-tree:
	qemu-system-riscv$(XLEN) $(QEMU_FLAGS) -machine dumpdtb=$(BUILD)/qemu.dtb
	dtc -I dtb -O dts $(BUILD)/qemu.dtb -o $(BUILD)/qemu-device-tree.dts
	less $(BUILD)/qemu-device-tree.dts

