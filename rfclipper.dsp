declare name "RFClipper"; // No spaces for better JACK port names.
declare version "0.01";
declare author "jpka";
declare license "MIT";
declare description "See readme at github.com/twonoise/rfclipper";

import("stdfaust.lib");

/* Overamp gain becomes clipping dynamic range,
   but be aware of unfilterable harmonics increase. */
OVERAMP = hslider("Gain dB", 15, 0, 30, 1) : ba.db2linear;

/* Less bandwidth not just filters sound, but gives also
 * more space for harmonics removal, so more precise result. */
AUDIO_BW_HZ = hslider("BW Hz", 20000, 1000, 20000, 1000);

/* Increase filter order gives cleaner result,
 * but eats CPU and increases delay.
 * NOTE It is rarely possible to realtime filter order change,
 * not only with Faust, but other syntheziers like VHDL/Verilog. */
// This gives 'stack overflow in eval' at fi.bandpass build.
// FLT_ORD = hslider("FLT Ord", 33, 10, 33, 1);
FLT_ORD = 33;

/* Local oscillator, or Heterodyne. Fine-tune it for specific setup,
 * bitrate and audio BW for best sound & fewer artifacts. */
LO_HZ = hslider("LO Hz", 25000, 500, 47500, 1); // Min. Fs is 48k S/s

/* Imagine what happens then? */
OFS_HZ = hslider("OFS2 Hz", 0, -2000, 2000, 0.01);

/* This (voltage) gain factor can be fine-tuned if BPFs changed,
   it is to keep amplitude peaks close to 1.0 when OVERAMP = 1.
   NOTE This value is re:20 kHz audio BW. If your favorite BW
   is far away, it is better to re-evaluate it. */
G1 = 2;

clip(lo,hi) = min(hi) : max(lo);
sym_clip(thr) = clip(-thr,thr);

BPF_FROM = LO_HZ;
BPF_TO = BPF_FROM + AUDIO_BW_HZ;

/* For fine-tune it all. Note, you need hi-res spectrum analyzer for it.
 * If with oscope, just give like sum of 420 and 440 Hz. */
testsrc = no.noise * 0.1,
  os.osc(1000) * 0.316228, // -5 dBV
  os.osc(1800) * 0.316228,
  os.osc(17500) * 0.1, // -10 dBV
  os.osc(18500) * 0.1  :>  fi.lowpass(FLT_ORD, AUDIO_BW_HZ);

/* A bit weird look, but gives flat Faust diargam for book/paper.
 * Note six extra outputs coupled via '<:' for Spectrum Analyzer,
 * it's worth to connect hi-res SA to overdrive control. */
process =
  testsrc <:

/* Upconversion. */
/* We take unfiltered input. Should not have out-of-band stuff. */
  ( _ * (LO_HZ:os.osc) <:

/* Take one of two SSBs (single side bands). */
  ( fi.bandpass(FLT_ORD, BPF_FROM, BPF_TO) <:

/* Gain it to approx. unity amplitude, then well beyond it. */
  ( _ * G1 * OVERAMP <:

/* Hard limit overamped signal, note it gives a lot if harmonics,
 * some are aliased from Fs/2 and are falls back to our band again,
 * this can not be filtered or avoided in ways other than increase Fs. */
  ( (sym_clip(1.0)) <:

/* Filter our SSB again to get rid of as many harmonics as possible. */
  ( fi.bandpass(FLT_ORD, BPF_FROM + OFS_HZ, BPF_TO + OFS_HZ) <:

/* Downconversion. */
  ( _ * ((LO_HZ + OFS_HZ):os.osc) <:

/* Low pass filter is important to restore baseband waveform. */
/* Then pass it to 1st output port. */
  ( fi.lowpass(FLT_ORD, AUDIO_BW_HZ) : _

/* Extra testpoint outputs, in reversed order (see Faust diagram). */
  ),_ ),_ ),_ ),_ ),_ ),_ ),_ ;
