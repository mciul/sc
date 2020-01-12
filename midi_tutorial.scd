s.boot;
MIDIClient.init;
MIDIIn.connectAll;

(
SynthDef(\test, {
	arg freq=440, amp=0.3, gate=0, out=0, mod=0;
	var sig, vibrato, depth, attack;
	attack = 0.02 / (amp);
	depth = (mod * 0.7) + 0.05;
	mod.poll(1);
	vibrato = {SinOsc.kr(LFNoise1.kr(2.3, 0.6, 6.94), 0, LFNoise1.kr(0.9, depth / 2, depth))}!10;
	sig = VarSaw.ar(freq * vibrato.midiratio, 0, 0.01, EnvGen.kr(Env.adsr(attack), gate, doneAction:2) * amp / 5);
	Out.ar(out, sig.sum);
}).add;

~notes=Array.newClear(128);
~mod = 0;

MIDIdef.noteOn(\noteOn, {
	arg val, num, chan, src;
	~notes[num] = Synth.new(
		\test,
		[
			\freq, num.midicps,
			\amp, val.linexp(0,127,0.05,0.3),
			\gate, 1,
			\mod, ~mod;
		]
	);
});

MIDIdef.noteOff(\noteOff, {
	arg val, num, chan, src;
	~notes[num].set(\gate, 0);
	~notes[num] = nil;
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

x=Synth.new(\test, [\gate: 1, \mod, 0])
x.set(\mod, 1)
x.set(\gate, 0)

Synth.new(\test)