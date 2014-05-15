

s.options.memSize=1048576;
s.options.numWireBufs=128;
s.quit;
s.boot;

b.free;
b = Buffer.read(s, "/Users/mciul/Music/samples/Birdsong-Dunnock.aiff");
b = Buffer.read(s, "/Users/mciul/Music/samples/upenn_birdsong_20140505.aiff");
c = Buffer.read(s, "/Users/mciul/Music/samples/langelliott_blue_jay.aiff");
b = Buffer.read(s, "/Users/mciul/Music/samples/langelliott_wood_thrush.aiff");
d = Buffer.read(s, "/Users/mciul/Music/samples/langelliott_american_crow.aiff");

w.free
w = Buffer.alloc(s,1024,1);


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

~sampleGrain = {
		arg buffer=b, gate=1, start=0, dur=1, pitch=1, tempo=1, grainSize=0.17, overlap=7.58;
		var end = start+((dur*tempo)/BufDur.kr(buffer));
		var triggerRate = overlap/grainSize;
		var triggerDrift = 1/grainSize;
		var trigger = Impulse.kr(LFNoise0.kr(triggerRate+triggerDrift, triggerDrift, triggerRate), mul:gate);
		var rate = tempo*BufRateScale.kr(buffer.bufnum)/buffer.numFrames;
		var pos = Phasor.ar(gate, rate, start, end, start);
		GrainBuf.ar(2, trigger, grainSize, buffer, pitch, pos, 2);
	};

Instr(\sampleGrain,
	~sampleGrain,
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

~stereoBeatZip={
	arg in, delay=1, stretchRate=0.5, squashRate=2, directRegen=1, crossRegen=0.5, gate=1, maxDelay=8, minDelay=0.1;
	var upSlew, downSlew;
	var fbNode, feedback, fft, detected, times, slewed, out;
	var limiterDelay;
	upSlew = 1-min(1,stretchRate);
	downSlew = max(1,squashRate)-1;
	//Poll(Impulse.kr(0)+Changed.kr(squashRate), squashRate, "squashRate");
	Poll(Changed.kr(upSlew), upSlew, "upSlew");
	Poll(Impulse.kr(0)+Changed.kr(downSlew), downSlew, "downSlew");
	fbNode = FbNode(2, minDelay, 4);
	limiterDelay = minDelay - ControlDur.ir;
	feedback = LeakDC.ar(fbNode.delay(ControlDur.ir));
	detected = delay;
	times = [detected, LastValue.kr(detected)] - minDelay;
	slewed = Slew.kr(times, upSlew, downSlew);//.poll(0.5);
	out = DelayC.ar(feedback, maxDelay-minDelay, slewed);
	fbNode.write(Limiter.ar(in + (directRegen*out) + (crossRegen*out.rotate(1)), dur:limiterDelay));
	out;
};

Instr(\stereoBeatZip, ~stereoBeatZip);

~vocoder={ arg in, func, boundaries=[20, 160, 600, 2000, 6000, 20000];
	var low_bound = boundaries[0..boundaries.size-2];
	var cutoff = low_bound.collect({|b,i|
		var rq=0.8;
		[boundaries[i], (1 - (rq/2)) * boundaries[i+1], rq]});
	var vocoder, bands, mix;

	vocoder = cutoff.collect({ |range, i|
		RHPF.ar(RLPF.ar(in,range[1], range[2]), range[0], range[2]);
	});

	bands = cutoff.collect({|range, i| func.value(vocoder[i], range[0], range[1])});
	mix = Mix.new(bands);
};

~octave={arg in, lowFreq=20, hiFreq=20000;
		in * ToggleFF.ar(in);
};

~halfShift={arg in, lowFreq=20, hiFreq=20000;
	var freq = Median.ar(31,ZeroCrossing.ar(in));
	FreqShift.ar(in, Median.kr(31, A2K.kr(freq),-0.5));
};

~ctrlDist={
	arg in, gain=100, center=0.5, min=0, max=1;
	var mid=(max-min)/2;
	(in-center).madd(gain,0).distort.madd(mid, min+mid);
};
)

play({var in=Blip.ar(MouseX.kr(160,600), MouseY.kr(1,200)); [~vocoder.(in, ~halfShift), in]})

play({Instr(\stereoBeatZip).ar(w, SoundIn.ar())})

