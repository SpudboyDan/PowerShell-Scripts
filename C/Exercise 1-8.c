#include <stdio.h>
/* count blanks, tabs, and newlines */
int main ()
{
	int character, spaceCount, tabCount, newLineCount;
	spaceCount = 0;
	tabCount = 0;
	newLineCount = 0;
	while ((character = getchar()) != EOF)
	{
		if (character == ' ')
		{
			++spaceCount;
		}
		if (character == '\t')
		{
			++tabCount;
		}
		if (character == '\n')
		{
			++newLineCount;
		}
	}
		printf("\n%s%d", "Blank Space Count: ", spaceCount);
		printf("\n%s%d", "Tab Count: ", tabCount);
		printf("\n%s%d", "New Line Count: ", newLineCount);
}
