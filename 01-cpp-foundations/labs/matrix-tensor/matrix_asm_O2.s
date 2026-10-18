	.file	"matrix_benchmark.cpp"
	.intel_syntax noprefix
	.text
#APP
	.globl _ZSt21ios_base_library_initv
	.section	.rodata._Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_.str1.8,"aMS",@progbits,1
	.align 8
.LC1:
	.string	"Incomaptible matrix dimensions for multiplication"
	.section	.rodata._Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_.str1.1,"aMS",@progbits,1
.LC2:
	.string	"Matrix dimension overflow"
	.section	.rodata._Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_.str1.8
	.align 8
.LC3:
	.string	"cannot create std::vector larger than max_size()"
#NO_APP
	.section	.text._Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_,"axG",@progbits,_Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_,comdat
	.p2align 4
	.weak	_Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_
	.type	_Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_, @function
_Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_:
.LFB6438:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA6438
	endbr64
	push	r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	push	r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	push	r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	push	r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	push	rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	push	rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	sub	rsp, 40
	.cfi_def_cfa_offset 96
	mov	rax, QWORD PTR [rdx]
	cmp	QWORD PTR 8[rsi], rax
	jne	.L44
	mov	rax, QWORD PTR 8[rdx]
	mov	r14, rdx
	mov	rdx, QWORD PTR [rsi]
	mov	rbx, rdi
	mov	r13, rsi
	movq	xmm0, rdx
	movq	xmm2, rax
	punpcklqdq	xmm0, xmm2
	movups	XMMWORD PTR [rdi], xmm0
	test	rax, rax
	je	.L3
	mul	rdx
	mov	r12, rax
	jo	.L5
	shr	rax, 60
	jne	.L45
	pxor	xmm0, xmm0
	mov	QWORD PTR 32[rdi], 0
	movups	XMMWORD PTR 16[rdi], xmm0
	test	r12, r12
	je	.L3
	lea	r15, 0[0+r12*8]
	mov	rdi, r15
.LEHB0:
	call	_Znwm@PLT
	lea	rcx, [rax+r15]
	mov	QWORD PTR 16[rbx], rax
	mov	rbp, rax
	lea	rdi, 8[rax]
	mov	QWORD PTR 32[rbx], rcx
	mov	QWORD PTR [rax], 0x000000000
	cmp	r12, 1
	je	.L11
	cmp	rcx, rdi
	je	.L12
	lea	rdx, -8[r15]
	xor	esi, esi
	mov	QWORD PTR [rsp], rcx
	call	memset@PLT
	mov	rcx, QWORD PTR [rsp]
.L12:
	mov	rdi, rcx
.L11:
	mov	rax, QWORD PTR 16[r14]
	mov	r15, QWORD PTR 16[r13]
	mov	QWORD PTR 24[rbx], rdi
	mov	r10, QWORD PTR 8[r13]
	mov	r9, QWORD PTR 8[r14]
	mov	QWORD PTR 8[rsp], rax
	mov	rax, QWORD PTR 0[r13]
	mov	QWORD PTR [rsp], rax
	test	rax, rax
	je	.L1
	mov	QWORD PTR 16[rsp], r15
	xor	r13d, r13d
	xor	r12d, r12d
	xor	edx, edx
	mov	QWORD PTR 24[rsp], rbx
	lea	r14, 0[0+r10*8]
	lea	rsi, 0[0+r9*8]
	lea	rcx, [r15+r14]
	.p2align 4,,10
	.p2align 3
.L14:
	test	r9, r9
	je	.L16
	mov	rax, QWORD PTR 16[rsp]
	mov	r11, QWORD PTR 8[rsp]
	lea	rbx, 0[rbp+r12*8]
	xor	r8d, r8d
	lea	r15, [rax+r13*8]
	.p2align 4,,10
	.p2align 3
.L18:
	mov	rdi, r11
	mov	rax, r15
	pxor	xmm1, xmm1
	test	r10, r10
	je	.L17
	.p2align 4,,10
	.p2align 3
.L15:
	movsd	xmm0, QWORD PTR [rax]
	mulsd	xmm0, QWORD PTR [rdi]
	add	rax, 8
	add	rdi, rsi
	addsd	xmm1, xmm0
	cmp	rax, rcx
	jne	.L15
.L17:
	movsd	QWORD PTR [rbx+r8*8], xmm1
	add	r8, 1
	add	r11, 8
	cmp	r9, r8
	jne	.L18
.L16:
	add	rdx, 1
	add	r12, r9
	add	r13, r10
	add	rcx, r14
	cmp	QWORD PTR [rsp], rdx
	jne	.L14
	mov	rbx, QWORD PTR 24[rsp]
.L1:
	add	rsp, 40
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	mov	rax, rbx
	pop	rbx
	.cfi_def_cfa_offset 48
	pop	rbp
	.cfi_def_cfa_offset 40
	pop	r12
	.cfi_def_cfa_offset 32
	pop	r13
	.cfi_def_cfa_offset 24
	pop	r14
	.cfi_def_cfa_offset 16
	pop	r15
	.cfi_def_cfa_offset 8
	ret
.L3:
	.cfi_restore_state
	mov	QWORD PTR 16[rbx], 0
	xor	ebp, ebp
	xor	edi, edi
	mov	QWORD PTR 32[rbx], 0
	jmp	.L11
.L45:
	lea	rdi, .LC3[rip]
	call	_ZSt20__throw_length_errorPKc@PLT
.LEHE0:
.L5:
	mov	edi, 16
	call	__cxa_allocate_exception@PLT
	lea	rsi, .LC2[rip]
	mov	rdi, rax
	mov	rbx, rax
.LEHB1:
	call	_ZNSt12length_errorC1EPKc@PLT
.LEHE1:
	mov	rdx, QWORD PTR _ZNSt12length_errorD1Ev@GOTPCREL[rip]
	lea	rsi, _ZTISt12length_error[rip]
	mov	rdi, rbx
.LEHB2:
	call	__cxa_throw@PLT
.LEHE2:
.L44:
	mov	edi, 16
	call	__cxa_allocate_exception@PLT
	lea	rsi, .LC1[rip]
	mov	rdi, rax
	mov	rbx, rax
.LEHB3:
	call	_ZNSt16invalid_argumentC1EPKc@PLT
.LEHE3:
	mov	rdx, QWORD PTR _ZNSt16invalid_argumentD1Ev@GOTPCREL[rip]
	lea	rsi, _ZTISt16invalid_argument[rip]
	mov	rdi, rbx
.LEHB4:
	call	__cxa_throw@PLT
.L22:
	endbr64
.L42:
	mov	rbp, rax
	jmp	.L19
.L21:
	endbr64
	jmp	.L42
.L19:
	mov	rdi, rbx
	call	__cxa_free_exception@PLT
	mov	rdi, rbp
	call	_Unwind_Resume@PLT
.LEHE4:
	.cfi_endproc
.LFE6438:
	.globl	__gxx_personality_v0
	.section	.gcc_except_table._Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_,"aG",@progbits,_Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_,comdat
.LLSDA6438:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE6438-.LLSDACSB6438
.LLSDACSB6438:
	.uleb128 .LEHB0-.LFB6438
	.uleb128 .LEHE0-.LEHB0
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB1-.LFB6438
	.uleb128 .LEHE1-.LEHB1
	.uleb128 .L22-.LFB6438
	.uleb128 0
	.uleb128 .LEHB2-.LFB6438
	.uleb128 .LEHE2-.LEHB2
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB3-.LFB6438
	.uleb128 .LEHE3-.LEHB3
	.uleb128 .L21-.LFB6438
	.uleb128 0
	.uleb128 .LEHB4-.LFB6438
	.uleb128 .LEHE4-.LEHB4
	.uleb128 0
	.uleb128 0
.LLSDACSE6438:
	.section	.text._Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_,"axG",@progbits,_Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_,comdat
	.size	_Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_, .-_Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_
	.section	.text._Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_,"axG",@progbits,_Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_,comdat
	.p2align 4
	.weak	_Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_
	.type	_Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_, @function
_Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_:
.LFB6481:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA6481
	endbr64
	push	r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	push	r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	push	r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	push	r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	push	rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	push	rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	sub	rsp, 24
	.cfi_def_cfa_offset 80
	mov	rax, QWORD PTR [rdx]
	mov	QWORD PTR 8[rsp], rdi
	cmp	QWORD PTR 8[rsi], rax
	jne	.L87
	mov	rax, QWORD PTR 8[rdx]
	mov	r13, rdx
	mov	rdx, QWORD PTR [rsi]
	mov	rbp, rsi
	mov	rsi, QWORD PTR 8[rsp]
	movq	xmm0, rdx
	movq	xmm2, rax
	punpcklqdq	xmm0, xmm2
	movups	XMMWORD PTR [rsi], xmm0
	test	rax, rax
	je	.L48
	mul	rdx
	mov	rbx, rax
	jo	.L50
	shr	rax, 60
	jne	.L88
	mov	rax, QWORD PTR 8[rsp]
	pxor	xmm0, xmm0
	mov	QWORD PTR 32[rax], 0
	movups	XMMWORD PTR 16[rax], xmm0
	test	rbx, rbx
	je	.L48
	lea	r12, 0[0+rbx*8]
	mov	rdi, r12
.LEHB5:
	call	_Znwm@PLT
	mov	r9, rax
	mov	rax, QWORD PTR 8[rsp]
	lea	r14, [r9+r12]
	mov	QWORD PTR [r9], 0x000000000
	lea	rdi, 8[r9]
	mov	QWORD PTR 16[rax], r9
	mov	QWORD PTR 32[rax], r14
	cmp	rbx, 1
	je	.L56
	cmp	r14, rdi
	je	.L57
	lea	rdx, -8[r12]
	xor	esi, esi
	mov	QWORD PTR [rsp], r9
	call	memset@PLT
	mov	r9, QWORD PTR [rsp]
.L57:
	mov	rdi, r14
.L56:
	mov	rax, QWORD PTR 8[rsp]
	mov	r15, QWORD PTR 0[rbp]
	mov	r14, QWORD PTR 16[rbp]
	mov	r11, QWORD PTR 16[r13]
	mov	r12, QWORD PTR 8[rbp]
	mov	r10, QWORD PTR 8[r13]
	mov	QWORD PTR 24[rax], rdi
	test	r15, r15
	je	.L46
	mov	QWORD PTR [rsp], r14
	lea	r13, 0[0+r12*8]
	xor	ebx, ebx
	xor	edx, edx
	lea	rbp, 0[0+r10*8]
	lea	r8, [r14+r13]
	mov	rsi, r15
	lea	rcx, [r9+rbp]
	.p2align 4,,10
	.p2align 3
.L59:
	mov	rax, QWORD PTR [rsp]
	lea	rdi, [rax+rbx*8]
	test	r12, r12
	je	.L62
	test	r10, r10
	je	.L60
	movsd	xmm1, QWORD PTR [rdi]
	xor	r15d, r15d
	.p2align 4,,10
	.p2align 3
.L63:
	lea	r14, [r11+r15*8]
	mov	rax, r9
	.p2align 4,,10
	.p2align 3
.L61:
	movsd	xmm0, QWORD PTR [r14]
	add	rax, 8
	add	r14, 8
	mulsd	xmm0, xmm1
	addsd	xmm0, QWORD PTR -8[rax]
	movsd	QWORD PTR -8[rax], xmm0
	cmp	rax, rcx
	jne	.L61
	add	rdi, 8
	add	r15, r10
	cmp	rdi, r8
	je	.L62
	movsd	xmm1, QWORD PTR [rdi]
	jmp	.L63
	.p2align 4,,10
	.p2align 3
.L60:
	add	rdi, 8
	cmp	rdi, r8
	jne	.L60
	.p2align 4,,10
	.p2align 3
.L62:
	add	rdx, 1
	add	r8, r13
	add	rbx, r12
	add	r9, rbp
	add	rcx, rbp
	cmp	rsi, rdx
	jne	.L59
.L46:
	mov	rax, QWORD PTR 8[rsp]
	add	rsp, 24
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	pop	rbx
	.cfi_def_cfa_offset 48
	pop	rbp
	.cfi_def_cfa_offset 40
	pop	r12
	.cfi_def_cfa_offset 32
	pop	r13
	.cfi_def_cfa_offset 24
	pop	r14
	.cfi_def_cfa_offset 16
	pop	r15
	.cfi_def_cfa_offset 8
	ret
.L48:
	.cfi_restore_state
	mov	rax, QWORD PTR 8[rsp]
	xor	r9d, r9d
	xor	edi, edi
	mov	QWORD PTR 16[rax], 0
	mov	QWORD PTR 32[rax], 0
	jmp	.L56
.L88:
	lea	rdi, .LC3[rip]
	call	_ZSt20__throw_length_errorPKc@PLT
.LEHE5:
.L50:
	mov	edi, 16
	call	__cxa_allocate_exception@PLT
	lea	rsi, .LC2[rip]
	mov	rdi, rax
	mov	rbx, rax
.LEHB6:
	call	_ZNSt12length_errorC1EPKc@PLT
.LEHE6:
	mov	rdx, QWORD PTR _ZNSt12length_errorD1Ev@GOTPCREL[rip]
	lea	rsi, _ZTISt12length_error[rip]
	mov	rdi, rbx
.LEHB7:
	call	__cxa_throw@PLT
.LEHE7:
.L87:
	mov	edi, 16
	call	__cxa_allocate_exception@PLT
	lea	rsi, .LC1[rip]
	mov	rdi, rax
	mov	rbx, rax
.LEHB8:
	call	_ZNSt16invalid_argumentC1EPKc@PLT
.LEHE8:
	mov	rdx, QWORD PTR _ZNSt16invalid_argumentD1Ev@GOTPCREL[rip]
	lea	rsi, _ZTISt16invalid_argument[rip]
	mov	rdi, rbx
.LEHB9:
	call	__cxa_throw@PLT
.L68:
	endbr64
.L86:
	mov	rbp, rax
	jmp	.L66
.L67:
	endbr64
	jmp	.L86
.L66:
	mov	rdi, rbx
	call	__cxa_free_exception@PLT
	mov	rdi, rbp
	call	_Unwind_Resume@PLT
.LEHE9:
	.cfi_endproc
.LFE6481:
	.section	.gcc_except_table._Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_,"aG",@progbits,_Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_,comdat
.LLSDA6481:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE6481-.LLSDACSB6481
.LLSDACSB6481:
	.uleb128 .LEHB5-.LFB6481
	.uleb128 .LEHE5-.LEHB5
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB6-.LFB6481
	.uleb128 .LEHE6-.LEHB6
	.uleb128 .L68-.LFB6481
	.uleb128 0
	.uleb128 .LEHB7-.LFB6481
	.uleb128 .LEHE7-.LEHB7
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB8-.LFB6481
	.uleb128 .LEHE8-.LEHB8
	.uleb128 .L67-.LFB6481
	.uleb128 0
	.uleb128 .LEHB9-.LFB6481
	.uleb128 .LEHE9-.LEHB9
	.uleb128 0
	.uleb128 0
.LLSDACSE6481:
	.section	.text._Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_,"axG",@progbits,_Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_,comdat
	.size	_Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_, .-_Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_
	.text
	.p2align 4
	.type	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPdSt6vectorIdSaIdEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.0, @function
_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPdSt6vectorIdSaIdEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.0:
.LFB8061:
	.cfi_startproc
	push	r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	mov	rax, rsi
	push	rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	sub	rax, rdi
	mov	rbp, rdi
	push	rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	sub	rsp, 16
	.cfi_def_cfa_offset 48
	cmp	rax, 128
	jle	.L89
	mov	r12, rdx
	mov	rcx, rsi
	test	rdx, rdx
	je	.L144
	mov	rdi, rsi
	lea	rbx, 8[rbp]
.L92:
	movupd	xmm0, XMMWORD PTR 0[rbp]
	sar	rax, 4
	sub	r12, 1
	movsd	xmm3, QWORD PTR -8[rdi]
	lea	rax, 0[rbp+rax*8]
	movsd	xmm2, QWORD PTR [rax]
	movapd	xmm5, xmm0
	movapd	xmm4, xmm0
	unpckhpd	xmm5, xmm5
	shufpd	xmm4, xmm0, 1
	comisd	xmm2, xmm5
	movapd	xmm1, xmm5
	jbe	.L177
	comisd	xmm3, xmm2
	ja	.L181
	comisd	xmm3, xmm5
	ja	.L186
.L179:
	movups	XMMWORD PTR 0[rbp], xmm4
	movsd	xmm2, QWORD PTR -8[rdi]
.L127:
	comisd	xmm1, xmm0
	mov	rsi, rbx
	mov	rdx, rdi
	lea	rax, 8[rsi]
	jbe	.L182
	.p2align 4,,10
	.p2align 3
.L137:
	mov	rcx, rax
	movsd	xmm0, QWORD PTR [rax]
	add	rax, 8
	comisd	xmm1, xmm0
	ja	.L137
	comisd	xmm2, xmm1
	lea	rax, -16[rdx]
	jbe	.L183
	.p2align 4,,10
	.p2align 3
.L140:
	mov	rdx, rax
	movsd	xmm2, QWORD PTR [rax]
	sub	rax, 8
	comisd	xmm2, xmm1
	ja	.L140
	cmp	rcx, rdx
	jnb	.L187
.L142:
	movsd	QWORD PTR [rcx], xmm2
	lea	rsi, 8[rcx]
	movsd	xmm2, QWORD PTR -8[rdx]
	movsd	QWORD PTR [rdx], xmm0
	movsd	xmm0, QWORD PTR 8[rcx]
	movsd	xmm1, QWORD PTR 0[rbp]
	lea	rax, 8[rsi]
	comisd	xmm1, xmm0
	ja	.L137
.L182:
	comisd	xmm2, xmm1
	mov	rcx, rsi
	lea	rax, -16[rdx]
	ja	.L140
	.p2align 4,,10
	.p2align 3
.L183:
	sub	rdx, 8
	cmp	rcx, rdx
	jb	.L142
	.p2align 4,,10
	.p2align 3
.L187:
	mov	rsi, rdi
	mov	rdx, r12
	mov	rdi, rcx
	mov	QWORD PTR 8[rsp], rcx
	call	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPdSt6vectorIdSaIdEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.0
	mov	rcx, QWORD PTR 8[rsp]
	mov	rax, rcx
	sub	rax, rbp
	cmp	rax, 128
	jle	.L89
	test	r12, r12
	je	.L144
	mov	rdi, rcx
	jmp	.L92
.L177:
	comisd	xmm3, xmm5
	ja	.L179
	comisd	xmm3, xmm2
	jbe	.L181
.L186:
	movsd	QWORD PTR 0[rbp], xmm3
	movapd	xmm2, xmm0
	movsd	QWORD PTR -8[rdi], xmm0
	movsd	xmm1, QWORD PTR 0[rbp]
	movsd	xmm0, QWORD PTR 8[rbp]
	jmp	.L127
.L181:
	movsd	QWORD PTR 0[rbp], xmm2
	movsd	QWORD PTR [rax], xmm0
	movsd	xmm0, QWORD PTR 8[rbp]
	movsd	xmm1, QWORD PTR 0[rbp]
	movsd	xmm2, QWORD PTR -8[rdi]
	jmp	.L127
.L105:
	sub	rcx, 8
	.p2align 4,,10
	.p2align 3
.L122:
	mov	rdi, rcx
	movsd	xmm0, QWORD PTR 0[rbp]
	movsd	xmm2, QWORD PTR [rcx]
	sub	rdi, rbp
	mov	r11, rdi
	movsd	QWORD PTR [rcx], xmm0
	sar	r11, 3
	lea	rax, -1[r11]
	mov	rbx, r11
	mov	r10, rax
	and	ebx, 1
	shr	r10, 63
	add	r10, rax
	sar	r10
	cmp	rdi, 16
	jle	.L108
	xor	esi, esi
	jmp	.L111
	.p2align 4,,10
	.p2align 3
.L151:
	mov	rsi, rdx
.L111:
	lea	rax, 1[rsi]
	lea	rdx, [rax+rax]
	sal	rax, 4
	lea	r8, -1[rdx]
	add	rax, rbp
	lea	r9, 0[rbp+r8*8]
	movsd	xmm0, QWORD PTR [rax]
	movsd	xmm1, QWORD PTR [r9]
	comisd	xmm1, xmm0
	jbe	.L109
	movapd	xmm0, xmm1
	mov	rax, r9
	mov	rdx, r8
.L109:
	movsd	QWORD PTR 0[rbp+rsi*8], xmm0
	cmp	rdx, r10
	jl	.L151
	test	rbx, rbx
	je	.L115
	lea	r8, -1[rdx]
	mov	rsi, r8
	shr	rsi, 63
	add	rsi, r8
	sar	rsi
	test	rdx, rdx
	jne	.L120
	jmp	.L188
	.p2align 4,,10
	.p2align 3