(play{
	var fft, trackb, trackh, trackq, tempo, barDur, trackphrase, tracksample;
	var bird, beat;
	var monitor, monitor_in, monitor_mono, shifted, out;
	var mintempo;
	var in = SoundIn.ar();
	var buffer=d;
	var freq1, hasFreq1, freq2, hasFreq2;
	var loudness, stereoSpread;
	var pulse, gate, sampleStart, sampleDur, samplePitch, sampleStartChange, sampleTempo;
	var zipTrigger, zipDelay, zipStretch, zipSquash, zipDirect, zipCross, maxBars, minBars, zipDelayChange;
	var freqDownbeat;
	monitor = FbNode(2);
	monitor_in = monitor.delay;
	fft = FFT(w, in+monitor_in.sum);
	// only second channel works with Pitch when using FbNode, don't know why
	//#freq1, hasFreq1, freq2, hasFreq2= monitor.delay.rotate(1).collect({|in| Pitch.kr(in)}).flatten.postln;
	freq1 = A2K.kr(ZeroCrossing.ar(LPF.ar(monitor_in[0], 100)));
	// try this? // hasFreq2 = Onsets.kr(fft, odftype:\wphase);
	// hacky check for low rate of freq1 change:
	// multiply by freq1 so 0 freq never registers as pitch
	// subtract from lag to see if it's changed recently
	// threshold: change < 1 Hz
	hasFreq1 = freq1*(1-abs(freq1.lag(0.3) - freq1));
	freq1 = max(12.midicps, freq1);
	#freq2, hasFreq2 = Pitch.kr(monitor_in[1],clar:1);
	//Poll(hasFreq2, freq2, "freq2");
	//Poll(hasFreq1, freq1, "freq1");
	// use SpecFlatness? SpecPcile? SpecCentroid? KeyTrack?
	#trackb, trackh, trackq, tempo = BeatTrack.kr(fft, 0);
	trackphrase = PulseDivider.kr(trackb, 8);
	mintempo=BufDur.kr(buffer).reciprocal;
	barDur=(max(mintempo, tempo)).reciprocal;
	loudness = Amplitude.kr(monitor_in);
	stereoSpread = (loudness[1]-loudness[0]).abs;
	// freqDownbeat is a trigger that signals multiple pitch
	// events happening on a downbeat
	freqDownbeat = Impulse.kr(0) + Trig1.kr(hasFreq1.clip + hasFreq2 - 2 + Decay.kr(trackb,0.01),0);
	//Poll(hasFreq1, hasFreq1, "hasFreq1");
	//Poll(hasFreq2, hasFreq2, "hasFreq2");
	//Poll(0.5, freq2, "freq2");
	// using freq1 triggers more overloads, but sometimes never recovers
	// try tweaking values for freq2, since I think that is now used
	// to control pitch
	gate = SetResetFF.kr(freq2.lag(1)<70, freq2>3800);
	Poll.kr(1-gate, PulseCount.kr(1-gate), "frequency overload");
	Poll.kr(gate, Timer.kr(1-gate), "frequency recovery");// Timer not doing what I thought it would
	sampleStartChange = freqDownbeat+Trig1.kr(gate,0);
	sampleStart = Latch.kr(freq1.cpsoct.mod(1), sampleStartChange);
	Poll(sampleStartChange, sampleStart, "sampleStart");
	sampleDur = Latch.kr(2.pow(loudness[0].madd(14,-8).round)*tempo*16, trackphrase);
	tracksample = PulseDivider.kr(trackb, max(1,sampleDur*2/barDur));
	gate = gate * (1 - tracksample);
	sampleDur = sampleDur * Latch.kr((0.2+loudness[1]-loudness[0]).sign, trackb);
	//Poll(trackphrase, sampleDur, "sampleDur");
	samplePitch = Latch.kr(freq2/880, hasFreq2 * trackq);
	// bird is in channel 0, so louder 0 means more bird
	// let's make the bird play slower when it's louder
	sampleTempo = 4.pow(((loudness[1]*20)-(loudness[0]*50)).distort);
	//Poll(trackphrase, sampleTempo, "sampleTempo");
	//Poll(gate, PulseCount.kr(gate), "gate");
	//Poll(hasFreq1, samplePitch, "samplePitch");
	bird = ~sampleGrain.value(buffer, gate, sampleStart, sampleDur, samplePitch, sampleTempo);
	maxBars = max(1,(8/barDur).floor);
	//Poll(trackb, maxBars*barDur, "max delay");
	minBars = (0.25/barDur).ceil;
	zipDelayChange = freqDownbeat + SetResetFF.kr(trackphrase, Changed.kr(tempo));
	zipDelay = barDur * Latch.kr((freq1/freq2).cpsmidi.round.wrap(minBars,maxBars), zipDelayChange);
	Poll(zipDelayChange, zipDelay, "zipDelay");
	// multiply by gate so when frequency overloads, we use
	// the minimum (lowest pitch) rate
	zipTrigger=SetResetFF.kr(trackphrase, TDelay.kr(zipDelayChange,barDur/8));
	zipStretch = Latch.kr(Decay.kr(loudness[0], barDur, 0.1*gate).round(1/2).clip(0.25, 0.5), zipTrigger);
	zipSquash = Latch.kr(loudness[1].madd(-3, 2.5).round(1/2).clip(4/3, 2), zipTrigger);
	//Poll(trackphrase, zipTrigger, "zipTrigger");
	//Poll(zipTrigger, zipSquash, "zipSquash");
	// zipDirect is stereo, open gate during attacks
	zipDirect = Latch.kr(~ctrlDist.(loudness.lag(barDur/4)-loudness.lag(barDur),10000,0.01,1,0),trackh).lag(1.1-gate);
	// zipcross is strong when two channels are different
	zipCross = Latch.kr(~ctrlDist.(stereoSpread.lag(barDur*4), 8, 0.01, gate/2, max(1-zipDirect,1/2)),trackphrase).lag(barDur/4);
	//Poll(TDelay.kr(trackb,0.1), zipDirect, "zipDirect");
	//Poll(TDelay.kr(trackphrase, barDur/4), zipCross, "zipcross");
	beat = ~stereoBeatZip.value(in+bird,
		zipDelay, // tempo
		zipStretch, // stretchRate
		zipSquash, // squashRate
		zipDirect,  // directRegen
		zipCross, // crossRegen
		gate
	);
	// shifted should be inside the feedback loop of stereoBeatZip
	//shifted=FreqShift.ar(beat, -0.75*[freq1, freq2]);
	//shifted=~vocoder.(beat, ~halfShift, Array.geom(21, 20, 1.414));
	//SelectX.ar(gate.lag(barDur*4), [shifted, beat]
	out = Pan2.ar(bird, 0.2) + beat;
	//beat * (Ringz.ar(K2A.ar(trackb),22, mul:0.005) + Ringz.ar(K2A.ar(trackh), 550,mul:0.005) + Decay.kr(trackq, mul:0.15) + Decay2.ar(Impulse.ar(tempo/4),0.4,3,mul:0.7));
	monitor.write(out);
	out*0.7;
})

