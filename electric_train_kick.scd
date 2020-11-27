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