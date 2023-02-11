#.section	.note.GNU-stack,"",@progbits
.section .data
	s: .ascii "Hello asm World!\n"
.section .text
.globl greetings
	greetings:
	movl $4,%eax      # Syscall-ID 4 (= __NR_write)
	movl $1,%ebx      # output f descriptor STDOUT (= 1)
	movl $s,%ecx      # start address string
	movl $17,%edx     # lenght
	int $0x80         # softwareinterrupt 0x80 Syscall (write(1,s,12))
	movl $1,%eax      # Syscall-ID 1 (= __NR_exit)
	xor %ebx,%ebx     # return 0
	int $0x80         # softwareinterrupt 0x80 Syscall (exit(0))
