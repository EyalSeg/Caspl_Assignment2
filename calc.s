

%define STRUCT_SIZE 5
section .data
    prompt_msg db  'calc: ', 0x0 
    current_operand_index db -1
    print_hex db '%X', 10, 0
    print_char db '%c', 10, 0


section .bss
input_buffer resb 80
operands_stack resd 5




section .text

align 16
     global main
     extern printf
     extern fflush
     extern malloc
     extern calloc
     extern free
     extern gets
     extern fgets

main:
    call prompt_input
    call act_on_input
    jmp main

exit: 
    mov     eax, 1 ; exit
    mov     ebx, 0 ; return value
    int     0x80

act_on_input:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    ; push input_buffer
    ; call printf
    ; pop edx

    call store_operand
    call print_operand

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

print_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    ; TODO: Get the operand index as a parameter
    mov ebx, [operands_stack] ; contains the pointer to the node

    print_operand_loop:
        cmp ebx, 0
        je print_operand_end

        xor eax, eax
        mov al, [ebx]
        
        push word [ebx+1]
        push print_hex
        call printf
        add esp, 8 ; discard PRINT_HEX from the stack
        
        inc ebx
        mov ebx, [ebx]

        push eax
        push print_hex
        call printf
        add esp, 4 ; discard PRINT_HEX from the stack
        pop eax



        jmp print_operand_loop
        
    print_operand_end:

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; UNFINISHED
store_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad   

    xor ebx, ebx ; previous node, init with null
    mov esi, input_buffer ; cursor. assuming input length < 80

    ; NOTE that some c calls change ecx, edx!

    store_operand_loop:
    xor edi, edi
    xor ecx, ecx
    mov cl, byte [esi]
    mov edi, ecx
    inc esi

    cmp edi, 0
    je store_operand_return


    ;create a new struct

    mov edx ,STRUCT_SIZE;
    push edx
    ;push STRUCT_SIZE
    call malloc
    ;add esp, 4 ; discard STRUCT_SIZE from the stack
    pop edx

    push eax
    push print_hex
    call printf
    add esp, 4 ; discard PRINT_HEX from the stack
    pop eax

    mov [eax + 1], ebx ; point the current node to the previous one
    mov ebx, eax
    
    ; convert dh from hexa to binary
    ; TODO: handle A-F
    sub edi, '0'

    ;write the value to the current node
    mov [ebx], edi

    ; read the next char
    xor ecx, ecx
    mov cl, [esi]
    inc esi

    cmp ecx, 0
    je store_operand_return


    ; convert dl from hexa to binary
    ; TODO: handle A-F
    sub ecx, '0'

    ; note that the left-most digit belongs to the 4 left bits
    shl edi, 4
    or edi, ecx

    ; ;write the value to the current node
    mov [ebx], edi

    ; ; proceed to the next node
    jmp store_operand_loop

    store_operand_return:
    ; TODO: increment the index and write in the correct spot
    mov [operands_stack], ebx

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

prompt_input:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    push prompt_msg
    call printf
    pop edx; remove promptmsg from stack

    push input_buffer
    call gets
    pop edx

    ; push input_buffer
    ; call printf
    ; pop edx; remove inputbuffer from stack

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller