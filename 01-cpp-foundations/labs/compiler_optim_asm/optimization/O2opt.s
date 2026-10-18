	.file	"optimization.cpp"
	.intel_syntax noprefix
	.text
	.p2align 4
	.globl	_Z8multiplydd
	.type	_Z8multiplydd, @function
_Z8multiplydd:
.LFB0:
	.cfi_startproc
	endbr64
	mulsd	xmm0, xmm1
	ret
	.cfi_endproc
.LFE0:
	.size	_Z8multiplydd, .-_Z8multiplydd
	.section	.text.startup,"ax",@progbits
	.p2align 4
	.globl	main
	.type	main, @function
main:
.LFB1:
	.cfi_startproc
	endbr64
	movsd	xmm0, QWORD PTR .LC0[rip]
	xor	eax, eax
	mov	edx, 1
	movsd	QWORD PTR -8[rsp], xmm0
	movsd	xmm0, QWORD PTR -8[rsp]
	mulsd	xmm0, QWORD PTR .LC1[rip]
	ucomisd	xmm0, QWORD PTR .LC2[rip]
	setp	al
	cmovne	eax, edx
	ret
	.cfi_endproc
.LFE1:
	.size	main, .-main
	.section	.rodata.cst8,"aM",@progbits,8
	.align 8
.LC0:
	.long	0
	.long	1074266112
	.align 8
.LC1:
	.long	0
	.long	1074790400
	.align 8
.LC2:
	.long	0
	.long	1076363264
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	1f - 0f
	.long	4f - 1f
	.long	5
0:
	.string	"GNU"
1:
	.align 8
	.long	0xc0000002
	.long	3f - 2f
2:
	.long	0x3
3:
	.align 8
4:
