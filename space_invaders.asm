.model small

.data

;Variables
  ;Sniper
  sniperX db 40
  sniperY db 23

  ;Enemies
  enemiesX db 6, 14, 22, 30, 38
  enemiesY db 4, 4, 4, 4, 4
  enemiesCount db 5
  movingVar db 1

  ;Bullet
  bulletX db 0
  bulletY db 0
  BulletMovingVar db, 0

  ;Strings
  ending_text db 10, "                                   GAME OVER!$"
  ending_press_key  db 10, "                               PRESS ESC TO EXIT$"

.stack 100h

.code

start:
  mov ax,@data
  mov ds,ax

  ;Initialization
  call clear
  call hide_cursor

next:
  call clear
  call game_status
  call print_sniper
  call print_enemies
  call print_bullet
  call delay
  call move_bullet
  call check_bullet_hit
  call move_enemies
  call wait_key

  ;Escape button pressed
  cmp al, 27
  je fin

  ;Left arrow pressed
  cmp al, 75
  je sniper_check_left

  ;Right arrow pressed
  cmp al, 77
  je sniper_check_right

  ;Space key pressed
  cmp al, 32
  je bullet_start_moving

  ;Continue waiting for key press
  jmp next

sniper_check_left:
  cmp sniperX, 2
  jle next
  jmp move_player_left

sniper_check_right:
  cmp sniperX, 78
  jge next
  jmp move_player_right

move_player_left:
  sub sniperX, 2
  jmp next

move_player_right:
  add sniperX, 2
  jmp next

bullet_start_moving:
  call move_bullet_start
  jmp next

fin:
  mov ah,4ch
  int 21h


;Procedures
print_sniper proc
  mov ah, 2
  mov dl, sniperX
  mov dh, sniperY
  int 10h

  mov ah, 2
  mov dx, '_'
  int 21h

  ret
print_sniper endp

print_enemies proc
  mov cx, 0
  mov cl, enemiesCount
  mov bx, 0

  print_enemies_loop:
    ;Check if enemy is killed
    cmp enemiesX[bx], -1
    je print_enemies_next
    cmp enemiesY[bx], -1
    je print_enemies_next

    mov ah, 2
    mov dl, enemiesX[bx]
    mov dh, enemiesY[bx]
    int 10h

    mov ah, 2
    mov dx, '0'
    int 21h

  print_enemies_next:
    add bx, 1
    loop print_enemies_loop

  ret
print_enemies endp

print_bullet proc
  ;Check if bullet is not on screen
  cmp bulletX, -1
  jne bullet_print
  jmp finish_bullet_print

  bullet_print:
    mov ah, 2
    mov dl, bulletX
    mov dh, bulletY
    int 10h

    mov ah, 2
    mov dx, '|'
    int 21h

  finish_bullet_print:
    ret
print_bullet endp

move_enemies proc
  mov cl, enemiesCount
  mov bx, 0
  mov ax, 0
  mov dx, 0

  ;Looping enemies to check whether borders are touched
	reverse_check_loop:
    ;Check if enemy is killed
    cmp enemiesY[bx], -1
    je reverse_check_next
    cmp enemiesX[bx], -1
    je reverse_check_next

	  cmp enemiesX[bx], 2
	  jle add_counter_reverse

	  cmp enemiesX[bx], 77
	  jge add_counter_reverse

    ;Move to next if not out of borders
    jmp reverse_check_next

	add_counter_reverse:
	  add al, 1

	reverse_check_next:
	  add bx, 1
	  loop reverse_check_loop


  ;Check whether borders were touched
  ;If borders were touched - reverse enemies direction and move them down
  ;If not - move enemies normally
	cmp al, 0
  jg call_reverse
	jmp add_enemies_x

  ;Reverse enemies and move down if borders were touched
	call_reverse:
	  call reverse_enemies

  ;Add x to enemies if borders were not touched
  add_enemies_x:
    mov cx, 0
	  mov cl, enemiesCount
	  mov bx, 0

  add_enemies_loop:
    ;Check if enemy is killed
    cmp enemiesX[bx], -1
    je add_enemies_next
    cmp enemiesY[bx], -1
    je add_enemies_next

  add_enemy_x:
    mov dl, movingVar
    add enemiesX[bx], dl

	add_enemies_next:
    add bx, 1
    loop add_enemies_loop

  ret
move_enemies endp

reverse_enemies proc
  mov cx, 0
  mov cl, enemiesCount
  mov bx, 0
  neg movingVar

  reverse_enemies_loop:
    ;Check if enemy is killed
    cmp enemiesX[bx], -1
    je reverse_enemies_next
    cmp enemiesY[bx], -1
    je reverse_enemies_next

    add enemiesY[bx], 1

  reverse_enemies_next:
    add bx, 1
    loop reverse_enemies_loop

  ret
