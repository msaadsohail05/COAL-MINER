INCLUDE Irvine32.inc
.model flat, stdcall
.STACK 4096
; -------------------------
; Constants
; -------------------------
MAXROCKS = 10
MAXCOAL = 6
SCRWIDTH = 80
SCRHEIGHT = 25
PLAYERROW = 23 ; row where player stands
.DATA
playerX BYTE 40
playerY BYTE 23
score DWORD 0
lives DWORD 3
level DWORD 1
delayMS DWORD 500
rockX BYTE MAXROCKS DUP(0)
rockY BYTE MAXROCKS DUP(0)
rockActive BYTE MAXROCKS DUP(0)
coalX BYTE MAXCOAL DUP(0)
coalY BYTE MAXCOAL DUP(0)
coalActive BYTE MAXCOAL DUP(0)
batX BYTE 10
batY BYTE 5
BAT_SPEED = 2
batDX  BYTE 1      ; horizontal velocity  (+1 or -1)
batDY  BYTE 1      ; vertical velocity    (+1 or -1)

batDir SBYTE 1
lineBuffer BYTE SCRWIDTH DUP(' ')
lineTerm BYTE 0
introStr BYTE "COAL MINER RESCUE - Press any key to start",0
controlsStr BYTE "Use LEFT/RIGHT/UP/DOWN arrows to move. Collect 'o' (coal). Avoid '#' (rocks) and 'B' (bat). ESC to quit.",0
gameOverStr BYTE "GAME OVER! Press R to restart or ESC to quit.",0
finalScoreStr BYTE "Final Score: ",0
finalLivesStr BYTE "Lives Remaining: ",0
finalLevelStr BYTE "Level Reached: ",0
scoreLbl BYTE "Score: ",0
livesLbl BYTE "Lives: ",0
levelLbl BYTE "Level: ",0
.CODE
; -------------------------
; Random number generator
; -------------------------
GetRandom PROC
    mov eax, SCRWIDTH
    call RandomRange  ; returns 0 to 79 in eax
    ret
GetRandom ENDP
; -------------------------
; Convert integer to decimal string
; -------------------------
IntToDec PROC
    push ebx
    push ecx
    push edx
    push esi
    lea esi, lineBuffer
    mov ecx, 0
    cmp eax, 0
    jne itd_loop_start
    mov byte ptr [esi], '0'
    inc esi
    mov byte ptr [esi], 0
    jmp itd_done
itd_loop_start:
    xor ecx, ecx
itd_div:
    xor edx, edx
    mov ebx, 10
    div ebx
    add dl, '0'
    push dx
    inc ecx
    cmp eax, 0
    jne itd_div
itd_pop:
    pop dx
    mov [esi], dl
    inc esi
    dec ecx
    jnz itd_pop
    mov byte ptr [esi], 0
itd_done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
IntToDec ENDP
; -------------------------
; Clear screen
; -------------------------
ClearScreen PROC
    call Clrscr
    ret
ClearScreen ENDP
; -------------------------
; Initialize game
; -------------------------
InitGame PROC
    call ClearScreen
    call Randomize
    mov byte ptr playerX, 40
    mov dword ptr score, 0
    mov dword ptr lives, 3
    mov dword ptr level, 1
    mov dword ptr delayMS, 250
    mov byte ptr batX, 10
    mov byte ptr batY, 5
    mov byte ptr batDir, 1
    ; Deactivate rocks
    mov ecx, MAXROCKS
    xor ebx, ebx
init_rocks:
    mov byte ptr rockActive[ebx], 0
    mov byte ptr rockX[ebx], 0
    mov byte ptr rockY[ebx], 0
    inc ebx
    loop init_rocks
    ; Deactivate coal
    mov ecx, MAXCOAL
    xor ebx, ebx
init_coal:
    mov byte ptr coalActive[ebx], 0
    mov byte ptr coalX[ebx], 0
    mov byte ptr coalY[ebx], 0
    inc ebx
    loop init_coal
    mov ecx, 5
init_spawn_rocks:
    call SpawnRock
    loop init_spawn_rocks
    mov ecx, 3
