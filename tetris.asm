.MODEL BIG   
.STACK
.DATA  
    LEFT_COL_COR EQU 111 
    RIGHT_COL_COR EQU 211
    UP_ROW_COR EQU 1
    DOWN_ROW_COR EQU 201
     
    NUMBER_OF_BLOCKS_PER_ROW EQU 10
    GAME_MAP DB 210 DUP(0)
    SIZE DW 8
    CURR_ROW DW 0
    CURR_COL DW 0
    CURR_COLOR DB 0
    
    CURR_RAND DW 0
    
    RAND_NUM DW 0
    
    DEST_AVAILABLE DB 0 
     
    
    L_OBJECT_INDEXES DW 0, 10, 20, 21
                     DW 0, 1, 2, 10
                     DW 0, 1, 11, 21
                     DW 0, 8, 9, 10
                     
    FLIPPED_L_OBJECT_INDEXES DW 0, 10, 20, 19
                             DW 0, 10, 11, 12
                             DW 0, 1, 10, 20
                             DW 0, 1, 2, 12
                     
    Z_OBJECT_INDEXES DW 0, 10, 11, 21
                     DW 0, 1, 9, 10
                     DW 0, 10, 11, 21
                     DW 0, 1, 9, 10
                     
    N_OBJECT_INDEXES DW 0, 10, 9, 19
                     DW 0, 1, 11, 12
                     DW 0, 10, 9, 19
                     DW 0, 1, 11, 12
                     
    T_OBJECT_INDEXES DW 0, 1, 2, 11 
                     DW 0, 9, 10, 20
                     DW 0, 9, 10, 11
                     DW 0, 10, 11, 20                                          
                     
    CUBE_OBJECT_INDEXES DW 0, 1, 10, 11
                        DW 0, 1, 10, 11
                        DW 0, 1, 10, 11
                        DW 0, 1, 10, 11
                     
    LINE_OBJECT_INDEXES DW 0, 1, 2, 3
                        DW 0, 10, 20, 30
                        DW 0, 1, 2, 3
                        DW 0, 10, 20, 30 
    IS_ROTATE DW 0
    
    DESTINATION DW 0, 0, 0, 0
    
    ACTIVE_OBJECT DW 0, 0, 0, 0
    
    ACTIVE_OBJECT_PATTERN DW 0
    
    ACTIVE_OBJECT_INDEXES DW 16 DUP(0)
    
    ACTIVE_OBJECT_SRC DW 0
    
    ACTIVE_OBJECT_COLOR DW 0
    
    BLOCK_PLACED DW 0 
    
    SWAP_LINE_INDEX DW 0
    
    CHECKING_LINE DW 0
    
    CLEANED_LINES_NUM DW 0
    
    LINE_FULL DW 0
    
    MILIS DB 0
    
    SCORE DW 0
    
    LOSE DW 0


MACRO PUSH_ALL
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
ENDM

MACRO POP_ALL
    POP DX
    POP CX
    POP BX
    POP AX
ENDM  


GET_RANDOM_NUMBER_BETWEEN MACRO FIRST, SECOND   
    MOV BX, SECOND
    SUB BX, FIRST
    INC BX
    MOV DX, 0
    MOV AX, [CURR_RAND]
    DIV BX
    ADD DX, FIRST
    MOV [RAND_NUM], DX
    CALL REFRESH_CURRENT_RAND
ENDM            

                 

DRAW_SQUARE MACRO X, Y, COLOR  
    LOCAL INTERNAL_LOOP, INTERNAL_LOOP2
    MOV AH, 0CH
    MOV AL, COLOR
    MOV DX, X
INTERNAL_LOOP:
    MOV CX, Y
INTERNAL_LOOP2:
    INT 10H
    INC CX 
    MOV BX, Y
    ADD BX, SIZE
    CMP CX, BX   
    JBE INTERNAL_LOOP2
    INC DX
    MOV BX, X
    ADD BX, SIZE 
    CMP DX, BX
    JBE INTERNAL_LOOP  
ENDM
    
    
GENERATE_BLOCK MACRO OBJECT 
    LOCAL GENERATE_NEXT, DONE_GENERATION, GENERATION_INDEX_FULL, CONTINUE, FIRST_FULL, CONTINUE_FIRST
    MOV BX, [ACTIVE_OBJECT_PATTERN]
    MOV BX, [OBJECT + BX]                        
    ADD BX, [ACTIVE_OBJECT_SRC]
    MOV CX, [ACTIVE_OBJECT_COLOR]
    CMP [GAME_MAP + BX], 0
    JNE  FIRST_FULL          
    MOV [GAME_MAP + BX], CL 
CONTINUE_FIRST:    
    MOV [ACTIVE_OBJECT], BX    
    MOV DX, 2
GENERATE_NEXT:
    CMP DX, 8
    JE  DONE_GENERATION 
    MOV BX, [ACTIVE_OBJECT_PATTERN]
    MOV CX, [OBJECT + BX] 
    ADD BX, DX
    MOV BX, [OBJECT + BX]
    ADD BX, CX
    ADD BX, [ACTIVE_OBJECT_SRC]
    MOV CX, [ACTIVE_OBJECT_COLOR]
    CMP [GAME_MAP + BX], 0
    JNE GENERATION_INDEX_FULL 
    MOV [GAME_MAP + BX], CL
CONTINUE:    
    MOV CX, BX
    MOV BX, DX
    MOV [ACTIVE_OBJECT + BX], CX
    ADD DX, 2
    JMP GENERATE_NEXT
    
GENERATION_INDEX_FULL:
    MOV [LOSE], 1
    JMP CONTINUE
FIRST_FULL:
    MOV [LOSE], 1
    JMP CONTINUE_FIRST
DONE_GENERATION:         
ENDM


MOVE_OBJECT MACRO MOVE_OFFSET
    LOCAL CALCULATE_DEST, DEST_CALCULATED, DEST_UNAVAILABLE, DONE_MOVE, ROTATE, BELOW_32, UPDATE_ROTATE_VALUES, RESET_ACTIVE_OBJECT_PATTERN
    MOV [IS_ROTATE], 0
    MOV AX, MOVE_OFFSET
    CMP AX, 8
    JE ROTATE
    MOV BX, [ACTIVE_OBJECT]
    MOV BX, 0 

CALCULATE_DEST:
    CMP BX, 8                                   
    JE  DEST_CALCULATED 
    MOV AX, [ACTIVE_OBJECT + BX] 
    ADD AX, MOVE_OFFSET
    MOV [DESTINATION + BX], AX 
    ADD BX, 2
    JMP CALCULATE_DEST
    
ROTATE:
    MOV [IS_ROTATE], 1
    MOV AX, [ACTIVE_OBJECT_PATTERN]
    ADD AX, 8
    CMP AX, 32
    JNE BELOW_32
    MOV AX, 0
    
BELOW_32: 
    MOV BX, AX   
    MOV AX, [ACTIVE_OBJECT_SRC]
    ADD AX, [ACTIVE_OBJECT_INDEXES + BX]
    MOV [DESTINATION], AX  
    ADD BX, 2  
    
    MOV AX, [ACTIVE_OBJECT_SRC]
    ADD AX, [ACTIVE_OBJECT_INDEXES + BX]
    MOV [DESTINATION + 2], AX  
    ADD BX, 2 
    
    MOV AX, [ACTIVE_OBJECT_SRC]
    ADD AX, [ACTIVE_OBJECT_INDEXES + BX]
    MOV [DESTINATION + 4], AX  
    ADD BX, 2 
    
    MOV AX, [ACTIVE_OBJECT_SRC]
    ADD AX, [ACTIVE_OBJECT_INDEXES + BX]
    MOV [DESTINATION + 6], AX  
    ADD BX, 2
    
DEST_CALCULATED:
    MOV BX, [ACTIVE_OBJECT]
    MOV [GAME_MAP + BX], 0
     
    MOV BX, [ACTIVE_OBJECT + 2]  
    MOV [GAME_MAP + BX], 0
    
    MOV BX, [ACTIVE_OBJECT + 4]
    MOV [GAME_MAP + BX], 0
    
    MOV BX, [ACTIVE_OBJECT + 6] 
    MOV [GAME_MAP + BX], 0  
      
    CALL CHECK_DEST
    
    CMP [DEST_AVAILABLE], 1
    JNE DEST_UNAVAILABLE
    
    MOV CX, [ACTIVE_OBJECT_COLOR]
    MOV CH ,0
    
    MOV BX, [DESTINATION]
    MOV [ACTIVE_OBJECT], BX
    MOV [GAME_MAP + BX], CL
    
    MOV BX, [DESTINATION + 2]
    MOV [ACTIVE_OBJECT + 2], BX
    MOV [GAME_MAP + BX], CL
    
    MOV BX, [DESTINATION + 4]
    MOV [ACTIVE_OBJECT + 4], BX
    MOV [GAME_MAP + BX], CL
    
    MOV BX, [DESTINATION + 6]
    MOV [ACTIVE_OBJECT + 6], BX
    MOV [GAME_MAP + BX], CL
          
    CMP [IS_ROTATE], 1
    JE  UPDATE_ROTATE_VALUES 
    ADD ACTIVE_OBJECT_SRC, MOVE_OFFSET
    
    JMP DONE_MOVE
    
UPDATE_ROTATE_VALUES:
    MOV AX, [ACTIVE_OBJECT_PATTERN]
    ADD AX, 8        
    CMP AX, 32
    JNE RESET_ACTIVE_OBJECT_PATTERN
    MOV AX, 0
RESET_ACTIVE_OBJECT_PATTERN:   
    MOV [ACTIVE_OBJECT_PATTERN], AX
    
    JMP DONE_MOVE 
    
DEST_UNAVAILABLE: 
    MOV CX, [ACTIVE_OBJECT_COLOR]   
    MOV BX, [ACTIVE_OBJECT]
    MOV [GAME_MAP + BX], CL
     
    MOV BX, [ACTIVE_OBJECT + 2]  
    MOV [GAME_MAP + BX], CL
    
    MOV BX, [ACTIVE_OBJECT + 4]
    MOV [GAME_MAP + BX], CL
    
    MOV BX, [ACTIVE_OBJECT + 6] 
    MOV [GAME_MAP + BX], CL 

DONE_MOVE:
       
ENDM

        
.CODE

MAIN PROC FAR                                        
    MOV AX, @DATA
    MOV DS, AX
    MOV AH,00 ;SET MODE
    MOV AL,13H ;MODE = 13H (CGA Med RESOLUTION)
    INT 10h
    
    CALL INIT_CURRENT_RAND
    
    MOV BX, 200
INIT:
    CMP BX, 210
    JE END_INIT
    MOV [GAME_MAP + BX], 1
    INC BX
    JMP INIT     
END_INIT:
                         
    
    CALL DRAW_BORDER
    CALL GENERATE_NEW_BLOCK
    MOV [BLOCK_PLACED], 0
    
    MOV  AH, 2CH
    INT  21H      ;?�� RETURN SECONDS IN DH.
    MOV  MILIS, DH  ;?�� IF SECONDS ARE THE SAME... 
    
    CALL PRINT_SCORE
MAIN_LOOP: 
    
    MOV AH, 2CH
    INT 21H      ;?�� RETURN SECONDS IN DH.
    MOV DL, MILIS
    CMP DL, DH
    JNE MOVE_DOWN_DELAY 
    
    
    
    CMP [BLOCK_PLACED], 0
    JE NO_NEW_BLOCK 
    CALL CHECK_FULL_LINES
    CALL GENERATE_NEW_BLOCK
    MOV [BLOCK_PLACED], 0
     
NO_NEW_BLOCK:    
    CALL DRAW_MAP
    CALL PRINT_SCORE
    
    CMP [LOSE], 1
    JE END_MAIN_LOOP
    
    MOV AH, 1
    INT 16H
    JZ NO_KEY_PRESSED  
    MOV AH, 0
    INT 16H 
        
    CMP AL, 'W'
    JZ ROTATE_LABEL
    CMP AL, 'w'  
    JZ ROTATE_LABEL
    
    CMP AL, 'A'
    JZ  SHIFT_LEFT_LABEL
    CMP AL, 'a'  
    JZ  SHIFT_LEFT_LABEL
    
    CMP AL, 'S'
    JZ  MOVE_DOWN_LABEL
    CMP AL, 's'  
    JZ  MOVE_DOWN_LABEL
    
    CMP AL, 'D'
    JZ  SHIFT_RIGHT_LABEL
    CMP AL, 'd'  
    JZ  SHIFT_RIGHT_LABEL
              
    CMP AL, 'F'
    JZ  PLACE_LABEL
    CMP AL, 'f'  
    JZ  PLACE_LABEL    
    
    CMP AL, 'Q'
    JE  END_MAIN_LOOP
    CMP AL, 'q'  
    JE  END_MAIN_LOOP
    
    
    
