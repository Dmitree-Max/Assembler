; -------------------------------------------------------------------------------------	;
;	������������ ������ �n �� ����� ���������������� �� ����� ����������				;
;	������� �1.8.																		;
;	�������� ������� ���������� ������� ���������.										;
;																						;
;	�������� ������ LabAssignment.asm													;
;	�������� ������� �� ����� ����������, ������������� � ������������ � ��������		;
; -------------------------------------------------------------------------------------	;
;	�������: ����������� ������ � �������� �������������� �����
;	������ ������ �������: __int16
;	������ ������ �������: double
;	������ (���������� ��������) ������� � �������: 8
;	������ ����������: DFT 2x2 + 2 �������
;	������� ������� �������� ������������ �������. ������ �������������� ����� ��������
;	� ������ �������� �������, � ������ - �� ������

.DATA
;   ����� 8 ������� �� 1
    roots  real8  1., 0.70710678 , 0. , -0.70710678, -1., -0.70710678, 0., 0.70710678,                  ; ������������ �����
			      0., -0.70710678, -1., -0.70710678,  0., 0.70710678 , 1., 0.70710678                   ; ������ �����

;   ����� 4 ������� �� 1
	forthroots real8    1., 0. , -1., 0. ,
	                    0., -1.,  0., 1.
;   ������� ��������������, ��� �� ��� ���������
	matrix       dw 1, 1, 1, -1
;   ���������� �������� �������
	signal_size  dw 8


.CODE
; -------------------------------------------------------------------------------------	;
; void CalculateSpectrum(spectrum_type* Spectrum, signal_type* Signal)					;
;	������ �������������� �����. ��������� ������ Spectrum �� ������� Signal			;
;	���� ������ spectrum_type � signal_type, � ��� �� ������� �������					;
;	������������ � ����� Tuning.h														;
; -------------------------------------------------------------------------------------	;
CalculateSpectrum PROC	; [RCX] - Spectrum
						; [RDX] - Signal
	
	push rbp
	push rcx
	sub rsp, 16              ; ����� ��� �������� ���������� ������� ����
	push rdx

	mov rbp, rsp                                ;
	and  sp, 0FFE0h                             ; ������������ ��������� �� 32 ����

	;*************      �������� ������� �� �������     ***************
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov rcx, [rbp]
	lea rdx, matrix
	mov r9, rbp 
	add r9, 8
	call MultiplyVectorOnMatrix
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov rcx, [rbp]
	add rcx, 2
	lea rdx, matrix
	mov r9, rbp 
	add r9, 12
	call MultiplyVectorOnMatrix
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov rcx, [rbp]
	add rcx, 4
	lea rdx, matrix
	mov r9, rbp 
	add r9, 16
	call MultiplyVectorOnMatrix
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov rcx, [rbp]
	add rcx, 6
	lea rdx, matrix
	mov r9, rbp 
	add r9, 20
	call MultiplyVectorOnMatrix
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	add rbp, 8    ; ������� �� ����� ��������� �� ������, �� ��� ����������� �������� � ������� first_step_res
	              ; ������ ���� �������� ��������� ������� ���� � dst 
	finit

	sub rsp, 64                                 ; ����������� ����� ��� �������� ����� � 64 ������ �����


	;----------------------------�������������� � ������, � ���� 64 ������ ����� � ��������� ������------------------------------------

	mov rcx, 8                             ;  ���������� ��������
	mov rax, rbp                           ;  src
	mov r8 , rsp                           ;  dst

start_loop_rewrite:      
	    fild  word  ptr [rax]              ; ��������� 16 ������ ����� �����
	    fstp  qword ptr [r8]               ; ��������� ���������, ��� ����� 16 ������ �����

		dec rcx

		cmp cx, 0
		je end_loop_rewrite
		add rax, 2                         ; ����� � src �� ���� ������� int16
		add r8 , 8                         ; ����� � dst �� ���� ������� real8
		jmp start_loop_rewrite

end_loop_rewrite:


    sub rsp, 128                                 ; ����������� ����� ��� �������� ���������� ������� ����


	; vpmovsxwq  xmm0, dword ptr [rbp]            ; ��������� 2 ������ ����� �� ymm0
	 ;vpmovsxwq  xmm1, dword ptr [rbp + 4]        ;
	; vperm2f128 ymm0, ymm0, ymm0, 6              ;
	; vpmovsxwq  xmm1, dword ptr [rbp + 8]        ; ��������� 2 ������ ����� �� ymm1
	; vpmovsxwq  xmm2, dword ptr [rbp + 12]       ;
	; vperm2f128 ymm1, ymm1, ymm1, 6              ; 

	add rbp, 16                                  ; ������� ��������, ���������� � 16 ������ �����

;----------------------������ �������: ��� ����� ������������ � ����������� ����� -----------------------------
	 lea rbx, forthroots
;--------------������������ �����------------------------------------------------------------------------------

    vbroadcastf128 ymm0, xmmword ptr [rsp + 128]         ;      ������������ ����� ������ ���������
	vbroadcastf128 ymm1, xmmword ptr [rsp + 160]         ;      ������������ ����� ������ ���������
	 vmovdqa        ymm3, ymmword ptr [rbx]               ;      ������������ ����� ������ 

	 vmulpd         ymm3, ymm1, ymm3                      ;      ������������ ������� �������� �� ������������ ����� 
	 vaddpd         ymm3, ymm0, ymm3                      ;
	                                                      ;      �������� ����� ������������ �����, ���������� �� � ������.
     vmovapd  ymmword ptr [rsp], ymm3                     ;      ���������� � ������
	  
;-------------����������� �����---------------------------------------------------------------------------------

	 vbroadcastf128 ymm0, xmmword ptr [rsp + 160]         ;      ������������ ����� ������ ���������
	 vmovdqa        ymm4, ymmword ptr [rbx + 32]          ;      ����������� ����� ������
	 vmulpd         ymm0, ymm0, ymm4                      ;      ������������ ������ �� ����������� ������
     vmovapd        ymmword ptr [rsp + 64], ymm0          ;      ���������� � ������


;----------------------������ �������: ��� ����� ������������ � ����������� ����� -----------------------------
;--------------������������ �����------------------------------------------------------------------------------

     vbroadcastf128 ymm0, xmmword ptr [rsp + 144]         ;      ������������ ����� ������ ���������
	 vbroadcastf128 ymm1, xmmword ptr [rsp + 176]         ;      ������������ ����� ������ ���������
	 vmovdqa        ymm3, ymmword ptr [rbx]               ;      ������������ ����� ������ 
	 vmovdqa        ymm4, ymmword ptr [rbx + 32]          ;      ����������� ����� ������
	 vmulpd         ymm1, ymm1, ymm3                      ;      ������������ ������� �������� �� ������������ �����
	 vaddpd         ymm0, ymm0, ymm1                      ;
	                                                      ;      �������� ����� ������������ �����, ���������� �� � ������.
     vmovapd  ymmword ptr [rsp + 32], ymm0                ;      ���������� � ������
	  
