#include <stdio.h>

/* Copy input to output; Version 1 */

int main()
{
	int c;
	c = getchar();
	while (c != EOF) {
		putchar(c);
		c = getchar();
	}
}
