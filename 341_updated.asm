.MODEL SMALL
.STACK 100H

; ============================================
; MACROS dumb, repeated boilerplate only
; ============================================
PRINT_STR MACRO msg
    PUSH AX
    PUSH DX
    LEA DX, msg
    MOV AH, 09H
    INT 21H
    POP DX
    POP AX
ENDM

NEWLINE MACRO
    PUSH AX
    PUSH DX
    MOV AH, 09H
    LEA DX, CRLF
    INT 21H
    POP DX
    POP AX
ENDM

READ_STR MACRO buffer
    PUSH AX
    PUSH DX
    LEA DX, buffer
    MOV AH, 0AH
    INT 21H
    POP DX
    POP AX
ENDM

.DATA

    CRLF        DB 0DH, 0AH, '$'

    ; ============================================
    ; MAIN MENU
    ; ============================================
    MenuTitle   DB '=== EmuFlix: Cinema Ticket Booking System ===$'
    MenuOpt1    DB '1. Show Scheduling & Capacity Management$'
    MenuOpt2    DB '2. Seat Management & Reservation$'
    MenuOpt3    DB '3. Fare & Ticket Generation$'
    MenuOpt4    DB '4. Ticket Cancellation & Refund$'
    MenuOpt5    DB '5. Booking Search & History$'
    MenuOpt6    DB '6. Sales & Movie Statistics$'
    MenuOpt7    DB '7. Exit$'
    PromptMsg   DB 'Enter your choice (1-7): $'
    InvalidMsg  DB 'Invalid choice. Try again.$'
    ExitMsg     DB 'Exiting EmuFlix... Goodbye!$'

    StubMsg4    DB 'Cancellation & Refund module (stub).$'
    StubMsg5    DB 'Booking Search module (stub).$'
    StubMsg6    DB 'Sales Statistics module (stub).$'

    ChoiceBuf   DB 2, ?, ?


    ; ============================================
    ; FEATURE 1 SHOW SCHEDULING
    ; ============================================
    MAX_SHOWS   EQU 5
    MAX_SEATS   EQU 20

    MovieName   DB 100 DUP('$')
    ShowTime    DB 30  DUP('$')
    TicketPrice DW MAX_SHOWS DUP(0)
    SeatCap     DB MAX_SHOWS DUP(0)
    SeatsBooked DB MAX_SHOWS DUP(0)
    ShowActive  DB MAX_SHOWS DUP(0)

    ShowMenuTitle   DB 0DH,0AH,'--- Show Scheduling ---$'
    ShowSubOpt1     DB '1. Add New Show$'
    ShowSubOpt2     DB '2. Modify Existing Show$'
    ShowSubPrompt   DB 'Choice: $'

    NoSlotMsg       DB 'No free show slots available!$'
    AskMovie        DB 'Enter movie name (max 19 chars): $'
    AskTime         DB 'Enter show time (HH:MM, 5 chars): $'
    AskPrice        DB 'Enter ticket price (number): $'
    AskCap          DB 'Enter seat capacity (max 20): $'
    AskIndex        DB 'Enter show number to modify (1-5): $'
    InvalidCap      DB 'Invalid capacity! Must be 1-20.$'
    InvalidCapBooked DB 'Invalid capacity! Below seats already booked.$'
    InvalidPrice    DB 'Invalid price! Must be non-zero.$'
    ShowAddedMsg    DB 'Show added/updated successfully!$'
    InvalidIndexMsg DB 'Invalid show number!$'
    SlotInactive    DB 'That show slot is empty. Use Add instead.$'

    NumBuf      DB 7, ?, 7 DUP('$')
    ; For DOS function 0Ah, byte 1 must start at zero before input.
    ; It is the returned character count and may otherwise be reused
    ; as a recalled-input count on the next read.
    NameBuf     DB 19, 0, 20 DUP('$')
    TimeBuf     DB 6, ?, 6 DUP('$')

    TempWord    DW 0
    IsNewShow   DB 0    
    ShowNumLbl   DB 'Show Number : $'
    ShowPriceLbl DB 'Price       : $'
    ShowCapLbl   DB 'Capacity    : $'


    ; ============================================
    ; FEATURE 2 SEAT MANAGEMENT
    ; ============================================
    TOTAL_SEATS EQU MAX_SHOWS * MAX_SEATS

    SeatStatus  DB TOTAL_SEATS DUP(0)

    SeatMenuTitle   DB 0DH,0AH,'--- Seat Management ---$'
    SeatSubOpt1     DB '1. Display Seats for a Show$'
    SeatSubOpt2     DB '2. Reserve a Seat$'
    SeatSubPrompt   DB 'Choice: $'

    AskShowIdx      DB 'Enter show number (1-5): $'
    NoSuchShow      DB 'No active show at that number!$'
    AskSeatNum      DB 'Enter seat number to reserve: $'
    SeatLabel       DB 'Seat $'
    FreeLabel       DB ' : Free$'
    OccupiedLabel   DB ' : Occupied$'
    SeatOutOfRange  DB 'Invalid seat number for this show!$'
    SeatTaken       DB 'That seat is already booked!$'
    SeatReserved    DB 'Seat reserved successfully!$'

    ShowIdxHolder   DW 0
    SeatIdxHolder   DB 0


    ; ============================================
    ; BOOKING RECORDS
    ; ============================================
    MAX_BOOKINGS    EQU 20

    BookingID       DW MAX_BOOKINGS DUP(0)
    BookShowIdx     DB MAX_BOOKINGS DUP(0)
    BookSeatIdx     DB MAX_BOOKINGS DUP(0)
    CustName        DB 300 DUP('$')
    BookQty         DB MAX_BOOKINGS DUP(0)
    BookFare        DW MAX_BOOKINGS DUP(0)
    BookStatus      DB MAX_BOOKINGS DUP(0)

    ; Exact seat map for every booking
    ; Index = booking index * MAX_SEATS + local seat index
    BookSeatMap     DB (MAX_BOOKINGS * MAX_SEATS) DUP(0)

    NextBookingID   DW 1000

    CustNameBuf     DB 14, ?, 14 DUP('$')

    AskCustName       DB 'Enter customer name (max 14 chars): $'
    NoBookingSlot     DB 'Booking storage full! Cannot create record.$'
    BookingCreatedMsg DB 'Booking created! ID: $'


    ; ============================================
    ; FEATURE 3 FARE & TICKET GENERATION
    ; ============================================
    DISCOUNT_QTY_MIN EQU 3

    FareMenuTitle     DB 0DH,0AH,'--- Fare & Ticket Generation ---$'
    AskCategory       DB 'Select category: 1=Regular  2=VIP: $'
    AskQty            DB 'Enter number of tickets: $'

    InvalidCategory   DB 'Invalid category!$'
    NotEnoughSeats    DB 'Not enough free seats available for that quantity!$'
    InvalidQty        DB 'Invalid quantity! Must be at least 1.$'

    SeatsReservedLbl  DB 'Seats reserved: $'
    SeatSepSpace      DB ' $'

    TicketHeader      DB 0DH,0AH,'========= TICKET =========$'
    TktBookingIDLbl   DB 'Booking ID  : $'
    TktMovieLbl       DB 'Movie       : $'
    TktTimeLbl        DB 'Show Time   : $'
    TktCategoryLbl    DB 'Category    : $'
    RegularLbl        DB 'Regular$'
    VIPLbl            DB 'VIP$'
    TktQtyLbl         DB 'Quantity    : $'
    TktPerTicketLbl   DB 0DH,0AH,'Price/Ticket: $'
    TktSubtotalLbl    DB 0DH,0AH,'Subtotal    : $'
    TktDiscountLbl    DB 0DH,0AH,'Discount    : $'
    TktTotalLbl       DB 0DH,0AH,'Total Fare  : $'
    TicketFooter      DB 0DH,0AH,'===========================$'

    OrderShowIdx      DB 0
    OrderCategory     DB 0
    OrderQty          DW 0
    OrderPerTicket    DW 0
    OrderSubtotal     DW 0
    OrderDiscount     DW 0
    OrderTotal        DW 0
    OrderFirstSeat    DB 0
    OrderBookingID    DW 0

    SeatScanIdx       DB 0
    SeatsToGo         DW 0

    ; Tracks which local seats the current
    ; multi-seat order reserved
    OrderSeatFlags    DB MAX_SEATS DUP(0)


    ; ============================================
    ; FEATURE 4 CANCELLATION & REFUND
    ; ============================================
    CancelMenuTitle     DB 0DH,0AH,'--- Ticket Cancellation & Refund ---$'
    AskCancelBookingID  DB 'Enter Booking ID to cancel: $'
    BookingNotFoundMsg  DB 'No active booking found with that ID!$'
    CancelFoundMsg      DB 'Booking found:$'
    CancelSuccessMsg    DB 0DH,0AH,'Booking cancelled successfully!$'
    RefundLbl           DB 'Refund Amount: $'

    FindTargetID        DW 0
    CancelBookIdx       DW 0
    RefundAmount        DW 0

    RBS_BookIdx         DW 0
    RBS_LocalIdx        DW 0
    RBS_MapIdx          DW 0  
        ; ============================================
    ; FEATURE 5 BOOKING SEARCH & HISTORY
    ; ============================================
    BSMenuTitle        DB 0DH,0AH,'--- Booking Search & History ---$'
    BSMenuOptions      DB 0DH,0AH,'1. Search by Booking ID',0DH,0AH,'2. View All Booking History',0DH,0AH,'Enter choice (1-2): $'
    BSInvalidChoice    DB 'Invalid choice!$'
    AskSearchBookingID DB 'Enter Booking ID to search: $'
    BSMovieLbl         DB 'Movie       : $'
    BSCustLbl          DB 'Customer   : $'
    BSFareLbl          DB 'Fare       : $'
    BSStatusLbl        DB 'Status     : $'
    BSActiveLbl        DB 'Active$'
    BSCancelledLbl     DB 'Cancelled$'
    BSHistoryHeader    DB 0DH,0AH,'--- All Bookings ---$'
    BSSeparator        DB '------------------------------$'

    BSRecIdx DW 0   
        ; ============================================
    ; FEATURE 6 SALES & MOVIE STATISTICS
    ; ============================================
    SSMenuTitle        DB 0DH,0AH,'--- Sales & Movie Statistics ---$'
    SSOverallHeader    DB 0DH,0AH,'--- Overall Statistics ---$'
    SSTotalBookingsLbl DB 'Total Active Bookings : $'
    SSTotalTicketsLbl  DB 'Total Tickets Sold    : $'
    SSTotalRevenueLbl  DB 'Total Revenue         : $'
    SSPerShowHeader    DB 0DH,0AH,'--- Per-Show Statistics ---$'
    SSMovieLbl         DB 'Movie      : $'
    SSSeatsLbl         DB 'Seats Sold : $'
    SSSeatSlash        DB '/$'
    SSOccupancyLbl     DB 'Occupancy  : $'
    SSPercentSign      DB '%$'
    SSRevenueLbl       DB 'Revenue    : $'
    SSSeparator        DB '------------------------------$'
    SSNoActiveShows    DB 'No active shows to report.$'

    TotalActiveBookings DW 0
    TotalTicketsSold    DW 0
    TotalRevenue        DW 0
    SSShowTickets       DW 0
    SSShowRevenue       DW 0
    SSOccupancyPct      DW 0
    CS_ShowIdx          DB 0
    SSAnyActive         DB 0


