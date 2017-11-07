// Feedback matrix - the class definition
//
// A network of effects processors feeding back to each other.
// Thanks to David Lee Myers for his feedback music 
// and to Charles Cohen for telling me about it
//
// - Mike Ciul 2006
// No copyright unless this file comes with a GPL or Creative Commons license.

// ***************************************************************
// SynthArray
// ***************************************************************

SynthArray { var node, synths, debug;

	// constructor
	// 
	// synthNames should be an array of synthdef names
	// It will clip if shorter than the synthData array
	// synthData should be a two dimensional array:
	//	[
	//		controlName, [ value, nil, value .. ],
	//		controlName, [ nil, value, nil .. ]
	//	]
	// controlName.. are names of synth controls, 
	// and value/nil are values of the control settings 
	// (or nil if that synth doesn't use that value)
	//
	// inBuses and outBuses should be arrays of bus objects
	// inBuses should always be the size of the channel array
	// 
	// node should be a group to add all the synths to

	*new{ arg synthNames, synthData, inBuses, outBuses, myNode, debug=false;
	
		^super.new.init( synthNames, synthData, inBuses, outBuses, myNode, debug );
	}

	init{ arg synthNames, synthData, inBuses, outBuses, myNode, myDebug;
	
		var synthTable = synthData.flop;
		node = myNode;
		debug = myDebug;
		synths = [ ];
		inBuses.do( { |inBus, i|
			debug.if { 
				( "SynthArray.init: inBus=" ++ inBus.asString ++ " i=" ++ i.asString).postln;
			};
			this.addSynth( synthNames.clipAt(i), synthTable.wrapAt(i), inBus, outBuses[i] );
		} );
		^this;
	} 

	addSynth{ arg synthName, controls, inBus, outBus;
		var newSynth;
		controls = controls.addAll( [ \in, inBus.index, \out, outBus.index ] );
		debug.if {
			( "SynthArray.addSynth: synthName=" ++ synthName.asString ++ " controls=" ++ controls.asString ).postln
		};

		newSynth = synthName.notNil.if( { Synth( synthName, controls, node ) }, { nil } );
		debug.if { ( "SynthArray.addSynth: new synth=" ++ newSynth.asString ).postln };
		synths = synths.add( newSynth );	
		^this;
	}
	
	set{ arg mixData;
		var flopped = mixData.flop;
		
		synths.do { |synth, i| 
			var control, setting;
			# control, setting = flopped.wrapAt(i);
			synth.set( control, setting );
			
			debug.if { ( "Set synth " ++ synth.asString ++ " control " ++ control.asString
				++ " to " ++ setting ).postln;
			};
		}
	}
	
	setAt{ arg i, control, value;
		debug.if { ( "SynthArray:SetAt: i=" ++ i.asString ++ " controls=" ++ control.asString ++ "->" ++ value.asString ++ " synth=" ++ synths[i].asString ).postln };
		synths[i].set( control, value );
	}
	
	free{
		synths.do( _.free );
		synths = [ ];
		^this;
	}
}

// ***************************************************************
// FeedbackMatrix
// ***************************************************************
//
// requires the effectSend and mainOut synths to be defined on the server
// Where's the best place to do that?

