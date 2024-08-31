Seg1 SEGMENT

ASSUME SS:Seg1,DS:Seg1,CS:Seg1,ES:Seg1

ORG 100h ;Начало программы с 0100h

Pr: JMP Main 		;Пропускаем резидентную часть
      old_09 dd 0 		;Старый адрес Int 09h
      video_mode db 0	;Сохранение видео режима
      tmp dw 0
	  Food dw 0
	  mode dw 186 
	  motion dw 0
	  counter dw 0
	  rand dw 1
	  temp dw 0
	  
proc pr_Clear 		;процедура очистки экрана
      mov ah,00h		;Функция 00h
      mov al,video_mode	;Загружаем в al старый видео режим
      int 10h			;Вызываем прерывание 10h
	  mov ax,0300h	;Функция для считывания данных о позиции курсора
      int 10h			;Прерывание функций видео режимаs
ret
pr_Clear endp 		;конец процедуры

proc Show_Counter 
	push ax
	push dx
	push bx
	push cx
	
	mov ax, counter
	mov bx, 10
	mov cx,0
	L:  mov dx, 0
		div BX
		inc CX
		push DX
		cmp AX, 0
	jnz L
	
	mov bx,0
	bgn: pop dx
		 mov dh,00001111b
		 add dx,30h
		 mov es:word ptr[bx],dx
		 add bx,2
	loop bgn

	pop dx
	mov cx, dx
	
	pop bx
	pop dx
	pop ax
	ret
endp Show_Counter

proc Generate_Food
	push ax
	push bx
	push dx
	
	mov AH,00001111b;Ярко-белые буквы на черном фоне
	mov al, 'H'
	mov es:word ptr[160],ax
	mov es:word ptr[318],ax

AGAIN:
	mov ax,0200h
	INT 1AH
	mov ax,rand

	mov dl,0
	xchg dh,dl
	xchg bx, dx
	mul bx
	xchg bx, dx

	mov bh,0
	mov bl,cl
	add ax,bx
	xchg bx,cx
	add cl,ch
	rcr bx,cl
	xchg cl,ch
	rcr bx,cl
	add ax,bx
	
	mov bx,4000
	div bx
	
	mov rand,dx
	mov bx,dx
	
	shr dx,1
	jnb pnt
	inc bx
	
	pnt:
	cmp es:word ptr[di],ax
	je AGAIN
	mov ax,Food
	mov es:word ptr[bx],ax
	mov tmp,bx
	
	pop dx
	pop bx
	pop ax
	ret 
endp Generate_Food

proc pr_Check

;Уровень сложности
    IN AL,60h		;Смотрим какая клавиша нажата
    CMP AL,02h		;Если 1
jz SIMPLE			;Переходим на блок смены уровня сложности
    IN AL,60h		;Смотрим какая клавиша нажата
    CMP AL,03h		;Клавиша 2
jz MIDDLE
    IN AL,60h		;Смотрим какая клавиша нажата
    CMP AL,04h		;Клавиша 3
jz HARD

;Управление направлением 
DIRECTION:
    IN AL,60h		;Смотрим какая клавиша нажата
    CMP AL,4Dh		;Если стрелочка вправо
jz RIGHT			
    IN AL,60h		;Смотрим какая клавиша нажата
    CMP AL,4Bh		;Стрелочка влево
jz LEFT				
    IN AL,60h		;Смотрим какая клавиша нажата
    CMP AL,48h		;Стрелочка вверх
jz UP				
	IN AL,60h		;Смотрим какая клавиша нажата
	CMP AL,50h		;Стрелочка вниз
jz DOWN				
	jmp rt

SIMPLE:mov mode,170
	   jmp rt
MIDDLE:mov mode,150
	   jmp rt
HARD:mov mode,135
	 jmp rt
	 
RIGHT:mov motion,2
	  jmp rt
LEFT:mov motion,-2
	 jmp rt
UP:mov motion,-160
   jmp rt
DOWN:mov motion,160
	rt:ret
endp pr_Check 

proc Border_Check
	push ax
	push di

	cmp di,0
	jle LiftDown
	
	cmp di,4000
	jge LiftUp
	
	mov dx,di
	check1:
		sub di,158
	cmp di,158
	jge check1
	
	check2:
		sub bx,158
	cmp bx,158
	jge check2
	
	
	cmp di,0
	jne cmp2
    cmp bx,2
	jne cmp2
	add dx,158
	mov di,dx
	jmp r

