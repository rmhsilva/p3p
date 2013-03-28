#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>		// For va_list etc
#include <stdint.h>		// For uint16_t
#include <unistd.h>
#include <fcntl.h>		// For file open flags
#include <termios.h>	// For baud rate #defines
#include <errno.h>
#include <math.h>
#include <time.h>		// For testing timing
#include <fftw3.h>		// FFTs
#include "libmfcc/libmfcc.h"	// MFCCs

#include "gpio.h"
#include "serial.h"
#include "preProcess.h"
#include "main.h"


/****[ Global Variables ]************************************************/

int uart;				// The UART file descriptor
char uart_ready = 0;	// Bool to indicate that UART may be read/written

// FFTW related variables
double *fft_in, *fft_spectrum;	
fftw_complex *fft_out;
fftw_plan fft_p;


/****[ Utilities ]*******************************************************/

// A die function that generates an error message and exits
void die(int err, const char *msg, ...) {
	va_list args;
	va_start(args, msg);

	fprintf(stderr, "[!] Exiting: ");
	vfprintf(stderr, msg, args);
	fprintf(stderr, "\n");

	va_end(args);
	exit(err);
}


/**
 * Send an observation vector via UART, including asserting the new_vec flag
 * @param  observation The vector to send
 * @return             Number of bytes written
 */
uint send_vector(uint16_t observation[]) {
	uint ret=0;

	// First provide a pulse on the new_vector pin to reset the fpga
	gpio_wr(NEW_VEC_GPIO, 0);
	gpio_wr(NEW_VEC_GPIO, 1);
	usleep(1);
	gpio_wr(NEW_VEC_GPIO, 0);

	// Write the observation to uart
	ret = write(uart, observation, NUM_COMPS*2);

	tcdrain(uart);
	return ret;
}

void get_scores(uint16_t *observation, uint16_t *scores) {
	static int obs_cnt = 0;
	uint32_t rec = 0, no = 0;

	if (!uart_ready) die(-1, "Initialise UART first please :)");
	
	// Send a vector
	if (send_vector(observation) != NUM_COMPS*2) {
		die(-1, "Error sending");
	}
	usleep(WAIT);
	obs_cnt++;
	printf("Sent observation vector number %d\n", obs_cnt);

	// Receive scores
	while (rec < NUM_SENONES) {
		if (read(uart, &scores[rec], 2) == 2) {
			rec++;
		}
		else no++;

		if (no > 0xFFFF) die(-1, "Timeout while reading");
	}

	tcflush(uart, TCIOFLUSH);	// Get rid of anything left in uart
}


// TODO: sampling / reading WAVs ??? Pull it all together...


/**
 * init: Does all initialisation and setup for main
 */
int init() {
	DISP("[ ] Initialising...");

	// Initialise serial
	uart = open(TTY_SER, O_RDWR | O_NOCTTY | O_SYNC);
	if (uart < 0) {
		fprintf(stderr, "Error %d opening device %s: %s", errno, TTY_SER, strerror(errno));
		return -1;
	}
	serial_init(uart, BAUD_DEFAULT);
	uart_ready = 1;
	usleep(WAIT);  // 100ms delay to allow hardware to finish config

	// And GPIO
	gpio_map();
	gpio_output(NEW_VEC_GPIO);
	gpio_wr(NEW_VEC_GPIO, 0);
	gpio_output(GPIO_TO_PIN(60));
	gpio_wr(GPIO_TO_PIN(60), 1);	// Power the onboard status LED

	// Initialise pre-processing (FFTW, Hamming, Liftering)
	hamming_init(N);
	lifter_init(N_CEPS, CEP_LIFT);

	fft_spectrum = (double*) malloc(sizeof(double) * N);
	fft_in       = (double*) fftw_malloc(sizeof(double) * N);
	fft_out      = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N);
	fft_p        = fftw_plan_dft_r2c_1d(N, fft_in, fft_out, FFTW_MEASURE);

	DISP("[+] Init complete.");
	return 0;
}


int main(int argc, char const *argv[])
{
	int i;
	char disp_buf[100];
	uint16_t scores[NUM_SENONES];
	uint16_t vec1[NUM_COMPS] = {0xdabe, 0x00c1, 0xfd3c, 0xfeda};

	// Initialise things
	if (init() < 0) {
		die(-1, "Error initialising");
		return -1;
	}
	usleep(WAIT);

	// Send!
	get_scores(vec1, scores);


	// Display results
	for(i=0; i<NUM_SENONES; i++) {
		sprintf(disp_buf, "Senone %d score: 0x%x", i, scores[i]);
		printf("%s\n",disp_buf);
		sprintf(disp_buf, "echo \"Senone %d score: 0x%x\" > /dev/tty0", i, scores[i]);
		system(disp_buf);
	}

	DISP("[+] Done.");
	close(uart);
	usleep(100000);
	gpio_wr(GPIO_TO_PIN(60), 0);
	return 0;
}







