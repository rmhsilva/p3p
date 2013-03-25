#!/bin/sh
# Script to adapt the Voxforge Models. Make sure that these dirs exist
#   - mfcc, hmm16, hmmAdapt
# See http://www.voxforge.org/home/dev/acousticmodels/linux/adapt/htkjulius/
# Ricardo da Silva

# Path to HTK binaries
HTK=/Users/ric/Documents/University/Part3/Part-3-Project/HTK/htk-bin-3.2.1

# Downsample the recorded audio to 8kHz -> wav/sample{1-31}.wav
# Assumes audio is recorded as WAV, 48K, 16-bit, mono
echo "* Downsampling Audio"
./downsample.pl FilesToBeDownsampled wav 48000 8000

# Create the mfccs from the downsampled audio -> mfccs/sample{1-31}.mfc
echo "* Creating MFCCs"
$HTK/HCopy -A -D -T 1 -C wav_config -S codetrain.scp

# Re-Align the data
# Watch for errors in this!!! -> adaptPhones.mlf
echo "* Re-Aligning data"
$HTK/HVite -A -D -T 1 -l '*' -o SWT -b SENT-END -C config -H macros -H hmmdefs -i adaptPhones.mlf -m -t 250.0 150.0 1000.0 -y lab -a -I adaptWords.mlf -S adapt.scp dict tiedlist

# Build regression class tree -> hmm16/{hmmdefs,macros}
echo "* Building regression class tree"
$HTK/HHEd -H macros -H hmmdefs -M hmm16 regtree.hed tiedlist

# Static adaptation time!
# 1. Global adaptation -> global.tmf
echo "* Performing static adaptation"
$HTK/HEAdapt -C config -g -S adapt.scp -I adaptPhones.mlf -H hmm16/macros -H hmm16/hmmdefs -K global.tmf -t 250.0 150.0 3000.0 tiedlist

# 2. Transform models -> hmmAdapt/{hmmdefs,macros}
echo "* Transforming models"
$HTK/HEAdapt -C config -S adapt.scp -I adaptPhones.mlf -H hmm16/macros -H hmm16/hmmdefs -J global.tmf -M hmmAdapt -t 250.0 150.0 3000.0  -j 0.9 -i 10 tiedlist

echo 
echo "*** Done. Models in hmmAdapt ***"
# The final hmms to be used are now in the hmmAdapt folder
# grammar files?

# Note: Use this to convert mffcs to txt format
# HList -e 200 -i 26 -o -h sample1.mfc > sample1-data.txt