cmp2:
	cmp di,2
	jne p
	cmp bx,0
	jne p	
	sub dx,158
	mov di,dx	
	jmp r
	
	LiftDown:
	add bx,4000
	mov di,bx
	jmp r
	
	LiftUp:
	sub bx,4000
	mov di,bx
	jmp r
	
  p:pop di
	jmp r2
  r:pop bx
 r2:pop ax
	ret
endp Border_Check

proc Cycle			;Начало цикла
	mov AX,0B800h	;Загружаем адрес видео буфера
    mov ES,AX		;Переносим его в ES
	mov ax,0003h	;Функция для считывания данных о позиции курсора
    int 10h			;Прерывание функций видео режимаs
	
	mov AH,00001111b;Ярко-белые буквы на черном фоне
	mov al, 'S'
	mov Food,ax
	
    mov AH,00001111b;Ярко-белые буквы на черном фоне
	mov al, '0'
	mov bp,sp
	
	mov mode,170
	add di,366
	call Generate_Food
	mov motion,2
	mov bx,0
	mov cx,1
	
beg:
	mov bx,motion
	mov dx,es:word ptr[di+bx]
	xor dx,ax
	cmp dx,0
	jz CLEAR
	;mov dx,es:word ptr[di]
	cmp tmp,di
	jnz CONTINUE	
	;Ноль добавляется в промежуток между появляющимся нулем и предыдущими
		add counter,1
		call Show_Counter
		call Generate_Food
		add di,motion
		mov es:word ptr[di],ax
		lea bx,es:word ptr[di]
	    push bx
CONTINUE: 
	mov bx,di
	add di,motion	
    call Border_Check
	
	mov es:word ptr[di],ax
	lea bx,es:word ptr[di]
	push bx
	
	mov bx,ss:word ptr[bp]
	mov es:word ptr[bx],0
	sub bp,2 
	
	;Пауза и проверка на нажатие
	mov dx,mode
		push ax
			mov si,50
			mov cx,00fffh
			lp2:
			call pr_Check
			IN AL,60h		;Смотрим какая клавиша нажата
			CMP AL,01h		;Если Esc
			jz CLEAR		;Переходим на блок очистки экрана и выхода
				cmp si, 0
				jne sb
				add cx,dx
				mov si,200
				sb: dec si
			loop lp2
		pop ax
    jmp beg
	ret
endp Cycle

int9:
pushF					;Сохраняем в стек флаги
    call CS:old_09			;Вызываем старое прерывание int 09h
    push AX				;Сохраняем в стек
    push BX				;значения регистров
    push ES				;AX, BX и ES

    IN AL,60h			;Смотрим, какая кнопка нажата по адресу 60h
    CMP AL,20h			;Если это не буква D,
jnz Exit				;то переходим в конец резидентной части, иначе

    MOV AX,40h			;Смотрим на параметры клавиатуры
    mov ES,AX
    MOV AL,byte ptr es:[17h]	;по адресу 17h (первый байт параметров клавиатуры)
    test AL,08h			;Если 4 бит равен 0, то переходим в конец рез. части,
jz Exit				;иначе продолжаем
;call pr_Buffer		;Вызываем процедуру вывода дампа на экран

call Cycle
	
Exit:
      pop ES 	;Восстановим содержимое
      pop BX 	;регистров ES, BX и AX
      pop AX
iret	;Возврат в восстановлением флагов

CLEAR:
    call pr_Clear
	jmp Exit			;Прыжок в конец резидентной части
	
Main: ;---------------------- ;Инициирующая часть
	  
	  mov AH,0Fh			;Функция 0Fh для получения видео режима
      int 10h				;Прерывание 10h
	  mov video_mode,AL 	;Сохраняем его в переменную
	  
      mov AX,3509h 			;Получить в ES:BX старый адрес
      INT 21h 				;обработчика прерывания int 09hn
      
	  mov word ptr old_09,BX 		;и запомнить его
      mov word ptr old_09+2,ES 		;в ячейке old_09

      mov AX,2509h 			;Установка нового адреса <адр.int9>
      mov DX,offset int9			;обработчика прерывания int 09h
      INT 21h

      mov AH,09h		;Вывод строки:
      lea DX,x 		;'Резидентный обработчик загружен$'
      INT 21h
	  
mov AX,3100h			;Завершить и оставить резидентной
mov DX,(Main-Pr+10Fh)/16 	;часть размером (Main-Pr+10Fh)/16
INT 21h

x db 'hanlder is loaded$'

Seg1 ENDS ;Конец сегмента

END Pr 	;Полный конец программы Pr