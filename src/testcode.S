#include "vmon/config.h"

#ifdef WITH_TESTCODE

.global testcode

.text


testcode:
    addi a0,a0,1

#ifdef WITH_TESTCODE_RV32I
.option push
.option norvc
testcode_RV32I:
    ecall
    ebreak 
    add     x0, x0, x0
    add     x31, x31, x31
    sub     x0, x0, x0
    sub     x31, x31, x31
    xor     x0, x0, x0
    xor     x31, x31, x31
    or      x0, x0, x0
    or      x31, x31, x31
    and     x0, x0, x0
    and     x31, x31, x31
    sll     x0, x0, x0
    sll     x31, x31, x31
    srl     x0, x0, x0
    srl     x31, x31, x31
    sra     x0, x0, x0
    sra     x31, x31, x31
    slt     x0, x0, x0
    slt     x31, x31, x31
    sltu    x0, x0, x0
    sltu    x31, x31, x31
    addi    x0, x0, 0
    addi    x31, x31, 0
    addi    x0, x0, 2047
    addi    x31, x31, 2047
    addi    x0, x0, -2048
    addi    x31, x31, -2048
    xori    x0, x0, 0
    xori    x31, x31, 0
    xori    x0, x0, 2047
    xori    x31, x31, 2047
    xori    x0, x0, -2048
    xori    x31, x31, -2048
    ori     x0, x0, 0
    ori     x31, x31, 0
    ori     x0, x0, 2047
    ori     x31, x31, 2047
    ori     x0, x0, -2048
    ori     x31, x31, -2048
    andi    x0, x0, 0
    andi    x31, x31, 0
    andi    x0, x0, 2047
    andi    x31, x31, 2047
    andi    x0, x0, -2048
    andi    x31, x31, -2048
    slli    x0, x0, 0x0
    slli    x31, x31, 0x0
    slli    x0, x0, 0x1f
    slli    x31, x31, 0x1f
    srli    x0, x0, 0x0
    srli    x31, x31, 0x0
    srli    x0, x0, 0x1f
    srli    x31, x31, 0x1f
    srai    x0, x0, 0x0
    srai    x31, x31, 0x0
    srai    x0, x0, 0x1f
    srai    x31, x31, 0x1f
    slti    x0, x0, 0x0
    slti    x31, x31, 0x0
    slti    x0, x0, 0x1f
    slti    x31, x31, 0x1f
    slti    x0, x0, 0x3f
    slti    x31, x31, 0x3f
    sltiu   x0, x0, 0x0
    sltiu   x31, x31, 0x0
    sltiu   x0, x0, 0x1f
    sltiu   x31, x31, 0x1f
    sltiu   x0, x0, 0x3f
    sltiu   x31, x31, 0x3f
    lb      x0, 0(x0) #0x0
    lb      x0, 2047(x0) #0x7ff
    lb      x0, -2048(x0) #0xfffffffffffff800   
    lh      x31, 0(x31)
    lh      x31, 2047(x31)
    lh      x31, -2048(x31)
    lw      x0, 0(x0)
    lw      x0, 2047(x0)
    lw      x0, -2048(x0)
    lbu     x31, 0(x31)
    lbu     x31, 2047(x31)
    lbu     x31, -2048(x31)
    lhu     x31, 0(x31)
    lhu     x31, 2047(x31)
    lhu     x31, -2048(x31)
    sb      x0, 0(x0)
    sb      x0, 2047(x0)
    sb      x0, -2048(x0)
    sh      x31, 0(x31)
    sh      x31, 2047(x31)
    sh      x31, -2048(x31)
    sw      x0, 0(x0)
    sw      x0, 2047(x0)
    sw      x0, -2048(x0)
testcode_branch_backward:
    beq     zero, zero, testcode_branch_backward
    beq     zero, zero, testcode_branch_forward
    bne     zero, zero, testcode_branch_backward
    bne     zero, zero, testcode_branch_forward
    blt     zero, zero, testcode_branch_backward
    blt     zero, zero, testcode_branch_forward
    bge     zero, zero, testcode_branch_backward
    bge     zero, zero, testcode_branch_forward
    bltu    zero, zero, testcode_branch_backward
    bltu    zero, zero, testcode_branch_forward
    bgeu    zero, zero, testcode_branch_backward
    bgeu    zero, zero, testcode_branch_forward
testcode_branch_forward: 
testcode_jal_backward:
    jal     x0, testcode_jal_backward
    jal     x0, testcode_jal_forward
    jal     x31, testcode_jal_backward
    jal     x31, testcode_jal_forward
    jalr    x0, 2047
    jalr    x0, -2048
    jalr    x31, 2047
    jalr    x31, -2048
testcode_jal_forward:
    lui     x0, 1048575
    auipc   x0, 1048575
.option pop /* norvc */
.size testcode_RV32I, .-testcode_RV32I
#endif /* WITH_TESTCODE_RV32I */

# RV64I
#if defined(WITH_TESTCODE_RV64I) && (XLEN >= 64)
.option push
.option norvc
testcode_RV64I:
    lwu     x0, 0(x0)
    lwu     x0, 2047(x0)
    lwu     x0, -2048(x0)
    lwu     x31, 0(x0)
    lwu     x31, 2047(x0)
    lwu     x31, -2048(x0)
    ld      x0, 0(x0)
    ld      x0, 2047(x0)
    ld      x0, -2048(x0)
    ld      x31, 0(x0)
    ld      x31, 2047(x0)
    ld      x31, -2048(x0)
    sd      x0, 0(x0)
    sd      x0, 2047(x0)
    sd      x0, -2048(x0)
    sd      x31, 0(x0)
    sd      x31, 2047(x0)
    sd      x31, -2048(x0)
    addiw   x0, x0, 0
    addiw   x31, x31, 0
    addiw   x0, x0, 31
    addiw   x31, x31, 31
    addiw   x0, x0, 63
    addiw   x31, x31, 63
    srliw   x0, x0, 0
    srliw   x31, x31, 0
    srliw   x0, x0, 31
    srliw   x31, x31, 31
    srli    x0, x0, 0x3f
    srli    x31, x31, 0x3f
    slliw   x0, x0, 0
    slliw   x31, x31, 0
    slliw   x0, x0, 31
    slliw   x31, x31, 31
    slli    x0, x0, 0x3f
    slli    x31, x31, 0x3f
    sraiw   x0, x0, 0
    sraiw   x31, x31, 0
    sraiw   x0, x0, 31
    sraiw   x31, x31, 31
    srai    x0, x0, 0x3f
    srai    x31, x31, 0x3f
    addw    x0, x0, 0
    addw    x31, x31, 0
    addw    x0, x0, 31
    addw    x31, x31, 31
    subw    x0, x0, x0
    subw    x0, x0, x31
    subw    x31, x31, x0
    subw    x31, x31, x31
    srlw    x0, x0, 0
    srlw    x31, x31, 0
    srlw    x0, x0, 31
    srlw    x31, x31, 31
    sllw    x0, x0, 0
    sllw    x31, x31, 0
    sllw    x0, x0, 31
    sllw    x31, x31, 31
    sraw    x0, x0, 0
    sraw    x31, x31, 0
    sraw    x0, x0, 31
    sraw    x31, x31, 31
.option pop /* norvc */
.size testcode_RV64I, .-testcode_RV64I
#endif /* WITH_TESTCODE_RV32I */


#ifdef WITH_TESTCODE_RVM
.option push
.option norvc
testcode_RVM:
    # RV32M
    mul     x0, x1, x2
    mul     x29, x30, x31
    mulh    x0, x1, x2
    mulh    x29, x30, x31
    mulhu   x0, x1, x2
    mulhu   x29, x30, x31
    mulhsu  x0, x1, x2
    mulhsu  x29, x30, x31
    div     x0, x1, x2
    div     x29, x30, x31
    divu    x0, x1, x2
    divu    x29, x30, x31
    rem     x0, x1, x2
    rem     x29, x30, x31
    remu    x0, x1, x2
    remu    x29, x30, x31
    # RV64M
    #if XLEN >= 64 
        mulw     x0, x1, x2
        mulw     x29, x30, x31
        divw     x0, x1, x2
        divw     x29, x30, x31
        remw     x0, x1, x2
        remw     x29, x30, x31
        remuw    x0, x1, x2
        remuw    x29, x30, x31
    #endif
