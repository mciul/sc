(
f = (76-36).midicps; // "fundamental" frequency - somewhat arbitrary, but this is the max at default control rate
~delayTimes = Dictionary.newFrom([\eighth, 1/8, \sixth, 1/6, \fifth, 1/5, \quarter, 1/4, \third, 1/3, \half, 1/2]);
~delayKeys = ~delayTimes.keys.asArray;

~out = 0;
~makeBusses = {
	~bus = Dictionary.new;
	~bus.add(\feedback -> Bus.audio(s, ~delayKeys.size));
	~bus.add(\res -> Bus.audio(s,~delayKeys.size));
};

~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

~makeNodes = {
	s.bind({
		~group = Dictionary.new;
		~group.add(\res -> Group.new);
		~group.add(\feedback -> Group.before(~group[\res]));
		~group.add(\mixOut -> Group.after(~group[\res]));
		~feedbackSynths = ~delayKeys.collect({
			arg key, i;
			Synth.new(\distortedResonator,
				[
					\in, ~bus[\res].index + i,
					\out, ~bus[\feedback].index + i,
					\delaytime, ~delayTimes[\key]
				],
				~group[\res]
			);
		});
		~outSynth = Synth.new(\mixOut, [\out, ~out, \in, ~bus[\feedback].index], ~group[\mixOut]);
		~noiseSynth = Synth.new(\noiseFloor, [\out, ~bus[\res].index], ~group[\feedback]);
	});
};

~openGates = {
	arg midi, velocity;
	// TODO
};

~closeGates = {
	arg midi;
	// TODO
};

~controlGates = {
	arg key, val;
	// TODO
};

~mapKeyboard = {
	MIDIIn.connectAll;

	MIDIdef.noteOn(\noteOn, {
		arg val, num, chan, src;
		~closeGates.value(num);
		~openGates.value(num, val);
	});

	MIDIdef.noteOff(\noteOff, {
		arg val, num, chan, src;
		~closeGates.value(num);
	});

	MIDIdef.bend(\bend, {
		arg val, chan, src;
		~bend = val.linlin(0,16383, -2, 2);
		~controlGates.value(\bend, ~bend);
	});

	MIDIdef.cc(\modWheel, {
		arg val, num, chan, src;
		if (
			num == 1,
			{
				~mod = val.linlin(0,127,0,1);
				~controlGates.value(\mod, ~mod);
			}
		);
	});
};
)

// together - not working

