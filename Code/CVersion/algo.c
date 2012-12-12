#include <stdio.h>
#include <stdlib.h>
#include <math.h>

// Assume we get the MFCC coefficients from somewhere.
// At this stage we will read them from a file
/*
So there are 12 MFCCs + 12 Delta coefficients + deltaC0 as energy coeff = 25 variances,means per state gaussian


For every current state (senone!!!), get the mean and variance, and calc the bj(O).


*/

#define COMPS 26		// The number of components per observation vector

typedef union {
	struct {
		double mfcc[12];
		double del[13];
	} s;
	double comp[25];
} OVector;


// First two samples of sample1.mfcc (12xMFCC, C0, 12xDel, DelC0)
// $ HList -h -e 3 -o sample1.mfcc
float sample1[][25] = {
					{	-18.684, -4.821, -4.996, -1.257, -3.512, -0.453, -6.513, -1.960, -4.348, 1.189,
        				-3.690,  -0.572,/*52.985,*/-0.005,  0.495,  0.045, -0.285,  0.093,  1.178, 0.909,
         				0.662,   -0.380, -1.215, -0.892, -0.678, -0.052},
         			{	-18.885, -3.467, -4.339, -1.698, -2.771,  4.419, -6.686, -1.222, -3.780,  0.970,
						-5.154,	 -5.745,/*52.652,*/-0.252,  0.287, -0.312, -0.476, -0.550,  0.493,  0.883,
						 0.886,	 -0.460, -1.087, -0.440,  0.730, -0.172},
};



// calc the prob of a certain observation for a set of means and std devs (sigma)
// There are 7094 states (senones) in my model.
// K: first precomputed term in eq 2.19
// omega: second prevomputed term
double prob(OVector* o, double K, double mean[], double omega[]) {
	double dist;
	int i;

	dist = K;

	// Eq 2.19 part 2
	for (i = 0; i < COMPS; i++) {
		//dist += (0.5 / (pow(sigma[i],2))) * pow((o->comp[i] - mean[i]),2);
		dist += pow((o->comp[i] - mean[i]),2) * omega[i];
	}

	return -1 * exp(dist);
}


int main(int argc, char const *argv[])
{
	// Test: 
	//printf("%f\n", sample1[1][2]);	// => -4.339

	printf("--- Done ---\n");
	return 0;
}