#ifndef SERIAL_H
#define SERIAL_H

// A default baud rate
#define BAUD_DEFAULT B115200

/**
 * Initialise a file descriptor to be used as a serial port
 * @param  fd      : Pointer to an open file (eg /dev/ttySP1)
 * @param  baud    : Baud rate. Must be one defined in termios.h
 * @param  timeout : Read timeout (in 100ms units), -1 for blocking read
 * @return         : 0 success, -1 error
 */
int serial_init (int fd, speed_t baud, int timeout);

#endif
