; -------------------------------------------------------------------------------------	;
;	Лабораторная работа №n по курсу Программирование на языке ассемблера				;
;	Вариант №1.8.																		;
;	Выполнил студент Максименко Дмитрий Сергеевич.										;
;																						;
;	Исходный модуль LabAssignment.asm													;
;	Содержит функции на языке ассемблера, разработанные в соответствии с заданием		;
; -------------------------------------------------------------------------------------	;
;	Задание: Реализовать прямое и обратное преобразования Фурье
;	Формат данных сигнала: __int16
;	Формат данных спектра: double
;	Размер (количество отсчетов) сигнала и спектра: 8
;	Способ реализации: DFT 2x2 + 2 бабочки
;	Отсчеты спектра являются комплексными числами. Причем действительные части хранятся
;	в первой половине массива, а мнимые - во второй

.DATA
;   Корни 8 степени из 1
    roots  real8  1., 0.70710678 , 0. , -0.70710678, -1., -0.70710678, 0., 0.70710678,                  ; вещественный части
			      0., -0.70710678, -1., -0.70710678,  0., 0.70710678 , 1., 0.70710678                   ; мнимые части
;   Матрица преобразования, она же для обратного
	matrix       dw 1, 1, 1, -1
;   Количество отсчтеов сигнала
	signal_size  dw 8


.CODE
; -------------------------------------------------------------------------------------	;
; void CalculateSpectrum(spectrum_type* Spectrum, signal_type* Signal)					;
;	Прямое преобразование Фурье. Вычисляет спектр Spectrum по сигналу Signal			;
;	Типы данных spectrum_type и signal_type, а так же разимер сигнала					;
;	определяются в файле Tuning.h														;
; -------------------------------------------------------------------------------------	;
CalculateSpectrum PROC	; [RCX] - Spectrum
						; [RDX] - Signal

    push rcx
	sub rsp, 16              ; место для хранения результата первого шага
	push rdx

	;*************      умножаем вектора на матрицу     ***************
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

	add rsp, 8    ; убираем из стека указатель на сигнал, тк все необходимые значения в массиве first_step_res
	              ; теперь стек содержит результат первого шага и dst 
	finit

	sub rsp, 128  ; освобождаем место для результата второго шага

	;**************        Первая бабочка            ************
	mov rcx, 4                        ;  количество повторов
	mov rax,  rsp                     ;  src
	add rax,  128                     ;
	lea rbx, roots                    ;  корни 8-ой степени из 1
	mov r8,  rsp                      ;  dst
start_loop_first:      
	    fild word ptr [rax + 8]                                  ;   загружаем вещественную часть o[i]
	    fld  qword ptr [rbx]                                     ;   загружаем вещественную часть корня
	    fmulp                                                    
	    fild  word ptr [rax]                                     ;   загружаем вещественную часть e[i]
	    faddp
		fstp qword ptr [r8]                                      ;   записываем результат в вещественную часть dst

		fld  qword ptr [rbx + 64]                                ;   загружаем мнимую часть, прибавляем 8 элементов по 8 байт
	    fild word ptr [rax + 8]                                  ;   загружаем вещественную часть o[i] 
	    fmulp
  	    fstp qword ptr [r8 + 64]                                 ;   записываем в мнимую часть dst

		dec rcx
		cmp rcx, 2                                               ;   возвращаемся к началу массива, тк нам нужны элементы в порядке 1,2,1,2 
		je return_to_src_start_first
loop_middle_first:
		cmp cx, 0
		je end_loop_first
		add rax, 2                                               ;   src имеет формат int16
		add rbx, 16                                              ;   добавляем две длины корня, тк корни четвертый степени идут через один в корнях восьмой степени
		add r8, 8                                                ;   dst имеет формат real8

		jmp start_loop_first
return_to_src_start_first:
		sub rax, 4                                               ;   уменьшааем указатель на две длины элемента
		jmp loop_middle_first