(
ServerBoot.add(~makeBusses);
ServerQuit.add(~cleanup);
"not waiting".postln;
s.waitForBoot({
	"waitForBoot".postln;
	s.sync;

	//synthdefs
	SynthDef(\distortedResonator, {
		arg in=0, out=0, maxdelaytime=0.2, latency=ControlRate.ir.reciprocal, delaytime=440.reciprocal, gain=1, amp=1;
		var sig;
		sig = In.ar(in).madd(gain).softclip;
		sig = DelayL.ar(sig, maxdelaytime, delaytime.reciprocal - latency, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef(\feedbackGate, {
		arg in=0, out=0, amp=0.3, gate=0;
		var sig;
		sig = InFeedback.ar(in) * EnvGen.ar(Env.adsr(sustainLevel:1, releaseTime:0.2), gate, amp, doneAction:2);
		Out.ar(out, sig);
	}).add;

	SynthDef(\noiseFloor, {
		arg out=0, amp=0.001;
		Out.ar(out, BrownNoise.ar(amp!~delayKeys.size));
	}).add;

	SynthDef(\mixOut, {
		arg in, out;
		Out.ar(out, Splay.ar(In.ar(in, ~delayKeys.size)));
	}).add;

	// remaining functions
	ServerTree.add(~makeNodes);
	ServerTree.add(~mapKeyboard);
	s.freeAll;

	s.sync;

	"done".postln;
});
)

~bus
~group
~noiseSynth.set(\amp, 0.3);
~feedbackSynths[1].free;
(
SynthDef(\test, {
	arg in, out;
	Out.ar(out, In.ar(in, 2).neg);
}).add;
)
y={Out.ar(~bus[\feedback].index+5, SinOsc.ar(mul:0.1))}.play;
y.free;
~outSynth.free
~outSynth.set(\out, 1);
~outSynth = Synth(\mixOut, [\out, ~out, \in, ~bus[\res].index], ~group[\mixOut]);
~outSynth = Synth(\test, [\out, ~out, \in, ~bus[\feedback].index], ~group[\mixOut]);
x= Synth.new(\noiseFloor, [\out, 0, \amp, 0.1]);
x.free;
x= Synth.new(\distortedResonator,
				[
					\in, ~bus[\res].index + 0,
					\out, ~bus[\feedback].index + 0,
					\delaytime, ~delayTimes[\eighth]
				],
				~feedbackGrp
			);
// separately

s.quit
ServerBoot.add(~makeBusses);
ServerQuit.add(~cleanup);
s.boot

(
	SynthDef(\distortedResonator, {
		arg in=0, out=0, maxdelaytime=0.2, latency=ControlRate.ir.reciprocal, delaytime=440.reciprocal, gain=1, amp=1;
		var sig;
		sig = In.ar(in).madd(gain).softclip;
		sig = DelayL.ar(sig, maxdelaytime, delaytime.reciprocal - latency, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef(\feedbackGate, {
		arg in=0, out=0, amp=0.3, gate=0;
		var sig;
		sig = InFeedback.ar(in) * EnvGen.ar(Env.adsr(sustainLevel:1, releaseTime:0.2), gate, amp, doneAction:2);
		Out.ar(out, sig);
	}).add;

	SynthDef(\noiseFloor, {
		arg out=0, amp=0.001;
		Out.ar(out, BrownNoise.ar(amp!~delayKeys.size));
	}).add;

	SynthDef(\mixOut, {
		arg in, out;
		Out.ar(out, Splay.ar(In.ar(in, ~delayKeys.size)));
	}).add;
)
ServerTree.add(~makeNodes);
ServerTree.add(~mapKeyboard);
s.freeAll;


/*
(44100/64).cpsmidi ~= 76.77

[(1/4), (1/8)] -> 3/8
[(1/4), (1/6)] -> 5/12
[(1/4), (1/5)] -> 9/20
[(1/3), (1/6)] -> 1/2
[(1/3), (1/5)] -> 8/15
[(1/3), (1/6), (1/8)] -> 5/8
[(1/2), (1/8)] -> 5/8
[(1/2), (1/6)] -> 2/3
[(1/2), (1/4)] -> 3/4
[(1/3), (1/4), (1/6)] -> 3/4
[(1/2), (1/3)] -> 5/6
[(1/2), (1/3), (1/6)] -> 1/1
[(1/2), (1/3), (1/6), (1/8)] -> 9/8
[(1/2), (1/3), (1/5), (1/6)] -> 6/5
[(1/2), (1/3), (1/4), (1/6)] -> 5/4

longer version:
(1/8).reciprocal.ratiomidi // = +36 semitones
(1/6).reciprocal.ratiomidi // = +31.019550008654 semitones
(1/4).reciprocal.ratiomidi // = +24 semitones
(7/24).reciprocal.ratiomidi.mod(12) // 1/6 + 1/8 = + (21.331290943962625) semitones
(13/40).reciprocal.ratiomidi.mod(12) // 1/5 + 1/8 = + (19.457860520955244) semitones
(1/3).reciprocal.ratiomidi // = +19.019550008654 semitones
(11/30).reciprocal.ratiomidi.mod(12) // 1/5 + 1/6 = + (17.36950772365466) semitones
(3/8).reciprocal.ratiomidi.mod(12) // 1/4 + 1/8 = + (16.980449991346124) semitones
(5/12).reciprocal.ratiomidi.mod(12) // 1/4 + 1/6 = + (15.156412870005525) semitones
(9/20).reciprocal.ratiomidi.mod(12) // 1/4 + 1/5 = + (13.8240371213406) semitones
(11/24).reciprocal.ratiomidi.mod(12) // 1/3 + 1/8 = + (13.50637058500631) semitones
(1/2).reciprocal.ratiomidi.mod(12) // 1/2 = + (12.0) semitones
(8/15).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 = + (10.88268714730222) semitones
(13/24).reciprocal.ratiomidi.mod(12) // 1/4 + 1/6 + 1/8 = + (10.614273390960768) semitones
(7/12).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 = + (9.331290943962623) semitones
(5/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/8 = + (8.136862861351654) semitones
(2/3).reciprocal.ratiomidi.mod(12) // 1/2 + 1/6 = + (7.019550008653875) semitones
(7/10).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 + 1/6 = + (6.174878073957099) semitones
(7/10).reciprocal.ratiomidi.mod(12) // 1/2 + 1/5 = + (6.174878073957099) semitones
(3/4).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 = + (4.980449991346124) semitones
(19/24).reciprocal.ratiomidi.mod(12) // 1/2 + 1/6 + 1/8 = + (4.04441984733085) semitones
(5/6).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 = + (3.1564128700055254) semitones
(7/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/8 = + (2.31174093530875) semitones
(19/20).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/5 = + (0.8880069773253213) semitones
(1/1).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/6 = + (0.0) semitones
(13/12).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 = + (-1.3857266090392308) semitones
(9/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/6 + 1/8 = + (-2.0391000173077494) semitones
(6/5).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 + 1/6 = + (-3.1564128700055254) semitones
(5/4).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/6 = + (-3.8631371386483475) semitones
(53/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 + 1/6 + 1/8 = + (-4.871908316110041) semitones
(11/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/6 + 1/8 = + (-5.513179423647567) semitones
(29/20).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 + 1/6 = + (-6.432634802882516) semitones
(63/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 + 1/6 + 1/8 = + (-7.8642219433506515) semitones

full version:
(7/24).reciprocal.ratiomidi.mod(12) // 1/6 + 1/8 = + (21.331290943962625) semitones
(13/40).reciprocal.ratiomidi.mod(12) // 1/5 + 1/8 = + (19.457860520955244) semitones
(11/30).reciprocal.ratiomidi.mod(12) // 1/5 + 1/6 = + (17.36950772365466) semitones
(3/8).reciprocal.ratiomidi.mod(12) // 1/4 + 1/8 = + (16.980449991346124) semitones
(5/12).reciprocal.ratiomidi.mod(12) // 1/4 + 1/6 = + (15.156412870005525) semitones
(9/20).reciprocal.ratiomidi.mod(12) // 1/4 + 1/5 = + (13.8240371213406) semitones
(11/24).reciprocal.ratiomidi.mod(12) // 1/3 + 1/8 = + (13.50637058500631) semitones
(59/120).reciprocal.ratiomidi.mod(12) // 1/5 + 1/6 + 1/8 = + (12.29097055496013) semitones
(1/2).reciprocal.ratiomidi.mod(12) // 1/3 + 1/6 = + (12.0) semitones
(8/15).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 = + (10.88268714730222) semitones
(13/24).reciprocal.ratiomidi.mod(12) // 1/4 + 1/6 + 1/8 = + (10.614273390960768) semitones
(23/40).reciprocal.ratiomidi.mod(12) // 1/4 + 1/5 + 1/8 = + (9.580393665964195) semitones
(7/12).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 = + (9.331290943962623) semitones
(37/60).reciprocal.ratiomidi.mod(12) // 1/4 + 1/5 + 1/6 = + (8.369246759754825) semitones
(5/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/8 = + (8.136862861351654) semitones
(5/8).reciprocal.ratiomidi.mod(12) // 1/3 + 1/6 + 1/8 = + (8.136862861351654) semitones
(79/120).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 + 1/8 = + (7.237318169176989) semitones
(2/3).reciprocal.ratiomidi.mod(12) // 1/2 + 1/6 = + (7.019550008653875) semitones
(7/10).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 + 1/6 = + (6.174878073957099) semitones
(7/10).reciprocal.ratiomidi.mod(12) // 1/2 + 1/5 = + (6.174878073957099) semitones
(17/24).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/8 = + (5.969995913649799) semitones
(89/120).reciprocal.ratiomidi.mod(12) // 1/4 + 1/5 + 1/6 + 1/8 = + (5.173885975705449) semitones
(3/4).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/6 = + (4.980449991346124) semitones
(3/4).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 = + (4.980449991346124) semitones
(47/60).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/5 = + (4.227620927170575) semitones
(19/24).reciprocal.ratiomidi.mod(12) // 1/2 + 1/6 + 1/8 = + (4.04441984733085) semitones
(33/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/5 + 1/8 = + (3.3304077063469073) semitones
(33/40).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 + 1/6 + 1/8 = + (3.3304077063469073) semitones
(5/6).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 = + (3.1564128700055254) semitones
(13/15).reciprocal.ratiomidi.mod(12) // 1/2 + 1/5 + 1/6 = + (2.4774105296091147) semitones
(7/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/8 = + (2.31174093530875) semitones
(7/8).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/6 + 1/8 = + (2.31174093530875) semitones
(109/120).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/5 + 1/8 = + (1.6644752499791071) semitones
(11/12).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/6 = + (1.5063705850063096) semitones
(19/20).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/5 = + (0.8880069773253213) semitones
(19/20).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/5 + 1/6 = + (0.8880069773253213) semitones
(23/24).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/8 = + (0.7368065359697193) semitones
(119/120).reciprocal.ratiomidi.mod(12) // 1/2 + 1/5 + 1/6 + 1/8 = + (0.14487398760689965) semitones
(1/1).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/6 = + (0.0) semitones
(31/30).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 = + (-0.5676685773402816) semitones
(25/24).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/6 + 1/8 = + (-0.7067242686428228) semitones
(43/40).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/5 + 1/6 + 1/8 = + (-1.2520399177768273) semitones
(43/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/5 + 1/8 = + (-1.2520399177768273) semitones
(13/12).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 = + (-1.3857266090392308) semitones
(67/60).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/5 + 1/6 = + (-1.9103831381910463) semitones
(9/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/6 + 1/8 = + (-2.0391000173077494) semitones
(139/120).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 + 1/8 = + (-2.544605725379868) semitones
(6/5).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 + 1/6 = + (-3.1564128700055254) semitones
(29/24).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/8 = + (-3.2762219328769895) semitones
(149/120).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/5 + 1/6 + 1/8 = + (-3.7473350982437177) semitones
(5/4).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/6 = + (-3.8631371386483475) semitones
(77/60).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 = + (-4.318751341036596) semitones
(53/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 + 1/6 + 1/8 = + (-4.871908316110041) semitones
(11/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/6 + 1/8 = + (-5.513179423647567) semitones
(169/120).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 + 1/8 = + (-5.9278660880839915) semitones
(29/20).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 + 1/6 = + (-6.432634802882516) semitones
(63/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 + 1/6 + 1/8 = + (-7.8642219433506515) semitones
*/
(20/9).ratiomidi.mod(12)