init_spawn_coal:
    call SpawnCoal
    loop init_spawn_coal
    ret
InitGame ENDP
; -------------------------
; Spawn rock
; -------------------------
SpawnRock PROC
    push ebx
    push ecx
    xor ebx, ebx
    mov ecx, MAXROCKS
sr_loop:
    mov al, rockActive[ebx]
    cmp al, 0
    jne sr_next
    call GetRandom
    mov rockX[ebx], al
    mov byte ptr rockY[ebx], 0
    mov byte ptr rockActive[ebx], 1
    jmp sr_done
sr_next:
    inc ebx
    loop sr_loop
sr_done:
    pop ecx
    pop ebx
    ret
SpawnRock ENDP
; -------------------------
; Spawn coal
; -------------------------
SpawnCoal PROC
    push ebx
    push ecx
    xor ebx, ebx
    mov ecx, MAXCOAL
sc_loop:
    mov al, coalActive[ebx]
    cmp al, 0
    jne sc_next
    call GetRandom
    mov coalX[ebx], al
    mov byte ptr coalY[ebx], 0
    mov byte ptr coalActive[ebx], 1
    jmp sc_done
sc_next:
    inc ebx
    loop sc_loop
sc_done:
    pop ecx
    pop ebx
    ret
SpawnCoal ENDP
; -------------------------
; Update entities (rocks, coal, bat)
; -------------------------
UpdateEntities PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    ; Rocks
    mov ecx, MAXROCKS
    xor ebx, ebx
rocks_upd:
    mov al, rockActive[ebx]
    cmp al, 0
    je rskip
    mov al, rockY[ebx]
    inc al
    mov rockY[ebx], al
    mov al, rockY[ebx]
    cmp al, playerY
    jb rskip
    je rcheck_collision
    ; > PLAYERROW
    mov byte ptr rockActive[ebx], 0
    call SpawnRock
    jmp rskip
rcheck_collision:
    mov al, rockY[ebx]
    cmp al, playerY
    jne rno_hit
    mov al, rockX[ebx]
    mov dl, playerX
    cmp al, dl
    jne rno_hit
    mov eax, lives
    sub eax, 1
    mov lives, eax
rno_hit:
    mov byte ptr rockActive[ebx], 0
    call SpawnRock
rskip:
    inc ebx
    loop rocks_upd
    ; Coal
    mov ecx, MAXCOAL
    xor ebx, ebx
coal_upd:
    mov al, coalActive[ebx]
    cmp al, 0
    je cskip
    mov al, coalY[ebx]
    inc al
    mov coalY[ebx], al
    mov al, coalY[ebx]
    cmp al, playerY
    jb cskip
    je ccheck_collect
    ; > PLAYERROW
    mov byte ptr coalActive[ebx], 0
    call SpawnCoal
    jmp cskip
ccheck_collect:
    mov al, coalY[ebx]
    cmp al, playerY
    jne cno_collect
    mov al, coalX[ebx]
    mov dl, playerX
    cmp al, dl
    jne cno_collect
    mov eax, score
    add eax, 10
    mov score, eax
    call UpdateLevelIfNeeded
cno_collect:
    mov byte ptr coalActive[ebx], 0
    call SpawnCoal
cskip:
    inc ebx
    loop coal_upd
; -----------------------------------------------------
; BAT COLLISION WITH PLAYER
; -----------------------------------------------------
mov al, batY
cmp al, playerY
jne bat_col_end

mov al, batX
cmp al, playerX
jne bat_col_end

; ---- HIT! ----
mov eax, lives
dec eax
mov lives, eax

mov eax, score
cmp eax, 20
jl bat_score_zero
sub eax, 20
jmp bat_score_store

bat_score_zero:
mov eax, 0

bat_score_store:
mov score, eax

; optional bat reset
mov byte ptr batX, 10
mov byte ptr batY, 5

bat_col_end:

; -----------------------------------------------------
;  BAT – FULL DIAGONAL RANDOM MOVEMENT
; -----------------------------------------------------

; Randomly change direction sometimes
call Random32
and eax, 0Fh        ; 1-in-16 chance
cmp eax, 0
jne bat_keep_dir

