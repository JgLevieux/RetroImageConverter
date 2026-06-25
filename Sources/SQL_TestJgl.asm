
;CLEAR_SCREEN	equ		1
;DATA_CUBE	equ		1
;DATA_LOGO		equ		1
DATA_OLIPIX	equ		1
;DATA_RPUO		equ		1

ScreenMode01	equ		%00001000
ScreenMode02	equ		%10001000
COLOR_WHITE     equ     7
COLOR_RED		equ		3

SCREEN_WIDTH    equ     128             ; Largeur d'une ligne d'écran en octets
	ifd DATA_CUBE
NUM_VERTICES    equ     8               ; Nombre de sommets du cube
NUM_EDGES       equ     12              ; Nombre d'arêtes du cube
	endif

	ifd DATA_LOGO
NUM_VERTICES    equ     20              ; Nombre de sommets du logo
NUM_EDGES       equ     12              ; Nombre d'arêtes du logo
	endif

	ifd DATA_OLIPIX
NUM_VERTICES    equ     20              ; Nombre de sommets du logo
NUM_EDGES       equ     14              ; Nombre d'arêtes du logo
	endif

	ifd DATA_RPUO
NUM_VERTICES    equ     19              ; Nombre de sommets du logo
NUM_EDGES       equ     16              ; Nombre d'arêtes du logo
	endif

COLOR_BLACK     equ     0               ; Couleur noire
num_sprites equ 30
step_x      equ 1
step_y      equ 3
speed_x     equ 2
speed_y     equ 5

Start:
				lea     NbLoop,a0
                move.l  #0,(a0)

                trap    #0              ; Appel QDOS pour basculer en mode Superviseur
                ori.w   #$0700,sr       ; Coupe TOUTES les interruptions matérielles (Masque à 7)

				lea		top_of_stack,a0
				move.l	a0,sp				

                movem.l d0-d7/a0-a6,-(sp)

				move.b	#ScreenMode01,$18063

				lea		ScreenBase,a0
				move.l	#$28000,(a0)
				bsr     ClearScreen
				bsr		DrawOlipixLines
				
				lea		ScreenBase,a0
				move.l	#$20000,(a0)
				bsr     ClearScreen
				bsr		DrawOlipixLines

				move.l	#$28000,(a0)					; Init draw in screen 2 to swap directly to 1

				lea		Projected,a1
				lea		Projected1,a2
				move.l	a2,(a1)
                bsr     RotateAndProject
MainLoop:

.frame_loop:
				jsr		waitVBlank
				
				lea		ScreenBase,a0
				lea		Projected,a1
				move.l	(a0),d0
				cmp.l	#$20000,d0
				beq.s	.swapscreen1
				
				move.l	#$20000,(a0)					; Draw in screen 1
				move.b	#ScreenMode02,$18063			; Display screen 2
				lea		Projected1,a2					; Use data buffer 1
				move.l	a2,(a1)

				; --- evolution de l'animation ---
                lea     globalphasex,a0
				addi.b  #speed_x,(a0)

                lea     globalphasey,a0
				addi.b  #speed_y,(a0)


				
				bra.s	.swapscreen2
.swapscreen1:
				move.l	#$28000,(a0)					; Draw in screen 2
				move.b	#ScreenMode01,$18063			; Display screen 1
				lea		Projected2,a2					; Use data buffer 2
				move.l	a2,(a1)
.swapscreen2:
				lea     NbPlotPixel,a0
                move.l  #0,(a0)

				lea     NbLoop,a0
				add.l	#1,(a0)

	ifd CLEAR_SCREEN
				bsr		ClearScreen
	else
				; Clear all pixel from previous frame
				lea     PlotPixelBlack,a0
                lea     PlotPixelAdr,a1
				move.l	a0,(a1)
				;bsr     DrawEdges
	endif
                ; Update angles
                lea     AngleX,a0
                lea     AngleY,a1
                addq.w  #1,(a0)
                andi.w  #63,(a0)
                addq.w  #3,(a1)
                andi.w  #63,(a1)

                ; Rotate and project
                ;bsr     RotateAndProject
                
				; Draw everything
				lea     PlotPixelWhite,a0
                lea     PlotPixelAdr,a1
				move.l	a0,(a1)
                ;bsr     DrawEdges
				
				bsr		compute3dsinus

				;jmp		MainLoop

; Test affichage sprite
	;ifd DEP

				;lea     NbLoop,a0
				;move.l	(a0),d0
				;lsr.l	#1,d0 			; divise par 2 pour bouger une frame sur deux pour écriure ds les deux buffers
				
				lea		ScreenBase,a0
				move.l	(a0),a1
				lea		Sprite,a0

				move.l	#16,d0
				move.l	#16,d1
				bsr		DisplaySprite8x8Masked

				move.l	#20,d0
				move.l	#16,d1
				bsr		DisplaySprite8x8Masked

				move.l	#32,d0
				move.l	#32,d1
				bsr		DisplaySprite8x8Masked
				;bsr		WaitAnyKey
				jmp		MainLoop

                movem.l (sp)+,d0-d7/a0-a6
                rts                     ; Retour à SuperBASIC ou au moniteur
				
; =============================================================================
; Display a sprite, 8x8 with shifting
; d0 = x
; d1 = y
; a0 = sprite base
; a1 = screen base
; =============================================================================
DisplaySprite8x8Masked:
                movem.l d0-d7/a0-a6,-(sp)
				move.l	d0,d3
				lsr.l	#2,d0			; divise par 4, 4 pixels pour 1 word.
				lsl.l	#1,d0			; mul par 2 car c'est des word.
				lsl.l	#7,d1			; y*128
				add.l	d1,a1			; +y screen
				add.l	d0,a1			; +x screen
						
				and.l	#3,d3			; garde 2 bits pour shifting (0-3)
				move.l	d3,d2		
				lsl.l	#6,d3			; *64
				lsl.l	#5,d2			; *32
				add.l	d3,d2			; *96

				add.l	d2,a0			; a0 = sprite
				move.l	a0,a2
				lea		48(a2),a2		; a2 = mask
