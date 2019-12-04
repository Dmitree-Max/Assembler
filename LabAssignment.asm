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

    push rcx
	sub rsp, 16              ; ����� ��� �������� ���������� ������� ����
	push rdx

	;*************      �������� ������� �� �������     ***************
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov rcx, [rsp]
	lea rdx, matrix
	mov r9, rsp 
	add r9, 8
	call MultiplyVectorOnMatrix
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov rcx, [rsp]
	add rcx, 2
	lea rdx, matrix
	mov r9, rsp 
	add r9, 12
	call MultiplyVectorOnMatrix
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov rcx, [rsp]
	add rcx, 4
	lea rdx, matrix
	mov r9, rsp 
	add r9, 16
	call MultiplyVectorOnMatrix
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov rcx, [rsp]
	add rcx, 6
	lea rdx, matrix
	mov r9, rsp 
	add r9, 20
	call MultiplyVectorOnMatrix
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	add rsp, 8    ; ������� �� ����� ��������� �� ������, �� ��� ����������� �������� � ������� first_step_res
	              ; ������ ���� �������� ��������� ������� ���� � dst 
	finit

	sub rsp, 128  ; ����������� ����� ��� ���������� ������� ����

	;**************        ������ �������            ************
	mov rcx, 4                        ;  ���������� ��������
	mov rax,  rsp                     ;  src
	add rax,  128                     ;
	lea rbx, roots                    ;  ����� 8-�� ������� �� 1
	mov r8,  rsp                      ;  dst
start_loop_first:      
	    fild word ptr [rax + 8]                                  ;   ��������� ������������ ����� o[i]
	    fld  qword ptr [rbx]                                     ;   ��������� ������������ ����� �����
	    fmulp                                                    
	    fild  word ptr [rax]                                     ;   ��������� ������������ ����� e[i]
	    faddp
		fstp qword ptr [r8]                                      ;   ���������� ��������� � ������������ ����� dst

		fld  qword ptr [rbx + 64]                                ;   ��������� ������ �����, ���������� 8 ��������� �� 8 ����
	    fild word ptr [rax + 8]                                  ;   ��������� ������������ ����� o[i] 
	    fmulp
  	    fstp qword ptr [r8 + 64]                                 ;   ���������� � ������ ����� dst

		dec rcx
		cmp rcx, 2                                               ;   ������������ � ������ �������, �� ��� ����� �������� � ������� 1,2,1,2 
		je return_to_src_start_first
loop_middle_first:
		cmp cx, 0
		je end_loop_first
		add rax, 2                                               ;   src ����� ������ int16
		add rbx, 16                                              ;   ��������� ��� ����� �����, �� ����� ��������� ������� ���� ����� ���� � ������ ������� �������
		add r8, 8                                                ;   dst ����� ������ real8

		jmp start_loop_first
return_to_src_start_first:
		sub rax, 4                                               ;   ���������� ��������� �� ��� ����� ��������
		jmp loop_middle_first

end_loop_first:




    ;**************          ��������� ���������� �������� �� ������ ��������       *********

	mov rcx, 4                                                   ;  ���������� ��������
	mov rax, rsp                                                 ;  src
	add rax, 132                                                 ;  �������� ������ � ������� �������� ������� �������. ����� ��� �������� int 16
	lea rbx, roots                                               ;  ����� 8-�� ������� �� 1
	mov r8,  rsp                                                 ;  dst
	add r8,  32                                                  ;  �������� ������ �� ������ ��������� ������������ �����. ����� - 4 �������� Real8
    start_loop_sec:      
	    fild word ptr [rax + 8]
	    fld  qword ptr [rbx]
	    fmulp
	    fild  word ptr [rax]
	    faddp
	    fstp qword ptr [r8]
	    fild word ptr [rax + 8]
	    fld  qword ptr [rbx + 64]                                 ;   ��������� ������ �����, ���������� 8 ��������� �� 8 ����
	    fmulp
  	    fstp qword ptr [r8 + 64]                                  ;   ���������� � ������ ����� ����������

		dec rcx
		cmp rcx, 2                                                ;   ������������ � ������ ������� 
		je return_to_start_sec
	    loop_middle_sec:
		cmp cx, 0
		je end_loop_sec
		add rax, 2
		add rbx, 16                                               ;   ��������� ��� ����� �����, �� ����� ��������� ������� ���� ����� ���� � ������ ������� �������
		add r8, 8

		jmp start_loop_sec

	return_to_start_sec:
		sub rax, 4
		jmp loop_middle_sec

	end_loop_sec:



;****************        ������� �������          *****************

	mov rcx, 8                                                  ;  ���������� ��������
	mov rax, rsp                                                ;  src
	lea rbx, roots                                              ;  ����� 8-�� ������� �� 1
	mov r8,  [rsp + 144]                                        ;  dst

start_loop_third:      
	    ;;;;;;;;;;;;;;;;;;;;; ������������ �����  ;;;;;;;;;;;;;;;  ��� ������� + ��� ������� �� ��� ����� - ����� ������� �� ����� �����
	    fld  qword ptr [rax]              ; ������� �������

		fld  qword ptr [rax + 32]         ; ������� �������
	    fld  qword ptr [rbx]              ; ������� �����
	    fmulp                             ; ��� ������� �� ��� �����
	    faddp                             ; ��� ������� + ��� ������� �� ��� �����

		fld  qword ptr [rax + 96]         ; ����� �������
		fld  qword ptr [rbx + 64]         ; ����� �����
		fmulp                             ; ����� ������� �� ����� �����
		fsubp st(1), st(0)                ; ��� ������� + ��� ������� �� ��� ����� - ����� ������� �� ����� �����
	    fstp qword ptr [r8]               ; ��������� ���������

		;;;;;;;;;;;;;;;;;;;;;; ������ �����  ;;;;;;;;;;;;;;;;;;  ����� ������� + ��� ������� �� ����� ����� + ����� ������� �� ��� �����
	    fld  qword ptr [rax + 64]         ; ����� �������

		fld  qword ptr [rax + 32]         ; ������� �������
		fld  qword ptr [rbx + 64]         ; ����� �����

	    fmulp                             ; ��� ������� �� ����� �����
	    faddp                             ; ����� ������� + ��� ������� �� ����� �����

		fld  qword ptr [rax + 96]         ; ����� �������
	    fld  qword ptr [rbx]              ; ������� �����
		fmulp                             ; ����� ������� �� ��� �����
		faddp                             ; ����� ������� + ��� ������� �� ����� ����� + ����� ������� �� ��� �����
	    fstp qword ptr [r8 + 64]          ; ��������� ���������

		dec rcx
		cmp rcx, 4                        ; ������������ � ������ ������� 
		je return_to_start_third
loop_middle_third:
		cmp cx, 0
		je end_loop_third
		add rax, 8                        ; ����� � src �� ���� ������� real8
		add rbx, 8                        ; ����� � ������ �� ���� ������� real8
		add r8,  8                        ; ����� � dst �� ���� ������� real8

		jmp start_loop_third

return_to_start_third:
		sub rax, 32                       ; ��������� src �� 4 �������� real8
		jmp loop_middle_third

end_loop_third:
	add rsp, 152                          ; ������� ����


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
	sub rsp, 128                                ; ����� ��� ���������� ������� ����

	;**************         ���� ��������� �������� �� �������            *************
	                                            ;  rdx - src �� �������
	mov rcx, 4                                  ;  ���������� ��������        
	mov r8,  rsp                                ;  dst
	lea r9,  matrix                             ;  �������, �� ������� ������������ ���������

start_loop_rev:
	;  |a b| (x + ki) = (ax + by + aki + bli)
	;  |c d| (y + li) = (cx + dy + cki + dli)
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


    sub rsp, 128                  ; ����� ��� ���������� ������� ����,
	                              ; ��� ����� ������������ ������� ��������� ������� � ������� ����,
	                              ; � ����� ��������� �� ������ ���������� ����������, ������� ���� �������� �� 264 ���� 

	;********       ������ �������, ������� ������ ������������ �����       ************
	mov rcx, 4                                            ;  ���������� ��������        
	mov r8,  rsp                                          ; dst 
	mov r9,  rsp                                          ; src
	add r9,  128                                          ;
	lea r10, roots                                        ; ����� �� 1

start_loop_rev_sec:

	fld qword ptr [r9]                                    ; ������ ����� e[i]
	fld qword ptr [r9 + 32]                               ; ������ ����� o[i]
	fld qword ptr [r10]                                   ; ������ ����� �����
	fmulp
	faddp
	fld qword ptr [r9 + 96]                               ; ������ ����� o[i]
	fld qword ptr [r10 + 64]                              ; ������ ����� �����
	fchs                                                  ; ������������ ���������� ���������� �����
	fmulp
	fsubp st(1), st(0)                                    ; ���������� ���������, �� ������������ ����������� ������ �������� i^2 = -1
	fstp qword ptr [r8]                                   ; ���������� ���������


	dec rcx
	cmp rcx, 2                                            ; ������������ � ������ ������� 
	je return_to_start_rev_sec
	cmp rcx, 0
	je end_loop_rev_sec
loop_middle_rev_sec:
	add r9,  8                                            ; ����� �� ���� ������� real8 � src
	add r8,  8                                            ; ����� �� ���� ������� real8 � dst
	add r10, 16                                           ; ����� � ������ �� ��� �������� real8, �� ����� 4-�� ������� ���� � ������ 8-�1 ������� ����� ����
	jmp start_loop_rev_sec
	
