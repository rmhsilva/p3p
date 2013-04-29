/**
 * General Pre-processing, other than FFT and MFCC computation
 *     : Pre-emphasising (HTK p82)
 *     : Hamming windowing
 *     : Liftering (HTK p84)
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>

#ifndef PI
  #define PI 3.14159265358979
#endif
#define TPI 6.28318530717959  // 2*pi, from HTK HMath.h


static double *hamming_window;
static int hamming_length = -1;

static double *lifters;
static int lifter_length = -1;


// Initialises the array of lifter values
void lifter_init(int length, double cep_lift) {
  int i;
  lifter_length = length;
  lifters = (double *) malloc(sizeof(double) * length);

  for(i=0; i<length; i++)
    lifters[i] = 1 + (cep_lift/2.0) * sin(PI*i/(cep_lift*1.0));
}

//Perform `Liftering' on a set of mfcc coefficients.
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


// Initialises the array of window values to be used by hamming()
void hamming_init(int length) {
  int i;
  hamming_length = length;
  hamming_window = (double *) malloc(sizeof(double) * length);

  for (i=0; i<length; i++)
    hamming_window[i] = 0.54-(0.46*cos(TPI*(i/((length - 1)*1.0))));
}


// Apply a hamming window to some data
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


// Pre-emphasise the input data with a difference equation
void pre_emphasise(double *input, double a, int n) {
  int i;
  for(i=1; i<n; i++)
    input[i] -= a*input[i-1];

  input[0] *= 1.0 - a;
}
