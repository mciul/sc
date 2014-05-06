

s = Server.internal;
s.options.memSize=1048576;
s.options.numWireBufs=128;
s.quit;
Server.default = s.boot;

b = Buffer.read(s, "/Users/mciul/Music/samples/Birdsong-Dunnock.aiff");
b = Buffer.read(s, "/Users/mciul/Music/samples/upenn_birdsong_20140505.aiff");
b.bufnum
(
Instr(\sampleWalk,
	{
		arg trigger, rate=0;

		var playRate=Latch.kr(rate, trigger);

		var dir = ToggleFF.kr(trigger) * 2 - 1;

		PlayBuf.ar(1,b.bufnum, dir * playRate * BufRateScale.kr(b.bufnum), loop: 1)
	},
	#[
		\nil,
		[-2,2,\lin,0.0001]
	];
);
)

(
Instr(\sampleGrain,
	{
		arg reset, start=0, end=1, pitch=1, tempo=1;

		var trigger = Impulse.kr(LFNoise0.kr(40, 10, 40));
		// TODO: better formula for tempo, so 1 actually=normal rate
		var pos = Phasor.ar(reset, tempo/SampleRate.ir, start, end, start);
		GrainBuf.ar(2, trigger, 0.05, b, pitch, pos, 2);
	},
	#[
	];
);
)

play({Instr.ar("sampleWalk",[Dust.kr(7), LFNoise1.kr(2,1,1)])});

play({Instr.ar("sampleGrain", [Dust.kr(7), LFNoise1.kr(0.2, 0.5, 0.5), LFNoise1.kr(0.3, 0.5, 0.5), LFNoise1.kr(0.3, 0.7, 0.7), LFNoise1.kr(0.4, 0.2, 0.2)])});
play({Instr.ar("sampleGrain", [0, LFNoise1.kr(3,0.5,0.5), LFNoise1.kr(5,0.5,0.5), LFNoise0.kr(0.3,0.7), LFNoise1.kr(1,0.3,0.3)])});

play({GrainBuf.ar(2, Impulse.kr(10), 0.1, b, 1, Phasor.ar(0,0.1/SampleRate.ir, 0, 1))});