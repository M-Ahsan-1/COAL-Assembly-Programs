; COAL Assignment 3 - Q2 - Video Memory 
;GITHUB_REPO: https://github.com/M-Ahsan-1/COAL-Assembly-Programs

[org 0x0100]
jmp start

title_text: db ' TEXT VIEWPORT MANAGER ', 0
keyword: db 'stack', 0
count_text: db 'Total Matches Found: ', 0
status_text: db ' | Viewport Status: ACTIVE', 0
scroll_hint: db 'Press any key to scroll up', 0
exit_hint: db '  |  ESC = Exit', 0

next_line: dw 0

; Zero ends each line. An extra zero ends the document.
text:
db 'Text mode video memory begins at segment 0xB800 and each', 0
db 'character cell uses two bytes: the ASCII code and then an', 0
db 'attribute byte that controls the colour of the cell.', 0
db 'A viewport window keeps its own text inside a border so the', 0
db 'outer frame never gets damaged when the text moves.', 0
db 'To scroll one window we copy every row up with MOVSW and', 0
db 'then blank the freed rows with STOSW. The stack holds all', 0
db 'arguments, and each subroutine builds a stack frame with BP', 0
db 'so that local variables live below BP and parameters live', 0
db 'above it. The stack is cleaned by RET n when the stack', 0
db 'frame is destroyed. A recursive routine may also use the', 0
db 'stack to print a number digit by digit.', 0
db 'String instructions such as LODSB, STOSW, MOVSW and CMPSB', 0
db 'make memory work simple, because SI and DI move on their', 0
db 'own after every step. The direction flag decides if they', 0
db 'move forward or backward through memory.', 0
db 'Searching the screen for a keyword means comparing the text', 0
db 'row by row, then changing only the attribute bytes of a hit.', 0
db 'The word stack is searched and each visible match is marked.', 0
db 'This viewport scrolls independently without damaging the', 0
db 'outer frame, margins, title, or status bar.', 0
db 0

; Reserve a word before the arguments if a result is needed.

; clear_screen(fill)
clear_screen:
	push bp
	mov bp, sp
	sub sp, 2
	push ax
	push cx
	push di
	push es

	mov word [bp-2], 2000
	mov ax, 0xB800
	mov es, ax
	xor di, di
	mov cx, [bp-2]
	mov ax, [bp+4]
	cld
	rep stosw

	pop es
	pop di
	pop cx
	pop ax
	mov sp, bp
	pop bp
	ret 2

; str_len(string), length goes in [bp+6]
str_len:
	push bp
	mov bp, sp
	sub sp, 2
	push ax
	push si

	mov word [bp-2], 0
	mov si, [bp+4]
	cld

length_loop:
	lodsb
	or al, al
	jz length_done
	inc word [bp-2]
	jmp length_loop

length_done:
	mov ax, [bp-2]
	mov [bp+6], ax

	pop si
	pop ax
	mov sp, bp
	pop bp
	ret 2

; print_string(string, screen offset, color)
; Next screen offset goes in [bp+10].
print_string:
	push bp
	mov bp, sp
	push ax
	push si
	push di
	push es

	mov ax, 0xB800
	mov es, ax
	mov si, [bp+8]
	mov di, [bp+6]
	mov ah, [bp+4]
	cld

print_char_loop:
	lodsb
	or al, al
	jz string_done
	stosw
	jmp print_char_loop

string_done:
	mov [bp+10], di

	pop es
	pop di
	pop si
	pop ax
	mov sp, bp
	pop bp
	ret 6

; printNum(number, screen offset, color)
; Next screen offset goes in [bp+10].
printNum:
	push bp
	mov bp, sp
	sub sp, 2
	push ax
	push bx
	push cx
	push dx
	push di
	push es

	mov ax, 0xB800
	mov es, ax
	cld

	mov ax, [bp+8]
	mov di, [bp+6]
	mov bx, 10
	mov word [bp-2], 0

	; Save remainders so the digits print in the right order.
divide_loop:
	xor dx, dx
	div bx
	push dx
	inc word [bp-2]
	test ax, ax
	jnz divide_loop

	mov cx, [bp-2]
	mov ah, [bp+4]