.L190:
	lea	rdx, -1[rsi]
	movsd	QWORD PTR [rax], xmm0
	mov	rax, rdx
	shr	rax, 63
	add	rax, rdx
	mov	rdx, rsi
	sar	rax
	test	rsi, rsi
	je	.L189
	mov	rsi, rax
.L120:
	lea	r8, 0[rbp+rsi*8]
	lea	rax, 0[rbp+rdx*8]
	movsd	xmm0, QWORD PTR [r8]
	comisd	xmm2, xmm0
	ja	.L190
.L114:
	movsd	QWORD PTR [rax], xmm2
	sub	rcx, 8
	cmp	rdi, 8
	jg	.L122
.L89:
	add	rsp, 16
	.cfi_remember_state
	.cfi_def_cfa_offset 32
	pop	rbx
	.cfi_def_cfa_offset 24
	pop	rbp
	.cfi_def_cfa_offset 16
	pop	r12
	.cfi_def_cfa_offset 8
	ret
.L144:
	.cfi_restore_state
	sar	rax, 3
	lea	r11, -2[rax]
	lea	r9, -1[rax]
	not	rax
	sar	r11
	mov	r8d, eax
	sar	r9
	lea	r10, 0[rbp+r11*8]
	mov	rdi, r11
	and	r8d, 1
	movsd	xmm2, QWORD PTR [r10]
	mov	rdx, r10
	cmp	rdi, r9
	jge	.L148
.L194:
	mov	rsi, rdi
	jmp	.L96
	.p2align 4,,10
	.p2align 3
.L149:
	mov	rsi, rax
.L96:
	lea	rdx, 1[rsi]
	lea	rax, [rdx+rdx]
	sal	rdx, 4
	lea	rbx, -1[rax]
	add	rdx, rbp
	lea	r12, 0[rbp+rbx*8]
	movsd	xmm0, QWORD PTR [rdx]
	movsd	xmm1, QWORD PTR [r12]
	comisd	xmm1, xmm0
	jbe	.L94
	movapd	xmm0, xmm1
	mov	rdx, r12
	mov	rax, rbx
.L94:
	movsd	QWORD PTR 0[rbp+rsi*8], xmm0
	cmp	rax, r9
	jl	.L149
.L93:
	cmp	r11, rax
	jne	.L157
	test	r8b, r8b
	jne	.L97
.L157:
	lea	rsi, -1[rax]
	sar	rsi
	cmp	rdi, rax
	jl	.L103
	jmp	.L191
	.p2align 4,,10
	.p2align 3
.L193:
	lea	rdx, -1[rsi]
	movsd	QWORD PTR [rax], xmm0
	mov	rax, rdx
	shr	rax, 63
	add	rax, rdx
	sar	rax
	mov	rdx, rax
	mov	rax, rsi
	cmp	rdi, rsi
	jge	.L192
	mov	rsi, rdx
.L103:
	lea	rbx, 0[rbp+rsi*8]
	lea	rax, 0[rbp+rax*8]
	movsd	xmm0, QWORD PTR [rbx]
	comisd	xmm2, xmm0
	ja	.L193
.L101:
	movsd	QWORD PTR [rax], xmm2
	test	rdi, rdi
	je	.L105
.L104:
	sub	r10, 8
	sub	rdi, 1
	movsd	xmm2, QWORD PTR [r10]
	mov	rdx, r10
	cmp	rdi, r9
	jl	.L194
.L148:
	mov	rax, rdi
	jmp	.L93
.L192:
	mov	rax, rbx
	jmp	.L101
.L189:
	mov	rax, r8
	sub	rcx, 8
	movsd	QWORD PTR [rax], xmm2
	cmp	rdi, 8
	jg	.L122
	jmp	.L89
.L115:
	lea	rsi, -2[r11]
	sar	rsi
	cmp	rsi, rdx
	je	.L118
	lea	r8, -1[rdx]
	mov	rsi, r8
	shr	rsi, 63
	add	rsi, r8
	sar	rsi
	test	rdx, rdx
	jne	.L120
	jmp	.L114
	.p2align 4,,10
	.p2align 3
.L113:
	cmp	rax, 2
	mov	rax, rbp
	ja	.L114
	xor	edx, edx
.L118:
	lea	r8, 1[rdx+rdx]
	mov	rsi, rdx
	movsd	xmm0, QWORD PTR 0[rbp+r8*8]
	mov	rdx, r8
	movsd	QWORD PTR [rax], xmm0
	jmp	.L120
.L108:
	test	rbx, rbx
	je	.L113
	mov	rax, rbp
	sub	rcx, 8
	movsd	QWORD PTR [rax], xmm2
	cmp	rdi, 8
	jg	.L122
	jmp	.L89
	.p2align 4,,10
	.p2align 3
.L97:
	lea	rsi, [rax+rax]
	lea	rax, 1[rsi]
	sar	rsi
	lea	rbx, 0[rbp+rax*8]
	movsd	xmm0, QWORD PTR [rbx]
	movsd	QWORD PTR [rdx], xmm0
	mov	rdx, rbx
	cmp	rdi, rax
	jl	.L103
.L191:
	movsd	QWORD PTR [rdx], xmm2
	jmp	.L104
.L188:
	movsd	QWORD PTR [rax], xmm2
	sub	rcx, 8
	jmp	.L122
	.cfi_endproc
.LFE8061:
	.size	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPdSt6vectorIdSaIdEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.0, .-_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPdSt6vectorIdSaIdEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.0
	.section	.text._ZN6MatrixIdEC2Emm,"axG",@progbits,_ZN6MatrixIdEC5Emm,comdat
	.align 2
	.p2align 4
	.weak	_ZN6MatrixIdEC2Emm
	.type	_ZN6MatrixIdEC2Emm, @function
_ZN6MatrixIdEC2Emm:
.LFB6430:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA6430
	endbr64
	push	r13
	.cfi_def_cfa_offset 16
	.cfi_offset 13, -16
	push	r12
	.cfi_def_cfa_offset 24
	.cfi_offset 12, -24
	push	rbp
	.cfi_def_cfa_offset 32
	.cfi_offset 6, -32
	push	rbx
	.cfi_def_cfa_offset 40
	.cfi_offset 3, -40
	mov	rbx, rdi
	sub	rsp, 8
	.cfi_def_cfa_offset 48
	mov	QWORD PTR [rdi], rsi
	mov	QWORD PTR 8[rdi], rdx
	test	rdx, rdx
	je	.L196
	mov	rax, rsi
	mul	rdx
	mov	rbp, rax
	jo	.L198
	shr	rax, 60
	jne	.L215
	pxor	xmm0, xmm0
	mov	QWORD PTR 32[rdi], 0
	movups	XMMWORD PTR 16[rdi], xmm0
	test	rbp, rbp
	je	.L196
	lea	r12, 0[0+rbp*8]
	mov	rdi, r12
.LEHB10:
	call	_Znwm@PLT
.LEHE10:
	lea	r13, [rax+r12]
	mov	QWORD PTR 16[rbx], rax
	lea	rdi, 8[rax]
	mov	QWORD PTR 32[rbx], r13
	mov	QWORD PTR [rax], 0x000000000
	cmp	rbp, 1
	je	.L204
	cmp	rdi, r13
	je	.L205
	lea	rdx, -8[r12]
	xor	esi, esi
	call	memset@PLT
.L205:
	mov	rdi, r13
.L204:
	mov	QWORD PTR 24[rbx], rdi
	add	rsp, 8
	.cfi_remember_state
	.cfi_def_cfa_offset 40
	pop	rbx
	.cfi_def_cfa_offset 32
	pop	rbp
	.cfi_def_cfa_offset 24
	pop	r12
	.cfi_def_cfa_offset 16
	pop	r13
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L196:
	.cfi_restore_state
	xor	edi, edi
	mov	QWORD PTR 16[rbx], 0
	mov	QWORD PTR 32[rbx], 0
	mov	QWORD PTR 24[rbx], rdi
	add	rsp, 8
	.cfi_remember_state
	.cfi_def_cfa_offset 40
	pop	rbx
	.cfi_def_cfa_offset 32
	pop	rbp
	.cfi_def_cfa_offset 24
	pop	r12
	.cfi_def_cfa_offset 16
	pop	r13
	.cfi_def_cfa_offset 8
	ret
.L198:
	.cfi_restore_state
	mov	edi, 16
	call	__cxa_allocate_exception@PLT
	lea	rsi, .LC2[rip]
	mov	rdi, rax
	mov	rbx, rax
.LEHB11:
	call	_ZNSt12length_errorC1EPKc@PLT
.LEHE11:
	mov	rdx, QWORD PTR _ZNSt12length_errorD1Ev@GOTPCREL[rip]
	lea	rsi, _ZTISt12length_error[rip]
	mov	rdi, rbx
.LEHB12:
	call	__cxa_throw@PLT
.L215:
	lea	rdi, .LC3[rip]
	call	_ZSt20__throw_length_errorPKc@PLT
.L206:
	endbr64
	mov	rbp, rax
.L202:
	mov	rdi, rbx
	call	__cxa_free_exception@PLT
	mov	rdi, rbp
	call	_Unwind_Resume@PLT
.LEHE12:
	.cfi_endproc
.LFE6430:
	.section	.gcc_except_table._ZN6MatrixIdEC2Emm,"aG",@progbits,_ZN6MatrixIdEC5Emm,comdat
.LLSDA6430:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE6430-.LLSDACSB6430
.LLSDACSB6430:
	.uleb128 .LEHB10-.LFB6430
	.uleb128 .LEHE10-.LEHB10
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB11-.LFB6430
	.uleb128 .LEHE11-.LEHB11
	.uleb128 .L206-.LFB6430
	.uleb128 0
	.uleb128 .LEHB12-.LFB6430
	.uleb128 .LEHE12-.LEHB12
	.uleb128 0
	.uleb128 0
.LLSDACSE6430:
	.section	.text._ZN6MatrixIdEC2Emm,"axG",@progbits,_ZN6MatrixIdEC5Emm,comdat
	.size	_ZN6MatrixIdEC2Emm, .-_ZN6MatrixIdEC2Emm
	.weak	_ZN6MatrixIdEC1Emm
	.set	_ZN6MatrixIdEC1Emm,_ZN6MatrixIdEC2Emm
	.section	.text._ZNSt12_Vector_baseIdSaIdEED2Ev,"axG",@progbits,_ZNSt12_Vector_baseIdSaIdEED5Ev,comdat
	.align 2
	.p2align 4
	.weak	_ZNSt12_Vector_baseIdSaIdEED2Ev
	.type	_ZNSt12_Vector_baseIdSaIdEED2Ev, @function
