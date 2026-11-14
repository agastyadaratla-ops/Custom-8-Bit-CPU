; Adds 5 and 7, then writes 12 to the output port.
; Memory location 0xF0 is used as a data variable.

        LDI 5
        STA 0xF0
        LDI 7
        ADD 0xF0
        OUT
        HLT
