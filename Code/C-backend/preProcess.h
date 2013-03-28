#ifndef PRE_PROCESS
#define PRE_PROCESS

/**
 * Initialises the array of lifter values
 * @param length   : number of MFCC coefficients
 * @param cep_lift : the scaling factor
 */
void lifter_init(int length, double cep_lift);

/**
 * Perform `Liftering' on a set of mfcc coefficients. See HTK p84
 * lifter_init must be called first
 * @param mfccs : The Cepstral coefficients to be liftered
 * @return      : Number of coefficients liftered, -1 on error
 */
int lifter(double *mfccs);

/**
 * Initialises the array of window values to be used by hamming()
 * @param length : The window length
 */
void hamming_init(int length);

/**
 * Apply a hamming window to some data
 * This function is made to work with pre-calculated values for a
 * specific window size.  First call hamming_init(N)
 * http://en.wikipedia.org/wiki/Window_function#Hamming_window
 * @param data   : input data
 * @return       : length of the window used, -1 on error
 */
int hamming(double *data);

/**
 * Pre-emphasise the input data with a difference equation. See HTK p82
 * s'[n] = s[n] - pre_em_coeff * s[n-1]
 * @param input : input data
 * @param a     : Pre-Emphasis coefficient
 * @param n     : number of data points
 */
void pre_emphasise(double *input, double a, int n);


#endif
