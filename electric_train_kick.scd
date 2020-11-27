s.boot;
(
{
	var amp_env = Decay.ar(Impulse.ar(0), 2.0);
	var freq_env = Decay.ar(Impulse.ar(0),3.0);
	var high_note = 39.midicps;
	var low_note = 27.midicps;
	var freq = freq_env.linlin(0,1,low_note,high_note);
	SinOsc.ar(freq, 1*pi/2, [0.5, 0.5]*amp_env)
}.play;
)
43.midicps