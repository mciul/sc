(
Instr(\zigzag_delay, {
	arg in, trig, stretch_rate=1, squash_rate=1, min_time=0, max_time=2, lag=0.01;
	var blend = VarLag.kr(ToggleFF.kr(trig).madd(2,-1), lag, warp:\lin);
	var target_time = SetResetFF.kr(blend, 1-blend).madd(max_time-min_time, min_time);
	var up_slew = max(0, 1 - stretch_rate);
	var down_slew = max(0, squash_rate - 1);
	var delay_time = Slew.kr(target_time, up_slew, down_slew);
	//Poll.kr(delay_time > min_time * delay_time < max_time * Impulse.kr(10), delay_time);
	DelayC.ar(in, max_time, delay_time, blend);
});
// stretch range: -infinity -> 1
// squash range:  1 -> infinity
)

b.free;
b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
x.free;
(
x={
	var in=PlayBuf.ar(1, b.bufnum, BufRateScale.kr(b.bufnum), loop:1);
	Instr(\zigzag_delay).ar(in, MouseY.kr(-1, 1), -2, 2, 0, 8);
}.scope;
)

playbackrate 0 -> slew rate 1
playbackrate 0.5 -> slew rate 2

(
Instr(\dyn_lag, {
	arg in, lag_time, mul, add;

});
)

(
Instr(\limiter_delay, {
	arg in, level, maxdelaytime, delaytime;
	var in_amp = abs(in);
	var below_limit = in_amp < level;
	var time_below_limit = Sweep.ar(below_limit) * below_limit;
	var potential_peak = RunningMax.ar(in_amp, time_below_limit > maxdelaytime);
	var likely_peak = RunningMax.ar(in_amp, time_below_limit > delaytime);
	//var delaytime_at_reset = Latch.ar(delaytime, time_below_limit > delaytime);
	// still clips sometimes, mainly when delaytime is decreasing - why?
	// also, can we open sooner when delay times are shorter?
	//var selected_peak = Select.ar(delaytime > delaytime_at_reset,
		//[potential_peak, likely_peak]);
	var overflow = max(level, potential_peak);
	var gain = VarLag.ar(overflow.reciprocal, delaytime, warp:\lin, mul:level);
	DelayC.ar(in, maxdelaytime, delaytime, gain);
});
)

)
x.free;
(
x={
	var in = SinOsc.ar(50, 0, VarSaw.kr(0.4, 0, MouseX.kr(0,1), 1, 1));
	var delaytime = MouseY.kr(0, 1);
	[DelayC.ar(in, 1, delaytime, 0.5), Instr(\limiter_delay).ar(in, 1, 1, delaytime)].clip(-1,1);
	//[DelayC.ar(in, 0.5, 0.5, 0.5), DelayC.ar(in, 0.5, 0.5, 0.5)];
}.scope;
)

x.free
x={var in = LFPulse.ar(64); [in, Sweep.ar(in, 10)]}.scope