_ZNSt12_Vector_baseIdSaIdEED2Ev:
.LFB6764:
	.cfi_startproc
	endbr64
	mov	rax, QWORD PTR [rdi]
	test	rax, rax
	je	.L216
	mov	rsi, QWORD PTR 16[rdi]
	mov	rdi, rax
	sub	rsi, rax
	jmp	_ZdlPvm@PLT
	.p2align 4,,10
	.p2align 3
.L216:
	ret
	.cfi_endproc
.LFE6764:
	.size	_ZNSt12_Vector_baseIdSaIdEED2Ev, .-_ZNSt12_Vector_baseIdSaIdEED2Ev
	.weak	_ZNSt12_Vector_baseIdSaIdEED1Ev
	.set	_ZNSt12_Vector_baseIdSaIdEED1Ev,_ZNSt12_Vector_baseIdSaIdEED2Ev
	.section	.rodata._Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_.str1.1,"aMS",@progbits,1
.LC8:
	.string	"E don go infinity ooo"
.LC9:
	.string	"vector::_M_realloc_insert"
.LC10:
	.string	"Checksum result: "
.LC11:
	.string	"\n"
	.section	.text._Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_,"axG",@progbits,_Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_,comdat
	.p2align 4
	.weak	_Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_
	.type	_Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_, @function
_Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_:
.LFB6451:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA6451
	endbr64
	push	r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	pxor	xmm0, xmm0
	push	r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	mov	r14, rdx
	push	r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	mov	r13, rsi
	push	r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	mov	r12, rdi
	push	rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	push	rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	mov	ebx, 6
	sub	rsp, 136
	.cfi_def_cfa_offset 192
	mov	rax, QWORD PTR fs:40
	mov	QWORD PTR 120[rsp], rax
	xor	eax, eax
	lea	r15, 80[rsp]
	movaps	XMMWORD PTR 48[rsp], xmm0
	mov	QWORD PTR 64[rsp], 0
	mov	QWORD PTR 8[rsp], 0x000000000
	.p2align 4,,10
	.p2align 3
.L237:
	call	_ZNSt6chrono3_V212steady_clock3nowEv@PLT
	mov	rdx, r14
	mov	rsi, r13
	mov	rdi, r15
	mov	rbp, rax
.LEHB13:
	call	r12
.LEHE13:
	call	_ZNSt6chrono3_V212steady_clock3nowEv@PLT
	pxor	xmm0, xmm0
	mov	rdx, QWORD PTR 96[rsp]
	sub	rax, rbp
	cvtsi2sd	xmm0, rax
	mov	rax, QWORD PTR 104[rsp]
	divsd	xmm0, QWORD PTR .LC5[rip]
	movsd	QWORD PTR 16[rsp], xmm0
	mov	rcx, rax
	sub	rcx, rdx
	sar	rcx, 3
	cmp	rdx, rax
	je	.L219
	movsd	xmm3, QWORD PTR 8[rsp]
	lea	rax, -1[rcx]
	addsd	xmm3, QWORD PTR [rdx]
	and	eax, 1
	mov	rsi, rax
	mov	eax, 1
	movsd	QWORD PTR 8[rsp], xmm3
	cmp	rax, rcx
	jnb	.L219
	test	rsi, rsi
	je	.L220
	movsd	xmm6, QWORD PTR 8[rsp]
	addsd	xmm6, QWORD PTR 8[rdx]
	mov	eax, 2
	movsd	QWORD PTR 8[rsp], xmm6
	cmp	rax, rcx
	jnb	.L219
	.p2align 4,,10
	.p2align 3
.L220:
	movsd	xmm2, QWORD PTR 8[rsp]
	addsd	xmm2, QWORD PTR [rdx+rax*8]
	addsd	xmm2, QWORD PTR 8[rdx+rax*8]
	add	rax, 2
	movsd	QWORD PTR 8[rsp], xmm2
	cmp	rax, rcx
	jb	.L220
.L219:
	movsd	xmm0, QWORD PTR 8[rsp]
	movsd	xmm4, QWORD PTR .LC7[rip]
	andpd	xmm0, XMMWORD PTR .LC6[rip]
	ucomisd	xmm4, xmm0
	jnb	.L224
	mov	edx, 21
	lea	rsi, .LC8[rip]
	lea	rdi, _ZSt4cerr[rip]
.LEHB14:
	call	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
.LEHE14:
.L224:
	mov	rax, QWORD PTR 56[rsp]
	mov	rbp, QWORD PTR 64[rsp]
	cmp	rax, rbp
	je	.L312
	movsd	xmm5, QWORD PTR 16[rsp]
	add	rax, 8
	movsd	QWORD PTR -8[rax], xmm5
	mov	QWORD PTR 56[rsp], rax
.L225:
	mov	rdi, QWORD PTR 96[rsp]
	test	rdi, rdi
	je	.L236
	mov	rsi, QWORD PTR 112[rsp]
	sub	rsi, rdi
	call	_ZdlPvm@PLT
.L236:
	sub	ebx, 1
	jne	.L237
	mov	rbp, QWORD PTR 56[rsp]
	mov	rbx, QWORD PTR 48[rsp]
	cmp	rbx, rbp
	je	.L238
	mov	r12, rbp
	sub	r12, rbx
	mov	rax, r12
	sar	rax, 3
	je	.L313
	bsr	rdx, rax
	mov	rsi, rbp
	lea	r13, 8[rbx]
	mov	rdi, rbx
	movsx	rdx, edx
	add	rdx, rdx
	call	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPdSt6vectorIdSaIdEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.0
	cmp	r12, 128
	jle	.L240
	lea	r14, 128[rbx]
	mov	r12d, 8
	jmp	.L249
	.p2align 4,,10
	.p2align 3
.L315:
	sub	rdx, rbx
	cmp	rdx, 8
	jle	.L243
	mov	rdi, r12
	mov	rsi, rbx
	movsd	QWORD PTR 16[rsp], xmm1
	sub	rdi, rdx
	add	rdi, r13
	call	memmove@PLT
	movsd	xmm1, QWORD PTR 16[rsp]
.L244:
	add	r13, 8
	movsd	QWORD PTR [rbx], xmm1
	cmp	r14, r13
	je	.L314
.L249:
	movsd	xmm1, QWORD PTR 0[r13]
	movsd	xmm0, QWORD PTR [rbx]
	mov	rdx, r13
	comisd	xmm0, xmm1
	ja	.L315
	movsd	xmm0, QWORD PTR -8[r13]
	lea	rax, -8[r13]
	comisd	xmm0, xmm1
	jbe	.L246
	.p2align 4,,10
	.p2align 3
.L248:
	movsd	QWORD PTR 8[rax], xmm0
	mov	rdx, rax
	movsd	xmm0, QWORD PTR -8[rax]
	sub	rax, 8
	comisd	xmm0, xmm1
	ja	.L248
.L246:
	add	r13, 8
	movsd	QWORD PTR [rdx], xmm1
	cmp	r14, r13
	jne	.L249
.L314:
	cmp	rbp, r14
	je	.L238
	.p2align 4,,10
	.p2align 3
.L250:
	movsd	xmm1, QWORD PTR [r14]
	movsd	xmm0, QWORD PTR -8[r14]
	lea	rax, -8[r14]
	comisd	xmm0, xmm1
	jbe	.L307
	.p2align 4,,10
	.p2align 3
.L254:
	movsd	QWORD PTR 8[rax], xmm0
	mov	rdx, rax
	movsd	xmm0, QWORD PTR -8[rax]
	sub	rax, 8
	comisd	xmm0, xmm1
	ja	.L254
	add	r14, 8
	movsd	QWORD PTR [rdx], xmm1
	cmp	rbp, r14
	jne	.L250
.L238:
	lea	r12, _ZSt4cout[rip]
	mov	edx, 17
	lea	rsi, .LC10[rip]
	mov	rdi, r12
.LEHB15:
	call	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movsd	xmm0, QWORD PTR 8[rsp]
	mov	rdi, r12
	call	_ZNSo9_M_insertIdEERSoT_@PLT
	mov	rdi, rax
	mov	edx, 1
	lea	rsi, .LC11[rip]
	call	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
.LEHE15:
	sub	rbp, rbx
	sar	rbp, 3
	shr	rbp
	movsd	xmm0, QWORD PTR -8[rbx+rbp*8]
	addsd	xmm0, QWORD PTR [rbx+rbp*8]
	mulsd	xmm0, QWORD PTR .LC12[rip]
	test	rbx, rbx
	je	.L218
	mov	rsi, QWORD PTR 64[rsp]
	mov	rdi, rbx
	movsd	QWORD PTR 8[rsp], xmm0
	sub	rsi, rbx
	call	_ZdlPvm@PLT
	movsd	xmm0, QWORD PTR 8[rsp]
.L218:
	mov	rax, QWORD PTR 120[rsp]
	sub	rax, QWORD PTR fs:40
	jne	.L311
	add	rsp, 136
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	pop	rbx
	.cfi_def_cfa_offset 48
	pop	rbp
	.cfi_def_cfa_offset 40
	pop	r12
	.cfi_def_cfa_offset 32
	pop	r13
	.cfi_def_cfa_offset 24
	pop	r14
	.cfi_def_cfa_offset 16
	pop	r15
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L312:
	.cfi_restore_state
	movabs	rdx, 1152921504606846975
	mov	rsi, QWORD PTR 48[rsp]
	sub	rax, rsi
	mov	QWORD PTR 24[rsp], rsi
	mov	QWORD PTR 32[rsp], rax
	sar	rax, 3
	cmp	rax, rdx
	je	.L316
	mov	rsi, QWORD PTR 24[rsp]
	cmp	rbp, rsi
	je	.L317
	lea	rdx, [rax+rax]
	cmp	rdx, rax
	jb	.L271
	test	rdx, rdx
	jne	.L318
	xor	r8d, r8d
	xor	ecx, ecx
.L232:
	mov	rdx, QWORD PTR 32[rsp]
	movsd	xmm7, QWORD PTR 16[rsp]
	lea	r9, 8[rcx+rdx]
	movsd	QWORD PTR [rcx+rdx], xmm7
	test	rdx, rdx
	jg	.L319
	cmp	QWORD PTR 24[rsp], 0
	jne	.L234
.L235:
	mov	QWORD PTR 48[rsp], rcx
	mov	QWORD PTR 56[rsp], r9
	mov	QWORD PTR 64[rsp], r8
	jmp	.L225
.L271:
	movabs	rax, 9223372036854775800
	mov	QWORD PTR 40[rsp], rax
.L231:
	mov	rdi, QWORD PTR 40[rsp]
.LEHB16:
	call	_Znwm@PLT
	mov	r8, QWORD PTR 40[rsp]
	mov	rcx, rax
	add	r8, rax
	jmp	.L232
.L313:
	mov	rdx, -2
	mov	rsi, rbp
	lea	r13, 8[rbx]
	mov	rdi, rbx
	call	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPdSt6vectorIdSaIdEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.0
.L240:
	cmp	rbp, r13
	je	.L238
	mov	r12d, 8
	jmp	.L264
	.p2align 4,,10
	.p2align 3
.L320:
	sub	rdx, rbx
	cmp	rdx, 8
	jle	.L258
	mov	rdi, r12
	mov	rsi, rbx
	movsd	QWORD PTR 16[rsp], xmm1
	sub	rdi, rdx
	add	rdi, r13
	call	memmove@PLT
	movsd	xmm1, QWORD PTR 16[rsp]
.L259:
	movsd	QWORD PTR [rbx], xmm1
.L260:
	add	r13, 8
	cmp	rbp, r13
	je	.L238
.L264:
	movsd	xmm1, QWORD PTR 0[r13]
	movsd	xmm0, QWORD PTR [rbx]
	mov	rdx, r13
	comisd	xmm0, xmm1
	ja	.L320
	movsd	xmm0, QWORD PTR -8[r13]
	lea	rax, -8[r13]
	comisd	xmm0, xmm1
	jbe	.L261
	.p2align 4,,10
	.p2align 3
.L263:
	movsd	QWORD PTR 8[rax], xmm0
	mov	rdx, rax
	movsd	xmm0, QWORD PTR -8[rax]
	sub	rax, 8
	comisd	xmm0, xmm1
	ja	.L263
.L261:
	movsd	QWORD PTR [rdx], xmm1
	jmp	.L260
.L319:
	mov	rsi, QWORD PTR 24[rsp]
	mov	rdi, rcx
	mov	QWORD PTR 32[rsp], r9
	mov	QWORD PTR 16[rsp], r8
	call	memmove@PLT
	mov	r8, QWORD PTR 16[rsp]
	mov	r9, QWORD PTR 32[rsp]
	mov	rcx, rax
.L234:
	mov	rdi, QWORD PTR 24[rsp]
	mov	rsi, rbp
	mov	QWORD PTR 40[rsp], rcx
	mov	QWORD PTR 32[rsp], r9
	sub	rsi, rdi
	mov	QWORD PTR 16[rsp], r8
	call	_ZdlPvm@PLT
	mov	rcx, QWORD PTR 40[rsp]
	mov	r9, QWORD PTR 32[rsp]
	mov	r8, QWORD PTR 16[rsp]
	jmp	.L235
.L317:
	add	rax, 1
	jc	.L271
	movabs	rdx, 1152921504606846975
	cmp	rax, rdx
	cmova	rax, rdx
	sal	rax, 3
	mov	QWORD PTR 40[rsp], rax
	jmp	.L231
.L307:
	mov	rdx, r14
	add	r14, 8
	movsd	QWORD PTR [rdx], xmm1
	cmp	rbp, r14
	jne	.L250
	jmp	.L238
.L258:
	jne	.L259
	movsd	QWORD PTR 0[r13], xmm0
	jmp	.L259
.L243:
	jne	.L244
	movsd	QWORD PTR 0[r13], xmm0
	jmp	.L244
.L316:
	mov	rax, QWORD PTR 120[rsp]
	sub	rax, QWORD PTR fs:40
	jne	.L311
	lea	rdi, .LC9[rip]
	call	_ZSt20__throw_length_errorPKc@PLT
.LEHE16:
.L266:
	lea	rdi, 96[rsp]
	call	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L267:
	lea	rdi, 48[rsp]
	call	_ZNSt12_Vector_baseIdSaIdEED2Ev
	mov	rax, QWORD PTR 120[rsp]
	sub	rax, QWORD PTR fs:40
	je	.L268
.L311:
	call	__stack_chk_fail@PLT
.L318:
	movabs	rax, 1152921504606846975
	cmp	rdx, rax
	cmova	rdx, rax
	lea	rax, 0[0+rdx*8]
	mov	QWORD PTR 40[rsp], rax
	jmp	.L231
.L274:
	endbr64
	mov	rbx, rax
	jmp	.L266
.L275:
	endbr64
	mov	rbx, rax
	jmp	.L267
.L268:
	mov	rdi, rbx
.LEHB17:
	call	_Unwind_Resume@PLT
.LEHE17:
	.cfi_endproc
.LFE6451:
	.section	.gcc_except_table._Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_,"aG",@progbits,_Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_,comdat
.LLSDA6451:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE6451-.LLSDACSB6451
.LLSDACSB6451:
	.uleb128 .LEHB13-.LFB6451
	.uleb128 .LEHE13-.LEHB13
	.uleb128 .L275-.LFB6451
	.uleb128 0
	.uleb128 .LEHB14-.LFB6451
	.uleb128 .LEHE14-.LEHB14
	.uleb128 .L274-.LFB6451
	.uleb128 0
	.uleb128 .LEHB15-.LFB6451
	.uleb128 .LEHE15-.LEHB15
	.uleb128 .L275-.LFB6451
	.uleb128 0
	.uleb128 .LEHB16-.LFB6451
	.uleb128 .LEHE16-.LEHB16
	.uleb128 .L274-.LFB6451
	.uleb128 0
	.uleb128 .LEHB17-.LFB6451
	.uleb128 .LEHE17-.LEHB17
	.uleb128 0
	.uleb128 0
.LLSDACSE6451:
	.section	.text._Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_,"axG",@progbits,_Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_,comdat
	.size	_Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_, .-_Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_
	.section	.rodata._Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m.str1.1,"aMS",@progbits,1
.LC14:
	.string	"Block size must be positive"
	.section	.text._Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m,"axG",@progbits,_Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m,comdat
	.p2align 4
	.weak	_Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m
	.type	_Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m, @function
_Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m:
.LFB6786:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA6786
	endbr64
	push	r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	push	r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	push	r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	push	r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	push	rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	push	rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	sub	rsp, 184
	.cfi_def_cfa_offset 240
	mov	r8, QWORD PTR 8[rsi]
	mov	QWORD PTR 40[rsp], rcx
	cmp	r8, QWORD PTR [rdx]
	jne	.L380
	cmp	QWORD PTR 40[rsp], 0
	je	.L381
	mov	r14, QWORD PTR [rsi]
	mov	r15, QWORD PTR 8[rdx]
	mov	rbx, rdi
	mov	r12, rsi
	mov	rbp, rdx
	movq	xmm0, r14
	movq	xmm2, r15
	punpcklqdq	xmm0, xmm2
	movups	XMMWORD PTR [rdi], xmm0
	test	r15, r15
	je	.L324
	mov	rax, r14
	mul	r15
	mov	rcx, rax
	jo	.L326
	shr	rax, 60
	jne	.L382
	pxor	xmm0, xmm0
	mov	QWORD PTR 32[rdi], 0
	movups	XMMWORD PTR 16[rdi], xmm0
	test	rcx, rcx
	je	.L324
	lea	r13, 0[0+rcx*8]
	mov	QWORD PTR 16[rsp], r8
	mov	rdi, r13
	mov	QWORD PTR 8[rsp], rcx
.LEHB18:
	call	_Znwm@PLT
.LEHE18:
	mov	rcx, QWORD PTR 8[rsp]
	mov	r8, QWORD PTR 16[rsp]
	lea	r9, [rax+r13]
	mov	QWORD PTR 48[rsp], rax
	lea	rdi, 8[rax]
	cmp	rcx, 1
	mov	QWORD PTR 16[rbx], rax
	mov	QWORD PTR 32[rbx], r9
	mov	QWORD PTR [rax], 0x000000000
	je	.L332
	cmp	r9, rdi
	je	.L333
	lea	rdx, -8[r13]
	xor	esi, esi
	mov	QWORD PTR 16[rsp], r9
	mov	QWORD PTR 8[rsp], r8
	call	memset@PLT
	mov	r9, QWORD PTR 16[rsp]
	mov	r8, QWORD PTR 8[rsp]
.L333:
	mov	rdi, r9
	jmp	.L332
.L324:
	mov	QWORD PTR 16[rbx], 0
	xor	edi, edi
	mov	QWORD PTR 32[rbx], 0
	mov	QWORD PTR 48[rsp], 0
.L332:
	mov	rax, QWORD PTR 16[r12]
	mov	QWORD PTR 24[rbx], rdi
	mov	QWORD PTR 64[rsp], rax
	mov	rax, QWORD PTR 16[rbp]
	mov	QWORD PTR 72[rsp], rax
	test	r14, r14
	je	.L321
	mov	rax, QWORD PTR 40[rsp]
	mov	rdx, r14
	xor	r9d, r9d
	xor	edi, edi
	mov	QWORD PTR 56[rsp], 0
	lea	rsi, 0[0+r15*8]
	mov	r12, rax
	imul	rax, r15
	mov	r13, rsi
	imul	r12, r8
	mov	r11, rax
	lea	rax, 0[0+r8*8]
	mov	QWORD PTR 32[rsp], rax
	mov	rax, r14
.L335:
	test	r8, r8
	je	.L345
	mov	rsi, QWORD PTR 56[rsp]
	mov	rcx, QWORD PTR 48[rsp]
	xor	r14d, r14d
	mov	QWORD PTR 8[rsp], 0
	mov	QWORD PTR 104[rsp], r12
	lea	rcx, [rcx+rsi*8]
	mov	rsi, QWORD PTR 40[rsp]
	mov	QWORD PTR 112[rsp], rdx
	mov	QWORD PTR 88[rsp], rcx
	mov	rcx, r8
	cmp	rsi, rdx
	mov	QWORD PTR 96[rsp], rax
	mov	rax, rdi
	cmova	rsi, rdx
	add	rsi, rdi
	mov	QWORD PTR 16[rsp], rsi