; Flip horizontal direction
mov al, batDX
neg al
mov batDX, al

; Flip vertical direction
mov al, batDY
neg al
mov batDY, al

bat_keep_dir:

; -----------------------------------------------------
; MOVE HORIZONTALLY
; -----------------------------------------------------
mov al, batX
add al, batDX       ; new X = X + DX

; check boundary
cmp al, 1
jl bat_bounce_left

cmp al, SCRWIDTH-3
jg bat_bounce_right

mov batX, al
jmp bat_x_done

bat_bounce_left:
mov byte ptr batDX, 1
mov batX, 1
jmp bat_x_done

bat_bounce_right:
mov byte ptr batDX, -1
mov batX, SCRWIDTH-3

bat_x_done:

; -----------------------------------------------------
; MOVE VERTICALLY
; -----------------------------------------------------
mov al, batY
add al, batDY       ; new Y = Y + DY

cmp al, 2
jl bat_bounce_top

cmp al, SCRHEIGHT-3
jg bat_bounce_bottom

mov batY, al
jmp bat_y_done

bat_bounce_top:
mov byte ptr batDY, 1
mov batY, 2
jmp bat_y_done

bat_bounce_bottom:
mov byte ptr batDY, -1
mov batY, SCRHEIGHT-3

bat_y_done:


    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
UpdateEntities ENDP
; -------------------------
; Level update
; -------------------------
UpdateLevelIfNeeded PROC
    push eax
    push ebx
    mov eax, score
    mov ebx, 100
    xor edx, edx
    div ebx
    inc eax
    mov ebx, level
    cmp eax, ebx
    jle ul_done
    mov level, eax
    mov eax, delayMS
    sub eax, 50
    cmp eax, 100
    jge ul_set
    mov eax, 100
ul_set:
    mov delayMS, eax
ul_done:
    pop ebx
    pop eax
    ret
UpdateLevelIfNeeded ENDP
; -------------------------
; Rendering
; -------------------------
RenderFrame PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    ;call Clrscr
    xor bl, bl
render_row_loop:
    lea edi, lineBuffer
    mov ecx, SCRWIDTH
fill_spaces:
    mov byte ptr [edi], ' '
    inc edi
    dec ecx
    jnz fill_spaces
    mov byte ptr [edi], 0
    mov dl, bl
    ; Rocks
    mov esi, 0
    mov ecx, MAXROCKS
rock_place:
    mov al, rockActive[esi]
    cmp al, 0
    je rp_next
    mov al, rockY[esi]
    cmp al, dl
    jne rp_next
    mov al, rockX[esi]
    movzx eax, al
    lea edi, lineBuffer
    add edi, eax
    mov byte ptr [edi], '#'
rp_next:
    inc esi
    loop rock_place
    ; Coal
    mov esi, 0
    mov ecx, MAXCOAL
coal_place:
    mov al, coalActive[esi]
    cmp al, 0
    je cp_next
    mov al, coalY[esi]
    cmp al, dl
    jne cp_next
    mov al, coalX[esi]
    movzx eax, al
    lea edi, lineBuffer
    add edi, eax
    mov byte ptr [edi], 'o'
cp_next:
    inc esi
    loop coal_place
    ; Bat
    mov al, batY
    cmp al, dl
    jne skip_bat_place
    mov al, batX
    movzx eax, al
    lea edi, lineBuffer
    add edi, eax
    mov byte ptr [edi], 'B'
skip_bat_place:
    ; Player
    mov al, playerY
    cmp al, dl
    jne skip_player
    mov al, playerX
    movzx eax, al
    lea edi, lineBuffer
    add edi, eax
    mov byte ptr [edi], 'M'
skip_player:
    mov dl, 0
    mov dh, bl
    call Gotoxy
    lea edx, lineBuffer
    call WriteString
    inc bl
    cmp bl, 24
    jnb short skip_loop
    jmp near ptr render_row_loop
