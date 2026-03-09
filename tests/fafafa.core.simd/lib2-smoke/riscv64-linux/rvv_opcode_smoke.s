	.file "rvv_opcode_smoke.pas"
# Begin asmlist al_begin

.section .debug_line
	.type	.Ldebug_linesection0,@object
.Ldebug_linesection0:
	.type	.Ldebug_line0,@object
.Ldebug_line0:

.section .debug_abbrev
	.type	.Ldebug_abbrevsection0,@object
.Ldebug_abbrevsection0:
	.type	.Ldebug_abbrev0,@object
.Ldebug_abbrev0:
	.option nopic
	.attribute 4,16
	.attribute 6,0
	.attribute 5,"rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_v1p0"

.section .text.b_DEBUGSTART_$P$RVV_OPCODE_SMOKE,"ax"
.globl	DEBUGSTART_$P$RVV_OPCODE_SMOKE
	.type	DEBUGSTART_$P$RVV_OPCODE_SMOKE,@object
DEBUGSTART_$P$RVV_OPCODE_SMOKE:
# End asmlist al_begin
# Begin asmlist al_pure_assembler

.section .text.n_p$rvv_opcode_smoke_$$_rvvopcodeprobe$pointer$pointer,"ax"
	.balign 8
.globl	P$RVV_OPCODE_SMOKE_$$_RVVOPCODEPROBE$POINTER$POINTER
	.type	P$RVV_OPCODE_SMOKE_$$_RVVOPCODEPROBE$POINTER$POINTER,@function
P$RVV_OPCODE_SMOKE_$$_RVVOPCODEPROBE$POINTER$POINTER:
.Lc2:
#  CPU RV64GCV
.Ll1:
	vsetivli	x0,4,208
.Ll2:
	vle32.v	v0,0(x10)
.Ll3:
	vle32.v	v1,0(x11)
.Ll4:
	vfadd.vv	v0,v0,v1
.Ll5:
	vse32.v	v0,0(x10)
#  CPU RV64GCV
.Ll6:
	jalr	x0,x1
.Lc1:
.Lt2:
.Le0:
	.size	P$RVV_OPCODE_SMOKE_$$_RVVOPCODEPROBE$POINTER$POINTER, .Le0 - P$RVV_OPCODE_SMOKE_$$_RVVOPCODEPROBE$POINTER$POINTER
.Ll7:
# End asmlist al_pure_assembler
# Begin asmlist al_procedures

.section .text.n_main,"ax"
	.balign 8
.globl	main
	.type	main,@function
main:
.globl	PASCALMAIN
	.type	PASCALMAIN,@function
PASCALMAIN:
.Lc4:
.Ll8:
	addi	x2,x2,-16
	sd	x1,8(x2)
	sd	x8,0(x2)
	addi	x8,x2,16
	addi	x2,x2,-104
.Lj5:
	auipc	x1,%pcrel_hi(fpc_initializeunits)
	jalr	x1,x1,%pcrel_lo(.Lj5)
.Lj6:
.Ll9:
	auipc	x1,%pcrel_hi(fpc_do_exit)
	jalr	x1,x1,%pcrel_lo(.Lj6)
	ld	x8,104(x2)
	ld	x1,112(x2)
	addi	x2,x2,120
	jalr	x0,x1
.Lc3:
.Lt1:
.Le1:
	.size	main, .Le1 - main
.Ll10:

.section .text,"ax"

.section .fpc.n_links
	.quad	DEBUGSTART_$P$RVV_OPCODE_SMOKE
	.quad	DEBUGEND_$P$RVV_OPCODE_SMOKE
# End asmlist al_procedures
# Begin asmlist al_globals

.section .rodata.n_.Ld3
	.balign 8
.Ld3:
	.byte	6
	.ascii	"System"
.Le2:
	.size	.Ld3, .Le2 - .Ld3

.section .rodata.n_.Ld3
	.balign 8
.Ld4:
	.byte	7
	.ascii	"exeinfo"
.Le3:
	.size	.Ld4, .Le3 - .Ld4

.section .rodata.n_.Ld3
	.balign 8
.Ld5:
	.byte	8
	.ascii	"lnfodwrf"
.Le4:
	.size	.Ld5, .Le4 - .Ld5

.section .rodata.n_.Ld3
	.balign 8
.Ld6:
	.byte	6
	.ascii	"objpas"
.Le5:
	.size	.Ld6, .Le5 - .Ld6

.section .data.n_INITFINAL
	.balign 8