NO_KEY_PRESSED:
    JMP MAIN_LOOP    
    
ROTATE_LABEL:
    CALL ROTATE 
    JMP MAIN_LOOP 
 
SHIFT_LEFT_LABEL:
    CALL SHIFT_LEFT 
    JMP MAIN_LOOP

SHIFT_RIGHT_LABEL:
    CALL SHIFT_RIGHT 
    JMP MAIN_LOOP        
                 
PLACE_LABEL:
    CALL PLACE 
    JMP MAIN_LOOP
    
MOVE_DOWN_LABEL:
    CALL MOVE_DOWN 
    JMP MAIN_LOOP
        
MOVE_DOWN_DELAY:
    MOV  AH, 2CH
    INT  21H      ;?�� RETURN SECONDS IN DH.
    MOV  MILIS, DH  ;?�� IF SECONDS ARE THE SAME...
    CALL MOVE_DOWN
    JMP MAIN_LOOP:                 

END_MAIN_LOOP:    
    MOV AH, 4CH
    INT 21H
    RET
MAIN ENDP

PROC DRAW_BORDER 
    MOV CX,LEFT_COL_COR ;START LINE AT COLUMN =100 AND   
    DEC CX
    MOV DX,UP_ROW_COR ;ROW=5O
    DEC DX
BACK: 
    MOV AH,0CH ;AH=OCH FUNCTION TO SET A PIXEL
    MOV AL, 8 ;PIXELS= LIGHT RED
    INT 10H ;INVOKE INTERRUPT TO SET A PIXEL OF LINE
    INC CX ;INCREMENT HORIZONTAL POSITION
    CMP CX,RIGHT_COL_COR ;DRAW LINE UNTIL COLUMN = 200
    JE NEXT_ROW
    JMP BACK
NEXT_ROW:
    MOV CX,LEFT_COL_COR
    DEC CX
    INC DX
    CMP DX, DOWN_ROW_COR
    JE DRAW_BORDER_FINISH 
    JMP BACK
DRAW_BORDER_FINISH:
RET
        
    
ENDP 
 

PROC ROTATE
    MOVE_OBJECT 8    
    RET
ROTATE ENDP

PROC SHIFT_RIGHT
    MOVE_OBJECT 1  
    RET
SHIFT_RIGHT ENDP

PROC SHIFT_LEFT
    MOVE_OBJECT -1
        RET
SHIFT_LEFT ENDP

PROC MOVE_DOWN    
    PUSH [ACTIVE_OBJECT_SRC]
    MOVE_OBJECT 10
    POP AX
    CMP AX, [ACTIVE_OBJECT_SRC]
    JNE NOT_PLACED
    MOV [BLOCK_PLACED], 1
    NOT_PLACED:  
    RET
MOVE_DOWN ENDP

PROC PLACE
MOVING_DOWN:
    PUSH [ACTIVE_OBJECT_SRC]
    MOVE_OBJECT 10
    POP AX
    CMP AX, [ACTIVE_OBJECT_SRC]
    JNE MOVING_DOWN
    MOV [BLOCK_PLACED], 1  
    RET
PLACE ENDP 


DRAW_MAP PROC  
    MOV BX, 0 
ITERATE:
    MOV DL, [GAME_MAP + BX]
    MOV [CURR_COLOR], DL           
    MOV AX, BX
    MOV CX, NUMBER_OF_BLOCKS_PER_ROW
    MOV DX, 0
    DIV CX
    MOV CX, 10
    MOV [CURR_COL], DX
    MUL CX
    ADD AX, UP_ROW_COR
    MOV [CURR_ROW], AX
    MOV AX, [CURR_COL]
    MUL CX
    ADD AX, LEFT_COL_COR 
    MOV [CURR_COL], AX
    PUSH BX     
    DRAW_SQUARE [CURR_ROW], [CURR_COL], [CURR_COLOR]    
    POP BX          
    INC BX
    CMP BX, 200
    JE END_ITR         
    JMP ITERATE
