# Example hello world program for 64-bit Linux and GNU assembler

.section .note.GNU-stack,"",@progbits

# start the text section
.text

# Constant data may be defined in the text section
mess:	.ascii	"Hello World!\n"
len	= . - mess    # determine message lenght

	.globl	greetings
greetings:
	# print message to STDOUT
	movq	$1, %rax	# 'write' system call = 1
	movq	$1, %rdi	# file descriptor 1 = STDOUT
	lea	mess(%rip), %rsi	# address of the string to write
	movq	$len, %rdx	# length of string to write
	syscall			# call the kernel

	ret