.CODE

; ============================================
; MAIN
; ============================================
MAIN PROC

    MOV AX, @DATA
    MOV DS, AX

MENU_LOOP:

    PRINT_STR MenuTitle
    NEWLINE

    PRINT_STR MenuOpt1
    NEWLINE

    PRINT_STR MenuOpt2
    NEWLINE

    PRINT_STR MenuOpt3
    NEWLINE

    PRINT_STR MenuOpt4
    NEWLINE

    PRINT_STR MenuOpt5
    NEWLINE

    PRINT_STR MenuOpt6
    NEWLINE

    PRINT_STR MenuOpt7
    NEWLINE

    PRINT_STR PromptMsg

    READ_STR ChoiceBuf
    NEWLINE

    MOV AL, ChoiceBuf[2]

    CMP AL, '1'
    JE CALL_F1

    CMP AL, '2'
    JE CALL_F2

    CMP AL, '3'
    JE CALL_F3

    CMP AL, '4'
    JE CALL_F4

    CMP AL, '5'
    JE CALL_F5

    CMP AL, '6'
    JE CALL_F6

    CMP AL, '7'
    JE DO_EXIT

    PRINT_STR InvalidMsg
    NEWLINE

    JMP MENU_LOOP


CALL_F1:
    CALL ShowScheduling
    JMP MENU_LOOP

CALL_F2:
    CALL SeatManagement
    JMP MENU_LOOP

CALL_F3:
    CALL FareTicket
    JMP MENU_LOOP

CALL_F4:
    CALL CancelRefund
    JMP MENU_LOOP

CALL_F5:
    CALL BookingSearch
    JMP MENU_LOOP

CALL_F6:
    CALL SalesStatistics
    JMP MENU_LOOP


DO_EXIT:

    PRINT_STR ExitMsg
    NEWLINE

    MOV AH, 4CH
    INT 21H

MAIN ENDP


; ============================================
; ReadNumber
; Reads decimal number from NumBuf
; Returns value in AX
; ============================================
ReadNumber PROC

    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    READ_STR NumBuf
    NEWLINE

    MOV AX, 0
    MOV BX, 10

    XOR CX, CX
    MOV CL, NumBuf[1]

    LEA SI, NumBuf
    ADD SI, 2

RN_LOOP:

    CMP CX, 0
    JE RN_DONE

    XOR DX, DX
    MOV DL, [SI]

    CMP DL, '0'
    JB RN_DONE

    CMP DL, '9'
    JA RN_DONE

    SUB DL, '0'

    PUSH DX

    MUL BX

    POP DX

    ADD AX, DX

    INC SI
    DEC CX

    JMP RN_LOOP