;-------------����������� �����---------------------------------------------------------------------------------


	 vbroadcastf128 ymm0, xmmword ptr [rsp + 176]         ;      ������������ ����� ������ ���������
	 vmulpd         ymm0, ymm0, ymm4                      ;      ������������ ������ �� ����������� ������
     vmovapd  ymmword ptr [rsp + 96], ymm0                ;      ���������� � ������


	 
	 ;-----------------------------������� �������, ������������ � ����������� �����---------------------------------
	
	;-----------------------������� �������� ������� �������---------------------------------------------------------
	;---------------������������ �����-------------------------------------------------------------------------------
	lea            rbx , roots                           ;      ����� 8-�� ������� �� 1
	mov            rax , rsp                             ;      src
    mov            r8  , [rbp]                           ;      dst

	vmovdqa        ymm0, ymmword ptr [rax]               ;      ������������ ������ ���������
	vmovdqa        ymm1, ymmword ptr [rax + 32]          ;      ������������ ������
	vmovdqa        ymm2, ymmword ptr [rbx]               ;      ������������ ������ 
	vmulpd         ymm1, ymm1, ymm2                      ;      ������������ ������ �� ������������ ������
	vaddpd         ymm0, ymm0, ymm1                      ;      ���������� � ������������ ������ ������ ���������

	vmovdqa        ymm1, ymmword ptr [rax + 96]          ;      ����������� ������
	vmovdqa        ymm2, ymmword ptr [rbx + 64]          ;      ����������� ������
	vmulpd         ymm1, ymm1, ymm2                      ;      ����������� ������ �� ����������� ������
	vsubpd         ymm0, ymm0, ymm1                      ;      ��������, �� � ������������ ����������� ������ i^2 = -1
	 
	vmovdqa        ymmword ptr [r8], ymm0                ;      ���������� � ������

	;---------------����������� �����--------------------------------------------------------------------------------

	vmovdqa        ymm0, ymmword ptr [rax + 64]          ;      ����������� ������ ���������
	vmovdqa        ymm1, ymmword ptr [rax + 32]          ;      ������������ ������
	vmovdqa        ymm2, ymmword ptr [rax + 96]          ;      ����������� ������
	vmovdqa        ymm3, ymmword ptr [rbx]               ;      ������������ ������ 
	vmovdqa        ymm4, ymmword ptr [rbx + 64]          ;      ����������� ������
	vmulpd         ymm1, ymm1, ymm4                      ;      ������������ ������ �� ����������� ������
	vmulpd         ymm2, ymm2, ymm3                      ;      ������������ ������ �� ������������ ������

	vaddpd         ymm0, ymm0, ymm1                      ;      ���������� � ����������� ������ ������ ���������
	vaddpd         ymm0, ymm0, ymm2                      ;      
	 
	vmovdqa        ymmword ptr [r8 + 64], ymm0           ;      ���������� � ������


	;-----------------------������ �������� ������� �������----------------------------------------------------------
	;---------------������������ �����-------------------------------------------------------------------------------
	vmovdqa        ymm0, ymmword ptr [rax]               ;      ������������ ������ ���������
	vmovdqa        ymm1, ymmword ptr [rax + 32]          ;      ������������ ������
	vmovdqa        ymm2, ymmword ptr [rbx + 32]          ;      ������������ ������, ������� � 5-�� �����
	vmulpd         ymm1, ymm1, ymm2                      ;      ������������ ������ �� ������������ ������
	vaddpd         ymm0, ymm0, ymm1                      ;      ���������� � ������������ ������ ������ ���������

	vmovdqa        ymm1, ymmword ptr [rax + 96]          ;      ����������� ������
	vmovdqa        ymm2, ymmword ptr [rbx + 96]          ;      ����������� ������, ������� � 5-�� �����
	vmulpd         ymm1, ymm1, ymm2                      ;      ����������� ������ �� ����������� ������
	vsubpd         ymm0, ymm0, ymm1                      ;      ��������, �� � ������������ ����������� ������ i^2 = -1
	
	vmovdqa        ymmword ptr [r8 + 32], ymm0           ;      ���������� � ������

	;---------------����������� �����--------------------------------------------------------------------------------

	vmovdqa        ymm0, ymmword ptr [rax + 64]          ;      ����������� ������ ���������
	vmovdqa        ymm1, ymmword ptr [rax + 32]          ;      ������������ ������
	vmovdqa        ymm2, ymmword ptr [rax + 96]          ;      ����������� ������
	vmovdqa        ymm3, ymmword ptr [rbx + 32]          ;      ������������ ������, ������� � 5-�� �����
	vmovdqa        ymm4, ymmword ptr [rbx + 96]          ;      ����������� ������, ������� � 5-�� �����
	vmulpd         ymm1, ymm1, ymm4                      ;      ������������ ������ �� ����������� ������
	vmulpd         ymm4, ymm2, ymm3                      ;      ������������ ������ �� ������������ ������

	vaddpd         ymm0, ymm0, ymm1                      ;      ���������� � ����������� ������ ������ ���������
	vaddpd         ymm0, ymm0, ymm4                      ;      
	 
	vmovdqa        ymmword ptr [r8 + 96], ymm0           ;      ���������� � ������

	vzeroall
	add rbp, 8                            ; ������� �� ����� ��������� �� src
	mov rsp, rbp                          ; ���������� ���� � �������������� �����
	mov rbp, [rsp]                        ; ��������������� rbp
	add rsp, 8                            ; ������� �� rsp rbp

	ret