end_loop_first:




    ;**************          абсолютно аналогично дейсвуем со второй бабочкой       *********

	mov rcx, 4                                                   ;  количество повторов
	mov rax, rsp                                                 ;  src
	add rax, 132                                                 ;  начинаем читать с первого элемента второго вектора. Сдвиг два элемента int 16
	lea rbx, roots                                               ;  корни 8-ой степени из 1
	mov r8,  rsp                                                 ;  dst
	add r8,  32                                                  ;  начинаем запись во вторую половнину вещественной части. Сдвиг - 4 элемента Real8
    start_loop_sec:      
	    fild word ptr [rax + 8]
	    fld  qword ptr [rbx]
	    fmulp
	    fild  word ptr [rax]
	    faddp
	    fstp qword ptr [r8]
	    fild word ptr [rax + 8]
	    fld  qword ptr [rbx + 64]                                 ;   загружаем мнимую часть, прибавляем 8 элементов по 8 байт
	    fmulp
  	    fstp qword ptr [r8 + 64]                                  ;   записываем в мнимую часть результата

		dec rcx
		cmp rcx, 2                                                ;   возвращаемся к началу массива 
		je return_to_start_sec
	    loop_middle_sec:
		cmp cx, 0
		je end_loop_sec
		add rax, 2
		add rbx, 16                                               ;   добавляем две длины корня, тк корни четвертый степени идут через один в корнях восьмой степени
		add r8, 8

		jmp start_loop_sec

	return_to_start_sec:
		sub rax, 4
		jmp loop_middle_sec

	end_loop_sec:



;****************        Большая бабочка          *****************

	mov rcx, 8                                                  ;  количество повторов
	mov rax, rsp                                                ;  src
	lea rbx, roots                                              ;  корни 8-ой степени из 1
	mov r8,  [rsp + 144]                                        ;  dst

start_loop_third:      
	    ;;;;;;;;;;;;;;;;;;;;; вещественная часть  ;;;;;;;;;;;;;;;  вещ первого + вещ второго на вещ корня - компл второго на компл корня
	    fld  qword ptr [rax]              ; веществ первого

		fld  qword ptr [rax + 32]         ; веществ второго
	    fld  qword ptr [rbx]              ; веществ корня
	    fmulp                             ; вещ второго на вещ корня
	    faddp                             ; вещ первого + вещ второго на вещ корня

		fld  qword ptr [rax + 96]         ; компл второго
		fld  qword ptr [rbx + 64]         ; компл корня
		fmulp                             ; компл второго на компл корня
		fsubp st(1), st(0)                ; вещ первого + вещ второго на вещ корня - компл второго на компл корня
	    fstp qword ptr [r8]               ; сохранили результат

		;;;;;;;;;;;;;;;;;;;;;; мнимая часть  ;;;;;;;;;;;;;;;;;;  компл первого + вещ второго на компл корня + компл второго на вещ корня
	    fld  qword ptr [rax + 64]         ; компл первого

		fld  qword ptr [rax + 32]         ; веществ второго
		fld  qword ptr [rbx + 64]         ; компл корня

	    fmulp                             ; вещ второго на компл корня
	    faddp                             ; компл первого + вещ второго на компл корня

		fld  qword ptr [rax + 96]         ; компл второго
	    fld  qword ptr [rbx]              ; веществ корня
		fmulp                             ; компл второго на вещ корня
		faddp                             ; компл первого + вещ второго на компл корня + компл второго на вещ корня
	    fstp qword ptr [r8 + 64]          ; сохранили результат

		dec rcx
		cmp rcx, 4                        ; возвращаемся к началу массива 
		je return_to_start_third
loop_middle_third:
		cmp cx, 0
		je end_loop_third
		add rax, 8                        ; сдвиг в src на один элемент real8
		add rbx, 8                        ; сдвиг в корнях на один элемент real8
		add r8,  8                        ; сдвиг в dst на один элемент real8

		jmp start_loop_third

return_to_start_third:
		sub rax, 32                       ; уменьшаем src на 4 элемента real8
		jmp loop_middle_third

end_loop_third:
	add rsp, 152                          ; очищаем стек


	ret
CalculateSpectrum ENDP
; -------------------------------------------------------------------------------------	;
; void RecoverSignal(signal_type* Signal, spectrum_type* Spectrum)						;
;	Обратное преобразование Фурье. Вычисляет сигнал Signal по спектру Spectrum			;
;	Типы данных spectrum_type и signal_type, а так же размер сигнала					;
;	определяются в файле Tuning.h														;
; -------------------------------------------------------------------------------------	;
RecoverSignal PROC	; [RCX] - Signal
					; [RDX] - Spectrum
	finit

	push rcx
	sub rsp, 128                                ; место для результата первого шага

	;**************         цикл умножения векторов на матрицы            *************
	                                            ;  rdx - src по условию
	mov rcx, 4                                  ;  количество повторов        
	mov r8,  rsp                                ;  dst
	lea r9,  matrix                             ;  матрица, на которую производится умножение

