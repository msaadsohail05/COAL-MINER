; =========================================================
; Coal Miner Rescue - FINAL VERSION (Colored + Level Transitions + Faster per Level)
; Team: Taha (lead), Abdullah, Saad
; =========================================================
INCLUDE Irvine32.inc
.386
.STACK 4096
; -------------------------
; Constants
; -------------------------
MAXROCKS = 10
MAXCOAL = 6
SCRWIDTH = 80
SCRHEIGHT = 25
.DATA
playerX BYTE 40
playerY BYTE 23
score DWORD 0
lives DWORD 3
level DWORD 1
baseDelay DWORD 300 ; Starting delay (higher = slower)
currentDelay DWORD 300 ; Will decrease with levels
fallSpeed BYTE 1 ; How many rows fall per frame (increases per level)
rockX BYTE MAXROCKS DUP(0)
rockY BYTE MAXROCKS DUP(0)
rockActive BYTE MAXROCKS DUP(0)
coalX BYTE MAXCOAL DUP(0)
coalY BYTE MAXCOAL DUP(0)
coalActive BYTE MAXCOAL DUP(0)
batX BYTE 10
batY BYTE 5
batDX BYTE 1
batDY BYTE 1
lineBuffer BYTE SCRWIDTH DUP(' '), 0
introStr BYTE "COAL MINER RESCUE - Press any key to start",0
controlsStr BYTE "Use ARROW KEYS to move. Collect GREEN 'o' (coal). Avoid RED '#' & MAGENTA 'B'. ESC to quit.",0
gameOverStr BYTE "GAME OVER! Press R to restart or ESC to quit.",0
finalScoreStr BYTE "Final Score: ",0
finalLivesStr BYTE "Lives Left: ",0
finalLevelStr BYTE "Level Reached: ",0
scoreLbl BYTE "Score: ",0
livesLbl BYTE "Lives: ",0
levelLbl BYTE "Level: ",0
levelUpMsg1 BYTE " LEVEL UP! ",0
levelUpMsg2 BYTE " LEVEL ",0
levelUpMsg3 BYTE " Get Ready! ",0
.CODE
; -------------------------
; Show Level Transition Screen
; -------------------------
ShowLevelTransition PROC
    push eax
    push edx
    call Clrscr
    mov dh, 10
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET levelUpMsg1
    mov eax, 14
    call SetTextColor
    call WriteString
    mov dh, 12
    mov dl, 30
    call Gotoxy
    mov edx, OFFSET levelUpMsg2
    call WriteString
    mov eax, level
    call WriteDec
    mov dh, 14
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET levelUpMsg3
    call WriteString
    mov eax, 1800
    call Delay
    pop edx
    pop eax
    ret
ShowLevelTransition ENDP
; -------------------------
; Update Level & Speed
; -------------------------
UpdateLevelIfNeeded PROC
    push eax
    push ebx
    mov eax, score
    mov ebx, 50
    xor edx, edx
    div ebx
    inc eax ; level = (score / 50) + 1
    cmp eax, level
    jle no_level_up
    mov level, eax
    ; Increase falling speed (max 5)
    mov al, fallSpeed
    cmp al, 5
    jae speed_max
    inc al
    mov fallSpeed, al
speed_max:
    ; Decrease delay (faster game loop) - minimum 80ms
    mov eax, currentDelay
    sub eax, 35
    cmp eax, 80
    jge set_delay
    mov eax, 80
set_delay:
    mov currentDelay, eax
    call ShowLevelTransition
no_level_up:
    pop ebx
    pop eax
    ret
UpdateLevelIfNeeded ENDP
; -------------------------
; Random
; -------------------------
GetRandom PROC
    mov eax, SCRWIDTH
    call RandomRange
    ret
GetRandom ENDP
; -------------------------
; Init Game
; -------------------------
InitGame PROC
    call Clrscr
    call Randomize
    mov playerX, 40
    mov playerY, 23
    mov score, 0
    mov lives, 3
    mov level, 1
    mov baseDelay, 300
    mov currentDelay, 300
    mov fallSpeed, 1
    mov batX, 10
    mov batY, 5
    mov batDX, 1
    mov batDY, 1
    ; Clear rocks & coal
    mov ecx, MAXROCKS
    xor ebx, ebx
clear_rocks:
    mov rockActive[ebx], 0
    inc ebx
    loop clear_rocks
    mov ecx, MAXCOAL
    xor ebx, ebx
clear_coal:
    mov coalActive[ebx], 0
    inc ebx
    loop clear_coal
    ; Spawn initial objects
    mov ecx, 5
