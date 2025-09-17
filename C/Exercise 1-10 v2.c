#include <stdio.h>

/* copy input to output, replace tab with \t, backspace with \b, backslash with \\ */
/* version 2 */

int main()
{
	int c, d;

	while ((c = getchar()) != EOF) {
		d = 0;

		if (c == '\\') {
			putchar('\\');
			putchar('\\');
			d = 1;
		}

		if (c == '\t') {
			putchar('\\');
			putchar('t');
			d = 1;
		}

		if (c == '\b') {
			putchar('\\');
			putchar('b');
			d = 1;
		}

		if (d == 0)
			putchar(c);
	}
}