skip_loop:
    ; HUD
    mov dl, 0
    mov dh, 24
    call Gotoxy
    mov edx, OFFSET scoreLbl
    call WriteString
    mov eax, score
    call IntToDec
    mov edx, OFFSET lineBuffer
    call WriteString
    mov al, ' '
    call WriteChar
    mov edx, OFFSET livesLbl
    call WriteString
    mov eax, lives
    call IntToDec
    mov edx, OFFSET lineBuffer
    call WriteString
    mov al, ' '
    call WriteChar
    mov edx, OFFSET levelLbl
    call WriteString
    mov eax, level
    call IntToDec
    mov edx, OFFSET lineBuffer
    call WriteString
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
RenderFrame ENDP
; -------------------------
; Wait for key press (blocking)
; -------------------------
WaitForKey PROC
wfk_loop:
    call ReadKey
    jz wfk_loop
    ret
WaitForKey ENDP
; -------------------------
; Input (non-blocking)
; -------------------------
ReadInput PROC
    call ReadKey
    jz ri_done
    cmp al, 0
    jne ri_normal
    ; extended key
    cmp ah, 48h  ; up arrow
    je ri_up
    cmp ah, 50h  ; down arrow
    je ri_down
    cmp ah, 4Bh  ; left arrow
    je ri_left
    cmp ah, 4Dh  ; right arrow
    je ri_right
    jmp ri_done
ri_normal:
    cmp al, 1Bh  ; ESC
    je ri_exit
    jmp ri_done
ri_up:
    mov al, playerY
    cmp al, 1
    jle ri_done
    dec al
    mov playerY, al
    jmp ri_done
ri_down:
    mov al, playerY
    cmp al, SCRHEIGHT-2
    jge ri_done
    inc al
    mov playerY, al
    jmp ri_done
ri_left:
    mov al, playerX
    cmp al, 1
    jle ri_done
    sub al, 1
    mov playerX, al
    jmp ri_done
ri_right:
    mov al, playerX
    cmp al, SCRWIDTH-2
    jge ri_done
    add al, 1
    mov playerX, al
    jmp ri_done
ri_exit:
    mov dword ptr lives, 0
ri_done:
    ret
ReadInput ENDP
; -------------------------
; Delay
; -------------------------
GameDelay PROC
    mov eax, delayMS
    call Delay
    ret
GameDelay ENDP
; -------------------------
; Main game loop
; -------------------------
GameLoop PROC
main_loop:
    call ReadInput
    mov eax, lives
    cmp eax, 0
    jle game_over
    call GetRandom
    cmp al, 24
    jae gs_skip1
    call SpawnRock
gs_skip1:
    call GetRandom
    cmp al, 30
    jae gs_skip2
    call SpawnCoal
gs_skip2:
    call UpdateEntities
    call RenderFrame
    call GameDelay
    jmp main_loop
game_over:
    call Clrscr

    ; --- PRINT GAME OVER LINE ---
    mov edx, OFFSET gameOverStr
    call WriteString
    call Crlf

    ; --- PRINT FINAL SCORE ---
    mov edx, OFFSET finalScoreStr
    call WriteString
    mov eax, score
    call IntToDec
    mov edx, OFFSET lineBuffer
    call WriteString
    call Crlf

    ; --- PRINT FINAL LIVES ---
    mov edx, OFFSET finalLivesStr
    call WriteString
    mov eax, lives
    call IntToDec
    mov edx, OFFSET lineBuffer
    call WriteString
    call Crlf

    ; --- PRINT FINAL LEVEL ---
    mov edx, OFFSET finalLevelStr
    call WriteString
    mov eax, level
    call IntToDec
    mov edx, OFFSET lineBuffer
    call WriteString
    call Crlf

go_wait:
    call WaitForKey
    cmp al, 'r'
    je restart_game
    cmp al, 'R'
    je restart_game
    cmp al, 1Bh
    je exit_game
    jmp go_wait

restart_game:
    call InitGame
    jmp main_loop
exit_game:
    ret
GameLoop ENDP
; -------------------------
; Main
; -------------------------
main PROC
    call Clrscr
    mov edx, OFFSET introStr
    call WriteString
    call Crlf
    mov edx, OFFSET controlsStr
    call WriteString
    call Crlf
    call WaitForKey
    call InitGame
    call GameLoop
    exit
main ENDP
END main
