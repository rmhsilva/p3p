#include <iostream>

using std::cout;
using std::endl;

#include <cassert>
#include "HMMViterbi.hh"

/* 
This program is a simple implementation of a connected unit Viterbi
decoder.  It is designed using the "token passing" model whereby each
state of an N-State HMM holds a single token.
*/


typedef struct{
  LogFloat prob;		/* log prob of partial path */
  int stFrame;         	/* frame index on entering current model */
}Token;

typedef struct{
  int numStates;	 	/* num states N in this instance */
  Token tok[MAXSTATES]; 	/* token for each state (tok[1] to tok[N]) */
}Instance;

typedef struct{
  int hmmIdx;			/* model index of best HMM */
  int stFrame;         	/* frame index where it starts */
}BoundInfo;

static Instance insts[MAXMODELS];       /* HMM insts indexed 0 to numPhones-1 */
static BoundInfo bnds[MAXFRAMES];       /* Best model ending at each frame */
static BoundInfo bndsrev[MAXFRAMES];       /* Best model ending at each frame */
static Instance tmpinsts[MAXMODELS];    /* HMM insts indexed 0 to numPhones-1 */
static Token stTok   = {0.0,0};
static Token nullTok = {LZERO,0};  

/* ---------------------- Top Level of Program ---------------------- */

void HMMViterbi::Initialise()
{
  int nmod,i,j,N;
  HMMModel h;


  numPhones = hsys->numModels();
  if (numPhones>MAXMODELS)
    HError(1,"%d models loaded, only have space for %d",
	   numPhones,MAXMODELS);
  vSize = hsys->sizeVector();
  for (i=0; i<numPhones; i++){
    hsys->getModel(i,h);
    N = h.numStates();
    if (N>=MAXSTATES)
      HError(1,"Model %s has too many states [%d]",
	     h.getName(),N);
    insts[i].numStates = N;
  }

  // Initialise all the tokens in the network
  for (i=0; i<numPhones; i++){
    insts[i].tok[1] = stTok;
    tmpinsts[i].tok[1] = stTok;
    for (j=2; j<=insts[i].numStates; j++) {
      insts[i].tok[j] = nullTok;
      tmpinsts[i].tok[j] = nullTok;
    }
  }
}

void HMMViterbi::setInsertPen(const LogFloat pen)
{
  insertPen = pen;
}

/* ---------------------- Recognition ------------------------ */

/* StepModels: internally propagate all tokens in all states of
   all models.  Token propagation must be done 'in parallel' so
   store propagated tokens in a temporary array and copy back 
   into the model inst when all tokens propagated */
void HMMViterbi::StepModels(void)
{
  int kmax;
  LogFloat  x, xhi;
  HMMModel h;

  //cout << "In StepModels" << endl;

  // iterate over phones
  for (int i=0; i<numPhones; i++){

    hsys->getModel(i,h);

    for (int jd=2; jd<insts[i].numStates; jd++) {

      // find pred state for which prob + log a is maximum
      xhi = LZERO;
      kmax = 1;

      for (int k=1; k<=jd; k++) {

        x = insts[i].tok[k].prob + h.getTrans(k,jd);            

        if (x > xhi) {
          xhi = x;
          kmax = k;	   
        }

      }

      // copy that token into state jd
      tmpinsts[i].tok[jd] = insts[i].tok[kmax];  
      tmpinsts[i].tok[jd].prob += (h.getTrans(kmax,jd) + h.getOProb(ot,jd));    

    }
  }

// finding and copying the best exit token into state N of the best model
// is done by BestExitToken as given in Bill Byrne's Speech 1 notes.


// copy back tmp tokens
  for (int i=0; i<numPhones; i++){
    for (int j=1; j<=insts[i].numStates; j++) {
      insts[i].tok[j] =tmpinsts[i].tok[j];
    }
  }

}


/* PropagateBestToken: take token in exit state of best model bestPhn
   ending at time t, add the phone to phone insertion penalty and 
   propagate to all entry states */
void HMMViterbi::PropagateBestToken(int bestPhn, int t)
{
  int N;
  char rchar;
  char *name;
  Token q;
  HMMModel h;
   
  N = insts[bestPhn].numStates;
  q = insts[bestPhn].tok[N];

  q.stFrame = t+1;
  q.prob = q.prob + insertPen;

  // find the rightmost phone
  hsys->getModel(bestPhn,h);
  name = h.getName();
  rchar = name[strlen(name)-1];
  

  // copy token q into state 1 of all models
  for (int i=0; i<numPhones; i++){
  
    hsys->getModel(i,h);
    name = h.getName();

    // allow only consistent sequences
    if (rchar == name[0])
      insts[i].tok[1] = q;
    else
      insts[i].tok[1] = nullTok;
  }
  
}

