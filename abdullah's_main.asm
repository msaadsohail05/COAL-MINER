INCLUDE Irvine32.inc

.data

	playerPos BYTE 40					; player's X position b/w 0-79
	
	coalX BYTE 10 DUP(?)
	coalY BYTE 10 DUP(?)				; coal's X and Y positions
	coalActive BYTE 10 DUP(?)

	rockX BYTE 10 DUP(?)
	rockY BYTE 10 DUP(?)				; rocks's X and Y positions
	rockActive BYTE 10 DUP(?)
		
	score DWORD 0
	lives BYTE 3
	gameOver BYTE 0						; game states

	spawnCounter BYTE 0 
	moveCounter BYTE 0					; counters

	gameOverMsg BYTE "Game Over! Press R to restart or Q to quit. Final Score: " ,0
	scoreMsg BYTE "Score: " ,0
	livesMsg BYTE "Lives: " ,0			; messages


.code
	main PROC
		call Randomize
		call InitGame
		call GameLoop
		exit
	main ENDP
	
	InitGame PROC
		call Clrscr
		mov playerPos, 40
		mov score, 0
		mov lives, 3
		mov gameOver, 0
		mov spawnCounter, 0
		mov moveCounter, 0

		mov ecx, 10						; clear object arrays
		mov esi, 0						
		init_objects: 
			mov coalActive[esi], 0
			mov rockActive[esi], 0
			inc esi
		loop init_objects
		ret
	InitGame ENDP


	GameLoop PROC
		MainLoop:
			call ReadInput
			call UpdateGame
			call CheckCollisions
			call Render
			mov eax, 50
			call Delay

			cmp gameOver, 1
			JNE MainLoop

			call GameOverScreen
			ret
	GameLoop ENDP

	ReadInput PROC
		call ReadKey
		JZ NoInput

		cmp al, 'a'						; move left
		JE MoveLeft
		cmp al, 'd'						; move right
		JE MoveRight
		cmp al, 'q'						; quit game
		JE QuitGame
		cmp al, 'r'						; restart game
		JE RestartGame
		JMP NoInput

		MoveLeft:
			cmp playerPos, 1
			JLE NoInput
			dec playerPos
			JMP NoInput

		MoveRight:
			cmp playerPos, 79
			JGE NoInput
			inc playerPos
			JMP NoInput

		QuitGame:
			mov gameOver, 1
			JMP NoInput

		RestartGame:
			call InitGame
			JMP NoInput

		NoInput:
			ret
	ReadInput ENDP

	
	UpdateGame PROC
		inc spawnCounter				; update counters
		inc	moveCounter

		cmp spawnCounter, 10			; spawn new objects at fixed spawn rate of 10 FPS
		JL SkipSpawning
		mov spawnCounter, 0
		call SpawnObjects

		SkipSpawning:
			cmp moveCounter, 5			; move objects at fixed rate of 5 FPS
			JL SkipMoving
			mov moveCounter, 0
			call UpdateCoal
			call UpdateRocks

		SkipMoving:
			ret
	UpdateGame ENDP


	SpawnObjects PROC
		call Random32
		and eax, 0FFh
		cmp eax, 80						; 20% chance to spawn coal
		JGE SkipCoalSpawn

		mov ecx, 10
		mov esi, 0

		FindCoalSlot:
			cmp coalActive[esi], 0
			JE SpawnCoal
			inc esi
		loop FindCoalSlot
		JMP SkipCoalSpawn

		SpawnCoal:
			call GetRandomX
			mov coalX[esi], al
			mov coalY[esi], 1
			mov coalActive[esi], 1

		SkipCoalSpawn:
			call Random32
			and eax, 0FFh
			cmp eax, 128				; 30% chance to spawn rock
			JG SkipRockSpawn

		mov ecx, 10
		mov esi, 0

		FindRockSlot:
			cmp rockActive[esi], 0
			JE SpawnRock
			inc esi
		loop FindRockSlot
		JMP SkipRockSpawn

		SpawnRock:
			call GetRandomX
			mov rockX[esi], al
			mov rockY[esi], 1
			mov rockActive[esi], 1

		SkipRockSpawn:
			ret

	SpawnObjects ENDP


	GetRandomX PROC
		call Random32
		and eax, 7Fh
		cmp eax, 79
		JLE ValidX
		mov eax, 79
		
		ValidX:
			ret
	GetRandomX ENDP


	UpdateCoal PROC
		mov ecx, 10
		mov esi, 0

		CoalLoop:
			cmp coalActive[esi], 1
			JNE NextCoal

			inc coalY[esi]						; mov coal downwards by 1 position

			; remove these lines for troubleshooting improper collision detections
			; cmp coalY[esi], 24					
			; JL NextCoal
			; mov coalActive[esi], 0

			NextCoal:
				inc esi

		loop CoalLoop
		ret
	UpdateCoal ENDP


	UpdateRocks PROC
		mov ecx, 10
		mov esi, 0

		RockLoop:
			cmp rockActive[esi], 1
			JNE NextRock

			inc rockY[esi]						; move rock downwards by 1 pos

			; remove these lines for troubleshooting improper collision detections
			; cmp rockY[esi], 24					
			; JL NextRock
			; mov rockActive[esi], 0

			NextRock:
				inc esi

		loop RockLoop
		ret
	UpdateRocks ENDP


	CheckCollisions PROC						; main thing
		mov ecx, 10
		mov esi, 0
		CoalCollisionCheck:						; check for collision with coal
			cmp coalActive[esi], 1				
			JNE SkipCoalCollision

			mov al, coalX[esi]
			cmp al, playerPos
			JNE SkipCoalCollision

			mov al, coalY[esi]
			cmp al, 24
			JNE SkipCoalCollision

			add score, 10						; coal collected
			mov coalActive[esi], 0

			SkipCoalCollision:
				inc esi
		loop CoalCollisionCheck

		mov ecx, 10
		mov esi, 0
		RockCollisionCheck:						; check for collisions with rocks
			cmp rockActive[esi], 1
			JNE SkipRockCollision
			
			mov al, rockX[esi]
			cmp al, playerPos
			JNE SkipRockCollision

			mov al, rockY[esi]
			cmp al, 24
			JNE SkipRockCollision

			dec lives							; rock hits player
			mov rockActive[esi], 0

			cmp lives, 0						; check for game over
			JG SkipRockCollision
			mov gameOver, 1

			SkipRockCollision:
				inc esi
		loop RockCollisionCheck

		call CleanUpObjects
		ret
	CheckCollisions ENDP

	CleanUpObjects PROC
		mov ecx, 10
		mov esi, 0
		CleanCoalLoop:
			cmp coalActive[esi], 1
			JNE NextCleanCoal
			mov al, coalY[esi]
			cmp al, 25
			JL NextCleanCoal
			mov coalActive[esi], 0
			NextCleanCoal:
				inc esi
		loop CleanCoalLoop

		mov ecx, 10
		mov esi, 0
		CleanRockLoop:
			cmp rockActive[esi], 1
			JNE NextCleanRock
			mov al, rockY[esi]
			cmp al, 25
			JL NextCleanRock
			mov rockActive[esi], 0
			NextCleanRock:
				inc esi
		loop CleanRockLoop
		
		ret
	CleanUpObjects ENDP


	Render PROC
		call Clrscr

		mov dh, 0								; display score in HUD
		mov dl, 0
		call Gotoxy
		mov edx, OFFSET scoreMsg
		call writeString
		mov eax, score
		call WriteDec

		mov dl, 20								; display remaining health in HUD
		call Gotoxy
		mov edx, OFFSET livesMsg
		call WriteString
		mov al, lives
		call WriteDec

		mov dl, playerPos						; display player as 'P'
		mov dh, 24
		call Gotoxy
		mov al, 'P'
		call WriteChar

		mov ecx, 10
		mov esi, 0
		DrawCoal:
			cmp coalActive[esi], 1				; draw falling coal as 'c'
			JNE SkipCoalDraw
			mov dl, coalX[esi]
			mov dh, coalY[esi]
			call Gotoxy
			mov al, 'c'
			call WriteChar
			SkipCoalDraw:
				inc esi
		loop DrawCoal

		mov ecx, 10
		mov esi, 0
		DrawRocks:
			cmp rockActive[esi], 1
			JNE SkipRockDraw
			mov dl, rockX[esi]
			mov dh, rockY[esi]
			call Gotoxy
			mov al, 'R'							; draw falling rocks as 'R'
			call WriteChar

			SkipRockDraw:
				inc esi
		loop DrawRocks
		ret
	Render ENDP


	GameOverScreen PROC
		call Clrscr
		mov dh, 12
		mov dl, 25
		call Gotoxy
		mov edx, OFFSET gameOverMsg
		call WriteString
		mov eax, score
		call writeDec

		WaitForInput:
			call ReadKey
			cmp al, 'r'
			JE RestartGame
			cmp al, 'q'
			JE ExitGame
		JMP WaitForInput

		RestartGame:
			call InitGame
			call GameLoop

		ExitGame:
			ret
	GameOverScreen ENDP

	END main
