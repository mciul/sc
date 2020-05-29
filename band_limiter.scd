s.boot;
b = Buffer.read( s, "/Users/mciul/Music/GarageBand/quiethours - 3:24:20, 6.17 PM.aif" );

(
{
	var cutoffs = [20, 35, 70, 140, 270, 550, 1100, 2200, 4500, 9000, 18000];
	var in = PlayBuf.ar(2,b);
	var bands = (cutoffs.size-1).collect { |i|
		HPF.ar(LPF.ar(in, cutoffs[i+1]), cutoffs[i]);
	};
	var limiters = bands.collect { |sig, i|
		var max_delay = 0.25;
		var gain = 1;
		var limit_delay = (cutoffs[0]/cutoffs[i]) * max_delay;
		var extra_delay = 64/44100 + max_delay - limit_delay;
		DelayC.ar(Limiter.ar(sig * gain, 1, dur: limit_delay), extra_delay, extra_delay);
	};
	limiters.sum;
}.play
)