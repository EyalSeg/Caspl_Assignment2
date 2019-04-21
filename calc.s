

%define STRUCT_SIZE 5
section .data
    prompt_msg db  'calc: ', 0x0 
    current_operand_index db -1
    print_hex db '%X', 0
    print_char db '%c', 10, 0
    print_newLine db 10, 0
    print_wrong_input db 'wrong input ', 10, 0


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
    cmp al, '^'
    je act_mulby2pow
    cmp al, 'v'
    je act_divby2pow
    cmp al, 'n'
    je act_countones

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

    act_mulby2pow:
        call mul_by_2power
        jmp act_on_input_end

    act_divby2pow:
        call div_by_2power
        jmp act_on_input_end

    act_countones:
        call count_bits_in_top
        jmp act_on_input_end

    act_on_input_end:

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; pops the top-most operand, counts how many 1-bits it has and pushes a new operand with that number
count_bits_in_top:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad  

    call pop_stack
    mov esi, eax            ; esi holds the top operand

    ; init a zero'd counter operand
    mov edx ,STRUCT_SIZE ; create a new node
    push edx
    call malloc
    pop edx

    mov edi, eax             ; edi holds the new counter operand
    mov byte [edi], 0
    mov dword [edi + 4], 0

    push edi
    call push_operand
    ; keep edi in the stack, as we are going to call inc_operand on it


    counts_bits_list_loop:
        cmp esi, 0
        je counts_bits_list_loop_end

        mov al, [esi]
        count_bits_node_loop:
            cmp al, 0
            je count_bits_node_loop_end

            mov bl, 1
            and bl, al
            shr al, 1

            cmp bl, 0
            je count_bits_node_loop

            call inc_operand
            jmp count_bits_node_loop

        count_bits_node_loop_end:
        mov esi, [esi + 4]
        jmp counts_bits_list_loop

    counts_bits_list_loop_end:
    pop edi

    push esi
    call free_operand
    pop esi

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

div_by_2power:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad   

    xor ecx, ecx
    push ecx ; push 0 carry

    call pop_stack
    push eax
    call pop_stack

    cmp dword [eax + 4], 0 ; if the list contains two nodes, than it's value is greater than one byte (and specifically than 200)
    jne div_by_2power_wrong_input
    mov bl, byte [eax] 
    cmp bl, 200
    jl div_by_2power_wrong_input

    push eax
    call free_operand
    pop eax

    
    ; note that the first operand is still in the stack

    div_by_2power_loop:
        cmp bl, 1
        jle div_by_2power_loop_end

        call shr_operand
        dec bl
        jmp div_by_2power_loop

    div_by_2power_loop_end:

     ;first operand still in the stack
    call push_operand
    pop eax
    jmp div_by_2power_return

    div_by_2power_wrong_input:
        push eax
        call push_operand
        pop eax

        ; first operand was pushed earlier
        call push_operand
        pop eax

        mov eax, print_wrong_input
        push eax
        call printf
        pop eax

    div_by_2power_return:
    pop eax ; pop carry

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

mul_by_2power:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad   

    xor ecx, ecx
    push ecx ; push 0 carry

    call pop_stack
    push eax
    call pop_stack

    cmp dword [eax + 4], 0 ; if the list contains two nodes, than it's value is greater than one byte (and specifically than 200)
    jne mul_by_2power_wrong_input
    mov bl, byte [eax] 
    cmp bl, 200
    jl mul_by_2power_wrong_input

    push eax
    call free_operand
    pop eax

    
    ; note that the first operand is still in the stack

    mul_by_2power_loop:
        cmp bl, 1
        jle mul_by_2power_loop_end

        call shl_carry_operand
        dec bl
        jmp mul_by_2power_loop

    mul_by_2power_loop_end:

     ;first operand still in the stack
    call push_operand
    pop eax
    jmp mul_by_2power_return

    mul_by_2power_wrong_input:
        push eax
        call push_operand
        pop eax

        ; first operand was pushed earlier
        call push_operand
        pop eax

        mov eax, print_wrong_input
        push eax
        call printf
        pop eax

    mul_by_2power_return:
    pop eax ; pop carry

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

    xor ebx, ebx
    push ebx ; push 0 carry
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

    pop ebx

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

