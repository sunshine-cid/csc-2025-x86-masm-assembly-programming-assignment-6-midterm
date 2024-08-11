; Student
; Professor
; Class: CSC 2025 XXX
; Week  - Programming Midterm Exam - Part #2
; Date
; A basic BlackJack program. One deck, shuffled. Player goes. Dealer goes. Calculate results. Repeat if user prompts Y.

INCLUDE C:\Irvine\Irvine32.inc
INCLUDELIB C:\Irvine\Irvine32.lib

.data
	cardDeck BYTE 52 DUP (?) ; Reserve space for deck of cards

    ; Setup strings for card ranks
	rankAce    BYTE "A", 0
	rank2      BYTE "2", 0
	rank3      BYTE "3", 0
	rank4      BYTE "4", 0
	rank5      BYTE "5", 0
	rank6      BYTE "6", 0
	rank7      BYTE "7", 0
	rank8      BYTE "8", 0
	rank9      BYTE "9", 0
	rank10     BYTE "10", 0
	rankJack   BYTE "J", 0
	rankQueen  BYTE "Q", 0
	rankKing   BYTE "K", 0

  ; Setup strings for card suits
	suitClubs    BYTE " of Clubs", 0
	suitSpades   BYTE " of Spades", 0
	suitHearts   BYTE " of Hearts", 0
	suitDiamonds BYTE " of Diamonds", 0	

    ; Create offset arrays in order for ranks and suits so they can be accessed algorythmically
	  rankStrings DWORD OFFSET rankAce, OFFSET rank2, OFFSET rank3, OFFSET rank4, OFFSET rank5, OFFSET rank6, OFFSET rank7, OFFSET rank8, OFFSET rank9, OFFSET rank10, OFFSET rankJack, OFFSET rankQueen, OFFSET rankKing
	  suitStrings DWORD OFFSET suitClubs, OFFSET suitSpades, OFFSET suitHearts, OFFSET suitDiamonds

    ; Setup for player and computer hands and totals
	  playerHand BYTE 12 DUP (-1)   ; Assuming a max of 12 cards
    playerTotal DWORD 0          ; Stores the total value of the player's hand

	  computerHand BYTE 12 DUP (-1) ; Assuming a max of 12 cards
    computerTotal DWORD 0          ; Stores the total value of the player's hand

    ; We need some variables for these for CalculateHandValue since register space alone is insufficient
    calculatedTotal DWORD 0 ; Needed a variable for holding the totalled value in CalculateHandValue
    calculatedAces DWORD 0 ; Needed to account for multiple aces when totaling hand

    ; We need a variable for the position we are in the deck. Normally we're using EDI, but sometimes we need EDI for other stuff.
    deckPosition DWORD OFFSET cardDeck ; This holds the memory address of the current deck position from EDI if we need to swap that value to something else
    playerHandPosition DWORD OFFSET playerHand
    computerHandPosition DWORD OFFSET computerHand

    ; Setup for some strings to make user interface nicer/more understandable
    msgWelcome BYTE "Welcome to our BlackJack program! ",0
    msgShuffling BYTE "Shuffling the Deck... ", 0
    msgTotalValue BYTE "Total value: ", 0
    msgPlayerCard BYTE "Player's Hand: ", 0
    msgComputerCard BYTE "House's Hand: ", 0
    msgHitOrStand BYTE "Would you like to Hit or Stand(H/S)? ", 0
    msgDealCard BYTE "Dealing out a card... ", 0
    msgComputerTurn BYTE "Now its the House's Turn! ", 0
    msgComputerHit BYTE "The House Hits! ", 0
    msgPlayerBust BYTE "The Player has Busted! ",0
    msgComputerBust BYTE "The House has Busted! ", 0
    msgPlayerWin BYTE "You Win! ", 0
    msgComputerWin BYTE "The House Wins! ", 0
    msgDraw BYTE "It's a Draw! ", 0
    msgResults BYTE "Here are the results: ", 0
    msgPlayAgain BYTE "Would you like to play again(Y/N)? ", 0
    msgBye BYTE "Thank you for playing! Goodbye! ", 0

    ; Prompt input memory space for char
    charHitOrStand BYTE ?
    charPlayAgain BYTE ?

    ; String values for chars for comparisons
    strH BYTE "H", 0
    strS BYTE "S", 0
    strY BYTE "Y", 0
    strN BYTE "N", 0