END_ITR:
    RET    
ENDP

PROC INIT_CURRENT_RAND
    MOV AH, 00h
    INT 1AH
    MOV [CURR_RAND], DX 
    CALL REFRESH_CURRENT_RAND
    RET
ENDP

PROC REFRESH_CURRENT_RAND
    MOV AX, [CURR_RAND]
    MOV DX, 0ABCDH 
    MUL DX
    ADD AX, 0BH 
    MUL DX     
    SHR AX, 1
    MOV [CURR_RAND], AX
    RET 
ENDP

PROC GENERATE_NEW_BLOCK
    
    GET_RANDOM_NUMBER_BETWEEN 3, 6
    MOV AX, [RAND_NUM]
    MOV [ACTIVE_OBJECT_SRC], AX
    GET_RANDOM_NUMBER_BETWEEN 0, 3
    MOV AX, [RAND_NUM]
    MOV BX, 8
    MUL BX
    MOV [ACTIVE_OBJECT_PATTERN], AX
AGAIN:
    GET_RANDOM_NUMBER_BETWEEN 1, 14 
    MOV AX, [RAND_NUM]
    CMP AX, 8
    JE AGAIN
    MOV [ACTIVE_OBJECT_COLOR], AX
         
    GET_RANDOM_NUMBER_BETWEEN 0, 6
    
    CMP [RAND_NUM], 0 
    JE T_BLOCK 
    CMP [RAND_NUM], 1 
    JE L_BLOCK    
    CMP [RAND_NUM], 2 
    JE Z_BLOCK      
    CMP [RAND_NUM], 3 
    JE LINE_BLOCK
    CMP [RAND_NUM], 4 
    JE CUBE_BLOCK
    CMP [RAND_NUM], 5 
    JE FLIPPED_L_BLOCK
    CMP [RAND_NUM], 6 
    JE N_BLOCK
    

T_BLOCK:
    MOV BX, 0
T_UPDATE_INDEXES:
    CMP BX, 32
    JE T_INDEXES_UPDATED
    MOV AX, [T_OBJECT_INDEXES + BX]
    MOV [ACTIVE_OBJECT_INDEXES + BX], AX 
    ADD BX, 2
    JMP T_UPDATE_INDEXES 
T_INDEXES_UPDATED:             
    GENERATE_BLOCK T_OBJECT_INDEXES 
    JMP END_GENERATE
    
L_BLOCK:
    MOV BX, 0
L_UPDATE_INDEXES:
    CMP BX, 32
    JE L_INDEXES_UPDATED
    MOV AX, [L_OBJECT_INDEXES + BX]
    MOV [ACTIVE_OBJECT_INDEXES + BX], AX 
    ADD BX, 2
    JMP L_UPDATE_INDEXES 
L_INDEXES_UPDATED:            
    GENERATE_BLOCK L_OBJECT_INDEXES
    JMP END_GENERATE 
    
FLIPPED_L_BLOCK:
    MOV BX, 0
FLIPPED_L_UPDATE_INDEXES:
    CMP BX, 32
    JE FLIPPED_L_INDEXES_UPDATED
    MOV AX, [FLIPPED_L_OBJECT_INDEXES + BX]
    MOV [ACTIVE_OBJECT_INDEXES + BX], AX 
    ADD BX, 2
    JMP FLIPPED_L_UPDATE_INDEXES 
FLIPPED_L_INDEXES_UPDATED:            
    GENERATE_BLOCK L_OBJECT_INDEXES
    JMP END_GENERATE    
    
    
Z_BLOCK:
    MOV BX, 0
Z_UPDATE_INDEXES:
    CMP BX, 32
    JE Z_INDEXES_UPDATED
    MOV AX, [Z_OBJECT_INDEXES + BX]
    MOV [ACTIVE_OBJECT_INDEXES + BX], AX 
    ADD BX, 2
    JMP Z_UPDATE_INDEXES 
