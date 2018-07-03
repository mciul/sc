// Let's try it this way
//

Server.default = s = Server.internal.boot;

(
~analysis_bus = Bus.control( s, 4 );
b = Buffer.read(s, "/Users/mike/Documents/recordings/samples/harold_bigorlittle.aiff");
// allocate a disk i/o buffer
c = Buffer.alloc(s, 65536, 4);
~playgroup = Group.head( s );
~recordgroup = Group.tail( s );
)

(
SynthDef( 'MachineSample', {
	arg outbus = 0, analysis_bus = 0, bufnum = 0, unityFreq = 440,
		attackdb = 6, minVelocity = 0.1;
	var freq, hasFreq, attack, amplitude, velocity, interval, out;
	
	#freq, hasFreq, amplitude, attack = In.kr( analysis_bus, 4 );
	attack = attack - attackdb;
	velocity = RunningMax.kr( amplitude, attack * hasFreq ) min: 1;
	velocity = LinLin.kr( velocity, 0, 1, minVelocity, 1 );
	interval = ( freq / unityFreq ).ratiomidi.wrap2( 24 );

	out = PlayBuf.ar(
		1,
		bufnum,
		rate: interval.midiratio * BufRateScale.kr( bufnum ),
		trigger: attack,
		loop:0
	);
	
	Out.ar( outbus, out * velocity );
}).send( s );

// MachineRes
//
// minFreq, minPitch, and range can't be modulated
// because some parameters for CombL and Wrap can't be modulated.

SynthDef( 'MachineRes', {
	arg outbus = 1, analysis_bus = 0, minPitch = 220, minFreq = 55, range = 24, attackdb = 12,
		leftLevel = 0.5, rightLevel = 0.5, sampleLevel = 0.5,
		decayTime = 0.38, maxVelocity = 8;
	var in, pitch, hasFreq, amplitude, attack, velocity,
		minMidi, transpose, halfRange, centerMidi,
		freq, period, maxperiod, out;
	
	in = Mix( ( AudioIn.ar([1,2]) ++ In.ar(0) ) * [ leftLevel, rightLevel, sampleLevel ] );
	
	#pitch, hasFreq, amplitude, attack = In.kr( analysis_bus, 4 );
	attack = attack - attackdb;
	
	//velocity = Latch.kr( amplitude, attack ).lag(0.05) min: 1;
	// try this:
	velocity = amplitude / ( Amplitude.kr( in ) + maxVelocity.reciprocal );
	
	minMidi = minFreq.cpsmidi;
	transpose = minMidi - minPitch.cpsmidi;
		
	freq = ( pitch.cpsmidi + transpose ).wrap( minMidi, minMidi + range ).midicps;
	
	period = freq.reciprocal;
	maxperiod = minMidi.midicps.reciprocal;
	
	out = CombL.ar( in * velocity, maxperiod, period, decayTime );

	Out.ar( outbus, ( out ).softclip );
}).send(s);

SynthDef( 'Analysis', {
	arg koutbus = 0, samplebus = 0, resbus = 1, 
		leftLevel = 0.5, rightLevel = 0.5, sampleLevel = 0.5, resLevel = 0.5;
	
	var mix, freq, hasFreq, amplitude, attack;
	mix = Mix.ar(
		AudioIn.ar( [1,2] ) ++ InFeedback.ar( [samplebus] ) *
		[ leftLevel, rightLevel, sampleLevel ]
	);
	
	#freq, hasFreq = Pitch.kr( mix, downSample: 2, median: 7 );
	amplitude = Amplitude.kr( mix, add: 0.0001 ); // avoid division by zero	
	attack = Slope.kr( amplitude.ampdb, ControlRate.ir.reciprocal );
	
	Out.kr( koutbus, [ freq, hasFreq, amplitude, attack ] );

}).send( s );

// this will record to the disk
SynthDef("4chan-Diskout", {arg bufnum;
	DiskOut.ar(bufnum, AudioIn.ar([1,2]) ++ In.ar(0,2));
}).send(s);

)

create an output file for the buffer, leave it open
// can you actually have a 4 channel aiff? Yes!!
// can we create unique filenames somehow?
c.write("recordings/machine.aiff", "aiff", "int16", 0, 0, true);

// start a recording:
(
~analysis = Synth( 'Analysis', [ \koutbus, ~analysis_bus.index, \sampleLevel, 4 ], ~playgroup );
~analysis.set( \leftLevel, 0.5, \rightLevel, 0.0, \sampleLevel, 1, \resLevel, 0.0 );
~sample = Synth.after( ~analysis, 'MachineSample', [ \analysis_bus, ~analysis_bus.index, \bufnum, b.bufnum ] );
~res = Synth.after( ~sample, 'MachineRes', [ \analysis_bus, ~analysis_bus.index, \minFreq, 55,
	\leftLevel, 1, \rightLevel, 0.25, \sampleLevel, 0.5, \maxVelocity, 27.dbamp ] );
// create the diskout node; making sure it comes after the source
d = Synth("4chan-Diskout", ["bufnum", c.bufnum], ~recordgroup );
)

// stop the music:
(
~analysis.set( \leftLevel, 0, \rightLevel, 0, \sampleLevel, 0, \resLevel, 0 );
// hope that works!
)

// when it all stops, end recording:
d.free;
// close the buffer and the soundfile
c.close;


// experiment with settings:

~analysis.free;
~analysis = Synth( 'Analysis', [ \koutbus, ~analysis_bus.index ], ~playgroup );
~analysis.set( \leftLevel, 0.5, \rightLevel, 0.0, \sampleLevel, 1, \resLevel, 0.0 );
~analysis.set( \leftLevel, 0, \rightLevel, 0);
~analysis.set( \sampleLevel, 0.01 );

~sample.free;
~sample = Synth.after( ~analysis, 'MachineSample', [ \analysis_bus, ~analysis_bus.index, \bufnum, b.bufnum ] );
~res.free;
~res = Synth.after( ~sample, 'MachineRes', [ \analysis_bus, ~analysis_bus.index, \minFreq, 55 ] );
~res.set( \leftLevel, 1, \rightLevel, 0.25, \sampleLevel, 0.5 );
~res.set( \attackdb, 12 );
~res.set( \decayTime, 0.38 );
~res.set( \maxVelocity, 24.dbamp );

~sample.set( \attackdb, 1 );
~sample.set( \unityFreq, 880 );

s.scope(2, rate: \audio)
s.scope(4, rate: \control)
