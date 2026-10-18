[org 0x0100]
jmp start

title_str: db ' TEXT VIEWPORT MANAGER ', 0
keyword: db 'stack', 0
msg_total: db 'Total Matches Found: ', 0
msg_tail: db ' | Viewport Status: ACTIVE', 0

next_line: dw 0

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

str_len:
	push bp
	mov bp, sp
	sub sp, 2
	push si

	mov word [bp-2], 0
	mov si, [bp+4]
	cld

count_string_characters:
	lodsb
	or al, al
	jz string_length_ready
	inc word [bp-2]
	jmp count_string_characters

string_length_ready:
	mov ax, [bp-2]
	pop si
	mov sp, bp
	pop bp
	ret 2

print_string:
	push bp
	mov bp, sp
	sub sp, 2
	push si
	push di
	push es

	mov ax, 0xB800
	mov es, ax
	mov si, [bp+8]
	mov di, [bp+6]
	mov ah, [bp+4]
	cld

print_next_character:
	lodsb
	or al, al
	jz string_printed
	stosw
	jmp print_next_character

string_printed:
	mov [bp-2], di
	pop es
	pop di
	pop si
	mov ax, [bp-2]
	mov sp, bp
	pop bp
	ret 6

printNum:
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

	mov ax, [bp+8]
	mov di, [bp+6]
	mov bx, 10
	mov word [bp-2], 0

divide_number_into_digits:
	xor dx, dx
	div bx
	push dx
	inc word [bp-2]
	test ax, ax
	jnz divide_number_into_digits

	mov cx, [bp-2]
	mov ah, [bp+4]

print_next_digit:
	pop dx
	add dl, '0'
	mov al, dl
	stosw
	loop print_next_digit

	mov [bp-4], di

	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	mov ax, [bp-4]
	mov sp, bp
	pop bp
	ret 6

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

draw_side_borders:
	mov ax, [bp-4]
	cmp ax, [bp+8]
	jae draw_bottom_border

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
	jmp draw_side_borders

draw_bottom_border:
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

draw_title:
	push bp
	mov bp, sp
	sub sp, 4
	push ax
	push bx
	push dx

	push word [bp+12]
	call str_len
	mov [bp-2], ax

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

	push word [bp+12]
	push word [bp-4]
	push word [bp+4]
	call print_string

	pop dx
	pop bx
	pop ax
	mov sp, bp
	pop bp
	ret 10

stream_text:
	push bp
	mov bp, sp
	sub sp, 6
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

display_next_document_line:
	mov ax, [bp-2]
	cmp ax, [bp+4]
	ja text_streaming_done

	cmp byte [si], 0
	je text_streaming_done

	mov ax, [bp-2]
	mov bx, 80
	mul bx
	add ax, [bp+8]
	shl ax, 1
	mov di, ax

	mov cx, [bp-4]
	mov ah, 0x07

display_next_document_character:
	lodsb
	or al, al
	jz move_to_next_text_row
	jcxz display_next_document_character
	stosw
	dec cx
	jmp display_next_document_character

move_to_next_text_row:
	inc word [bp-2]
	jmp display_next_document_line

text_streaming_done:
	mov [bp-6], si

	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	mov ax, [bp-6]
	mov sp, bp
	pop bp
	ret 10

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

	mov ax, [bp+6]
	sub ax, [bp+10]
	sub ax, 3
	mov [bp-2], ax

	mov ax, [bp+8]
	sub ax, [bp+12]
	sub ax, 2

	mov bx, [bp+4]
	test bx, bx
	jns limit_scroll_to_viewport
	xor bx, bx

limit_scroll_to_viewport:
	cmp bx, ax
	jbe scroll_amount_ready
	mov bx, ax

scroll_amount_ready:
	mov [bp-10], bx
	sub ax, bx
	mov [bp-4], ax

	mov ax, [bp+12]
	add ax, 2
	mov bx, 80
	mul bx

	mov bx, [bp+10]
	add bx, 2
	add ax, bx
	shl ax, 1
	mov [bp-6], ax

	mov ax, [bp-10]
	mov bx, 160
	mul bx
	add ax, [bp-6]
	mov [bp-8], ax

	mov dx, [bp-4]
	test dx, dx
	jz prepare_to_clear_bottom_rows