Z_INDEXES_UPDATED:            
    GENERATE_BLOCK Z_OBJECT_INDEXES
    JMP END_GENERATE

N_BLOCK:
    MOV BX, 0
N_UPDATE_INDEXES:
    CMP BX, 32
    JE N_INDEXES_UPDATED
    MOV AX, [N_OBJECT_INDEXES + BX]
    MOV [ACTIVE_OBJECT_INDEXES + BX], AX 
    ADD BX, 2
    JMP N_UPDATE_INDEXES 
N_INDEXES_UPDATED:            
    GENERATE_BLOCK N_OBJECT_INDEXES
    JMP END_GENERATE     
    
LINE_BLOCK:
    MOV BX, 0
LINE_UPDATE_INDEXES:
    CMP BX, 32
    JE LINE_INDEXES_UPDATED
    MOV AX, [LINE_OBJECT_INDEXES + BX]
    MOV [ACTIVE_OBJECT_INDEXES + BX], AX 
    ADD BX, 2
    JMP LINE_UPDATE_INDEXES 
LINE_INDEXES_UPDATED:            
    GENERATE_BLOCK LINE_OBJECT_INDEXES
    JMP END_GENERATE 
    
CUBE_BLOCK:
    MOV BX, 0
CUBE_UPDATE_INDEXES:
    CMP BX, 32
    JE CUBE_INDEXES_UPDATED
    MOV AX, [CUBE_OBJECT_INDEXES + BX]
    MOV [ACTIVE_OBJECT_INDEXES + BX], AX 
    ADD BX, 2
    JMP CUBE_UPDATE_INDEXES 
CUBE_INDEXES_UPDATED:            
    GENERATE_BLOCK CUBE_OBJECT_INDEXES
    JMP END_GENERATE         
END_GENERATE:
    CALL INIT_CURRENT_RAND 
    CALL REFRESH_CURRENT_RAND       
    RET
ENDP
    
    
CHECK_DEST PROC
    MOV BX, 0
CHECK_LEFT_RIGHT:
    PUSH BX
    CMP BX, 8
    JE  LEFT_RIGHT_OKAY 
    MOV DX, 0
    MOV CX, [ACTIVE_OBJECT + BX]
    MOV AX, [DESTINATION + BX]
    MOV BX, 10
    DIV BX
    MOV AX, CX
    MOV CX, DX
    MOV DX, 0
    DIV BX
    SUB DX, CX
    POP BX
    CMP DX, -4
    JE  OK
    CMP DX, 4
    JE  OK
    CMP DX, -3
    JE  OK
    CMP DX, 3
    JE  OK
    CMP DX, -2
    JE  OK
    CMP DX, 2
    JE  OK
    CMP DX, -1
    JE  OK
    CMP DX, 1
    JE  OK
    CMP DX, 0
    JE  OK 
    JMP CANNOT
OK:  
    ADD BX, 2  
    JMP CHECK_LEFT_RIGHT
LEFT_RIGHT_OKAY:
    POP BX    
    MOV BX, [DESTINATION] 
    CMP [GAME_MAP + BX], 0
    JNE CANNOT
    MOV BX, [DESTINATION + 2] 
    CMP [GAME_MAP + BX], 0
    JNE CANNOT    
    MOV BX, [DESTINATION + 4] 
    CMP [GAME_MAP + BX], 0
    JNE CANNOT    
    MOV BX, [DESTINATION + 6] 
    CMP [GAME_MAP + BX], 0    
    JNE CANNOT   
    MOV [DEST_AVAILABLE], 1     
    RET    
CANNOT:
    MOV [DEST_AVAILABLE], 0     
    RET
ENDP  

SWAP_LINE_WITH_ABOVE PROC
    MOV CX, 0
SWAP_LINE_LOOP:
    CMP CX, 10 
    JE LINE_SWAPED
    PUSH CX 
    MOV AX, [SWAP_LINE_INDEX]
    MOV BX, 10
    MUL BX
    ADD AX, CX
    MOV BX, AX
    MOV CH, [GAME_MAP + BX] 
    SUB BX, 10
    MOV DH, [GAME_MAP + BX]     
    MOV [GAME_MAP + BX], CH 
    ADD BX, 10
    MOV [GAME_MAP + BX], DH    
    POP CX
    INC CX
    JMP SWAP_LINE_LOOP                           