RN_DONE:

    POP SI
    POP DX
    POP CX
    POP BX

    RET

ReadNumber ENDP


; ============================================
; PrintNumber
; Prints AX as decimal
; ============================================
PrintNumber PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 10
    XOR CX, CX

    CMP AX, 0
    JNE PN_LOOP

    MOV DL, '0'
    MOV AH, 02H
    INT 21H

    JMP PN_DONE


PN_LOOP:

    CMP AX, 0
    JE PN_PRINT

    XOR DX, DX
    DIV BX

    PUSH DX

    INC CX

    JMP PN_LOOP


PN_PRINT:

    CMP CX, 0
    JE PN_DONE

    POP DX

    ADD DL, '0'

    MOV AH, 02H
    INT 21H

    DEC CX

    JMP PN_PRINT


PN_DONE:

    POP DX
    POP CX
    POP BX
    POP AX

    RET

PrintNumber ENDP


; ============================================
; PrintStringAt
; DX = address of $ terminated string
; ============================================
PrintStringAt PROC

    PUSH AX
    PUSH DX
    PUSH SI

    ; Print one character at a time so a stray CR/LF stored in an
    ; input buffer cannot move the cursor back over an already-printed
    ; field label (for example, "Movie       : ").
    MOV SI, DX

PSA_NEXT:

    MOV DL, [SI]
    CMP DL, '$'
    JE PSA_DONE

    INC SI

    CMP DL, 20H
    JB PSA_NEXT
    CMP DL, 7FH
    JE PSA_NEXT

    MOV AH, 02H
    INT 21H
    JMP PSA_NEXT

PSA_DONE:

    POP SI
    POP DX
    POP AX

    RET

PrintStringAt ENDP


; ============================================
; FEATURE 1
; Show Scheduling
; ============================================
ShowScheduling PROC

    PRINT_STR ShowMenuTitle
    NEWLINE

    PRINT_STR ShowSubOpt1
    NEWLINE

    PRINT_STR ShowSubOpt2
    NEWLINE

    PRINT_STR ShowSubPrompt

    READ_STR ChoiceBuf
    NEWLINE

    MOV AL, ChoiceBuf[2]

    CMP AL, '1'
    JE SS_ADD

    CMP AL, '2'
    JE SS_MODIFY

    RET


SS_ADD:

    CALL FindFreeSlot

    CMP BX, -1
    JNE SS_ADD_CONT

    PRINT_STR NoSlotMsg
    NEWLINE

    RET


SS_ADD_CONT:

    MOV IsNewShow, 1

    JMP SS_FILL


SS_MODIFY:

    PRINT_STR AskIndex

    CALL ReadNumber

    DEC AX

    CMP AX, 0
    JL SS_BADINDEX

    CMP AX, MAX_SHOWS - 1
    JG SS_BADINDEX

    MOV BX, AX

    CMP ShowActive[BX], 1
    JE SS_MODIFY_CONT

    PRINT_STR SlotInactive
    NEWLINE

    RET


SS_MODIFY_CONT:

    MOV IsNewShow, 0

    JMP SS_FILL


SS_BADINDEX:

    PRINT_STR InvalidIndexMsg
    NEWLINE

    RET


SS_FILL:

    PRINT_STR AskMovie
    MOV BYTE PTR NameBuf[1], 0
    READ_STR NameBuf
    NEWLINE

    CALL CopyNameToSlot

    PRINT_STR AskTime
    READ_STR TimeBuf
    NEWLINE

    CALL CopyTimeToSlot

    PRINT_STR AskPrice

    CALL ReadNumber

    CMP AX, 0
    JE SS_BADPRICE

    MOV TempWord, AX

    MOV SI, BX
    SHL SI, 1

    MOV AX, TempWord
    MOV TicketPrice[SI], AX

    PRINT_STR AskCap

    CALL ReadNumber

    CMP AX, 1
    JL SS_BADCAP

    CMP AX, MAX_SEATS
    JG SS_BADCAP

        CMP IsNewShow, 1
    JNE SS_CAP_CHECK

    MOV SeatsBooked[BX], 0

SS_CAP_CHECK:

    CMP AL, SeatsBooked[BX]
    JB SS_BADCAP_BOOKED

    MOV SeatCap[BX], AL

SS_SKIP_RESET:

    MOV ShowActive[BX], 1

    PRINT_STR ShowAddedMsg
    NEWLINE

    PRINT_STR ShowNumLbl
    MOV AX, BX
    INC AX
    CALL PrintNumber
    NEWLINE

    PRINT_STR TktMovieLbl
    MOV AX, BX
    MOV CX, 20
    MUL CX
    LEA DX, MovieName
    ADD DX, AX
    CALL PrintStringAt
    NEWLINE

    PRINT_STR TktTimeLbl
    MOV AX, BX
    MOV CX, 6
    MUL CX
    LEA DX, ShowTime
    ADD DX, AX
    CALL PrintStringAt
    NEWLINE

    PRINT_STR ShowPriceLbl
    MOV SI, BX
    SHL SI, 1
    MOV AX, TicketPrice[SI]
    CALL PrintNumber
    NEWLINE

    PRINT_STR ShowCapLbl
    XOR AH, AH
    MOV AL, SeatCap[BX]
    CALL PrintNumber
    NEWLINE

    RET

SS_BADPRICE:

    PRINT_STR InvalidPrice
    NEWLINE

    RET


SS_BADCAP:

    PRINT_STR InvalidCap
    NEWLINE

    RET


SS_BADCAP_BOOKED:

    PRINT_STR InvalidCapBooked
    NEWLINE

    RET

ShowScheduling ENDP


; ============================================
; FindFreeSlot
; ============================================
FindFreeSlot PROC

    PUSH CX

    MOV BX, 0
    MOV CX, MAX_SHOWS

FFS_LOOP:

    CMP ShowActive[BX], 0
    JE FFS_FOUND

    INC BX

    LOOP FFS_LOOP

    MOV BX, -1

FFS_FOUND:

    POP CX

    RET

FindFreeSlot ENDP


; ============================================
; CopyNameToSlot
; ============================================
CopyNameToSlot PROC

    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI

    ; BX = show index
    ; Destination = MovieName + BX * 20

    MOV AX, BX
    MOV CX, 20
    MUL CX

    LEA DI, MovieName
    ADD DI, AX

    XOR CX, CX
    MOV CL, NameBuf[1]
    CMP CL, 19
    JBE CNS_OK
    MOV CL, 19
    
CNS_OK:

    LEA SI, NameBuf
    ADD SI, 2

CN_LOOP:

    CMP CX, 0
    JE CN_TERM

    MOV AL, [SI]
    INC SI
    DEC CX

    ; Keep only printable characters. This preserves the first real
    ; letter and prevents CR, LF, backspace, or other control bytes
    ; from altering the later screen output.
    CMP AL, 20H
    JB CN_LOOP
    CMP AL, 7FH
    JE CN_LOOP

    MOV [DI], AL
    INC DI

    JMP CN_LOOP

