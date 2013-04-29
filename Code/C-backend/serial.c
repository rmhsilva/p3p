/**
 * Serial communications.
 * Not much other than config here really.
 * See http://pubs.opengroup.org/onlinepubs/007908775/xsh/termios.h.html
 */

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <termios.h>	// for serial things
#include <string.h>		// for memset
#include "serial.h"

// Initialise a file descriptor to be used as a serial port
int serial_init (int fd, speed_t baud, int timeout) {
	struct termios stty;
	
	memset(&stty, 0, sizeof(stty));		// Set up termios memory
	if (tcgetattr(fd, &stty) != 0) {
		printf("Error %d getting attributes", errno);
		return -1;
	}
	
	cfsetospeed(&stty, baud);	// Set input and output baud rates
	cfsetispeed(&stty, baud);

	// Optionally set a read timeout
	if (timeout < 0) {
		stty.c_cc[VMIN] = 1;	// blocking read (until 1 byte rec'd)
	}
	else {
		stty.c_cc[VMIN] = 0;	// No blocking read
		stty.c_cc[VTIME] = timeout; // Max time to wait for data
	}
	
	// Set important parameters
	stty.c_cflag = (stty.c_cflag & ~CSIZE) | CS8;	// 8 bit chars
	stty.c_iflag &= ~IGNBRK;						// Ignore break commands
	stty.c_lflag = 0;
	stty.c_oflag = 0;
	stty.c_iflag &= ~(IXON | IXOFF | IXANY);	// No flow ctrl
	stty.c_cflag |= (CLOCAL | CREAD);			// enable receiver
	stty.c_cflag &= ~(PARENB | PARODD);			// No parity
	stty.c_cflag &= ~CSTOPB;					// Send 1 stop bit
	stty.c_cflag &= ~CRTSCTS;
	
	if (tcsetattr(fd, TCSANOW, &stty) != 0) {
		printf("Error %d setting attributes", errno);
		return -1;
	}
	
	return 0;
}
