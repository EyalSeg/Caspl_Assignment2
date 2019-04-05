section .data
prompt_msg db  'calc: ', 0x0 
prompt_msglen equ $ - prompt_msg    


%define STDIN 0

section .bss
input_buffer resb 100

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
    call prompt_input
    call prompt_input

    mov     eax, 1 ; exit
    mov     ebx, 0 ; return value
    int     0x80

prompt_input:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    push prompt_msg
    call printf
    pop edx; remove promtmsg from stack

    push input_buffer
    call gets
    pop edx

    push input_buffer
    call printf
    pop edx; remove promtmsg from stack

    
    loop:
        mov ah, 1
        int 21h         ; read character into al

        ; todo: check if endl


; COPYPASTA https://stackoverflow.com/questions/21870702/assembly-how-to-convert-hex-input-to-decimal
check_for_digit:
        

check_for_upper:
        cmp al, 'A'     ; handle A-F
        jl check_for_lower
        cmp al, 'F'
        jg check_for_lower
        sub al, 'A'-10  ; convert to numeric value
        jmp handle_num

check_for_lower:
        ; ASSUMES input is valid
       ; cmp al, 'a'     ; handle a-f
       ; jl handle_digit_error
       ; cmp al, 'f'
       ; jg handle_digit_error
        sub al, 'a'-10  ; convert to numeric value


handle_num:

    
    endloop:

    ; TODO check if operator


    ;mov eax, 6

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; not working
charhex_to_decimal:
    push    ebp             ; Save caller state
    mov     ebp, esp
    ;sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov al, [ebp + 8]

    cmp al, '0'     ; handle 0-9
    jl check_for_upper
    cmp al, '9'
    jg check_for_upper
    sub al, '0'     ; convert to numeric value
    jmp handle_num

    ;mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    ;mov     eax, [ebp-4]    ; place returned value where caller can see it
   ; add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller