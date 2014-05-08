

s.options.memSize=1048576;
s.options.numWireBufs=128;
s.quit;
s.boot;

b.free;
b = Buffer.read(s, "/Users/mciul/Music/samples/Birdsong-Dunnock.aiff");
b = Buffer.read(s, "/Users/mciul/Music/samples/upenn_birdsong_20140505.aiff");
c = Buffer.read(s, "/Users/mciul/Music/samples/langelliott_blue_jay.aiff");
b = Buffer.read(s, "/Users/mciul/Music/samples/langelliott_wood_thrush.aiff");

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

Instr(\sampleGrain,
	{
		arg buffer=b, gate=1, start=0, dur=1, pitch=1, tempo=1, grainSize=0.17, overlap=7.58;
		var end = start+((dur*tempo)/BufDur.kr(buffer));
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
		[0.0001,1,\exp],
		[0,2],
		[-1,2],
		[0.01, 0.2, \exp],
		[6,8],
	];
);

// TODO: change upSlew and downSlew to upRate and downRate
Instr(\stereoBeatZip, {
	arg in, tempo=1, upSlew=0.5, downSlew=0.5, directRegen=1, crossRegen=0.5, maxDelay=8, minDelay=0.1;
	var fbNode, feedback, fft, detected, times, slewed, out;
	fbNode = FbNode(2, minDelay, 4);
	feedback = LeakDC.ar(fbNode.delay(0.1));
	detected = max(tempo, maxDelay.reciprocal).reciprocal;
	times = [detected, LastValue.kr(detected)] - minDelay;
	slewed = Slew.kr(times, upSlew, downSlew);
	out = DelayC.ar(feedback, maxDelay-minDelay, slewed);
	fbNode.write(Limiter.ar(in + (directRegen*out) + (crossRegen*out.rotate(1)), dur:minDelay));
	out;
});
)

(

// a fun experiment, but let's use BeatTrack instead
Instr(\guessBeat, { arg in;
	var maxTime=8, minTime=0.1;
	var delayed = in;
	var chosenTime = maxTime;
	var delayTime = maxTime;
	while( {delayTime > minTime}, {
		var choice, choices, diffs, mean, delays, lags;
		delayTime = delayTime / 2;
		choices = chosenTime - [0, delayTime];
		delays = DelayN.kr(delayed, [choices], [choices]);
		diffs = delays.lag(choices/2) - in.lag(choices/2);
		mean = Decay.kr(diffs.squared, choices);
		choice = diffs[1] < diffs[0];
		delayed = Select.kr(choice, delays);
		chosenTime = Select.kr(choice, choices);
	});
	Poll(Impulse.kr(2), chosenTime, "chosenTime");
	chosenTime;
});

)

w.free
w = Buffer.alloc(s,1024,1);

play({Instr(\stereoBeatZip).ar(w, SoundIn.ar())})

(play{
	var fft, trackb, trackh, trackq, tempo;
	var bird, beat;
	var monitor,out;
	var mintempo;
	var in = SoundIn.ar();
	var buffer=c;
	var freq, hasFreq;
	monitor = FbNode(2);
	#freq, hasFreq = Pitch.kr(monitor);
	fft = FFT(w, in+monitor.delay.sum);
	// use SpecFlatness? SpecPcile? SpecCentroid?
	#trackb, trackh, trackq, tempo = BeatTrack.kr(fft, 0);
	mintempo=BufDur.kr(buffer).reciprocal;
	bird = Instr("sampleGrain").ar(buffer, 1,
		Phasor.kr(0, tempo*ControlDur.ir/32), // start
		max(mintempo,tempo*4).reciprocal, // dur
		freq[0]/440, // pitch
		freq[1]/440  // tempo
	);
	beat = Instr(\stereoBeatZip).ar(in+bird,
		tempo/4, // tempo
		0.5, // upSlew
		0.5, // downSlew
		SetResetFF.kr(PulseDivider.kr(trackb, 4), PulseDivider.kr(trackq, 27)).lag(0.1),  // directRegen
		SetResetFF.kr(PulseDivider.kr(trackb, 2), PulseDivider.kr(trackh, 31)).lag(1)*0.5, // crossRegen
	);
	out = bird+beat;
	//beat * (Ringz.ar(K2A.ar(trackb),22, mul:0.005) + Ringz.ar(K2A.ar(trackh), 550,mul:0.005) + Decay.kr(trackq, mul:0.15) + Decay2.ar(Impulse.ar(tempo/4),0.4,3,mul:0.7));
	monitor.write(out);
})

s.scope(2)
play({Instr.ar("sampleWalk",[Dust.kr(7), LFNoise1.kr(2,1,1)])});

play({Instr.ar("sampleGrain", [c, 1, 0, 1, MouseX.kr(0,1), MouseY.kr(0,1)])});
play({Instr.ar("sampleGrain", [b, 1, LFNoise1.kr(0.7,0.5,0.5), LinExp.kr(LFNoise1.kr(0.14),-1,1,0.001,1), LFNoise0.kr(0.03,0.7,0.7), LFNoise1.kr(0.1,0.3,0.3)])});

s.scope(2)

