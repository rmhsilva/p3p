/**
 * main.c
 * This is the main application code for the pre-processing software, 
 * designed to communicate with La Papessa over serial port at 115200 baud.
 * Ricardo da Silva 2013
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>           // For va args
#include <stdint.h>           // For uint16_t
#include <unistd.h>
#include <fcntl.h>            // For file open flags
#include <termios.h>          // For baud rate #defines
#include <errno.h>
#include <math.h>
#include <time.h>             // For testing timing
#include <fftw3.h>            // FFTs
#include "libmfcc/libmfcc.h"  // external MFCC computation library

#include "gpio.h"
#include "serial.h"
#include "sample.h"
#include "preProcess.h"
#include "main.h"

#undef DEBUG    // if defined, Debug messages are shown

/****[ Globals ]*********************************************************/

int uart;             // The UART file descriptor
char uart_ready = 0;  // Bool to indicate that UART may be read/written

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
  system("echo [!] Error! Aborting. See stderr for details > /dev/tty0");

  va_end(args);
  exit(err);
}

// A debugging display function. dlvl: 0=nothing, 1=stderr, 2=stderr,tty0
void disp(int dlvl, const char *format, ...) {
  va_list args;
  static char tty0_open = 0;
  static FILE *tty_fd = 0;

  if (tty0_open == 0) {
    tty_fd = fopen("/dev/tty0", "w");

    if (tty_fd == NULL) {
      fprintf(stderr, "[!] Warning: Can't open /dev/tty0\n");
      tty0_open = -1;  // prevent trying to open tty0 again
    }
    else
      tty0_open = 1;
  }

  if (dlvl > 0) {
    va_start(args, format);
    vfprintf(stderr, format, args);
    if (dlvl > 1 && tty0_open > 0)
      vfprintf(tty_fd, format, args);
    va_end(args);
  }
}


/*****[ Application Specific Code ]**************************************/

/**
 * Pre-processes the data in (global) fft_in and stores the resulting mfccs
 * @param samples : Array of sampled data. *Should* point to fft_in as that
 *                  memory is allocated with fftw_malloc and may be optimised
 * @param mfccs   : The resulting cepstral coefficients. Assumes that mfccs
 *                  is an array big enough to hold N_CEPS doubles!
 */