.L348:
	test	r15, r15
	je	.L347
	mov	rdx, QWORD PTR 40[rsp]
	mov	rdi, QWORD PTR 64[rsp]
	mov	QWORD PTR 120[rsp], r8
	mov	rsi, r15
	mov	QWORD PTR 128[rsp], rcx
	cmp	rdx, rcx
	mov	QWORD PTR 136[rsp], r9
	cmova	rdx, rcx
	mov	QWORD PTR 144[rsp], r11
	xor	r10d, r10d
	mov	QWORD PTR 152[rsp], rbx
	mov	rbp, rdx
	add	rbp, r14
	lea	rdx, 0[rbp+r9]
	lea	rdx, [rdi+rdx*8]
	mov	QWORD PTR 80[rsp], rdx
	mov	rdx, r14
	sub	rdx, rbp
	lea	r12, 0[0+rdx*8]
.L344:
	mov	rdx, QWORD PTR 40[rsp]
	cmp	rdx, rsi
	cmova	rdx, rsi
	mov	rbx, rdx
	mov	rdx, QWORD PTR 16[rsp]
	add	rbx, r10
	cmp	rax, rdx
	jnb	.L336
	mov	rdx, QWORD PTR 88[rsp]
	lea	r11, 0[0+r10*8]
	mov	rdi, QWORD PTR 48[rsp]
	mov	QWORD PTR 160[rsp], rax
	mov	QWORD PTR 24[rsp], r14
	mov	r8, QWORD PTR 80[rsp]
	lea	r9, [rdx+r11]
	mov	rdx, QWORD PTR 56[rsp]
	mov	QWORD PTR 168[rsp], rsi
	add	rdx, rbx
	lea	rcx, [rdi+rdx*8]
	mov	rdx, QWORD PTR 72[rsp]
	add	r11, rdx
	mov	rdx, rax
	.p2align 4,,10
	.p2align 3
.L337:
	mov	r14, QWORD PTR 8[rsp]
	lea	rdi, [r8+r12]
	cmp	QWORD PTR 24[rsp], rbp
	jnb	.L340
	.p2align 4,,10
	.p2align 3
.L339:
	movsd	xmm1, QWORD PTR [rdi]
	lea	rsi, [r11+r14*8]
	mov	rax, r9
	cmp	r10, rbx
	jnb	.L342
	.p2align 4,,10
	.p2align 3
.L341:
	movsd	xmm0, QWORD PTR [rsi]
	add	rax, 8
	add	rsi, 8
	mulsd	xmm0, xmm1
	addsd	xmm0, QWORD PTR -8[rax]
	movsd	QWORD PTR -8[rax], xmm0
	cmp	rax, rcx
	jne	.L341
.L342:
	add	rdi, 8
	add	r14, r15
	cmp	rdi, r8
	jne	.L339
.L340:
	mov	rax, QWORD PTR 32[rsp]
	add	rdx, 1
	add	r9, r13
	add	rcx, r13
	add	r8, rax
	cmp	QWORD PTR 16[rsp], rdx
	jne	.L337
	mov	rax, QWORD PTR 160[rsp]
	mov	r14, QWORD PTR 24[rsp]
	mov	rsi, QWORD PTR 168[rsp]
.L336:
	mov	rdx, QWORD PTR 40[rsp]
	add	r10, rdx
	sub	rsi, rdx
	cmp	r10, r15
	jb	.L344
	mov	r8, QWORD PTR 120[rsp]
	mov	rcx, QWORD PTR 128[rsp]
	mov	r9, QWORD PTR 136[rsp]
	mov	r11, QWORD PTR 144[rsp]
	mov	rbx, QWORD PTR 152[rsp]
.L347:
	mov	rdx, QWORD PTR 40[rsp]
	add	QWORD PTR 8[rsp], r11
	add	r14, rdx
	sub	rcx, rdx
	cmp	r14, r8
	jb	.L348
	mov	rdi, rax
	mov	r12, QWORD PTR 104[rsp]
	mov	rax, QWORD PTR 96[rsp]
	mov	rdx, QWORD PTR 112[rsp]
.L345:
	mov	rcx, QWORD PTR 40[rsp]
	add	QWORD PTR 56[rsp], r11
	add	r9, r12
	add	rdi, rcx
	sub	rdx, rcx
	cmp	rdi, rax
	jb	.L335
.L321:
	add	rsp, 184
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	mov	rax, rbx
	pop	rbx
	.cfi_def_cfa_offset 48
	pop	rbp
	.cfi_def_cfa_offset 40
	pop	r12
	.cfi_def_cfa_offset 32
	pop	r13
	.cfi_def_cfa_offset 24
	pop	r14
	.cfi_def_cfa_offset 16
	pop	r15
	.cfi_def_cfa_offset 8
	ret
.L326:
	.cfi_restore_state
	mov	edi, 16
	call	__cxa_allocate_exception@PLT
	lea	rsi, .LC2[rip]
	mov	rdi, rax
	mov	rbx, rax
.LEHB19:
	call	_ZNSt12length_errorC1EPKc@PLT
.LEHE19:
	mov	rdx, QWORD PTR _ZNSt12length_errorD1Ev@GOTPCREL[rip]
	lea	rsi, _ZTISt12length_error[rip]
	mov	rdi, rbx
.LEHB20:
	call	__cxa_throw@PLT
.L382:
	lea	rdi, .LC3[rip]
	call	_ZSt20__throw_length_errorPKc@PLT
.LEHE20:
.L381:
	mov	edi, 16
	call	__cxa_allocate_exception@PLT
	lea	rsi, .LC14[rip]
	mov	rdi, rax
	mov	rbx, rax
.LEHB21:
	call	_ZNSt16invalid_argumentC1EPKc@PLT
.LEHE21:
.L378:
	mov	rdx, QWORD PTR _ZNSt16invalid_argumentD1Ev@GOTPCREL[rip]
	lea	rsi, _ZTISt16invalid_argument[rip]
	mov	rdi, rbx
.LEHB22:
	call	__cxa_throw@PLT
.LEHE22:
.L380:
	mov	edi, 16
	call	__cxa_allocate_exception@PLT
	lea	rsi, .LC1[rip]
	mov	rdi, rax
	mov	rbx, rax
.LEHB23:
	call	_ZNSt16invalid_argumentC1EPKc@PLT
.LEHE23:
	jmp	.L378
.L353:
	endbr64
.L379:
	mov	rbp, rax
	jmp	.L350
.L352:
	endbr64
	jmp	.L379
.L351:
	endbr64
	jmp	.L379
.L350:
	mov	rdi, rbx
	call	__cxa_free_exception@PLT
	mov	rdi, rbp
.LEHB24:
	call	_Unwind_Resume@PLT
.LEHE24:
	.cfi_endproc
.LFE6786:
	.section	.gcc_except_table._Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m,"aG",@progbits,_Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m,comdat
.LLSDA6786:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE6786-.LLSDACSB6786
.LLSDACSB6786:
	.uleb128 .LEHB18-.LFB6786
	.uleb128 .LEHE18-.LEHB18
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB19-.LFB6786
	.uleb128 .LEHE19-.LEHB19
	.uleb128 .L353-.LFB6786
	.uleb128 0
	.uleb128 .LEHB20-.LFB6786
	.uleb128 .LEHE20-.LEHB20
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB21-.LFB6786
	.uleb128 .LEHE21-.LEHB21
	.uleb128 .L352-.LFB6786
	.uleb128 0
	.uleb128 .LEHB22-.LFB6786
	.uleb128 .LEHE22-.LEHB22
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB23-.LFB6786
	.uleb128 .LEHE23-.LEHB23
	.uleb128 .L351-.LFB6786
	.uleb128 0
	.uleb128 .LEHB24-.LFB6786
	.uleb128 .LEHE24-.LEHB24
	.uleb128 0
	.uleb128 0
.LLSDACSE6786:
	.section	.text._Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m,"axG",@progbits,_Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m,comdat
	.size	_Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m, .-_Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC15:
	.string	"Matrix index out of range"
.LC17:
	.string	"Matrix size: "
.LC18:
	.string	" x "
.LC19:
	.string	"ijk: "
.LC20:
	.string	"ms\n"
.LC21:
	.string	"ikj: "
.LC22:
	.string	"multiply block by block: "
	.section	.text.unlikely,"ax",@progbits
.LCOLDB23:
	.section	.text.startup,"ax",@progbits
.LHOTB23:
	.p2align 4
	.globl	main
	.type	main, @function
main:
.LFB5917:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA5917
	endbr64
	push	r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	mov	edx, 1024
	mov	esi, 1024
	push	r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	push	r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	push	r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	push	rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	push	rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	sub	rsp, 248
	.cfi_def_cfa_offset 304
	mov	rax, QWORD PTR fs:40
	mov	QWORD PTR 232[rsp], rax
	xor	eax, eax
	lea	rax, 96[rsp]
	mov	rdi, rax
	mov	QWORD PTR 32[rsp], rax
.LEHB25:
	call	_ZN6MatrixIdEC1Emm
.LEHE25:
	mov	edx, 1024
	mov	esi, 1024
	lea	rax, 144[rsp]
	mov	rdi, rax
	mov	QWORD PTR 16[rsp], rax
.LEHB26:
	call	_ZN6MatrixIdEC1Emm
.LEHE26:
	mov	r14, QWORD PTR 112[rsp]
	mov	r13, QWORD PTR 96[rsp]
	xor	r15d, r15d
	xor	edi, edi
	mov	rbx, QWORD PTR 152[rsp]
	mov	r9, QWORD PTR 104[rsp]
	movabs	rbp, -2049638230412172401
	mov	QWORD PTR [rsp], r14
	mov	r12, QWORD PTR 144[rsp]
	mov	r8, QWORD PTR 160[rsp]
	movsd	xmm2, QWORD PTR .LC16[rip]
	lea	rsi, 0[0+rbx*8]
	.p2align 4,,10
	.p2align 3
.L384:
	mov	rax, QWORD PTR [rsp]
	lea	r14, [rdi+rdi]
	xor	ecx, ecx
	lea	r11, [rax+r15*8]
	.p2align 4,,10
	.p2align 3
.L394:
	lea	r10, [rdi+rcx]
	pxor	xmm0, xmm0
	mov	rax, r10
	mul	rbp
	mov	rax, rdx
	and	rdx, -8
	shr	rax, 3
	add	rdx, rax
	sub	r10, rdx
	cvtsi2sd	xmm0, r10
	cmp	r13, rdi
	je	.L385
	cmp	r9, rcx
	je	.L385
	movsd	QWORD PTR [r11+rcx*8], xmm0
	pxor	xmm0, xmm0
	pxor	xmm1, xmm1
	cvtsi2sd	xmm0, rcx
	cvtsi2sd	xmm1, r14
	mulsd	xmm0, xmm2
	addsd	xmm0, xmm1
	cmp	r12, rdi
	je	.L503
	cmp	rbx, rcx
	je	.L388
	movsd	QWORD PTR [r8+rcx*8], xmm0
	add	rcx, 1
	cmp	rcx, 1024
	jne	.L394
	add	rdi, 1
	add	r8, rsi
	add	r15, r9
	cmp	rdi, 1024
	jne	.L384
	lea	r13, _ZSt4cout[rip]
	lea	rsi, .LC17[rip]
	mov	rdi, r13