.globl	INITFINAL
	.type	INITFINAL,@object
INITFINAL:
	.quad	4,0
	.quad	INIT$_$SYSTEM
	.quad	0
	.quad	.Ld3
	.quad	INIT$_$EXEINFO
	.quad	0
	.quad	.Ld4
	.quad	INIT$_$LNFODWRF
	.quad	FINALIZE$_$LNFODWRF
	.quad	.Ld5
	.quad	0
	.quad	FINALIZE$_$OBJPAS
	.quad	.Ld6
.Le6:
	.size	INITFINAL, .Le6 - INITFINAL

.section .data.n_FPC_THREADVARTABLES
	.balign 8
.globl	FPC_THREADVARTABLES
	.type	FPC_THREADVARTABLES,@object
FPC_THREADVARTABLES:
	.quad	1
	.quad	THREADVARLIST_$SYSTEM$indirect
.Le7:
	.size	FPC_THREADVARTABLES, .Le7 - FPC_THREADVARTABLES

.section .rodata.n_FPC_RESOURCESTRINGTABLES
	.balign 8
.globl	FPC_RESOURCESTRINGTABLES
	.type	FPC_RESOURCESTRINGTABLES,@object
FPC_RESOURCESTRINGTABLES:
	.quad	0
.Le8:
	.size	FPC_RESOURCESTRINGTABLES, .Le8 - FPC_RESOURCESTRINGTABLES

.section .data.n_FPC_WIDEINITTABLES
	.balign 8
.globl	FPC_WIDEINITTABLES
	.type	FPC_WIDEINITTABLES,@object
FPC_WIDEINITTABLES:
	.quad	0
.Le9:
	.size	FPC_WIDEINITTABLES, .Le9 - FPC_WIDEINITTABLES

.section .data.n_FPC_RESSTRINITTABLES
	.balign 8
.globl	FPC_RESSTRINITTABLES
	.type	FPC_RESSTRINITTABLES,@object
FPC_RESSTRINITTABLES:
	.quad	0
.Le10:
	.size	FPC_RESSTRINITTABLES, .Le10 - FPC_RESSTRINITTABLES

.section .fpc.n_version
	.balign 16
	.type	__fpc_ident,@object
__fpc_ident:
	.ascii	"FPC 3.3.1 [2026/02/06] for riscv64 - Linux"
.Le11:
	.size	__fpc_ident, .Le11 - __fpc_ident

.section .data.n___stklen
	.balign 8
.globl	__stklen
	.type	__stklen,@object
__stklen:
	.quad	10485760
.Le12:
	.size	__stklen, .Le12 - __stklen

.section .data.n___heapsize
	.balign 8
.globl	__heapsize
	.type	__heapsize,@object
__heapsize:
	.quad	0
.Le13:
	.size	__heapsize, .Le13 - __heapsize

.section .data.n___fpc_valgrind
	.balign 8
.globl	__fpc_valgrind
	.type	__fpc_valgrind,@object
__fpc_valgrind:
	.byte	0
.Le14:
	.size	__fpc_valgrind, .Le14 - __fpc_valgrind

.section .rodata.n_FPC_RESLOCATION
	.balign 8
.globl	FPC_RESLOCATION
	.type	FPC_RESLOCATION,@object
FPC_RESLOCATION:
	.quad	0
.Le15:
	.size	FPC_RESLOCATION, .Le15 - FPC_RESLOCATION
# End asmlist al_globals
# Begin asmlist al_dwarf_frame

.section .debug_frame
.Lc5:
	.long	.Lc7-.Lc6
.Lc6:
	.long	-1
	.byte	1
	.byte	0
	.uleb128	1
	.sleb128	-4
	.byte	1
	.byte	12
	.uleb128	2
	.uleb128	0
	.balign 8,0
.Lc7:
	.long	.Lc9-.Lc8
.Lc8:
	.long	.Lc5
	.quad	.Lc2
	.quad	.Lc1-.Lc2
	.balign 8,0
.Lc9:
	.long	.Lc12-.Lc11
.Lc11:
	.long	.Lc5
	.quad	.Lc4
	.quad	.Lc3-.Lc4
	.byte	7
	.uleb128	1
	.balign 8,0
.Lc12:
# End asmlist al_dwarf_frame
# Begin asmlist al_dwarf_info

.section .debug_info
	.type	.Ldebug_info0,@object
.Ldebug_info0:
	.long	.Ledebug_info0-.Lf2
