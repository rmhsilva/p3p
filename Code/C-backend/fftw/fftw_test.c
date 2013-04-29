/**
 * Testing FFTW
 * See http://www.fftw.org/fftw3_doc/
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>		// Timing
#include <math.h>
#include <fftw3.h>		// FFTW library
#include "libmfcc.h"

#define S_RATE	8000.0 	// The Sampling Rate (Hz)
#define PRE_EM	0.97 	// Pre-emphasis to apply to data. Same as HTK
#define N 		200		// Sample number = 25ms window * 8kHz sampling rate
#define N_CEPS	12 		// Number of MFCC coefficients to compute
#define N_CHANS 26 		// Number of channels for MFCC comp. See HTK p77
#define CEP_LIFT 22.0 	// Scaling for MFCCs. See HTK p75
#define BIN_SIZE 40.0 	// 8000 / 200 = 40Hz per FFT bin

/*
 * 3kHz sine wave:
 */
const double sin_test[200] = {
	0.0 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	3.67394039744e-16 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-7.34788079488e-16 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	1.10218211923e-15 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-1.46957615898e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-1.71574348008e-15 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-2.20436423847e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-9.80955400591e-16 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-2.93915231795e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-7.3515946787e-15 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	3.43148696016e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	1.46994754736e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-4.40872847693e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-2.00928732349e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	1.96191080118e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	1.95819691736e-15 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-5.87830463591e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	9.79841235445e-15 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	1.47031893574e-14 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	1.76386277915e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	6.86297392032e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-2.94286620177e-15 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-2.93989509472e-14 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	4.89734923532e-15 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-8.81745695386e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	1.27375646724e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	4.01857464699e-14 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	2.05777801095e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	3.92382160236e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-2.84254233142e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-3.91639383473e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	3.62582109837e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-1.17566092718e-14 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-1.274499244e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-1.95968247089e-14 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-6.17481958638e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	2.94063787148e-14 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	2.93543843413e-15 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-3.52772555831e-14 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	1.07756538712e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	1.37259478406e-14 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-3.82275495525e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	5.88573240355e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-3.03873341154e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-5.87979018944e-14 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-2.25471186783e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-9.79469847063e-15 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-1.47069032412e-14 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187 ,
	-1.76349139077e-14 ,
	0.707106781187 ,
	-1.0 ,
	0.707106781187 ,
	-6.86668780414e-15 ,
	-0.707106781187 ,
	1.0 ,
	-0.707106781187
};

static double *hamming_window;
static int hamming_length = -1;

static double *lifters;
static int lifter_length = -1;

/**
 * Initialises the array of lifter values
 * @param length   : number of MFCC coefficients
 * @param cep_lift : the scaling factor
 */
void lifter_init(int length, double cep_lift) {
	int i;
	lifter_length = length;
	lifters = (double *) malloc(sizeof(double) * length);

	for(i=0; i<length; i++)
		lifters[i] = 1 + (cep_lift/2.0) * sin(PI*i/(cep_lift*1.0));
}

/**
 * Perform `Liftering' on a set of mfcc coefficients.
 * lifter_init must be called first
 * See HTK p84
 * @param mfccs : The Cepstral coefficients to be liftered
 * @return      : Number of coefficients liftered, -1 on error
 */
int lifter(double *mfccs) {
	int i;
	if (lifter_length == -1) {
		fprintf(stderr, "lifter_init(...) MUST be called before lifter()\n");
		return -1;
	}
	for(i=0; i<lifter_length; i++)
		mfccs[i] *= lifters[i];
	return i;
}

/**
 * Initialises the array of window values to be used by hamming()
 * @param length : The window length
 */
void hamming_init(int length) {
	int i;
	hamming_length = length;
	hamming_window = (double *) malloc(sizeof(double) * length);

	for (i=0; i<length; i++)
		hamming_window[i] = 0.54-(0.46*cos(2*PI*(i/((length - 1)*1.0))));
}

/**
 * Apply a hamming window to some data
 * This function is made to work with pre-calculated values for a
 * specific window size.  First call hamming_init(N)
 * http://en.wikipedia.org/wiki/Window_function#Hamming_window
 * @param data   : input data
 * @return       : length of the window used, -1 on error
 */
int hamming(double *data) {
	int i;
	if (hamming_length == -1) {
		fprintf(stderr, "hamming_init(...) MUST be called before hamming()\n");
		return -1;
	}
	for(i=0; i<hamming_length; i++)
		data[i] *= hamming_window[i];
	return i;
}

/**
 * Pre-emphasise the input data with a simply difference equation
 * s'[n] = s[n] - pre_em_coeff * s[n-1].   See HTK p82
 * @param input : input data
 * @param a     : Pre-Emphasis coefficient
 * @param n     : number of data points
 */
void pre_emphasise(double *input, double a, uint n) {
	int i;
	for(i=1; i<n; i++)
		input[i] -= a*input[i-1];
	input[0] *= 1.0 - a;
}


int main(int argc, char const *argv[])
{
	int i;
	clock_t tic, toc;
	double *in, *spectrum;
	fftw_complex *out;
	fftw_plan p;
	double mfccs[N_CEPS];

	printf("[+] Initialising... ");
	tic = clock();
	in = (double*) fftw_malloc(sizeof(double) * N);
	spectrum = (double*) malloc(sizeof(double) * N);
	out = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N);
	p = fftw_plan_dft_r2c_1d(N, in, out, FFTW_MEASURE);

	hamming_init(N);
	lifter_init(N_CEPS, CEP_LIFT);
	toc = clock();
	printf("Done, took: %f s\n", (double)(toc - tic) / CLOCKS_PER_SEC);

	// for(i=0; i<N; i++) {
	// 	printf("Hamming[%d]: %lf\n", i, hamming_window[i]);
	// }
	// for(i=0; i<N_CEPS; i++) {
	// 	printf("Lifter[%d]: %lf\n", i, lifters[i]);
	// }

	// test: copy data.
	for(i=0; i<N; i++)
		in[i] = sin_test[i];

	printf("[+] Running FFT... ");
	tic = clock();

	// Apply pre-emphasis and hamming window to the data
	pre_emphasise(in, PRE_EM, N);
	hamming(in);

	fftw_execute(p);

	// take magnitude of the DFT
	for (i=0; i<N; i++)
		spectrum[i] = sqrt((out[i][0]*out[i][0]) + (out[i][1]*out[i][1]));

	toc = clock();
	printf("Done, took: %f s\n", (double)(toc - tic) / CLOCKS_PER_SEC);

	// for(i=0; i<200; i++) {
	// 	printf("spectrum[%d]:\t %f\n", i, spectrum[i]);
	// }

	// pass to libMFCC
	// Problem: Computing each MFCC takes the same amount of time (~0.16s)
	// This should not be the case, as the multiplication factors need to
	// be computed only once...
	// The GetCoefficient should return ALL the coeffs..
	// Computing the 10th coeff requires computing all the previous ones...
	// LibMFCC is NOT ideal, but works (slowly) for now.
	printf("[+] Computing MFCCs... ");
	tic = clock();
	for (i=0; i<N_CEPS; i++) {
		mfccs[i] = GetCoefficient(spectrum, S_RATE, N_CHANS, N, i);
	}
	lifter(mfccs);
	toc = clock();
	printf("Done, took: %f s\n", (double)(toc - tic) / CLOCKS_PER_SEC);

	for(i=0; i<N_CEPS; i++) {
		printf("MFCC[%d]: %f\n", i, mfccs[i]);
	}

	printf("[+] Cleaning memory and returning\n");
	fftw_destroy_plan(p);
	fftw_free(in); fftw_free(out);
	return 0;
}