copy_next_viewport_row:
	mov si, [bp-8]
	mov di, [bp-6]
	mov cx, [bp-2]
	rep movsw

	add word [bp-8], 160
	add word [bp-6], 160
	dec dx
	jnz copy_next_viewport_row

prepare_to_clear_bottom_rows:
	mov dx, [bp-10]
	test dx, dx
	jz scrolling_done

clear_next_bottom_row:
	mov di, [bp-6]
	mov cx, [bp-2]
	mov ax, 0x0720
	rep stosw

	add word [bp-6], 160
	dec dx
	jnz clear_next_bottom_row

scrolling_done:
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

find_and_highlight:
	push bp
	mov bp, sp
	sub sp, 78
	push bx
	push cx
	push dx
	push si
	push di
	push ds
	push es

	cld
	mov word [bp-4], 0

	push word [bp+14]
	call str_len
	mov [bp-2], ax

	test ax, ax
	jnz check_keyword_fits_row
	jmp keyword_search_done

check_keyword_fits_row:
	mov ax, [bp+4]
	sub ax, [bp+8]
	sub ax, 3
	mov [bp-8], ax

	sub ax, [bp-2]
	mov [bp-14], ax
	jns prepare_first_search_row
	jmp keyword_search_done

prepare_first_search_row:
	mov ax, [bp+10]
	add ax, 2
	mov [bp-6], ax

check_search_row_boundary:
	mov ax, [bp-6]
	cmp ax, [bp+6]
	jb prepare_row_for_search
	jmp keyword_search_done

prepare_row_for_search:
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

	lea di, [bp-78]
	mov cx, [bp-8]

copy_row_characters_to_buffer:
	lodsw
	stosb
	loop copy_row_characters_to_buffer

	push cs
	pop ds
	mov word [bp-12], 0

compare_keyword_at_position:
	mov ax, [bp-12]
	cmp ax, [bp-14]
	ja move_to_next_search_row

	lea di, [bp-78]
	add di, [bp-12]
	mov si, [bp+14]
	mov cx, [bp-2]
	repe cmpsb
	jne try_next_search_position

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

highlight_matched_characters:
	stosb
	inc di
	loop highlight_matched_characters

	pop es
	inc word [bp-12]
	jmp compare_keyword_at_position

try_next_search_position:
	inc word [bp-12]
	jmp compare_keyword_at_position

move_to_next_search_row:
	inc word [bp-6]
	jmp check_search_row_boundary

keyword_search_done:
	mov ax, [bp-4]

	pop es
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	mov sp, bp
	pop bp
	ret 12

show_status:
	push bp
	mov bp, sp
	sub sp, 2
	push ax

	mov word [bp-2], 3696

	mov ax, msg_total
	push ax
	push word [bp-2]
	mov ax, 0x0A
	push ax
	call print_string

	mov [bp-2], ax

	push word [bp+4]
	push word [bp-2]
	mov ax, 0x0A
	push ax
	call printNum

	mov [bp-2], ax

	mov ax, msg_tail
	push ax
	push word [bp-2]
	mov ax, 0x0A
	push ax
	call print_string

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

	mov ax, title_str
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
	mov [next_line], ax

wait_for_key:
	xor ah, ah
	int 0x16

	cmp al, 27
	jne check_document_end
	jmp program_exit

check_document_end:
	mov bx, [next_line]
	cmp byte [bx], 0
	jne scroll_and_load_next_lines
	jmp program_exit

scroll_and_load_next_lines:
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
	mov [next_line], ax

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

	push ax
	call show_status

	jmp wait_for_key

program_exit:
	mov ah, 0x02
	xor bh, bh
	mov dx, 0x1800
	int 0x10

	mov ax, 0x4C00
	int 0x21