CalculateSpectrum ENDP
; -------------------------------------------------------------------------------------	;
; void RecoverSignal(signal_type* Signal, spectrum_type* Spectrum)						;
;	�������� �������������� �����. ��������� ������ Signal �� ������� Spectrum			;
;	���� ������ spectrum_type � signal_type, � ��� �� ������ �������					;
;	������������ � ����� Tuning.h														;
; -------------------------------------------------------------------------------------	;
RecoverSignal PROC	; [RCX] - Signal
					; [RDX] - Spectrum
	finit

	push rcx
	sub rsp, 160                                ; ����� ��� ���������� ������� ���� + 32 ���� �� ������������
	mov rax, rsp                                ; 
	add rax, 32
	and  ax, 0FFE0h                             ; ������������ ��������� �� 32 ����

	;**************         ���� ��������� �������� �� �������            *************
	                                            ;  rdx - src �� �������
	mov rcx, 4                                  ;  ���������� ��������        
	mov r8,  rax                                ;  dst
	lea r9,  matrix                             ;  �������, �� ������� ������������ ���������

	;vmovapd ymm0, ymmword ptr [rdx]             ;  ������������ �����, ������ 4 ��������
	;vmovapd ymm1, ymmword ptr [rdx + 32]        ;  ������������ �����, ��������� 4 ���������
	
	;vaddpd ymm2, ymm0, ymm1                     ;  ������������ ����� ������ ��������� 
	;vmovapd [r8], ymm4                          ;  ���������� � ������
	;vsubpd ymm3, ymm0, ymm1                     :  ������������ ����� ������ ���������
	;vmovapd [r8 + 32], ymm4                     ;  ���������� � ������

	;vmovapd ymm0, ymmword ptr [rdx + 64]        ;  ������ �����, ������ 4 ��������
	;vmovapd ymm1, ymmword ptr [rdx + 96]        ;  ������ �����, ��������� 4 ���������

	;vaddpd ymm2, ymm0, ymm1                     ;  ������ ����� ������ ��������� 
	;vmovapd [r8 + 64], ymm4                     ;  ���������� � ������
	;vsubpd ymm3, ymm0, ymm1                     :  ������ ����� ������ ���������
	;vmovapd [r8 + 96], ymm4                     ;  ���������� � ������

	                                            ;  ������ � ������ x00, x10, x20, x30,          x01, x11, x21, x31      ��� ����� ������������, � ����� ����������� �����
												;  �����           x00, x01, x10, x11,          x20, x21, x30, x31 

	
 
start_loop_rev:
	;  |1 1| (x + ki) = (x + y + ki + li)
	;  |1 -1| (y + li) = (x - y + ki - li)
	;
	;;;;;;;;;;;;;;;;;;;;;;;;     ������������ ����� ������� �������� ������     ;;;;;;;;;;;;;;;;;;;;;;;;
	fild  word  ptr[r9]           ; a
	fld   qword ptr[rdx]          ; x
	fmulp                         ; ax
	fild  word ptr[r9 + 2]        ; b
	fld   qword ptr[rdx + 32]     ; y
	fmulp                         ; by
	faddp                         ; ax + by
	fstp  qword ptr[r8]           ; ���������� ���������

	;;;;;;;;;;;;;;;;;;;;;;;      ������ ����� ������� �������� ������         ;;;;;;;;;;;;;;;;;;;;;;;;

	fild  word ptr[r9]            ; a
	fld   qword ptr[rdx + 64]     ; k
	fmulp                         ; ak
	fild  word ptr[r9 + 2]        ; b
	fld   qword ptr[rdx + 96]     ; l
	fmulp                         ; bl
	faddp                         ; ak + bl
	fstp  qword ptr[r8 + 64]      ; ���������� ���������
	
	;;;;;;;;;;;������������ ����� ������� �������� ������;;;;;;;;;;;;;;;;;;;;;;;;
	fild  word  ptr[r9 + 4]       ; c
	fld   qword ptr[rdx]          ; x
	fmulp                         ; cx
	fild  word  ptr[r9 + 6]       ; d
	fld   qword ptr[rdx + 32]     ; y
	fmulp                         ; dy
	faddp                         ; cx + dy
	fstp  qword ptr[r8 + 8]       ; ���������� ���������
	;;;;;;;;;;;������ ����� ������� �������� ������;;;;;;;;;;;;;;;;;;;;;;;;
	fild  word  ptr[r9 + 4]       ; c
	fld   qword ptr[rdx + 64]     ; k
	fmulp                         ; ck
	fild  word  ptr[r9 + 6]       ; d
	fld   qword ptr[rdx + 96]     ; l
	fmulp                         ; dl
	faddp                         ; ck + dl
	fstp  qword ptr[r8 + 72]      ; ���������� ���������


	dec rcx
	cmp rcx, 0
	je end_loop_rev
	add rdx, 8                    ; ����� � src �� ���� ������� real8
	add r8, 16                    ; ����� � dst �� ��� �������� real8, �� �� �������� ��� �������� �������
	jmp start_loop_rev
end_loop_rev:


    sub rax, 128                  ; ����� ��� ���������� ������� ����, � ����� �������������� 32 ���� �� ������������ ���������
	                              ; ��� ����� ������������ ������� ��������� ������� � ������� ����,
	                              ; � ����� ��������� �� ������ ���������� ����������, ������� ���� �������� �� 264 ���� 
	sub rsp, 128
    
	;----------------------������ �������: ��� ����� ������ ������������ ����� -----------------------------

	 lea rbx, forthroots
	 vbroadcastf128 ymm0, xmmword ptr [rax + 128]         ;      ������������ ����� ������ ���������
	 vbroadcastf128 ymm1, xmmword ptr [rax + 160]         ;      ������������ ����� ������ ���������
	 vbroadcastf128 ymm2, xmmword ptr [rax + 224]         ;      ����������� ����� ������ ���������
	 vmovdqa        ymm3, ymmword ptr [rbx]               ;      ������������ ����� ������ 
	 vmovdqa        ymm4, ymmword ptr [rbx + 32]          ;      ����������� ����� ������
	 vmulpd         ymm1, ymm1, ymm3                      ;      ������������ ������� �������� �� ������������ �����
	 vmulpd         ymm2, ymm2, ymm4                      ;      ����������� ������� �������� �� ����������� ����� 
	 vaddpd         ymm0, ymm0, ymm1                      ;
	 vaddpd         ymm0, ymm0, ymm2                      ;      ���� ����� �� i^2 = -1, � ���� ����� �� ������������ ���������� �����
	                                                      ;      �������� ����� ������������ �����, ���������� �� � ������.

     vmovapd  ymmword ptr [rax], ymm0                     ;      ���������� � ������
	 

;----------------------������ �������: ��� ����� ������������ � ����������� ����� -----------------------------
;--------------������������ �����------------------------------------------------------------------------------

     vbroadcastf128 ymm0, xmmword ptr [rax + 144]         ;      ������������ ����� ������ ���������
	 vbroadcastf128 ymm1, xmmword ptr [rax + 176]         ;      ������������ ����� ������ ���������
	 vbroadcastf128 ymm2, xmmword ptr [rax + 240]         ;      ����������� ����� ������ ���������
	 vmovdqa        ymm3, ymmword ptr [rbx]               ;      ������������ ����� ������ 
	 vmovdqa        ymm4, ymmword ptr [rbx + 32]          ;      ����������� ����� ������
	 vmulpd         ymm1, ymm1, ymm3                      ;      ������������ ������� �������� �� ������������ �����
	 vmulpd         ymm2, ymm2, ymm4                      ;      ����������� ������� �������� �� ����������� ����� 
	 vaddpd         ymm0, ymm0, ymm1                      ;
	 vaddpd         ymm0, ymm0, ymm2                      ;      ���� ����� �� i^2 = -1, � ���� ����� �� ������������ ���������� �����
	                                                      ;      �������� ����� ������������ �����, ���������� �� � ������.
     vmovapd  ymmword ptr [rax + 32], ymm0                ;      ���������� � ������

;-------------����������� �����---------------------------------------------------------------------------------


	 vbroadcastf128 ymm0, xmmword ptr [rax + 176]         ;      ������������ ����� ������ ���������
	 vbroadcastf128 ymm1, xmmword ptr [rax + 240]         ;      ����������� ����� ������ ���������

	 vmulpd         ymm0, ymm0, ymm4                      ;      ������������ ������ �� ����������� ������
	 vmulpd         ymm1, ymm1, ymm3                      ;      ����������� ������ �� ������������ ������
	 vsubpd         ymm0, ymm1, ymm0                      ;      ����� ��-�� ������������ ���������� �����

	 vbroadcastf128 ymm1, xmmword ptr [rax + 208]         ;      ����������� ����� ������ ���������
	 vaddpd         ymm0, ymm1, ymm0                      ;      ���������� � ����������� ������ ������ ���������

     vmovapd  ymmword ptr [rax + 96], ymm0                ;      ���������� � ������


;-----------------------------������� �������, ������� ������ ������������ �����---------------------------------
	lea            rbx , roots

	vmovdqa        ymm0, ymmword ptr [rax]               ;      ������������ ������ ���������
	vmovdqa        ymm1, ymmword ptr [rax + 32]          ;      ������������ ������
	vmovdqa        ymm2, ymmword ptr [rbx]               ;      ������������ ������ 
	vmulpd         ymm1, ymm1, ymm2                      ;      ������������ ������ �� ������������ ������
	vaddpd         ymm0, ymm0, ymm1                      ;      ���������� � ������������ ������ ������ ���������

	vmovdqa        ymm1, ymmword ptr [rax + 96]          ;      ����������� ������
	vmovdqa        ymm2, ymmword ptr [rbx + 64]          ;      ����������� ������
	vmulpd         ymm1, ymm1, ymm2                      ;      ����������� ������ �� ����������� ������
	vaddpd         ymm0, ymm0, ymm1                      ;      ����������, �� � ������������ ����������� ������ i^2 = -1, � ����� ������ ��������
	 
	vmovdqa        ymmword ptr [rax + 128], ymm0         ;      ���������� � ������

	vmovdqa        ymm0, ymmword ptr [rax]               ;      ������������ ������ ���������
	vmovdqa        ymm1, ymmword ptr [rax + 32]          ;      ������������ ������
	vmovdqa        ymm2, ymmword ptr [rbx + 32]          ;      ������������ ������, ������� � 5-�� �����
	vmulpd         ymm1, ymm1, ymm2                      ;      ������������ ������ �� ������������ ������
	vaddpd         ymm0, ymm0, ymm1                      ;      ���������� � ������������ ������ ������ ���������

	vmovdqa        ymm1, ymmword ptr [rax + 96]          ;      ����������� ������
	vmovdqa        ymm2, ymmword ptr [rbx + 96]          ;      ����������� ������, ������� � 5-�� �����
	vmulpd         ymm1, ymm1, ymm2                      ;      ����������� ������ �� ����������� ������
	vaddpd         ymm0, ymm0, ymm1                      ;      ����������, �� � ������������ ����������� ������ i^2 = -1, � ����� ������ ��������
	
	vmovdqa        ymmword ptr [rax + 160], ymm0         ;      ���������� � ������


;----------------------------�������������� � ������, ��� ����, � ����� ����� �� 8----------------------------------------

	mov rcx, 8                             ;  ���������� ��������
	add rax, 128                           ;  src
	mov r8 , [rsp + 288]                   ;  dst

start_loop_third_rev:      
	    fld  qword ptr [rax]               ; ��������� 64 ������ �����
		fidiv signal_size
	    fistp word ptr [r8]                ; ��������� ���������, ��� ����� 16 ������ �����

		dec rcx

		cmp cx, 0
		je end_loop_third_rev
		add rax, 8                         ; ����� � src �� ���� ������� real8
		add r8 , 2                         ; ����� � dst �� ���� ������� int16
		jmp start_loop_third_rev

end_loop_third_rev:
	
	vzeroall
	add rsp, 296                           ; ������� ����

	ret
RecoverSignal ENDP



MultiplyVectorOnMatrix  PROC   ; [RCX] - beginining of Vector 2x1
							   ; [RDX] - Matrix 2x2
							   ; R9 - Pointer to result array
	;  |a b| (x) = (ax + by)
	;  |c d| (y) = (cx + dy)
	;
	movsx    r10w ,  byte ptr [rdx]                         ; a
	movsx    eax  ,  byte ptr [rcx]                         ; x
	imul     r10w ,  ax                                     ; ax
	movsx    r11w ,  byte ptr [rdx + 2]                     ; b
	movsx    r8w  ,  byte ptr [rcx + 8]                     ; y
	imul     r11w ,  r8w                                    ; by
	add      r10w ,  r11w                                   ; ax + by
	mov      [r9] ,  r10w                                   ; ������ ������� �������� �������

	movsx    r10w ,  byte ptr[rdx + 4]                      ; c
	imul     r10w ,  ax                                     ; cx
	movsx    r11w ,  byte ptr[rdx + 6]                      ; d
	imul     r11w ,  r8w                                    ; dy
	add      r10w ,  r11w                                   ; cx + dy

	mov      [r9 + 2]  ,  r10w                              ; ������ ������� �������� �������
	ret

MultiplyVectorOnMatrix  ENDP
END	 

