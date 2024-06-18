.PHONY: clean default

default: all


#TARGET	= qemu-rv32g
TARGET	= qemu-rv64g
#TARGET	= qemu-rv64gc
#TARGET	= vf2

ifeq ($(TARGET), qemu-rv32g)
	ARCH    	= riscv32-unknown-elf
	XLEN		= 32
	TOOLBIN 	= /opt/riscv/rv32g/bin
	ADDFLAGS	= -DXLEN=$(XLEN) -march=rv32g
	RUN			= qemu-system-riscv32 -machine virt -cpu rv32,pmp=false -smp 2 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
endif

ifeq ($(TARGET), qemu-rv64g)
	ARCH    	= riscv64-unknown-elf
	XLEN		= 64
	TOOLBIN 	= /opt/riscv/rv64g/bin
	ADDFLAGS	= -DXLEN=$(XLEN) -march=rv64g
	RUN			= qemu-system-riscv64 -machine virt -cpu rv64,pmp=false -smp 2 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
endif

ifeq ($(TARGET), qemu-rv64gc)
	ARCH    	= riscv64-unknown-elf
	XLEN		= 64
	TOOLBIN 	= /opt/riscv/rv64g/bin
	ADDFLAGS	= -DXLEN=$(XLEN) -march=rv64gc -mabi=lp64
	RUN			= qemu-system-riscv64 -machine virt -cpu rv64,pmp=false -smp 2 -gdb tcp::1234 -bios none -serial stdio -display none -kernel $(BUILD)/$(NAME).img
endif

ifeq ($(TARGET), vf2)
	ARCH    	= riscv64-unknown-elf
	XLEN		= 64
	TOOLBIN 	= /opt/riscv/rv64g/bin
	ADDFLAGS	= -DXLEN=$(XLEN) -march=rv64g
	RUN			= echo "for running please move executable to hardware"
endif

NAME	= vmon
CC      = $(TOOLBIN)/$(ARCH)-gcc
CFLAGS	= $(ADDFLAGS) -nostartfiles -g -I"src/include"
LD		= $(TOOLBIN)/$(ARCH)-ld
LDFLAGS = --no-warn-rwx-segments
OBJCOPY = $(TOOLBIN)/$(ARCH)-objcopy
OBJDUMP = $(TOOLBIN)/$(ARCH)-objdump
STRIP   = $(TOOLBIN)/$(ARCH)-strip
GDB		= $(TOOLBIN)/$(ARCH)-gdb
SRCD	= src
LOGD	= log

BUILD	= build/$(TARGET)
SRC = $(wildcard $(SRCD)/*.S)
OBJ = $(SRC:$(SRCD)/%.S=$(BUILD)/%.o)
DEP = $(OBJ:%.o=%.d)

-include $(DEP)


all: $(BUILD) $(BUILD)/$(NAME).img $(BUILD)/$(NAME)-stripped.img
	ls -al $(BUILD)/$(NAME).img $(BUILD)/$(NAME)-stripped.img
	
$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/$(NAME).img: $(BUILD)/$(NAME).elf
	$(OBJCOPY) $(BUILD)/$(NAME).elf -I binary $@

$(BUILD)/$(NAME)-stripped.img: $(BUILD)/$(NAME).img
	$(STRIP) $< -o $@

$(BUILD)/$(NAME).elf: linker/link.ld.$(TARGET) Makefile $(OBJ)
	$(LD) -T linker/link.ld.$(TARGET) $(LDFLAGS) -o $@ $(OBJ)

$(BUILD)/%.o: $(SRCD)/%.S Makefile
	$(CC) $(CFLAGS) -MMD -c $< -o $@


clean:
	rm -f $(BUILD)/*.o $(BUILD)/*.d $(BUILD)/*.elf $(BUILD)/*.img $(BUILD)/*.log $(BUILD)/*.objdump

run: $(BUILD)/$(NAME).img
	$(RUN)

debug:
	$(GDB) entry -ex "target remote :1234"

