s.options.memSize=1048576;
//explore the effect
(
Instr("scrm", {
	arg wipe=0, width=0.2;
    var in, chain, out;
	in = SoundIn.ar([0,1]) + LocalIn.ar(2);
	chain = in.collect({ |chan| FFT(LocalBuf(1024), chan) });
    chain=PV_BinScramble(chain, wipe, width, MouseY.kr>0.99);
	out = IFFT(chain);
	LocalOut.ar(out.softclip);
    out * 0.5;
},
#[
		[0, 1],
		[0, 1]
]);
)

Instr("scrm").gui;

(
//trig with MouseY
SynthDef("help-binScramble", { arg out=0, soundBufnum=2;
    var in, chain;
    in = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
    chain = FFT(LocalBuf(2048), in);
    chain = PV_BinScramble(chain, MouseX.kr , 0.1, MouseY.kr > 0.5 );
    Out.ar(out, 0.1 * IFFT(chain).dup);
}).play(s, [\soundBufnum, b]);
)

1.0/[[1,2,3], [4,5,6]].flop.clump(2).flop.flatten.size

s.boot;
c.free;
c = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");

(
Instr(\fft_mandelbrot, { arg unit_midi=90, shift_60ths= -92, delay=0.3, gain=2;
	var unit_freq=unit_midi.midicps;
	var shift_factor= shift_60ths/60;
	var in, numFrames=512, chain;
	var sweet_spot = 1/2;
	var sweet_freq = (22050*sweet_spot);
	var unit_to_sweet = (sweet_freq/unit_freq);
	var stretch = unit_to_sweet.sqrt;
	var shift = (shift_factor * unit_freq);
	var out;
	var high_cutoff =
	in = LocalIn.ar(1) * gain;
	chain = FFT(LocalBuf(numFrames), in);
	chain = PV_MagShift(chain, stretch);
	chain = chain.pvcalc(numFrames, {|mags, phases|
		[mags.collect({ |mag, i| mags.at(((i * mags.size * sweet_spot).sqrt).round)}), phases];
	});
	out = IFFT(chain) * Linen.kr; //envelope prevents a pop
	out = FreqShift.ar(out, shift);
	LocalOut.ar(DelayN.ar(Limiter.ar(out.madd(1, SoundIn.ar(0)), 1), 1, delay));
	Pan2.ar(out.softclip, 0);
}, #[
		\midi,
		[-121, 16, \lin, 1],
		[0,1,\lin,0],
		[0,4,\lin,0]
	]).gui;
)
s.scope
s = Server.default

x = {FreqShift.ar(SinOsc.ar(15000), MouseX.kr(-10000, 10000))}.scope;
x.free;

42.midicps
Function
"sweet bin ratio: ".post; w=1/16
"unit freq: ".post; u=1500        //unit freq
"sweet freq: ".post; f=(22050*w)  //sweet freq
"unit_to_sweet: "; r=f/u         //unit_to_sweet
"stretch: ".post; s=r.sqrt    //stretch
b=(u*s/22050*257) // stretched bin
q={|in, unit| in**2 / unit}  //scaled_square
t=q.value(b, 257*w)  // target bin
t * 22050/257 // target frequency
"max stretched bin: ".post; (256 * 257 * w).sqrt

q.value(u/r.sqrt)
r.sqrt
r
1000 * ((1/16)*22050/1000)
(16 * 256 * (1/16)).sqrt

1378.125/22050*256

256 * 16
(256

{Integrator.ar(Impulse.ar(0)).lag(0.001)}.plot
m = Array.fill(512, {|i| i});
512.collect({ |i| "frame map: ".post; m.at(((i * 512).sqrt).round.postln)}).at(136)

b=Buffer.alloc(s, 512)
f=FFT(Buffer)
f.pvcalc(512, {|mags, phases| mags.size.postln;});
264 ** 2 / 512

(1100* (22050/1000).sqrt - (0.1*(22050 * 1000).sqrt)) ** 2

((1000 * (22050/1000).sqrt)/22050) ** 2 * 22050
22050/1000.sqrt
(unit_freq * stretch)^2 = unit_freq

22000/256
x.free; c.free;
0.2!8
(
Instr(\softgate, {
	arg in, gain=200, thresh=0.5;
	(in - thresh).madd(gain).distort.madd(0.5, 0.5);
});

Instr(\mandelshift, {
	arg unit_freq=2300, c= -1.04, delay=0.08, damping=0.1;
	var numFrames=64;

	// iterate using delays
	var in = LocalIn.ar(1);

	// create frequency bins as if we were using an FFT
	// using an n^2 distribution to cover a larger range with fewer bins
	var bin_ratio = (numFrames + 1) * (numFrames + 1);
	var freq_bounds = (numFrames + 1).collect({ |i| i * i * 22050 / bin_ratio }).postln;
	var center_freq = numFrames.collect({ |i| (freq_bounds.at(i) + freq_bounds.at(i+1)) / 2 }).postln;
	var band_rq = center_freq.collect({ |freq, i| (freq_bounds.at(i+1) - freq_bounds.at(i)) * 1.75 / freq });
	var max_freq = center_freq.at(numFrames-1);
	var bands = BPF.ar(in, center_freq, band_rq);

	// use Amplitude and ZeroCrossing to get magnitude and frequency
	// for each band
	var mags = Amplitude.kr(bands);
	var freqs = ZeroCrossing.ar(bands).postln;

	// perform the Mandelbrot iteration on the frequencies
	var out, mag_gate;
	var units = freqs / unit_freq;
	freqs = units.madd(units, c).abs * unit_freq;

	// "filter" anything that goes over the Nyquist rate
	mag_gate = Instr(\softgate).kr(A2K.kr(freqs) * -1, 200, -1*max_freq);

	// fake IFFT
	out = DynKlang.ar(`[freqs, (mags * mag_gate), nil]).postln;

	// send the iteration into the delay
	LocalOut.ar(DelayN.ar(Limiter.ar(out.madd(1.1-damping, SoundIn.ar(0)), 1), 1, delay));
	Pan2.ar(out.softclip, 0);
	},
#[
		\freq,
		[-2.1, 0.3, \lin, 0],
		[0.001, 1, \exp, 0],
		[0.001, 1.1, \exp, 0]
]).gui;
)
)

s.scope

[ [ a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossing, a ZeroCrossi...etc...
