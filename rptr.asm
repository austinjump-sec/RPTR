section .data
	ascii: 
		db "____/\\\\\\\\\______/\\\\\\\\\\\\\____/\\\\\\\\\\\\\\\____/\\\\\\\\\_____", 10  
    	db "__/\\\///////\\\___\/\\\/////////\\\_\///////\\\/////___/\\\///////\\\___", 10     
    	db "_\/\\\_____\/\\\___\/\\\_______\/\\\_______\/\\\_______\/\\\_____\/\\\___", 10  
	    db "_\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/________\/\\\_______\/\\\\\\\\\\\/____", 10  
    	db "_\/\\\//////\\\____\/\\\/////////__________\/\\\_______\/\\\//////\\\____", 10  
    	db "_\/\\\____\//\\\___\/\\\___________________\/\\\_______\/\\\____\//\\\___", 10  
    	db "_\/\\\_____\//\\\__\/\\\___________________\/\\\_______\/\\\_____\//\\\__", 10  
    	db "_\/\\\______\//\\\_\/\\\___________________\/\\\_______\/\\\______\//\\\_", 10  
    	db "_\///________\///__\///____________________\///________\///________\///__", 10  
	    db "Created by @austinjump-sec", 10
		db "Usage: ./rptr '{COMMAND TO BE RAN}' {TIME UNTIL REFRESH}", 10
	asciiLen:  equ $-ascii             ; Ascii length in bytes
	bashPath: db "/bin/sh", 0
	flagC:  db '-c', 0

	sig_action:
        dq cntrl_c
        dq 0x04000000       ; SA_RESTORER
        dq sigreturn_stub   ; Restorer address
        dq 0       
	delay_time:
	    dq 1
		dq 0
 

section .text
	global _start

sigreturn_stub:
    mov eax, 15          ; rt_sigreturn
    syscall

_start:
    cmp qword [rsp], 3
    jne print_usage ;validate kwargc

    
    mov r12, [rsp+16]       ; argv[1] = command
    mov r13, [rsp+24]       ; argv[2] = delay


    mov rax, 13             ; rt_sigaction
    mov rdi, 2              ; SIGINT
    mov rsi, sig_action
    xor rdx, rdx
    mov r10, 8
    syscall

    test rax, rax
    js exit_error

    xor rax, rax            ; atoi accumulator
    jmp atoi_loop

atoi_loop:
	movzx rbx, byte [r13]
	test rbx, rbx
	jz atoi_done
	cmp bl, '0'
	jb print_usage
	cmp bl, '9'
	ja print_usage
	sub rbx, '0'
	imul rax, 10
	jo print_usage
	add rax, rbx
	jo print_usage
	inc r13
	jmp atoi_loop

atoi_done:
	test rax, rax
	jz print_usage
	mov [delay_time], rax

	mov rax, 1
	mov rdi, 1
	mov rsi, ascii
	mov rdx, asciiLen
	syscall
	
_open_term:
	mov rax, 57                    ; fork
	syscall
	test rax, rax
	js exit_error
	je child_process   ;if rax 0 were in child proc

	mov rdi, rax                   ; wait for this command to finish
	xor rsi, rsi
	xor rdx, rdx
	xor r10, r10
	mov rax, 61                    ; wait4
	syscall
	mov rax, 35                    ; nanosleep
	mov rdi, delay_time ;store delay time
	xor rsi, rsi
	syscall
	jmp _open_term

child_process:
    push 0   ;insert and execute commands 
    	push r12 		
		push flagC
		push bashPath
	    mov rsi, rsp
	    mov rdi, bashPath
	    xor rdx, rdx
	    mov rax, 59 ;execute 
	    syscall 
	    mov rax, 60 ;close 
	    mov rdi, 127
	    syscall

exit_error:
	mov rax, 60 ;exit gracefully 
	mov rdi, 1
	syscall

print_usage:
   	mov rax,1            ; Print usage
	mov rdi,1            
	mov rsi,ascii        
	mov rdx,asciiLen
	syscall    
	mov rax, 60 
	mov rdi, 1 
	syscall 

cntrl_c:
	mov rax, 60                    ; exit on cntrl+c
	xor rdi, rdi
	syscall