.option pop /* norvc */
.size testcode_RVM, .-testcode_RVM
#endif /* WITH_TESTCODE_RVM */


#ifdef WITH_TESTCODE_RVA
.option push
.option norvc
testcode_RVA:
    # RV32A
    lr.w            x0, (x1)
    lr.w            x30, (x31)
    lr.w.aq         x0, (x1)
    lr.w.aq         x30, (x31)
    lr.w.rl         x0, (x1)
    lr.w.rl         x30, (x31)
    lr.w.aqrl       x0, (x1)
    lr.w.aqrl       x30, (x31)
    sc.w            x0, x0, (x0)
    sc.w            x31, x31, (x31)
    sc.w.aq         x0, x0, (x0)
    sc.w.aq         x31, x31, (x31)
    sc.w.rl         x0, x0, (x0)
    sc.w.rl         x31, x31, (x31)
    sc.w.aqrl       x0, x0, (x0)
    sc.w.aqrl       x31, x31, (x31)
    amoswap.w       x0, x0, (x0)
    amoswap.w       x31, x31, (x31)
    amoswap.w.aq    x0, x0, (x0)
    amoswap.w.aq    x31, x31, (x31)
    amoswap.w.rl    x0, x0, (x0)
    amoswap.w.rl    x31, x31, (x31)
    amoswap.w.aqrl  x0, x0, (x0)
    amoswap.w.aqrl  x31, x31, (x31)
    amoadd.w        x0, x0, (x0)
    amoadd.w        x31, x31, (x31)
    amoadd.w.aq     x0, x0, (x0)
    amoadd.w.aq     x31, x31, (x31)
    amoadd.w.rl     x0, x0, (x0)
    amoadd.w.rl     x31, x31, (x31)
    amoadd.w.aqrl   x0, x0, (x0)
    amoadd.w.aqrl   x31, x31, (x31)
    amoxor.w        x0, x0, (x0)
    amoxor.w        x31, x31, (x31)
    amoxor.w.aq     x0, x0, (x0)
    amoxor.w.aq     x31, x31, (x31)
    amoxor.w.rl     x0, x0, (x0)
    amoxor.w.rl     x31, x31, (x31)
    amoxor.w.aqrl   x0, x0, (x0)
    amoxor.w.aqrl   x31, x31, (x31)
    amoand.w        x0, x0, (x0)
    amoand.w        x31, x31, (x31)
    amoand.w.aq     x0, x0, (x0)
    amoand.w.aq     x31, x31, (x31)
    amoand.w.rl     x0, x0, (x0)
    amoand.w.rl     x31, x31, (x31)
    amoand.w.aqrl   x0, x0, (x0)
    amoand.w.aqrl   x31, x31, (x31)
    amoor.w         x0, x0, (x0)
    amoor.w         x31, x31, (x31)
    amoor.w.aq      x0, x0, (x0)
    amoor.w.aq      x31, x31, (x31)
    amoor.w.rl      x0, x0, (x0)
    amoor.w.rl      x31, x31, (x31)
    amoor.w.aqrl    x0, x0, (x0)
    amoor.w.aqrl    x31, x31, (x31)
    amomin.w        x0, x0, (x0)
    amomin.w        x31, x31, (x31)
    amomin.w.aq     x0, x0, (x0)
    amomin.w.aq     x31, x31, (x31)
    amomin.w.rl     x0, x0, (x0)
    amomin.w.rl     x31, x31, (x31)
    amomin.w.aqrl   x0, x0, (x0)
    amomin.w.aqrl   x31, x31, (x31)
    amomax.w        x0, x0, (x0)
    amomax.w        x31, x31, (x31)
    amomax.w.aq     x0, x0, (x0)
    amomax.w.aq     x31, x31, (x31)
    amomax.w.rl     x0, x0, (x0)
    amomax.w.rl     x31, x31, (x31)
    amomax.w.aqrl   x0, x0, (x0)
    amomax.w.aqrl   x31, x31, (x31)
    amominu.w       x0, x0, (x0)
    amominu.w       x31, x31, (x31)
    amominu.w.aq    x0, x0, (x0)
    amominu.w.aq    x31, x31, (x31)
    amominu.w.rl    x0, x0, (x0)
    amominu.w.rl    x31, x31, (x31)
    amominu.w.aqrl  x0, x0, (x0)
    amominu.w.aqrl  x31, x31, (x31)
    amomaxu.w       x0, x0, (x0)
    amomaxu.w       x31, x31, (x31)
    amomaxu.w.aq    x0, x0, (x0)
    amomaxu.w.aq    x31, x31, (x31)
    amomaxu.w.rl    x0, x0, (x0)
    amomaxu.w.rl    x31, x31, (x31)
    amomaxu.w.aqrl  x0, x0, (x0)
    amomaxu.w.aqrl  x31, x31, (x31)
    # RV64A
    #if XLEN >= 64
        lr.d            x0, (x1)
        lr.d            x30, (x31)
        lr.d.aq         x0, (x1)
        lr.d.aq         x30, (x31)
        lr.d.rl         x0, (x1)
        lr.d.rl         x30, (x31)
        lr.d.aqrl       x0, (x1)
        lr.d.aqrl       x30, (x31)
        sc.d            x0, x0, (x0)
        sc.d            x31, x31, (x31)
        sc.d.aq         x0, x0, (x0)
        sc.d.aq         x31, x31, (x31)
        sc.d.rl         x0, x0, (x0)
        sc.d.rl         x31, x31, (x31)
        sc.d.aqrl       x0, x0, (x0)
        sc.d.aqrl       x31, x31, (x31)
        amoswap.d       x0, x0, (x0)
        amoswap.d       x31, x31, (x31)
        amoswap.d.aq    x0, x0, (x0)
        amoswap.d.aq    x31, x31, (x31)
        amoswap.d.rl    x0, x0, (x0)
        amoswap.d.rl    x31, x31, (x31)
        amoswap.d.aqrl  x0, x0, (x0)
        amoswap.d.aqrl  x31, x31, (x31)
        amoadd.d        x0, x0, (x0)
        amoadd.d        x31, x31, (x31)
        amoadd.d.aq     x0, x0, (x0)
        amoadd.d.aq     x31, x31, (x31)
        amoadd.d.rl     x0, x0, (x0)
        amoadd.d.rl     x31, x31, (x31)
        amoadd.d.aqrl   x0, x0, (x0)
        amoadd.d.aqrl   x31, x31, (x31)
        amoxor.d        x0, x0, (x0)
        amoxor.d        x31, x31, (x31)
        amoxor.d.aq     x0, x0, (x0)
        amoxor.d.aq     x31, x31, (x31)
        amoxor.d.rl     x0, x0, (x0)
        amoxor.d.rl     x31, x31, (x31)
        amoxor.d.aqrl   x0, x0, (x0)
        amoxor.d.aqrl   x31, x31, (x31)
        amoand.d        x0, x0, (x0)
        amoand.d        x31, x31, (x31)
        amoand.d.aq     x0, x0, (x0)
        amoand.d.aq     x31, x31, (x31)
        amoand.d.rl     x0, x0, (x0)
        amoand.d.rl     x31, x31, (x31)
        amoand.d.aqrl   x0, x0, (x0)
        amoand.d.aqrl   x31, x31, (x31)
        amoor.d         x0, x0, (x0)
        amoor.d         x31, x31, (x31)
        amoor.d.aq      x0, x0, (x0)
        amoor.d.aq      x31, x31, (x31)
        amoor.d.rl      x0, x0, (x0)
        amoor.d.rl      x31, x31, (x31)
        amoor.d.aqrl    x0, x0, (x0)
        amoor.d.aqrl    x31, x31, (x31)
        amomin.d        x0, x0, (x0)
        amomin.d        x31, x31, (x31)
        amomin.d.aq     x0, x0, (x0)
        amomin.d.aq     x31, x31, (x31)
        amomin.d.rl     x0, x0, (x0)
        amomin.d.rl     x31, x31, (x31)
        amomin.d.aqrl   x0, x0, (x0)
        amomin.d.aqrl   x31, x31, (x31)
        amomax.d        x0, x0, (x0)
        amomax.d        x31, x31, (x31)
        amomax.d.aq     x0, x0, (x0)
        amomax.d.aq     x31, x31, (x31)
        amomax.d.rl     x0, x0, (x0)
        amomax.d.rl     x31, x31, (x31)
        amomax.d.aqrl   x0, x0, (x0)
        amomax.d.aqrl   x31, x31, (x31)
        amominu.d       x0, x0, (x0)
        amominu.d       x31, x31, (x31)
        amominu.d.aq    x0, x0, (x0)
        amominu.d.aq    x31, x31, (x31)
        amominu.d.rl    x0, x0, (x0)
        amominu.d.rl    x31, x31, (x31)
        amominu.d.aqrl  x0, x0, (x0)
        amominu.d.aqrl  x31, x31, (x31)
        amomaxu.d       x0, x0, (x0)
        amomaxu.d       x31, x31, (x31)
        amomaxu.d.aq    x0, x0, (x0)
        amomaxu.d.aq    x31, x31, (x31)
        amomaxu.d.rl    x0, x0, (x0)
        amomaxu.d.rl    x31, x31, (x31)
        amomaxu.d.aqrl  x0, x0, (x0)
        amomaxu.d.aqrl  x31, x31, (x31)
    #endif
