#ifndef SAMPLE_H
#define SAMPLE_H

/**
 * Function to emulate real data sampling.
 * Reads a WAV file that must be sampled at 8kHz, 16bit Mono PCM
 * This is approximately the same as sampling a mic at 8kHz
 * @param wav_file : An open
 * @param data     : bla
 * @param n        : bla
 */
void emul_sample(FILE *wav_file, double *data, int n);

#endif