MASK	equ		1
		rept 8	; lines
	ifd MASK
			rept 3 ; words
				move.w	(a1),d0			; Get the pixels on the screen
				and.w	(a2)+,d0		; Apply sprite mask
				or.w	(a0)+,d0		; Apply sprite color
				move.w	d0,(a1)+		; Write final pixel
			endr

	else
			rept 3
				move.w	(a0)+,(a1)+
			endr
	endif
				
				lea		122(a1),a1
		endr
                movem.l (sp)+,d0-d7/a0-a6
				rts
	;endif



; =============================================================================
; Wait VBL
; =============================================================================
waitVBlank:
	move.b #%11111111,$18021	;Clear interrupt flags
waitVBlankAgain
	move.b $18021,d0			;See if interrupt has occurred
	tst.b d0
	beq waitVBlankAgain
	rts


; =============================================================================
; 
; =============================================================================
compute3dsinus:
				moveq	#0,d5
				moveq	#0,d6
				moveq	#0,d3
				moveq	#0,d0
				moveq	#0,d1

                lea     ScreenBase,a0
                move.l  (a0),a4

				lea     sintable2,a6

                lea     globalphasex,a0
				move.b  (a0),d5

                lea     globalphasey,a0
				move.b  (a0),d6

				move.w  #num_sprites-1,d7

.loop_sprites:
				; --- calcul de l'axe x ---
				move.b  (a6,d5.w),d0
				addi.w  #128,d0

				; --- calcul de l'axe y ---
				move.b  (a6,d6.w),d1
				addi.w  #128,d1

				;bsr		PlotPixelWhite ; Entrée : d0=X, d1=Y, a4=ScreenBase ; Détruit les registres : d2, a0
				lea		ScreenBase,a0
				move.l	(a0),a1
				lea		Sprite,a0

				;move.l	#16,d0
				;move.l	#16,d1
				bsr		DisplaySprite8x8Masked


				; --- creation de l'effet 3d ---
				lea     NbLoop,a5
				move.l	(a5),d4
				and.l	#1,d4
				beq.s	.noadd
				
				addi.b  #step_x,d5
				addi.b  #step_y,d6
.noadd:
				dbra    d7,.loop_sprites

				rts
globalphasex: dc.b 128
globalphasey: dc.b 0
    even
sintable2:
	dc.b 0,2,4,7,9,11,13,15,18,20,22,24,26,28,30,32
    dc.b 34,36,38,40,42,44,46,48,50,52,54,55,57,59,60,62
    dc.b 64,65,67,68,70,71,72,74,75,76,77,78,79,80,81,82
    dc.b 83,84,85,85,86,87,87,88,88,89,89,89,90,90,90,90
    dc.b 90,90,90,90,90,89,89,89,88,88,87,87,86,85,85,84
    dc.b 83,82,81,80,79,78,77,76,75,74,72,71,70,68,67,65
    dc.b 64,62,60,59,57,55,54,52,50,48,46,44,42,40,38,36
    dc.b 34,32,30,28,26,24,22,20,18,15,13,11,9,7,4,2
    dc.b 0,-2,-4,-7,-9,-11,-13,-15,-18,-20,-22,-24,-26,-28,-30,-32
    dc.b -34,-36,-38,-40,-42,-44,-46,-48,-50,-52,-54,-55,-57,-59,-60,-62
    dc.b -64,-65,-67,-68,-70,-71,-72,-74,-75,-76,-77,-78,-79,-80,-81,-82
    dc.b -83,-84,-85,-85,-86,-87,-87,-88,-88,-89,-89,-89,-90,-90,-90,-90
    dc.b -90,-90,-90,-90,-90,-89,-89,-89,-88,-88,-87,-87,-86,-85,-85,-84
    dc.b -83,-82,-81,-80,-79,-78,-77,-76,-75,-74,-72,-71,-70,-68,-67,-65
    dc.b -64,-62,-60,-59,-57,-55,-54,-52,-50,-48,-46,-44,-42,-40,-38,-36
    dc.b -34,-32,-30,-28,-26,-24,-22,-20,-18,-15,-13,-11,-9,-7,-4,-2
	
; =============================================================================
; Rotation et Projection des Sommets
; =============================================================================
RotateAndProject:
                movem.l d0-d7/a0-a5,-(sp)

				bsr		AnimateZoom

				lea 	AngleX,a2
				lea 	AngleY,a3
				lea 	SinX,a4
				lea 	CosX,a5

                ; Récupération du Sinus/Cosinus pour l'angle Y
                move.w  (a3),d0
                bsr     GetSinCos
                move.w  d1,(a4)         ; d1 = Sin(Y)
                move.w  d2,(a5)         ; d2 = Cos(Y)

                ; Récupération du Sinus/Cosinus pour l'angle X
                move.w  AngleX,d0
                bsr     GetSinCos
                move.w  d1,(a4)         ; d1 = Sin(X)
                move.w  d2,(a5)         ; d2 = Cos(X)

                lea     Vertices,a0     ; Table des sommets initiaux (X, Y, Z)
                lea     Projected,a1    ; Table de destination (ScreenX, ScreenY)
				move.l	(a1),a1
                move.w  #NUM_VERTICES-1,d7

