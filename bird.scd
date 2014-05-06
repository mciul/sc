

s.options.memSize=1048576;
s.options.numWireBufs=128;
s.quit;
s.boot;

b.free;
b = Buffer.read(s, "/Users/mciul/Music/samples/Birdsong-Dunnock.aiff");
b = Buffer.read(s, "/Users/mciul/Music/samples/upenn_birdsong_20140505.aiff");
b = Buffer.read(s, "/Users/mciul/Music/samples/langelliott_blue_jay.aiff");
b = Buffer.read(s, "/Users/mciul/Music/samples/langelliott_wood_thrush.aiff");

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
		arg buffer=b, gate=1, start=0, dur=1, pitch=1, tempo=1, grainSize=0.17, overlap=7.58;
		var end = start+dur;
		var triggerRate = overlap/grainSize;
		var triggerDrift = 1/grainSize;
		var trigger = Impulse.kr(LFNoise0.kr(triggerRate+triggerDrift, triggerDrift, triggerRate), mul:gate);
		var rate = tempo*BufRateScale.kr(buffer.bufnum)/buffer.numFrames;
		var pos = Phasor.ar(gate, rate, start, end, start);
		GrainBuf.ar(2, trigger, grainSize, buffer, pitch, pos, 2);
	},
	#[
		\buffer,
		[0,1,\lin,1],
		[0,1],
		[0.0001,1,\exp],  // allow negative dur?
		[0,2],
		[-1,2],
		[0.01, 0.2, \exp],
		[6,8],
	];
);
)

play({Instr.ar("sampleWalk",[Dust.kr(7), LFNoise1.kr(2,1,1)])});

play({Instr.ar("sampleGrain", [0, MouseX.kr(0,1), MouseY.kr(0,1), 1, 1])});
play({Instr.ar("sampleGrain", [b, 1, LFNoise1.kr(0.7,0.5,0.5), LinExp.kr(LFNoise1.kr(0.14),-1,1,0.001,1), LFNoise0.kr(0.03,0.7,0.7), LFNoise1.kr(0.1,0.3,0.3)])});

Instr("sampleGrain").gui
play({GrainBuf.ar(2, Impulse.kr(10), 0.1, b, 1, Phasor.ar(0,0.1/SampleRate.ir, 0, 1))});