spawn_init_rocks:
    call SpawnRock
    loop spawn_init_rocks
    mov ecx, 3
spawn_init_coal:
    call SpawnCoal
    loop spawn_init_coal
    ret
InitGame ENDP
SpawnRock PROC
    push ebx
    push ecx
    xor ebx, ebx
    mov ecx, MAXROCKS
find_slot_rock:
    cmp rockActive[ebx], 0
    je found_rock
    inc ebx
    loop find_slot_rock
    jmp done_rock
found_rock:
    call GetRandom
    mov rockX[ebx], al
    mov rockY[ebx], 0
    mov rockActive[ebx], 1
done_rock:
    pop ecx
    pop ebx
    ret
SpawnRock ENDP
SpawnCoal PROC
    push ebx
    push ecx
    xor ebx, ebx
    mov ecx, MAXCOAL
find_slot_coal:
    cmp coalActive[ebx], 0
    je found_coal
    inc ebx
    loop find_slot_coal
    jmp done_coal
found_coal:
    call GetRandom
    mov coalX[ebx], al
    mov coalY[ebx], 0
    mov coalActive[ebx], 1
done_coal:
    pop ecx
    pop ebx
    ret
SpawnCoal ENDP
; -------------------------
; Update Entities
; -------------------------
UpdateEntities PROC
    push eax
    push ebx
    push ecx
    ; === FALLING OBJECTS (speed increases with level) ===
    movzx ecx, fallSpeed
fall_loop:
    push ecx
    ; Rocks
    mov ecx, MAXROCKS
    xor ebx, ebx
rock_move:
    cmp rockActive[ebx], 0
    je NEAR PTR next_rock_move
    mov al, rockY[ebx]
    inc al
    mov rockY[ebx], al
    cmp al, 24
    jb NEAR PTR rock_ok
    mov rockActive[ebx], 0
    call SpawnRock
    jmp NEAR PTR next_rock_move
rock_ok:
    cmp al, playerY
    jne NEAR PTR next_rock_move
    mov al, rockX[ebx]
    cmp al, playerX
    jne NEAR PTR next_rock_move
    dec lives
    mov rockActive[ebx], 0
    call SpawnRock
next_rock_move:
    inc ebx
    loop rock_move
    ; Coal
    mov ecx, MAXCOAL
    xor ebx, ebx
coal_move:
    cmp coalActive[ebx], 0
    je NEAR PTR next_coal_move
    mov al, coalY[ebx]
    inc al
    mov coalY[ebx], al
    cmp al, 24
    jb NEAR PTR coal_ok
    mov coalActive[ebx], 0
    call SpawnCoal
    jmp NEAR PTR next_coal_move
coal_ok:
    cmp al, playerY
    jne NEAR PTR next_coal_move
    mov al, coalX[ebx]
    cmp al, playerX
    jne NEAR PTR next_coal_move
    add score, 10
    call UpdateLevelIfNeeded
    mov coalActive[ebx], 0
    call SpawnCoal
next_coal_move:
    inc ebx
    loop coal_move
    pop ecx
    dec ecx
    jnz NEAR PTR fall_loop
    ; === BAT MOVEMENT ===
    mov al, batX
    add al, batDX
    cmp al, 1
    jl NEAR PTR bounce_left
    cmp al, 76
    jg NEAR PTR bounce_right
    mov batX, al
    jmp NEAR PTR check_y_bat
bounce_left:
    mov batDX, 1
    mov batX, 1
    jmp NEAR PTR check_y_bat
bounce_right:
    mov batDX, -1
    mov batX, 76
check_y_bat:
    mov al, batY
    add al, batDY
    cmp al, 2
    jl NEAR PTR bounce_top
    cmp al, 22
    jg NEAR PTR bounce_bottom
    mov batY, al
    jmp NEAR PTR bat_done
bounce_top:
    mov batDY, 1
    mov batY, 2
    jmp NEAR PTR bat_done
bounce_bottom:
    mov batDY, -1
    mov batY, 22
bat_done:
    ; Bat collision
    mov al, batX
    cmp al, playerX
    jne NEAR PTR no_bat_hit
    mov al, batY
    cmp al, playerY
    jne NEAR PTR no_bat_hit
    dec lives
    mov score, 0
    mov batX, 40
    mov batY, 5
no_bat_hit:
    pop ecx
    pop ebx
    pop eax
    ret