; takes an operand and shifts it right (in place). returns the preshift-lsb (which got shifted out)
shr_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov edi, [ebp + 8]
    xor eax, eax ; the return value

    cmp edi, 0
    je shr_operand_return

    xor ebx, ebx ; the leftmost bit to add after shift

    mov esi, [edi + 4] ; nextptr
    cmp esi, 0 ; if has no next pointer, skip to the edit part
    jmp shr_operand_editnode

    ; recursively shr
    push esi
    call shr_operand
    pop esi

    mov ebx, eax ; add the next pointer's lsb as the msb after shift

    ; if esi's value is 0 and it is the last node, delete it
    mov eax, [esi + 4] ; nextptr nextptr
    cmp eax, 0
    jne shr_operand_editnode

    xor eax, eax
    mov al, byte [esi]
    cmp al, 0
    jg shr_operand_editnode

    ; delete the nextnode
    push esi
    call free
    pop esi

    mov dword [edi + 4], 0 ; set nextptr to 0

    
    shr_operand_editnode:
        xor ecx, ecx
        xor al, al
        mov cl , byte [edi]

        mov al, 1
        and al, cl ; move the lsb to eax

        shr cl, 1
        shl bl, 7 
        or cl, bl ; turn ebx (nextptr's lsb) into esx's msb

        mov [edi], cl

    shr_operand_return:
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; takes an operand and a carry, and shifts it left (in place)
shl_carry_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov esi, [ebp + 8]
    mov ecx, [ebp + 12] ; input carry
    xor edx, edx        ; output carry

    cmp esi, 0
    je shl_operand_return

    mov bl, [esi]
    shl bl, 1
    jne shl_no_carry

    mov edx, 1

    shl_no_carry:
    push edx ; push the output carry
    or bl, cl ; add input carry
    mov [esi], bl
    
    ; if there is a carry and the next node is null, instantiate a new node
    cmp edx, 0
    je shl_operand_next

    mov eax, dword [esi + 4]  ; point the current node's nextptr to the previous one
    cmp eax, 0
    jne shl_operand_next

    ; init a new node
    mov edx ,STRUCT_SIZE;
    push edx
    call malloc
    pop edx
    mov byte [eax], 1
    mov dword [eax + 4], 0
    
    ; point the current node's nextptr to the new node
    mov dword [esi + 4], eax

    pop edx ; pop the output carry
    jmp shl_operand_return

    shl_operand_next:
    mov esi, [esi + 4]
    push esi
    call shl_carry_operand
    pop esi
    pop edx

    shl_operand_return:
    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller




; input: op1, op2 operands, carry 
; output: pointer to a new operand, op1+op2+carry
add_operands:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov ebx, [ebp + 8]      ; operand 1
    mov esi, [ebp + 12]     ; operand 2
                            ; carry exists at [ebp+16]
    

    mov ecx, ebx
    or ecx, esi
    xor edi, edi            ; output, initialized to null

    cmp ecx, 0 ; both operands are null
    je add_operands_both_null
    jmp add_operand_init_node

    add_operands_both_null:
    ; if both are null and there is no carry, we are done
        mov ecx, [ebp + 16]
        cmp ecx, 0
        je add_operands_return
    

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

        mov ch, [esi]
        mov esi, [esi + 4] ; next ptr

    add_operands_join:
        mov edx, [ebp + 16]

        add cl, dl
        xor edx, edx ; set new carry to 0

        jnc add_operands_nocarry1
        mov edx, 1

    add_operands_nocarry1:
        add cl, ch
        jnc add_operands_nocarry2

        mov edx, 1
    add_operands_nocarry2:

    mov [edi], cl       ; write the value of the current node

    ; recursively calculate the next nodes
    push edx
    push esi
    push ebx
    call add_operands
    pop ebx
    pop esi
    pop edx

    mov dword [edi + 4], eax  ; point the next node to the returned value from the recursive call

    add_operands_return:

    mov     [ebp-4], edi    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller


inc_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad      

    mov esi, [ebp + 8]

    mov al, [esi]
    cmp al, 0xFF
    je inc_operand_propagate

    inc al
    mov [esi], al
    jmp inc_operand_return

    inc_operand_propagate:
    mov byte [esi], 0

    mov eax, [esi + 4] ; nextptr
    cmp eax, 0
    jne inc_operand_recursive

    mov edx ,STRUCT_SIZE;
    push edx
    call malloc
    pop edx

    mov [esi + 4], eax
    mov byte [eax], 1
    mov dword [eax + 4], 0

    jmp inc_operand_return

    inc_operand_recursive:
    mov esi, [esi + 4]
    push esi
    call inc_operand
    pop esi

    inc_operand_return:
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

        xor ecx, ecx
        mov cl, 0xF
        mov ch, 0xF0

        xor eax, eax
        mov al, [ebx]

        and cl, al
        and ch, al
        shr ch, 4

        ; push the lower digit
        mov al, cl
        push  eax
        inc edi

        ; push the upper digit
        mov al, ch
        push eax
        inc edi

        mov ebx, [ebx + 4] ; next ptr       

        ; if it is the last node and the high digit is 0, pop it
        cmp ebx, 0
        jne print_operand_enstackloop
        cmp ch, 0
        jne print_operand_enstackloop
        pop eax
        dec edi

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

    xor edi, edi ; return value, initialized with null
    mov esi, input_buffer ; cursor. assuming input length < 80

    xor eax, eax
    ; set esi to the end of the input
    ; convert the input buffer to binary
    read_operand_set_cursor_loop:
        mov al, byte[esi]

        cmp al, 0
        je read_operand_set_cursor_end
        cmp al, 10
        je read_operand_set_cursor_end

        push eax
        call charhex_to_decimal
        pop edx


        mov byte[esi], al

        inc esi
        jmp read_operand_set_cursor_loop

    read_operand_set_cursor_end:
    dec esi ; we don't want the \0 or \n
    mov ecx, esi
    push ecx ; store for later

    read_operand_allocate_space_loop:
        cmp esi, input_buffer ; assign space for each character
        jl read_operand_allocate_space_end

        mov edx ,STRUCT_SIZE;
        push edx
        call malloc
        pop edx

        ; insert the new node at the beginning of the list
        mov dword [eax + 4], edi
        mov edi, eax

        sub esi, 2 ; each node contains two characters

        jmp read_operand_allocate_space_loop

    read_operand_allocate_space_end:
    pop esi
    mov [ebp-4], edi    ; Save returned value...

    read_operand_write_loop:
        cmp esi, input_buffer
        jl read_operand_write_loop_end

        xor ebx, ebx
        mov bl, [esi]
        dec esi

        cmp esi, input_buffer
        jl read_operand_write

        mov bh, [esi]
        shl bh, 4
        or bl, bh

        dec esi

        read_operand_write:
        mov [edi], bl
        mov edi, [edi + 4] ; next ptr

        jmp read_operand_write_loop
        
    read_operand_write_loop_end:

    ;mov     [ebp-4], ebx    ; Save returned value...
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