/* BestExitToken: find the model with the best exit token */
int HMMViterbi::BestExitToken(void)
{
  int j, jmax, imax, N;
  LogFloat x, xhi;
  HMMModel h;

  imax = 0;  // model 0
  jmax = 1; // state 1
  xhi = LZERO;

  // iterate over phones
  for (int i=0; i<numPhones; i++){
   hsys->getModel(i,h);

   for (j=1; j<insts[i].numStates; j++) {

      // find pred state jmax in model imax for which prob + log a is maximum
      x = insts[i].tok[j].prob + h.getTrans(j,insts[i].numStates);            

      if (x > xhi) {
        xhi = x;
        jmax = j;
        imax = i;
      }
    }
  }

  hsys->getModel(imax,h);

  // copy the best exit token into state N of the best model
  N = insts[imax].numStates;
  insts[imax].tok[N] = insts[imax].tok[jmax];
  insts[imax].tok[N].prob +=  h.getTrans(jmax,N);            

  return(imax);
} 



/* RecordBestToken: store start time and identity in bnds of best model
                    ending at time t */
void HMMViterbi::RecordBestToken(int bestPhn, int t)
{

  int N;
  Token q;
  
  N = insts[bestPhn].numStates;
  q = insts[bestPhn].tok[N];

  bnds[t].hmmIdx = bestPhn;
  bnds[t].stFrame = q.stFrame;
}



/* TraceBack: starting from the last frame end of speech, trace back 
   through the bnds array to find the mostly likely sequence of
   models. */
void HMMViterbi::TraceBack(FILE *f, int end)
{  
 
  int index, i, j,  m, s;
  char *name;
  HMMModel h;

  index = end;

  i = 1;

  while (index > 0) {
    
    m = bnds[index].hmmIdx;
    s = bnds[index].stFrame;

    //hsys->getModel(m,h);
    //name = h.getName();
    //cout << bnds[index].stFrame  << "\t"  << name << endl;

    bndsrev[i].hmmIdx = m;
    bndsrev[i].stFrame = s;
    i++;

    index = s-1; 
  }
  bndsrev[0].stFrame = end+1;

  //count << endl;

  for (j=i-1; j>0; j--) {

    m = bndsrev[j].hmmIdx;
    hsys->getModel(m,h);
    name = h.getName();
    //count  << bndsrev[j].stFrame << "0000" << "\t" << bndsrev[j-1].stFrame << "0000 " << name << endl;
    cout << name << " ";
    fprintf(f,"%8d %8d %s\n",bndsrev[j].stFrame*10000,bndsrev[j-1].stFrame*10000, name);
  }
  cout << endl;
}

/* writeDecision: write the best state sequence to a file */
void HMMViterbi::writeDecision(char *outdir, char *testfile)
{
  FILE *f;
  char outname[256];

  if (trace>0) printf("Rec: ");
  MakeFN(testfile,outdir,"rec",outname);
  if ((f = fopen(outname,"w")) == NULL)
    HError(999,"Cannot open output file %s",outname);
  TraceBack(f,nFrames-1);
  fclose(f);
  if (trace>0) printf("\n");
}

// prob of last token, but need to allow for different lengths
LogFloat HMMViterbi::getLogLike()
{

  int N,bestPhn;
  float ll;
  Token q;

  bestPhn = bnds[nFrames-1].hmmIdx;
  
  N = insts[bestPhn].numStates;
  q = insts[bestPhn].tok[N];
  
  //  cout << "Nframes is " << nFrames << endl;

  ll = q.prob / (nFrames);

  return ll;
}

/* doRecognition: initialise the HMM insts and then process testfile
   frame by frame.  Until the last frame, each cycle consists of
   propagating all tokens within each model, finding the best
   exit token and propagating it to the start of all models */
void HMMViterbi::doRecognition(char *testfile)
{
  int t,N;
  FILE *f;
  HMMParmBuf p;
  trace =1 ;

  if (trace >0) 
    cout << "Recognising " << testfile << endl;
  Initialise();
  p.loadSpeech(testfile);
  nFrames = p.numVectors();
  if (trace >1)
    cout << "Speech file " << testfile << " loaded with " 
	 << nFrames << " frames" << endl;

  if (p.sizeVector() != vSize)
    HError(-1,"Incompatible vec size HMM=%d, base speech file=%d",
	   vSize,p.sizeVector());

  /* Process speech frame by frame */
   for (t=0; t<nFrames; t++){

     p.getVector(t,ot);
     StepModels();
     bestp = BestExitToken();
     RecordBestToken(bestp,t);
     if (t < nFrames-1)
       PropagateBestToken(bestp,t);
  }
  if (trace >0)
    cout << "Log-likelihood = " << getLogLike() << endl;
  p.unloadSpeech();
}

/* ----------------------------------------------------------- */

