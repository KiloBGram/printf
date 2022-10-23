.global main
.data
BUFFER: .skip 1024 # Reserve 1024 bytes of memory

.text
message:
    .asciz "Hello!\n"

/*
byte[] MEMORY = {...};
char[] BUFFER = {};
void my_printf(add_to_string, first_param, second_param, ...) {
    int currentIndex = 0;
    int bufferIndex = 0;
    int paramsCount = 0;
    char currentCharacter = '';

    while(currentCharacter != 0) {
        currentCharacter = MEMORY[add_to_string(, currentIndex, 1)];
        currentIndex++;
        if(currentCharacter == '%') {
            currentCharacter = MEMORY[add_to_string(, currentIndex, 1)];
            currentIndex++;
            if(currentCharacter == ('d' | 'u' | 's' | '%')) {
                paramsCount++;
            }
        }
    }

    int i = paramsCount;
    while(i > 0) {
        i--;
        if(i == 0) push(%rsi);
        else if(i == 1) push(%rdx);
        else if(i == 2) push(%rcx);
        else if(i == 3) push(%r8);
        else if(i == 4) push(%r9);
        else {
            i = i - 2;
            push(%rbp, i, 8);
            i = i + 2;
        }
    }

    // at this point we have pushed all additional params to the stack in reverse order.

    currentIndex = 0;

    while(currentCharacter != 0) {
        currentCharacter = MEMORY[add_to_string(, currentIndex, 1)];

        if(currentCharacter == '%') {
            currentIndex++;
            currentCharacter = MEMORY[add_to_string(, currentIndex, 1)];
            
            switch(currentCharacter) {
                case 'u':
                    int num = pop();
                    int count = 0;
                    while (num != 0) {
                        num = num / 10;
                        push((num % 10) + '0'); // push remainder of division + ascii 0
                        count++;
                    }

                    while (count > 0) {
                        BUFFER[bufferIndex] = pop();
                        bufferIndex++;
                        count--;
                    }
                    break;
                case 'd':
                    ...
                    break;
                case 's':
                    ...
                    break;
                case '%':
                    ...
                    break;
                default:
                    ...
            }
        } else {
            BUFFER[bufferIndex] = currentCharacter;
            currentIndex++;
            bufferIndex++;
        }
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
    pushq %r14 # bufferIndex
    pushq %r15 # paramsCount

    movq $0, %r12
    movq $1, %r13

my_printf_count_params_loop:
    cmpq $0, %r13
    je my_printf_count_params_loop_end
    
    movq (%rdi, %r12, 1), %r13
    andq $255, %r13
    incq %r12

    cmpq $37, %r13  # ascii %
    jne my_printf_count_params_loop

    movq (%rdi, %r12, 1), %r13
    andq $255, %r13
    incq %r12

    cmpq $37, %r13 # ascii %
    je my_printf_count_params_increment

    cmpq $100, %r13 # ascii d
    je my_printf_count_params_increment

    cmpq $117, %r13 # ascii u
    je my_printf_count_params_increment

    cmpq $115, %r13 #ascii s
    je my_printf_count_params_increment

    jmp my_printf_count_params_loop

my_printf_count_params_increment:
    incq %r15
    jmp my_printf_count_params_loop

my_printf_count_params_loop_end:
    movq %r15, %rax

my_printf_push_params_loop:
    cmpq $0, %rax
    je my_printf_push_params_loop_end

    decq %rax

    cmpq $0, %rax
    jne after_zero
    pushq %rsi

    after_zero:
        cmpq $1, %rax
        jne after_one
        pushq %rdx
        jmp my_printf_push_params_loop

    after_one:
        cmpq $2, %rax
        jne after_two
        pushq %rcx
        jmp my_printf_push_params_loop

    after_two:
        cmpq $3, %rax
        jne after_three
        pushq %r8
        jmp my_printf_push_params_loop

    after_three:
        cmpq $4, %rax
        jne after_four
        pushq %r9
        jmp my_printf_push_params_loop

    after_four:
        subq $3, %rax
        pushq (%rbp, %rax, 8)
        jmp my_printf_push_params_loop

my_printf_push_params_loop_end:
    movq $0, %r12

my_printf_parse_loop:
    cmpq $0, %r13
    je my_printf_parse_loop_end
    
    movq (%rdi, %r12, 1), %r13
    andq $255, %r13 

    cmpq $37, %r13 # ascii %
    jne add_to_buffer

    incq %r12
    movq (%rdi, %r12, 1), %r13
    andq $255, %r13

    # switch-ish thing here
    cmpq $117, %r13  # ascii u
    je case_u

    cmpq $100, %r13 # ascii d
    je case_d

    cmpq $115, %r13 #ascii s
    je case_s

    cmpq $37, %r13 # ascii %
    je case_procent

    jmp default

    case_u:
        popq %rax
        movq $0, %rcx # this is the count

        unsigned_parse_loop:
            movq $0, %rdx # we won't need top half of dividend
            movq $10, %r10 # load divisor
            div %r10

            addq '0', %rdx
            push %rdx
            incq %rcx
            
            cmpq $0, %rax
            jne unsigned_parse_loop

        unsigned_write_loop:
            popq %r13
            movq %r13, BUFFER(, %r14, 1)
            incq %r14

        jmp my_printf_parse_loop

    case_d:
        movq %r13, BUFFER(, %r14, 1)
        incq %r14
        jmp my_printf_parse_loop

    case_s:
        movq %r13, BUFFER(, %r14, 1)
        incq %r14
        jmp my_printf_parse_loop

    case_procent:
        movq %r13, BUFFER(, %r14, 1)
        incq %r14
        jmp my_printf_parse_loop

    default:
        movq %r13, BUFFER(, %r14, 1)
        incq %r14
        jmp my_printf_parse_loop

    add_to_buffer:
        movq %r13, BUFFER(, %r14, 1)
        incq %r14
        incq %r12

        jmp my_printf_parse_loop

my_printf_parse_loop_end:

    movq $1, %rdi # first param is where to write; stdout is 1
    movq $BUFFER, %rsi # second param is from what adress to write
    movq %r14, %rdx # third param is how many bytes to write
    movq $1, %rax # system call 1 is print
    syscall


    # Epilogue
    popq %r15
    popq %r14
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