return_to_start_rev_sec:
	sub r9, 16
	jmp loop_middle_rev_sec

end_loop_rev_sec:




	;***************        ������ �������, ������� ������������ � ����������� �����       ***************
	mov rcx, 4                                            ;  ���������� ��������        
	mov r8,  rsp                                          ;  dst
	add r8,  32                                           ;  ����� �� 4 ��������, �� ����� �� ������ ��������� �������
	mov r9,  rsp                                          ;  src
	add r9,  144                                          ;  ����� �� 128 - ����� ��� ����������, � �� ��� �������� �� 8, �� ���������� ��� �������� ������� �������
	lea r10, roots                                        ;  ����� �� 1
	
start_loop_rev_th:
    ;;;;;;;;;;;;;;;;;;;;          ������������ �����          ;;;;;;;;;;;;;;;;;;;
	fld qword ptr [r9]                           ; ������������ ����� �
	fld qword ptr [r9 + 32]                      ; ������������� ����� �
	fld qword ptr [r10]                          ; ������������ ����� �����
	fmulp
	faddp
	fld qword ptr [r9 + 96]                      ; ����������� ����� �
	fld qword ptr [r10 + 64]                     ; ����������� ����� �����
	fchs                                         ; ����������� ���������� ����� 
	fmulp
	fsubp  st(1), st(0)                          ; ���������� ����������, �� i^2 = -1

	fstp qword ptr [r8]                          ; ���������� ������������ ����� ����������
;;;;;;;;;;;;;;;;;;;;;;;;;         ����������� �����            ;;;;;;;;;;;;;;;;;;
	fld qword ptr [r9 + 32]                      ; ������������ ����� �������� �
	fld qword ptr [r10 + 64]                     ; ����������� ����� �����
	fchs                                         ; ����������� ���������� �����
	fmulp
	fld qword ptr [r9 + 64]                      ; ����������� ����� e
	fld qword ptr [r9 + 96]                      ; ����������� ����� o
	fld qword ptr [r10]                          ; ������������ ����� �����
	fmulp
	faddp
	faddp

	fstp qword ptr [r8 + 64]                     ; ���������� ����������� ����� ����������


	dec rcx
	cmp rcx, 2                                   ; ������������ � ������ ������� 
	je return_to_start_rev_th
	cmp rcx, 0
	je end_loop_rev_th
loop_middle_rev_th:
	add r9,  8                                   ; ����� �� ���� ������� � src
	add r8,  8                                   ; ����� �� ���� ������� � dst
	add r10, 16                                  ; ����� �� ��� �����, �� ����� 4-�1 ������� ���� ����� ���� � ������ 8-�� �������
	jmp start_loop_rev_th
	
return_to_start_rev_th:
	sub r9, 16                                   ; �������� ��� �������� real8 �� src
	jmp loop_middle_rev_th

end_loop_rev_th:




	;******************       ������� �������, ������� ������ ������������ �����        ******************

	mov rcx, 8                             ;  ���������� ��������
	mov rax, rsp                           ;  src
	lea rbx, roots                         ;  ����� �� 1
	mov r8 , [rsp + 256]                   ;  ������ ����������

start_loop_third_rev:      
	;;;;;;;;;;;;;;;;;;;;; ������������ �����  ;;;;;;;;;;;;;;;  ��� ������� + ��� ������� �� ��� ����� - ����� ������� �� ����� �����
	    fld  qword ptr [rax]              ; ������� �������

		fld  qword ptr [rax + 32]         ; ������� �������
	    fld  qword ptr [rbx]              ; ������� �����
	    fmulp                             ; ��� ������� �� ��� �����
	    faddp                             ; ��� ������� + ��� ������� �� ��� �����

		fld  qword ptr [rax + 96]         ; ����� �������
		fld  qword ptr [rbx + 64]         ; ����� �����
		fchs
		fmulp                             ; ����� ������� �� ����� �����
		fsubp st(1), st(0)                ; ��� ������� + ��� ������� �� ��� ����� - ����� ������� �� ����� �����
		fidiv signal_size

	    fistp word ptr [r8]               ; ��������� ���������

		dec rcx
		cmp rcx, 4                        ; ������������ � ������ �������
		je return_to_start_third_rev
 loop_middle_third_rev:
		cmp cx, 0
		je end_loop_third_rev
		add rax, 8                        ; ����� � src �� ���� ������� real8
		add rbx, 8                        ; ����� � ������ �� ���� ������� real8
		add r8 , 2                        ; ����� � dst �� ���� ������� int16

		jmp start_loop_third_rev

return_to_start_third_rev:
		sub rax, 32                       ; �������� 4 �������� real8
		jmp loop_middle_third_rev

end_loop_third_rev:

	add rsp, 264                           ; ������� ����

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

