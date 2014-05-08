//      intro to CrucialLibrary for SC Server
//      _version: 101211, written 031209
// _tested on sc3.3, sc3.4

// note: to make it work with supercollider versions newer than 3.4,
//one need to install the cruciallib quark.  the library is no longer
//included with the standard sc distribution.


//--

//this library is made by crucial (a.k.a. felix/timeblind).  it's huge and
//this tutorial will only scratch a bit on the surface.
//check [CRUCIAL-LIBRARY] plus all helpfiles for more info.

//the two main concepts of this library are instruments and patches,
//here called [Instr] and [Patch].  an Instr is defined once and
//automatically loaded into the global Library.  an Instr can be
//accessed from anywhere and is most often used in combo with
//Patch.  Patch logically plays and combines instruments.

//at startup and after recompile the Library is usually pretty empty.
Library.postTree;

//anything can be stored in Library, but from here on we will
//concentrate on Instr.  the following line will create and save an
//Instr in Library at address \test.
Instr(\test, {BrownNoise.ar(0.1)});

//again dump content of Library.  it should list our test instrument
//under Instr.
Library.postTree;

//to play the Instr at address \test, look it up in the Library using
//the .at method and then .play.
s.boot;
a= Instr.at(\test).play;
a.stop

//this line will overwrite our Instr with another UGen graph.
Instr(\test, {WhiteNoise.ar(0.1)});
a= Instr.at(\test).play;
a.stop

//so the Library is sort of a global repository for Instr.  the Instr
//address can also be multi level like in the following example.
//note the brackets.
Library.clear;
Instr([\testNoises, \brown], {BrownNoise.ar(0.1)});
Instr([\testNoises, \pink], {PinkNoise.ar(0.1)});
Instr([\testNoises, \white, \mono], {WhiteNoise.ar(0.1)});
Instr([\testNoises, \white, \stereo], {WhiteNoise.ar([0.1, 0.1])});
Library.postTree;

//multi level addressed Instr are accessed in this way...
a= Instr.at([\testNoises, \pink]).play;
a.stop
a= Instr.at([\testNoises, \white, \stereo]).play
a.stop
a= Instr.at([\testNoises, \white, \mono]).play
a.stop


//--

//when calling an Instr object it first searches the Library.  if no
//matching name is found, it tries to load a file with the same name
//as the Instr address from the current Instr.dir folder.  this is
//Document.dir++"Instr/" by default, which usually means a folder
//called Instr inside your main supercollider application directory.
//you can of course override this classvar as you like by pointing it
//to another folder.
Library.clear;
Instr.dir= "~/Documents/SuperCollider/myInstrFolder";

//now put a rtf, txt or scd file called "nameless" containing a valid
//Instr into the directory specified above.  if nothing is found
//Instr.at(\nameless) returns nil.
a= Instr.at([\nameless, \nameless]).play     //(try twice - breaks the first time)
a.stop


//--

//to make more interesting Instr you will need arguments.  here is
//an extended version of the testNoise Instr with two arguments.
Instr(\testNoise, {|freq= 1000, mul= 0.5| LPF.ar(WhiteNoise.ar(mul), freq)});

//relying on argument defaults will set noise amplitude to 0.5 and
//low-pass filter's frequency to 1000
a= Instr.at(\testNoise).play;
a.stop

//(btw, as you may have noted there is no need for Out or In when
//using Instr.  CrucialLibrary is smart and takes care of it for you.
//this also makes porting old SC2 code fairly easy.)

//there are a few different ways of supplying arguments.  version 1:
a= {Instr.at(\testNoise).ar(250, 1)}.play;
a.free

//supplying arguments version 2:
a= {Instr.ar(\testNoise, [6000, 0.2])}.play;
a.free

//it is also possible to modulate inlets with other ugens!
a= {Instr.at(\testNoise).ar(FSinOsc.kr(1, 0, 500, 1000), 0.4)}.play;
a.free

//so as you see Instr also works within functions like {}.play and
//SynthDef.  but then you do need an Out etc.
(
SynthDef(\testNoiseDef, {
        Out.ar(0, Instr.at(\testNoise).ar(650, 1));
}).add
)
a= Synth(\testNoiseDef)
a.free

//anyway, now we can play many instances of the same Instr - all
//with their individual settings - at the same time.
(
a= {
        Mix.ar([
                Instr.ar(\testNoise, [FSinOsc.kr(1.2, 0, 100, 500), 0.25]),
                Instr.ar(\testNoise, [9000, LFPulse.kr(2, 0, 0.2, 0.1)]),
                Instr.ar(\testNoise, [150])
        ]);
}.play
)
a.free


//--

//Patch takes an Instr as an argument and plays it.  normally you
//don't play Instr directly like we have above.  create a Patch object
//and supply an Instr name argument instead.
Instr(\testSaw, {Saw.ar(100, 0.1)});    //create an Instr
a= Patch(\testSaw).play;        //play the Instr
a.stop

//and with arguments...  note the array.
Instr(\testSaw, {|freq, mul| Saw.ar(freq, mul)});
a= Patch(\testSaw, [200, 0.1]).play;
a.stop

//as shortcut and for testing, soundfunctions can also be directly
//written in a Patch like this...  but that will actually build an Instr
//with a random name.
a= Patch({|freq, mul| Saw.ar(freq, mul)}, [150, 0.1]).play;
a.stop


//--

//the following lines creates two Instr, one effect and one sound
//source, and then patches them together.
Instr(\testNoise, {WhiteNoise.ar(0.2)});
Instr(\sweepfilter, {|audio| LPF.ar(audio, LFTri.kr(0.3, 0, 300, 800))});
a= Patch(\sweepfilter, [Patch(\testNoise)]).play
a.stop

//this will create one noisy Instr and two simple effects
(
        Instr(\testNoise2, {|mul= 1.0| BrownNoise.ar(mul)});
        Instr([\efx, \lowpass], {|audio, freq= 1000| LPF.ar(audio, freq)});
        Instr([\efx, \delay], {|audio, delaytime= 1|
                audio+CombN.ar(audio, 2, delaytime, 2)});
)

//let us first play the above running a repeating burst of noise
//through a lowpass effect.  cutoff frequency is controlled with the
//mouse.
(
        var source, cutoff;
        source= Patch(\testNoise2, [Patch({LFPulse.kr(2, 0, 0.1, 0.3)})]);
        cutoff= Patch({MouseX.kr(60, 20000, 'exponential')});
        a= Patch([\efx, \lowpass], [source, cutoff]).play
)
a.stop

//secondly we add the delay Instr
(
        var source, cutoff;
        source= Patch(\testNoise2, [Patch({LFPulse.kr(2, 0, 0.1, 0.3)})]);
        cutoff= Patch({MouseX.kr(60, 20000, 'exponential')});
        a= Patch([\efx, \delay], [
                Patch([\efx, \lowpass], [source, cutoff]),
                0.4     //delaytime in seconds
        ]).play
)
a.stop

//last let us run the above example through another instance of the
//delay with a very short delaytime (0.01).  i.e. same delay Instr
//used twice but with different settings.
(
        var source, cutoff;
        source= Patch(\testNoise2, [Patch({LFPulse.kr(2, 0, 0.1, 0.3)})]);
        cutoff= Patch({MouseX.kr(60, 20000, 'exponential')});
        a= Patch([\efx, \delay], [
                Patch([\efx, \delay], [
                        Patch([\efx, \lowpass], [source, cutoff]),
                        0.4     //delaytime in seconds
                ]),
                0.01    //delaytime in seconds
        ]).play
)
a.stop


//--

//multiple channels are easy to deal with when using Instr/Patch.
//here the argument Patch with two Mouse objects will expand the
//SinOsc Patch into two.
(
        a= Patch({|freq= 400| SinOsc.ar(freq, 0, 0.1)}, [
                Patch({[
                        MouseX.kr(60, 20000, 'exponential'),
                        MouseY.kr(60, 20000, 'exponential')
                ]})
        ]).play
)
a.stop

//and a stereo effect with a mono Patch argument will work in the
//same way.
(
        a= Patch({|audio| audio*LFNoise0.kr([3, 2], 0.5, 0.5)}, [
                Patch({SinOsc.ar(350, 0, 0.3)}) //mono sound source
        ]).play
)
a.stop

//also Crucial's NumChannels and Mono classes are sometimes
//useful.  here mixing down from 7 to 2 channels.
(
        var n= 7;
        a= Patch({|audio|
                NumChannels.ar(
                        audio*LFNoise0.kr(
                                Array.fill(n, {3.0.rrand(9.0).round(1.667)}),
                                0.4,
                                0.3
                        ).max(0.0),
                        2
                )
        }, [
                Patch({SinOsc.ar(Array.series(n, 90, 90), 0, 0.1)})
        ]).play
)
a.stop


//--

//then there is PlayerMixer for mixing patches
(
Instr(\testSine, {|freq= 1000, mul= 0.1| SinOsc.ar(freq, 0, mul)});
a= PlayerMixer([
        Patch(\testSine, [400, 0.1]),
        Patch(\testSine, [600, 0.08]),
        Patch(\testSine, [1000, 0.06])
]);
)
a.play
a.stop


//--

//PlayerPool is another useful class.  it lets you switch between
//patches.
(
Instr([\moreTestNoises, \brown], {BrownNoise.ar(0.1)});
Instr([\moreTestNoises, \pink], {PinkNoise.ar(0.1)});
Instr([\moreTestNoises, \white], {WhiteNoise.ar(0.1)});
a= PlayerPool([
        Patch([\moreTestNoises, \brown]),
        Patch([\moreTestNoises, \pink]),
        Patch([\moreTestNoises, \white])
]);
)
a.play;
a.select(1);                            //pink
a.select(2);                            //white
a.select(0);                            //brown
a.choose;                                       //select at random
a.releaseVoice;                 //fadeout

a.autostart_(true);             //start right away
a.autostart_(false);    //or not (default)
a.play;
a.select(0);

//get some info
a.selected;
a.selectedItem.instr;
a.maxIndex;

//PlayerPool also can be quantized with the .round message.
a.round_(4.0);  //now on every 4/4 bar
a.select(1);            //wait.  will shift eventually.
a.select(2);
a.stop


//--

//and almost everything in this library can easily be gui:fied
a.gui;          //playerpool from above

Instr([\testNoises, \brown]).gui;
Patch([\testNoises, \brown]).gui;

//and this lists a few useful tools:
Crucial.menu;

Library.postTree;
Library.clear;