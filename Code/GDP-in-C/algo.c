#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

// Assume we get the MFCC coefficients from somewhere.
// At this stage we will read them from a file
/*
So there are 12 MFCCs + 12 Delta coefficients + deltaC0 as energy coeff = 25 variances,means per state gaussian


For every current state (senone!!!), get the mean and variance, and calc the bj(O).


*/

#define N_COMPS    25	// The number of components per observation vector
#define N_SENONES   7094// Number of states (senones)
#define MAX_COMPS   4 	// Max number of components to process
#define MAX_SENONES 3 	// Max number of senones to process

typedef union {
	struct {
		double mfcc[12];
		double del[13];
	} s;
	double comp[N_COMPS];
} OVector;

typedef struct {
	double k;
	double mean[N_COMPS];
	double omega[N_COMPS];	// = 0.5/variance^2
} Senone;


// First two samples of sample1.mfcc (12xMFCC, C0, 12xDel, DelC0)
// $ HList -h -e 3 -o sample1.mfcc
float sample1[][N_COMPS] = {
	{	-18.684, -4.821, -4.996, -1.257, -3.512, -0.453, -6.513, -1.960, -4.348, 1.189,
		-3.690,  -0.572, -0.005,  0.495,  0.045, -0.285,  0.093,  1.178, 0.909,
		0.662,   -0.380, -1.215, -0.892, -0.678, -0.052 },
	{	-18.885, -3.467, -4.339, -1.698, -2.771,  4.419, -6.686, -1.222, -3.780,  0.970,
		-5.154,	 -5.745, -0.252,  0.287, -0.312, -0.476, -0.550,  0.493,  0.883,
		 0.886,	 -0.460, -1.087, -0.440,  0.730, -0.172 }
};

OVector sample1_o[] = {
	{	-18.684, -4.821, -4.996, -1.257, -3.512, -0.453, -6.513, -1.960, -4.348, 1.189,
		-3.690,  -0.572, -0.005,  0.495,  0.045, -0.285,  0.093,  1.178, 0.909,
		0.662,   -0.380, -1.215, -0.892, -0.678, -0.052 },
	{	-18.885, -3.467, -4.339, -1.698, -2.771,  4.419, -6.686, -1.222, -3.780,  0.970,
		-5.154,	 -5.745, -0.252,  0.287, -0.312, -0.476, -0.550,  0.493,  0.883,
		 0.886,	 -0.460, -1.087, -0.440,  0.730, -0.172 },
};

Senone senones[] = {
    /* Senone 2 (ST_ae_4_18) */
    { k:     42.171024,
      mean:  { -1.311694, 1.281243, -3.994659, -0.02301142 },
      omega: { 0.011437091, 0.016844073, 0.017512877, 0.029473398 } },
    /* Senone 1 (ST_r_4_108) */
    { k:     48.43822,
      mean:  { -1.913995, 1.85043, -0.8573892, 4.246782 },
      omega: { 0.013892933, 0.026711356, 0.014819368, 0.036674663 } },
    /* Senone 0 (ST_ey_4_47) */
    { k:     47.54454,
      mean:  { -1.285092, -1.527962, 3.741305, 5.909739 },
      omega: { 0.017152535, 0.01642813, 0.020314805, 0.042014197 } },
};


// calc the prob of a certain observation for a set of means and std devs (sigma)
// There are 7094 states (senones) in my model.
// K: first precomputed term in eq 2.19
// omega: second precomputed term
double score(OVector *o, Senone *s) {
	double dist;
	int i;

	// Eq 2.19
	dist = s->k;
	for (i = 0; i < MAX_COMPS; i++)
		dist += pow((o->comp[i] - s->mean[i]),2) * s->omega[i];

	return -1 * exp(dist);
}


int main(int argc, char const *argv[])
{
	int i, j;
	clock_t tic, toc;
	double scores[MAX_SENONES] = {0, 0, 0};
	// Test: 
	//printf("%f\n", sample1[1][2]);	// => -4.339
	printf("--- Starting ---\n");

	// The state and HMM definitions will be in a header somewhere

	// For each observation, loop through all the senones stored somewhere,
	// and calculate their scores using prob(...)
	tic = clock();
	for (i=0; i<2*1000000; i++)
		for (j=0; j<MAX_SENONES; j++)
			scores[j] += score( &sample1_o[i%2], &senones[j] );
			//printf("Senone %d score: %lf\n", j, score( &sample1_o[i%2], &senones[j] ));

	toc = clock();
	printf("Scoring %d senones took %f s\n", i*j, (double)(toc-tic) / CLOCKS_PER_SEC);
	printf("This is ~%lf s per senone\n", (double)(toc-tic)/CLOCKS_PER_SEC/i/j);

	printf("--- Done ---\n");
	return 0;
}