CN_TERM:

    MOV BYTE PTR [DI], '$'

    POP DI
    POP SI
    POP CX
    POP AX

    RET

CopyNameToSlot ENDP

; ============================================
; CopyTimeToSlot
; ============================================
CopyTimeToSlot PROC

    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI

    ; Find destination:
    ; show index * 6
    MOV AX, BX
    MOV CX, 6
    MUL CX

    LEA DI, ShowTime
    ADD DI, AX

    ; Number of characters entered
    XOR CX, CX
    MOV CL, TimeBuf[1]
    
    CMP CL, 5          
    JBE CT_LEN_OK 
    MOV CL, 5

CT_LEN_OK:

    ; Source = TimeBuf + 2
    LEA SI, TimeBuf
    ADD SI, 2

CT_LOOP:

    CMP CX, 0
    JE CT_TERM

    MOV AL, [SI]
    MOV [DI], AL

    INC SI
    INC DI

    DEC CX
    JMP CT_LOOP


CT_TERM:

    ; Always terminate with $
    MOV BYTE PTR [DI], '$'

    POP DI
    POP SI
    POP CX
    POP AX

    RET

CopyTimeToSlot ENDP


; ============================================
; SelectActiveShow
; ============================================
SelectActiveShow PROC

    PRINT_STR AskShowIdx

    CALL ReadNumber

    DEC AX

    CMP AX, 0
    JL SAS_BAD

    CMP AX, MAX_SHOWS - 1
    JG SAS_BAD

    MOV BX, AX

    CMP ShowActive[BX], 1
    JE SAS_OK


SAS_BAD:

    PRINT_STR NoSuchShow
    NEWLINE

    MOV BX, -1


SAS_OK:

    RET

SelectActiveShow ENDP


; ============================================
; DisplaySeatsForShow
; BX = show index
; ============================================
DisplaySeatsForShow PROC

    PUSH AX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV ShowIdxHolder, BX

    MOV AX, BX
    MOV CX, MAX_SEATS

    MUL CX

    MOV SI, AX

    NEWLINE

    XOR CX, CX
    MOV CL, SeatCap[BX]

    MOV DX, 1


DSF_LOOP:

    CMP CX, 0
    JE DSF_DONE

    PRINT_STR SeatLabel

    PUSH AX

    MOV AX, DX
    CALL PrintNumber

    POP AX

    CMP SeatStatus[SI], 0
    JE DSF_FREE

    PRINT_STR OccupiedLabel

    JMP DSF_NEXT


DSF_FREE:

    PRINT_STR FreeLabel


DSF_NEXT:

    NEWLINE

    INC SI
    INC DX
    DEC CX

    JMP DSF_LOOP


DSF_DONE:

    MOV BX, ShowIdxHolder

    POP SI
    POP DX
    POP CX
    POP AX

    RET

DisplaySeatsForShow ENDP


; ============================================
; ReserveSeat
; BX = show index
; ============================================
ReserveSeat PROC

    MOV ShowIdxHolder, BX

    PRINT_STR AskSeatNum

    CALL ReadNumber

    CMP AX, 1
    JL RS_BADRANGE

    MOV BX, ShowIdxHolder

    XOR CH, CH
    MOV CL, SeatCap[BX]

    CMP AX, CX
    JG RS_BADRANGE

    DEC AX

    MOV SeatIdxHolder, AL

    PUSH AX

    MOV AX, BX
    MOV CX, MAX_SEATS

    MUL CX

    POP CX

    ADD AX, CX

    MOV SI, AX

    CMP SeatStatus[SI], 1
    JE RS_TAKEN

    MOV SeatStatus[SI], 1

    INC SeatsBooked[BX]

    PRINT_STR SeatReserved
    NEWLINE

    MOV BX, ShowIdxHolder

    ; FIX:
    ; CreateBookingRecord expects AX = show index.
    MOV AX, BX

    CALL CreateBookingRecord

    RET


RS_TAKEN:

    PRINT_STR SeatTaken
    NEWLINE

    RET


RS_BADRANGE:

    PRINT_STR SeatOutOfRange
    NEWLINE

    RET

ReserveSeat ENDP


; ============================================
; SeatManagement
; ============================================
SeatManagement PROC

    PRINT_STR SeatMenuTitle
    NEWLINE

    PRINT_STR SeatSubOpt1
    NEWLINE

    PRINT_STR SeatSubOpt2
    NEWLINE

    PRINT_STR SeatSubPrompt

    READ_STR ChoiceBuf
    NEWLINE

    MOV AL, ChoiceBuf[2]

    CMP AL, '1'
    JE SM_DISPLAY

    CMP AL, '2'
    JE SM_RESERVE

    RET


SM_DISPLAY:

    CALL SelectActiveShow

    CMP BX, -1
    JE SM_DONE

    CALL DisplaySeatsForShow

    JMP SM_DONE


SM_RESERVE:

    CALL SelectActiveShow

    CMP BX, -1
    JE SM_DONE

    CALL ReserveSeat


SM_DONE:

    RET

SeatManagement ENDP


; ============================================
; FindFreeBookingSlot
; ============================================
FindFreeBookingSlot PROC

    PUSH CX

    MOV BX, 0
    MOV CX, MAX_BOOKINGS


FFB_LOOP:

    CMP BookStatus[BX], 0
    JE FFB_FOUND

    INC BX

    LOOP FFB_LOOP

    MOV BX, -1


FFB_FOUND:

    POP CX

    RET

FindFreeBookingSlot ENDP


; ============================================
; CreateBookingRecord
; Used by Feature 2
; ============================================
CreateBookingRecord PROC

    PUSH AX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH BX

    CALL FindFreeBookingSlot

    CMP BX, -1
    JNE CBR_CONT

    PRINT_STR NoBookingSlot
    NEWLINE

    POP BX

    JMP CBR_EXIT


CBR_CONT:

    MOV DI, BX

    POP BX

    MOV BookShowIdx[DI], AL

    MOV AL, SeatIdxHolder
    MOV BookSeatIdx[DI], AL

    PRINT_STR AskCustName

    READ_STR CustNameBuf
    NEWLINE

    MOV AX, DI
    MOV CX, 15

    MUL CX

    LEA BX, CustName
    ADD BX, AX

    LEA SI, CustNameBuf
    ADD SI, 2

    XOR CH, CH
    MOV CL, CustNameBuf[1]


CBR_COPY:

    CMP CX, 0
    JE CBR_TERM

    MOV AL, [SI]
    MOV [BX], AL

    INC SI
    INC BX

    DEC CX

    JMP CBR_COPY


CBR_TERM:

    MOV BYTE PTR [BX], '$'

    MOV BookQty[DI], 1

    XOR BX, BX

    MOV BL, BookShowIdx[DI]

    SHL BX, 1

    MOV AX, TicketPrice[BX]

    MOV SI, DI
    SHL SI, 1

    MOV BookFare[SI], AX

    MOV BookStatus[DI], 1

    MOV AX, NextBookingID

    MOV SI, DI
    SHL SI, 1

    MOV BookingID[SI], AX

    INC NextBookingID

    PRINT_STR BookingCreatedMsg

    CALL PrintNumber

    NEWLINE