digit_loop:
	pop dx
	add dl, '0'
	mov al, dl
	stosw
	loop digit_loop

	mov [bp+10], di

	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	mov sp, bp
	pop bp
	ret 6

; draw_window(top, left, bottom, right, color)
draw_window:
	push bp
	mov bp, sp
	sub sp, 4
	push ax
	push bx
	push cx
	push dx
	push di
	push es

	mov ax, 0xB800
	mov es, ax
	cld

	mov ax, [bp+6]
	sub ax, [bp+10]
	dec ax
	mov [bp-2], ax

	; Top edge and corners
	mov ax, [bp+12]
	mov bx, 80
	mul bx
	add ax, [bp+10]
	shl ax, 1
	mov di, ax
	mov ah, [bp+4]

	mov al, 0xC9
	stosw
	mov al, 0xCD
	mov cx, [bp-2]
	rep stosw
	mov al, 0xBB
	stosw

	mov ax, [bp+12]
	inc ax
	mov [bp-4], ax

side_loop:
	mov ax, [bp-4]
	cmp ax, [bp+8]
	jae bottom_edge

	mov bx, 80
	mul bx
	add ax, [bp+10]
	shl ax, 1
	mov di, ax
	mov ah, [bp+4]
	mov al, 0xBA
	stosw

	mov ax, [bp-4]
	mov bx, 80
	mul bx
	add ax, [bp+6]
	shl ax, 1
	mov di, ax
	mov ah, [bp+4]
	mov al, 0xBA
	stosw

	inc word [bp-4]
	jmp side_loop

bottom_edge:
	mov ax, [bp+8]
	mov bx, 80
	mul bx
	add ax, [bp+10]
	shl ax, 1
	mov di, ax
	mov ah, [bp+4]

	mov al, 0xC8
	stosw
	mov al, 0xCD
	mov cx, [bp-2]
	rep stosw
	mov al, 0xBC
	stosw

	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	mov sp, bp
	pop bp
	ret 10

; draw_title(string, row, left, right, color)
draw_title:
	push bp
	mov bp, sp
	sub sp, 4
	push ax
	push bx
	push dx

	sub sp, 2
	push word [bp+12]
	call str_len
	pop ax
	mov [bp-2], ax

	; Split the spare width between both sides.
	mov ax, [bp+6]
	sub ax, [bp+8]
	inc ax
	sub ax, [bp-2]
	shr ax, 1
	add ax, [bp+8]
	mov bx, ax

	mov ax, [bp+10]
	mov dx, 80
	mul dx
	add ax, bx
	shl ax, 1
	mov [bp-4], ax

	sub sp, 2
	push word [bp+12]
	push word [bp-4]
	push word [bp+4]
	call print_string
	add sp, 2

	pop dx
	pop bx
	pop ax
	mov sp, bp
	pop bp
	ret 10

; stream_text(pointer, top, left, right, bottom)
; Next unread line goes in [bp+14].
stream_text:
	push bp
	mov bp, sp
	sub sp, 4
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push es

	mov ax, 0xB800
	mov es, ax
	cld

	mov si, [bp+12]
	mov ax, [bp+10]
	mov [bp-2], ax

	mov ax, [bp+6]
	sub ax, [bp+8]
	inc ax
	mov [bp-4], ax

line_loop:
	mov ax, [bp-2]
	cmp ax, [bp+4]
	ja stream_done

	cmp byte [si], 0
	je stream_done

	mov ax, [bp-2]
	mov bx, 80
	mul bx
	add ax, [bp+8]
	shl ax, 1
	mov di, ax

	mov cx, [bp-4]
	mov ah, 0x07

text_char_loop:
	lodsb
	or al, al
	jz next_text_row

	; Keep reading a long line, but stop writing at the margin.
	jcxz text_char_loop
	stosw
	dec cx
	jmp text_char_loop

next_text_row:
	inc word [bp-2]
	jmp line_loop

stream_done:
	mov [bp+14], si

	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	mov sp, bp
	pop bp
	ret 10

; scroll_window_up(top, left, bottom, right, lines)
scroll_window_up:
	push bp
	mov bp, sp
	sub sp, 10
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push ds
	push es

	cld
	mov ax, 0xB800
	mov es, ax
	mov ds, ax

	; Width and height of the text area only
	mov ax, [bp+6]
	sub ax, [bp+10]
	sub ax, 3
	mov [bp-2], ax

	mov ax, [bp+8]
	sub ax, [bp+12]
	sub ax, 2

	mov bx, [bp+4]
	test bx, bx
	jns limit_scroll
	xor bx, bx

limit_scroll:
	cmp bx, ax
	jbe scroll_ready
	mov bx, ax

scroll_ready:
	mov [bp-10], bx
	sub ax, bx
	mov [bp-4], ax

	; First destination cell
	mov ax, [bp+12]
	add ax, 2
	mov bx, 80
	mul bx

	mov bx, [bp+10]
	add bx, 2
	add ax, bx
	shl ax, 1
	mov [bp-6], ax

	; Source starts the requested number of rows below it.
	mov ax, [bp-10]
	mov bx, 160
	mul bx
	add ax, [bp-6]
	mov [bp-8], ax

	mov dx, [bp-4]
	test dx, dx
	jz blank_rows

copy_row_loop:
	mov si, [bp-8]
	mov di, [bp-6]
	mov cx, [bp-2]
	rep movsw

	add word [bp-8], 160
	add word [bp-6], 160
	dec dx
	jnz copy_row_loop

blank_rows:
	mov dx, [bp-10]
	test dx, dx
	jz scroll_done

blank_row_loop:
	mov di, [bp-6]
	mov cx, [bp-2]
	mov ax, 0x0720
	rep stosw

	add word [bp-6], 160
	dec dx
	jnz blank_row_loop

scroll_done:
	pop es
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	mov sp, bp
	pop bp
	ret 10

; find_and_highlight(keyword, color, top, left, bottom, right)
; Match count goes in [bp+16].
find_and_highlight:
	push bp
	mov bp, sp
	sub sp, 94
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push ds
	push es

	cld
	mov word [bp-4], 0

	sub sp, 2
	push word [bp+14]
	call str_len
	pop ax
	mov [bp-2], ax

	test ax, ax
	jnz check_keyword
	jmp search_done

check_keyword:
	mov ax, [bp+4]
	sub ax, [bp+8]
	sub ax, 3
	mov [bp-8], ax

	sub ax, [bp-2]
	mov [bp-14], ax
	jns first_search_row
	jmp search_done

first_search_row:
	mov ax, [bp+10]
	add ax, 2
	mov [bp-6], ax

search_row_loop:
	mov ax, [bp-6]
	cmp ax, [bp+6]
	jb prepare_row
	jmp search_done

prepare_row:
	mov ax, [bp-6]
	mov bx, 80
	mul bx

	mov bx, [bp+8]
	add bx, 2
	add ax, bx
	shl ax, 1
	mov [bp-10], ax

	mov si, [bp-10]
	mov ax, 0xB800
	mov ds, ax
	mov ax, ss
	mov es, ax

	lea di, [bp-94]
	mov cx, [bp-8]

	; Put just the characters into the local row buffer.
copy_letters_loop:
	lodsw
	stosb
	loop copy_letters_loop

	push cs
	pop ds
	mov word [bp-12], 0

search_pos_loop:
	mov ax, [bp-12]
	cmp ax, [bp-14]
	ja next_search_row

	lea di, [bp-94]
	add di, [bp-12]
	mov si, [bp+14]
	mov cx, [bp-2]
	repe cmpsb
	jne next_search_pos

	inc word [bp-4]

	mov di, [bp-12]
	shl di, 1
	add di, [bp-10]
	inc di

	mov cx, [bp-2]
	mov al, [bp+12]

	push es
	mov dx, 0xB800
	mov es, dx

	; Paint the attributes and leave the letters alone.
highlight_loop:
	stosb
	inc di
	loop highlight_loop

	pop es
	inc word [bp-12]
	jmp search_pos_loop

