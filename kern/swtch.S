# Context switch
#
#   void swtch(struct context **old, struct context *new);
# 
# Save the current registers on the stack, creating
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
	# TODO: your code here
	movl 4(%esp), %eax # old
	movl 8(%esp), %edx # new
	# Save old callee-saved registers
	pushl %ebp
	pushl %ebx
	pushl %esi
	pushl %edi
	# Switch stacks
	movl %esp, (%eax)
	movl %edx, %esp
	# Load new callee-saved registers
	popl %edi
	popl %esi
	popl %ebx
	popl %ebp
	ret