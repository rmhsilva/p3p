/**
 * GPIO control
 * Mostly from the Olinuxino open-source project, hosted on github at:
 * https://github.com/OLIMEX/OLINUXINO/blob/master/SOFTWARE/iMX233/gpio-mmap.h
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include "gpio.h"

#define GPIO_BASE 0x80018000
#define GPIO_WRITE_PIN(gpio,value) GPIO_WRITE((gpio)>>5, (gpio)&31, value)
#define GPIO_WRITE(bank,pin,value) (gpio_mmap[0x140+((bank)<<2)+((value)?1:2)] = 1<<(pin))
#define GPIO_READ_PIN(gpio) GPIO_READ((gpio)>>5, (gpio)&31)
#define GPIO_READ(bank,pin) ((gpio_mmap[0x180+((bank)<<2)] >> (pin)) & 1)


/* gpio_mmap : Pointer to the actual mapped memory */
int *gpio_mmap = 0;

/**
 * gpio_map : sets up gpio_mmap correctly. Must be called first
 * @return nothing
 */
int *gpio_map() {
    int fd;
    if (gpio_mmap != 0) return 0;

    fd = open("/dev/mem", O_RDWR);
    if( fd < 0 ) {
        perror("Unable to open /dev/mem");
        fd = 0;
    }

    gpio_mmap = mmap(0, 0xfff, PROT_READ|PROT_WRITE, MAP_SHARED, fd, GPIO_BASE);
    if((int)gpio_mmap == -1) {
        perror("Unable to mmap file");
        gpio_mmap = 0;
    }
    if(close(fd) == -1)
        perror("Couldn't close file");
    fd=0;

    return 0;
}


/***[ General read/write functions ]********************************/

int gpio_rd(int bank, int pin) {
    return (gpio_mmap[0x180+(bank<<2)] >> pin) & 1;
}

void gpio_wr(int bank, int pin, int value) {
    gpio_mmap[0x140+(bank<<2)+((value)?1:2)] = 1<<pin;
}

void gpio_toggle(int bank, int pin) {
	GPIO_WRITE(bank,pin, (GPIO_READ(bank,pin))?0:1 );
}

/***[ These set a pin as output or input ]**************************/

void gpio_output(int bank, int pin) {
    gpio_mmap[0x1C1 + (bank*4)] = 1 << pin;
}

void gpio_input(int bank, int pin) {
    gpio_mmap[0x1C2 + (bank*4)] = 1 << pin;
}
