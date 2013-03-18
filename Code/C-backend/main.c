#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>		// for file open flags
#include <termios.h>	// for baud rate #defines
#include <errno.h>
#include "gpio.h"
#include "serial.h"

// Display (Debug) messages to the screen
#define DISP(msg) ({ printf("%s\n",msg); system("echo "msg" > /dev/tty0"); })

#define NUM_COMPS     4					// Number of components per vector
#define NUM_SENONES   3					// Number of senones to be scored
#define WAIT          100000			// 0.1s delay for uart
#define NEW_VEC_GPIO  GPIO_TO_PIN(92)	// new vector flag: bank,pin
#define TTY_SER       "/dev/ttySP1"

int uart;	// The UART file descriptor


/**
 * Send an observation vector via UART, including asserting the new_vec flag
 * @param  observation The vector to send
 * @return             Number of bytes written
 */
uint send_vector(uint16_t observation[]) {
	uint i, ret=0;

	// First provide a pulse on the new_vector pin to reset the fpga
	gpio_wr(NEW_VEC_GPIO, 0);
	gpio_wr(NEW_VEC_GPIO, 1);
	usleep(1);
	gpio_wr(NEW_VEC_GPIO, 0);

	// Loop over the observation
	// for(i=0; i<NUM_COMPS; i++) {
	// 	ret += write(uart, observation[i] , 2);
	// }

	ret = write(uart, observation, NUM_COMPS*2);

	tcdrain(uart);
	return ret;
}

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
	usleep(WAIT);  // 100ms delay to allow hardware to finish config

	// And GPIO
	gpio_map();
	gpio_output(NEW_VEC_GPIO);
	gpio_wr(NEW_VEC_GPIO, 0);
	gpio_output(GPIO_TO_PIN(60));
	gpio_wr(GPIO_TO_PIN(60), 1);

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
		DISP("[!] Aborting");
		return -1;
	}
	usleep(WAIT);

	// Send a vector
	if (send_vector(vec1) != NUM_COMPS*2) {
		DISP("[!] Error sending. Aborting");
		return -1;
	}
	usleep(WAIT);
	DISP("[+] Sent vector 1");

	// Receive scores
	if (read(uart, scores, NUM_SENONES*2) != NUM_SENONES*2) {
		DISP("[!] Error reading. Aborting");
		return -1;
	}

	tcflush(uart, TCIOFLUSH);	// Get rid of anything left in uart

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