start_loop_rev:
	;  |a b| (x + ki) = (ax + by + aki + bli)
	;  |c d| (y + li) = (cx + dy + cki + dli)
	;
	;;;;;;;;;;;;;;;;;;;;;;;;     вещественная часть первого элемента ответа     ;;;;;;;;;;;;;;;;;;;;;;;;
	fild  word  ptr[r9]           ; a
	fld   qword ptr[rdx]          ; x
	fmulp                         ; ax
	fild  word ptr[r9 + 2]        ; b
	fld   qword ptr[rdx + 32]     ; y
	fmulp                         ; by
	faddp                         ; ax + by
	fstp  qword ptr[r8]           ; записываем результат

	;;;;;;;;;;;;;;;;;;;;;;;      мнимая часть первого элемента ответа         ;;;;;;;;;;;;;;;;;;;;;;;;

	fild  word ptr[r9]            ; a
	fld   qword ptr[rdx + 64]     ; k
	fmulp                         ; ak
	fild  word ptr[r9 + 2]        ; b
	fld   qword ptr[rdx + 96]     ; l
	fmulp                         ; bl
	faddp                         ; ak + bl
	fstp  qword ptr[r8 + 64]      ; записываем результат

	;;;;;;;;;;;вещественная часть второго элемента ответа;;;;;;;;;;;;;;;;;;;;;;;;
	fild  word  ptr[r9 + 4]       ; c
	fld   qword ptr[rdx]          ; x
	fmulp                         ; cx
	fild  word  ptr[r9 + 6]       ; d
	fld   qword ptr[rdx + 32]     ; y
	fmulp                         ; dy
	faddp                         ; cx + dy
	fstp  qword ptr[r8 + 8]       ; записываем результат
	;;;;;;;;;;;мнимая часть второго элемента ответа;;;;;;;;;;;;;;;;;;;;;;;;
	fild  word  ptr[r9 + 4]       ; c
	fld   qword ptr[rdx + 64]     ; k
	fmulp                         ; ck
	fild  word  ptr[r9 + 6]       ; d
	fld   qword ptr[rdx + 96]     ; l
	fmulp                         ; dl
	faddp                         ; ck + dl
	fstp  qword ptr[r8 + 72]      ; записываем результат


	dec rcx
	cmp rcx, 0
	je end_loop_rev
	add rdx, 8                    ; сдвиг в src на один элемент real8
	add r8, 16                    ; сдвиг в dst на два элемента real8, тк мы записали два элемента вектора
	jmp start_loop_rev
end_loop_rev:


    sub rsp, 128                  ; место для результата второго шага,
	                              ; нам нужно одновременно хранить результат первого и второго шага,
	                              ; а также указатель на запись финального результата, поэтому стек занимает до 264 байт 

	;********       первая бабочка, считаем только вещественную часть       ************
	mov rcx, 4                                            ;  количество повторов        
	mov r8,  rsp                                          ; dst 
	mov r9,  rsp                                          ; src
	add r9,  128                                          ;
	lea r10, roots                                        ; корни из 1

start_loop_rev_sec:

	fld qword ptr [r9]                                    ; вещест часть e[i]
	fld qword ptr [r9 + 32]                               ; вещест часть o[i]
	fld qword ptr [r10]                                   ; вещест часть корня
	fmulp
	faddp
	fld qword ptr [r9 + 96]                               ; комлек часть o[i]
	fld qword ptr [r10 + 64]                              ; комлек часть корня
	fchs                                                  ; осуществляем комлексное сопряжение корня
	fmulp
	fsubp st(1), st(0)                                    ; производим вычитание, тк произведение комплексных частей включает i^2 = -1
	fstp qword ptr [r8]                                   ; записываем результат


	dec rcx
	cmp rcx, 2                                            ; возвращаемся к началу массива 
	je return_to_start_rev_sec
	cmp rcx, 0
	je end_loop_rev_sec
loop_middle_rev_sec:
	add r9,  8                                            ; сдвиг на один элемент real8 в src
	add r8,  8                                            ; сдвиг на один элемент real8 в dst
	add r10, 16                                           ; сдвиг в корнях на два элемента real8, тк корни 4-ой степени идут в корнях 8-о1 степени через один
	jmp start_loop_rev_sec
	
return_to_start_rev_sec:
	sub r9, 16
	jmp loop_middle_rev_sec

end_loop_rev_sec:




	;***************        вторая бабочка, считаем вещественную и комплексную часть       ***************
	mov rcx, 4                                            ;  количество повторов        
	mov r8,  rsp                                          ;  dst
	add r8,  32                                           ;  Сдвиг на 4 элемента, тк пишем во вторую половнину массива
	mov r9,  rsp                                          ;  src
	add r9,  144                                          ;  Сдвиг на 128 - место для ерзультата, и на два элемента по 8, тк пропускаем два элемента первого вектора
	lea r10, roots                                        ;  корни из 1
	
