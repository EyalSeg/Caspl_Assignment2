

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

    cmp al, '+'
    je act_add

    cmp al, 'd'
    je act_duplicate

    call read_operand
    push eax
    call push_operand
    pop eax

    jmp act_on_input_end

    act_printandpop:
        call print_and_pop        
        jmp act_on_input_end

    act_add:
        call add_top_operands
        jmp act_on_input_end

    act_duplicate:
        call duplicate_top_operand
        jmp act_on_input_end

    act_on_input_end:

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

duplicate_top_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    ; get top operand
    call get_current_stack_address
    mov esi, [eax]

    push esi
    call duplicate_operand ; eax now holds the duplicated operand
    pop esi

    push eax
    call push_operand
    pop eax

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

add_top_operands:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    ; push two operands from the operands stack to the actual stack
    call pop_stack
    push eax 
    call pop_stack
    push eax

    ; push the addition result
    call add_operands
    push eax 

    call push_operand

    pop eax ; pop the result operand
    
    ;delete both operands (they are still on the stack)
    call free_operand 
    pop eax

    call free_operand 
    pop eax

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
    ;add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; duplicates an operand and returns a pointer to the new operand created
duplicate_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov esi, [ebp + 8]
    xor edi, edi

    cmp esi, 0
    je duplicate_operand_return

    mov edx ,STRUCT_SIZE ; create a new node
    push edx
    call malloc
    pop edx

    mov edi, eax ; store new node as edi

    ; copy source value to destination node
    xor ebx, ebx
    mov bl, [esi]
    mov [edi], bl

    ; recursively duplicate the next nodes
    mov esi, [esi + 4] ; next ptr
    push esi
    call duplicate_operand
    pop esi

    mov dword [edi + 4], eax  ; point the next node to the returned value from the recursive call


    duplicate_operand_return:

    mov     [ebp-4], edi    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; adds two operands and stores the result as a new operand (returns a pointer to the result op)
add_operands:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov ebx, [ebp + 8]      ; operand 1
    mov esi, [ebp + 12]     ; operand 2

    mov ecx, ebx
    xor ecx, esi
    xor edi, edi            ; output, initialized to null

    cmp ecx, 0 ; both operands are null
    je add_operands_both_null
    jmp add_operand_init_node

    add_operands_both_null:
        jnc add_operands_return ; if both are null and there is no carry, we are done

    add_operand_init_node:
        mov edx ,STRUCT_SIZE;
        push edx
        call malloc
        pop edx

        mov edi, eax ; store the new node's address

    xor ecx, ecx
    xor edx, edx

    add_operands_op1:
        cmp ebx, 0
        je add_operands_op2

        mov cl, [ebx]
        mov ebx, [ebx + 4] ; next ptr

    add_operands_op2:
        cmp esi, 0
        je add_operands_join

        mov dl, [esi]
        mov esi, [esi + 4] ; next ptr

    add_operands_join:
        adc cl, dl
        mov [edi], cl       ; write the value of the current node

    ; recursively calculate the next nodes
    push esi
    push ebx
    call add_operands
    pop ebx
    pop esi

    mov dword [edi + 4], eax  ; point the next node to the returned value from the recursive call

    add_operands_return:
    mov     [ebp-4], edi    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
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
    call malloc
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