FeedbackMatrix {
	
	var <s, feedbackGroup, fbDelayGroup, fbFXGroup, fbLimitGroup, sourceGroup, sendGroup,
			delaySynth, fxSynth, limitSynth, sourceSynth,
			fbSendSynth, sourceSendSynth, fbMixSynth, sourceMixSynth,
			<fbChannels, <sourceChannels, inputBus, <outputBus, sourceBus,
			debug;
		
	// Initialize class at compile time
	
	*initClass {
		// Create some synthdefs used in the matrix mixer
		
		// this directory command is borrowed from James Harkin's dewdropworld library.
		// http://www.dewdrop-world.net
		// I'm not sure if it works on all platforms.
		("synthdefs/FeedbackMatrix".pathMatch.size == 0).if {
			"mkdir synthdefs/FeedbackMatrix".unixCmd;
		};
		
		{
			SynthDef.writeOnce( "FeedbackMatrix/effectSend", { arg in, out, level = 0; 
				Out.ar( out, In.ar(in) * level );
			});

			SynthDef.writeOnce( "FeedbackMatrix/mainOut", { arg in, level = 0.5, pan = 0;
				Out.ar( 0, Pan2.ar( In.ar(in), pan, level ) );
			});
			
		}.defer(1); // Also borrowed from James Harkin. 
		// I assume this allows time for the directory to be created,
		// or for the SynthDef class to be defined
	}

	// constructor
	//
	// Creates an empty FeedbackMatrix
	// arguments: server, debug
	//
	// If we want one, we will have to create a convenience constructor
	// for creating a filled FeedbackMatrix	
	
	*new{ arg server, debug=false;
		^super.new.init( server, debug );
	}
	
	init{ arg server, mydebug;
		debug = mydebug;
		if (debug, { "FeedbackMatrix: debug is on".postln; } );

		s = server;
		fbChannels = sourceChannels = 0;
		
		feedbackGroup = Group.new(s);
		fbDelayGroup = Group.head(feedbackGroup);
		fbFXGroup = Group.tail(feedbackGroup);
		fbLimitGroup = Group.tail(feedbackGroup);
		sourceGroup = Group.after(feedbackGroup);
		sendGroup = Group.after(sourceGroup);
		
		^this;
	}
	
	// destructor
	free{
		[ delaySynth, fxSynth, limitSynth, sourceSynth,
		  sendGroup, sourceGroup, fbLimitGroup, fbFXGroup, fbDelayGroup, feedbackGroup,
		].do( _.free );
		delaySynth = fxSynth = limitSynth = sourceSynth = sendGroup = sourceGroup = 
			fbLimitGroup = fbFXGroup = fbDelayGroup = feedbackGroup = nil;
	
		( sourceSendSynth ++ fbSendSynth ++ inputBus ++ outputBus ++ sourceBus ).do( _.free );
		sourceSendSynth = fbSendSynth = inputBus = outputBus = sourceBus = [ ];
		
		fbChannels = sourceChannels = 0;
		
		^this;
	}
	
	// setFBChannels
	//
	// Set all channels of the feedback matrix,
	// wiping out any previous ones
	//
	// Creates an in and out bus for each channel
	// Creates the delay, effect, limit synth chain specified for each one
	// Creates a send from each out bus to each in bus, set to zero
	// Creates a stereo output mix: 
	//   guesses at a reasonable level for all channels
	//   pans each channel hard left and right alternately
	//
	// TODO: keep any can be saved by resetting controls
	// instead of destroying and recreating them
	
	setFBChannels{ arg delaySynthNames, delaySynthControls,
					 fxSynthNames, fxSynthControls,
					 limitSynthNames, limitSynthControls;		// data should be in this form:
	//	// delay synths
	//	[ synthName, synthName .. ],
	//	[ 
	//		controlName, [ value, value .. ],
	//		controlName, [ value, value .. ]
	//		..
	//	],
	//	// effect synths
	//		..
	//	// limiter synths
	//		..
	
		// this.clearOutOldChannelData;
		// TODO - implement this method, maybe change the name
		[ delaySynth, fxSynth, limitSynth ].do( _.free );
		// TODO - don't clear out all channels - leave unchanged items alone
		
		fbChannels = this.guessNumChannels( 
			[ delaySynthNames, fxSynthNames, limitSynthNames ],
			[ delaySynthControls, fxSynthControls, limitSynthControls ] );

		// create buses
		inputBus = ( { Bus.audio(s,1) } ).dup( fbChannels );
		outputBus = ( { Bus.audio(s,1) } ).dup( fbChannels );
		
		// create synths
		delaySynth = SynthArray( delaySynthNames, delaySynthControls,
			inputBus, outputBus, fbDelayGroup, debug );
		fxSynth = SynthArray( fxSynthNames, fxSynthControls,
			outputBus, outputBus, fbFXGroup, debug );
		limitSynth = SynthArray( limitSynthNames, limitSynthControls, 
			outputBus, outputBus, fbLimitGroup, debug );
					
		// create sends and zero them
		// TODO - don't zero it for unchanged channels?
		fbSendSynth = outputBus.collect( { |out| SynthArray( ["FeedbackMatrix/effectSend"], 
			[ \level, 0], out.dup(fbChannels), inputBus, sendGroup, debug );
		} );
		
		// send all channels to output
		// we use a default level that is unlikely to cause much clipping
		// by default, channels alternate panning hard left and right
		fbMixSynth = SynthArray( ["FeedbackMatrix/mainOut"], 
			[ \level, 0.7/fbChannels.sqrt, \pan, [-1, 1] ],
			outputBus, outputBus, sendGroup, debug );
	}
	
	guessNumChannels { arg synthNameArray, synthControlsArray;
				^(synthNameArray.collect( _.size ).maxItem max:
			( synthControlsArray.flatten(1) ).flop.size );	}
			
	setFBMix { arg mixData;
	
		fbMixSynth.set( mixData );
		^this;
	}

	setFBSends { arg mixData;
		// mixData should be a two dimensional array of send levels.
		// the array must be of dimensions (fbChannels, fbChannels)
		// TODO - make a MixArray class for both this and the source sends?
	//	[
	//			[ 0 -> 0, 0 -> 1, .. ],
	//			[ 1 -> 0 .. ],
	//			..
	//	]
		mixData.collect( { |row, i| row.collect( { |level, j|
			debug.if { ("setFBSends: i=" ++ i.asString ++ " j=" ++ j.asString ++ " level=" ++ level.asString ).postln; };
			this.setFBSendAt( i, j, level );
		} ); } );
		
		^this;
	}
	
	setSourceSends { arg mixData;
	
		mixData.collect( { |row, i| row.collect( { |level, j|
			debug.if { ("setSourceSends: i=" ++ i.asString ++ " j=" ++ j.asString ++ " level=" ++ level.asString ).postln; };
			this.setSourceSendAt( i, j, level );
		} ); } );
		
		^this;
	}
		
	
	setFBSendAt { arg i, j, level;
		fbSendSynth[i].setAt( j, \level, level );
	}
	
	setSourceSendAt { arg i, j, level;
		sourceSendSynth[i].setAt( j, \level, level );
	}
	
	setSourceChannels { arg sourceSynthNames, sourceSynthControls;
		// TODO - reduce duplication with setFeedbackChannels?
		// clear old source channels - TODO - keep what hasn't changed?
		sourceSynth.free;
		
		sourceChannels = this.guessNumChannels( [ sourceSynthNames ], [ sourceSynthControls ] );
		// create source channels
		sourceBus = ( { Bus.audio(s, 1) } ).dup( sourceChannels );
		
		// create source synths
		// I think we need the synthArray object to reduce duplication with fbChannels
		sourceSynth = SynthArray( sourceSynthNames, sourceSynthControls, 
			sourceBus, sourceBus, sourceGroup, debug );
		
		// create source sends and set them to a low level (?)
		sourceSendSynth = sourceBus.collect( { |out| SynthArray( ["FeedbackMatrix/effectSend"], 
			[ \level, 0.001], out.dup(fbChannels), inputBus, sendGroup, debug );
		} );
					
		// we don't send source channels to output, though maybe we should provide the option.
		^this;
	}
	
}