.option pop /* norvc */
.size testcode_RVA, .-testcode_RVA
#endif /* WITH_TESTCODE_RVA */


#ifdef WITH_TESTCODE_RVF
testcode_RVF:
.option push
.option norvc
# TODO
.option pop /* norvc */
.size testcode_RVF, .-testcode_RVF
#endif /* WITH_TESTCODE_RVF */


#if defined (WITH_TESTCODE_RVC) && defined (ENABLE_RVC)
testcode_RVC:
#    c.lw        a0, a0, 1
    c.li        s0, 1
    c.lui       s0, 1
    c.mv        s0, s1
    c.sub       s0, s1
.size testcode_RVC, .-testcode_RVC
#endif /* WITH_TESTCODE_RVC */


#ifdef WITH_TESTCODE_RVV
.option push
.option norvc
testcode_RVV:
# TODO
.option pop /* norvc */
.size testcode_RVV, .-testcode_RVV
#endif /* WITH_TESTCODE_RVV */


#ifdef WITH_TESTCODE_RVZicsr
.option push
.option norvc
testcode_RVZicsr:
    csrrw   t1, 1, t2
    csrrs   t3, cycle, t4
    csrrc   t5, cycle, t6
    csrrwi  t1, cycle, 0
    csrrsi  t2, cycle, 0
    csrrci  t3, cycle, 0
    csrrwi  t4, cycle, 31
    csrrsi  t5, cycle, 31
    csrrci  t6, cycle, 31
.option pop /* norvc */
.size testcode_RVZicsr, .-testcode_RVZicsr
#endif /* WITH_TESTCODE_RVZicsr */


#ifdef WITH_TESTCODE_RVPRIV
.option push
.option norvc
testcode_RVPRIV:
    wfi
.option pop /* norvc */
.size testcode_RVPRIV, .-testcode_RVPRIV
#endif /* WITH_TESTCODE_RVPRIV */

#ifdef WITH_TESTCODE_PSEUDO
.option push
.option norvc
testcode_Pseudo:
    jalr    x0, x1, 0           # ret
    ret
    addi    x0, x0, 0           # nop
    nop
.option pop /* norvc */
.size testcode_Pseudo, .-testcode_Pseudo
#endif /* WITH_TESTCODE_PSEUDO */


.size testcode, .-testcode
#endif /* WITH_TESTCODE */