.Lf2:
	.short	3
	.long	.Ldebug_abbrev0
	.byte	8
	.uleb128	1
	.ascii	"logs/rvv_opcode_smoke.pas\000"
	.ascii	"Free Pascal 3.3.1 2026/02/06\000"
	.ascii	"/work/tests/fafafa.core.simd/\000"
	.byte	9
	.byte	3
	.long	.Ldebug_line0
	.quad	DEBUGSTART_$P$RVV_OPCODE_SMOKE
	.quad	DEBUGEND_$P$RVV_OPCODE_SMOKE
# Syms - Begin Staticsymtable
# Symbol SYSTEM
# Symbol LNFODWRF
# Symbol FPINTRES
# Symbol OBJPAS
# Symbol RVV_OPCODE_SMOKE
# Symbol main
# Symbol RVVOPCODEPROBE
# Symbol SI_PRC
# Syms - End Staticsymtable
# Procdef $main; StdCall;
	.uleb128	2
	.ascii	"$main\000"
	.byte	1
	.byte	1
	.quad	main
	.quad	.Lt1
	.byte	0
# Procdef RVVOpcodeProbe(const Pointer;const Pointer);
	.uleb128	2
	.ascii	"RVVOpcodeProbe\000"
	.byte	1
	.byte	1
	.quad	P$RVV_OPCODE_SMOKE_$$_RVVOPCODEPROBE$POINTER$POINTER
	.quad	.Lt2
# Symbol A
	.uleb128	3
	.ascii	"a\000"
	.byte	2
	.byte	144
	.uleb128	10
	.long	_$RVV_OPCODE_SMOKE$_Ld1
# Symbol B
	.uleb128	3
	.ascii	"b\000"
	.byte	2
	.byte	144
	.uleb128	11
	.long	_$RVV_OPCODE_SMOKE$_Ld1
	.byte	0
# Defs - Begin unit SYSTEM has index 1
# Definition Pointer
.globl	_$RVV_OPCODE_SMOKE$_Ld1
	.type	_$RVV_OPCODE_SMOKE$_Ld1,@object
_$RVV_OPCODE_SMOKE$_Ld1:
	.uleb128	4
	.ascii	"Pointer\000"
	.long	.La1
	.type	.La1,@object
.La1:
	.uleb128	5
.Le16:
	.size	_$RVV_OPCODE_SMOKE$_Ld1, .Le16 - _$RVV_OPCODE_SMOKE$_Ld1
.globl	_$RVV_OPCODE_SMOKE$_Ld2
	.type	_$RVV_OPCODE_SMOKE$_Ld2,@object
_$RVV_OPCODE_SMOKE$_Ld2:
	.uleb128	6
	.long	_$RVV_OPCODE_SMOKE$_Ld1
# Defs - End unit SYSTEM has index 1
# Defs - Begin unit STRINGS has index 4
# Defs - End unit STRINGS has index 4
# Defs - Begin unit EXEINFO has index 3
# Defs - End unit EXEINFO has index 3
# Defs - Begin unit LNFODWRF has index 2
# Defs - End unit LNFODWRF has index 2
# Defs - Begin unit OBJPAS has index 6
# Defs - End unit OBJPAS has index 6
# Defs - Begin unit SI_PRC has index 6
# Defs - End unit SI_PRC has index 6
# Defs - Begin Staticsymtable
# Defs - End Staticsymtable
	.byte	0
	.type	.Ledebug_info0,@object
.Ledebug_info0:
# End asmlist al_dwarf_info
# Begin asmlist al_dwarf_abbrev

.section .debug_abbrev
# Abbrev 1
	.uleb128	1
	.uleb128	17
	.byte	1
	.uleb128	3
	.uleb128	8
	.uleb128	37
	.uleb128	8
	.uleb128	27
	.uleb128	8
	.uleb128	19
	.uleb128	11
	.uleb128	66
	.uleb128	11
	.uleb128	16
	.uleb128	6
	.uleb128	17
	.uleb128	1
	.uleb128	18
	.uleb128	1
	.byte	0
	.byte	0
# Abbrev 2
	.uleb128	2
	.uleb128	46
	.byte	1
	.uleb128	3
	.uleb128	8
	.uleb128	39
	.uleb128	12
	.uleb128	63
	.uleb128	12
	.uleb128	17
	.uleb128	1
	.uleb128	18
	.uleb128	1
	.byte	0
	.byte	0
