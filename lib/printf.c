#include<inc/stdio.h>
int
vcprintf(const char *fmt, va_list ap)
{
	
	return 
}

int
cprintf(const char *fmt, ...)
{
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vcprintf(fmt, ap);
	va_end(ap);

	return rc;
}
