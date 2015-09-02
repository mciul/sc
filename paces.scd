s.boot;

// key of Fm (midi note 41)

(
var midi, dur;
var beat = 0.556; // 108 bpm

SynthDef(\feetTick, { |out, freq=440, amp=0.1, pan=0, gate = 1|
	var env = EnvGen.kr(Env.perc(0.01, 0.2), gate, doneAction: 2);
	var audio = Klang.ar(`[[1,3,4],[0.2, 0.3, 0.6],nil], freq);
	OffsetOut.ar(out, Pan2.ar(audio, pan, env * amp));
}).add;

SynthDef(\yardBell, { |out, freq=440, amp=0.1, pan=0, gate = 1|
	var audio = Klank.ar(`[[
		1, 1.995, 2.008, 3.5505, 3.550789, 4, 5.68910
	],[
		1, 0.6, 0.6, 0.4, 0.3, 0.2, 0.2
	], [
		4, 3.5, 3.6, 2.4, 1.23, 0.89, 0.5
	]], Impulse.ar(0,0,amp), freq);
	DetectSilence.ar(audio, doneAction:2);
	OffsetOut.ar(out, Pan2.ar(audio, pan));
}).add;

~steps = Pbind(
	\instrument, \default,
	\midinote, Pseq([44, 36, 43, 36, 41, 36, 40, 36, 37, 36, 41, 43], 10),
	\dur, beat,
	\amp, 0.5
);

~feet = Pbind(
	\instrument, \feetTick,
	\midinote, Pseq([
		65, 68, 65, 68, 65,
		67, 70, 67, 70, 67,
		68, 72, 68, 72, 68,
		67, 70, 67, 70, 67,
		68, 63, 68, 63, 68,
		70, 65, 68, 65, 68
	], 20),
	\dur, beat * 2 / 5,
	\amp, Pseq([
		0.15, 0.02, 0.02, 0.11, 0.02,
		0.12, 0.11, 0.02, 0.02, 0.11,
		0.12, 0.02, 0.11, 0.02, 0.02
	], 20)
);

~yards = Pbind(
	\instrument, \yardBell,
	\midinote, Pseq([
		53, 55, 56, 58, 60,
		55, 56, 58, 60, 61,
		58, 60, 61, 65, 72,
		73, 77, 79, 85, 84
	], 5),
	\dur, beat * 6 / 5,
	\amp, Pseq([
		0.25, 0.1, 0.15, 0.15, 0.15,
		0.2, 0.1, 0.15, 0.15, 0.15
	] * 0.7, 10),
);
)

p = Ppar([~steps, ~yards, ~feet]).play;
p.stop;
s.prepareForRecord
s.record
s.stopRecording

F      41, 53, 65, 77
G      43, 55, 67, 79
Ab     44, 56, 68, 80
Bb     46, 58, 70, 82
C  36, 48, 60, 72, 84
Db 37, 49, 61, 73, 85
Eb 39, 51, 63, 75, 87