# Abbrev 3
	.uleb128	3
	.uleb128	5
	.byte	0
	.uleb128	3
	.uleb128	8
	.uleb128	2
	.uleb128	10
	.uleb128	73
	.uleb128	16
	.byte	0
	.byte	0
# Abbrev 4
	.uleb128	4
	.uleb128	22
	.byte	0
	.uleb128	3
	.uleb128	8
	.uleb128	73
	.uleb128	16
	.byte	0
	.byte	0
# Abbrev 5
	.uleb128	5
	.uleb128	15
	.byte	0
	.byte	0
	.byte	0
# Abbrev 6
	.uleb128	6
	.uleb128	16
	.byte	0
	.uleb128	73
	.uleb128	16
	.byte	0
	.byte	0
	.byte	0
# End asmlist al_dwarf_abbrev
# Begin asmlist al_dwarf_line

.section .debug_line
# === header start ===
	.long	.Ledebug_line0-.Lf3
.Lf3:
	.short	3
	.long	.Lehdebug_line0-.Lf4
.Lf4:
	.byte	1
	.byte	1
	.byte	1
	.byte	255
	.byte	13
	.byte	0
	.byte	1
	.byte	1
	.byte	1
	.byte	1
	.byte	0
	.byte	0
	.byte	0
	.byte	1
	.byte	0
	.byte	0
	.byte	1
# include_directories
	.ascii	"logs\000"
	.byte	0
# file_names
	.ascii	"rvv_opcode_smoke.pas\000"
	.uleb128	1
	.uleb128	0
	.uleb128	0
	.byte	0
	.type	.Lehdebug_line0,@object
.Lehdebug_line0:
# === header end ===
# function: P$RVV_OPCODE_SMOKE_$$_RVVOPCODEPROBE$POINTER$POINTER
# [7:3]
	.byte	0
	.uleb128	9
	.byte	2
	.quad	.Ll1
	.byte	5
	.uleb128	3
	.byte	18
# [8:3]
	.byte	0
	.uleb128	9
	.byte	2
	.quad	.Ll2
	.byte	13
# [9:3]
	.byte	0
	.uleb128	9
	.byte	2
	.quad	.Ll3
	.byte	13
# [10:3]
	.byte	0
	.uleb128	9
	.byte	2
	.quad	.Ll4
	.byte	13
# [11:3]
	.byte	0
	.uleb128	9
	.byte	2
	.quad	.Ll5
	.byte	13
# [12:4]
	.byte	0
	.uleb128	9
	.byte	2
	.quad	.Ll6
	.byte	5
	.uleb128	4
	.byte	13
	.byte	0
	.uleb128	9
	.byte	2
	.quad	.Ll7
	.byte	0
	.byte	1
	.byte	1
# ###################
# function: main
# function: PASCALMAIN
# [14:1]
	.byte	0
	.uleb128	9
	.byte	2
	.quad	.Ll8
	.byte	5
	.uleb128	1
	.byte	25
# [15:1]
	.byte	0
	.uleb128	9
	.byte	2
	.quad	.Ll9
	.byte	13
	.byte	0
	.uleb128	9
	.byte	2
	.quad	.Ll10
	.byte	0
	.byte	1
	.byte	1
# ###################
	.type	.Ledebug_line0,@object
.Ledebug_line0:
# End asmlist al_dwarf_line
# Begin asmlist al_dwarf_aranges

.section .debug_aranges
	.long	.Learanges0-.Lf1
.Lf1:
	.short	2
	.long	.Ldebug_info0
	.byte	8
	.byte	0
	.long	0
	.quad	main
	.quad	.Lt1-main
	.quad	P$RVV_OPCODE_SMOKE_$$_RVVOPCODEPROBE$POINTER$POINTER
	.quad	.Lt2-P$RVV_OPCODE_SMOKE_$$_RVVOPCODEPROBE$POINTER$POINTER
	.quad	0
	.quad	0
	.type	.Learanges0,@object
.Learanges0:
# End asmlist al_dwarf_aranges
# Begin asmlist al_dwarf_ranges

.section .debug_ranges
# End asmlist al_dwarf_ranges
# Begin asmlist al_end

.section .text.z_DEBUGEND_$P$RVV_OPCODE_SMOKE,"ax"
.globl	DEBUGEND_$P$RVV_OPCODE_SMOKE
	.type	DEBUGEND_$P$RVV_OPCODE_SMOKE,@object
DEBUGEND_$P$RVV_OPCODE_SMOKE:
# End asmlist al_end
.section .note.GNU-stack,"",%progbits

