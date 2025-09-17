#include <stdio.h>

/* copy input to output, replace tab with \t, backspace with \b, backslash with \\ */
/* version 1 */
int main()
{
	int character;
	while ((character = getchar()) != EOF) {
		if (character == '\t') {
			printf("%s", "\\t");
		}

		if (character == '\b') {
			printf("%s", "\\b");
		}

		if (character == '\\') {
			printf("%s", "\\");
		}
		putchar(character);
	}
}