.LEHB27:
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	mov	rdi, rax
	mov	esi, 1024
	call	_ZNSo9_M_insertImEERSoT_@PLT
	mov	rdi, rax
	lea	rsi, .LC18[rip]
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	mov	rdi, rax
	mov	esi, 1024
	call	_ZNSo9_M_insertImEERSoT_@PLT
	mov	rdi, rax
	lea	rsi, .LC11[rip]
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	lea	rsi, .LC19[rip]
	mov	rdi, r13
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	mov	r14, QWORD PTR 16[rsp]
	mov	r15, QWORD PTR 32[rsp]
	lea	rdi, _Z12multiply_ijkIdE6MatrixIT_ERKS2_S4_[rip]
	mov	rbx, rax
	mov	rdx, r14
	mov	rsi, r15
	call	_Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_
	mov	rdi, rbx
	call	_ZNSo9_M_insertIdEERSoT_@PLT
	lea	rbx, .LC20[rip]
	mov	rdi, rax
	mov	rsi, rbx
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	lea	rsi, .LC21[rip]
	mov	rdi, r13
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	mov	rdx, r14
	mov	rsi, r15
	lea	rdi, _Z12multiply_ikjIdE6MatrixIT_ERKS2_S4_[rip]
	mov	rbp, rax
	call	_Z16benchmark_matrixIPF6MatrixIdERKS1_S3_EEdT_S3_RS1_
	mov	rdi, rbp
	call	_ZNSo9_M_insertIdEERSoT_@PLT
	mov	rdi, rax
	mov	rsi, rbx
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	lea	rsi, .LC22[rip]
	mov	rdi, r13
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
.LEHE27:
	mov	QWORD PTR 40[rsp], rax
	lea	rax, 192[rsp]
	pxor	xmm0, xmm0
	mov	QWORD PTR 80[rsp], 0
	mov	DWORD PTR 52[rsp], 6
	mov	QWORD PTR [rsp], 0x000000000
	mov	QWORD PTR 56[rsp], rax
	movaps	XMMWORD PTR 64[rsp], xmm0
.L416:
	call	_ZNSt6chrono3_V212steady_clock3nowEv@PLT
	mov	rdx, QWORD PTR 16[rsp]
	mov	rsi, QWORD PTR 32[rsp]
	mov	ecx, 32
	mov	rdi, QWORD PTR 56[rsp]
	mov	rbx, rax
.LEHB28:
	call	_Z23multiply_block_by_blockIdE6MatrixIT_ERKS2_S4_m
.LEHE28:
	call	_ZNSt6chrono3_V212steady_clock3nowEv@PLT
	pxor	xmm0, xmm0
	mov	rbp, QWORD PTR 208[rsp]
	sub	rax, rbx
	cvtsi2sd	xmm0, rax
	mov	rax, QWORD PTR 216[rsp]
	divsd	xmm0, QWORD PTR .LC5[rip]
	movsd	QWORD PTR 8[rsp], xmm0
	mov	rdx, rax
	sub	rdx, rbp
	sar	rdx, 3
	cmp	rbp, rax
	je	.L398
	movsd	xmm3, QWORD PTR [rsp]
	addsd	xmm3, QWORD PTR 0[rbp]
	lea	rcx, -1[rdx]
	mov	eax, 1
	and	ecx, 1
	movsd	QWORD PTR [rsp], xmm3
	cmp	rax, rdx
	jnb	.L398
	test	rcx, rcx
	je	.L500
	movsd	xmm4, QWORD PTR [rsp]
	addsd	xmm4, QWORD PTR 8[rbp]
	mov	eax, 2
	movsd	QWORD PTR [rsp], xmm4
	cmp	rax, rdx
	jnb	.L398
.L500:
	movsd	xmm0, QWORD PTR [rsp]
.L399:
	addsd	xmm0, QWORD PTR 0[rbp+rax*8]
	addsd	xmm0, QWORD PTR 8[rbp+rax*8]
	add	rax, 2
	cmp	rax, rdx
	jb	.L399
	movsd	QWORD PTR [rsp], xmm0
.L398:
	movsd	xmm0, QWORD PTR [rsp]
	movsd	xmm5, QWORD PTR .LC7[rip]
	andpd	xmm0, XMMWORD PTR .LC6[rip]
	ucomisd	xmm5, xmm0
	jnb	.L403
	mov	edx, 21
	lea	rsi, .LC8[rip]
	lea	rdi, _ZSt4cerr[rip]
.LEHB29:
	call	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
.LEHE29:
.L403:
	mov	rbx, QWORD PTR 72[rsp]
	mov	r14, QWORD PTR 80[rsp]
	cmp	rbx, r14
	je	.L504
	movsd	xmm6, QWORD PTR 8[rsp]
	add	rbx, 8
	movsd	QWORD PTR -8[rbx], xmm6
	mov	QWORD PTR 72[rsp], rbx
.L404:
	test	rbp, rbp
	je	.L415
	mov	rsi, QWORD PTR 224[rsp]
	mov	rdi, rbp
	sub	rsi, rbp
	call	_ZdlPvm@PLT
.L415:
	sub	DWORD PTR 52[rsp], 1
	jne	.L416
	mov	rbp, QWORD PTR 72[rsp]
	mov	rbx, QWORD PTR 64[rsp]
	cmp	rbp, rbx
	je	.L417
	mov	r12, rbp
	mov	rsi, rbp
	lea	r14, 8[rbx]
	mov	rdi, rbx
	sub	r12, rbx
	mov	rax, r12
	sar	rax, 3
	bsr	rdx, rax
	xor	rdx, 63
	test	rax, rax
	mov	eax, 64
	cmovne	eax, edx
	mov	edx, 63
	sub	edx, eax
	movsx	rdx, edx
	add	rdx, rdx
	call	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPdSt6vectorIdSaIdEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.0
	cmp	r12, 128
	jg	.L505
	cmp	rbp, r14
	je	.L417
	mov	r12d, 8
	jmp	.L443
.L506:
	sub	rdx, rbx
	cmp	rdx, 8
	jle	.L437
	mov	rdi, r12
	mov	rsi, rbx
	movsd	QWORD PTR 8[rsp], xmm0
	sub	rdi, rdx
	add	rdi, r14
	call	memmove@PLT
	movsd	xmm0, QWORD PTR 8[rsp]
.L438:
	add	r14, 8
	movsd	QWORD PTR [rbx], xmm0
	cmp	r14, rbp
	je	.L417
.L443:
	movsd	xmm0, QWORD PTR [r14]
	movsd	xmm1, QWORD PTR [rbx]
	mov	rdx, r14
	comisd	xmm1, xmm0
	ja	.L506
	movsd	xmm1, QWORD PTR -8[r14]
	lea	rax, -8[r14]
	comisd	xmm1, xmm0
	jbe	.L440
.L442:
	movsd	QWORD PTR 8[rax], xmm1
	mov	rdx, rax
	movsd	xmm1, QWORD PTR -8[rax]
	sub	rax, 8
	comisd	xmm1, xmm0
	ja	.L442
.L440:
	add	r14, 8
	movsd	QWORD PTR [rdx], xmm0
	cmp	r14, rbp
	jne	.L443
.L417:
	lea	rsi, .LC10[rip]
	mov	rdi, r13
.LEHB30:
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	movsd	xmm0, QWORD PTR [rsp]
	mov	rdi, rax
	call	_ZNSo9_M_insertIdEERSoT_@PLT
	mov	rdi, rax
	lea	rsi, .LC11[rip]
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
.LEHE30:
	mov	rax, rbp
	lea	rdi, 64[rsp]
	sub	rax, rbx
	sar	rax, 3
	shr	rax
	movsd	xmm0, QWORD PTR -8[rbx+rax*8]
	addsd	xmm0, QWORD PTR [rbx+rax*8]
	mulsd	xmm0, QWORD PTR .LC12[rip]
	movsd	QWORD PTR [rsp], xmm0
	call	_ZNSt12_Vector_baseIdSaIdEED2Ev
	movsd	xmm0, QWORD PTR [rsp]
	mov	rdi, QWORD PTR 40[rsp]
.LEHB31:
	call	_ZNSo9_M_insertIdEERSoT_@PLT
	mov	rdi, rax
	lea	rsi, .LC11[rip]
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
.LEHE31:
	lea	rdi, 160[rsp]
	call	_ZNSt12_Vector_baseIdSaIdEED2Ev
	lea	rdi, 112[rsp]
	call	_ZNSt12_Vector_baseIdSaIdEED2Ev
	mov	rax, QWORD PTR 232[rsp]
	sub	rax, QWORD PTR fs:40
	jne	.L507
	add	rsp, 248
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	xor	eax, eax
	pop	rbx
	.cfi_def_cfa_offset 48
	pop	rbp
	.cfi_def_cfa_offset 40
	pop	r12
	.cfi_def_cfa_offset 32
	pop	r13
	.cfi_def_cfa_offset 24
	pop	r14
	.cfi_def_cfa_offset 16
	pop	r15
	.cfi_def_cfa_offset 8
	ret
.L504:
	.cfi_restore_state
	movabs	rax, 1152921504606846975
	mov	r12, QWORD PTR 64[rsp]
	sub	rbx, r12
	mov	rdx, rbx
	sar	rdx, 3
	cmp	rdx, rax
	je	.L508
	cmp	r14, r12
	je	.L509
	lea	rsi, [rdx+rdx]
	cmp	rsi, rdx
	jb	.L410
	xor	eax, eax
	xor	r15d, r15d
	mov	QWORD PTR 24[rsp], rax
	test	rsi, rsi
	jne	.L510
.L411:
	movsd	xmm7, QWORD PTR 8[rsp]
	lea	rax, 8[r15+rbx]
	mov	QWORD PTR 8[rsp], rax
	movsd	QWORD PTR [r15+rbx], xmm7
	test	rbx, rbx
	jg	.L511
	test	r12, r12
	jne	.L413
