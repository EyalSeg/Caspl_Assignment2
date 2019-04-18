section .data
prompt_msg db  'calc: ', 0x0 
prompt_msglen equ $ - prompt_msg    


%define STDIN 0
%define STRUCT_SIZE 5

section .bss
input_buffer resb 80
operand_stack resb STRUCT_SIZE * 4  ; [1 byte data | 4 bytes nextptr]
operand_index resb 1

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

    mov [operand_index], byte 0 ; chaneg to -1!

    call prompt_input
    call act_on_input
    jmp main

    mov     eax, 1 ; exit
    mov     ebx, 0 ; return value
    int     0x80

act_on_input:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad    

    ; TODO: check first char in input buffer and call matching function

    call store_operand


    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

store_operand:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad    

   mov ecx, input_buffer
   xor ebx, ebx ; previous pointer
   xor edx, edx

   store_operand_loop:
    mov dl, [ecx]
    inc ecx
    cmp dl, 0
    je store_operand_loop_end

    push STRUCT_SIZE
    call malloc
    add esp, 4 ; discard STRUCT_SIZE from the stack

    mov [eax + 1], ebx  ; writes the previous pointer to the end of the current struct
    mov ebx, eax        ; store the current struct as the previous

    ; convert edx from hex char to binary
    push edx
    call charhex_to_decimal
    pop edx

    ; move the converted result to [ebx]
    mov [ebx], byte al

    ; ; read the next char
    mov dl, [ecx]
    inc ecx
    cmp dl, 0
    je store_operand_loop_end

    push edx
    call charhex_to_decimal
    pop edx

    shl eax, 4  ; this second char is the significant part of the current input number
    add al, byte [ebx]
    mov al, byte [ebx]

    jmp store_operand_loop

    store_operand_loop_end:

    ; inc the operand index
    xor eax, eax
    mov al, byte [operand_index]
    inc al
    mov byte [operand_index], al

    ; write ebx to the operand stack
    mov ecx, STRUCT_SIZE
    mul ecx
    mov [operand_stack + eax], ebx

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; reads input into input_buffer
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

    ;push input_buffer
    ;call printf
    ;pop edx; remove inputbuffer from stack

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller


; assuming input is valid, letters are uppercase
charhex_to_decimal:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov al, [ebp + 8]

    cmp al, 'A'
    jge handle_char

    jmp handle_num

    ; if got here, the input is invalid!


    handle_char:
    sub al, 'A'
    add al, 10

    jmp charhex_to_decimal_ret

    handle_num:
    sub al, '0'

    charhex_to_decimal_ret:

    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller