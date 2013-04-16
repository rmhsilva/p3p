#include <stdio.h>
#include <stdint.h>
#include "sample.h"

// Simulate sampling by reading a wav file in chunks
void emul_sample(FILE *wav_file, double *data, int n) {
	int i;
	uint8_t sample[2];	// TODO: are my files really unsigned?????
	static int position = 0;

	// Skip over the WAV header
	if (position == 0) {
		fseek(wav_file, 44, SEEK_SET);
		position += 44;
	}
	
	// Read n samples (My wav's are little endian)
	for (i=0; i<n; i++) {
		fread(sample, 1, 2, wav_file);
		data[i] = (double) ((sample[0] << 8) | sample[1]);
	}
	position += n;
}