.L414:
	mov	rcx, QWORD PTR 24[rsp]
	mov	rax, QWORD PTR 8[rsp]
	mov	QWORD PTR 64[rsp], r15
	add	rcx, r15
	mov	QWORD PTR 72[rsp], rax
	mov	QWORD PTR 80[rsp], rcx
	jmp	.L404
.L505:
	lea	r15, 128[rbx]
	mov	r12d, 8
	jmp	.L428
.L513:
	sub	rdx, rbx
	cmp	rdx, 8
	jle	.L422
	mov	rdi, r12
	mov	rsi, rbx
	movsd	QWORD PTR 8[rsp], xmm0
	sub	rdi, rdx
	add	rdi, r14
	call	memmove@PLT
	movsd	xmm0, QWORD PTR 8[rsp]
.L423:
	add	r14, 8
	movsd	QWORD PTR [rbx], xmm0
	cmp	r14, r15
	je	.L512
.L428:
	movsd	xmm0, QWORD PTR [r14]
	movsd	xmm1, QWORD PTR [rbx]
	mov	rdx, r14
	comisd	xmm1, xmm0
	ja	.L513
	movsd	xmm1, QWORD PTR -8[r14]
	lea	rax, -8[r14]
	comisd	xmm1, xmm0
	jbe	.L425
.L427:
	movsd	QWORD PTR 8[rax], xmm1
	mov	rdx, rax
	movsd	xmm1, QWORD PTR -8[rax]
	sub	rax, 8
	comisd	xmm1, xmm0
	ja	.L427
.L425:
	add	r14, 8
	movsd	QWORD PTR [rdx], xmm0
	cmp	r14, r15
	jne	.L428
.L512:
	cmp	rbp, r15
	je	.L417
.L429:
	movsd	xmm1, QWORD PTR [r15]
	movsd	xmm0, QWORD PTR -8[r15]
	lea	rax, -8[r15]
	comisd	xmm0, xmm1
	jbe	.L495
.L433:
	movsd	QWORD PTR 8[rax], xmm0
	mov	rdx, rax
	movsd	xmm0, QWORD PTR -8[rax]
	sub	rax, 8
	comisd	xmm0, xmm1
	ja	.L433
.L431:
	add	r15, 8
	movsd	QWORD PTR [rdx], xmm1
	cmp	rbp, r15
	jne	.L429
	jmp	.L417
.L495:
	mov	rdx, r15
	jmp	.L431
.L511:
	mov	rdx, rbx
	mov	rsi, r12
	mov	rdi, r15
	call	memmove@PLT
.L413:
	mov	rsi, r14
	mov	rdi, r12
	sub	rsi, r12
	call	_ZdlPvm@PLT
	jmp	.L414
.L509:
	add	rdx, 1
	jc	.L410
	movabs	rax, 1152921504606846975
	cmp	rdx, rax
	cmovbe	rax, rdx
.L410:
	sal	rax, 3
	mov	rdi, rax
	mov	QWORD PTR 24[rsp], rax
.LEHB32:
	call	_Znwm@PLT
	mov	r15, rax
	jmp	.L411
.L422:
	jne	.L423
	movsd	QWORD PTR [r14], xmm1
	jmp	.L423
.L437:
	jne	.L438
	movsd	QWORD PTR [r14], xmm1
	jmp	.L438
.L507:
	call	__stack_chk_fail@PLT
.L510:
	movabs	rax, 1152921504606846975
	cmp	rsi, rax
	cmovbe	rax, rsi
	jmp	.L410
.L508:
	mov	rax, QWORD PTR 232[rsp]
	sub	rax, QWORD PTR fs:40
	jne	.L514
	lea	rdi, .LC9[rip]
	call	_ZSt20__throw_length_errorPKc@PLT
.LEHE32:
.L514:
	call	__stack_chk_fail@PLT
.L460:
	endbr64
	mov	rbx, rax
	jmp	.L445
.L455:
	endbr64
	mov	rbx, rax
	jmp	.L447
.L459:
	endbr64
	mov	rbx, rax
	jmp	.L446
.L489:
	endbr64
	jmp	.L490
.L503:
	jmp	.L388
	.section	.gcc_except_table,"a",@progbits
.LLSDA5917:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE5917-.LLSDACSB5917
.LLSDACSB5917:
	.uleb128 .LEHB25-.LFB5917
	.uleb128 .LEHE25-.LEHB25
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB26-.LFB5917
	.uleb128 .LEHE26-.LEHB26
	.uleb128 .L455-.LFB5917
	.uleb128 0
	.uleb128 .LEHB27-.LFB5917
	.uleb128 .LEHE27-.LEHB27
	.uleb128 .L489-.LFB5917
	.uleb128 0
	.uleb128 .LEHB28-.LFB5917
	.uleb128 .LEHE28-.LEHB28
	.uleb128 .L459-.LFB5917
	.uleb128 0
	.uleb128 .LEHB29-.LFB5917
	.uleb128 .LEHE29-.LEHB29
	.uleb128 .L460-.LFB5917
	.uleb128 0
	.uleb128 .LEHB30-.LFB5917
	.uleb128 .LEHE30-.LEHB30
	.uleb128 .L459-.LFB5917
	.uleb128 0
	.uleb128 .LEHB31-.LFB5917
	.uleb128 .LEHE31-.LEHB31
	.uleb128 .L489-.LFB5917
	.uleb128 0
	.uleb128 .LEHB32-.LFB5917
	.uleb128 .LEHE32-.LEHB32
	.uleb128 .L460-.LFB5917
	.uleb128 0
.LLSDACSE5917:
	.section	.text.startup
	.cfi_endproc
	.section	.text.unlikely
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDAC5917
	.type	main.cold, @function
main.cold:
.LFSB5917:
.L385:
	.cfi_def_cfa_offset 304
	.cfi_offset 3, -56
	.cfi_offset 6, -48
	.cfi_offset 12, -40
	.cfi_offset 13, -32
	.cfi_offset 14, -24
	.cfi_offset 15, -16
	mov	edi, 16
	call	__cxa_allocate_exception@PLT
	lea	rsi, .LC15[rip]
	mov	rdi, rax
	mov	rbp, rax
.LEHB33:
	call	_ZNSt12out_of_rangeC1EPKc@PLT
.LEHE33:
	mov	rax, QWORD PTR 232[rsp]
	sub	rax, QWORD PTR fs:40
	jne	.L515
	mov	rdx, QWORD PTR _ZNSt12out_of_rangeD1Ev@GOTPCREL[rip]
	lea	rsi, _ZTISt12out_of_range[rip]
	mov	rdi, rbp
.LEHB34:
	call	__cxa_throw@PLT
.LEHE34:
.L445:
	lea	rdi, 208[rsp]
	call	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L446:
	lea	rdi, 64[rsp]
	call	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L391:
	lea	rdi, 160[rsp]
	call	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L447:
	lea	rdi, 112[rsp]
	call	_ZNSt12_Vector_baseIdSaIdEED2Ev
	mov	rax, QWORD PTR 232[rsp]
	sub	rax, QWORD PTR fs:40
	jne	.L516
	mov	rdi, rbx
.LEHB35:
	call	_Unwind_Resume@PLT
.LEHE35:
.L515:
	call	__stack_chk_fail@PLT
.L456:
	endbr64
.L490:
	mov	rbx, rax
	jmp	.L391
.L457:
	endbr64
.L502:
	mov	rdi, rbp
	mov	rbx, rax
	call	__cxa_free_exception@PLT
	jmp	.L391
.L388:
	mov	edi, 16
	call	__cxa_allocate_exception@PLT
	lea	rsi, .LC15[rip]
	mov	rdi, rax
	mov	rbp, rax
.LEHB36:
	call	_ZNSt12out_of_rangeC1EPKc@PLT
.LEHE36:
	mov	rax, QWORD PTR 232[rsp]
	sub	rax, QWORD PTR fs:40
	jne	.L517
	mov	rdx, QWORD PTR _ZNSt12out_of_rangeD1Ev@GOTPCREL[rip]
	lea	rsi, _ZTISt12out_of_range[rip]
	mov	rdi, rbp
.LEHB37:
	call	__cxa_throw@PLT
.LEHE37:
.L517:
	call	__stack_chk_fail@PLT
.L458:
	endbr64
	jmp	.L502
.L516:
	call	__stack_chk_fail@PLT
	.cfi_endproc
.LFE5917:
	.section	.gcc_except_table
.LLSDAC5917:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSEC5917-.LLSDACSBC5917
.LLSDACSBC5917:
	.uleb128 .LEHB33-.LCOLDB23
	.uleb128 .LEHE33-.LEHB33
	.uleb128 .L457-.LCOLDB23
	.uleb128 0
	.uleb128 .LEHB34-.LCOLDB23
	.uleb128 .LEHE34-.LEHB34
	.uleb128 .L456-.LCOLDB23
	.uleb128 0
	.uleb128 .LEHB35-.LCOLDB23
	.uleb128 .LEHE35-.LEHB35
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB36-.LCOLDB23
	.uleb128 .LEHE36-.LEHB36
	.uleb128 .L458-.LCOLDB23
	.uleb128 0
	.uleb128 .LEHB37-.LCOLDB23
	.uleb128 .LEHE37-.LEHB37
	.uleb128 .L456-.LCOLDB23
	.uleb128 0
.LLSDACSEC5917:
	.section	.text.unlikely
	.section	.text.startup
	.size	main, .-main
	.section	.text.unlikely
	.size	main.cold, .-main.cold
.LCOLDE23:
	.section	.text.startup
.LHOTE23:
	.section	.rodata.cst8,"aM",@progbits,8
	.align 8
.LC5:
	.long	0
	.long	1093567616
	.section	.rodata.cst16,"aM",@progbits,16
	.align 16
.LC6:
	.long	-1
	.long	2147483647
	.long	0
	.long	0
	.section	.rodata.cst8
	.align 8
.LC7:
	.long	-1
	.long	2146435071
	.align 8
.LC12:
	.long	0
	.long	1071644672
	.align 8
.LC16:
	.long	-1717986918
	.long	1070176665
	.hidden	DW.ref.__gxx_personality_v0
	.weak	DW.ref.__gxx_personality_v0
	.section	.data.rel.local.DW.ref.__gxx_personality_v0,"awG",@progbits,DW.ref.__gxx_personality_v0,comdat
	.align 8
	.type	DW.ref.__gxx_personality_v0, @object
	.size	DW.ref.__gxx_personality_v0, 8
DW.ref.__gxx_personality_v0:
	.quad	__gxx_personality_v0
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