CBR_EXIT:

    POP DI
    POP SI
    POP DX
    POP CX
    POP AX

    RET

CreateBookingRecord ENDP


; ============================================================
; FEATURE 3
; Reserve multiple seats
; ============================================================
ReserveNSeats PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV SeatScanIdx, 0

    MOV AX, OrderQty
    MOV SeatsToGo, AX

    MOV OrderFirstSeat, 0FFH

    ; Clear seat-tracking flags for this new order
    LEA SI, OrderSeatFlags
    MOV CX, MAX_SEATS
    MOV AL, 0

OSF_CLR:

    MOV [SI], AL
    INC SI

    LOOP OSF_CLR

    ; BX = selected show index
    MOV BL, OrderShowIdx
    XOR BH, BH

    ; Calculate base offset:
    ; show index * MAX_SEATS
    XOR AH, AH
    MOV AL, OrderShowIdx

    MOV CX, MAX_SEATS
    MUL CX

    MOV SI, AX


RNS_LOOP:

    ; Stop when all requested seats are reserved
    MOV AX, SeatsToGo

    CMP AX, 0
    JE RNS_DONE

    ; Convert current seat scan index to word
    MOV AL, SeatScanIdx
    XOR AH, AH

    ; HARD CAPACITY CHECK
    ; SeatScanIdx must be < SeatCap[show]
    CMP AL, SeatCap[BX]
    JAE RNS_DONE

    ; DI = base offset + local seat index
    MOV DI, SI
    ADD DI, AX

    ; Check whether seat is free
    CMP SeatStatus[DI], 0
    JNE RNS_SKIP

    ; Reserve seat
    MOV SeatStatus[DI], 1

    INC SeatsBooked[BX]

    ; Mark this local seat as belonging to this order
    PUSH BX

    LEA BX, OrderSeatFlags
    ADD BX, AX

    MOV BYTE PTR [BX], 1

    POP BX

    ; Save first reserved seat
    CMP OrderFirstSeat, 0FFH
    JNE RNS_PRINT

    MOV OrderFirstSeat, AL


RNS_PRINT:

    ; Display seat number as 1-based
    PUSH AX

    INC AX

    CALL PrintNumber

    PRINT_STR SeatSepSpace

    POP AX

    ; One less seat required
    MOV DX, SeatsToGo
    DEC DX
    MOV SeatsToGo, DX


RNS_SKIP:

    INC SeatScanIdx

    JMP RNS_LOOP


RNS_DONE:

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

ReserveNSeats ENDP


; ============================================================
; FEATURE 3
; Create one booking record for the whole order
; ============================================================
CreateOrderBookingRecord PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI

    CALL FindFreeBookingSlot

    CMP BX, -1
    JNE COB_CONT

    PRINT_STR NoBookingSlot
    NEWLINE

    MOV OrderBookingID, 0FFFFH

    JMP COB_EXIT


COB_CONT:

    MOV DI, BX

    ; Store show index
    MOV AL, OrderShowIdx
    MOV BookShowIdx[DI], AL

    ; Store first reserved seat
    MOV AL, OrderFirstSeat
    MOV BookSeatIdx[DI], AL

    ; Customer name
    PRINT_STR AskCustName

    READ_STR CustNameBuf
    NEWLINE

    ; Calculate DI * 15
    MOV AX, DI
    MOV CX, 15

    MUL CX

    LEA BX, CustName
    ADD BX, AX

    LEA SI, CustNameBuf
    ADD SI, 2

    XOR CH, CH
    MOV CL, CustNameBuf[1]


COB_COPY:

    CMP CX, 0
    JE COB_TERM

    MOV AL, [SI]
    MOV [BX], AL

    INC SI
    INC BX

    DEC CX

    JMP COB_COPY


COB_TERM:

    MOV BYTE PTR [BX], '$'

    ; Store quantity
    MOV AX, OrderQty
    MOV BookQty[DI], AL

    ; Store fare
    MOV SI, DI
    SHL SI, 1

    MOV AX, OrderTotal
    MOV BookFare[SI], AX

    ; Active booking
    MOV BookStatus[DI], 1

    ; Booking ID
    MOV AX, NextBookingID

    MOV BookingID[SI], AX

    MOV OrderBookingID, AX

    INC NextBookingID

    ; Copy this order's seat flags into BookSeatMap
    ; Index = booking index * MAX_SEATS + local seat index
    MOV AX, DI
    MOV CX, MAX_SEATS

    MUL CX

    MOV BX, AX

    LEA SI, OrderSeatFlags
    MOV CX, MAX_SEATS


COB_MAP_COPY:

    MOV AL, [SI]
    MOV BookSeatMap[BX], AL

    INC SI
    INC BX

    LOOP COB_MAP_COPY


COB_EXIT:

    POP DI
    POP SI
    POP CX
    POP BX
    POP AX

    RET

CreateOrderBookingRecord ENDP


; ============================================================
; FEATURE 3
; Display generated ticket
; ============================================================
DisplayTicket PROC

    PUSH AX
    PUSH CX
    PUSH DX

    ; If booking failed, don't display ticket
    CMP OrderBookingID, 0FFFFH
    JE DT_EXIT


    PRINT_STR TicketHeader
    NEWLINE


    ; Booking ID
    PRINT_STR TktBookingIDLbl

    MOV AX, OrderBookingID
    CALL PrintNumber

    NEWLINE


    ; Movie name
    PRINT_STR TktMovieLbl

    XOR AX, AX
    MOV AL, OrderShowIdx
    
    MOV BX, 20
    MUL BX
    
    LEA DX, MovieName
    ADD DX, AX
    
    CALL PrintStringAt

    NEWLINE


    ; Show time
    PRINT_STR TktTimeLbl

    XOR AX, AX
    MOV AL, OrderShowIdx
    
    MOV BX, 6
    MUL BX
    
    LEA DX, ShowTime
    ADD DX, AX
    
    CALL PrintStringAt
    NEWLINE


    ; Category
    PRINT_STR TktCategoryLbl

    CMP OrderCategory, 2
    JE DT_VIP

    PRINT_STR RegularLbl

    JMP DT_CATDONE


DT_VIP:

    PRINT_STR VIPLbl


DT_CATDONE:

    NEWLINE


    ; Quantity
    PRINT_STR TktQtyLbl

    MOV AX, OrderQty
    CALL PrintNumber

    NEWLINE


    ; Price per ticket
    PRINT_STR TktPerTicketLbl

    MOV AX, OrderPerTicket
    CALL PrintNumber

    NEWLINE


    ; Subtotal
    PRINT_STR TktSubtotalLbl

    MOV AX, OrderSubtotal
    CALL PrintNumber

    NEWLINE


    ; Discount
    PRINT_STR TktDiscountLbl

    MOV AX, OrderDiscount
    CALL PrintNumber

    NEWLINE


    ; Total
    PRINT_STR TktTotalLbl

    MOV AX, OrderTotal
    CALL PrintNumber

    NEWLINE


    PRINT_STR TicketFooter
    NEWLINE