Array.geom(21, 20, 1.414).round


(~ctrlDist.(0.007, 8, 0.125, gate/2, max(1-zipDirect,1/2)),trackphrase)

play({Instr.ar("sampleWalk",[Dust.kr(7), LFNoise1.kr(2,1,1)])});

play({Instr.ar("sampleGrain", [c, 1, 0, 1, MouseX.kr(0,1), MouseY.kr(0,1)])});
play({Instr.ar("sampleGrain", [b, 1, LFNoise1.kr(0.7,0.5,0.5), LinExp.kr(LFNoise1.kr(0.14),-1,1,0.001,1), LFNoise0.kr(0.03,0.7,0.7), LFNoise1.kr(0.1,0.3,0.3)])});

play({var in=Saw.ar([440, 550]); SelectX.ar(MouseX.kr(0,1), [FreqShift.ar(in, [220, 275]), in])})

s.scope(2)
s.prepareForRecord
s.record
s.stopRecording
(
play({
	var freq1, hasFreq1, freq2, hasFreq2, s;
	var monitor = FbNode(2);
	var monitor_in = monitor.delay;
	#freq1, hasFreq1 = Pitch.kr(monitor_in[1], execFreq:60, peakThreshold:0.1,clar:1);
	#freq2, hasFreq2 = Pitch.kr(monitor_in[0],clar:1);
	Poll.kr(Impulse.kr(2), RunningMax.kr(hasFreq1, Impulse.kr(2)), "hasFreq1");
	Poll.kr(Impulse.kr(2), freq1, "freq1");
	Poll.kr(Impulse.kr(2), freq2, "freq2");
	monitor.write(SinOsc.ar([200,100]));
	monitor_in[0];
})
)