void pre_process(double *samples, uint16_t *mfccs) {
  int i;
  double mfccs_d[N_CEPS];

  if (samples != fft_in) {
    disp(1, "[*] Warning (pre_process): `samples' should point to fft_in\n");
    fft_in = samples;
  }

  pre_emphasise(fft_in, PRE_EM, N);
  hamming(fft_in);
  fftw_execute(fft_p);

  // Take the magnitude of the FFT
  for (i=0; i<N; i++)
    fft_spectrum[i] = sqrt((fft_out[i][0]*fft_out[i][0]) + (fft_out[i][1]*fft_out[i][1]));

  // Get the MFCCs and then do liftering
  for (i=0; i<N_CEPS; i++)
    mfccs_d[i] = GetCoefficient(fft_spectrum, S_RATE, N_CHANS, N, i);
  lifter(mfccs_d);

#ifdef DEBUG
  // Debug - check the output of the MFCC calculation
  for(i=0; i<N_CEPS; i++)
    disp(1, "mfcc[%d]: %lf\n", i, mfccs_d[i]);
#endif

  // Convert them to the correct binary format
  // Note: mfccs[0] is the Energy component -- ignored for now.
  for (i=0; i<NUM_COMPS; i++)
    mfccs[i] = D_TO_U16( mfccs_d[1+i] );
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

/**
 * Given an observation vector (of MFCCs), send them to La Papessa and
 * return the senone scores.
 * @param observation : The observation components
 * @param scores      : An array to write the scores back to
 */
void get_scores(uint16_t *observation, uint16_t *scores) {
  static int obs_cnt = 0;
  uint32_t rec = 0;

  if (!uart_ready)
    die(-1, "Initialise UART before trying to use it :)");

#ifdef DEBUG
  int i;
  for(i=0; i<NUM_COMPS; i++)
    disp(1, "oframe[%d] = 0x%04x\n", i, observation[i]);
#endif

  // Send a vector
  obs_cnt++;
  if (send_vector(observation) != NUM_COMPS*2)
    die(-1, "Error sending observation %d", obs_cnt);

  // Receive scores
  while (rec < NUM_SENONES) {
    if (read(uart, &scores[rec], 2) == 2)
      rec++;
    else
      die(-1, "Timeout while receiving scores");
  }

  tcflush(uart, TCIOFLUSH); // Get rid of anything left in uart
}


/*****[ Main Routine ]***************************************************/

/**
 * main_init: Does all initialisation and setup for main
 */
void main_init() {
  disp(2,"[ ] Initialising UART, GPIO, MEM, FFTW\n");

  // Initialise serial
  uart = open(TTY_SER, O_RDWR | O_NOCTTY | O_SYNC);
  if (uart < 0)
    die(-1, "Error %d opening device %s: %s", errno, TTY_SER, strerror(errno));

  serial_init(uart, BAUD_DEFAULT, 1); // 0.1s read timeout
  uart_ready = 1;

  // And GPIO
  gpio_map();
  gpio_output(NEW_VEC_GPIO);
  gpio_wr(NEW_VEC_GPIO, 0);
  gpio_output(GPIO_TO_PIN(60));
  gpio_wr(GPIO_TO_PIN(60), 1);  // Power the onboard status LED

  // Initialise pre-processing (Hamming, Liftering)
  hamming_init(N);
  lifter_init(N_CEPS, CEP_LIFT);

  // Allocate FFTW memory and initialise the plan (fft_p)
  fft_spectrum = (double*) malloc(sizeof(double) * N);
  fft_in       = (double*) fftw_malloc(sizeof(double) * N);
  fft_out      = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N);
  fft_p        = fftw_plan_dft_r2c_1d(N, fft_in, fft_out, FFTW_MEASURE);

  usleep(CFG_WAIT);  // 100ms delay to allow hardware to finish config
  disp(2,"[+] Init complete.\n");
}

int main(int argc, char const *argv[])
{
  int i, j, do_vectors=1;
  uint16_t scores[NUM_SENONES];
  uint16_t mfccs[NUM_COMPS];
  char disp_buf[5 + (NUM_SENONES*7)];
  FILE *wav;

  // Initialise things
  main_init();

  
  // Get arguments if they exist, otherwise assign defaults
  if (argc > 2)
    do_vectors = atoi(argv[2]);       // How many vectors to send

  // Open a wav file for reading
  if (argc > 1)
    wav = fopen(argv[1], "r");        // Let user specify a WAV
  else
    wav = fopen("sample1.wav", "r");  // A default file to open
  
  if (wav == NULL)
    die(-1, "Couldn't open wav file");


  // Main operations:
  for(i=0; i<do_vectors; i++) {
    emul_sample(wav, fft_in, N);
    pre_process(fft_in, mfccs);
    get_scores(mfccs, scores);
    
    disp(2, "--- Observation Frame %d ---\n", i+1);
    for(j=0; j<NUM_SENONES; j++)
      sprintf(disp_buf+(j*7), "0x%04x ", scores[j]);
    printf("Scores: [ %s]\n", disp_buf);

    /* Note: The results still need to be scaled up by RESULT_SHIFT
     * However this isn't necessary for simply displaying them
     */
  }

  // Exit
  disp(2,"[+] Done, cleaning up.\n");
  close(uart);
  fclose(wav);
  fftw_destroy_plan(fft_p);
  fftw_free(fft_out);
  usleep(100000);
  gpio_wr(GPIO_TO_PIN(60), 0);
  return 0;
}