DT_EXIT:

    POP DX
    POP CX
    POP AX

    RET

DisplayTicket ENDP


; ============================================================
; FEATURE 3
; Fare & Ticket Generation
; ============================================================
FareTicket PROC

    PRINT_STR FareMenuTitle
    NEWLINE


    ; --------------------------------------------
    ; Select show
    ; --------------------------------------------
    CALL SelectActiveShow

    CMP BX, -1
    JE FT_EXIT

    MOV OrderShowIdx, BL


    ; --------------------------------------------
    ; Select category
    ; --------------------------------------------
    PRINT_STR AskCategory

    CALL ReadNumber

    CMP AX, 1
    JE FT_CATEGORY_OK

    CMP AX, 2
    JE FT_CATEGORY_OK

    PRINT_STR InvalidCategory
    NEWLINE

    JMP FT_EXIT


FT_CATEGORY_OK:

    MOV OrderCategory, AL


    ; --------------------------------------------
    ; Enter quantity
    ; --------------------------------------------
    PRINT_STR AskQty

    CALL ReadNumber

    CMP AX, 1
    JL FT_BADQTY

    MOV OrderQty, AX


    ; --------------------------------------------
    ; Calculate available seats
    ; --------------------------------------------
    MOV BL, OrderShowIdx
    XOR BH, BH

    ; AX = capacity
    MOV AL, SeatCap[BX]
    XOR AH, AH

    ; CX = seats already booked
    MOV CL, SeatsBooked[BX]
    XOR CH, CH

    ; Prevent underflow
    CMP AX, CX
    JB FT_NO_SEATS

    ; AX = available seats
    SUB AX, CX

    ; Check requested quantity
    CMP OrderQty, AX
    JA FT_NOTENOUGH


    ; --------------------------------------------
    ; Get admin-set ticket price
    ; --------------------------------------------
    MOV BL, OrderShowIdx
    XOR BH, BH

    SHL BX, 1

    MOV AX, TicketPrice[BX]

    MOV OrderPerTicket, AX


    ; --------------------------------------------
    ; Subtotal = price * quantity
    ; --------------------------------------------
    MOV CX, OrderQty

    MUL CX

    MOV OrderSubtotal, AX


    ; --------------------------------------------
    ; Default discount = 0
    ; --------------------------------------------
    MOV OrderDiscount, 0


    ; --------------------------------------------
    ; 10% discount if quantity >= 3
    ; --------------------------------------------
    MOV AX, OrderQty

    CMP AX, DISCOUNT_QTY_MIN
    JB FT_NO_DISCOUNT


    MOV AX, OrderSubtotal

    MOV CX, 10

    XOR DX, DX

    DIV CX

    MOV OrderDiscount, AX


FT_NO_DISCOUNT:


    ; --------------------------------------------
    ; Total = subtotal - discount
    ; --------------------------------------------
    MOV AX, OrderSubtotal

    SUB AX, OrderDiscount

    MOV OrderTotal, AX


    ; --------------------------------------------
    ; Reserve required seats
    ; --------------------------------------------
    PRINT_STR SeatsReservedLbl

    CALL ReserveNSeats

    NEWLINE


    ; --------------------------------------------
    ; Create booking record
    ; --------------------------------------------
    CALL CreateOrderBookingRecord


    ; --------------------------------------------
    ; Display ticket
    ; --------------------------------------------
    CALL DisplayTicket

    JMP FT_EXIT


FT_BADQTY:

    PRINT_STR InvalidQty
    NEWLINE

    JMP FT_EXIT


FT_NOTENOUGH:

    PRINT_STR NotEnoughSeats
    NEWLINE

    JMP FT_EXIT


FT_NO_SEATS:

    PRINT_STR NotEnoughSeats
    NEWLINE


FT_EXIT:

    RET

FareTicket ENDP


; ============================================================
; FEATURE 4
; FindBookingByID
;
; Input:
;   AX = booking ID
;
; Output:
;   DI = matching booking index
;   DI = -1 if not found
; ============================================================
FindBookingByID PROC

    PUSH BX
    PUSH CX
    PUSH SI

    MOV FindTargetID, AX

    MOV BX, 0
    MOV CX, MAX_BOOKINGS

FBI_LOOP:

    CMP BookStatus[BX], 1
    JNE FBI_NEXT

    MOV SI, BX
    SHL SI, 1

    MOV AX, BookingID[SI]

    CMP AX, FindTargetID
    JE FBI_FOUND

FBI_NEXT:

    INC BX
    LOOP FBI_LOOP

    MOV DI, -1
    JMP FBI_EXIT

FBI_FOUND:

    MOV DI, BX

FBI_EXIT:

    POP SI
    POP CX
    POP BX

    RET

FindBookingByID ENDP


; ============================================================
; FEATURE 4
; ReleaseBookingSeats
;
; Input:
;   DI = booking record index
;
; Releases all seats belonging to this booking.
; ============================================================
ReleaseBookingSeats PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; Save booking index
    MOV RBS_BookIdx, DI

    ; --------------------------------------------
    ; Get show index
    ; --------------------------------------------
    XOR AX, AX
    MOV AL, BookShowIdx[DI]
    MOV BX, AX

    ; --------------------------------------------
    ; Calculate show seat base:
    ; show index * MAX_SEATS
    ; --------------------------------------------
    MOV AX, BX
    MOV CX, MAX_SEATS
    MUL CX

    MOV SI, AX


    ; --------------------------------------------
    ; Check booking quantity
    ; --------------------------------------------
    CMP BookQty[DI], 1
    JNE RBS_MULTI


    ; --------------------------------------------
    ; SINGLE SEAT BOOKING
    ; --------------------------------------------
    XOR AX, AX
    MOV AL, BookSeatIdx[DI]

    MOV DI, SI
    ADD DI, AX

    CMP SeatStatus[DI], 1
    JNE RBS_DONE

    MOV SeatStatus[DI], 0

    CMP SeatsBooked[BX], 0
    JE RBS_DONE

    DEC SeatsBooked[BX]

    JMP RBS_DONE


    ; --------------------------------------------
    ; MULTI-SEAT BOOKING
    ; --------------------------------------------
RBS_MULTI:

    MOV RBS_LocalIdx, 0

RBS_MULTI_LOOP:

    MOV AX, RBS_LocalIdx

    CMP AX, MAX_SEATS
    JAE RBS_DONE


    ; --------------------------------------------
    ; Calculate booking seat-map index:
    ; booking index * MAX_SEATS + local seat
    ; --------------------------------------------
    MOV AX, RBS_BookIdx
    MOV CX, MAX_SEATS
    MUL CX

    ADD AX, RBS_LocalIdx

    MOV RBS_MapIdx, AX

    MOV DI, AX

    ; Check whether this seat belongs
    ; to the booking
    CMP BookSeatMap[DI], 1
    JNE RBS_MULTI_SKIP


    ; Clear booking seat-map entry
    MOV BookSeatMap[DI], 0


    ; --------------------------------------------
    ; Calculate actual SeatStatus index:
    ; show base + local seat
    ; --------------------------------------------
    MOV AX, RBS_LocalIdx

    MOV DI, SI
    ADD DI, AX


    ; Release seat
    CMP SeatStatus[DI], 1
    JNE RBS_MULTI_SKIP

    MOV SeatStatus[DI], 0

    CMP SeatsBooked[BX], 0
    JE RBS_MULTI_SKIP

    DEC SeatsBooked[BX]