reverse_enemies endp

move_bullet_start proc
  mov ah, 2
  mov dl, sniperX
  mov dh, sniperY
  int 10h

  mov bulletX, dl
  mov bulletY, dh
  mov BulletMovingVar, 1

  ret
move_bullet_start endp

move_bullet proc
  ;Remove bullet if it reaches the top of the screen
  cmp bulletY, 0
  jle call_remove
  jmp move_bullet_up

  call_remove:
    call remove_bullet
    jmp finish_move_bullet

  move_bullet_up:
    mov bl, BulletMovingVar
    sub bulletY, bl

  finish_move_bullet:
    ret
move_bullet endp

check_bullet_hit proc
  ;Check if bullet is not displayed
  cmp bulletY, -1
  je finish_check_hit
  cmp bulletX, -1
  je finish_check_hit

  mov ah, 2
  mov dh, bulletY
  mov dl, bulletX
  int 10h

  ;Check character at cursor position
  mov ah, 8
  int 10h
  cmp al, '0'
  je remove_on_hit
  jmp finish_check_hit

  remove_on_hit:
    mov bx, 0
    mov cx, 0
    mov cl, enemiesCount

  colission_remove_loop:
    cmp enemiesX[bx], dl
    jne colission_remove_next

    cmp enemiesY[bx], dh
    jne colission_remove_next

  remove_collision:
    mov enemiesY[bx], -1
    mov enemiesX[bx], -1
    call remove_bullet

  colission_remove_next:
    add bx, 1
    loop colission_remove_loop

  finish_check_hit:
    ret
check_bullet_hit endp

remove_bullet proc
  mov bulletX, -1
  mov bulletY, -1
  mov BulletMovingVar, 0

  ret
remove_bullet endp

game_status proc
  call check_enemies_dead
  call check_line_reach

  ret
game_status endp

check_enemies_dead proc
  mov ax, 0
  mov bx, 0
  mov cx, 0
  mov cl, enemiesCount

  check_dead_loop:
    ;Check if enemy is killed
    cmp enemiesX[bx], -1
    jne check_dead_next

    cmp enemiesY[bx], -1
    jne check_dead_next

  check_dead_counter:
    add al, 1

  check_dead_next:
    add bx, 1
    loop check_dead_loop

  ;Check if all enemies are killed
  cmp al, enemiesCount
  je finish_game_dead
  jmp finish_check_dead

  finish_game_dead:
    call ending_screen

  finish_check_dead:
    ret
check_enemies_dead endp

check_line_reach proc
  mov ax, 0
  mov bx, 0
  mov cx, 0
  mov cl, enemiesCount

  line_reach_loop:
    cmp enemiesY[bx], 20
    je add_counter
    jmp line_reach_next

  add_counter:
    add al, 1

  line_reach_next:
    add bx, 1
    loop line_reach_loop

  ;Check if all enemies are killed
  cmp al, 0
  jg finish_game_reach
  jmp finish_line_reach

  finish_game_reach:
    call ending_screen

  finish_line_reach:
    ret
check_line_reach endp

ending_screen proc
  call clear
  call print_ending_screen

  ;Wait for escape key to be pressed
  ending_screen_loop:
    call wait_key
    cmp al, 27
    je exit_program
    jmp ending_screen_loop

  exit_program:
    mov ah, 4ch
    int 21h
ending_screen endp

print_ending_screen proc
  mov ah, 2
  mov dh, 5
  int 10h

  mov ah, 9
  mov dx, offset ending_text
  int 21h

  mov ah, 2
  mov dh, 15
  int 10h

  mov ah, 9
  mov dx, offset ending_press_key
  int 21h

  ret
print_ending_screen endp

wait_key proc
  push cx
  push dx
  push bx
  mov ah, 6
  mov dl, 0ffh
  int 21h
  pop bx
  pop dx
  pop cx
  ret
wait_key endp

hide_cursor	proc
  mov ah, 1
  mov ch, 1
  mov cl, 0
  int 10h
  ret
hide_cursor	endp

clear	proc
  push ax
  push cx
  push dx
  push bx

  mov ah,6
  mov al,25
  mov ch,0
  mov cl,0
  mov dh,24
  mov dl,79
  mov bh,00011111b
  int 10h

  pop bx
  pop dx
  pop cx
  pop ax
  ret
clear	endp

delay	proc
  push dx
  push ax
  push bx
  push cx

  mov ah,0
  int 1ah
  mov bx,dx
  add bx,2

  repeat:
    int 1ah
    cmp dx,bx
    jl repeat

  pop cx
  pop bx
  pop ax
  pop dx

  ret
delay	endp

end start
