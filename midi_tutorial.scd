s.quit;
s.options.numOutputBusChannels_(2);
//s.options.inDevice_("Built-in Microph");
s.options.numInputBusChannels_(2);
s.options.sampleRate_(44100);
s.options.memSize_(2.pow(20));
s.newBusAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;
s.boot;
MIDIClient.init;
MIDIIn.connectAll;


~sampleBuf.free;
~sampleBuf = Buffer.read(s, "/Users/mciul/Music/samples/long_tall_sally_garbled_cassette_scream_loop.aiff")
~sampleBuf = Buffer.read(s, "/Users/mciul/Music/samples/long_tall_sally_garbled_cassette_last_note.aiff");

(
SynthDef(\strings, {
	arg freq=440, bend=0, amp=0.3, gate=0, out=0, mod=0;
	var sig, vibrato, depth, attack;
	attack = 0.02 / (amp);
	depth = (mod * 0.7) + 0.05;
	vibrato = {SinOsc.kr(LFNoise1.kr(2.3, 0.6, 6.94), 0, LFNoise1.kr(0.9, depth / 2, depth))}!10;
	sig = VarSaw.ar(freq * bend.midiratio * vibrato.midiratio, 0, 0.01, EnvGen.kr(Env.adsr(attack), gate, doneAction:2) * amp / 5);
	Out.ar(out, sig.sum);
}).add;

SynthDef(\pmstrings, {
	arg freq=440, bend=0, amp=0.3, gate=0, out=0, mod=0;
	var bowspeed, bowpressure, bow, string, highboost;
	var bent, level, sig;
	bowpressure = amp * gate.lag(amp.linlin(0,1,0.2,0.01));
	bowspeed = freq.cpsmidi.linexp(0,127,24,932);
	bowspeed = LFNoise1.ar(50, bowspeed * 0.3, bowspeed) * gate.lag(0.5 - bowpressure);
	bent = freq * bend.midiratio;
	level = amp * freq.cpsmidi.linexp(0,127,0.04,1.5);
	bow = VarSaw.ar(bowspeed, 0, amp.linexp(0,1,0.4,0.005), bowpressure * 0.4);
	bow = DynKlank.ar(`[[140, 400, freq], bowpressure * 0.4, [0.005, 0.005, 1/freq]], BrownNoise.ar(0.1));
	string = Pluck.ar(bow, Impulse.ar(freq), 0.2, bent.reciprocal, 1.5, 0.5, level);
	string = LPF.ar(HPF.ar(string, bent * 0.75), 10000);
	DetectSilence.ar(string, doneAction: 2);
	Out.ar(out, string);
}).add;

SynthDef(\pluck, {
	arg freq=440, bend=0, amp=0.3, gate=0, out=0, mod=0;
	var sig, in, decaytime, open, closed, coef, bent, midi;
	var pitch_classes, wrap_points, octaves, midis, sympathetic_periods;
	midi = freq.cpsmidi.round.lag(0.01);
	in = HPF.ar(BrownNoise.ar(), freq * 0.75, midi.linexp(0,127,0.15,0.95));
	decaytime = gate.max(gate.lag(0.1)).linlin(0,1, 40 / freq, 1200 / freq);
	open = (((60 - freq.cpsmidi) / 5).distort + 1) / 6;
	closed = 0.6;
	coef = gate.max(gate.lag(0.1)).linlin(0, 1, closed, open);
	bent = freq * bend.midiratio;
	sig = Pluck.ar(in, gate, 0.1, bent.reciprocal, decaytime, coef, amp);
	// sympathetic strings at octave, 5th, M3, octave, 7th - but wrapping at different points
	pitch_classes = [ 0, 7, 4, 12, 10 ];
	wrap_points = [ 0, 0, 0, 6, 1 ];
	octaves = [ 3, 3, 4, 4, 5 ];
	midis = ( midi + pitch_classes - wrap_points ).mod(12) + wrap_points + (octaves * 12);
	sympathetic_periods = (midis).midicps.reciprocal;
	sig = sig + LeakDC.ar(Pluck.ar(sig * 0.1, Impulse.ar(bent), sympathetic_periods, sympathetic_periods, 6, 0.6 - (mod * 0.5), 0.3)).sum;
	DetectSilence.ar(sig, doneAction: 2);
	Out.ar(out, sig);
}).add;

SynthDef(\piano, {
	arg freq=440, bend=0, amp=0.3, gate=0, out=0, mod=0;
	var freqs, harms, sig, vibrato, depth, attack;
	attack = 0.02 / (amp);
	harms = (4000 / freq).ceil();
	freqs = { ExpRand(freq * (-0.10).midiratio, freq * (0.10).midiratio) }!3;
	sig = Saw.ar(freqs * bend.midiratio, harms, EnvGen.kr(Env.adsr(0.01, 600/freq + 0.5, 0.01, 0.2, curve: -4), gate, doneAction:2) * amp / 1);
	sig = LPF.ar(sig, EnvGen.kr(Env.adsr(0.01, 4/freq.log2, 0.001, 0.1), gate, 3000 * amp + 1500, 700));
	Out.ar(out, sig.sum);
}).add;

SynthDef(\sampleplay, {
	arg freq=440, bend=0, amp=0.3, gate=0, out=0, mod=0, bufnum=0, loop=1;
	var sig;
	sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) / 440 * freq * bend.midiratio, loop: loop);
	Out.ar(out, sig * EnvGen.kr(Env.adsr(), gate, doneAction: 2) * amp);
}).add;

~notes=Array.newClear(128);
~mod = 0;
~bend = 0;

MIDIdef.noteOn(\noteOn, {
	arg val, num, chan, src;
	~notes[num].set(\piano, 0);
	~notes[num] = Synth.new(
		num.postln;
		\pluck,
		[
			\freq, num.midicps,
			\bend, ~bend,
			\amp, val.linexp(0,127,0.1,0.99),
			\gate, 1,
			\mod, ~mod,
			\bufnum, ~sampleBuf;
		]
	);
});

MIDIdef.noteOff(\noteOff, {
	arg val, num, chan, src;
	~notes[num].set(\gate, 0);
	~notes[num] = nil;
});

MIDIdef.bend(\bend, {
	arg val, chan, src;
	~bend = val.linlin(0,16383, -2, 2);
	~notes.do {
		arg synth;
		synth.set(\bend, ~bend);
	};
});

MIDIdef.cc(\modWheel, {
	arg val, num, chan, src;
	if (
		num == 1,
		{
			~mod = val.linlin(0,127,0,1);
			~notes.do {
				arg synth;
				synth.set(\mod, ~mod);
			};
		}
	);
});
)

x=Synth.new(\piano, [\gate: 1, \mod, 0, \bufnum: ~sampleBuf])
x.set(\mod, 1)
x.set(\gate, 0)

Synth.new(\test)