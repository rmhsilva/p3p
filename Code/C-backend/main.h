#ifndef MAIN_H
#define MAIN_H

/*****[ Macros ]*********************************************************/

// Display (Debug) messages to the screen. No variables though.
#define DISP(msg) ({ printf("%s\n",msg); system("echo "msg" > /dev/tty0"); })

// Convert a double to an unsigned 16 bit int, shifted 10 bits left
#define D_TO_U16(x) ((uint16_t)((int)( (x)*1024.0 )))


/*****[ Other Defines ]**************************************************/

#define NUM_COMPS     6                 // Number of components per vector
#define NUM_SENONES   12                // Number of senones to be scored
#define RESULT_SHIFT  3                 // Amount to >> result by
#define CFG_WAIT      100000            // 0.1s delay for uart h.w. config
#define NEW_VEC_GPIO  GPIO_TO_PIN(92)   // new vector flag: bank,pin
#define TTY_SER       "/dev/ttySP1"     // The serial port file

#define S_RATE      8000.0  // Sampling Rate for the data (Hz)
#define PRE_EM      0.97    // Pre-emphasis to apply to data. Same as HTK
//#define N         200     // Sample number = 25ms window * 8kHz sampling rate
#define N           80      // In this case, it's a 10ms window
#define N_CEPS      NUM_COMPS
#define N_CHANS     26      // Number of channels for MFCC comp. See HTK p77
#define CEP_LIFT    22.0    // Liftering (scaling) for MFCCs. See HTK p75
#define BIN_SIZE    40.0    // 8000 / 200 = 40Hz per FFT bin


/*****[ Utility Functions ]**********************************************/

/**
 * A die function that displays an error message and then exits the program.
 * @param err : The error code to exit with
 * @param msg : Format string for the exit message
 * @param ... : Variables for the format string 
 */
void die(int err, const char *msg, ...)
    __attribute__((format(printf,2,3)))
    __attribute__((noreturn));

/**
 * Displays a message on stderr and optionally on /dev/tty0, depending on
 * the debug level
 * @param dlevel : Controls verbosity. 0:nothing. 1:stderr. 2:stderr & /dev/tty0
 * @param format : Format string for message
 * @param ...    : Variables for message
 */
void disp(const int dlevel, const char *format, ...)
    __attribute__((format(printf,2,3)));

#endif