RBS_MULTI_SKIP:

    MOV AX, RBS_LocalIdx
    INC AX
    MOV RBS_LocalIdx, AX

    JMP RBS_MULTI_LOOP


RBS_DONE:

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

ReleaseBookingSeats ENDP


; ============================================================
; FEATURE 4
; Ticket Cancellation & Refund
; ============================================================
CancelRefund PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    PRINT_STR CancelMenuTitle
    NEWLINE

    PRINT_STR AskCancelBookingID

    CALL ReadNumber

    ; AX = entered booking ID
    CALL FindBookingByID

    CMP DI, -1
    JE CR_NOTFOUND

    ; Save booking index
    MOV CancelBookIdx, DI


    ; --------------------------------------------
    ; Display booking information
    ; --------------------------------------------
    PRINT_STR CancelFoundMsg
    NEWLINE


    ; Booking ID
    PRINT_STR TktBookingIDLbl

    MOV SI, CancelBookIdx
    SHL SI, 1

    MOV AX, BookingID[SI]
    CALL PrintNumber

    NEWLINE


    ; --------------------------------------------
    ; Movie
    ; --------------------------------------------
    PRINT_STR TktMovieLbl

    MOV DI, CancelBookIdx

    XOR AX, AX
    MOV AL, BookShowIdx[DI]

    MOV BX, 20
    MUL BX

    LEA DX, MovieName
    ADD DX, AX

    CALL PrintStringAt

    NEWLINE


    ; --------------------------------------------
    ; Quantity
    ; --------------------------------------------
    PRINT_STR TktQtyLbl

    MOV DI, CancelBookIdx

    XOR AX, AX
    MOV AL, BookQty[DI]

    CALL PrintNumber

    NEWLINE


    ; --------------------------------------------
    ; Get original fare BEFORE changing record
    ; --------------------------------------------
    MOV DI, CancelBookIdx

    MOV SI, DI
    SHL SI, 1

    MOV AX, BookFare[SI]

    MOV RefundAmount, AX


    ; --------------------------------------------
    ; Release all seats
    ; --------------------------------------------
    MOV DI, CancelBookIdx

    CALL ReleaseBookingSeats


    ; --------------------------------------------
    ; Mark booking as cancelled
    ;
    ; 1 = active
    ; 2 = cancelled
    ; --------------------------------------------
    MOV DI, CancelBookIdx

    MOV BookStatus[DI], 2


    ; --------------------------------------------
    ; Display refund
    ; --------------------------------------------
    PRINT_STR CancelSuccessMsg
    NEWLINE

    PRINT_STR RefundLbl

    MOV AX, RefundAmount
    CALL PrintNumber

    NEWLINE

    JMP CR_EXIT


CR_NOTFOUND:

    PRINT_STR BookingNotFoundMsg
    NEWLINE


CR_EXIT:

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

CancelRefund ENDP

; ============================================
; FEATURE 5 STUB
; ============================================ 

; ; ============================================================
; FEATURE 5
; FindBookingByIDAny
; Input : AX = booking ID to search for
; Output: DI = index of matching booking (ACTIVE or CANCELLED),
;         or -1. Unlike Feature 4's FindBookingByID, this
;         matches any non-empty slot (BookStatus <> 0), since
;         history needs to find cancelled bookings too.
; ============================================================
FindBookingByIDAny PROC

    PUSH BX
    PUSH CX
    PUSH SI

    MOV FindTargetID, AX

    MOV BX, 0
    MOV CX, MAX_BOOKINGS

FBA_LOOP:

    CMP BookStatus[BX], 0
    JE FBA_NEXT

    MOV SI, BX
    SHL SI, 1

    MOV AX, BookingID[SI]
    CMP AX, FindTargetID
    JE FBA_FOUND

FBA_NEXT:

    INC BX
    LOOP FBA_LOOP

    MOV DI, -1
    JMP FBA_EXIT

FBA_FOUND:

    MOV DI, BX

FBA_EXIT:

    POP SI
    POP CX
    POP BX

    RET

FindBookingByIDAny ENDP

; ============================================================
; FEATURE 5
; PrintBookingDetails
; Input: DI = booking record index (any status)
; Prints full record: ID, Movie, Show Time, Customer,
; Quantity, Fare, Status.
; ============================================================
PrintBookingDetails PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV BSRecIdx, DI

    PRINT_STR TktBookingIDLbl

    MOV AX, BSRecIdx
    SHL AX, 1
    MOV SI, AX
    MOV AX, BookingID[SI]
    CALL PrintNumber
    NEWLINE

    ; Use the booking-history label here rather than a ticket label.
    ; Keep the record index in DI while calculating its show slot.
    PRINT_STR BSMovieLbl

    MOV DI, BSRecIdx
    XOR AX, AX
    MOV AL, BookShowIdx[DI]
    MOV BX, 20
    MUL BX
    LEA DX, MovieName
    ADD DX, AX
    CALL PrintStringAt
    NEWLINE

    PRINT_STR TktTimeLbl

    MOV DI, BSRecIdx
    XOR AX, AX
    MOV AL, BookShowIdx[DI]
    MOV BX, 6
    MUL BX
    LEA DX, ShowTime
    ADD DX, AX
    CALL PrintStringAt
    NEWLINE

    PRINT_STR BSCustLbl

    MOV AX, BSRecIdx
    MOV CX, 15
    MUL CX
    LEA DX, CustName
    ADD DX, AX
    CALL PrintStringAt
    NEWLINE

    PRINT_STR TktQtyLbl

    MOV DI, BSRecIdx
    XOR AX, AX
    MOV AL, BookQty[DI]
    CALL PrintNumber
    NEWLINE

    PRINT_STR BSFareLbl

    MOV AX, BSRecIdx
    SHL AX, 1
    MOV SI, AX
    MOV AX, BookFare[SI]
    CALL PrintNumber
    NEWLINE

    PRINT_STR BSStatusLbl

    MOV DI, BSRecIdx
    CMP BookStatus[DI], 1
    JE BSD_ACTIVE

    PRINT_STR BSCancelledLbl
    JMP BSD_STATUS_DONE

BSD_ACTIVE:

    PRINT_STR BSActiveLbl

BSD_STATUS_DONE:

    NEWLINE

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

PrintBookingDetails ENDP

; ============================================================
; FEATURE 5
; PrintAllBookingHistory
; Loops every booking slot; prints details for any slot with
; BookStatus <> 0 (active or cancelled).
; ============================================================
PrintAllBookingHistory PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    PRINT_STR BSHistoryHeader
    NEWLINE

    MOV BX, 0
    MOV CX, MAX_BOOKINGS

