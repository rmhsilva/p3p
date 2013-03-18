#ifndef SERIAL_H
#define SERIAL_H
#include <termios.h>

// A default baud rate
#define BAUD_DEFAULT B115200

// Publicised functions
int serial_init (int fd, speed_t baud);

#endif