.code

;-------------------------------- InitializeStarterDeck Procedure 
;	Functional Details: Practically this procedure fills our cardDeck array 
;   (decending) with the values 51 to 0. There's a problem (something like 
;   the line's too long) just doing that in the .data section.
;	Inputs: Uses EDI and ECX
;	Outputs: Essentially our output is the initialized deck.
;	Registers:  EDI is used to point to our position in the deck.
;               ECX is used to count down through the card values.
;	Memory Locations: Manipulates the OFFSET for cardDeck. Decriments through
;   ECX.
InitializeStarterDeck PROC USES ECX EDI
	
InitializeDeck:
	
	mov [edi], cl
	dec edi
	loop InitializeDeck
	
	ret
InitializeStarterDeck ENDP

;-------------------------------- InitializeForStart Procedure 
;	Functional Details: When the game first starts the player/computer hand 
;   positions and deck positions are all correctly set. But, after a game they 
;   need to be reset. Practically this procedure resets them to their starting 
;   values. 
;	Inputs: Not stricktly as input but this procedure does manipulate the 
;   values of playerHand, copmputerHand, playerTotal, computerTotal, 
;   deckPosition, playerHandPosition, and computerHandPosition.
;	Outputs: Again, not stricktly output but does reset the above-mentioned 
;   values
;	Registers:  ECX is utilized for a counter
;	Memory Locations: Again, the operands playerHand, copmputerHand, 
;   playerTotal, computerTotal, deckPosition, playerHandPosition, and 
;   computerHandPosition are accessed.
InitializeForStart PROC USES ECX

    ; Setup for player and computer hands and totals and deck positions
	
    mov ecx, LENGTHOF playerHand ; Set the counter to the length of the variable

    ;Fill potential Player Hand with -1
InitializePlayerHandLoop:
    
    mov playerHand[ecx-1], -1
    loop InitializePlayerHandLoop
    
    mov playerTotal, 0 ; New game player total at 0

    mov ecx, LENGTHOF computerHand ; Set the counter to the length of the variable

        ;Fill potential Computer Hand with -1
InitializeComputerHandLoop:
    
    mov computerHand[ecx-1], -1
    loop InitializeComputerHandLoop

    mov computerTotal, 0 ; New game computer total at 0

    ; Reset deck and hand positions
    mov deckPosition, OFFSET cardDeck ; This holds the memory address of the current deck position from EDI if we need to swap that value to something else
    mov playerHandPosition, OFFSET playerHand
    mov computerHandPosition, OFFSET computerHand

    ret

InitializeForStart ENDP

;-------------------------------- ShuffleDeck Procedure 
;	Functional Details: Practically this takes in the offset for the end of the 
;   deck position, swaps that position's value with one below it, decriments 
;   the deck position, and repeats swapping until all cards have been swapped.
;	Inputs: No strickt 'input'
;	Outputs: Dislpay's a message indicating the deck is being shuffled. Alters 
;   the cardDeck array.
;	Registers:  ECX is used as a counter for moving through the deck.
;               EDX is used to point to a string message. DL is used when 
;               swapping cards.
;               EAX is used for setting the value for RandomRange. AL is used 
;               when swapping cards.
;               EBX is used (SUB eax) for the position of the card to be 
;               swapped. Also used when swapping cards.
;               EDI is used for the deck position and when swapping cards 
;	Memory Locations: The shuffling message memory location offset is used. 
ShuffleDeck PROC USES EDI EAX EBX ECX EDX
	
    ; Display the shuffling message
    mov edx, OFFSET msgShuffling
    call WriteString
    call Crlf ; Add another line for formatting

ShuffleLoop: ; select random position, swap, repeat
	
	; Setup for RandomRange, a value maximum of ECX+1
	mov eax, ecx
	add eax, 1

	call RandomRange ; Generate a random number 0 to ECX+1
	mov ebx, edi ; Set EBX to current EDI offset (which is the end edge of the deck)
    sub ebx, eax ; Subtract EAX (the random range) from EBX giving us the position of the card to be swapped
    
    ; Swap the cards at index EDI and EBX
    mov al, [edi]    ; Load the card value from position EDI
    mov dl, [ebx]    ; Load the card value from position EBX
    mov [edi], dl    ; Store the card from DL into EDI's position
    mov [ebx], al    ; Store the card from AL into EBX's position
    
    dec edi ; Move down to the next end position
	loop ShuffleLoop ; Decriment ECX and loop until all cards are shuffled

	ret
ShuffleDeck ENDP

;-------------------------------- DislpayCard Procedure 
;	Functional Details: Practically, this procedure takes in the (0-51) value 
;   of a card and displays it's rank and suit.
;	Inputs: There's no strick user input. But this does take in a card 
;   position (via EDI).
;	Outputs: Based on the calculations and offsets the rank (face value) and 
;   suit of a card is displayed
;	Registers:  EDI is taken in as the pointer to a specific card
;               EAX is used to hold the card value, then it holds the card suit
;               ECX is used as the divisor in division
;               EDX hold the remainder in division, then it hoilds the card rank
;               EBX is used to hold the rank and suit index during the display
;	Memory Locations:
DisplayCard PROC USES EAX EBX ECX EDX ESI

    ; EDI points to the card in the deck
    mov al, [edi]           ; Get the card value
    movzx eax, al           ; Zero extend to avoid sign extension issues

    ; Calculate the suit and rank
    mov ecx, 13 ; Set the divisor to 13
    mov edx, 0 ; Set the divisor remainder to 0 (if you don't clear this DIV won't work)
    div ecx ; EAX result is Suit, EDX remainder is Rank

    ; EAX now contains the suit index (0=Clubs, 1=Spades, 2=Hearts, 3=Diamonds)
    ; EDX now contains the rank index (0=Ace, 1=2, ..., 9=10, 10=Jack, 11=Queen, 12=King)

    ; Display the rank
    mov esi, OFFSET rankStrings ; Address of the rank strings array
    movzx ebx, dl           ; Move the rank index to EBX
    mov edx, [esi + ebx * 4]; Get the address of the rank string
    call WriteString        ; Print the rank string

    ; Display the suit
    mov esi, OFFSET suitStrings ; Address of the suit strings array
    movzx ebx, al           ; Move the suit index to EBX
    mov edx, [esi + ebx * 4]; Get the address of the suit string
    call WriteString        ; Print the suit string

    call Crlf ; New line for readability

    ret
DisplayCard ENDP

;-------------------------------- DealCard Procedure 
;	Functional Details: Essentially this take in current deck position (EDI) 
;   and player/computer's hand (EAX) and 'places' the current top card into 
;   that hand.
;	Inputs: No strict user input is taken but this does read cardDeck and 
;   deckPosition.
;	Outputs: Displays a message about dealing a card. Alters EAX to point 
;   to that deckPosition.
;	Registers:  EDI points to the current position in the deck
;               EAX points to the next available slot in the player's/
;               computer's hand.
;               EBX is used to hold the card value as it moves into 
;               the hand position (EAX)
;	Memory Locations: An offset for a dealing card message is used. 
;   And pointers to currentDeckPosition and a hand position are used.
DealCard PROC USES EAX EBX EDI

    ; Display the Dealing a Card message
    mov edx, OFFSET msgDealCard
    call WriteString
    call Crlf ; Drop down a line for formatting's sake

    mov bl, [edi] ; Load the card from the deck
	movzx ebx, bl ; Extend the sign range to avoid any errors
    mov [eax], bl ; Store the card in the player's hand

    ret
DealCard ENDP

