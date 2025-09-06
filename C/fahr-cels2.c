#include <stdio.h>
/* print fahrenheit-celsius table in reverse */

int main ()
{
	printf("%s\t", "   Fahrenheit");
	printf("%s\n", "Celsius");
	
	int fahr;
	for (fahr = 300; fahr >= 0; fahr = fahr - 20)
		printf("\t%3.1d\t%6.3f\n", fahr, (5.0/9.0) * (fahr - 32));
}
