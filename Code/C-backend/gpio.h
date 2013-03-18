#ifndef GPIO_H
#define GPIO_H

// Converts a gpio (from schematic) to a bank and pin combination
#define GPIO_TO_PIN(gpio) (gpio)>>5, (gpio)&31

int* gpio_map();

int gpio_rd(int bank, int pin);
void gpio_wr(int bank, int pin, int value);
void gpio_toggle(int bank, int pin);

void gpio_output(int bank, int pin);
void gpio_input(int bank, int pin);

#endif