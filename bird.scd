

s.options.memSize=1048576;
s.options.numWireBufs=128;
s.quit;
s.boot;

b.free;
b = Buffer.read(s, "/Users/mciul/Music/samples/Birdsong-Dunnock.aiff");
b = Buffer.read(s, "/Users/mciul/Music/samples/upenn_birdsong_20140505.aiff");
b = Buffer.read(s, "/Users/mciul/Music/samples/langelliott_blue_jay.aiff");

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
		arg reset, start=0, end=1, pitch=1, tempo=1, grainSize=0.05, overlap=3;
		var triggerRate = overlap/grainSize;
		var trigger = Impulse.kr(LFNoise0.kr(triggerRate, triggerRate/overlap, triggerRate));
		var rate = tempo*BufRateScale.kr(b.bufnum)/b.numFrames;
		var pos = Phasor.ar(reset, rate, start, end, start);
		GrainBuf.ar(2, trigger, grainSize, b, pitch, pos, 2);
	},
	#[
		\audio,
		[0,1],
		[0,1],
		[0,2],
		[-1,2],
		[0.001, 0.1, \exp],
		[1,8],
	];
);
)

play({Instr.ar("sampleWalk",[Dust.kr(7), LFNoise1.kr(2,1,1)])});

play({Instr.ar("sampleGrain", [0, MouseX.kr(0,1), MouseY.kr(0,1), 1, 1])});
play({Instr.ar("sampleGrain", [0, LFNoise1.kr(3,0.5,0.5), LFNoise1.kr(5,0.5,0.5), LFNoise0.kr(0.3,0.7), LFNoise1.kr(1,0.3,0.3)])});

Instr("sampleGrain").gui
play({GrainBuf.ar(2, Impulse.kr(10), 0.1, b, 1, Phasor.ar(0,0.1/SampleRate.ir, 0, 1))});