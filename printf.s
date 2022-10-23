.global main
.data
BUFFER: .skip 1024 # Reserve 1024 bytes of memory

.text
message:
    .asciz "Hello!\n"

.equ zero, 0

/*
byte[] MEMORY = {...};
char[] BUFFER = {};
void my_printf(add_to_string, first param, second param, ...) {
    int currentIndex = 0;
    char currentCharacter = '';
    while(currentCharacter != 0) {
        currentCharacter = MEMORY[add_to_string(, currentIndex, 1)];
        // if(currentCharacter == '%') ...
        BUFFER[currentIndex] = currentCharacter;
        currentIndex++;
    }

    syscall_print(1, $BUFFER, currentIndex);
}
*/
my_printf:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    pushq %r12 # currentIndex
    pushq %r13 # currentCharacter

    movq $0, %r12
    movq $1, %r13

my_printf_loop:
    cmpq $0, %r13
    je my_printf_loop_end
    
    movq (%rdi, %r12, 1), %r13
    andq $255, %r13 

    movq %r13, BUFFER(, %r12, 1)

    incq %r12

    jmp my_printf_loop

my_printf_loop_end:

    movq $1, %rdi # first param is where to write; stdout is 1
    movq $BUFFER, %rsi # second param is from what adress to write
    movq %r12, %rdx # third param is how many bytes to write
    movq $1, %rax # system call 1 is print
    syscall


    # Epilogue
    popq %r13 # currentCharacter
    popq %r12 # currentIndex

    movq %rbp, %rsp
    popq %rbp
    ret

main:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp
    
    movq $message, %rdi
    call my_printf

    # Epilogue
    movq %rbp, %rsp
    popq %rbp

    movq $60, %rax # syscall code 60 is exit
    movq $0, %rdi # normal exit: 0
    syscall # call exit