next_search_pos:
	inc word [bp-12]
	jmp search_pos_loop

next_search_row:
	inc word [bp-6]
	jmp search_row_loop

search_done:
	mov ax, [bp-4]
	mov [bp+16], ax

	pop es
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	mov sp, bp
	pop bp
	ret 12

; show_status(count)
show_status:
	push bp
	mov bp, sp
	sub sp, 2
	push ax
	push cx
	push di
	push es

	; Wipe row 23 so shorter counts leave nothing behind.
	mov ax, 0xB800
	mov es, ax
	mov di, 3680
	mov cx, 80
	mov ax, 0x0720
	cld
	rep stosw

	mov word [bp-2], 3696

	sub sp, 2
	mov ax, count_text
	push ax
	push word [bp-2]
	mov ax, 0x0A
	push ax
	call print_string
	pop ax
	mov [bp-2], ax

	sub sp, 2
	push word [bp+4]
	push word [bp-2]
	mov ax, 0x0A
	push ax
	call printNum
	pop ax
	mov [bp-2], ax

	sub sp, 2
	mov ax, status_text
	push ax
	push word [bp-2]
	mov ax, 0x0A
	push ax
	call print_string
	add sp, 2

	pop es
	pop di
	pop cx
	pop ax
	mov sp, bp
	pop bp
	ret 2

start:
	push cs
	pop ds

	mov ax, 0x0720
	push ax
	call clear_screen

	mov ax, 3
	push ax
	mov ax, 8
	push ax
	mov ax, 21
	push ax
	mov ax, 72
	push ax
	mov ax, 0x0B
	push ax
	call draw_window

	mov ax, title_text
	push ax
	mov ax, 4
	push ax
	mov ax, 9
	push ax
	mov ax, 71
	push ax
	mov ax, 0x1E
	push ax
	call draw_title

	; Load the first page.
	sub sp, 2
	mov ax, text
	push ax
	mov ax, 5
	push ax
	mov ax, 10
	push ax
	mov ax, 70
	push ax
	mov ax, 20
	push ax
	call stream_text
	pop ax
	mov [next_line], ax

	sub sp, 2
	mov ax, keyword
	push ax
	mov ax, 0xCE
	push ax
	mov ax, 3
	push ax
	mov ax, 8
	push ax
	mov ax, 21
	push ax
	mov ax, 72
	push ax
	call find_and_highlight
	pop ax

	push ax
	call show_status

	; Scroll hint in cyan on row 24.
	sub sp, 2
	mov ax, scroll_hint
	push ax
	mov ax, 3856
	push ax
	mov ax, 0x0B
	push ax
	call print_string
	pop ax

	; Exit hint in red, after the scroll hint.
	sub sp, 2
	mov bx, exit_hint
	push bx
	push ax
	mov ax, 0x0C
	push ax
	call print_string
	add sp, 2

wait_for_key:
	xor ah, ah
	int 0x16

	cmp al, 27
	jne check_end
	jmp exit_program

check_end:
	mov bx, [next_line]
	cmp byte [bx], 0
	jne do_scroll
	jmp exit_program

do_scroll:
	mov ax, 3
	push ax
	mov ax, 8
	push ax
	mov ax, 21
	push ax
	mov ax, 72
	push ax
	mov ax, 2
	push ax
	call scroll_window_up

	; Fill the two rows freed by scrolling.
	sub sp, 2
	push word [next_line]
	mov ax, 19
	push ax
	mov ax, 10
	push ax
	mov ax, 70
	push ax
	mov ax, 20
	push ax
	call stream_text
	pop ax
	mov [next_line], ax

	sub sp, 2
	mov ax, keyword
	push ax
	mov ax, 0xCE
	push ax
	mov ax, 3
	push ax
	mov ax, 8
	push ax
	mov ax, 21
	push ax
	mov ax, 72
	push ax
	call find_and_highlight
	pop ax

	push ax
	call show_status

	jmp wait_for_key

exit_program:
	mov ah, 0x02
	xor bh, bh
	mov dx, 0x1800
	int 0x10

	mov ax, 0x4C00
	int 0x21