start_loop_rev_th:
    ;;;;;;;;;;;;;;;;;;;;          вещественная часть          ;;;;;;;;;;;;;;;;;;;
	fld qword ptr [r9]                           ; вещественная часть е
	fld qword ptr [r9 + 32]                      ; вещественнаяя часть о
	fld qword ptr [r10]                          ; вещественная часть корня
	fmulp
	faddp
	fld qword ptr [r9 + 96]                      ; комплексная часть е
	fld qword ptr [r10 + 64]                     ; комплексная часть корня
	fchs                                         ; комплексное сопряжение корня 
	fmulp
	fsubp  st(1), st(0)                          ; производим вычиитание, тк i^2 = -1

	fstp qword ptr [r8]                          ; записываем вещественную часть результата
;;;;;;;;;;;;;;;;;;;;;;;;;         комплексная часть            ;;;;;;;;;;;;;;;;;;
	fld qword ptr [r9 + 32]                      ; вещественная часть элемента о
	fld qword ptr [r10 + 64]                     ; комплексная часть корня
	fchs                                         ; комплексное сопряжение корня
	fmulp
	fld qword ptr [r9 + 64]                      ; комплексная часть e
	fld qword ptr [r9 + 96]                      ; комплексная часть o
	fld qword ptr [r10]                          ; вещественная часть корня
	fmulp
	faddp
	faddp

	fstp qword ptr [r8 + 64]                     ; записываем комплексную часть результата


	dec rcx
	cmp rcx, 2                                   ; возвращаемся к началу массива 
	je return_to_start_rev_th
	cmp rcx, 0
	je end_loop_rev_th
loop_middle_rev_th:
	add r9,  8                                   ; сдвиг на один элемент в src
	add r8,  8                                   ; сдвиг на один элемент в dst
	add r10, 16                                  ; сдвиг на два корня, тк корни 4-о1 степени идут через один в корнях 8-ой степени
	jmp start_loop_rev_th
	
return_to_start_rev_th:
	sub r9, 16                                   ; вычитаем два элемента real8 от src
	jmp loop_middle_rev_th

end_loop_rev_th:




	;******************       Большая бабочка, считаем только вещественную часть        ******************

	mov rcx, 8                             ;  количество повторов
	mov rax, rsp                           ;  src
	lea rbx, roots                         ;  корни из 1
	mov r8 , [rsp + 256]                   ;  запись результата

start_loop_third_rev:      
	;;;;;;;;;;;;;;;;;;;;; вещественная часть  ;;;;;;;;;;;;;;;  вещ первого + вещ второго на вещ корня - компл второго на компл корня
	    fld  qword ptr [rax]              ; веществ первого

		fld  qword ptr [rax + 32]         ; веществ второго
	    fld  qword ptr [rbx]              ; веществ корня
	    fmulp                             ; вещ второго на вещ корня
	    faddp                             ; вещ первого + вещ второго на вещ корня

		fld  qword ptr [rax + 96]         ; компл второго
		fld  qword ptr [rbx + 64]         ; компл корня
		fchs
		fmulp                             ; компл второго на компл корня
		fsubp st(1), st(0)                ; вещ первого + вещ второго на вещ корня - компл второго на компл корня
		fidiv signal_size

	    fistp word ptr [r8]               ; сохранили результат

		dec rcx
		cmp rcx, 4                        ; возвращаемся к началу массива
		je return_to_start_third_rev
 loop_middle_third_rev:
		cmp cx, 0
		je end_loop_third_rev
		add rax, 8                        ; сдвиг в src на один элемент real8
		add rbx, 8                        ; сдвиг в корнях на один элемент real8
		add r8 , 2                        ; сдвиг в dst на один элемент int16

		jmp start_loop_third_rev

return_to_start_third_rev:
		sub rax, 32                       ; вычитаем 4 элемента real8
		jmp loop_middle_third_rev

end_loop_third_rev:

	add rsp, 264                           ; очищаем стек

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
	mov      [r9] ,  r10w                                   ; запись первого элемента вектора

	movsx    r10w ,  byte ptr[rdx + 4]                      ; c
	imul     r10w ,  ax                                     ; cx
	movsx    r11w ,  byte ptr[rdx + 6]                      ; d
	imul     r11w ,  r8w                                    ; dy
	add      r10w ,  r11w                                   ; cx + dy

	mov      [r9 + 2]  ,  r10w                              ; запись второго элемента вектора
	ret

MultiplyVectorOnMatrix  ENDP
END	 

