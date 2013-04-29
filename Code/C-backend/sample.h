#ifndef SAMPLE_H
#define SAMPLE_H

/**
 * Function to emulate real data sampling.
 * Reads a WAV file that must be sampled at 8kHz, 16bit Mono PCM
 * This is approximately the same as sampling a mic at 8kHz
 * @param wav_file : Handle of an open WAV file
 * @param data     : Place to store data in
 * @param n        : Number of samples to read
 */
void emul_sample(FILE *wav_file, double *data, int n);

#endif
