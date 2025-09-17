#include <stdio.h>

int main()
{
	int character, previousCharacter;
	
	previousCharacter = EOF;

	while ((character = getchar()) != EOF) {
		if (character == ' ')
			if (previousCharacter != ' ')
				putchar(character);
		if (character != ' ')
			putchar(character);
		previousCharacter = character;
	}
}
