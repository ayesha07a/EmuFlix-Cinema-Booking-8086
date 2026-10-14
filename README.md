EmuFlix: Cinema Ticket Booking System

EmuFlix is a menu-driven cinema ticket booking system written entirely in 8086 assembly language for the EMU8086 emulator. It uses macros, procedures, arrays, and stack-based register preservation throughout.

Features
Show Scheduling & Capacity Management: add or modify shows (movie name, time, ticket price, seat capacity up to 20) and view a confirmation of what was saved.
Seat Management & Reservation: display the seat map for a show and reserve individual seats.
Fare & Ticket Generation: book multiple tickets in Regular or VIP category, apply a bulk discount, and print a formatted ticket.
Ticket Cancellation & Refund: cancel an active booking by ID, release exactly the seats that booking reserved (even when they are non-contiguous), and refund the full fare.
Booking Search & History: search any booking by ID or view all bookings, active and cancelled.
Sales & Movie Statistics: total bookings, tickets sold, and revenue, plus per-show seats sold, occupancy percentage, and revenue.
Technical highlights
Per-booking seat tracking (BookSeatMap) so cancellations release only the seats that booking owns.
Flat-array indexing for seats, bookings, and show data.
DOS INT 21h for all input and output.
Consistent PUSH/POP register preservation across all procedures.
