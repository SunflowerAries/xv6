## Exercise 2

### Grep

grep is a strong text matcher, short of global search regular expression and print out the line.

-n means to print the line number

^  means that the very words start a new line

So grep -n '^cprintf' \*/\*.c matches our coding style, then we can easily find the definition of foo, whose function name starts a new line.

### BSS

Since .bss section holds uninitialized global and static variables and global and static variables initialized with 0, and when allocated the value is by default 0. So we need to initialize them to ensure it.

