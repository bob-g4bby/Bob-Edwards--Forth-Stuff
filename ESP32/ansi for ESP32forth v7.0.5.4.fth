\ ANSI terminal control words for ESP32forth v7.0.5.4 - copied from v7.0.7.21 by Bob Edwards Oct 2025

forth
vocabulary ansi
ansi definitions

: esc           ( -- )
    27 emit
;

: bel           ( -- )
    7 emit
;

: clear-to-eol  ( -- )
    esc s" [0K" type
;

: hide          ( -- )
    esc s" [?25l" type
;

: scroll-down   ( -- )
    esc s" D" type
;

: scroll-up     ( -- )
    esc s" M" type
;

: show          ( -- )
    esc s" [?25h" type
;

: terminal-restore  ( -- )
    esc s" [?1049l" type
;

: terminal-save     ( -- )
    esc s" [?1049h" type
;

forth definitions
only forth also ansi

: at-xy         ( x y -- )
    esc s" [" type 1+ n. s" ;" type 1+ n. s" H" type
;

: bg            ( n - )
    esc s" [48;5;" type n. s" m" type
;

: fg            ( n -- )
    esc s" [38;5;" type n. s" m" type
;

: normal        ( -- )
    esc s" [0m" type
;

: page          ( -- )
    esc s" [2J" type esc s" [H" type
;

: set-title     ( a n -- )
    esc s" ]0;" type type bel
;
