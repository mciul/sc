(
Instr(\pretty_accident, {
	arg in, level, maxdelay, delay, lag=0.01;
	var max_monitor = FbNode(in.size);
	var recent_max = max_monitor.delay;
	var in_amp = abs(in);
	var time_since_peak = Sweep.ar(in_amp > recent_max) + ControlDur.ir;
	var current_max = RunningMax.ar(in_amp, time_since_peak > max(delay, ControlDur.ir));
	var gain = max(1, level/VarLag.ar(current_max, lag, warp:\lin));
	max_monitor.write( current_max );
	DelayC.ar(in, maxdelay, delay, gain);
});
)

x.free;
(
x={
	var in = SinOsc.ar(440, 0, VarSaw.kr(0.4, 0, MouseX.kr, 2));
	[DelayC.ar(in, 0.5, 0.5, 0.5), Instr(\dyn_limiter).ar(in, MouseY.kr, 0.5, 0.5)];
}.scope;
)