LINE_SWAPED:
RET   
ENDP 

     
CHECK_FULL_LINES PROC 
    MOV AX, 19
CHECKING_LINE_LABEL:
    CMP AX, 0 
    JE CHECKED_ALL_LINES
    PUSH_ALL
    MOV [CHECKING_LINE], AX
    CALL CHECK_IF_LINE_FULL
    POP_ALL 
    CMP [LINE_FULL], 1
    JE CLEANING_LINE
    JMP NOT_A_FULL_LINE
CLEANING_LINE:
    PUSH_ALL
    CALL CLEAN_LINE
    INC [CLEANED_LINES_NUM]
    POP_ALL    
LINE_CLEANED:
    MOV CX, AX
SWAPPING:
    CMP CX, 0
    JE DONE_SWAPPING
    MOV [SWAP_LINE_INDEX], CX
    PUSH_ALL
    CALL SWAP_LINE_WITH_ABOVE 
    POP_ALL
    DEC CX
    JMP SWAPPING
NOT_A_FULL_LINE: 
    DEC AX
DONE_SWAPPING: 
    JMP CHECKING_LINE_LABEL
CHECKED_ALL_LINES:

    CMP [CLEANED_LINES_NUM], 1
    JA ADD_20
    JE ADD_10
    JMP SCORES_ADDED
ADD_10:
    ADD [SCORE] , 10
    JMP SCORES_ADDED 
ADD_20:
    MOV AX, [CLEANED_LINES_NUM]
    MOV BX, 20
    MUL BX
    ADD [SCORE], AX 
SCORES_ADDED:
    MOV [CLEANED_LINES_NUM], 0
    RET
ENDP


CHECK_IF_LINE_FULL PROC 
    MOV AX, [CHECKING_LINE]
    MOV DX, 10
    MUL DX
    MOV BX, AX
    MOV CX, 0
CHECK_LINE:
    CMP CX, 10
    JE LINE_FULL_LABEL:
    CMP [GAME_MAP + BX], 0
    JE LINE_NOT_FULL 
    INC BX
    INC CX
    JMP CHECK_LINE
LINE_FULL_LABEL:
    MOV [LINE_FULL], 1
    RET
    
LINE_NOT_FULL:
    MOV [LINE_FULL], 0
    RET
ENDP 


CLEAN_LINE PROC 
    MOV AX, [CHECKING_LINE]
    MOV DX, 10
    MUL DX
    MOV BX, AX
    MOV CX, 0
EMPYT_LINE:
    CMP CX, 10
    JE LINE_EMPTY:
    MOV [GAME_MAP + BX], 0
    INC BX
    INC CX
    JMP EMPYT_LINE
LINE_EMPTY:
    RET
ENDP   


PRINT_SCORE PROC
    MOV AH, 02 ; set cursor option
    MOV BH, 00 ; page 0
    MOV DL, 02
    MOV DH, 02
    INT 10H   
    MOV CX, 0 
    MOV DX, 0
    MOV AX, [SCORE]
    CMP AX, 0 
    JE PRINT_ZERO
PRINTLOOP:   
    CMP AX, 0 
    JE PRINTLOOPFINAL  
    MOV BX, 10   
    DIV BX     
    PUSH DX    
    INC CX      
    MOV DX, 0 
    JMP PRINTLOOP 
PRINTLOOPFINAL:  
    CMP CX, 0 
    JE ENDPROC   
    POP DX 
    ADD DX, 48 
    MOV AH, 02h 
    INT 21h      
    DEC CX 
    JMP PRINTLOOPFINAL
PRINT_ZERO:
    MOV DX, '0' 
    MOV AH, 02h 
    INT 21h   
ENDPROC:
    RET
PRINT_SCORE ENDP


DELAY PROC
    MOV DX, 0FFFFH
    MOV CX, 0FFFFH
OUTER_LOOP:
    DEC DX
    CMP DX, 0
    JE FINISH
DELAY_LOOP:
    LOOP DELAY_LOOP 
    RET
FINISH:
    RET
DELAY ENDP