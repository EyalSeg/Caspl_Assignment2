

%define STRUCT_SIZE 5
section .data
    prompt_msg db  'calc: ', 0x0 
    current_operand_index db -1
    print_hex db '%X', 0
    print_char db '%c', 10, 0
    print_newLine db 10, 0


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


    mov al, [input_buffer]
    cmp al, 'p'
    je act_printandpop

    cmp al, 'q'
    je exit

    call read_operand
    push eax
    call push_operand
    pop eax

    jmp act_on_input_end

    act_printandpop:
        call print_and_pop        
        jmp act_on_input_end

    act_on_input_end:

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

print_and_pop:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    call get_current_stack_address
    mov ebx, [eax]

    push ebx
    call print_operand
    pop ebx

    call pop_stack

    push eax
    call free_operand
    pop eax

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; takes address to the operand as parameter
print_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov ebx, [ebp + 8] ; contains the pointer to the node

    xor edi, edi ; counter
    xor al, al
    print_operand_enstackloop:
        cmp ebx, 0
        je print_operand_printloop

        xor eax, eax
        mov al, [ebx]
        push  eax
        inc edi
        
        ;inc ebx
        mov ebx, [ebx + 4] ; next ptr

        jmp print_operand_enstackloop

    
    print_operand_printloop:
        cmp edi, 0
        je print_operand_end

        xor eax, eax
        pop eax

        push eax
        push print_hex
        call printf
        add esp, 4 ; discard PRINT_HEX from the stack
        pop eax

        dec edi


        jmp print_operand_printloop
        
    print_operand_end:
        push print_newLine
        call printf
        add esp, 4 ; discard PRINT_newline from the stack


    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller


; reads operand from the input buffer, returns address to it
read_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad   

    xor ebx, ebx ; previous node, init with null
    mov esi, input_buffer ; cursor. assuming input length < 80

    read_operand_loop:
    xor edi, edi
    xor ecx, ecx
    mov cl, byte [esi]
    mov edi, ecx
    inc esi

    cmp edi, 0
    je read_operand_return 

    ;create a new struct

    mov edx ,STRUCT_SIZE;
    push edx
    ;push STRUCT_SIZE
    call malloc
    ;add esp, 4 ; discard STRUCT_SIZE from the stack
    pop edx

    mov dword [eax + 4], ebx  ; point the current node's nextptr to the previous one
    mov ebx, eax        
    
    ; convert dh from hexa to binary
    push edi
    call charhex_to_decimal
    pop edi
    mov edi, eax

    ;write the value to the current node
    mov [ebx], al

    ; read the next char
    xor ecx, ecx
    mov cl, [esi]
    inc esi

    cmp ecx, 0
    je read_operand_return


    ; convert dl from hexa to binary
    push ecx
    call charhex_to_decimal
    pop ecx
    mov ecx, eax

    ; note that the left-most digit belongs to the 4 left bits
    shl edi, 4
    or edi, ecx

    ; ;write the value to the current node
    mov [ebx], edi

    ; ; proceed to the next node
    jmp read_operand_loop

    read_operand_return:



    mov     [ebp-4], ebx    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; takes an address to an operand, and pushes it to the operand stack
push_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad   

    mov ebx, [ebp + 8] ; address to the operand

    inc byte [current_operand_index] 
    call get_current_stack_address

    mov dword [eax], ebx

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; pops the top operand from the stack
pop_stack:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad   

    call get_current_stack_address
    mov eax, dword [eax]
    dec byte [current_operand_index]

    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; takes a pointer to an operand and frees it memory
free_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad   

    mov ebx, [ebp + 8]

    free_loop:
    cmp ebx, 0
    je free_end

    mov eax, ebx
    mov ebx, [ebx + 4] ; next ptr

    push eax
    call free
    pop eax

    jmp free_loop

    free_end:

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




; TODO
get_current_stack_address:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    xor eax, eax
    mov al, byte [current_operand_index]

    mov ebx, 4
    mul ebx

    mov ebx, operands_stack
    add eax, ebx

    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

    ; assuming input is valid, letters are uppercase
charhex_to_decimal:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov eax, [ebp + 8]

    cmp eax, 'A'
    jge handle_char

    jmp handle_num

    ; if got here, the input is invalid!


    handle_char:
    sub eax, 'A'
    add eax, 10

    jmp charhex_to_decimal_ret

    handle_num:
    sub eax, '0'

    charhex_to_decimal_ret:

    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller