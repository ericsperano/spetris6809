*******************************************************************************
* Tetris for my Color Computer 3                                              *
*******************************************************************************
                ORG     $3F00
Start           JSR     SaveVideoRAM            ; save video ram to restore on exit
                JSR     ClearScreen
                JSR     DrawInfo
                JSR     DrawNextPiece
                JSR     DrawField
GetKey          JSR     [POLCAT]                ; Polls keyboard 
                BEQ     GetKey                  ; Loop back if nothing
                JSR     RestoreVideoRAM         ; Cleanup and end execution
*******************************************************************************
ClearScreen     LDY     #VideoRAM               ; Y points to the real video ram
                LDA     #32                     ; space char
csLoop1         STA     ,Y+                     ; Put A in video ram
                CMPY    #$600                   ; End of video ram?
                BNE     csLoop1                 ; Loop if more to display
                RTS
*******************************************************************************               
DrawField       LDY     #VideoRAM               ; Y points to the real video ram
                LDX     #Field                  ; X points to the intro text
dfLoop1         LDB     #FieldWidth
dfLoop2         LDA     ,X+                     ; Load in A the byte to display
                STA     ,Y+                     ; Put A in video ram
                DECB                            ; Decrement counter of chars to display
                BNE     dfLoop2                 ; Loop if more to display for this row
                TFR     Y,D 
                ADDD    #(32-FieldWidth)
                TFR     D,Y
                CMPY    #$600                   ; End of video ram?
                BNE     dfLoop1                 ; Loop if more to display
                RTS
*******************************************************************************               
DrawInfo        LDY     #(VideoRAM+FieldWidth)  ; Y points to the real video ram
                LDX     #Info                   ; X points to the intro text
diLoop1         LDB     #(32-FieldWidth)
diLoop2         LDA     ,X+                     ; Load in A the byte to display
                STA     ,Y+                     ; Put A in video ram
                DECB                            ; Decrement counter of chars to display
                BNE     diLoop2                 ; Loop if more to display for this row
                TFR     Y,D 
                ADDD    #FieldWidth
                TFR     D,Y
                CMPY    #$60C                   ; End of video ram?
                BNE     diLoop1                 ; Loop if more to display
                RTS
*******************************************************************************
DrawNextPiece   LDY     #(VideoRAM+(32*5)+FieldWidth+2)
                LDX     #Pieces
dnLoop1         LDB     #4
dnLoop2         LDA     ,X+
                STA     ,Y+
                DECB
                BNE     dnLoop2
                TFR     Y,D
                ADDD    #28                
                TFR     D,Y
                CMPY    #(VideoRAM+(32*10)+FieldWidth+2)
                BNE     dnLoop1
                RTS
*******************************************************************************
SaveVideoRAM    LDY     #VideoRAM       ; Y points to the real video ram
                LDX     VideoRAMBuffer  ; X points to the saved buffer video ram
LoopSaveVRAM    LDA     ,Y+             ; Load in A the real video byte
                STA     ,X+             ; And store it in the saved buffer
                CMPY    #$600           ; At the end of the video ram?
                BNE     LoopSaveVRAM
                RTS
*******************************************************************************
RestoreVideoRAM LDY     #VideoRAM       ; Y points to the real video ram
                LDX     VideoRAMBuffer  ; X points to the saved buffer video ram
LoopRestoreVRAM LDA     ,X+             ; Load in A the saved video byte
                STA     ,Y+             ; And put in in real video ram
                CMPY    #$600           ; At the end of the video ram?
                BNE     LoopRestoreVRAM
                RTS
*******************************************************************************
FieldWidth      EQU     12
*FieldHeigth     EQU     10
VideoRAM        EQU     $400                    ; video ram address
POLCAT	        EQU	    $A000	                ; read keyboard ROM routine
*SGCHAR          EQU     128+(16*(IntroColor-1)) ; base semi graphic char
KeyUp		    EQU	$5E		                    ; UP key
KeyDown		    EQU	$0A		                    ; DOWN key
*VideoRAMMenu    EQU     VideoRAM+(7*32) ; first line of the menu in the video ram          
* Intro
*IntroLength     EQU     5*32            ; intro chars length (what is displayed before the menu)
*IntroColor      EQU     1               ; intro color
* Menu
*TotalMenu       EQU     4               ; entries in the menu
*******************************************************************************
Pieces          FCC     /..X...X...X...X./
                FCC     /..X..XX...X...../
                FCC     /.....XX..XX...../
                FCC     /..X..XX..X....../
                FCC     /.X...XX...X...../
                FCC     /.X...X...XX...../
                FCC     /..X...X..XX...../
Field           FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /#          #/
                FCC     /############/
Info            FCC     /                    /
                FCC     /  SCORE:            /
                FCC     /                    /
                FCC     /  NEXT PIECE:       /
                FCC     /                    /
                FCC     /                    /
                FCC     /                    /
                FCC     /                    /
                FCC     /                    /
                FCC     /                    /
                FCC     /                    /
                FCC     /  UP ARROW: ROTATE  /
                FCC     /                    /
                FCC     /                    /
                FCC     /                    /
                FCC     /                    /
VideoRAMBuffer  FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /
                FCC     /                                /




