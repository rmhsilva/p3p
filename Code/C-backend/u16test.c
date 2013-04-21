#include <stdio.h>
#include <stdint.h>
#include <math.h>

#define D_TO_U16(x) ((uint16_t)((int)( (x) * 1024.0 )))

int main(int argc, char const *argv[])
{
	int i;
	uint16_t val;
	double values[] = {	0.766322, 0.898598, -0.281679, 
						11.351808, -0.781241, -8.098151};

	// printf("%lf\n", values[0]);

	// uint16_t hex;
	// hex = (uint16_t)( values[0] * pow(2,10) );
	// printf("0x%4x\n", hex);
	
	printf("float size : %d\n", (int)sizeof(float));
	printf("double size: %d\n", (int)sizeof(double));

	for (i=0; i<sizeof(values)/sizeof(double); i++) {
		printf("better: 0x%04x\n", D_TO_U16(values[i]) );
	}

	for (i=0; i<sizeof(values)/sizeof(double); i++) {
		values[i] *= 1024.0;
		printf("val : %#x\n", *(unsigned int*)&values[i]);

		if (values[i] > 0)
			val = (uint16_t)values[i];
		else
			val = (uint16_t)((int)(values[i]));

		printf("conv: 0x%04x\n", val);
	}

	/**
	 * Conclusions:
	 * Stupid floating point.  
	 * Casting a negative floating point value to an unsigned int
	 * results in undefined behaviour.
	 *    -> cast to int first and then to uint...
	 */

	return 0;
}
