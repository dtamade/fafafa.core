#!/bin/sh
DoExitAsm ()
{ echo "An error occurred while assembling $1"; exit 1; }
DoExitLink ()
{ echo "An error occurred while linking $1"; exit 1; }
echo Assembling rvv_opcode_smoke
/usr/bin/riscv64-linux-gnu-as -o lib2-smoke/riscv64-linux/rvv_opcode_smoke.o  -march=rv64gcv -mabi=lp64d lib2-smoke/riscv64-linux/rvv_opcode_smoke.s
if [ $? != 0 ]; then DoExitAsm rvv_opcode_smoke; fi
echo Linking bin2-smoke/rvv_opcode_smoke
OFS=$IFS
IFS="
"
/usr/bin/riscv64-linux-gnu-ld.bfd -m elf64lriscv         -L. -o bin2-smoke/rvv_opcode_smoke -T bin2-smoke/link60.res -e _start
if [ $? != 0 ]; then DoExitLink bin2-smoke/rvv_opcode_smoke; fi
IFS=$OFS