PAH_LOOP:

    CMP BookStatus[BX], 0
    JE PAH_NEXT

    MOV DI, BX
    CALL PrintBookingDetails

    PRINT_STR BSSeparator
    NEWLINE

PAH_NEXT:

    INC BX
    LOOP PAH_LOOP

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

PrintAllBookingHistory ENDP

; ============================================================
; FEATURE 5
; Booking Search & History menu entry point
; ============================================================
BookingSearch PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    PRINT_STR BSMenuTitle
    NEWLINE

    PRINT_STR BSMenuOptions

    CALL ReadNumber

    CMP AX, 1
    JE BS_SEARCH

    CMP AX, 2
    JE BS_HISTORY

    PRINT_STR BSInvalidChoice
    NEWLINE

    JMP BS_EXIT

BS_SEARCH:

    PRINT_STR AskSearchBookingID

    CALL ReadNumber

    CALL FindBookingByIDAny

    CMP DI, -1
    JE BS_NOTFOUND

    CALL PrintBookingDetails

    JMP BS_EXIT

BS_NOTFOUND:

    PRINT_STR BookingNotFoundMsg
    NEWLINE

    JMP BS_EXIT

BS_HISTORY:

    CALL PrintAllBookingHistory

BS_EXIT:

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

BookingSearch ENDP

; ============================================
; FEATURE 6 STUB
; ============================================
; ============================================================
; FEATURE 6
; CalcOverallStats
; Sums active bookings, tickets sold, and revenue across the
; entire booking table (BookStatus = 1 only cancelled
; bookings are excluded, matching "refunded ticket" semantics).
; ============================================================
CalcOverallStats PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI

    MOV TotalActiveBookings, 0
    MOV TotalTicketsSold, 0
    MOV TotalRevenue, 0

    MOV BX, 0
    MOV CX, MAX_BOOKINGS

COS_LOOP:

    CMP BookStatus[BX], 1
    JNE COS_NEXT

    INC TotalActiveBookings

    XOR AH, AH
    MOV AL, BookQty[BX]
    ADD TotalTicketsSold, AX

    MOV SI, BX
    SHL SI, 1
    MOV AX, BookFare[SI]
    ADD TotalRevenue, AX

COS_NEXT:

    INC BX
    LOOP COS_LOOP

    POP SI
    POP CX
    POP BX
    POP AX

    RET

CalcOverallStats ENDP

; ============================================================
; FEATURE 6
; CalcShowStats
; Input : AL = show index (0-based)
; Output: SSShowTickets, SSShowRevenue (active bookings only,
;         for that show)
; ============================================================
CalcShowStats PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI

    MOV CS_ShowIdx, AL

    MOV SSShowTickets, 0
    MOV SSShowRevenue, 0

    MOV BX, 0
    MOV CX, MAX_BOOKINGS

CSS_LOOP:

    CMP BookStatus[BX], 1
    JNE CSS_NEXT

    MOV AL, BookShowIdx[BX]
    CMP AL, CS_ShowIdx
    JNE CSS_NEXT

    XOR AH, AH
    MOV AL, BookQty[BX]
    ADD SSShowTickets, AX

    MOV SI, BX
    SHL SI, 1
    MOV AX, BookFare[SI]
    ADD SSShowRevenue, AX

CSS_NEXT:

    INC BX
    LOOP CSS_LOOP

    POP SI
    POP CX
    POP BX
    POP AX

    RET

CalcShowStats ENDP

; ============================================================
; FEATURE 6
; PrintOverallStats
; ============================================================
PrintOverallStats PROC

    PUSH AX

    CALL CalcOverallStats

    PRINT_STR SSOverallHeader
    NEWLINE

    PRINT_STR SSTotalBookingsLbl
    MOV AX, TotalActiveBookings
    CALL PrintNumber
    NEWLINE

    PRINT_STR SSTotalTicketsLbl
    MOV AX, TotalTicketsSold
    CALL PrintNumber
    NEWLINE

    PRINT_STR SSTotalRevenueLbl
    MOV AX, TotalRevenue
    CALL PrintNumber
    NEWLINE

    POP AX

    RET

PrintOverallStats ENDP

; ============================================================
; FEATURE 6
; PrintPerShowStats
; Loops every show slot with ShowActive = 1; prints movie
; name, seats sold/capacity, occupancy %, and revenue.
; ============================================================
PrintPerShowStats PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    PRINT_STR SSPerShowHeader
    NEWLINE

    MOV SSAnyActive, 0

    MOV BX, 0
    MOV CX, MAX_SHOWS

PPS_LOOP:

    CMP ShowActive[BX], 1
    JNE PPS_NEXT

    MOV SSAnyActive, 1

    PRINT_STR SSMovieLbl

    MOV AX, BX
    MOV DX, 20
    MUL DX
    LEA DX, MovieName
    ADD DX, AX
    PUSH BX
    CALL PrintStringAt
    POP BX
    NEWLINE

    PRINT_STR SSSeatsLbl

    XOR AH, AH
    MOV AL, SeatsBooked[BX]
    PUSH BX
    CALL PrintNumber
    POP BX

    PRINT_STR SSSeatSlash

    XOR AH, AH
    MOV AL, SeatCap[BX]
    PUSH BX
    CALL PrintNumber
    POP BX
    NEWLINE

    PRINT_STR SSOccupancyLbl

    CMP SeatCap[BX], 0
    JE PPS_ZERO_OCC

    PUSH CX

    XOR AH, AH
    MOV AL, SeatsBooked[BX]
    MOV CX, 100
    MUL CX
    MOV CL, SeatCap[BX]
    DIV CL
    XOR AH, AH
    MOV SSOccupancyPct, AX

    POP CX

    JMP PPS_PRINT_OCC

PPS_ZERO_OCC:

    MOV SSOccupancyPct, 0

PPS_PRINT_OCC:

    PUSH BX
    MOV AX, SSOccupancyPct
    CALL PrintNumber
    POP BX

    PRINT_STR SSPercentSign
    NEWLINE

    PRINT_STR SSRevenueLbl

    MOV AL, BL
    PUSH BX
    CALL CalcShowStats
    POP BX

    MOV AX, SSShowRevenue
    PUSH BX
    CALL PrintNumber
    POP BX
    NEWLINE

    PRINT_STR SSSeparator
    NEWLINE

PPS_NEXT:

    INC BX
    LOOP PPS_LOOP

    CMP SSAnyActive, 0
    JNE PPS_DONE

    PRINT_STR SSNoActiveShows
    NEWLINE

PPS_DONE:

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

PrintPerShowStats ENDP

; ============================================================
; FEATURE 6
; Sales & Movie Statistics menu entry point
; ============================================================
SalesStatistics PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    PRINT_STR SSMenuTitle
    NEWLINE

    CALL PrintOverallStats
    CALL PrintPerShowStats

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

SalesStatistics ENDP


END MAIN