UpdateEntities ENDP
; -------------------------
; Render Frame (Colored!)
; -------------------------
RenderFrame PROC
    push eax
    call Clrscr
    ; Rocks - RED
    mov esi, 0
    mov ecx, MAXROCKS
draw_rocks:
    cmp rockActive[esi], 0
    je next_rock
    mov dl, rockX[esi]
    mov dh, rockY[esi]
    call Gotoxy
    mov eax, 4
    call SetTextColor
    mov al, '#'
    call WriteChar
next_rock:
    inc esi
    loop draw_rocks
    ; Coal - GREEN
    mov esi, 0
    mov ecx, MAXCOAL
draw_coal:
    cmp coalActive[esi], 0
    je next_coal
    mov dl, coalX[esi]
    mov dh, coalY[esi]
    call Gotoxy
    mov eax, 2
    call SetTextColor
    mov al, 'o'
    call WriteChar
next_coal:
    inc esi
    loop draw_coal
    ; Bat - MAGENTA
    mov dl, batX
    mov dh, batY
    call Gotoxy
    mov eax, 13
    call SetTextColor
    mov al, 'B'
    call WriteChar
    ; Player - BLUE
    mov dl, playerX
    mov dh, playerY
    call Gotoxy
    mov eax, 1
    call SetTextColor
    mov al, 'M'
    call WriteChar
    ; HUD - WHITE
    mov eax, 7
    call SetTextColor
    mov dl, 0
    mov dh, 24
    call Gotoxy
    mov edx, OFFSET scoreLbl
    call WriteString
    mov eax, score
    call WriteDec
    mov edx, OFFSET livesLbl
    call WriteString
    mov eax, lives
    call WriteDec
    mov edx, OFFSET levelLbl
    call WriteString
    mov eax, level
    call WriteDec
    pop eax
    ret
RenderFrame ENDP
; -------------------------
; Input Handling
; -------------------------
ReadInput PROC
    call ReadKey
    jz no_key
    cmp al, 1Bh
    je esc_pressed
    cmp ah, 48h
    je up
    cmp ah, 50h
    je down
    cmp ah, 4Bh
    je left
    cmp ah, 4Dh
    je right
    jmp no_key
up:
    cmp playerY, 1
    jle no_key
    dec playerY
    jmp no_key
down:
    cmp playerY, 22
    jge no_key
    inc playerY
    jmp no_key
left:
    cmp playerX, 1
    jle no_key
    dec playerX
    jmp no_key
right:
    cmp playerX, 78
    jge no_key
    inc playerX
    jmp no_key
esc_pressed:
    mov lives, 0
no_key:
    ret
ReadInput ENDP
; -------------------------
; Main Game Loop
; -------------------------
GameLoop PROC
main_loop:
    call ReadInput
    cmp lives, 0
    jle game_over
    ; Random spawn
    call Random32
    and eax, 31
    cmp eax, 3
    jb spawn_rock
    cmp eax, 8
    jb spawn_coal
spawn_rock:
    call SpawnRock
spawn_coal:
    call SpawnCoal
    call UpdateEntities
    call RenderFrame
    mov eax, currentDelay
    call Delay
    jmp main_loop
game_over:
    call Clrscr
    mov eax, 12
    call SetTextColor
    mov edx, OFFSET gameOverStr
    call WriteString
    call Crlf
    mov eax, 7
    call SetTextColor
    mov edx, OFFSET finalScoreStr
    call WriteString
    mov eax, score
    call WriteDec
    call Crlf
    mov edx, OFFSET finalLivesStr
    call WriteString
    mov eax, lives
    call WriteDec
    call Crlf
    mov edx, OFFSET finalLevelStr
    call WriteString
    mov eax, level
    call WriteDec
    call Crlf
wait_key:
    call ReadKey
    jz wait_key
    cmp al, 'r'
    je restart
    cmp al, 'R'
    je restart
    cmp al, 1Bh
    je quit_game
    jmp wait_key
restart:
    call InitGame
    jmp main_loop
quit_game:
    ret
GameLoop ENDP
; -------------------------
; WaitForKey
; -------------------------
WaitForKey PROC
wfk_loop:
    call ReadKey
    jz wfk_loop
    ret
WaitForKey ENDP
; -------------------------
; Main
; -------------------------
main PROC
    call Clrscr
    mov eax, 14
    call SetTextColor
    mov edx, OFFSET introStr
    call WriteString
    call Crlf
    mov eax, 7
    call SetTextColor
    mov edx, OFFSET controlsStr
    call WriteString
    call Crlf
    call WaitForKey
    call InitGame
    call GameLoop
    exit
main ENDP
END main
