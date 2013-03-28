#ifndef MAIN_H
#define MAIN_H

/*****[ Macros ]*********************************************************/

// Display (Debug) messages to the screen. No variables though...
#define DISP(msg) ({ printf("%s\n",msg); system("echo "msg" > /dev/tty0"); })

// Convert a double to an unsigned 16 bit int, shifted 10 bits left
#define D_TO_U16(x) ((uint16_t)( x * 1024 ))


/*****[ Other Defines ]**************************************************/

#define NUM_COMPS     4					// Number of components per vector
#define NUM_SENONES   3					// Number of senones to be scored
#define WAIT          100000			// 0.1s delay for uart
#define NEW_VEC_GPIO  GPIO_TO_PIN(92)	// new vector flag: bank,pin
#define TTY_SER       "/dev/ttySP1"		// The serial port file

#define S_RATE		8000.0 	// Sampling Rate for the data (Hz)
#define PRE_EM		0.97 	// Pre-emphasis to apply to data. Same as HTK
#define N 			200		// Sample number = 25ms window * 8kHz sampling rate
#define N_CEPS		12 		// Number of MFCC coefficients to compute
#define N_CHANS 	26 		// Number of channels for MFCC comp. See HTK p77
#define CEP_LIFT 	22.0 	// Liftering (scaling) for MFCCs. See HTK p75
#define BIN_SIZE 	40.0 	// 8000 / 200 = 40Hz per FFT bin


/*****[ Utility Functions ]**********************************************/

// A die function that generates an error message
void die(int err, const char *msg, ...)
	__attribute__((format(printf,2,3)))
	__attribute__((noreturn));

#endif
