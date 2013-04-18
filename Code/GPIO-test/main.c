#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>     // For va args
#include <stdint.h>     // For uint16_t
#include <unistd.h>
#include <fcntl.h>      // For file open flags

#include "gpio.h"

int main(int argc, char const *argv[])
{
    gpio_map();
    gpio_output(GPIO_TO_PIN(92));   // Bank 2, Pin 5
    
    for (;;) {
        gpio_wr(GPIO_TO_PIN(92), 1);
        gpio_wr(GPIO_TO_PIN(92), 0);
    }
    return 0;
}
