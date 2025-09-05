#include <stdio.h>
/* print fahrenheit-celsius table
 for fahr = 0,20,...300 */

int main()
{
	/* int fahr, celsius */

	float fahr, celsius;
	int lower, upper, step;

	lower = 0; /* lower limit of temp table */
	upper = 300; /* upper limit of temp table */
	step = 20; /* step size */

	fahr = lower;
	
	printf("%s\t", "    Fahrenheit");
	printf("%s\n", "Celsius");

	while (fahr <= upper) {

		/* celsius = 5 * (fahr - 32) / 9; */
		/* printf("%d\t%d\n", fahr, celsius); */

		celsius = (5.0/9.0) * (fahr - 32.0);
		printf("\t%3.0f\t%6.3f\n", fahr, celsius);
		fahr = fahr + step;
	}
}