*                JSR     DisplayIntro    ; display the big coco 3 thing above the menu          
* always clear the var for second execution                
*                CLR     MenuChoice      
*MainLoop        JSR     DisplayMenu
*GetKey          JSR     [POLCAT]        ; Polls keyboard 
*                BEQ     GetKey          ; Loop back if nothing
*        	CMPA	#KeyUp		; if UP key
*		BEQ	PressUp
*		CMPA	#KeyDown	; if DOWN key
*		BEQ	PressDown
*                CMPA    #KeyEnter       ; if ENTER Key
*                BEQ     PressEnter
*                JMP     GetKey          ; Loop back if anything else
*PressUp         LDA     MenuChoice      ; Do nothing if already at first entry
*                BEQ     GetKey
*                DECA                    ; We can decrement
*                STA     MenuChoice      ; Store for future use
*                JMP     MainLoop        ; Back to top of main loop
*PressDown       LDA     MenuChoice      ; Comparing with total so we need to increment first
*                INCA
*                CMPA    #TotalMenu      ; Do nothing if already at last entry
*                BEQ     GetKey       
*                STA     MenuChoice      ; We're not so we can store 
*                JMP     MainLoop        ; Back to top of main loop
*PressEnter      JSR     RestoreVideoRAM ; Cleanup and end execution
*                LDA     #0              ; Clear the A part of D
*                LDB     MenuChoice
*                INCB                    ; so first is 1
*                JSR     $B4F4           ; Convert D for BASIC
*                RTS
* DisplayIntro Subroutine
* Displays the big Coco 3 thing and the message underneath, before the menu
*DisplayIntro    LDY     #VideoRAM       ; Y points to the real video ram
*                LDX     #TextIntro      ; X points to the intro text
*                LDB     #IntroLength    ; B has the count of chars to display
*LoopIntro1      LDA     ,X+             ; Load in A the byte to display
*                STA     ,Y+             ; Put A in video ram
*                DECB                    ; Decrement counter of chars to display
*                BNE     LoopIntro1      ; Loop if more to display
*                LDA     #$20            ; If not, we'll paste the rest of video ram with $20
*LoopIntro2      STA     ,Y+             
*                CMPY    #$600           ; End of video ram?
*                BNE     LoopIntro2      ; No keep erasing                             
*                RTS
* DisplayMenu Subroutine
*
*DisplayMenu     LDY     #VideoRAMMenu   ; Y points to the real video ram menu location
*                CLR     MenuCount       ; Clear the counter
*                LDB     #0              ; Start with first entry
*LDispMenu1      LDX     #Menu           ; X points to the first entry of the menu
*                CLR     MenuSub         ; Clear the var use to display inverted or not
*                CMPB    MenuChoice      ; Is the current entry the selected one
*                BEQ     DispMulB        ; Yes, we won't need to sub
*                LDA     #64             ; Will subtract that when we'll display
*                STA     MenuSub                
*DispMulB        LSLB                    ; Multiply by 2 because adrs are on 2 bytes
*                ABX
*                LDX     ,X              ; X now to the current menu item to display
*                LDB     #32             ; Display the next 32 chars in X
*LDispMenu2      LDA     ,X+             ; Load in A the char to display
*                SUBA    MenuSub         ; Remove 0 or 64
*                STA     ,Y+             ; Put the char in video ram
*                DECB                    ; Decrement counter of chars to display
*                BNE     LDispMenu2      ; Loop if more to display
*                LDB     MenuCount       ; Increment menu counter
*                INCB    
*                STB     MenuCount
*                CMPB    #TotalMenu      ; Have we reached total?
*                BNE     LDispMenu1      ; No, keep displaying
*                RTS
*******************************
*** Variables and Constants ***
*******************************
*                        123456789012
*MenuSub         FCB     0
*MenuCount       FCB     0
*MenuChoice      FCB     0
*Menu            FDB     LBasic 
*                FDB     LSDCExplorer
*                FDB     LOS9L2
*                FDB     LNitrOS
*LBasic          FCC     /EXTENDED`BASIC``````````````````/
*LSDCExplorer    FCC     /SDC`EXPLORER````````````````````/
*LOS9L2          FCC     /OS/
*                FDB     $6D79
*                FCC     /`LEVEL`/
*                FCB     $72
*                FCC     /````````````````````/
*LNitrOS         FCC     /NITROS/
*                FCB     $79
*                FCC     /`````````````````````````/
*TextIntro       FCB     SGCHAR+6        ; C
*                FCB     SGCHAR+12
*                FCB     SGCHAR+9
*                FCB     SGCHAR
*                FCB     SGCHAR+6        ; O
*                FCB     SGCHAR+12
*                FCB     SGCHAR+9
*                FCB     SGCHAR
*                FCB     SGCHAR+6        ; C
*                FCB     SGCHAR+12
*                FCB     SGCHAR+9
*                FCB     SGCHAR
*                FCB     SGCHAR+6        ; O
*                FCB     SGCHAR+12
*                FCB     SGCHAR+9
*                FCB     SGCHAR
*                FCC     /512/
*                FDB     $0B90           ; K
*                FDB     $1201           ; RA
*                FDB     $0D90           ; M
*                FDB     $2D90           ; -
*                FDB     $0E05           ; NE
*                FDB     $1314           ; ST 
*                FDB     $0F12           ; OR
*                FCB     $90
*                FDB     $1605           ; VE           
*                FDB     $1213           ; RS
*                FDB     $090F           ; IO
*                FDB     $0E90           ; N
*                FCC     /0.1      /
                END     Start