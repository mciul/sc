s.boot;
(SynthDef.new(\electricTrainKick, {
	arg amp_decay=2, freq_decay=0.9, high=51, low=36;
	var amp_env = Decay.ar(Impulse.ar(0), amp_decay);
	var freq_env = Decay.ar(Impulse.ar(0), freq_decay);
	var high_note = high.midicps;
	var low_note = low.midicps;
	var freq = freq_env.linexp(0,1,low_note,high_note);
	var out = SinOsc.ar(freq, 1*pi/2, 0.5*amp_env);
	DetectSilence.ar(out, doneAction: Done.freeSelf);
	Out.ar(0, out);
}).add;
)

(SynthDef.new(\gamutKick, {
	arg note=51;
	var amp_decay = note.linexp(51,72,2,1);
	var freq_decay = note.linexp(51,72,0.9,0.2);
	var amp_env = Decay.ar(Impulse.ar(0), amp_decay);
	var freq_env = Decay.ar(Impulse.ar(0), freq_decay);
	var high_note = note.midicps;
	var low_note = 36.midicps;
	var freq = freq_env.linexp(0,1,low_note,high_note);
	var out = SinOsc.ar(freq, 1*pi/2, 0.5*amp_env);
	DetectSilence.ar(out, doneAction: Done.freeSelf);
	Out.ar(0, out);
}).add;
)

s.prepareForRecord();
s.record();
Synth.new(\electricTrainKick, [\amp_decay, 2, \freq_decay, 0.9, \high, 51, \low, 36]);
Synth.new(\electricTrainKick, [\amp_decay, 1, \freq_decay, 0.2, \high, 72, \low, 36]);
Synth.new(\gamutKick, [\note, 33]); // A1
Synth.new(\gamutKick, [\note, 34]); // Bb1
Synth.new(\gamutKick, [\note, 36]); // C2
Synth.new(\gamutKick, [\note, 38]); // D2
Synth.new(\gamutKick, [\note, 39]); // Eb2
Synth.new(\gamutKick, [\note, 41]); // F2
Synth.new(\gamutKick, [\note, 43]); // G2
Synth.new(\gamutKick, [\note, 45]); // A2
Synth.new(\gamutKick, [\note, 46]); // Bb2
Synth.new(\gamutKick, [\note, 48]); // C3
Synth.new(\gamutKick, [\note, 50]); // D3
Synth.new(\gamutKick, [\note, 51]); // Eb3
Synth.new(\gamutKick, [\note, 53]); // F3
Synth.new(\gamutKick, [\note, 55]); // G3
Synth.new(\gamutKick, [\note, 57]); // A3
Synth.new(\gamutKick, [\note, 58]); // Bb3
Synth.new(\gamutKick, [\note, 60]); // C4
Synth.new(\gamutKick, [\note, 62]); // D4
Synth.new(\gamutKick, [\note, 63]); // Eb4
Synth.new(\gamutKick, [\note, 65]); // F4
Synth.new(\gamutKick, [\note, 67]); // G4
Synth.new(\gamutKick, [\note, 69]); // A4
Synth.new(\gamutKick, [\note, 70]); // Bb4
Synth.new(\gamutKick, [\note, 72]); // C5
Synth.new(\gamutKick, [\note, 74]); // D5
Synth.new(\gamutKick, [\note, 75]); // Eb5
Synth.new(\gamutKick, [\note, 77]); // F5
Synth.new(\gamutKick, [\note, 79]); // G5
Synth.new(\gamutKick, [\note, 81]); // A5
Synth.new(\gamutKick, [\note, 82]); // Bb5
Synth.new(\gamutKick, [\note, 84]); // C6
Synth.new(\gamutKick, [\note, 86]); // D6
s.stopRecording();

l = Buffer.read( s, "/Users/mciul/Music/samples/train_kick_short_L.aiff" );
r = Buffer.read( s, "/Users/mciul/Music/samples/train_kick_short_R_filtered.aiff" );

(
SynthDef.new(\sweepKick, {
	arg inBuf, outBuf, vel = 100, rq=0.3;
	var dur = 2; // BufDur.ir(inBuf);
	var low_note = 36;
	var high_note = vel.explin(1,127,low_note,105);
	var freq = EnvGen.kr(Env.linen(0.0, 0, dur)).linlin(0,1,low_note,high_note).midicps;
	var in = PlayBuf.ar(
		2, inBuf, BufRateScale.ir(inBuf),
		doneAction: Done.freeSelf
	);
	var fx = RLPF.ar(in, freq, rq);
	var write = RecordBuf.ar(fx, outBuf, loop: 0);
	Out.ar(0, fx);
}).add;
)

100.linlin(1,127,30,127)

Synth.new(\sweepKick, [\inBuf, ~inBuf.bufnum, \outBuf, ~outBuf.bufnum, \vel, 110] );

(
~playSample = { |buf| { PlayBuf.ar(buf.numChannels, buf.bufnum, BufRateScale.ir(buf.bufnum))}.play; };
~writeSamples = Routine({
	var splits = ~inBuf.path.split($.);
	var outPrefix = splits.keep(splits.maxIndex).join('.');
	(7,15..127).do { |velocity|
		var outPath = outPrefix ++ velocity ++ ".aiff";
		Synth.new(\sweepKick, [\inBuf, ~inBuf.bufnum, \outBuf, ~outBuf.bufnum, \vel, velocity]);
		(~inBuf.duration + 0.1).yield;
		("writing to " ++ outPath).postln;
		~outBuf.write(outPath);
	};
});
)
~inBuf = l;
~inBuf = r;
~outBuf.free;
~outBuf = Buffer.alloc( s, ~inBuf.numFrames, ~inBuf.numChannels);
TempoClock.default.sched(0, ~writeSamples);
~writeSamples.stop;
~writeSamples.reset;

a="foo/bar.baz.txt".split($.)
a.keep(a.maxIndex)

~playSample.value(l);
~playSample.value(r);
~playSample.value(~outBuf);
