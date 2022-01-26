IDEAL

MODEL small

STACK 100h

DATASEG

x_points dw 2048 dup(0)
y_points dw 2048 dup(0)
point_info dw 2048 dup(0) ; first byte = color, second byte = mode (0 = doesn't exists, 1 = normal, 2 = highlighted, 3 = selected)
lines db 1024 dup(0)
x_point dw ?
y_point dw ?
color db 15
line_resulution dw 1000
pressed_last_frame db 0
dot_sprite_size db 1
dot_hitbox_size db 4
button_count db 3
button_images dw 48 dup(0)
calculation_variable dw ?

CODESEG

; visual

proc draw_dot
    ; draws a dot at x_point, y_point
    push ax
    push bx
    push cx

    xor ch, ch
    mov cl, [dot_sprite_size]

    mov ax, [x_point]
    add ax, cx
    
    mov bx, [y_point]
    add bx, cx

    sub [x_point], cx
    sub [y_point], cx

go_right:
    call print_point

    inc [x_point]
    cmp [x_point], ax
    jg go_down
    jmp go_right

go_down:
    sub [x_point], cx
    sub [x_point], cx
    dec [x_point]
    inc [y_point]
    cmp [y_point], bx
    jg finish1
    jmp go_right

finish1:
    pop cx
    pop bx
    pop ax
    ret
endp

proc prepare_for_line ; fix the order !
    ; doesn't save registers
    ; sets dx to selected points count
    ; pushes all selected points into stack
    pop bx
    xor dx, dx

    mov ax, 1024
next_point3:
    call get_selected_point
    jnz finish16
    push ax
    inc dx
    jmp next_point3

finish16:
    push bx
    ret
endp

proc draw_bezier_curve
    ; uses indexes in stack, gets count in dx
    ; doesn't save registers

    dec dx
    mov cx, [line_resulution]
    mov [calculation_variable], cx

next_t:
    mov bx, sp

    ; reset n choose i
    mov ax, 1

    mov [x_point], 0
    mov [y_point], 0

    mov cx, dx
    inc cx

    ; cx = i + 1
    ; calculation variable = t * line_resulution
    ; [x_points + bx] = x
    ; [y_points + bx] = y
    ; dx = n
    ; ax = current result
    ; [x_point], [y_point] = result

next_i:
    add bx, 2

    ; save current n choose i
    push ax
    
    ; save for next loop
    push cx
    
    ; calculate x

    ; multiply by P
    push dx
    push bx
    mov bx, [ss:bx]
    add bx, bx
    mul [x_points + bx]
    pop bx
    
    ; multiply by t power i
    dec cx
    push cx
    cmp cx, 0
    jz skip_power

calculate_t_power_i:
    mul [calculation_variable]
    div [line_resulution]
    loop calculate_t_power_i

skip_power:

    ; calculate n-i
    pop cx
    pop dx
    push dx
    sub cx, dx
    neg cx

    push bx

    ; calculate line_resulution-t*line_resulution
    mov bx, [line_resulution]
    sub bx, [calculation_variable]
    
    cmp cx, 0
    jz skip_power1

calculate_1_t_power_n_i:
    mul bx
    div [line_resulution]
    loop calculate_1_t_power_n_i

skip_power1:

    pop bx
    pop dx

    ; add to toatal
    add [x_point], ax

    ; calculate y
    pop cx
    pop ax
    push ax
    push cx

    ; multiply by P
    push dx
    push bx
    mov bx, [ss:bx]
    add bx, bx
    mul [y_points + bx]
    pop bx
    
    ; multiply by t power i
    dec cx
    push cx
    cmp cx, 0
    jz skip_power3

calculate_t_power_i1:
    mul [calculation_variable]
    div [line_resulution]
    loop calculate_t_power_i1

skip_power3:

    ; calculate n-i
    pop cx
    pop dx
    push dx
    sub cx, dx
    neg cx

    push bx

    ; calculate line_resulution-t*line_resulution
    mov bx, [line_resulution]
    sub bx, [calculation_variable]
    
    cmp cx, 0
    jz skip_power4

calculate_1_t_power_n_i1:
    mul bx
    div [line_resulution]
    loop calculate_1_t_power_n_i1

skip_power4:

    pop bx
    pop dx

    ; add to toatal
    add [y_point], ax

    ; calculate next n choose i
    pop cx
    pop ax
    push bx

    dec cx
    mul cl
    inc cx
    mov bx, dx
    add bx, 2
    sub bx, cx
    push dx
    xor dx, dx
    div bx ; ax becomes 0 at the end
    pop dx

    pop bx

    ; loop next
    dec cx
    jz jmp_next_t
    jmp next_i
jmp_next_t:
    call print_point
    dec [calculation_variable]
    jz finish15
    jmp next_t

finish15:
    ret
endp

proc clear_screen
    push ax

    mov ax, 13h
    int 10h

    pop ax
    ret
endp

proc show_mouse
	xor ax, ax
 	int 33h
	mov ax, 1h
	int 33h
	ret
endp

proc get_mouse_info
	; bx = 1 = pressed
	; x_point = X co-ordinate
	; y_point = y co-ordinate
    push ax
    push cx
    push dx

	mov ax, 03h
	int 33h
	shr cx, 1
    mov [x_point], cx
    mov [y_point], dx
    sub [x_point], 1
    sub [y_point], 1
    and bx, 1

    pop dx
    pop cx
    pop ax
	ret
endp

proc get_mouse_press_info
	; bx = 1 = pressed
	; x_point = X co-ordinate
	; y_point = y co-ordinate
    ; only call once per frame
    push ax
    push cx
    push dx

	mov ax, 03h
    int 33h
    shr cx, 1
    mov [x_point], cx
    mov [y_point], dx
    sub [x_point], 2
    sub [y_point], 2

    and bx, 1
    mov al, [pressed_last_frame]
    mov [pressed_last_frame], bl
    not al
    and bl, al

    pop dx
    pop cx
    pop ax
	ret
endp

proc exit_graphic_mode
    xor ah , ah
    mov al, 2
    int 10h
    ret
endp

proc print_point
	; x = x_point
    ; y = y_point
    ; color = color
    push ax
    push bx
    push cx
    push dx

    xor bh, bh 
    mov cx, [x_point]
    mov dx, [y_point]
    mov al, [color] 
    mov ah, 0ch 
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp

proc draw_16x16_image
    ; gets pointer to start in ax
    ; gets top left point in x_point, y_point
    push ax
    push bx
    push cx

    mov bx, ax
    sub bx, 2
    mov ax, 8000h
    add [x_point], 17
    dec [y_point]
    mov cx, 17
    loop go_down3

go_down3:
    add bx, 2
    sub [x_point], 16
    inc [y_point]

    push cx

    mov cx, 17
    loop go_right3

print:
    call print_point

    jmp next2

go_right3:
    test [bx], al
    jnz print

    test [bx + 1], ah
    jnz print

next2:
    ror ax, 1
    inc [x_point]

    loop go_right3

    pop cx
    loop go_down3

    pop cx
    pop bx
    pop ax
    ret
endp

; buttons

proc update_buttons
    ; gets location in x_point, y_point
    ; returns button in ax
    ; ax = 0 = not pressed button
    push bx

    mov ax, 0

    ; check if y_point is in the right location
    cmp [y_point], 16
    ja finish5

    ; check if x_point is in the right location
    mov bx, [x_point]
    shr bx, 4
    inc bx
    cmp bh, 0
    jnz finish5
    cmp bl, [button_count]
    ja finish5

    mov al, [button_count]
    inc al
    sub al, bl

finish5:
    pop bx
    ret
endp

proc draw_buttons
    push ax
    push bx
    mov bx, ax
    push cx
    mov al, [color]
    push ax
    push [x_point]
    push [y_point]

    mov [x_point], 0
    mov [y_point], 0
    mov ax, offset button_images
    xor ch, ch
    mov cl, [button_count]
    jmp draw_next1

draw_next1:
    cmp cl, bl
    jz draw_highlighted

    jmp draw_normal

draw_normal:
    mov [color], 15
    call draw_16x16_image
    add ax, 32
    mov [y_point], 0
    loop draw_next1
    jmp finish4

draw_highlighted:
    mov [color], 11
    call draw_16x16_image
    add ax, 32
    mov [y_point], 0
    loop draw_next1
    jmp finish4

finish4:
    pop [y_point]
    pop [x_point]
    pop ax
    mov [color], al
    pop cx
    pop bx
    pop ax
    ret
endp

; points

proc clear_selected_points
    ; zf = 1 = reset at least one point
    push ax
    push bx
    push cx
    push dx

    xor dx, dx
    mov cx, 1024
    jmp next_point1

reset_point:
    mov ah, 1
    mov [point_info + bx], ax
    mov dx, 1
    loop next_point1
    jmp finish3

next_point1:
    mov bx, cx
    dec bx
    add bx, bx
    mov ax, [point_info + bx]
    cmp ah, 3
    jz reset_point
    loop next_point1
    jmp finish3

finish3:
    cmp dx, 1
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp

proc clear_highlighted_point
    push ax
    push bx
    push cx

    mov cx, 1024
    jmp next_point2

reset_point1:
    mov ah, 1
    mov [point_info + bx], ax
    jmp finish9

next_point2:
    mov bx, cx
    dec bx
    add bx, bx
    mov ax, [point_info + bx]
    cmp ah, 2
    jz reset_point1
    loop next_point2
    jmp finish9

finish9:
    pop cx
    pop bx
    pop ax
    ret
endp

proc get_point_at_location
    ; gets location in x_point, y_point
    ; zf = 1 = pressed a point
    ; returns in ax the index of the point if there is one
    push bx
    push cx
    push dx

    ; reset
    mov cx, 1024
    jmp next_point

next_point:
    ; check if pressing the point
    mov bx, cx
    dec bx
    add bx, bx
    
    mov ax, [point_info + bx]
    cmp ah, 0
    jz loop_next

    ; check x
    xor ah, ah
    mov al, [dot_hitbox_size]
    add ax, [x_points + bx]
    cmp [x_point], ax
    ja loop_next

    xor ah, ah
    mov al, [dot_hitbox_size]
    add ax, [x_point]
    cmp [x_points + bx], ax
    ja loop_next

    ; check y
    xor ah, ah
    mov al, [dot_hitbox_size]
    add ax, [y_points + bx]
    cmp [y_point], ax
    ja loop_next

    xor ah, ah
    mov al, [dot_hitbox_size]
    add ax, [y_point]
    cmp [y_points + bx], ax
    ja loop_next

    ; finish
    mov ax, cx
    dec ax

    call toggle_zf_on
    
    pop dx
    pop cx
    pop bx
    ret

loop_next:
    loop next_point
    
    call toggle_zf_off

    pop dx
    pop cx
    pop bx
    ret
endp

proc save_point
    ; creates at (x_point, y_point)
    ; gets color in [color]
    push ax
    push bx
    push cx

    ; reset
    mov cx, 1024
    jmp find_space

    ; find empty space in list
find_space:
    mov bx, cx
    dec bx
    add bx, bx

    ; check if empty
    mov ax, [point_info + bx]
    cmp ah, 0
    jnz next1

    ; replace info
    mov al, [color]
    mov ah, 1
    mov [point_info + bx], ax

    ; replace x
    mov ax, [x_point]
    mov [x_points + bx], ax

    ; replace y
    mov ax, [y_point]
    mov [y_points + bx], ax

    jmp finish8

next1:
    loop find_space

finish8:
    pop cx
    pop bx
    pop ax
    ret
endp

proc draw_saved_points
    push ax
    mov al, [color]
    push ax
    push bx
    push cx

    ; start
    mov cx, 1024
    jmp find_next

find_next:
    ; check if exists
    mov bx, cx
    dec bx
    add bx, bx

    mov ax, [point_info + bx]
    cmp ah, 1
    jz draw_normal1
    cmp ah, 2
    jz draw_highlighted1
    cmp ah, 3
    jz draw_selected1
    
    loop find_next
    jmp finish

draw_normal1:
    mov [color], al
    mov ax, [x_points + bx]
    mov [x_point], ax
    mov ax, [y_points + bx]
    mov [y_point], ax
    call draw_dot

    loop find_next
    jmp finish

draw_selected1:
    mov ax, [x_points + bx]
    mov [x_point], ax
    mov ax, [y_points + bx]
    mov [y_point], ax
    mov [color], 12
    call draw_dot

    loop find_next
    jmp finish

draw_highlighted1:
    mov ax, [x_points + bx]
    mov [x_point], ax
    mov ax, [y_points + bx]
    mov [y_point], ax
    mov [color], 11
    call draw_dot

    loop find_next
    jmp finish

finish:
    pop cx
    pop bx
    pop ax
    mov [color], al
    pop ax
    ret
endp

proc get_selected_point
    ; gets starting search location in ax
    ; returns point index in ax
    ; zf = 1 = found point
    push bx
    push cx

    mov cx, ax

check_next_point:
    mov bx, cx
    dec bx
    add bx, bx

    mov ax, [point_info + bx]
    cmp ah, 3
    jz found_point

    loop check_next_point

    mov ax, cx
    dec ax
    call toggle_zf_off
    pop cx
    pop bx
    ret

found_point:
    mov ax, cx
    dec ax
    call toggle_zf_on
    pop cx
    pop bx
    ret
endp

proc move_selected_points
    ; gets distance in cx = x, dx = y
    push ax
    push bx

    mov ax, 1024

move_next:
    ; find next
    call get_selected_point
    jnz finish11

    ; move point
    mov bx, ax
    add bx, ax
    add [x_points + bx], cx
    add [y_points + bx], dx

    ; repeat
    jmp move_next

finish11:
    pop bx
    pop ax
    ret
endp

proc hide_selected_points
    push ax
    mov al, [color]
    push ax
    push bx
    push cx

    mov [color], 0
    mov ax, 1024

delete_next:
    ; find next
    call get_selected_point
    jnz finish12

    ; delete point
    mov bx, ax
    add bx, ax
    mov cx, [x_points + bx]
    mov [x_point], cx
    mov cx, [y_points + bx]
    mov [y_point], cx
    call draw_dot

    ; repeat
    jmp delete_next

finish12:
    pop cx
    pop bx
    pop ax
    mov [color], al
    pop ax
    ret
endp

proc delete_selected_points
    push ax
    push bx
    push cx

    mov ax, 1024

delete_next1:
    ; find next
    call get_selected_point
    jnz finish13

    ; delete point
    mov bx, ax
    add bx, ax
    mov [point_info + bx], 0

    ; repeat
    jmp delete_next1

finish13:
    pop cx
    pop bx
    pop ax
    ret
endp

; lines

proc save_line ; redo !
    ; uses first two selected points
    ; uses [color]
    push ax
    push bx
    push cx

    ; reset
    mov cx, 256
    jmp find_space1

next3:
    loop find_space1

    ; find empty space in list
find_space1:
    mov bx, cx
    dec bx
    add bx, bx
    add bx, bx

    ; check if empty
    mov al, [lines + bx + 3]
    test al, 80h
    jnz next3

    ; write color
    mov al, [color]
    mov [lines + bx], al

    ; delete info
    mov [lines + bx + 2], 0
    mov [lines + bx + 3], 0

    ; write first point
    mov ax, 1024
    call get_selected_point
    mov [offset lines + bx + 1], ax

    ; write second point
    call get_selected_point
    shl ax, 2
    or ax, 8000h
    or [offset lines + bx + 2], ax

    pop cx
    pop bx
    pop ax
    ret
endp

proc draw_saved_lines ; redo !
    push ax
    mov al, [color]
    push ax
    push bx
    push cx
    push dx

    ; start
    mov cx, 256
    jmp next_line

next4:
    loop next_line
    jmp finish14

next_line:
    ; find next line
    mov bx, cx
    dec bx
    add bx, bx
    add bx, bx

    ; check if not empty
    mov al, [lines + bx + 3]
    test al, 80h
    jz next4

    ; get color
    mov al, [lines + bx]
    mov [color], al

    ; get first point
    mov ax, [offset lines + bx + 1]
    and ax, 03FFh
    mov dx, ax
    add dx, ax

    ; get second point
    mov ax, [offset lines + bx + 2]
    shr ax, 2
    and ax, 03FFh
    mov bx, ax
    add bx, ax

    ; call draw_line !

    loop next_line

finish14:
    pop dx
    pop cx
    pop bx
    pop ax
    mov [color], al
    pop ax
    ret
endp

; other

proc toggle_zf
    push ax

    jz toggle_off
    jmp toggle_on

toggle_on:
    call toggle_zf_on
    jmp finish7

toggle_off:
    call toggle_zf_off
    jmp finish7

finish7:
    pop ax
    ret
endp

proc toggle_zf_on
    push ax

    cmp ax, ax

    pop ax
    ret
endp

proc toggle_zf_off
    push ax

    mov ax, 1
    cmp ax, 0

    pop ax
    ret
endp

; code

start:
	mov ax, @data
	mov ds, ax
    
	call clear_screen
	call show_mouse

    mov [button_images],      0000000000000000b
    mov [button_images + 2],  0001111111111000b
    mov [button_images + 4],  0010000000000100b
    mov [button_images + 6],  0100000110000010b
    mov [button_images + 8],  0100000110000010b
    mov [button_images + 10], 0100111111110010b
    mov [button_images + 12], 0100000000000010b
    mov [button_images + 14], 0100011111100010b
    mov [button_images + 16], 0100010110100010b
    mov [button_images + 18], 0100010110100010b
    mov [button_images + 20], 0100010110100010b
    mov [button_images + 22], 0100010110100010b
    mov [button_images + 24], 0100011111100010b
    mov [button_images + 26], 0010000000000100b
    mov [button_images + 28], 0001111111111000b
    mov [button_images + 30], 0000000000000000b

    mov [button_images + 32], 0000000000000000b
    mov [button_images + 34], 0001111111111000b
    mov [button_images + 36], 0010000000000100b
    mov [button_images + 38], 0100010000000010b
    mov [button_images + 40], 0100000000000010b
    mov [button_images + 42], 0100001000000010b
    mov [button_images + 44], 0100000100000010b
    mov [button_images + 46], 0100000100000010b
    mov [button_images + 48], 0100000010000010b
    mov [button_images + 50], 0100000010000010b
    mov [button_images + 52], 0100000001000010b
    mov [button_images + 54], 0100000000000010b
    mov [button_images + 56], 0100000000100010b
    mov [button_images + 58], 0010000000000100b
    mov [button_images + 60], 0001111111111000b
    mov [button_images + 62], 0000000000000000b

    mov [button_images + 64], 0000000000000000b
    mov [button_images + 66], 0001111111111000b
    mov [button_images + 68], 0010000000000100b
    mov [button_images + 70], 0100001100000010b
    mov [button_images + 72], 0100110000111010b
    mov [button_images + 74], 0100100000110010b
    mov [button_images + 76], 0101000000111010b
    mov [button_images + 78], 0101000000101010b
    mov [button_images + 80], 0101010000001010b
    mov [button_images + 82], 0101110000001010b
    mov [button_images + 84], 0100110000010010b
    mov [button_images + 86], 0101110000110010b
    mov [button_images + 88], 0100000011000010b
    mov [button_images + 90], 0010000000000100b
    mov [button_images + 92], 0001111111111000b
    mov [button_images + 94], 0000000000000000b

    jmp game_loop

button1:
    call clear_screen
    call show_mouse
    call draw_saved_lines
    jmp game_loop

button2:
    mov ax, 1024
    call get_selected_point
    jnz game_loop
    call prepare_for_line
    call draw_bezier_curve
    jmp game_loop

button3:
    call hide_selected_points
    call delete_selected_points
    jmp game_loop

execute_buttons:
    ; check if mouse was pressed
    cmp bx, 0
    jz game_loop

    ; check which button was pressed
    cmp ax, 1
    jz button1

    cmp ax, 2
    jz button2

    cmp ax, 3
    jz button3

move_loop:
    sub cx, [x_point]
    sub dx, [y_point]
    
    neg cx
    neg dx
    
    push [x_point]
    push [y_point]

    mov ax, cx
    or ax, dx
    jz next

    call hide_selected_points
    call move_selected_points
    call draw_saved_points

next:
    pop dx
    pop cx

    call get_mouse_info
    cmp bx, 1
    jnz game_loop
    jmp move_loop

game_loop:
    call draw_saved_points ; don't do this !
    call clear_highlighted_point
    call get_mouse_press_info

    ; update and execute buttons
    call update_buttons
    call draw_buttons

    ; check if pressed buttons
    cmp ax, 0
    jnz execute_buttons

    ; check if on point and get index
    call get_point_at_location
    
    ; store zf in bh
    pushf
    pop cx
    shr cx, 6
    and cx, 1
    mov bh, al

    ; variables:

    ; ax = point you are on
    ; bl = pressed
    ; bh = on point
    ; [x_point] = current x
    ; [y_point] = current y

    ; decision tree:
    ; * = has a lable
    
    ; start:
    ;     clear highlighted
    ;     not pressed: *
    ;         on point:
    ;             not point selected:
    ;                 set highlighed
    ;     pressed:
    ;         not on point: *
    ;             not exists selected point: *
    ;                 draw point
    ;             exists selected point:
    ;                 clear selected
    ;         on point:
    ;             not point selected: *
    ;                 select point
    ;             point selected:
    ;                 move selected

    call clear_highlighted_point
    cmp bl, 0
    jz not_pressed
    
    cmp bh, 0
    jz not_on_point

    mov bx, ax
    add bx, ax
    mov cx, [point_info + bx]
    cmp ch, 3
    jnz not_point_selected

    mov cx, [x_point]
    mov dx, [y_point]

    jmp move_loop

not_pressed:
    cmp bh, 0
    jz game_loop

    mov bx, ax
    add bx, ax
    mov cx, [point_info + bx]
    cmp ch, 3
    jz game_loop

    mov ch, 2
    mov [point_info + bx], cx

    jmp game_loop

not_on_point:
    mov ax, 1024
    call get_selected_point
    jnz not_exists_selected_point

    call clear_selected_points

    jmp game_loop

not_exists_selected_point:
    call save_point

    jmp game_loop

not_point_selected:
    mov bx, ax
    add bx, ax
    mov cx, [point_info + bx]
    mov ch, 3
    mov [point_info + bx], cx

    jmp game_loop

exit_loop:
    jmp exit_loop

exit:
	call exit_graphic_mode
	mov ax, 4c00h
	int 21h
END start

; add lines !
; make update points and update slines !
; add colors !
; add line button !
; add way to see lines !
; add out of bounds support by modifing the draw saved points and get point at location !
; add zoom in and zoom out !