;-------------------------------- CalculateHandValue Procedure 
;	Functional Details: Oh boy. Essentially this takes any card's value (0-51)
;   and translates that into an actual BlackJack scoring value. It does this by 
;   checking to see if the card value is -1 (no card actually), if not it 
;   divides the card value by 13. Giving it a suit as a result and a card value 
;   (rank) as a remainder. Then depending on the remainder either it's an ace 
;   scored at 11 (unless we're over 21 total points then scored as a 1), or a 
;   numbered rank (1-8 value is scored as 2-9), or it's a 10 or face card.
;   This loops unitl all cards in the hand have been counted.
;   (scored as 10). The total is sent to EAX.
;	Inputs: No strick user input is taken but this does read the hand vairable 
;   position through ESI.
;	Outputs: No strick output is made but the total hand score is sent to EAX
;	Registers:  ESI points to the hand offset being analyzed and iterates 
;               through it.
;               EAX holds the card value, holds the suit after DIV, and then 
;               holds the total score after adding everything up.
;               ECX is used to hold the divisor (13)
;               EDX is used to hold the remainder during DIV. But also holds 
;               the card rank which is used in comparisons then it's altered 
;               to the actual card score which is then added to calculatedTotal.
;	Memory Locations: calcualtedTotal is used to hold the accumuliating total. 
;   calculatedAces tracks how many Aces we have for potential score adjusting.
;   An offset is used in ESI to point to the current hand.
CalculateHandValue PROC USES EBX ECX EDX ESI

    mov calculatedTotal, 0 ; Clear calculatedTotal to accumulate card values
    mov calculatedAces, 0 ; Counter for Aces special behavior
        
    ; Loop through the ESI linked hand
CalculateLoop:
    mov al, [esi]               ; Load the card value
    movzx eax, al ; For simplicity's and error correcting's sake, clear the rest of the EAX register
    cmp al, -1                  ; Check if it is -1, i.e. an empty slot
    je CalculateDone            ; If so, end the loop

    ; Calculate the card's value
    mov edx, 0
    mov ecx, 13
    div ecx                      ; Divide card value by 13 to get rank
    
    ; Check for an Ace first, jump to proper section if found
    cmp edx, 0 ; Check if it's an Ace (when rank is 0)
    je AceCard

    ; Determine the card's value
    cmp edx, 8                   ; If card is 10, J, Q, K
    jg FaceCard                  ; Jump if greater than 9 (10, J, Q, K)
    
    inc edx                      ; Else, card is A-9
    jmp AddCardValue

FaceCard:
    mov edx, 10 ; Set value of face cards to 10       
    jmp AddCardValue ; If not, skip

    AceCard:
    mov edx, 11 ; Initial Ace value is 11
    inc calculatedAces ; Increment the number of Aces    

AddCardValue:
    add calculatedTotal, edx                 ; Add the card's value to the calculatedTotal
    inc esi                      ; Move to the next card in the hand
    loop CalculateLoop           ; Loop through the number of cards

CalculateDone:
    cmp calculatedTotal, 21
    jle Done           ; If <= 21, no adjustment needed

    ; Handle the case for Aces: reduce from 11 to 1 if total > 21 for each ace as necessary
AdjustAces: 
    cmp calculatedAces, 0 ; Check if there are any Aces counted as 11
    je Done ; If not, we're done
    sub calculatedTotal, 10 ; Subtract 10 to treat an Ace as 1
    dec calculatedAces ; Reduce the number of Aces to check
    jmp CalculateDone            ; Recalculate and continue to adjust if needed

Done:
    mov eax, calculatedTotal ; Store the total value in EAX
    
    ret
CalculateHandValue ENDP

;-------------------------------- DisplayHand Procedure 
;	Functional Details: Practically this translates DisplayCard (which was 
;   written for accessing the cardDeck) into accessing and walking through 
;   weach card in a hand.
;	Inputs: No strick input is taken, but this does access an ESI offset to find 
;   a card value
;	Outputs: This procedure doens't output directly but the call of DisplayCard 
;   does output the value of the card pointed to.
;	Registers:  ESI points to a card value
;               EAX holds a card value, and compared to -1 to signal the end 
;               of the hand.
;	Memory Locations: ESI points to an offset for a hand value
DisplayHand PROC USES EAX ESI
    
    DisplayCardLoop:
    mov al, [esi] ; Load the card value
    movzx eax, al ; For simplicity's and error correcting's sake, clear the rest of the EAX register
    cmp al, -1 ; Check if it is -1, i.e. an empty slot
    je DisplayHandDone ; If so, end the loop

    ; Otherwise sawp ESI (what DisplayHand takes) into EDI (What DisplayCard takes) and DislpayCard
    mov edi, esi
    call DisplayCard
    inc esi ; Move onto next card position in hand

    jmp DisplayCardLoop

    DisplayHandDone: ; If we're done, exit the procedure
    ret

DisplayHand ENDP

;-------------------------------- Main Procedure 
;	Functional Details: This is the main body of the program which brings the 
;   previous procedures and other smaller functions and checks together. 
;   (Notes detailing each sections more specific functionality can be found 
;   below)
;	Inputs: User input is take if the player which to (H)it or (S)tand, and 
;   again at the end of the game if they signal they'd like to go again.
;	Outputs: There is a lot of output. A message welcoming the player, 
;   displaying theior starting hand, questions about hitting or standing, 
;   output about the computer players hand and actions, the game results, 
;   a choice propt to play again, and a goodbye message.
;	Registers:  EAX holds card and total score values, points to the current 
;               hand position. Also used in comparisons and for taking a char 
;               as input.
;               EDX is used often to hold offsets to display string messages.
;               ECX is used as a counter for initializing and shufflking the 
;               deck.
;               ESI generallty points to the current hand position.
;               EDI generally points to the Deck or currentDeckPosition
;	Memory Locations: Many, many message string offsets are used. Also 
;   significant is cardDeck which holds the shuffled cards. There's playerHand
;   and computerHand which reference which cards the respective entity is in 
;   posession of. Additionaly there's carHotOrStand which h9olds the useres 
;   desired next stem, and charTryAgain where the player can choose to continue 
;   playing or exit.
main PROC

    ; Display Main Welcome Message
    mov edx, OFFSET msgWelcome
    call WriteString
    call Crlf ; Add a line for formatting purposes

	; Initialize random seed generator	
	call Randomize

	; Initialize a Starting Deck
	mov edi, OFFSET cardDeck + SIZEOF cardDeck - 1
	mov ecx, LENGTHOF cardDeck - 1
	call InitializeStarterDeck

;-------------------------------- MainGameStart Loop Point
;	Functional Details: This is the marker for the complete restart of the game.
;   Here we re-initialize the game and deal 1 card to the player
MainGameStart: ; Game start marker in the case player wants to go again
    
    ; Initialize or re-initialize player and computer hand and deck position variables
    call InitializeForStart

    ; Shuffle that Deck
	mov edi, OFFSET cardDeck + SIZEOF cardDeck - 1
	mov ecx, LENGTHOF cardDeck - 1
	call ShuffleDeck

	mov edi, OFFSET cardDeck
	mov ecx, LENGTHOF cardDeck

    ; Initialize deckPosition and playerHandPosition for DealCard
    mov edi, deckPosition     ; Point to the top of the deck
    mov eax, playerHandPosition   ; Point to the player's hand

    ; Deal first card to the player
    call DealCard                ; Deal first card to player
    inc deckPosition
    mov edi, deckPosition
    inc playerHandPosition
    mov eax, playerHandPosition

;-------------------------------- MainPlayerDeal Loop Point
;	Functional Details: Here we begin by dealing another card to the player 
;   and total up our starting score before asking Hit or Stand? Also notable,
;   based on the total score of the posessed cards a player might automatically 
;   lose (comparison and jumped to the MainPlayerBust section) becasue of a 
;   bust!
MainPlayerDeal: ; Start of the looping player portion

    mov edi, deckPosition
    mov eax, playerHandPosition

    call DealCard                ; Deal another card to player
    inc deckPosition
    mov edi, deckPosition
    inc playerHandPosition
    mov eax, playerHandPosition

    ; Display the players hand message
    mov edx, OFFSET msgPlayerCard
    call WriteString
    call Crlf ; New line for readability

    ; Display the player's cards
    mov esi, OFFSET playerHand   ; Point to the player's hand
    call DisplayHand 

    ; Dislplay the current card total value message
    mov edx, OFFSET msgTotalValue
    call WriteString
    
    ; Calculate and display the total value of the player's hand
    mov esi, OFFSET playerHand
    call CalculateHandValue
    mov playerTotal, eax

    ; Print the total value
    call WriteDec
    call Crlf                    ; New line for readability

    ; Compare palyerTotal to 21, if greater, player has busted!
    mov eax, playerTotal
    cmp eax, 21
    ja MainPlayerBust

    ; Would you like to hit or stand section?

;-------------------------------- MainPlayerHitOrStand Loop Point
;	Functional Details: The player is given the option to hit or stand. Stand 
;   just continues to the computer's turn, while hit loops you up to recieve 
;   another card
MainPlayerHitOrStand:
	; Display Hit or Stand prompt (case insensitive)
	mov  edx,OFFSET msgHitOrStand
	call WriteString

	call ReadChar
	call WriteChar ; Display the character typed, this is necessary since ReadChar doesn't display the Char typed
	call Crlf ; Move the display line down 1
	call Crlf ; Move the display line down 1

	movsx eax, al ; we need to overwrite the rest of the EAX register with the sign from AL becasue ReadChar loads the value to AL
	mov charHitOrStand, al ; Store the read character in our memory operand

	; Convert input Char to Uppercase
	INVOKE Str_ucase, ADDR charHitOrStand
	
	; Compare input character to uppercase H, if uppercase H jump to MainPlayerDeal
	mov al, charHitOrStand
	cmp al, strH
	je MainPlayerDeal

	; Compare input to uppercase S, if equals, jump to MainComputerTurn
	cmp al, strS
	je MainComputerTurn

	; If neither y opr n was pressed, repeat prompt
	jmp MainPlayerHitOrStand

;-------------------------------- MainPlayerBust Loop Point
;	Functional Details: Here the player bust message is displayed and we're 
;   jumped to the MainComputerWin section.
MainPlayerBust:
    ; Dislpay Player Bust Message, add a carriage return
    mov edx, OFFSET msgPlayerBust
    call WriteString
    call Crlf

    jmp MainComputerWin

;-------------------------------- MainComputerTurn Loop Point
;	Functional Details: This is the beginnign of the Computer's turn. Pointers 
;   are set to the computerHand and one card is delt to the computer's hand.
MainComputerTurn:

    ; Display the Computer's Turn Message
    mov edx, OFFSET msgComputerTurn
    call WriteString
    call Crlf ; New line for readability

    ; Deal a card to the Computer
    mov edi, deckPosition     ; Point to the top of the deck
    mov eax, computerHandPosition   ; Point to the player's hand

    call DealCard                ; Deal first card to player
    inc deckPosition
    mov edi, deckPosition
    inc computerHandPosition
    mov eax, computerHandPosition

;-------------------------------- MainComputerRepeat Loop Point
;	Functional Details: Pratically this is the loop point for an additional 
;   card, initially to bring the computer's hand up to 1 and later for if the 
;   computer chooses to Hit (if it's score total is below 17). Also notable,
;   if the computer busts we're jumped to MainComputerBust and the player wins!
MainComputerRepeat:

    mov edi, deckPosition
    mov eax, computerHandPosition
    
    call DealCard                ; Deal first card to player
    inc deckPosition
    mov edi, deckPosition
    inc computerHandPosition
    mov eax, computerHandPosition

    ; Display the computer's hand message
    mov edx, OFFSET msgComputerCard
    call WriteString
    call Crlf ; New line for readability

    ; Display the player's cards
    mov esi, OFFSET computerHand   ; Point to the player's hand
    call DisplayHand 

    ; Dislplay the current card total value message
    mov edx, OFFSET msgTotalValue
    call WriteString
    
    ; Calculate and display the total value of the player's hand
    mov esi, OFFSET computerHand
    call CalculateHandValue
    mov computerTotal, eax

    ; Print the total value
    call WriteDec
    call Crlf                    ; New line for readability

    ; Compare palyerTotal to 21, if greater, player has busted!
    mov eax, computerTotal
    cmp eax, 21
    ja MainComputerBust

    ; Compare computerTotal to 17, if below get another card!
    cmp eax, 17
    jb MainComputerHit

;-------------------------------- MainCalculateWinner Loop Point
;	Functional Details: If neither the player or computer busts we have to 
;   determine who wins. First we display their hands and scores. Then we make 
;   some comparisons. If computerTotal and playerTotal are equal, there's a 
;   draw. If playerTotal is above, player wins. If playerTotal is below 
;   computer wins.
MainCalculateWinner:
   ; Display hands, and totals before making comparison and displaying outcome

    ; Display thses are the results message
    call Crlf ; Drop down a line for formatting purposes
    mov edx, OFFSET msgResults
    call WriteString
    call Crlf ; New line for readability
    call Crlf ; New line for readability

    ; --- Display the player's hand and total ---
    ; Display the players hand message
    mov edx, OFFSET msgPlayerCard
    call WriteString
    call Crlf ; New line for readability

    ; Display the player's cards
    mov esi, OFFSET playerHand   ; Point to the player's hand
    call DisplayHand 

    ; Dislplay the current card total value message
    mov edx, OFFSET msgTotalValue
    call WriteString
    
    ; Print the total value
    mov eax, playerTotal
    call WriteDec
    call Crlf ; New line for readability
    call Crlf ; New line for readability
    
    ; --- Display the computer's hand and total ---
    ; Display the computer's hand message
    mov edx, OFFSET msgComputerCard
    call WriteString
    call Crlf ; New line for readability

    ; Display the player's cards
    mov esi, OFFSET computerHand   ; Point to the player's hand
    call DisplayHand 

    ; Dislplay the current card total value message
    mov edx, OFFSET msgTotalValue
    call WriteString
       
    ; Print the total value
    mov eax, computerTotal
    call WriteDec
    call Crlf ; New line for readability
    call Crlf ; New line for readability

    ; Calculating Winner

    ;Move playerTotal into EAX for comparison
    mov eax, playerTotal
    cmp eax, computerTotal

    ; If equal, go to Draw!
    je MainDraw

    ; if above, go to Player Wins!
    ja MainPlayerWin

    ; if below, go to Computer Wins!
    jb MainComputerWin

;-------------------------------- MainComputerHit Loop Point
;	Functional Details: If the computer has chosen to hit we display a message 
;   and loop up to MainComputerRepeat for another card.
MainComputerHit:
    
    ; Display the Computer Hits message
    call Crlf ; Drop down a line for formatting purposes
    mov edx, OFFSET msgComputerHit
    call WriteString
    call Crlf ; Drop down a line for formatting purposes

    jmp MainComputerRepeat

;-------------------------------- MainComputerBust Loop Point
;	Functional Details: If the computer has busted we display a message and 
;   loop to MainPlayerWin
MainComputerBust:
    ; Dislpay Player Bust Message, add a carriage return
    mov edx, OFFSET msgComputerBust
    call WriteString
    call Crlf
    ;jmp MainPlayerWin

;-------------------------------- MainPlayerWin Loop Point
;	Functional Details: If the player wins we display a message and loop
;   to MainPlayAgain
MainPlayerWin:
    ;display computer wins message
    mov edx, OFFSET msgPlayerWin
    call WriteString
    call Crlf
    jmp MainPlayAgain

;-------------------------------- MainDraw Loop Point
;	Functional Details: If there's a draw, we display a message and loop
;   to MainPlayAgain
MainDraw:
    ; Display the Draw message
    mov edx, OFFSET msgDraw
    call WriteString
    call Crlf
    jmp MainPlayAgain

;-------------------------------- MainComputerWin Loop Point
;	Functional Details: If the computer wins we display a message and loop
;   to MainPlayAgain
MainComputerWin:
    ;display computer wins message
    mov edx, OFFSET msgComputerWin
    call WriteString
    call Crlf

;-------------------------------- MainPlayAgain Loop Point
;	Functional Details: Prompts the player and asks if they'd like to play 
;   again. Either loops to MainGameStart or MainExit depending.
MainPlayAgain:
    ; Display play again? prompt (case insensitive)
    call Crlf ; New line for readability
	mov  edx,OFFSET msgPlayAgain
	call WriteString

	call ReadChar
	call WriteChar ; Display the character typed, this is necessary since ReadChar doesn't display the Char typed
	call Crlf ; Move the display line down 1
	call Crlf ; Move the display line down 1

	movsx eax, al ; we need to overwrite the rest of the EAX register with the sign from AL becasue ReadChar loads the value to AL
	mov charPlayAgain, al ; Store the read character in our memory operand

	; Convert input Char to Uppercase
	INVOKE Str_ucase, ADDR charPlayAgain
	
	; Compare input character to uppercase H, if uppercase H jump to MainPlayerDeal
	mov al, charPlayAgain
	cmp al, strY
	je MainGameStart

	; Compare input to uppercase S, if equals, jump to MainComputerTurn
	cmp al, strN
	je MainExit

	; If neither y opr n was pressed, repeat prompt
	jmp MainPlayAgain

;-------------------------------- MainExit Loop Point
;	Functional Details: Well, we're really at the end. Dislpay a goodbye message.
;   to MainPlayAgain
MainExit: 
    ; Display goodbye message
    mov edx, OFFSET msgBye
    call WriteString

    ; Call Irvine's exit procedure
	exit
main ENDP
END main
