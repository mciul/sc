s.boot;
MIDIClient.init;
MIDIIn.connectAll;

~sampleBuf.free;
~sampleBuf = Buffer.read(s, "/Users/mciul/Music/samples/long_tall_sally_garbled_cassette_scream_loop.aiff")
~sampleBuf = Buffer.read(s, "/Users/mciul/Music/samples/long_tall_sally_garbled_cassette_last_note.aiff");

Env.adsr(0.01, 6, 0.01, 0.2, curve: \exponential).plot
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

SynthDef(\piano, {
	arg freq=440, bend=0, amp=0.3, gate=0, out=0, mod=0;
	var freqs, harms, sig, vibrato, depth, attack;
	attack = 0.02 / (amp);
	harms = (4000 / freq).ceil();
	freqs = { ExpRand(freq * (-0.10).midiratio, freq * (0.10).midiratio) }!3;
	sig = Blip.ar(freqs * bend.midiratio, harms, EnvGen.kr(Env.adsr(0.01, 6, 0.1, 0.2, curve: -4), gate, doneAction:2) * amp / 1);
	sig = LPF.ar(sig, EnvGen.kr(Env.adsr(0.01, 4/freq.log2, 0.001, 0.1), gate, 3000 * amp + 1500, 400));
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
	~notes[num].set(\gate, 0);
	~notes[num] = Synth.new(
		\piano,
		[
			\freq, num.midicps,
			\bend, ~bend,
			\amp, val.linexp(0,127,0.05,0.3),
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
			~mod.postln;
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