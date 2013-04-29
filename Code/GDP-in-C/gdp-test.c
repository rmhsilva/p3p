/**
 * This is an implementation of the Gaussian Distance evaluation.
 * It uses floating point values however.
 * Ricardo da Silva 2013
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>


#define N_COMPS     25  // The number of components per observation vector
#define N_SENONES   12  // Number of states (senones)
#define MAX_COMPS   25  // Max number of components to process
#define MAX_SENONES 5   // Max number of senones to process
#define K_SHIFT     2   // Scaling down factor for K

typedef union {
  struct {
    double mfcc[12];
    double del[13];
  } s;
  double comp[N_COMPS];
} OVector;

typedef struct {
  double k;
  double mean[N_COMPS];
  double omega[N_COMPS];  // = 0.5/variance^2
} Senone;


// First two samples of sample1.mfcc (12xMFCC, 12xDel, DelC0)
// $ HList -h -e 3 -o sample1.mfcc
OVector sample1_o[] = {
  {   -18.684, -4.821, -4.996, -1.257, -3.512, -0.453, -6.513, -1.960, -4.348, 1.189,
    -3.690,  -0.572, -0.005,  0.495,  0.045, -0.285,  0.093,  1.178, 0.909,
    0.662,   -0.380, -1.215, -0.892, -0.678, -0.052 },
  {   -18.885, -3.467, -4.339, -1.698, -2.771,  4.419, -6.686, -1.222, -3.780,  0.970,
    -5.154,  -5.745, -0.252,  0.287, -0.312, -0.476, -0.550,  0.493,  0.883,
     0.886,  -0.460, -1.087, -0.440,  0.730, -0.172 }
};

// Senone parameters, generated by Lisp
Senone senones[N_SENONES] = {
  /* Senone 11 (ST_ow_3_83): */
  { k:     -42.037697,
    mean:  { -0.1238637, -0.2752218, 0.04219692, 0.2682348, 0.1241765, -0.1187387, 0.174705, 0.540849, -0.1241921, 0.1578213, 0.4971163, 0.2947437, -0.04093564, 1.808968, 4.356804, -3.603999, -4.801826, 1.149546, -4.320206, -7.761794, 1.133214, 4.37785, -3.95456, -3.202314, 9.563365 },
    omega: { 2.7498138, 0.33319828, 0.35065228, 0.46762407, 0.30121788, 0.32237723, 0.35574302, 0.5381649, 0.6463569, 0.6833101, 0.7668767, 1.5351198, 2.2176478, 0.015873998, 0.013432306, 0.014617399, 0.010451533, 0.01288514, 0.009790536, 0.019331038, 0.010099218, 0.014560183, 0.014818609, 0.032180127, 0.045861967 } },
  /* Senone 10 (ST_v_2_27): */
  { k:     -48.69782,
    mean:  { -0.2516595, -0.08483685, 0.0294413, 0.199706, -0.2840677, 0.0404758, -0.1175052, -0.2420893, 0.5282627, 0.9067854, 0.4767838, 0.8149973, -0.07147351, -0.1528362, -1.682972, -2.831595, 1.049697, 3.480547, -0.2654185, -2.264133, -6.664085, -4.865524, -1.660532, 1.295852, 7.260993 },
    omega: { 0.37726906, 0.1815112, 0.12875594, 0.15392932, 0.16744372, 0.1710799, 0.16337061, 0.18997076, 0.18116513, 0.1741494, 0.3267974, 0.30532357, 0.69572747, 0.012708202, 0.0111516705, 0.013783032, 0.015853172, 0.014080294, 0.010649634, 0.01417592, 0.019304333, 0.013323502, 0.027520142, 0.02317088, 0.047322046 } },
  /* Senone 9 (ST_ae_4_17): */
  { k:     -43.83508,
    mean:  { -0.4047516, -0.05326056, -0.1192584, -0.1568439, -0.1093456, 0.2392908, -0.04662286, 0.3226627, -0.1254602, -0.03157998, -0.4953188, 0.2958873, -0.03052555, 1.809745, 1.676583, -1.147342, -2.860159, -3.168358, 2.904502, 1.766067, -0.3521228, -3.824356, 0.2659411, -5.71393, -3.788797 },
    omega: { 0.77094364, 0.41084567, 0.3666993, 0.26892462, 0.28594238, 0.27028254, 0.30797547, 0.4474225, 0.4179704, 0.5451971, 0.6784247, 0.8301901, 0.86061096, 0.020469103, 0.018636724, 0.010711487, 0.006439062, 0.015004628, 0.010823493, 0.014331867, 0.021083916, 0.01723862, 0.029670315, 0.027361443, 0.034038566 } },
  /* Senone 8 (ST_r_4_107): */
  { k:     -51.3532,
    mean:  { 0.1104839, 0.2171581, -0.0195196, -0.1648417, 0.3965724, -0.2330181, -0.2650119, 0.2319123, 0.3427696, -1.235944, 0.4933986, -0.141569, -0.4739511, 2.132354, -2.470716, -1.748204, 0.2848097, 0.894938, -0.4597573, 1.373031, -5.834762, -1.129719, 2.099405, 2.093748, 6.259917 },
    omega: { 0.5903924, 0.14313458, 0.1689264, 0.15924303, 0.15722084, 0.120466396, 0.10405976, 0.12426049, 0.11383571, 0.10518178, 0.25100565, 0.22022153, 0.40333152, 0.014273985, 0.014801815, 0.014807217, 0.011874144, 0.01062683, 0.009561186, 0.010799474, 0.010143906, 0.010289137, 0.0187744, 0.014719342, 0.038157627 } },
  /* Senone 7 (ST_ah_3_68): */
  { k:     -50.3424,
    mean:  { -0.6231858, -0.9777656, -0.4024917, 1.071619, 0.6169897, -0.4230803, 1.201199, 0.3891984, -0.3928518, 0.4950105, 1.536223, 0.8426484, -1.310814, -0.2471085, 5.309228, -1.297143, -4.719993, 4.096592, 3.578004, -7.187865, -3.907341, 5.221713, -4.289326, -5.040376, 1.937276 },
    omega: { 0.31137845, 0.15579134, 0.12666774, 0.14642642, 0.13119082, 0.13239482, 0.13821532, 0.12159051, 0.14803314, 0.18531072, 0.21390814, 0.29572973, 0.57343745, 0.015816648, 0.015277896, 0.011240155, 0.011762517, 0.008743206, 0.012711051, 0.011139869, 0.012097305, 0.01672953, 0.021401728, 0.026986709, 0.041661218 } },
  /* Senone 6 (ST_ey_4_46): */
  { k:     -47.817406,
    mean:  { -0.3732284, -0.2589906, -0.04583126, -0.1115527, -0.3146526, 0.003884856, -0.0340459, 0.1380495, -0.162348, 0.7084103, 0.5636564, 0.8781577, 0.313024, -0.4739895, 1.648438, -2.705333, -1.709231, -0.5933363, -9.19943, -8.999229, 0.4771821, -0.161204, -1.444507, 8.108547, 11.51389 },
    omega: { 0.34035856, 0.24170001, 0.22312485, 0.22484522, 0.25272003, 0.19286515, 0.26859224, 0.18632536, 0.31629995, 0.24278033, 0.44725642, 0.28774428, 0.9175382, 0.017896771, 0.011851775, 0.015886845, 0.011311191, 0.009964359, 0.009186406, 0.0123731205, 0.01609859, 0.010309599, 0.018232964, 0.020046636, 0.032852203 } },
  /* Senone 5 (ST_l_3_110): */
  { k:     -48.56582,
    mean:  { -0.1725896, -0.01252445, 0.002635724, 0.2379868, 0.196843, 0.1861943, 0.2307368, -0.03346496, -0.2644183, 0.350923, 0.5138327, 0.713859, -0.08298364, -0.8624105, 1.280935, -5.598276, -5.19685, 0.3571944, -6.509619, -0.9264624, 4.848447, 0.7381644, -8.348698, 3.294811, 15.521 },
    omega: { 0.68249846, 0.2698209, 0.20178261, 0.17286766, 0.17202473, 0.19074847, 0.14050888, 0.15965061, 0.18925688, 0.26670507, 0.208525, 0.40576774, 0.75589436, 0.021189898, 0.012801419, 0.012769187, 0.014173739, 0.012452234, 0.01459874, 0.009136523, 0.010561114, 0.015017769, 0.009346514, 0.02492725, 0.038222678 } },
  /* Senone 4 (ST_ax_3_22): */
  { k:     -52.7032,
    mean:  { 1.045722, -0.01854272, 0.3995951, -0.4248601, -0.4293636, 0.2365726, -0.9198285, -0.9449574, 0.1621115, -0.1984376, -0.01482141, 0.3056754, 1.333655, 1.043509, -0.3112698, -1.608274, 1.440788, 2.885993, 0.01661486, -0.5747675, -6.967625, -4.295047, -0.7941749, 1.610688, 3.639316 },
    omega: { 0.26112226, 0.14335902, 0.08105779, 0.11326121, 0.10429921, 0.10828147, 0.09581576, 0.10848705, 0.13610364, 0.12248396, 0.20922786, 0.23412888, 0.22727065, 0.019094398, 0.015316863, 0.014365739, 0.014427225, 0.013488876, 0.009902804, 0.011240524, 0.011707817, 0.008134178, 0.017561255, 0.013963649, 0.028152503 } },
  /* Senone 3 (ST_v_2_28): */
  { k:     -48.53174,
    mean:  { -0.6474816, -0.2879819, -0.2545069, 0.4214189, -0.5071451, -0.5181996, 0.5245908, 0.07814562, 0.3252554, 1.418259, 0.7143379, 0.6525487, -0.5363405, -1.313061, -1.4088, -2.890042, 1.356108, 0.5117961, -4.880285, -6.637192, -3.734066, -1.639929, 2.334646, 2.721218, 7.635345 },
    omega: { 0.37696245, 0.23370636, 0.18823707, 0.19204606, 0.1745796, 0.1758468, 0.15445083, 0.12698022, 0.13720345, 0.17186046, 0.26171735, 0.3070165, 0.37276796, 0.017931238, 0.014580775, 0.01801916, 0.014297855, 0.017622668, 0.012998205, 0.016667655, 0.01784015, 0.012858581, 0.026089512, 0.021660343, 0.04168334 } },
  /* Senone 2 (ST_ae_4_18): */
  { k:     -42.171024,
    mean:  { -0.3647242, -0.1277833, -0.1092261, -0.03736734, -0.07338901, 0.05502949, 0.06683896, 0.4549827, -0.1958804, 0.1451689, -0.03807305, 0.4163231, -0.1312575, 1.817442, 2.089398, -2.571422, -3.079007, -2.797016, 0.167668, -1.552593, 0.3079382, -1.311694, 1.281243, -3.994659, -0.02301142 },
    omega: { 2.1058235, 0.63253194, 0.4873793, 0.42928475, 0.4319147, 0.4783714, 0.437502, 0.54363436, 0.5719502, 0.7057387, 0.9911993, 1.1654224, 1.5736785, 0.019850392, 0.013992727, 0.0114091635, 0.009828259, 0.013315796, 0.011455006, 0.010119245, 0.013118126, 0.011437091, 0.016844073, 0.017512877, 0.029473398 } },
  /* Senone 1 (ST_r_4_108): */
  { k:     -48.43822,
    mean:  { 0.07522945, 0.3816832, 0.4069113, -0.241427, 0.08144391, 0.08604367, -0.7059969, 0.1704739, 0.5249807, -0.6636739, 0.02316372, 0.2308965, 0.2790157, 3.355347, -2.465519, -2.32644, -0.2790849, -0.8065963, 0.3011959, 3.802077, -2.417308, -1.913995, 1.85043, -0.8573892, 4.246782 },
    omega: { 1.5862699, 0.2198497, 0.22020389, 0.216844, 0.16250122, 0.17585628, 0.15950285, 0.1390086, 0.17668755, 0.2015703, 0.37443367, 0.3553039, 0.8839546, 0.015959848, 0.015580402, 0.01692001, 0.00960982, 0.0096618, 0.008611627, 0.008610058, 0.00878911, 0.013892933, 0.026711356, 0.014819368, 0.036674663 } },
  /* Senone 0 (ST_ey_4_47): */
  { k:     -47.54454,
    mean:  { -0.3293856, -0.2136827, -0.06553839, -0.01288294, -0.1698855, -0.02062051, -0.2004738, 0.08641994, -0.030349, 0.6260473, 0.349449, 0.3114232, 0.02882212, -0.7253956, 1.465655, -0.9526349, -0.9686497, 0.7329352, -4.067567, -5.05192, -1.456967, -1.285092, -1.527962, 3.741305, 5.909739 },
    omega: { 0.4069338, 0.2583783, 0.24376877, 0.2087152, 0.22016482, 0.22563075, 0.1916421, 0.16179533, 0.20758946, 0.17990899, 0.33730316, 0.27367777, 0.6879633, 0.02396794, 0.01762854, 0.017260157, 0.01494536, 0.015557046, 0.0091652125, 0.011902586, 0.015589801, 0.017152535, 0.01642813, 0.020314805, 0.042014197 } },
};


/**
 * Calc the prob of a certain observation for a set of probabilities
 * @param  o : Observation
 * @param  s : Senone
 * @return   : The score
 */
double score(OVector *o, Senone *s) {
  double dist = 0;
  int i;

  // Eq 3.4
  for (i = 0; i < MAX_COMPS; i++)
    dist += pow((o->comp[i] - s->mean[i]),2) * s->omega[i];

  return s->k - dist;
}


int main(int argc, char const *argv[])
{
  int i, j;
  clock_t tic, toc;
  double scores[MAX_SENONES];
  unsigned int limit = 200000;

  printf("--- Starting GDP test ---\n");

  if (argc > 1)
    limit = atoi(argv[1]);

  // For each observation, loop through all the senones,
  // and calculate their scores
  tic = clock();
  for (i=0; i<limit; i++)
    for (j=0; j<MAX_SENONES; j++)
      scores[j] = score( &sample1_o[i%2], &senones[j] );

  toc = clock();
  printf("Scoring %d senones took %f s\n", i*j, (double)(toc-tic) / CLOCKS_PER_SEC);
  printf("This is ~%lf s per senone\n", (double)(toc-tic)/CLOCKS_PER_SEC/i/j);

  printf("--- Done ---\n");
  return 0;
}
