# rfclipper.dsp
Radio frequency voice clipper demo with Faust, lv2, and JACK

DESCRIPTION
-----------
_We assume that readers are well familiar with IF-LO-RF mixers and SSB approach._

Original idea by Joachim Münch (**df4zs**) shown here:<br>
https://www.qsl.net/df4zs/oszi.html<br>
https://www.qsl.net/df4zs/index2.htm<br>
and consist of heterodyne-based transmitter and receiver, and (hard) limiter between them.

The magic of this, at the point of view of modern DSP world, is that it makes _soft_ clipping while not have any _soft_ function. (It is more like compressor or normalize, but non-integrating, with momentary, per sample operation). If input is one tone, output will be one unity amplitude tone, without distortions using mentioned analog circuitry, and _almost_ without distortions using limited DSP math.

Hard limiter generates a lot of out-of-band harmonics, but they can be easily filtered out due to carrier frequency is much larger than baseband bandwidth.

Here is the difference between analog and sampled system. Analog harmonics can be eliminated completely. This is impossible with DSP-based design, because it have well limited BW and it is **Fs/2**. All harmonics which _can not be represented with current Fs_, are aliased and can fall back to **RF** band, which makes result not exactly precise. In other words, harmonic
can be filtered out only if they can be correctly represented first. See _Figure 2_ here https://www.soundonsound.com/sound-advice/q-what-aliasing-and-what-causes-it

Increasing **Fs** directly helps, and also reduces latency and baseband artifacts, but increases CPU usage. But exactly precision result, unlike of analog circuit, impossible anyway, due to it requires very high Fs.

Note, we talk here about virtual (processing) **Fs**, not related to real DAC/ADC Fs. It is fine if JACK **Fs** is 384 kS/s while only 48 kHz allowed for i/o (h/w audio codec).

The more **frequency "space"** for harmonics (this is Fs/2 minus baseband audio BW), the more precise result (so, less audio BW, better result). Less overdrive/dynamic is also directly related to precision. 

It can be noted that using soft limiter, instead of our hard one, not helps, but just eats CPU; but still need more tests. *TODO*

Here is not classic SSB processing used, but simpler substitution like on https://i.sstatic.net/65PtJ99B.png , it's mostly re-create of 2nd Nyquist alias. The difference is exactly zero gap between lower and upper sidebands at **RF**, it can lead to reduce of some very low frequencies, because one SSB should be filtered out with very sharp,
but still not ideal band pass filter.

Do not expect spectrally pure result for something more complex input than just one tone. Even when exactly precise, clipper is non-linearity by its definition. In-band IMD3 products are should be there... and they are.

One may note that our receive heterodyne can be easily detuned (shifted) from transmit one. We welcome our reader to imagine what happens then, then test with real realtime setup.

It can also be noted that same or better result should be possible using regular baseband DSP techniques, while one needs to be quite experienced with math, to rethink it all in baseband way. So, currently, it is demo mostly, due to it requires special mode of JACK engine, which is not supported by `qjackctl`, but only manually invoked.

BUILD
-----
* `faust2lv2 rfclipper.dsp`
* Place the newly created `rfclipper.lv2` folder contains plugin suite, to /usr/lib/lv2/ or similar place which your plugin host knows.
  
USAGE
-----
The realtime sound processing plugin we create, is intended to be used with so called _plugin hosts_ with **lv2** and **JACK** support, like **Ardour** (which is way more than just host, and you may find it quite useful). I've tested it with **Carla** plugin host. Please refer to its manuals how to add plugin and connect its input and output ports.

Please check [here](https://github.com/twonoise/jasmine-sa/?tab=readme-ov-file#above-192-kss) how to run JACK for higher Fs.








