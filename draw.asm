IDEAL

MODEL small

STACK 100h

DATASEG

scale_factor db 10
screen_x dw 32768
screen_y dw 32768
x_points dw 2048 dup(?)
y_points dw 2048 dup(?)
mod_x_points dw 2048 dup(?)
mod_y_points dw 2048 dup(?)
point_info dw 2048 dup(0) ; first byte = color, second byte = mode (0 = doesn't exists, 1 = normal, 2 = highlighted, 3 = selected, 4 = hidden)
line_info db 4096 dup(0) ; first, second bytes = starting index in line_points, third byte - 2 last bytes = point count, 2 last bytes of third byte = mode (0 = doesn't exists, 1 = normal), forth byte = color
area_info db 2048 dup(0) ; first byte = color, second byte = mode (0 = doesn't exists, 1 = normal)
ellipse_info db 8192 dup(0) ; first, second bytes = first point, third, fourth bytes = second point, fifth, sixth bytes = second point, seventh byte = color, eighth byte = mode (0 = doesn't exists, 1 = normal)
line_points dw 4096 dup(0)
used_line_points dw 0
x_point dw ?
y_point dw ?
color db 15
line_resulution dw 2000
fill_resulution dw 2
last_press_info db 0
dot_sprite_size db 3
dot_hitbox_size db 4
button_count db 11
button_images dw 352 dup(?)
calculation_variable dw ?

CODESEG

; visual

proc check_if_black
    ; gets top left corner in x_point, y_point
    ; gets sides in ax
    ; zf = 1 = all black
    push bx
    push cx
    push dx
    push [x_point]
    push [y_point]

    mov cx, [x_point]
    mov dx, [y_point]
    xor bx, bx

    cmp [x_point], 320
    jae found_color
    cmp [y_point], 200
    jae found_color

    add [x_point], ax
    add [y_point], ax

    cmp [x_point], 320
    jae found_color
    cmp [y_point], 200
    jae found_color

next_point3:
    push ax
    push cx
    push dx
    mov ah, 0dh
    mov cx, [x_point]
    mov dx, [y_point]
    int 10h
    cmp al, 0
    pop dx
    pop cx
    pop ax
    jnz found_color

    dec [x_point]
    cmp [x_point], cx
    jnz next_point3
    add [x_point], ax
    dec [y_point]
    cmp [y_point], dx
    jnz next_point3

    call toggle_zf_on
    pop [y_point]
    pop [x_point]
    pop dx
    pop cx
    pop bx
    ret

found_color:
    call toggle_zf_off
    pop [y_point]
    pop [x_point]
    pop dx
    pop cx
    pop bx
    ret
endp

proc draw_ellipse
    ; gets a in ax and b in bx
    ; gest location in x_point, y_point
    push cx
    push dx
    mov dx, ax

    mov cx, [line_resulution]

draw_next:
    dec cx
    push dx
    push [x_point]
    push [y_point]
    call cos
    imul dx
    idiv [line_resulution]
    add [x_point], ax
    call sin
    imul bx
    idiv [line_resulution]
    add [y_point], ax
    call print_point
    pop [y_point]
    pop [x_point]
    pop dx
    cmp cx, 0
    jnz draw_next
    
    pop dx
    pop cx
    ret
endp

proc extand_left
    ; gets point in x_point, y_point
    ; gets incruments in ax
    ; moves point to the nearest color left of the point

    add [x_point], ax

move_point:
    sub [x_point], ax
    call check_if_black
    jz move_point

    ret
endp

proc fill_in
    push ax
    push cx
    push dx

    mov si, sp
    mov ax, [fill_resulution]

    mov cl, [dot_sprite_size]
    xor ch, ch
    shr cx, 1
    add cx, 2
    add cx, ax
    sub [x_point], cx
    call extand_left
    push [x_point]
    push [y_point]

next_segment:
    cmp si, sp
    jnz not_done
    jmp finish23

not_done:

    pop [y_point]
    pop [x_point]
    mov cx, [x_point]
    mov dx, [y_point]

    add [x_point], ax
    add [y_point], ax
    call check_if_black
    jnz skip
    
    call extand_left
    push [x_point]
    push [y_point]

skip:

    mov [x_point], cx
    mov [y_point], dx

    add [x_point], ax
    sub [y_point], ax
    call check_if_black
    jnz do_segment
    
    call extand_left
    push [x_point]
    push [y_point]

do_segment:
    mov [x_point], cx
    mov [y_point], dx
    
    add [x_point], ax
    call draw_square

    add [x_point], ax
    call check_if_black
    jnz next_segment
    sub [x_point], ax

    mov cx, [x_point]
    mov dx, [y_point]

    add [y_point], ax
    call check_if_black
    jz skip1

    add [x_point], ax
    call check_if_black
    jnz skip1

    sub [x_point], ax
    push [x_point]
    push [y_point]

skip1:
    
    mov [x_point], cx
    mov [y_point], dx

    sub [y_point], ax
    call check_if_black
    jz do_segment

    add [x_point], ax
    call check_if_black
    jnz do_segment

    sub [x_point], ax
    push [x_point]
    push [y_point]

    jmp do_segment

finish23:
    pop dx
    pop cx
    pop ax
    ret
endp

proc draw_dot
    ; draws a dot at x_point, y_point
    push ax
    push bx

    ; calculate middle of point
    xor ah, ah
    mov al, [dot_sprite_size]
    shr al, 1
    sub [x_point], ax
    dec [x_point]
    sub [y_point], ax
    dec [y_point]
    mov al, [dot_sprite_size]

    mov bl, [color]
    mov [color], 0

    add ax, 2
    dec [x_point]
    dec [y_point]

    call draw_square_border
    mov [color], bl

    sub ax, 2
    inc [x_point]
    inc [y_point]
    call draw_square

    pop bx
    pop ax
    ret
endp

proc draw_selected_dot
    ; draws a dot at x_point, y_point
    push ax
    push bx

    ; calculate middle of point
    xor ah, ah
    mov al, [dot_sprite_size]
    shr al, 1
    sub [x_point], ax
    dec [x_point]
    sub [y_point], ax
    dec [y_point]
    mov al, [dot_sprite_size]

    mov bl, [color]
    mov [color], 12

    add ax, 2
    dec [x_point]
    dec [y_point]

    call draw_square_border
    mov [color], bl

    sub ax, 2
    inc [x_point]
    inc [y_point]
    call draw_square

    pop bx
    pop ax
    ret
endp

proc draw_highlighted_dot
    ; draws a dot at x_point, y_point
    push ax
    push bx

    ; calculate middle of point
    xor ah, ah
    mov al, [dot_sprite_size]
    shr al, 1
    sub [x_point], ax
    dec [x_point]
    sub [y_point], ax
    dec [y_point]
    mov al, [dot_sprite_size]

    mov bl, [color]
    mov [color], 11

    add ax, 2
    dec [x_point]
    dec [y_point]

    call draw_square_border
    mov [color], bl

    sub ax, 2
    inc [x_point]
    inc [y_point]
    call draw_square

    pop bx
    pop ax
    ret
endp

proc draw_bezier_curve
    ; uses indexes in stack, gets count in dx
    push ax
    push bx
    push cx
    push dx

    dec dx
    mov cx, [line_resulution]
    mov [calculation_variable], cx

next_t:
    mov bx, sp
    add bx, 8

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
    mul [mod_x_points + bx]
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
    mul [mod_y_points + bx]
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
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp

proc clear_screen
    push ax

    mov ax, 13h
    int 10h

    pop ax
    ret
endp

proc start_mouse
    push ax
    xor ax, ax
 	int 33h
	mov ax, 1h
	int 33h
    pop ax
	ret
endp

proc get_mouse_info
	; bx = press info
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

    pop dx
    pop cx
    pop ax
	ret
endp

proc get_mouse_press_info
	; bx = press info
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

    mov al, [last_press_info]
    mov [last_press_info], bl
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

    ; check if point is in bounds
    cmp [x_point], 320
    jae finish22
    cmp [y_point], 200
    jae finish22

    ; print point
    xor bh, bh
    mov cx, [x_point]
    mov dx, [y_point]
    mov al, [color]
    mov ah, 0ch
    int 10h

finish22:
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
    dec [x_point]

    pop cx
    pop bx
    pop ax
    ret
endp

proc draw_square
    ; gets top left corner in x_point, y_point
    ; gets sides in ax
    push cx
    push dx
    push [x_point]
    push [y_point]

    mov cx, [x_point]
    mov dx, [y_point]

    add [x_point], ax
    add [y_point], ax

next_point10:
    call print_point

    dec [x_point]
    cmp [x_point], cx
    jnz next_point10
    add [x_point], ax
    dec [y_point]
    cmp [y_point], dx
    jnz next_point10

    pop [y_point]
    pop [x_point]
    pop dx
    pop cx
    ret
endp

proc draw_square_border
    ; gets top left corner in x_point, y_point
    ; gets sides in ax
    push cx
    push [x_point]
    push [y_point]
    
    inc [x_point]
    inc [y_point]

    ; first line
    mov cx, ax
    dec cx
next_point5:
    inc [x_point]
    call print_point
    loop next_point5

    ; second line
    mov cx, ax
    dec cx
next_point6:
    inc [y_point]
    call print_point
    loop next_point6

    ; third line
    mov cx, ax
    dec cx
next_point7:
    dec [x_point]
    call print_point
    loop next_point7

    ; forth line
    mov cx, ax
    dec cx
next_point8:
    dec [y_point]
    call print_point
    loop next_point8

    pop [y_point]
    pop [x_point]
    pop cx
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

proc update_mod_points
    push ax
    push bx
    push cx
    push dx

    mov bx, 2048

next_point9:
    sub bx, 2

    ; update x
    mov ax, [x_points + bx]
    sub ax, [screen_x]
    xor dx, dx
    mov cl, [scale_factor]
    xor ch, ch
    div cx
    mov [mod_x_points + bx], ax
    
    ; update y
    mov ax, [y_points + bx]
    sub ax, [screen_y]
    xor dx, dx
    mov cl, [scale_factor]
    xor ch, ch
    div cx
    mov [mod_y_points + bx], ax

    ; next
    cmp bx, 0
    jnz next_point9

    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp

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
    ; bh = 1 = pressed a point
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
    add ax, [mod_x_points + bx]
    cmp [x_point], ax
    ja loop_next

    xor ah, ah
    mov al, [dot_hitbox_size]
    add ax, [x_point]
    cmp [mod_x_points + bx], ax
    ja loop_next

    ; check y
    xor ah, ah
    mov al, [dot_hitbox_size]
    add ax, [mod_y_points + bx]
    cmp [y_point], ax
    ja loop_next

    xor ah, ah
    mov al, [dot_hitbox_size]
    add ax, [y_point]
    cmp [mod_y_points + bx], ax
    ja loop_next

    ; finish
    mov ax, cx
    dec ax

    pop dx
    pop cx
    pop bx
    mov bh, 1
    ret

loop_next:
    loop next_point
    
    pop dx
    pop cx
    pop bx
    xor bh, bh
    ret
endp

proc save_point
    ; creates at (x_point, y_point)
    ; gets color in [color]
    push ax
    push bx
    push dx

    ; reset
    mov bx, 2048
    jmp find_space

    ; find empty space in list
find_space:
    sub bx, 2

    ; check if empty
    mov ax, [point_info + bx]
    cmp ah, 0
    jnz find_space

    ; replace info
    mov al, [color]
    mov ah, 1
    mov [point_info + bx], ax

    ; replace x
    mov ax, [x_point]
    mov [mod_x_points + bx], ax

    mov dl, [scale_factor]
    xor dh, dh
    mul dx
    add ax, [screen_x]
    mov [x_points + bx], ax

    ; replace y
    mov ax, [y_point]
    mov [mod_y_points + bx], ax

    mov dl, [scale_factor]
    xor dh, dh
    mul dx
    add ax, [screen_y]
    mov [y_points + bx], ax

    pop dx
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
    mov bx, 2048
    jmp find_next

find_next:
    ; check if exists
    cmp bx, 0
    jz finish
    sub bx, 2

    mov ax, [point_info + bx]
    mov [color], al
    cmp ah, 1
    jz draw_normal1
    cmp ah, 2
    jz draw_highlighted1
    cmp ah, 3
    jz draw_selected1
    
    jmp find_next

draw_normal1:
    mov ax, [mod_x_points + bx]
    mov [x_point], ax
    mov ax, [mod_y_points + bx]
    mov [y_point], ax
    call draw_dot

    jmp find_next

draw_selected1:
    mov ax, [mod_x_points + bx]
    mov [x_point], ax
    mov ax, [mod_y_points + bx]
    mov [y_point], ax
    call draw_selected_dot

    jmp find_next

draw_highlighted1:
    mov ax, [mod_x_points + bx]
    mov [x_point], ax
    mov ax, [mod_y_points + bx]
    mov [y_point], ax
    call draw_highlighted_dot

    jmp find_next

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

proc get_point
    ; gets starting search location in ax
    ; returns point index in ax
    ; zf = 1 = found point
    push bx
    push cx

    mov cx, ax

check_next_point1:
    mov bx, cx
    dec bx
    add bx, bx

    mov ax, [point_info + bx]
    cmp ah, 0
    jnz found_point1

    loop check_next_point1

    mov ax, cx
    dec ax
    call toggle_zf_off
    pop cx
    pop bx
    ret

found_point1:
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

    push dx

    mov ax, cx
    mov dl, [scale_factor]
    xor dh, dh
    mul dx
    mov cx, ax

    pop dx

    mov ax, dx
    mov dl, [scale_factor]
    xor dh, dh
    mul dx
    mov dx, ax

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
    mov cx, [mod_x_points + bx]
    mov [x_point], cx
    mov cx, [mod_y_points + bx]
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

proc hide_all_points
    push ax
    mov al, [color]
    push ax
    push bx
    push cx

    mov [color], 0
    mov ax, 1024

delete_next1:
    ; find next
    call get_point
    jnz finish8

    ; delete point
    mov bx, ax
    add bx, ax
    mov cx, [mod_x_points + bx]
    mov [x_point], cx
    mov cx, [mod_y_points + bx]
    mov [y_point], cx
    call draw_dot

    ; repeat
    jmp delete_next1

finish8:
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

delete_next2:
    ; find next
    call get_selected_point
    jnz finish13

    ; delete point
    mov bx, ax
    add bx, ax
    mov [point_info + bx], 0

    ; repeat
    jmp delete_next2

finish13:
    pop cx
    pop bx
    pop ax
    ret
endp

; lines

proc save_line
    ; uses indexes in stack, gets count in dx
    ; uses [color]
    push ax
    push bx
    push cx
    push dx

    xor bx, bx
    sub bx, 4

find_space1:
    add bx, 4
    mov al, [line_info + bx + 2]
    shr al, 6
    jnz find_space1

    ; save in space
    mov ax, [used_line_points]
    mov [offset line_info + bx], ax
    mov al, [color]
    mov [line_info + bx + 3], al
    mov al, dl
    and al, 00111111b
    mov cl, al
    xor ch, ch
    or al, 01000000b
    mov [line_info + bx + 2], al

    ; save point indexes
save_next_point:
    dec dx
    
    mov bx, sp
    add bx, dx
    add bx, dx
    mov ax, [ss:(bx + 10)]
    
    sub bx, sp
    add bx, [used_line_points]
    add bx, [used_line_points]
    mov [line_points + bx], ax

    cmp dx, 0
    jnz save_next_point

    add [used_line_points], cx
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp

proc draw_saved_lines
    push ax
    mov al, [color]
    push ax
    push bx
    push cx
    push dx

    xor bx, bx
    sub bx, 4
next_line:
    add bx, 4
    mov dl, [line_info + bx + 2]
    test dl, 11000000b
    jz finish16
    and dx, 0000000000111111b
    mov al, [line_info + bx + 3]
    mov [color], al
    mov cx, dx
    mov ax, bx
    mov bx, [offset line_info + bx]
    add bx, bx
    sub bx, 2

push_next_point:
    ; push all point indexes
    add bx, 2
    push [line_points + bx]
    loop push_next_point
    
    ; draw line
    call draw_bezier_curve

    ; reset stack
    add sp, dx
    add sp, dx

    ; repeat
    mov bx, ax
    jmp next_line

finish16:
    pop dx
    pop cx
    pop bx
    pop ax
    mov [color], al
    pop ax
    ret
endp

proc delete_line
    ; gets line index in ax
    push ax
    push bx
    push cx

    ; setup
    push ds
    pop es
    mov bx, ax
    add bx, ax
    add bx, ax
    add bx, ax
    mov cl, [line_info + bx + 2]
    and cx, 0000000000111111b
    push cx

move_next_group:
    cmp cx, 0
    jz next3
    dec cx
    mov si, offset line_points
    add si, [offset line_info + bx]
    add si, [offset line_info + bx]
    mov di, si
    add si, 2

move_next_point:
    push cx
    xor cx, cx
    cmp [di], cx
    pop cx
    jz move_next_group
    movsw
    jmp move_next_point

next3:
    mov di, offset line_info
    add di, bx
    mov si, di
    add si, 4
    pop cx

move_next_line:
    mov al, [di + 2]
    test al, 11000000b
    jz finish17
    sub [si], cx
    movsw
    movsw
    jmp move_next_line

finish17:
    pop cx
    pop bx
    pop ax
    ret
endp

proc erase_line
    ; gets line index in ax
    push bx
    mov bl, [color]
    push bx
    push cx
    push dx

    mov bx, ax
    add bx, ax
    add bx, ax
    add bx, ax
    mov cl, [line_info + bx + 2]
    and cx, 0000000000111111b
    mov dx, cx
    mov bx, [offset line_info + bx]
    add bx, bx
    add bx, cx
    add bx, cx

push_next:
    sub bx, 2
    push [line_points + bx]
    loop push_next

finish19:
    mov [color], 0
    call draw_bezier_curve

    add sp, dx
    add sp, dx

    pop dx
    pop cx
    pop bx
    mov [color], bl
    pop bx
    ret
endp

proc delete_lines
    ; gets point indexes at ax, bx
    ; deletes all lines that start at ax and end at bx
    push ax
    push cx
    push dx

    ; reset
    push bx
    mov [calculation_variable], 0

check_next_line:
    ; get points and check if line exists
    mov bx, [calculation_variable]
    mov cl, [line_info + bx + 2]
    test cx, 11000000b
    jz finish18
    and cx, 0000000000111111b
    mov dx, [offset line_info + bx]
    add cx, dx
    dec cx
    add cx, cx
    mov bx, cx
    mov cx, [line_points + bx]
    add dx, dx
    mov bx, dx
    mov dx, [line_points + bx]

    pop bx
    push bx

    ; cmp first point (ax)
    cmp cx, ax
    jz next_check
    cmp dx, ax
    jz next_check

    add [calculation_variable], 4
    jmp check_next_line

next_check:
    ; cmp next point (bx)
    cmp cx, bx
    jz delete_line1
    cmp dx, bx
    jz delete_line1

    add [calculation_variable], 4
    jmp check_next_line

delete_line1:
    push ax
    push bx
    push dx
    mov ax, [calculation_variable]
    mov bx, 4
    xor dx, dx
    div bx
    call erase_line
    call delete_line
    pop dx
    pop bx
    pop ax

    jmp check_next_line

finish18:
    pop bx

    pop dx
    pop cx
    pop ax
    ret
endp

proc delete_deleted_lines
    push ax
    push bx
    push cx

    ; ax = line index
    ; bx = point index
    ; cx = point count in current line

    mov ax, -4
    mov bx, -2

next_line1:
    ; go to next line
    add ax, 4
    xchg ax, bx
    mov cl, [offset line_info + bx + 2]
    test cl, 11000000b
    jz finish21
    and cx, 0000000000111111b
    inc cx
    xchg ax, bx

check_next_point2:
    dec cx
    jz next_line1

    ; check every point on line
    add bx, 2
    push bx
    mov bx, [line_points + bx]
    add bx, bx
    test [point_info + bx], 0000000011111111b
    pop bx
    jnz check_next_point2
    
    ; prepere next line
    xchg ax, bx
    push cx
    mov cl, [offset line_info + bx + 2]
    and cx, 0000000000111111b
    sub ax, cx
    sub ax, cx
    pop cx
    add ax, cx
    add ax, cx
    sub ax, 2
    xchg ax, bx

    ; delete line
    push cx
    mov cl, 4
    div cl
    call erase_line
    call delete_line
    mul cl
    pop cx
    sub ax, 4

    ; go to next line
    jmp next_line1

finish21:
    pop cx
    pop bx
    pop ax
    ret
endp

; areas

proc delete_deleted_areas
    ; deletes all areas who's origin is deleted

    push ax

    ; find space
    mov si, -2

check_next4:
    add si, 2
    cmp si, 2048
    jz finish30

    mov al, [offset point_info + si + 1]
    cmp al, 0
    jz delete_area

    jmp check_next4

delete_area:
    mov [area_info + si + 1], 0

    jmp check_next4
    
finish30:
    pop ax
    ret
endp

proc draw_saved_areas
    push ax
    mov al, [color]
    push ax
    push bx

    mov bx, -2

next_area:
    add bx, 2
    cmp bx, 2048
    jz finish24
    cmp [area_info + bx + 1], 0
    jz next_area
    test [point_info + bx], 0ff00h
    jz next_area

    mov ax, [mod_x_points + bx]
    mov [x_point], ax
    mov ax, [mod_y_points + bx]
    mov [y_point], ax
    mov al, [area_info + bx]
    mov [color], al
    call fill_in
    jmp next_area

finish24:
    pop bx
    pop ax
    mov [color], al
    pop ax
    ret
endp

; ellipses

proc delete_deleted_ellipses
    ; deletes all ellipses which have a deleted point

    push ax
    push bx

    mov si, -8
    mov ax, -1

check_next3:
    inc ax
    add si, 8
    cmp [ellipse_info + si + 7], 0
    jz finish29

    mov bx, [offset ellipse_info + si]
    add bx, bx
    mov bl, [offset point_info + bx + 1]
    cmp bl, 0
    jz delete_ellipse2
    
    mov bx, [offset ellipse_info + si + 2]
    add bx, bx
    mov bl, [offset point_info + bx + 1]
    cmp bl, 0
    jz delete_ellipse2
    
    mov bx, [offset ellipse_info + si + 4]
    add bx, bx
    mov bl, [offset point_info + bx + 1]
    cmp bl, 0
    jz delete_ellipse2

    jmp check_next3

delete_ellipse2:
    call delete_ellipse
    dec ax
    sub si, 8

    jmp check_next3
    
finish29:
    pop bx
    pop ax
    ret
endp

proc delete_selected_ellipses
    ; deletes all ellipses who's centers are selected

    push ax
    push bx

    ; find space
    mov si, -8
    mov ax, -1

check_next2:
    inc ax
    add si, 8
    cmp [ellipse_info + si + 7], 0
    jz finish28

    mov bx, [offset ellipse_info + si]
    add bx, bx
    mov bl, [offset point_info + bx + 1]
    cmp bl, 3
    jz delete_ellipse1

    jmp check_next2

delete_ellipse1:
    call delete_ellipse
    dec ax
    sub si, 8

    jmp check_next2
    
finish28:
    pop bx
    pop ax
    ret
endp

proc delete_ellipse
    ; gets index in ax
    ; deletes ellipse at index

    push si
    push di

    push ds
    pop es

    mov di, offset ellipse_info
    add di, ax
    add di, ax

    mov si, di
    add si, 8

move_next1:
    cmp [ellipse_info + di + 7], 0
    jz finish27

    movsw
    movsw
    movsw
    movsw

    jmp move_next1
    
finish27:
    pop di
    pop si
    ret
endp

proc save_ellipse
    ; gets center point index in ax
    ; gets side points in cx, dx

    push ax

    ; find space
    mov si, -8

check_next:
    add si, 8
    cmp [ellipse_info + si + 7], 0
    jnz check_next

    mov [offset ellipse_info + si], ax
    mov [offset ellipse_info + si + 2], cx
    mov [offset ellipse_info + si + 4], dx
    mov al, [color]
    mov [ellipse_info + si + 6], al
    mov [ellipse_info + si + 7], 1
    
    pop ax
    ret
endp

proc snap_ellipse_points
    push ax
    push bx

    mov si, -8

check_next1:
    add si, 8
    cmp [ellipse_info + si + 7], 0
    jz finish25

    mov bx, [offset ellipse_info + si]
    add bx, bx
    push bx
    mov ax, [x_points + bx]
    mov bx, [offset ellipse_info + si + 4]
    add bx, bx
    mov [x_points + bx], ax
    pop bx
    mov ax, [y_points + bx]
    mov bx, [offset ellipse_info + si + 2]
    add bx, bx
    mov [y_points + bx], ax

    jmp check_next1

finish25:
    pop bx
    pop ax
    ret
endp

proc draw_saved_ellipses
    push ax
    mov al, [color]
    push ax
    push bx

    mov si, -8

draw_next2:
    add si, 8
    cmp [ellipse_info + si + 7], 0
    jz finish26

    ; get origin and color
    mov bx, [offset ellipse_info + si]
    add bx, bx
    mov ax, [mod_x_points + bx]
    mov [x_point], ax
    mov ax, [mod_y_points + bx]
    mov [y_point], ax
    mov al, [ellipse_info + si + 6]
    mov [color], al

    ; get a
    mov bx, [offset ellipse_info + si + 2]
    add bx, bx
    mov ax, [mod_x_points + bx]
    sub ax, [x_point]
    call abs_ax

    ; get b
    push ax
    mov bx, [offset ellipse_info + si + 4]
    add bx, bx
    mov ax, [mod_y_points + bx]
    sub ax, [y_point]
    call abs_ax
    mov bx, ax
    pop ax

    call draw_ellipse

    jmp draw_next2

finish26:
    pop bx
    pop ax
    mov [color], al
    pop ax
    ret
endp

; screens

proc load_colors_screen
    push ax
    push cx
    push dx

    ; prepere
    call clear_screen

    push [x_point]
    push [y_point]

    mov [x_point], 230
    mov [y_point], 100
    mov [color], 15
    mov ax, 10

next_point4:
    call draw_square

    dec [color]
    cmp [color], 15
    jz finish20
    sub [x_point], 10
    cmp [x_point], -10
    jnz next_point4
    mov [x_point], 230
    sub [y_point], 10
    jmp next_point4

finish20:
    pop [y_point]
    pop [x_point]

    ; redo mouse
    call start_mouse
    mov cx, [x_point]
    add cx, [x_point]
    add cx, 4
    mov dx, [y_point]
    add dx, 2
    mov ax, 4
    int 33h
    
    pop dx
    pop cx
    pop ax
    ret
endp

proc load_draw_screen
    push ax
    push cx
    push dx

    ; reset
    mov cx, [x_point]
    shl cx, 1
    mov dx, [y_point]
    call clear_screen
    call update_mod_points
    call draw_saved_points
    call draw_saved_lines
    call draw_saved_ellipses
    call draw_saved_areas
    call start_mouse
    mov ax, 4
    int 33h

    pop dx
    pop cx
    pop ax
    ret
endp

; other

proc abs_ax
    ; gets value in ax
    ; returns answer in ax

    cmp ax, 0
    jl negate
    ret

negate:
    neg ax
    ret
endp

proc quarter_cos
    ; gets angle in ax
    ; returns value in ax
    ; only supports angles above or equal to 0 and less then line_resulution/4
    ; doesn't save dx

    ; mov dx, 100
    ; mul dx
    ; xor dx, dx
    ; div [line_resulution]
    ; mul cx
    ; mov bx, 6
    ; xor dx, dx
    ; div bx
    ; mov bx, ax
    ; mov ax, [line_resulution]
    ; sub ax, bx

    mov dx, 4
    mul dx
    mul ax
    div [line_resulution]
    neg ax
    add ax, [line_resulution]

    ret
endp

proc cos
    ; gets angle in cx
    ; returns value in ax
    ; only supports angles above or equal to 0 and less then line_resulution
    push bx
    push cx
    push dx

    ; determain which quarter the angle is in
    mov ax, [line_resulution]
    mov bx, 4
    xor dx, dx
    div bx
    
    cmp ax, cx
    ja first_quarter
    sub cx, ax
    cmp ax, cx
    ja second_quarter
    sub cx, ax
    cmp ax, cx
    ja third_quarter
    sub cx, ax
    jmp fourth_quarter

first_quarter:
    mov ax, cx

    call quarter_cos

    pop dx
    pop cx
    pop bx
    ret

second_quarter:
    sub ax, cx

    call quarter_cos

    neg ax

    pop dx
    pop cx
    pop bx
    ret

third_quarter:
    mov ax, cx

    call quarter_cos

    neg ax

    pop dx
    pop cx
    pop bx
    ret

fourth_quarter:
    sub ax, cx

    call quarter_cos

    pop dx
    pop cx
    pop bx
    ret
endp

proc sin
    ; gets angle in cx
    ; returns value in ax
    ; only supports angles above or equal to 0 and less then line_resulution
    push bx
    push cx
    push dx

    ; determain which quarter the angle is in
    mov ax, [line_resulution]
    mov bx, 4
    xor dx, dx
    div bx
    
    cmp ax, cx
    ja first_quarter1
    sub cx, ax
    cmp ax, cx
    ja second_quarter1
    sub cx, ax
    cmp ax, cx
    ja third_quarter1
    sub cx, ax
    jmp fourth_quarter1

first_quarter1:
    sub ax, cx

    call quarter_cos

    pop dx
    pop cx
    pop bx
    ret

second_quarter1:
    mov ax, cx

    call quarter_cos

    pop dx
    pop cx
    pop bx
    ret
    
third_quarter1:
    sub ax, cx

    call quarter_cos

    neg ax

    pop dx
    pop cx
    pop bx
    ret

fourth_quarter1:
    mov ax, cx

    call quarter_cos

    neg ax

    pop dx
    pop cx
    pop bx
    ret

endp

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
	call start_mouse

    mov [button_images],       0000000000000000b
    mov [button_images + 2],   0001111111111000b
    mov [button_images + 4],   0010000000000100b
    mov [button_images + 6],   0100000110000010b
    mov [button_images + 8],   0100000110000010b
    mov [button_images + 10],  0100111111110010b
    mov [button_images + 12],  0100000000000010b
    mov [button_images + 14],  0100011111100010b
    mov [button_images + 16],  0100010110100010b
    mov [button_images + 18],  0100010110100010b
    mov [button_images + 20],  0100010110100010b
    mov [button_images + 22],  0100010110100010b
    mov [button_images + 24],  0100011111100010b
    mov [button_images + 26],  0010000000000100b
    mov [button_images + 28],  0001111111111000b
    mov [button_images + 30],  0000000000000000b

    mov [button_images + 32],  0000000000000000b
    mov [button_images + 34],  0001111111111000b
    mov [button_images + 36],  0010000000000100b
    mov [button_images + 38],  0100010000000010b
    mov [button_images + 40],  0100000000000010b
    mov [button_images + 42],  0100001000000010b
    mov [button_images + 44],  0100000100000010b
    mov [button_images + 46],  0100000100000010b
    mov [button_images + 48],  0100000010000010b
    mov [button_images + 50],  0100000010000010b
    mov [button_images + 52],  0100000001000010b
    mov [button_images + 54],  0100000000000010b
    mov [button_images + 56],  0100000000100010b
    mov [button_images + 58],  0010000000000100b
    mov [button_images + 60],  0001111111111000b
    mov [button_images + 62],  0000000000000000b

    mov [button_images + 64],  0000000000000000b
    mov [button_images + 66],  0001111111111000b
    mov [button_images + 68],  0010000000000100b
    mov [button_images + 70],  0100001100000010b
    mov [button_images + 72],  0100110000111010b
    mov [button_images + 74],  0100100000110010b
    mov [button_images + 76],  0101000000111010b
    mov [button_images + 78],  0101000000101010b
    mov [button_images + 80],  0101010000001010b
    mov [button_images + 82],  0101110000001010b
    mov [button_images + 84],  0100110000010010b
    mov [button_images + 86],  0101110000110010b
    mov [button_images + 88],  0100000011000010b
    mov [button_images + 90],  0010000000000100b
    mov [button_images + 92],  0001111111111000b
    mov [button_images + 94],  0000000000000000b

    mov [button_images + 96],  0000000000000000b
    mov [button_images + 98],  0001111111111000b
    mov [button_images + 100], 0010000000000100b
    mov [button_images + 102], 0100010000000010b
    mov [button_images + 104], 0100000000000010b
    mov [button_images + 106], 0100001000000010b
    mov [button_images + 108], 0100000000000010b
    mov [button_images + 110], 0100000000000010b
    mov [button_images + 112], 0100000000000010b
    mov [button_images + 114], 0100000000000010b
    mov [button_images + 116], 0100000001000010b
    mov [button_images + 118], 0100000000000010b
    mov [button_images + 120], 0100000000100010b
    mov [button_images + 122], 0010000000000100b
    mov [button_images + 124], 0001111111111000b
    mov [button_images + 126], 0000000000000000b

    mov [button_images + 128], 0000000000000000b
    mov [button_images + 130], 0001111111111000b
    mov [button_images + 132], 0010000000000100b
    mov [button_images + 134], 0100000000000010b
    mov [button_images + 136], 0100110000000010b
    mov [button_images + 138], 0100111100000010b
    mov [button_images + 140], 0100011100000010b
    mov [button_images + 142], 0100011110000010b
    mov [button_images + 144], 0100000111000010b
    mov [button_images + 146], 0100000011100010b
    mov [button_images + 148], 0100000001100010b
    mov [button_images + 150], 0100000000010010b
    mov [button_images + 152], 0100000000000010b
    mov [button_images + 154], 0010000000000100b
    mov [button_images + 156], 0001111111111000b
    mov [button_images + 158], 0000000000000000b

    mov [button_images + 160], 0000000000000000b
    mov [button_images + 162], 0001111111111000b
    mov [button_images + 164], 0010000000000100b
    mov [button_images + 166], 0100011100000010b
    mov [button_images + 168], 0100100010000010b
    mov [button_images + 170], 0101001001000010b
    mov [button_images + 172], 0101011101000010b
    mov [button_images + 174], 0101001001000010b
    mov [button_images + 176], 0100100010000010b
    mov [button_images + 178], 0100011101000010b
    mov [button_images + 180], 0100000000100010b
    mov [button_images + 182], 0100000000010010b
    mov [button_images + 184], 0100000000000010b
    mov [button_images + 186], 0010000000000100b
    mov [button_images + 188], 0001111111111000b
    mov [button_images + 190], 0000000000000000b

    mov [button_images + 192], 0000000000000000b
    mov [button_images + 194], 0001111111111000b
    mov [button_images + 196], 0010000000000100b
    mov [button_images + 198], 0100011100000010b
    mov [button_images + 200], 0100100010000010b
    mov [button_images + 202], 0101000001000010b
    mov [button_images + 204], 0101011101000010b
    mov [button_images + 206], 0101000001000010b
    mov [button_images + 208], 0100100010000010b
    mov [button_images + 210], 0100011101000010b
    mov [button_images + 212], 0100000000100010b
    mov [button_images + 214], 0100000000010010b
    mov [button_images + 216], 0100000000000010b
    mov [button_images + 218], 0010000000000100b
    mov [button_images + 220], 0001111111111000b
    mov [button_images + 222], 0000000000000000b

    mov [button_images + 224], 0000000000000000b
    mov [button_images + 226], 0001111111111000b
    mov [button_images + 228], 0010000000000100b
    mov [button_images + 230], 0100000000000010b
    mov [button_images + 232], 0100111000000010b
    mov [button_images + 234], 0101001100000010b
    mov [button_images + 236], 0100011110000010b
    mov [button_images + 238], 0100111111000010b
    mov [button_images + 240], 0101111111100010b
    mov [button_images + 242], 0101111110010010b
    mov [button_images + 244], 0100111100000010b
    mov [button_images + 246], 0100011000010010b
    mov [button_images + 248], 0100000000010010b
    mov [button_images + 250], 0010000000000100b
    mov [button_images + 252], 0001111111111000b
    mov [button_images + 254], 0000000000000000b
    
    mov [button_images + 256], 0000000000000000b
    mov [button_images + 258], 0001111111111000b
    mov [button_images + 260], 0010000000000100b
    mov [button_images + 262], 0100000000000010b
    mov [button_images + 264], 0100000011000010b
    mov [button_images + 266], 0100000100100010b
    mov [button_images + 268], 0100001000010010b
    mov [button_images + 270], 0100010000010010b
    mov [button_images + 272], 0100101000100010b
    mov [button_images + 274], 0100100101000010b
    mov [button_images + 276], 0100010010000010b
    mov [button_images + 278], 0100001100000010b
    mov [button_images + 280], 0100000000000010b
    mov [button_images + 282], 0010000000000100b
    mov [button_images + 284], 0001111111111000b
    mov [button_images + 286], 0000000000000000b
    
    mov [button_images + 288], 0000000000000000b
    mov [button_images + 290], 0001111111111000b
    mov [button_images + 292], 0010000000000100b
    mov [button_images + 294], 0100000000000010b
    mov [button_images + 296], 0100100110000010b
    mov [button_images + 298], 0100011111100010b
    mov [button_images + 300], 0100101000010010b
    mov [button_images + 302], 0101000100001010b
    mov [button_images + 304], 0101000010001010b
    mov [button_images + 306], 0100100001010010b
    mov [button_images + 308], 0100011111100010b
    mov [button_images + 310], 0100000110010010b
    mov [button_images + 312], 0100000000000010b
    mov [button_images + 314], 0010000000000100b
    mov [button_images + 316], 0001111111111000b
    mov [button_images + 318], 0000000000000000b

    mov [button_images + 320], 0000000000000000b
    mov [button_images + 322], 0001111111111000b
    mov [button_images + 324], 0010000000000100b
    mov [button_images + 326], 0100000000000010b
    mov [button_images + 328], 0100000110000010b
    mov [button_images + 330], 0100011111100010b
    mov [button_images + 332], 0100100000010010b
    mov [button_images + 334], 0101000000001010b
    mov [button_images + 336], 0101000000001010b
    mov [button_images + 338], 0100100000010010b
    mov [button_images + 340], 0100011111100010b
    mov [button_images + 342], 0100000110000010b
    mov [button_images + 344], 0100000000000010b
    mov [button_images + 346], 0010000000000100b
    mov [button_images + 348], 0001111111111000b
    mov [button_images + 350], 0000000000000000b
    
    xor dx, dx
    jmp game_loop

button1:
    cmp dx, 3
    jz continue2
    jmp game_loop

continue2:
    pop dx
    pop cx
    pop ax
    push ax
    push cx
    push dx

    call save_ellipse
    call snap_ellipse_points
    call load_draw_screen

    mov dx, 3

    jmp game_loop

button2:
    call delete_selected_ellipses
    call load_draw_screen
    jmp game_loop

button3:
    cmp dx, 1
    jz continue3
    jmp game_loop

continue3:
    pop bx
    push bx
    add bx, bx
    mov [area_info + bx + 1], 0
    call load_draw_screen
    jmp game_loop

button4:
    cmp dx, 1
    jz continue1
    jmp game_loop

continue1:
    pop bx
    push bx
    add bx, bx
    mov al, [color]
    mov [area_info + bx], al
    mov [area_info + bx + 1], 1
    mov ax, [mod_x_points + bx]
    mov [x_point], ax
    mov ax, [mod_y_points + bx]
    mov [y_point], ax
    mov ax, 2
    int 33h
    call fill_in
    mov ax, 1
    int 33h
    jmp game_loop

button5:
    inc [scale_factor]
    call update_mod_points
    call load_draw_screen
    jmp game_loop

button6:
    cmp [scale_factor], 1
    jnz zoom_in
    jmp game_loop
zoom_in:
    dec [scale_factor]
    call update_mod_points
    call load_draw_screen
    jmp game_loop

button7:
    call load_colors_screen

wait_for_input:
    call get_mouse_press_info
    test bl, 1
    jz wait_for_input

    cmp [x_point], 240
    ja wait_for_input
    cmp [y_point], 110
    ja wait_for_input

    ; calculate color
    mov [color], 8
    mov ax, [y_point]
    mov bl, 10
    div bl
    mov bl, 24
    mul bl
    add [color], al
    mov ax, [x_point]
    mov bl, 10
    div bl
    add [color], al

    call load_draw_screen
    jmp game_loop

button8:
    cmp dx, 2
    jz continue
    jmp game_loop
continue:
    pop ax
    pop bx
    push bx
    push ax
    call delete_lines
    jmp game_loop

button9:
    call load_draw_screen
    jmp game_loop

button10:
    cmp dx, 1
    ja enough_points
    jmp game_loop
enough_points:
    call save_line
    call draw_bezier_curve
    jmp game_loop

button11:
    push [x_point]
    push [y_point]
    call delete_selected_points
    call delete_deleted_lines
    call delete_deleted_ellipses
    call delete_deleted_areas
    pop [y_point]
    pop [x_point]
    call load_draw_screen
    add sp, dx
    add sp, dx
    xor dx, dx
    jmp game_loop

not_pressed1:

    cmp ax, 2
    jnz not_pressed2
    jmp button2

not_pressed2:

    cmp ax, 3
    jnz not_pressed3
    jmp button3

not_pressed3:

    cmp ax, 4
    jnz not_pressed4
    jmp button4

not_pressed4:

    cmp ax, 5
    jnz not_pressed5
    jmp button5

not_pressed5:

    cmp ax, 6
    jnz not_pressed6
    jmp button6

not_pressed6:

    cmp ax, 7
    jnz not_pressed7
    jmp button7

not_pressed7:

    cmp ax, 8
    jnz not_pressed8
    jmp button8

not_pressed8:
    cmp ax, 9
    jnz not_pressed9
    jmp button9

not_pressed9:
    cmp ax, 10
    jnz not_pressed10
    jmp button10

not_pressed10:
    jmp button11

execute_buttons:
    ; check which button was pressed
    cmp ax, 1
    jnz not_pressed1
    jmp button1

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

    mov ax, 2
    int 33h
    call hide_selected_points
    call move_selected_points
    call snap_ellipse_points
    call update_mod_points
    call draw_saved_points
    mov ax, 1
    int 33h

next:
    pop dx
    pop cx

    call get_mouse_info
    test bl, 1
    jnz move_loop
    pop dx
    call load_draw_screen
    jmp game_loop

move_screen_loop:
    sub cx, [x_point]
    sub dx, [y_point]
    
    push dx

    mov ax, cx
    mov dl, [scale_factor]
    xor dh, dh
    mul dx
    mov cx, ax

    pop dx
    push cx

    mov ax, dx
    mov cl, [scale_factor]
    xor ch, ch
    mul cx
    mov dx, ax

    pop cx

    push [x_point]
    push [y_point]

    mov ax, cx
    or ax, dx
    jz next1

    add [screen_x], cx
    add [screen_y], dx
    mov ax, 2
    int 33h
    call hide_all_points
    call update_mod_points
    call draw_saved_points
    mov ax, 1
    int 33h

next1:
    pop dx
    pop cx

    call get_mouse_info
    test bl, 2
    jnz move_screen_loop
    pop dx
    call load_draw_screen
    jmp game_loop

game_loop:
    call draw_saved_points
    call clear_highlighted_point
    call get_mouse_press_info

    ; update and execute buttons
    call update_buttons
    call draw_buttons

    ; check if pressed buttons
    cmp ax, 0
    jz buttons_not_pressed
    test bx, 1
    jz buttons_not_pressed
    jmp execute_buttons

buttons_not_pressed:

    ; check if on point and get index
    call get_point_at_location
    
    ; variables:

    ; ax = point you are on
    ; bl = pressed info
    ; bh = on point
    ; [x_point] = current x
    ; [y_point] = current y
    ; dx = selected points count
    ; stack = selected points indexes

    ; decision tree:
    ; * = has a lable
    
    ; start:
    ;     pressed right:
    ;         move screen
    ;     not pressed right: *
    ;         clear highlighted
    ;         not pressed: *
    ;             on point:
    ;                 not point selected:
    ;                     set highlighed
    ;         pressed:
    ;             not on point: *
    ;                 not exists selected point: *
    ;                     draw point
    ;                 exists selected point:
    ;                     clear selected
    ;             on point:
    ;                 not point selected: *
    ;                     select point
    ;                 point selected:
    ;                     move selected

    push dx
    mov cx, [x_point]
    mov dx, [y_point]
    test bl, 2
    jz not_pressed_right
    jmp move_screen_loop

not_pressed_right:
    pop dx
    call clear_highlighted_point
    test bl, 1
    jz not_pressed
    
    cmp bh, 0
    jz not_on_point

    mov bx, ax
    add bx, ax
    mov cx, [point_info + bx]
    cmp ch, 3
    jnz not_point_selected

    push dx

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

    add sp, dx
    add sp, dx
    xor dx, dx
    call clear_selected_points

    jmp game_loop

not_exists_selected_point:
    call save_point

    jmp game_loop

not_point_selected:
    push ax
    inc dx
    mov ch, 3
    mov [point_info + bx], cx

    jmp game_loop
END start