.loop_points:
                ; Charger les coordonnées d'origine
                move.w  (a0)+,d0        ; d0 = X
                move.w  (a0)+,d1        ; d1 = Y
                move.w  (a0)+,d2        ; d2 = Z

                ; --- Rotation autour de l'axe Y (Angles 8.8) ---
                ; X' = (X * CosY - Z * SinY) / 256
                ; Z' = (X * SinY + Z * CosY) / 256
                move.w  d0,d3           ; d3 = X
                move.w  d2,d4           ; d4 = Z

                muls    (a5),d0         ; d0 = X * CosY
                muls    (a4),d2         ; d2 = Z * SinY
                sub.l   d2,d0           ; d0 = X*CosY - Z*SinY
                asr.l   #8,d0           ; Échelle 8.8 -> entier

                muls    (a4),d3         ; d3 = X * SinY
                muls    (a5),d4         ; d4 = Z * CosY
                add.l   d4,d3           ; d3 = X*SinY + Z*CosY
                asr.l   #8,d3           ; d3 = Z'

                move.w  d3,d2           ; d2 = Z' (Y reste dans d1)

                ; --- Rotation autour de l'axe X ---
                ; Y' = (Y * CosX - Z' * SinX) / 256
                ; Z'' = (Y * SinX + Z' * CosX) / 256
                move.w  d1,d3           ; d3 = Y
                move.w  d2,d4           ; d4 = Z'

                muls    (a5),d1         ; d1 = Y * CosX
                muls    (a4),d2         ; d2 = Z' * SinX
                sub.l   d2,d1           ; d1 = Y*CosX - Z'*SinX
                asr.l   #8,d1           ; d1 = Y'

                muls    (a4),d3         ; d3 = Y * SinX
                muls    (a5),d4         ; d4 = Z' * CosX
                add.l   d4,d3           ; d3 = Y*SinX + Z'*CosX
                asr.l   #8,d3           ; d3 = Z''

                move.w  d3,d2           ; d2 = Z''

                ; --- Projection Perspective 3D -> 2D ---
                ; ScreenX = CenterX + (X' * Distance) / (Z'' + OffsetZ)
                ; ScreenY = CenterY - (Y' * Distance) / (Z'' + OffsetZ)
                addi.w  #150,d2         ; OffsetZ
                ble.s   .clip_point

                ; Chargement du niveau de zoom dynamique
                move.w  ZoomLevel(PC),d3

                ; --- Calcul de ScreenX ---
                ext.l   d0
                muls    d3,d0           ; X' * ZoomLevel (Remplace lsl.l #7,d0)
                divs    d2,d0
                addi.w  #128,d0         ; CenterX

                ; --- Calcul de ScreenY ---
                ext.l   d1
                muls    d3,d1           ; Y' * ZoomLevel (Remplace lsl.l #7,d1)
                divs    d2,d1
                move.w  #128,d4         ; CenterY (Utilise d4 car d3 contient ZoomLevel)
                sub.w   d1,d4
                move.w  d4,d1
                bra.s   .store

.clip_point:
                moveq   #0,d0
                moveq   #0,d1

.store:
                move.w  d0,(a1)+        ; Stocker ScreenX
                move.w  d1,(a1)+        ; Stocker ScreenY

                dbf     d7,.loop_points

                movem.l (sp)+,d0-d7/a0-a5
                rts


; =============================================================================
; Dessin des Arêtes (Edges)
; =============================================================================
DrawEdges:
                movem.l d0-d4/a0-a2,-(sp)

                lea     Edges,a0
                lea     Projected,a1
				move.l	(a1),a1
                move.w  #NUM_EDGES-1,d7

.loop_edges:
                moveq   #0,d0
                moveq   #0,d1
                move.b  (a0)+,d0        ; Indice du point de départ A
                move.b  (a0)+,d1        ; Indice du point d'arrivée B

                ; Recherche des coordonnées 2D du point A dans le buffer
                lsl.w   #2,d0           ; Indice * 4 (chaque point projeté = 2 mots = 4 octets)
                moveq   #0,d2
                moveq   #0,d3
                move.w  (a1,d0.w),d2    ; X1
                move.w  2(a1,d0.w),d3   ; Y1

                ; Recherche des coordonnées 2D du point B dans le buffer
                lsl.w   #2,d1           ; Indice * 4
                move.w  (a1,d1.w),d0    ; X2
                move.w  2(a1,d1.w),d1   ; Y2

				
                ; Appel du traceur de ligne de Bresenham
                ; Entrées : d0=X2, d1=Y2, d2=X1, d3=Y1, d4=Couleur
                ; Note : On inverse les registres pour correspondre aux entrées attendues
                exg     d0,d2           ; d0=X1, d2=X2
                exg     d1,d3           ; d1=Y1, d3=Y2
                bsr     DrawLine

                dbf     d7,.loop_edges

                movem.l (sp)+,d0-d4/a0-a2
                rts


; =============================================================================
; Tracé de ligne - Algorithme de Bresenham (Optimisé 68008)
; =============================================================================
;  Entrées : d0 = X1, d1 = Y1, d2 = X2, d3 = Y2, d4 = Couleur
;  Sorties : Registres d0-d6 préservés (valeurs d'origine restaurées)
; =============================================================================
DrawLine:
                movem.l d0-d7/a0-a6,-(sp)

				lea     PlotPixelAdr,a0
                move.l  (a0),a5

                lea     ScreenBase,a0
                move.l  (a0),a4

                ; --- Tri des points pour garantir X1 <= X2 ---
                cmp.w   d0,d2
                bge.s   .no_swap
                exg     d0,d2           
                exg     d1,d3           
.no_swap:
                move.w  d0,a1           ; a1 = X courant
                move.w  d1,a2           ; a2 = Y courant

                sub.w   d0,d2           ; d2 = dX
                move.w  d2,d6           ; d6 = dX (constant)

                ; --- Calcul de dY et isolation du signe ---
                sub.w   d1,d3           ; d3 = Y2 - Y1
                bpl.s   .dy_positive

                ; =============================================================
                ; CAS 1 : dY est négatif (La ligne monte)
                ; =============================================================
                neg.w   d3              ; d3 = abs(dY)
                move.w  d3,a3           ; a3 = |dY| (constant)

                cmp.w   d3,d6           ; Comparaison dX vs |dY|
                blt.s   .steep_down

                ; --- Ligne douce / descendante (dX >= |dY|) ---
                move.w  d6,d7           ; Compteur de boucle = dX
                move.w  d6,d5
                lsr.w   #1,d5           ; Erreur initiale = dX / 2
.loop_h_down:
                move.w  a1,d0           ; d0 = X
                move.w  a2,d1           ; d1 = Y
				jsr     (a5)                
                
				addq.w  #1,a1           ; X = X + 1
                move.l  a3,d0           ; Correction : d0 sert de tampon légal pour l'adresse
                sub.w   d0,d5           ; Erreur = Erreur - |dY|
                bpl.s   .next_h_down
                subq.w  #1,a2           ; Y = Y - 1
                add.w   d6,d5           ; Erreur = Erreur + dX
.next_h_down:
                dbf     d7,.loop_h_down
                bra.s   .done

.steep_down:
                ; --- Ligne abrupte / descendante (|dY| > dX) ---
                move.w  a3,d7           ; Compteur de boucle = |dY|
                move.w  a3,d5
                lsr.w   #1,d5           ; Erreur initiale = |dY| / 2
.loop_v_down:
                move.w  a1,d0
                move.w  a2,d1
                jsr     (a5)
                
                subq.w  #1,a2           ; Y = Y - 1
                sub.w   d6,d5           ; Erreur = Erreur - dX
                bpl.s   .next_v_down
                addq.w  #1,a1           ; X = X + 1
                move.l  a3,d0
                add.w   d0,d5           ; Erreur = Erreur + |dY|
.next_v_down:
                dbf     d7,.loop_v_down
                bra.s   .done

                ; =============================================================
                ; CAS 2 : dY est positif (La ligne descend)
                ; =============================================================
.dy_positive:
                move.w  d3,a3           ; a3 = dY (constant)
                cmp.w   d3,d6           ; Comparaison dX vs dY
                blt.s   .steep_up

                ; --- Ligne douce / montante (dX >= dY) ---
                move.w  d6,d7           ; Compteur de boucle = dX
                move.w  d6,d5
                lsr.w   #1,d5           ; Erreur initiale = dX / 2
.loop_h_up:
                move.w  a1,d0
                move.w  a2,d1
                jsr     (a5)
                
                addq.w  #1,a1           ; X = X + 1
                move.l  a3,d0
                sub.w   d0,d5           ; Erreur = Erreur - dY
                bpl.s   .next_h_up
                addq.w  #1,a2           ; Y = Y + 1
                add.w   d6,d5           ; Erreur = Erreur + dX
.next_h_up:
                dbf     d7,.loop_h_up
                bra.s   .done

.steep_up:
                ; --- Ligne abrupte / montante (dY > dX) ---
                move.w  a3,d7           ; Compteur de boucle = dY
                move.w  a3,d5
                lsr.w   #1,d5           ; Erreur initiale = dY / 2
.loop_v_up:
                move.w  a1,d0
                move.w  a2,d1
                jsr     (a5)
                
                addq.w  #1,a2           ; Y = Y + 1
                sub.w   d6,d5           ; Erreur = Erreur - dX
                bpl.s   .next_v_up
                addq.w  #1,a1           ; X = X + 1
                move.l  a3,d0
                add.w   d0,d5           ; Erreur = Erreur + dY
.next_v_up:
                dbf     d7,.loop_v_up

.done:
                movem.l (sp)+,d0-d7/a0-a6
                rts

; =============================================================================
;  PlotPixel mode 8 couleurs
;  Entrées : d0 = X (0-511), d1 = Y (0-255), d2 = Couleur, a4 = ScreenBase
; =============================================================================
PlotPixel:
				move.l	a4,a0
				
                move.w  d2,d3               ; d3 = Couleur (0-7)
                
                ; --- Calcul de l'adresse du mot horizontal (X) ---
                move.w  d0,d2               ; d2 = Copie de X
                lsr.w   #1,d2               ; d2 = X / 2
                andi.w  #$007E,d2           ; Force l'alignement sur un mot pair
                adda.w  d2,a0               ; a0 pointe sur le bon mot horizontal
                
                ; --- Calcul de l'adresse de la ligne verticale (Y) ---
                move.w  d1,d2               ; d2 = Copie de Y
                lsl.w   #7,d2               ; d2 = Y * 128 octets par ligne
                adda.w  d2,a0               ; a0 = Adresse mémoire finale du mot cible
                
                ; --- Préparation des masques de couleur ---
                lsl.w   #6,d3
                move.w  d3,d2
                lsl.w   #7,d2
                andi.w  #$8000,d2           ; Isole le bit Vert (Bit 15)
                andi.w  #$00C0,d3           ; Isole les bits Rouge et Bleu (Bits 7 et 6)
                or.w    d2,d3               ; d3 = Pixel brut configuré pour la position 0
                
                ; --- Positionnement intra-mot (Pixel 0, 1, 2 ou 3) ---
                andi.w  #3,d0               ; d0 = X modulo 4
                add.w   d0,d0               ; d0 = Facteur de rotation (0, 2, 4 ou 6 bits)
                
                ; --- Application directe avec correction du masque ---
                move.w  #$3F3F,d2           ; Correction : Nettoie TOUS les bits du pixel (y compris le Flash)
                ror.w   d0,d3               ; Décale les bits de couleur à la bonne position
                ror.w   d0,d2               ; Décale le masque de nettoyage à la bonne position
                
                and.w   d2,(a0)             ; Effacement chirurgical de l'ancien pixel
                or.w    d3,(a0)             ; Injection de la nouvelle couleur
                rts

				
; Entrée : d0=X, d1=Y, a4=ScreenBase
; Détruit les registres : d2, a0
				
; =============================================================================
; 0. NOIR (Routine d'effacement ultra-rapide, sans instruction OR)
; =============================================================================
PlotPixelBlack:
                move.l  a4,a0
                move.w  d0,d2
                lsr.w   #1,d2
                andi.w  #$007E,d2
                adda.w  d2,a0
                move.w  d1,d2
                lsl.w   #7,d2
                adda.w  d2,a0
                
                move.w  d0,d2
                andi.w  #3,d2
                add.w   d2,d2               ; d2 = Facteur de rotation (0, 2, 4 ou 6)
                
                move.l  d3,-(sp)            ; Sauvegarde uniquement d3 (|dY| de Bresenham)
                move.w  #$3F3F,d3           ; Masque de nettoyage
                ror.w   d2,d3
                and.w   d3,(a0)             ; Le pixel passe à 0 (Noir)
                move.l  (sp)+,d3
                rts

; =============================================================================
; 1. BLEU
; =============================================================================
PlotPixelBlue:
                move.l  a4,a0
                move.w  d0,d2
                lsr.w   #1,d2
                andi.w  #$007E,d2
                adda.w  d2,a0
                move.w  d1,d2
                lsl.w   #7,d2
                adda.w  d2,a0
                
                move.w  d0,d2
                andi.w  #3,d2
                add.w   d2,d2
                
                move.l  d3,-(sp)
                move.w  #$3F3F,d3           ; Masque de nettoyage
                ror.w   d2,d3
                and.w   d3,(a0)
                
                move.w  #$0040,d3           ; Couleur : Bleu
                ror.w   d2,d3
                or.w    d3,(a0)
                move.l  (sp)+,d3
                rts

; =============================================================================
; 2. ROUGE
; =============================================================================
PlotPixelRed:
                move.l  a4,a0
                move.w  d0,d2
                lsr.w   #1,d2
                andi.w  #$007E,d2
                adda.w  d2,a0
                move.w  d1,d2
                lsl.w   #7,d2
                adda.w  d2,a0
                
                move.w  d0,d2
                andi.w  #3,d2
                add.w   d2,d2
                
                move.l  d3,-(sp)
                move.w  #$3F3F,d3
                ror.w   d2,d3
                and.w   d3,(a0)
                
                move.w  #$0080,d3           ; Couleur : Rouge
                ror.w   d2,d3
                or.w    d3,(a0)
                move.l  (sp)+,d3
                rts

; =============================================================================
; 3. MAGENTA
; =============================================================================
PlotPixelMagenta:
                move.l  a4,a0
                move.w  d0,d2
                lsr.w   #1,d2
                andi.w  #$007E,d2
                adda.w  d2,a0
                move.w  d1,d2
                lsl.w   #7,d2
                adda.w  d2,a0
                
                move.w  d0,d2
                andi.w  #3,d2
                add.w   d2,d2
                
                move.l  d3,-(sp)
                move.w  #$3F3F,d3
                ror.w   d2,d3
                and.w   d3,(a0)
                
                move.w  #$00C0,d3           ; Couleur : Magenta
                ror.w   d2,d3
                or.w    d3,(a0)
                move.l  (sp)+,d3
                rts

; =============================================================================
; 4. VERT
; =============================================================================
PlotPixelGreen:
                move.l  a4,a0
                move.w  d0,d2
                lsr.w   #1,d2
                andi.w  #$007E,d2
                adda.w  d2,a0
                move.w  d1,d2
                lsl.w   #7,d2
                adda.w  d2,a0
                
                move.w  d0,d2
                andi.w  #3,d2
                add.w   d2,d2
                
                move.l  d3,-(sp)
                move.w  #$3F3F,d3
                ror.w   d2,d3
                and.w   d3,(a0)
                
                move.w  #$8000,d3           ; Couleur : Vert
                ror.w   d2,d3
                or.w    d3,(a0)
                move.l  (sp)+,d3
                rts

; =============================================================================
; 5. CYAN
; =============================================================================
PlotPixelCyan:
                move.l  a4,a0
                move.w  d0,d2
                lsr.w   #1,d2
                andi.w  #$007E,d2
                adda.w  d2,a0
                move.w  d1,d2
                lsl.w   #7,d2
                adda.w  d2,a0
                
                move.w  d0,d2
                andi.w  #3,d2
                add.w   d2,d2
                
                move.l  d3,-(sp)
                move.w  #$3F3F,d3
                ror.w   d2,d3
                and.w   d3,(a0)
                
                move.w  #$8040,d3           ; Couleur : Cyan
                ror.w   d2,d3
                or.w    d3,(a0)
                move.l  (sp)+,d3
                rts

; =============================================================================
; 6. JAUNE
; =============================================================================
PlotPixelYellow:
                move.l  a4,a0
                move.w  d0,d2
                lsr.w   #1,d2
                andi.w  #$007E,d2
                adda.w  d2,a0
                move.w  d1,d2
                lsl.w   #7,d2
                adda.w  d2,a0
                
                move.w  d0,d2
                andi.w  #3,d2
                add.w   d2,d2
                
                move.l  d3,-(sp)
                move.w  #$3F3F,d3
                ror.w   d2,d3
                and.w   d3,(a0)
                
                move.w  #$8080,d3           ; Couleur : Jaune
                ror.w   d2,d3
                or.w    d3,(a0)
                move.l  (sp)+,d3
                rts

; =============================================================================
; 7. BLANC
; =============================================================================
PlotPixelWhite:
                move.l  a4,a0
                move.w  d0,d2
                lsr.w   #1,d2
                andi.w  #$007E,d2
                adda.w  d2,a0
                move.w  d1,d2
                lsl.w   #7,d2
                adda.w  d2,a0
                
                move.w  d0,d2
                andi.w  #3,d2
                add.w   d2,d2
                
                move.l  d3,-(sp)
                move.w  #$3F3F,d3
                ror.w   d2,d3
                and.w   d3,(a0)
                
                move.w  #$80C0,d3           ; Couleur : Blanc
                ror.w   d2,d3
                or.w    d3,(a0)
                move.l  (sp)+,d3
                rts

; =============================================================================
; Nettoyage d'écran "rapide"
; =============================================================================
ClearScreen:
                movem.l d0-d1/a0,-(sp)
                lea     ScreenBase,a0
				move.l	(a0),a0
                move.w  #8191,d0        ; 8192 itérations de longs (32768 octets au total)
                move.l   #$FFFFFFFF,d1
                move.l   #$0,d1
.loop:
                move.l  d1,(a0)+
                dbf     d0,.loop
                movem.l (sp)+,d0-d1/a0
                rts


; =============================================================================
;  Obtention Sinus / Cosinus (64 étapes pour 360°)
; =============================================================================
;  Entrée : d0 = Angle (0-63)
;  Sorties : d1 = Valeur de Sinus (format signé 8.8), d2 = Cosinus (format signé 8.8)
;  La table ne contient que le sinus. Le cosinus est calculé par décalage de phase :
;  Cos(x) = Sin(x + 90°) -> Dans notre cercle à 64 étapes, 90° correspond à 16 étapes.
; =============================================================================
GetSinCos:
                andi.w  #63,d0          ; Écrêtage de sécurité de l'angle d'entrée

                ; Extraction du Sinus
                move.w  d0,d1
                add.w   d1,d1           ; d1 * 2 pour indexation sur mots (16-bit)
                lea     SinTable,a1
                move.w  (a1,d1.w),d1    ; d1 = Sin(Angle)

                ; Extraction du Cosinus
                move.w  d0,d2
                addi.w  #16,d2          ; Ajout du quart de période (90° / 16 étapes)
                andi.w  #63,d2          ; Écrêtage
                add.w   d2,d2
                move.w  (a1,d2.w),d2    ; d2 = Cos(Angle)

                rts

; =============================================================================
;  SOUS-ROUTINE : Animation du Zoom (Oscillation entre 50 et 200)
; =============================================================================
AnimateZoom:
                movem.l d0-d1/a0-a1,-(sp)

                ; 1. Avancement de l'angle du zoom
                lea     ZoomAngle(PC),a0
                move.w  (a0),d0         ; d0 = Angle actuel
                addq.w  #1,d0           ; Vitesse de l'oscillation (+1 par trame)
                andi.w  #63,d0          ; Limite à l'espace de la table [0-63]
                move.w  d0,(a0)         ; Sauvegarde de l'angle mis à jour

                ; 2. Lecture de la valeur de Sinus
                add.w   d0,d0           ; Multiplié par 2 (indexation par mots de 16 bits)
                lea     SinTable(PC),a1
                move.w  (a1,d0.w),d0    ; d0 = Valeur brute de Sinus (-256 à 256)

                ; 3. Application de l'amplitude (Multiplication par 75)
                muls    #75,d0          ; d0 = Sinus * 75

                ; 4. Division par 256 (Conversion du format 8.8 vers entier)
                ; Sur 68008, un décalage de 8 bits via asr.l est plus rapide qu'un divs
                asr.l   #8,d0           ; d0 = Amplitude réelle calculée [-75 à +75]

                ; 5. Ajout du point central (Offset 125)
                addi.w  #100,d0         ; d0 = 125 + [-75 à +75] -> [50 à 200]

                ; 6. Stockage du nouveau niveau de zoom
                lea     ZoomLevel(PC),a0
                move.w  d0,(a0)         ; ZoomLevel est prêt pour RotateAndProject

                movem.l (sp)+,d0-d1/a0-a1
                rts
				
DrawOlipixLines:
                movem.l d0-d7/a0-a6,-(sp)

				move.w	#4,d4
				move.w	#0,d0
				move.w	#128-13,d1
				move.w	#50,d2
				lea     PlotPixelRed,a0
                lea     PlotPixelAdr,a1
				move.l	a0,(a1)
.redlines:
				move.w	d1,d3
				bsr		DrawLine
				add.w	#1,d1
				dbf		d4,.redlines

				move.w	#4,d4
				move.w	#0,d0
				move.w	#128-8,d1
				move.w	#48,d2
				lea     PlotPixelMagenta,a0
                lea     PlotPixelAdr,a1
				move.l	a0,(a1)
.magentalines:
				move.w	d1,d3
				bsr		DrawLine
				add.w	#1,d1
				dbf		d4,.magentalines

				move.w	#4,d4
				move.w	#0,d0
				move.w	#128-3,d1
				move.w	#46,d2
				lea     PlotPixelYellow,a0
                lea     PlotPixelAdr,a1
				move.l	a0,(a1)
.yellowlines:
				move.w	d1,d3
				bsr		DrawLine
				add.w	#1,d1
				dbf		d4,.yellowlines

				move.w	#4,d4
				move.w	#0,d0
				move.w	#128+2,d1
				move.w	#46,d2
				lea     PlotPixelGreen,a0
                lea     PlotPixelAdr,a1
				move.l	a0,(a1)
.greenlines:
				move.w	d1,d3
				bsr		DrawLine
				add.w	#1,d1
				dbf		d4,.greenlines

				move.w	#4,d4
				move.w	#0,d0
				move.w	#128+7,d1
				move.w	#48,d2
				lea     PlotPixelCyan,a0
                lea     PlotPixelAdr,a1
				move.l	a0,(a1)
.cyanlines:
				move.w	d1,d3
				bsr		DrawLine
				add.w	#1,d1
				dbf		d4,.cyanlines


				move.w	#4,d4
				move.w	#0,d0
				move.w	#128+12,d1
				move.w	#50,d2
				lea     PlotPixelBlue,a0
                lea     PlotPixelAdr,a1
				move.l	a0,(a1)
.bluelines:
				move.w	d1,d3
				bsr		DrawLine
				add.w	#1,d1
				dbf		d4,.bluelines


                movem.l (sp)+,d0-d7/a0-a6

				rts
; =============================================================================
;  WaitAnyKey (Attente matérielle pure - SANS QDOS)
; =============================================================================
WaitAnyKey:
                move.l  d1,-(sp)

                ; 1. Effacer toute interruption IPC résiduelle pour éviter un faux départ
                ; Écrire '1' sur le bit 3 de $18022 acquitte l'état de l'IPC
                moveq   #$08,d1
                move.b  d1,$18022

.poll_loop:
                ; 2. Lire le registre d'état des interruptions (ZX8302)
                move.b  $18002,d0
                
                ; 3. Tester le bit 3 (IPC Interrupt Pending)
                btst    #3,d0
                beq.s   .poll_loop          ; Boucle tant que le bit reste à 0 (aucune action)

                ; 4. Une action a été détectée. On acquitte à nouveau l'interruption
                ; pour laisser le matériel dans un état propre à la sortie
                move.b	d1,$18022

                move.l  (sp)+,d1
                rts				
				
				
; =============================================================================
;  ZONE DE DONNÉES / VARIABLES
; =============================================================================
                even
;dm 385f8
Sprite:
	incbin		"test.bin"
				
ScreenBase:		dc.l	$20000          ; Adresse de départ de la mémoire d'écran QL

AngleX:         dc.w    0
AngleY:         dc.w    0

				even
				
PlotPixelAdr:	dc.l	0
				even
NbPlotPixel:	dc.l	0
NbLoop:			dc.l	0

; Stockage intermédiaire des valeurs de rotation courantes
SinX:           dc.w    0
CosX:           dc.w    0
SinY:           dc.w    0
CosY:           dc.w    0
ZoomLevel:		dc.w	128
ZoomAngle:		dc.w	0

; --- Table de Sinus prédéfinie (64 étapes, codée en 8.8 signé) ---
; Valeurs calculées selon : Sin(i * 2*Pi / 64) * 256. 256 représente 1.0 en virgule fixe.
SinTable:
                dc.w    0, 25, 50, 74, 98, 120, 142, 162
                dc.w    181, 198, 213, 226, 236, 244, 250, 254
                dc.w    256, 254, 250, 244, 236, 226, 213, 198
                dc.w    181, 162, 142, 120, 98, 74, 50, 25
                dc.w    0, -25, -50, -74, -98, -120, -142, -162
                dc.w    -181, -198, -213, -226, -236, -244, -250, -254
                dc.w    -256, -254, -250, -244, -236, -226, -213, -198
                dc.w    -181, -162, -142, -120, -98, -74, -50, -25

; --- Géométrie 3D de l'objet (Cube) ---
; Liste de sommets locaux signés (X, Y, Z)
	ifd DATA_CUBE
Vertices:
                dc.w    -40, -40, -40   ; Sommet 0
                dc.w     40, -40, -40   ; Sommet 1
                dc.w     40,  40, -40   ; Sommet 2
                dc.w    -40,  40, -40   ; Sommet 3
                dc.w    -40, -40,  40   ; Sommet 4
                dc.w     40, -40,  40   ; Sommet 5
                dc.w     40,  40,  40   ; Sommet 6
                dc.w    -40,  40,  40   ; Sommet 7

; Table de connectivité des arêtes (12 arêtes connectant les sommets de 0 à 7)
Edges:
                ; Face Avant (Arrière-plan relatif de l'objet)
                dc.b    0, 1
                dc.b    1, 2
                dc.b    2, 3
                dc.b    3, 0
                ; Face Arrière (Avant-plan relatif)
                dc.b    4, 5
                dc.b    5, 6
                dc.b    6, 7
                dc.b    7, 4
                ; Liaisons inter-faces (Profondeur)
                dc.b    0, 4
                dc.b    1, 5
                dc.b    2, 6
                dc.b    3, 7
	endif
	
	ifd DATA_LOGO
even
Vertices:
                ; --- Corps / Tête rectangulaire (Points 0 à 3) ---
                dc.w    -40,  30,   0   ; 0 : Coin supérieur gauche
                dc.w     40,  30,   0   ; 1 : Coin supérieur droit
                dc.w     40, -30,   0   ; 2 : Coin inférieur droit
                dc.w    -40, -30,   0   ; 3 : Coin inférieur gauche

                ; --- Antenne (Points 4 à 7) ---
                dc.w      0,  30,   0   ; 4 : Base de la tige (milieu haut du corps)
                dc.w      0,  50,   0   ; 5 : Sommet de la tige (jonction du T)
                dc.w    -15,  50,   0   ; 6 : Extrémité gauche de la barre du T
                dc.w     15,  50,   0   ; 7 : Extrémité droite de la barre du T

                ; --- Yeux (Points 8 à 11) ---
                dc.w    -20,  10,   0   ; 8 : Œil gauche (début)
                dc.w    -10,  10,   0   ; 9 : Œil gauche (fin)
                dc.w     10,  10,   0   ; 10: Œil droit (début)
                dc.w     20,  10,   0   ; 11: Œil droit (fin)

                ; --- Bras (Points 12 à 15) ---
                dc.w    -40, -10,   0   ; 12: Épaule gauche
                dc.w    -60, -10,   0   ; 13: Bout du bras gauche
                dc.w     40, -10,   0   ; 14: Épaule droite
                dc.w     60, -10,   0   ; 15: Bout du bras droit

                ; --- Jambes (Points 16 à 19) ---
                dc.w    -20, -30,   0   ; 16: Hanche gauche
                dc.w    -20, -55,   0   ; 17: Pied gauche
                dc.w     20, -30,   0   ; 18: Hanche droite
                dc.w     20, -55,   0   ; 19: Pied droit

; --- Table de connectivité des arêtes (12 segments reliant les points) ---
Edges:
                ; Contour du corps / tête
                dc.b    0, 1
                dc.b    1, 2
                dc.b    2, 3
                dc.b    3, 0

                ; Antenne
                dc.b    4, 5            ; Tige verticale
                dc.b    6, 7            ; Barre horizontale du T

                ; Yeux (deux segments horizontaux internes)
                dc.b    8, 9
                dc.b    10, 11

                ; Bras
                dc.b    12, 13
                dc.b    14, 15

                ; Jambes
                dc.b    16, 17
                dc.b    18, 19
	endif

	ifd DATA_OLIPIX
; =============================================================================
;  GÉOMÉTRIE VECTORIELLE : Mot "OLIPIX" (Centré, Hauteur: 40, Largeur totale: 110)
; =============================================================================
Vertices:
                ; --- Lettre 'O' (Points 0 à 3) ---
                dc.w    -55,  20,   0   ; 0 : Haut Gauche
                dc.w    -40,  20,   0   ; 1 : Haut Droite
                dc.w    -40, -20,   0   ; 2 : Bas Droite
                dc.w    -55, -20,   0   ; 3 : Bas Gauche

                ; --- Lettre 'L' (Points 4 à 6) ---
                dc.w    -30,  20,   0   ; 4 : Sommet du L
                dc.w    -30, -20,   0   ; 5 : Angle du L
                dc.w    -15, -20,   0   ; 6 : Base du L

                ; --- Lettre 'I' (Points 7 à 8) ---
                dc.w     -5,  20,   0   ; 7 : Sommet du premier I
                dc.w     -5, -20,   0   ; 8 : Base du premier I

                ; --- Lettre 'P' (Points 9 à 13) ---
                dc.w      5, -20,   0   ; 9 : Base du jambage
                dc.w      5,  20,   0   ; 10: Sommet du jambage
                dc.w     20,  20,   0   ; 11: Boucle Haut Droite
                dc.w     20,   0,   0   ; 12: Boucle Milieu Droite
                dc.w      5,   0,   0   ; 13: Intersection Milieu Jambage

                ; --- Lettre 'I' (Points 14 à 15) ---
                dc.w     30,  20,   0   ; 14: Sommet du second I
                dc.w     30, -20,   0   ; 15: Base du second I

                ; --- Lettre 'X' (Points 16 à 19) ---
                dc.w     40,  20,   0   ; 16: Branche 1 - Haut Gauche
                dc.w     55, -20,   0   ; 17: Branche 1 - Bas Droite
                dc.w     55,  20,   0   ; 18: Branche 2 - Haut Droite
                dc.w     40, -20,   0   ; 19: Branche 2 - Bas Gauche

; --- Connectivité des lignes pour écrire OLIPIX ---
Edges:
                ; Lettre 'O' (Un rectangle fermé)
                dc.b    0, 1
                dc.b    1, 2
                dc.b    2, 3
                dc.b    3, 0

                ; Lettre 'L'
                dc.b    4, 5
                dc.b    5, 6

                ; Lettre 'I'
                dc.b    7, 8

                ; Lettre 'P'
                dc.b    9, 10           ; Tracé vertical complet
                dc.b    10, 11          ; Haut de la boucle
                dc.b    11, 12          ; Flanc droit de la boucle
                dc.b    12, 13          ; Retour au centre du P

                ; Lettre 'I'
                dc.b    14, 15

                ; Lettre 'X' (Deux diagonales croisées)
                dc.b    16, 17
                dc.b    18, 19

                even	
	endif

	ifd DATA_RPUO
Vertices:
                ; --- Lettre 'R' (Points 0 à 5) ---
                dc.w    -45, -20,   0   ; 0 : Base du jambage gauche
                dc.w    -45,  20,   0   ; 1 : Sommet du jambage gauche
                dc.w    -27,  20,   0   ; 2 : Haut de la boucle (droite)
                dc.w    -27,   0,   0   ; 3 : Bas de la boucle (droite)
                dc.w    -45,   0,   0   ; 4 : Intersection milieu jambage
                dc.w    -27, -20,   0   ; 5 : Pied de la diagonale droite

                ; --- Lettre 'P' (Points 6 à 10) ---
                dc.w    -21, -20,   0   ; 6 : Base du jambage
                dc.w    -21,  20,   0   ; 7 : Sommet du jambage
                dc.w     -3,  20,   0   ; 8 : Haut de la boucle (droite)
                dc.w     -3,   0,   0   ; 9 : Bas de la boucle (droite)
                dc.w    -21,   0,   0   ; 10: Intersection milieu jambage

                ; --- Lettre 'U' (Points 11 à 14) ---
                dc.w      3,  20,   0   ; 11: Sommet gauche
                dc.w      3, -20,   0   ; 12: Base gauche
                dc.w     21, -20,   0   ; 13: Base droite
                dc.w     21,  20,   0   ; 14: Sommet droit

                ; --- Lettre 'O' (Points 15 à 18) ---
                dc.w     27,  20,   0   ; 15: Coin Haut Gauche
                dc.w     45,  20,   0   ; 16: Coin Haut Droite
                dc.w     45, -20,   0   ; 17: Coin Bas Droite
                dc.w     27, -20,   0   ; 18: Coin Bas Gauche

; --- Connectivité des lignes (Indexation des points) ---
Edges:
                ; Lettre 'R' (5 segments)
                dc.b    0, 1            ; Jambage vertical
                dc.b    1, 2            ; Haut de la boucle
                dc.b    2, 3            ; Flanc droit de la boucle
                dc.b    3, 4            ; Retour au milieu du jambage
                dc.b    4, 5            ; Diagonale/Pied

                ; Lettre 'P' (4 segments)
                dc.b    6, 7            ; Jambage vertical
                dc.b    7, 8            ; Haut de la boucle
                dc.b    8, 9            ; Flanc droit de la boucle
                dc.b    9, 10           ; Retour au milieu du jambage

                ; Lettre 'U' (3 segments)
                dc.b    11, 12          ; Barre verticale gauche
                dc.b    12, 13          ; Barre horizontale basse
                dc.b    13, 14          ; Barre verticale droite

                ; Lettre 'O' (4 segments fermés)
                dc.b    15, 16
                dc.b    16, 17
                dc.b    17, 18
                dc.b    18, 15
	endif
	even

; --- Buffer de réception des coordonnées projetées (2D) ---
; Chaque sommet projeté nécessite 2 mots (ScreenX, ScreenY) -> 8 sommets * 4 octets = 32 octets.

Projected:		dc.l	0

Projected1:     ds.w    NUM_VERTICES*2

Projected2:     ds.w    NUM_VERTICES*2

				ds.b    2048            
top_of_stack:
                end
