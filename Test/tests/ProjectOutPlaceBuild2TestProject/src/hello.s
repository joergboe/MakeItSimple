.section .note.GNU-stack,"",@progbits

.text

mess:	.ascii	"Hello World!\n"
len	= . - mess

	.globl	greetings
greetings:
	movq	$1, %rax
	movq	$1, %rdi
	lea	mess(%rip), %rsi
	movq	$len, %rdx
	syscall

	ret
