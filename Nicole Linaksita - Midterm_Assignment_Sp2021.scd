/*******MIDTERM ASSIGNMENT********/

//BUILD A GENERATIVE PATTERN MACHINE

//PART 1. Design and test 2 SynthDefs using Blip.ar and VarSaw.ar

//Requirements:
//-Each SynthDef must have discernible pitch.
//-Each must be stereophonic. (Use a different method of multi-channel expansion for each.)
//-Each must have an envelope. (Use a different method for each.)
//-Each must have basic control of freq, amp, envelope parameters (atk, sus, rel, or similar, etc.), and pan at a minimum.
//-Blip should have control of nharm, and VarSaw should have control of width.
//-Both SynthDefs must utilize some sort of frequency offset variable. (Hint: Utilize some form of randomness, like LFNoise1 or similar. Use a different method for each.)

Server.killAll;
//Boot the server
s.boot;

/********LOAD SYNTHDEFS**********/ // CLOSING BRACKET ON LINE 66
(
//Blip.ar SynthDef
SynthDef(\blip, {
	arg atk=0.01, rel=2, freq=440, amp=0.1, lev=1, out=0, pan=0.0, nharm=10, freqOff=0.1, freqRate=5;
	var sig, env, freqVar, panRand;

	// Frequency offset
	// freqOff: frequency offset value
	// freqRate: frequency of randomness changing
	freqVar = freq*LFNoise2.kr(freqRate).range((freqOff*(-1)),freqOff).midiratio;

	// Envelope
	env = EnvGen.kr(Env.perc(atk,rel),doneAction:2);
	sig = Blip.ar(freqVar,Line.kr(1,nharm,atk+rel));
	sig = sig * env * amp * lev;
	// pan within a small movable range (of 0.7)
	panRand = LFNoise1.kr(0.5).range(-0.3,0.3);
	sig = Pan2.ar(sig,panRand+pan);
	Out.ar(out,sig);
}).add;



//VarSaw.ar SynthDef
SynthDef(\varSaw, {
	arg atk=0.01, dec=0.2, susL=0.3, susT=0.5, rel=2, freq=220, width=0.5, amp=0.1, lev=1, out=0, pan=0.0, freqOff=2.0, freqRate=5, freqDif=2.0;
	var sigStereo, sigMono, sigMix, env, freqVar, autoPan;

	// Frequency offset using sine wave like vibrato
	freqVar = SinOsc.kr(freqRate,mul:freqOff,add:freq);

	// Envelope
	env = EnvGen.kr(Env.new([0,1,susL,susL,0],[atk,dec,susT,rel]),doneAction:2);

	sigStereo = {VarSaw.ar(freqVar!2,width:width)};
	sigStereo = sigStereo * env * amp/4 * lev;
	// has difference in frequency from sigStereo by freqDif
	sigMono = VarSaw.ar(freqVar-freqDif,width:width);
	sigMono = sigMono * env * (amp*0.75) * SinOsc.ar(8) * lev;
	//just one voice moves. other is stereo
	sigMono = Pan2.ar(sigMono,pan);
	sigMix = Splay.ar([sigStereo,sigMono]);
	Out.ar(out,sigMix);

}).add;

) // <<=============================================== LOAD SYNTHS HERE ==============================

//TEST
(
Synth(\blip, [
	\nharm, 50,
	\pan, -0.7]);
)
(
Synth(\varSaw, [
	\width, 0.5,
	\pan, -1.0,
	\freqOff, 10.0,
]);
)

//PART 2. Create Pbinds to control each SynthDef
//-Each Pbind must address all of the controllable parameters from PART 1.
//-Do not hardwire any parameters. Each should have some form of contrained randomness. (Use the various data patterns you've learned to accomplish this: Pseq,Prand,Pxrand,Pwrand,Pexprand,and Pwhite.)
//-Use degree and scale for handling pitch in each of the Pbinds.
//-Create global variables to handle changing scales (Scale.major, Scale.minor, etc.). Save the scale possibilities in an array.
//-Wrap the degree parameter, scale parameter, and a 'lev' parameter into a 'Pdefn' for each Pbind. (The user should be able to change scales, degree patterns, and the output level during performance. The output level will be controlled by a Slider for each instrument in the GUI.)
//-Create numerous scale and pitch-degree pattern possibilities. (You must include at least FIVE. Each can be triggered by a button in the GUI.)
//-You can create chords using arrays of pitches within your larger degree array... [[0,2,4],4,5,6,7] would add tonic triad on the first degree of the scale being used.
//-Clearly comment all of your Pbinds and what you're attempting to do with each pattern parameter.
//-Remember to use the 'quant' message to ensure all of your Pbinds are synced.
//It should look like this: ~blip.play(quant:1)

//LOAD ALL OF THIS FIRST // CLOSING BRACKET ON LINE 279
(
//scale global variable declarations go here:

// tempo clock for quant
t = TempoClock.new(1);
/**** KNOBS ****/
// blip synth knobs: atk, rel, nharm, pan, freqOff, freqRate, busy-ness
~blipKnobs = Array.fill(7,{nil});
// varSaw synth knobs: atk, dec, susL, susT, rel, width, pan, freqOff, freqRate, busy
~varSawKnobs = Array.fill(10,{nil});

// global knobs
~globalTempo = nil;
~globalRoot = nil;

/**** BUTTONS ****/
// blip buttons
~blipOnOff = nil;
~blipAutoPan = nil;
~blipAutoRel = nil;
~blipAutoNH = nil;
~blipPanLoc = 0.0;
~blipPanDir = 0; // 0 = left, 1 = right
~blipDegButtons = Array.fill(6,{nil});
// varSaw buttons
~varSawOnOff = nil;
~varSawAutoPan = nil;
~varSawRandEnv = nil;
~varSawAutoWidth = nil;
~varSawPanLoc = 0.0;
~varSawPanDir = 0; // 0 = left, 1 = right
~varSawDegButtons = Array.fill(6,{nil});
// global buttons
~globalOnOff = nil;
~scaleButtons = Array.fill(8,{nil});
~instructionsBtn = nil;
/**** SLIDERS ****/
~blipLevel = nil;
~varSawLevel = nil;

/**** TEXT ****/
~globalTempoText = nil;
~globalRootMenu = nil;
~globalRoots = ["C","C#/Db","D","D#/Eb","E","F","F#/Gb","G","G#/Ab","A","A#/Bb","B"];


/**** SCALES ****/
~scales = [Scale.neapolitanMajor,Scale.harmonicMinor,Scale.spanish,Scale.bartok,Scale.iwato,
	Scale.prometheus,Scale.scriabin,Scale.whole];
//Scale.directory;
~scaleMenu = nil;

/**** DEGREE PATTERNS ****/
~degBlip = [
	[0,2,4,7,1,3,4,6], // I and V43 chords
	[[0,2],4,7,4,[1,3],4,6,4], // I and ii seven chords with diads
	[[5,7,9],0,2,4,[0,3,5],3,5,6], // vi and IV chords
	[[1,3,5],7,5,3,[4,6],[3,5],4,3], // ii leading back to something else?
	[[1,4,6],4,1,[5,7,2],2,5,7,5], // V to vi
	[5,4,3,[3,5],3,2,1,[1,3]] // IV and I
];

~degVarSaw = [
	[0,4,1,4],
	[0,[4,7],1,[4,6]],
	[5,[0,2],7,[3,5]],
	[[1,5],3,[4,6],1],
	[1,[4,6],[5,7],2],
	[[0,3,5],7,[0,2],4,]
];

/**** DEFAULT BUSY ARRAY ****/
~busyDefault = [0,1];

/**** FONTS ****/
~title = Font("Helvetica",24,bold:true);
~header = Font("Helvetica",18,bold:true);
~body = Font("Helvetica", 11);

// Instructions window
~iWin = nil;

/**** OCTAVER ****/
~octDefault = [5,6];
~blipOctLo = nil;
~blipOctHi = nil;
~varSawOctLo = nil;
~varSawOctHi = nil;

/*****PBinds*****/

//Blip.ar Pbind
~mtBlip = Pbind(
	\instrument, \blip,
	\scale, Pdefn(\globalScale, ~scales[0]), // array of scales
	\degree, Pdefn(\degBlip, Pseq(~degBlip[0], inf)), // Array of 6 degree patterns
	\root, Pdefn(\globalRoot, 0), // root is changeable with global knob
	\octave, Pdefn(\octBlip, Prand(~octDefault, inf)), // changeable two-octave range per synth (up to two times each direction)
	// Rests are defining factor regarding busy-ness. More busy = more weight towards
	// playing the actual note rather than a rest (i.e. weightedArray[0] is busy, weightedArray[1] is not
	\dur, Pxrand([
		Pseq([
			1.0,
			Pwrand([1.0/3, Rest(1.0/3)], Pdefn(\busyBlip,[0,1])),
			Pwrand([1.0/3, Rest(1.0/3)], Pdefn(\busyBlip,[0,1])),
			Pwrand([1.0/3, Rest(1.0/3)], Pdefn(\busyBlip,[0,1])),
		]),
		Pwrand([0.5, Rest(0.5)], Pdefn(\busyBlip,[0,1]),4),
		Pseq([
			Pwrand([1.5, Rest(1.5)], Pdefn(\busyBlip,[0,1])),
			0.5,
			1.0,
			Pwrand([1.0, Rest(1.0)], Pdefn(\busyBlip,[0,1])),
		]),
		Prand([
			Pwrand([0.25, Rest(0.25)], Pdefn(\busyBlip,[0,1])),
			0.25
		],8),
		Pseq([
			1.0,
			Pwrand([0.5, Rest(0.5)], Pdefn(\busyBlip,[0,1])),
			Pwrand([0.5, Rest(0.5)], Pdefn(\busyBlip,[0,1])),
			1.0/5,1.0/5,1.0/5,1.0/5,1.0/5
		])
	], inf),
	// all adjustable with knobs
	\atk, Pdefn(\atkBlip, 0.01),
	\rel, Pdefn(\relBlip, 2.0),
	\nharm, Pdefn(\nharmBlip, 20), // max number of harmonics. in synth def, goes from 1 harmonic to nharm harmonics using Line.kr
	\pan, Pdefn(\panBlip, (-1.0)), // also features pan that moves across stereo field
	\freqOff, Pdefn(\freqOffBlip, 0.1), //frequency offset
	\freqRate, Pdefn(\freqRateBlip, 5.0), // rate at which frequency fluctuates
	\lev, Pdefn(\levBlip, 1.0), // controlled with level slider
	\amp, Pexprand(0.1,0.4,inf), // varying amplitude
	\stretch, Pdefn(\globalTempo, 1.0), // global tempo knob
);


//VarSaw.ar Pbind
~mtVarSaw = Pbind(
	\instrument, \varSaw,
	\scale, Pdefn(\globalScale, ~scales[0]), // array of scales
	\degree, Pdefn(\degVarSaw, Pseq(~degVarSaw[0],inf)), // array of 6 degree patterns
	\root, Pdefn(\globalRoot, 0), // root is changeable with global knob
	\octave, Pdefn(\octVarSaw, Prand(~octDefault, inf)), // changeable two-octave range per synth (up to two times each direction)
	// Rests are defining factor regarding busy-ness. More busy = more weight towards
	// playing the actual note rather than a rest (i.e. weightedArray[0] is busy, weightedArray[1] is not
	\dur, Pxrand([
		Prand([
			1.0,
			Pwrand([1.0, Rest(1.0)], Pdefn(\busyVarSaw,[0,1])),
		],2),
		Prand([
			1.0/3,
			Pwrand([1.0/3, Rest(1.0/3)], Pdefn(\busyVarSaw,[0,1])),
		],6),
		Pseq([
			Pwrand([1.5, Rest(1.5)], Pdefn(\busyVarSaw,[0,1])),
			0.5,
			Pwrand([1.0, Rest(1.0)], Pdefn(\busyVarSaw,[0,1])),
			1.0,
		]),
		Prand([
			Pwrand([0.25, Rest(0.25)], Pdefn(\busyVarSaw,[0,1])),
			0.25
		],8),
		Pwrand([0.5, Rest(0.5)], Pdefn(\busyBlip,[0,1]),4),
	],inf),
	// all adjustable with knobs
	\atk, Pdefn(\atkSaw, 0.01),
	\dec, Pdefn(\decSaw, 0.1),
	\susL, Pdefn(\susLSaw, 0.3),
	\susT, Pdefn(\susTSaw, 0.5),
	\rel, Pdefn(\relSaw, 2.0),
	\width, Pdefn(\widthSaw, 0.5),
	\pan, Pdefn(\panSaw, (1.0)), // also features pan that moves across stereo field
	\freqOff, Pdefn(\freqOffSaw, 2.0), //frequency offset
	\freqRate, Pdefn(\freqRateSaw, 5.0), // rate at which frequency fluctuates
	\lev, Pdefn(\levSaw, 1.0), // controlled with level slider
	\amp, Pexprand(0.1,0.4,inf), // varying amplitude
	\stretch, Pdefn(\globalTempo, 1.0), // global tempo knob
);


) // <<=============================================== LOAD VARS AND PBINDS HERE ======================

x = ~mtBlip.play(quant:1);
Pdefn(\globalScale, ~scales[1]);
Pdefn(\globalRoot, 2);
x = ~mtVarSaw.play(quant:1);
x.stop;
Pdefn(\degVarSaw, Pseq(~degVarSaw[4], inf));
Pdefn(\busySaw,[0.4,0.3,0.1,0.1,0.05,0.05]);


//PART 3. Create a GUI which can control the following:
//-Be able to start and stop each of the 2 Pbinds (I would recommend using an 'if' statement in this case.)
//-Be able to change the global pitch scale (at least 2 scale choices (major/minor would work))
//-Button(s) to change the pitch (degree) pattern within each Pbind
//-Be able to change the volume of each SynthDef (2 sliders, 'lev' argument in each SynthDef and their Pbinds)
//-Make your GUI clean, colorful, intuitive and inviting, and be sure to implement StaticText to label sections of your GUI with text.
//-Consider dividing sections of your GUI with panels (CompositeView.new)

/*****GUI CODE GOES HERE*****/ // CLOSING BRACKET ON LINE 1340
(
if ((w == nil).not) {
	w.close; // check if w has anything. If yes, close. If not, do not try closing window
};
if ((~iWin == nil).not) {
	~iWin.close;
};
w = Window.new("MIDTERM GUI", Rect(700,100,640,790), resizable:false);
w.front;
w.alwaysOnTop = true;
// padding
w.view.decorator = FlowLayout(w.view.bounds,10@10,10@10);

/******** GLOBAL PANEL ********/
~globalPanel = CompositeView(w,620@210)
.background_(Color.fromHexString("#EFEFBB"));
~globalPanel.decorator = FlowLayout(~globalPanel.bounds,20@10,10@5);

// Instructions button and window
~instructionsBtn = Button(~globalPanel,30@30)
.states_([
	["?", Color.black],
	["?", Color.black, Color.fromHexString("FFC12E")]
])
.action_({
	arg btn;
	if (btn.value == 1) {
		// Open an Instructions Window
		~iWin = Window.new("INSTRUCTIONS", Rect(100,300,400,400), resizable:false, scroll:true)
		// Closing the instruction window frees the instruction button from "opened" state
		.onClose_({~instructionsBtn.value_(0)});
		~iWin.front;
		~iWin.view.decorator = FlowLayout(~iWin.view.bounds,10@10,10@10);
		// Header
		StaticText(~iWin, 380@30)
		.string_("This patch has no name") // I can't think of a title
		.font_(~title);
		// Intro
		StaticText(~iWin, 380@120)
		.string_("This patch consists of two synths: a blip synth and a varsaw synth. Each comes with controls that manipulate their respective envelopes, as well as controls for varying frequency offset (FreqO), rate of varying frequency (FreqR), pan location (Pan), and busy-ness of notes (Busy). Hovering over the titles of each component will reveal a short description of its function.

To begin, turn on either of the synths.")
		.font_(~body);
		// Global Controls Header
		StaticText(~iWin, 380@30)
		.string_("Global Controls")
		.font_(~header);
		// Global Controls Instructions
		StaticText(~iWin, 380@110)
		.string_("- Scale: Controls the scale for both synths.
- Degree Patterns: Changes the pitch collection for both synths.
- Tempo: Changes the global tempo. Tempo can be changed by dialing the knob or inputting a value into the number box. Min: 30 bpm, Max: 200 bpm.
- Root: Changes the root/key of the scale.
- Power: Turns off both synths. To turn on, turn on either synth.
- Reset: Resets all values in global controls, blip synth, and varsaw synth to default values and turns everything off.")
		.font_(~body);
		// Blip Synth Header
		StaticText(~iWin,380@30)
		.string_("Blip Synth")
		.font_(~header);
		// Blip Synth Instructions
		StaticText(~iWin, 380@330)
		.string_("- Synth Controls: Blip is a band limited impulse oscillator and utilizes a customizable percussion envelope.
--- Atk: Changes the attack of the envelope.
--- Rel: Changes the release of the envelope.
--- nharm: Changes the maximum number of harmonics.
--- FreqO: Changes the amount of offset for varying frequency.
--- FreqR: Changes the rate at which frequency is varied.
--- Pan: Controls pan location.
--- Busy: Controls the 'busy-ness' of the pattern.

- Automation:
--- Rel: Continuously generates random values for the envelope release.
--- NHarm: Continuously generates random values for the maximum number of harmonics.
--- Pan: Automatically pans the synth back and forth across the stereo field.

- Octave: Changes the two-octave range of the synth up to 2 times in each direction.
--- >: Moves an octave higher. Max: 2 octaves.
--- <: Moves an octave lower. Max: 2 octaves.

- Level: Controls the gain of the synth.
- Power: Turns the synth on/off.
- Reset: Turns the synth off and resets all control values to default.")
		.font_(~body);
		// VarSaw Synth Header
		StaticText(~iWin,380@30)
		.string_("VarSaw Synth")
		.font_(~header);
		// VarSaw Synth Instructions
		StaticText(~iWin, 380@340)
		.string_("- Synth Controls: VarSaw is a sawtooth-triangle oscillator with variable duty and utilizes a customizable segmented envelope and ring modulation.
--- Atk: Changes the attack of the envelope.
--- Dec: Changes the decay of the envelope.
--- SusL: Sustain Level. Changes the level at which the envelope will sustain.
--- SusT: Sustain Time. Changes the time that the envelope will sustain.
--- Rel: Changes the release of the envelope.
--- Width: Changes the duty cycle.
--- FreqO: Changes the amount of offset for varying frequency.
--- FreqR: Changes the rate at which frequency is varied.
--- Pan: Controls pan location.
--- Busy: Controls the 'busy-ness' of the pattern.

- Automation:
--- Rand: Generates random values for all knobs except for Pan and Busy.
--- Width: Continuously generates random values for the duty cycle.
--- Pan: Automatically pans the synth back and forth across the stereo field.

- Octave: Changes the two-octave range of the synth up to 2 times in each direction.
--- >: Moves an octave higher. Max: 2 octaves.
--- <: Moves an octave lower. Max: 2 octaves.

- Level: Controls the gain of the synth.
- Power: Turns the synth on/off.
- Reset: Turns the synth off and resets all control values to default.")
		.font_(~body);
	} {
		// closes the instruction window
		~iWin.close;
	}
})
.value_(0)
.toolTip_("Instructions");

// GLOBAL CONTROLS TITLE
StaticText(~globalPanel, 500@30)
.string_("GLOBAL CONTROLS")
.font_(Font("Helvetica",18,bold:true))
.align_(\center);

/******** Scale menu layout ********/
~scaleMenuPanel = CompositeView(~globalPanel, 130@90);
~scaleMenuPanel.decorator = FlowLayout(~scaleMenuPanel.bounds,0@0,5@5);

// SPACER
Button(~scaleMenuPanel, 130@25)
.visible_(false);

// SCALE TITLE
StaticText(~scaleMenuPanel, 130@20)
.string_("SCALE")
.font_(Font("Helvetica",10,bold:true))
.align_(\center)
.toolTip_("Controls the scale for both synths");

// SCALE POPUP MENU
~scaleMenu = PopUpMenu(~scaleMenuPanel, 130@20)
.items_([
	/*
	~scales = [Scale.neapolitanMajor,Scale.romanianMinor,Scale.spanish,Scale.zhi,Scale.iwato,
	Scale.prometheus,Scale.scriabin,Scale.whole];
	*/
	"Neapolitan Major",
	"Romanian Minor",
	"Spanish",
	"Zhi",
	"Iwato",
	"Prometheus",
	"Scriabin",
	"Whole"
])
.action_({
	arg m;
	Pdefn(\globalScale, ~scales[m.value])
})
.valueAction_(0);

/******** SCALE DEGREES ********/
~degreeControls = CompositeView(~globalPanel, 180@120);
~degreeControls.decorator = FlowLayout(~degreeControls.bounds,25@0,5@5);

// SCALE DEGREE TITLE
StaticText(~degreeControls, 130@20)
.string_("DEGREE PATTERNS")
.font_(Font("Helvetica",10,bold:true))
.align_(\center)
.toolTip_("Changes the pitch collections for both synths");

// create a button for each pitch collection
6.do{
	arg i;
	Button(~degreeControls,40@40)
	.string_(i.asHexString(1)) //button labeled with index number with only one digit
	.action_({
		arg btn;
		// Changes degree patterns for both synths using button index as degree pattern array index
		Pdefn(\degBlip, Pseq(~degBlip[btn.string.asInteger], inf));
		Pdefn(\degVarSaw, Pseq(~degVarSaw[btn.string.asInteger], inf));
	})
};

/******** GLOBAL KNOBS ********/
~globalKnobPanel = CompositeView(~globalPanel, 60@150);
~globalKnobPanel.decorator = FlowLayout(~globalKnobPanel.bounds, 0@5, 5@5);


/******** GLOBAL TEMPO ********/
~globalTempoPanel = CompositeView(~globalKnobPanel, 60@70);
~globalTempoPanel.decorator = FlowLayout(~globalTempoPanel.bounds, 0@0, 5@5);

// TEMPO TITLE
StaticText(~globalTempoPanel, 50@10)
.string_("TEMPO")
.font_(Font("Helvetica",10,bold:true))
.align_(\center)
.toolTip_("Changes the global tempo");

// TEMPO KNOB
~globalTempo = Knob(~globalTempoPanel, 50@50)
.action_({
	arg kn, tempo;
	tempo = kn.value.linexp(0.001,1.0,2.0,0.3);
	Pdefn(\globalTempo, tempo);
	~globalTempoText.value_((60/tempo).floor);
})
.value_(0.36600276149958) // calculated value for 60 bpm to avoid looping valueAction between numberbox and knob
.background_(Color.rand)
.mode_(\vert);


/******** GLOBAL ROOT ********/
~globalRootPanel = CompositeView(~globalKnobPanel, 60@70);
~globalRootPanel.decorator = FlowLayout(~globalRootPanel.bounds, 0@0, 5@5);

// ROOT TITLE
StaticText(~globalRootPanel, 50@10)
.string_("ROOT")
.font_(Font("Helvetica",10,bold:true))
.align_(\center)
.toolTip_("Changes the root/key of the scale");

// ROOT KNOB
~globalRoot = Knob(~globalRootPanel, 50@50)
.action_({
	arg kn,root;
	// Linear stepping (using floor) to match with drop down menu indexes
	root = kn.value.linlin(0.001,1.0,0.1,11.0).floor;
	// Change root in pbind
	Pdefn(\globalRoot, root);
	// Automatically change value in drop down menu based on knob value
	~globalRootMenu.value_(root);
})
.background_(Color.rand)
.mode_(\vert);

/******** GLOBAL TEXT FIELDS ********/
~globalTextPanel = CompositeView(~globalPanel, 60@160);
~globalTextPanel.decorator = FlowLayout(~globalTextPanel.bounds, 0@35, 0@55);

// Tempo text
~globalTempoText = NumberBox(~globalTextPanel, 60@20)
.action_({
	arg t,tempo;
	// Max value 200 bpm, min value 30 bpm
	// if input is higher/lower than max/min, change value to max/min
	tempo = t.value.asInteger;
	if (tempo > 200.0) {
		tempo = 200.0;
		~globalTempoText.value_(200.0);
	};
	if (tempo < 30.0) {
		tempo = 30.0;
		~globalTempoText.value_(30.0);
	};
	tempo = (60.0/tempo);

	Pdefn(\globalTempo,(tempo));
	~globalTempo.value_(tempo.explin(0.3,2.0,1.0,0.001));
})
.valueAction_(60.0)
.toolTip_("Input number and press <enter/return>. Min: 30 bpm, Max: 200 bpm");

// ROOT DROP DOWN MENU
~globalRootMenu = PopUpMenu(~globalTextPanel, 60@20)
.items_(~globalRoots)
.action_({
	arg i;
	~globalRoot.valueAction_(i.value.linlin(0.0,11.0,0.001,1.0));
})
.value_(0);

/******** GLOBAL RIGHT BUTTONS ********/
~globalButtonPanel = CompositeView(~globalPanel, 110@210);
~globalButtonPanel.decorator = FlowLayout(~globalButtonPanel.bounds, 30@0, 0@5);

// GLOBAL POWER TITLE
StaticText(~globalButtonPanel, 60@10)
.string_("POWER")
.font_(Font("Helvetica",10,bold:true))
.align_(\center);

// ON/OFF button global
~globalOnOff = Button(~globalButtonPanel, 60@60)
.action_({
	arg btn;
	if (btn.value == 0) {
		// Turn off both synths through their respective power buttons
		~blipOnOff.valueAction_(0);
		~varSawOnOff.valueAction_(0);
	} {
		// Only turning on the synths will turn on global on/off
		btn.value_(0);
	}
})
.states_([
	["OFF", Color.black, Color.red],
	["ON", Color.black, Color.green],
])
.toolTip_("Turns off both synths. To turn on, turn on either synth");

// GLOBAL RESET BUTTON
Button(~globalButtonPanel, 60@60)
.action_({
	// reset all knobs to default value 0.5
	7.do{
		arg i;
		~blipKnobs[i].valueAction_(0.5);
	};
	// Reset all knobs to default value of 0.5
	10.do{
		arg i;
		~varSawKnobs[i].valueAction_(0.5);
	};
	// Turn off synth which also turns off other automation
	~blipReset.valueAction_(0);
	~varSawReset.valueAction_(0);
	~globalOnOff.valueAction_(0);
	~globalTempoText.valueAction_(60);
	~globalRoot.valueAction_(0);
	~scaleMenu.valueAction_(0);
})
.states_([
	["RESET", Color.black, Color.fromHexString("#FEB9FF")]
])
.toolTip_("Resets all values and turns synths off");

/************************** BLIP SYNTH **************************/

~blipPanel = CompositeView(w,620@270)
.background_(Color.fromHexString("#CAEFBB"));
~blipPanel.decorator = FlowLayout(~blipPanel.bounds,20@10,10@5);

// Blip Synth Title
StaticText(~blipPanel, 580@30)
.string_("BLIP SYNTH")
.font_(Font("Helvetica",18,bold:true))
.align_(\center);

/******** BLIP LEFT HALF ********/
~blipLeftPanel = CompositeView(~blipPanel, 380@200);
~blipLeftPanel.decorator = FlowLayout(~blipLeftPanel.bounds,0@0,0@5);

/******** BLIP ENV ********/
~blipEnvPanel = CompositeView(~blipLeftPanel, 380@115);
~blipEnvPanel.decorator = FlowLayout(~blipEnvPanel.bounds,0@5,10@5);

// Blip Env Controls label
StaticText(~blipEnvPanel, 380@20)
.string_("SYNTH CONTROLS")
.font_(Font("Helvetica",10,bold:true))
.align_(\center);

// Blip synth knobs and labels
7.do{
	arg i;
	// blip knob labels
	StaticText(~blipEnvPanel, 40@40).string_(
		// blip synth knobs: atk, rel, nharm, freqOff, freqRate, pan, busy-ness
		case
		{i == 0} {"Atk"}
		{i == 1} {"Rel"}
		{i == 2} {"nharm"}
		{i == 3} {"FreqO"}
		{i == 4} {"FreqR"}
		{i == 5} {"Pan"}
		{i == 6} {"Busy"}
	)
	.font_(Font("Helvetica",10,bold:true))
	.stringColor_(Color.grey)
	.align_(\right)
	.toolTip_(
		case
		{i == 0} {"Changes the attack of the envelope"}
		{i == 1} {"Changes the release of the envelope"}
		{i == 2} {"Changes the maximum number of harmonics"}
		{i == 3} {"Changes the amount of offset for varying frequency"}
		{i == 4} {"Changes the rate at which frequency is varied"}
		{i == 5} {"Controls pan location"}
		{i == 6} {"Controls the 'busy-ness' of the pattern"}
	);

	// populate knobs array
	~blipKnobs[i] = Knob(~blipEnvPanel, 30@30)
	.action_({
		arg kn;
		case
		// blip synth knobs: atk, rel, nharm, pan, freqOff, freqRate, busy-ness
		{i == 0} {Pdefn(\atkBlip, kn.value.linexp(0.0001,1.0,0.01,2))}
		{i == 1} {Pdefn(\relBlip, kn.value.linexp(0.0001,1.0,0.1,5))}
		{i == 2} {Pdefn(\nharmBlip, kn.value.linexp(0.0001,1.0,5,50))}
		{i == 3} {Pdefn(\freqOffBlip, kn.value.linexp(0.0001,1.0,0.001,0.6))}
		{i == 4} {Pdefn(\freqRateBlip, kn.value.linexp(0.0001,1.0,1.0,20.0))}
		{i == 5} {Pdefn(\panBlip, ((kn.value-0.5)*2))}
		{i == 6} {Pdefn(\busyBlip, [
			~busyDefault[0] + kn.value,
			~busyDefault[1] - kn.value
		])}
	})
	.background_(Color.rand)
	.valueAction_(0.5)
	.mode_(\vert);
};

/******** AUTOMATION BUTTONS ********/
~blipAutoPanel = CompositeView(~blipLeftPanel, 200@80);
~blipAutoPanel.decorator = FlowLayout(~blipAutoPanel.bounds, 10@0, 10@0);

// Automation Title
StaticText(~blipAutoPanel, 180@30)
.string_("AUTOMATION")
.font_(Font("Helvetica",10,bold:true))
.align_(\center);

/******** BLIP AUTO REL ********/
~blipAutoRelRtn = Task ({
	{
		var num;
		num = rrand(0.0,1.0);
		~blipKnobs[1].valueAction_(num);
		0.25.wait;
	}.loop;
},AppClock);

~blipAutoRel = Button(~blipAutoPanel, 50@50)
.action_({
	arg btn;
	if (btn.value == 1) {
		~blipAutoRelRtn.play;
	} {
		~blipAutoRelRtn.pause;
	}
})
.states_([
	["REL", Color.black,],
	["REL", Color.black, Color.yellow]
])
.toolTip_("Generate random values for envelope release");

/******** BLIP AUTO NHARM ********/
~blipAutoNHRtn = Task ({
	{
		var num;
		num = rrand(0.0,1.0);
		~blipKnobs[2].valueAction_(num);
		0.25.wait;
	}.loop;
},AppClock);

~blipAutoNH = Button(~blipAutoPanel, 50@50)
.action_({
	arg btn;
	if (btn.value == 1) {
		~blipAutoNHRtn.play;
	} {
		~blipAutoNHRtn.pause;
	}
})
.states_([
	["NHARM", Color.black,],
	["NHARM", Color.black, Color.magenta]
])
.toolTip_("Generate random values for max number of harmonics");

/******** BLIP AUTO PAN ********/
// Blip Auto Pan Routine (0 is left, 1 is right)
~blipAutoPanRtn = Task({
	{
		if (~blipPanDir == 0) {
			~blipPanLoc = ~blipPanLoc - 0.05;
		} {
			~blipPanLoc = ~blipPanLoc + 0.05;
		};
		// Make sure the values don't go past -1 or 1
		// Change direction of the panning once bound is reached
		if (~blipPanLoc < -1) {
			~blipPanLoc = -1;
			~blipPanDir = 1;
		};
		if (~blipPanLoc > 1) {
			~blipPanLoc = 1;
			~blipPanDir = 0;
		};

		// Set value of knob with adjusted value
		~blipKnobs[5].valueAction_((~blipPanLoc+1.0)/2.0);
		0.05.wait;
	}.loop;
},AppClock);


// Auto pan button
~blipAutoPan = Button(~blipAutoPanel, 50@50)
.action_({
	arg btn;
	if (btn.value == 1) {
		~blipAutoPanRtn.play;
	} {
		~blipAutoPanRtn.pause;
	}
})
.states_([
	["PAN", Color.black,],
	["PAN", Color.black, Color.cyan]
])
.toolTip_("Automatically pan the synth across the stereo field");


/******** BLIP OCTAVER ********/
~blipOctPanel = CompositeView(~blipLeftPanel, 180@80);
~blipOctPanel.decorator = FlowLayout(~blipOctPanel.bounds, 35@0, 10@0);

StaticText(~blipOctPanel, 115@30)
.string_("OCTAVE")
.font_(Font("Helvetica",10,bold:true))
.align_(\center)
.toolTip_("Changes blip octave");

// Lower octave button
~blipOctLo = Button(~blipOctPanel, 50@50)
.states_([
	["<", Color.black],
	["<", Color.black, Color.fromHexString("98CAFF")],
	["<", Color.black, Color.fromHexString("2B92FF")],
])
.action_({
	arg btn;
	case
	{btn.value == 0} {
		// if in state 2, stay in state 2
		// cannot reach state 0 unless using blipOctHi button
		btn.value_(2);
	}
	{btn.value == 1} {
		// base case: ~blipOctHi state 0 (not activated)
		if (~blipOctHi.value == 0) {
			Pdefn(\octBlip, Prand([~octDefault[0]-1, ~octDefault[1]-1], inf));
		};
		// ~blipOctHi in state 1 (one octave higher), bring back to default, ~blipOctHi.value = 0;
		if (~blipOctHi.value == 1) {
			Pdefn(\octBlip, Prand([~octDefault[0], ~octDefault[1]], inf));
			~blipOctHi.value_(0);
			//~blipOctLo stays at 0
			btn.value_(0);
		};
		// ~blipOctHi in state 2 (two octaves higher), bring back to oct higher, ~blipOctHi.value = 1
		if (~blipOctHi.value == 2) {
			Pdefn(\octBlip, Prand([~octDefault[0]+1, ~octDefault[1]+1], inf));
			~blipOctHi.value_(1);
			//~blipOctLo stays at 0
			btn.value_(0);
		};
	}
	{btn.value == 2} {
		// Only able to reach state 2 if ~blipOctHi.value == 0 so only one possibility
		// move down 2 octaves
		Pdefn(\octBlip, Prand([~octDefault[0]-2, ~octDefault[1]-2], inf));
	}
})
.value_(0);

// Raise octave button
~blipOctHi = Button(~blipOctPanel, 50@50)
.states_([
	[">", Color.black],
	[">", Color.black, Color.fromHexString("98CAFF")],
	[">", Color.black, Color.fromHexString("2B92FF")],
])
.action_({
	arg btn;
	case
	{btn.value == 0} {
		// if in state 2, stay in state 2
		// cannot reach state 0 unless using blipOctLo button
		btn.value_(2);
	}
	{btn.value == 1} {
		// base case: ~blipOctLo state 0 (not activated)
		if (~blipOctLo.value == 0) {
			Pdefn(\octBlip, Prand([~octDefault[0]+1, ~octDefault[1]+1], inf));
		};
		// ~blipOctLo in state 1 (one octave lower), bring back to default, ~blipOctLo.value = 0;
		if (~blipOctLo.value == 1) {
			Pdefn(\octBlip, Prand([~octDefault[0], ~octDefault[1]], inf));
			~blipOctLo.value_(0);
			//~blipOctHi stays at 0
			btn.value_(0);
		};
		// ~blipOctLo in state 2 (two octaves lower), bring back to oct lower, ~blipOctLo.value = 1
		if (~blipOctLo.value == 2) {
			Pdefn(\octBlip, Prand([~octDefault[0]-1, ~octDefault[1]-1], inf));
			~blipOctLo.value_(1);
			//~blipOctHi stays at 0
			btn.value_(0);
		};
	}
	{btn.value == 2} {
		// Only able to reach state 2 if ~blipOctLo.value == 0 so only one possibility
		// move down 2 octaves
		Pdefn(\octBlip, Prand([~octDefault[0]+2, ~octDefault[1]+2], inf));
	}
})
.value_(0);

/******** BLIP OTHER (RIGHT SIDE) CONTROLS ********/
~blipRightPanel = CompositeView(~blipPanel, 180@200);
~blipRightPanel.decorator = FlowLayout(~blipRightPanel.bounds,0@0,10@10);


// SPACER
Button(~blipRightPanel,40@50)
.visible_(false);


/******** BLIP LEVEL SLIDER ********/
~blipLevelPanel = CompositeView(~blipRightPanel, 50@210);
~blipLevelPanel.decorator = FlowLayout(~blipLevelPanel.bounds, 0@0, 0@0);

StaticText(~blipLevelPanel, 50@30)
.string_("LEVEL")
.font_(Font("Helvetica",10,bold:true))
.align_(\center)
.toolTip_("Controls blip gain");

~blipLevel = Slider(~blipLevelPanel, 50@170)
.action_({
	arg s;
	Pdefn(\levBlip, s.value);
})
.valueAction_(1.0)
.background_(Color.rand);

/******** BLIP RIGHT BUTTONS ********/
~blipButtonPanel = CompositeView(~blipRightPanel, 60@210);
~blipButtonPanel.decorator = FlowLayout(~blipButtonPanel.bounds, 0@0, 0@10);

StaticText(~blipButtonPanel, 60@30)
.string_("POWER")
.font_(Font("Helvetica",10,bold:true))
.align_(\center);

// ON/OFF button Blip
~blipOnOff = Button(~blipButtonPanel, 60@60)
.action_({
	arg btn;
	if (btn.value == 1) {
		// Turn on global on/off
		~globalOnOff.value_(1);
		x = ~mtBlip.play(t, quant:1);
	} {
		x.stop;
		// Turn off all other buttons
		~blipAutoPan.valueAction_(0);
		~blipAutoRel.valueAction_(0);
		~blipAutoNH.valueAction_(0);
	}
})
.states_([
	["OFF", Color.black, Color.red],
	["ON", Color.black, Color.green],
])
.toolTip_("Turns blip synth on/off");

// RESET BUTTON
~blipReset = Button(~blipButtonPanel, 60@60)
.action_({
	// Reset all knobs to default value of 0.5
	7.do{
		arg i;
		~blipKnobs[i].valueAction_(0.5);
	};
	// Turn off synth which also turns off other automation
	~blipOnOff.valueAction_(0);
	~blipLevel.valueAction_(1.0);

	// Reset octaver
	~blipOctLo.value_(0);
	~blipOctHi.value_(0);
	Pdefn(\octBlip, Prand(~octDefault, inf));
})
.states_([
	["RESET", Color.black, Color.fromHexString("#FEB9FF")]
])
.toolTip_("Resets all values and turns blip synth off");


/************************** VARSAW **************************/

~varSawPanel = CompositeView(w,620@270)
.background_(Color.fromHexString("#BBEFE1"));
~varSawPanel.decorator = FlowLayout(~varSawPanel.bounds,20@10,0@5);

// VarSaw Synth Title
StaticText(~varSawPanel, 580@30)
.string_("VARSAW SYNTH")
.font_(Font("Helvetica",18,bold:true))
.align_(\center);

/******** VARSAW LEFT HALF ********/
~varSawLeftPanel = CompositeView(~varSawPanel, 420@200);
~varSawLeftPanel.decorator = FlowLayout(~varSawLeftPanel.bounds,0@0,0@5);

/******** VARSAW ENV ********/
~varSawEnvPanel = CompositeView(~varSawLeftPanel, 420@115);
~varSawEnvPanel.decorator = FlowLayout(~varSawEnvPanel.bounds,0@5,10@5);

// VarSaw Env Controls label
StaticText(~varSawEnvPanel, 420@20)
.string_("SYNTH CONTROLS")
.font_(Font("Helvetica",10,bold:true))
.align_(\center);

// VarSaw synth knobs and labels
10.do{
	arg i;
	StaticText(~varSawEnvPanel, 30@40).string_(
		// varsaw knobs: atk dec susl sust rel eidth freqo freqr pan busy
		case
		{i == 0} {"Atk"}
		{i == 1} {"Dec"}
		{i == 2} {"SusL"}
		{i == 3} {"SusT"}
		{i == 4} {"Rel"}
		{i == 5} {"Width"}
		{i == 6} {"FreqO"}
		{i == 7} {"FreqR"}
		{i == 8} {"Pan"}
		{i == 9} {"Busy"}
	)
	.font_(Font("Helvetica",10,bold:true))
	.stringColor_(Color.grey)
	.align_(\right)
	.toolTip_(
		case
		{i == 0} {"Changes the attack of the envelope"}
		{i == 1} {"Changes the decay of the envelope"}
		{i == 2} {"Changes the sustain level of the envelope"}
		{i == 3} {"Changes the sustain time of the envelope"}
		{i == 4} {"Changes the release of the envelope"}
		{i == 5} {"Changes the duty cycle"}
		{i == 6} {"Changes the amount of offset for varying frequency"}
		{i == 7} {"Changes the rate at which frequency is varied"}
		{i == 8} {"Controls pan location"}
		{i == 9} {"Controls the 'busy-ness' of the pattern"}
	);

	~varSawKnobs[i] = Knob(~varSawEnvPanel, 30@30)
	.action_({
		arg kn;
		case
		// varsaw knobs: atk dec susl sust rel eidth freqo freqr pan busy
		{i == 0} {Pdefn(\atkSaw, kn.value.linexp(0.0001,1.0,0.01,2))}
		{i == 1} {Pdefn(\decSaw, kn.value.linexp(0.0001,1.0,0.1,3))}
		{i == 2} {Pdefn(\susLSaw, kn.value.linexp(0.0001,1.0,0.2,0.9))}
		{i == 3} {Pdefn(\susTSaw, kn.value.linexp(0.0001, 1.0,0.25,3))}
		{i == 4} {Pdefn(\relSaw, kn.value.linexp(0.0001,1.0,0.01,4))}
		{i == 5} {Pdefn(\widthSaw, kn.value/2)}
		{i == 6} {Pdefn(\freqOffSaw, kn.value.linexp(0.0001,1.0,0.001,8.0))}
		{i == 7} {Pdefn(\freqRateSaw, kn.value.linlin(0.0001,1.0,1.0,20.0))}
		{i == 8} {Pdefn(\panSaw, ((kn.value-0.5)*2))}
		{i == 9} {Pdefn(\busyVarSaw, [
			~busyDefault[0] + kn.value,
			~busyDefault[1] - kn.value
		])}
	})
	.background_(Color.rand)
	.valueAction_(0.5)
	.mode_(\vert);

};


/******** AUTOMATION BUTTONS ********/
~varSawAutoPanel = CompositeView(~varSawLeftPanel, 200@80);
~varSawAutoPanel.decorator = FlowLayout(~varSawAutoPanel.bounds, 10@0, 10@0);

// Automation Title
StaticText(~varSawAutoPanel, 180@30)
.string_("AUTOMATION")
.font_(Font("Helvetica",10,bold:true))
.align_(\center);

/******** VARSAW ENV RANDOM VALUES ********/
~varSawRandEnv = Button(~varSawAutoPanel, 50@50)
.action_({
	var num;
	8.do {
		arg i;
		num = rrand(0.0,1.0);
		~varSawKnobs[i].valueAction_(num);
	}
})
.states_([
	["RAND", Color.black,]
])
.toolTip_("One time: Generate random values for all knobs except pan and busy");

/******** VARSAW AUTO WIDTH ********/
~varSawAutoWidthRtn = Task ({
	{
		var num;
		num = rrand(0.0,1.0);
		~varSawKnobs[5].valueAction_(num);
		0.25.wait;
	}.loop;
},AppClock);

~varSawAutoWidth = Button(~varSawAutoPanel, 50@50)
.action_({
	arg btn;
	if (btn.value == 1) {
		~varSawAutoWidthRtn.play;
	} {
		~varSawAutoWidthRtn.pause;
	}
})
.states_([
	["WIDTH", Color.black,],
	["WIDTH", Color.black, Color.magenta]
])
.toolTip_("Generate random values for duty cycle");

/******** VARSAW AUTO PAN ********/
// VarSaw Auto Pan Routine (0 is left, 1 is right)
~varSawAutoPanRtn = Task({
	{
		if (~varSawPanDir == 0) {
			~varSawPanLoc = ~varSawPanLoc - 0.05;
		} {
			~varSawPanLoc = ~varSawPanLoc + 0.05;
		};

		// Make sure the values don't go past -1 or 1
		// Change direction of the panning once bound is reached
		if (~varSawPanLoc < -1) {
			~varSawPanLoc = -1;
			~varSawPanDir = 1;
		};
		if (~varSawPanLoc > 1) {
			~varSawPanLoc = 1;
			~varSawPanDir = 0;
		};

		// Set value of knob with adjusted value
		~varSawKnobs[8].valueAction_((~varSawPanLoc+1.0)/2.0);
		0.05.wait;
	}.loop;
},AppClock);


// Auto pan button
~varSawAutoPan = Button(~varSawAutoPanel, 50@50)
.action_({
	arg btn;
	if (btn.value == 1) {
		~varSawAutoPanRtn.play;
	} {
		~varSawAutoPanRtn.pause;
	}
})
.states_([
	["PAN", Color.black,],
	["PAN", Color.black, Color.cyan]
])
.toolTip_("Automatically pan the synth across the stereo field");


/******** VARSAW OCTAVER ********/
~varSawOctPanel = CompositeView(~varSawLeftPanel, 180@80);
~varSawOctPanel.decorator = FlowLayout(~varSawOctPanel.bounds, 35@0, 10@0);

StaticText(~varSawOctPanel, 115@30)
.string_("OCTAVE")
.font_(Font("Helvetica",10,bold:true))
.align_(\center)
.toolTip_("Changes varsaw octave");

// Lower octave button
~varSawOctLo = Button(~varSawOctPanel, 50@50)
.states_([
	["<", Color.black],
	["<", Color.black, Color.fromHexString("98CAFF")],
	["<", Color.black, Color.fromHexString("2B92FF")],
])
.action_({
	arg btn;
	case
	{btn.value == 0} {
		// if in state 2, stay in state 2
		// cannot reach state 0 unless using varSawOctHi button
		btn.value_(2);
	}
	{btn.value == 1} {
		// base case: ~varSawOctHi state 0 (not activated)
		if (~varSawOctHi.value == 0) {
			Pdefn(\octVarSaw, Prand([~octDefault[0]-1, ~octDefault[1]-1], inf));
		};
		// ~varSawOctHi in state 1 (one octave higher), bring back to default, ~varSawOctHi.value = 0;
		if (~varSawOctHi.value == 1) {
			Pdefn(\octVarSaw, Prand([~octDefault[0], ~octDefault[1]], inf));
			~varSawOctHi.value_(0);
			//~varSawOctLo stays at 0
			btn.value_(0);
		};
		// ~varSawOctHi in state 2 (two octaves higher), bring back to oct higher, ~varSawOctHi.value = 1
		if (~varSawOctHi.value == 2) {
			Pdefn(\octVarSaw, Prand([~octDefault[0]+1, ~octDefault[1]+1], inf));
			~varSawOctHi.value_(1);
			//~varSawOctLo stays at 0
			btn.value_(0);
		};
	}
	{btn.value == 2} {
		// Only able to reach state 2 if ~varSawOctHi.value == 0 so only one possibility
		// move down 2 octaves
		Pdefn(\octVarSaw, Prand([~octDefault[0]-2, ~octDefault[1]-2], inf));
	}
})
.value_(0);

// Raise octave button
~varSawOctHi = Button(~varSawOctPanel, 50@50)
.states_([
	[">", Color.black],
	[">", Color.black, Color.fromHexString("98CAFF")],
	[">", Color.black, Color.fromHexString("2B92FF")],
])
.action_({
	arg btn;
	case
	{btn.value == 0} {
		// if in state 2, stay in state 2
		// cannot reach state 0 unless using varSawOctLo button
		btn.value_(2);
	}
	{btn.value == 1} {
		// base case: ~varSawOctLo state 0 (not activated)
		if (~varSawOctLo.value == 0) {
			Pdefn(\octVarSaw, Prand([~octDefault[0]+1, ~octDefault[1]+1], inf));
		};
		// ~varSawOctLo in state 1 (one octave lower), bring back to default, ~varSawOctLo.value = 0;
		if (~varSawOctLo.value == 1) {
			Pdefn(\octVarSaw, Prand([~octDefault[0], ~octDefault[1]], inf));
			~varSawOctLo.value_(0);
			//~varSawOctHi stays at 0
			btn.value_(0);
		};
		// ~varSawOctLo in state 2 (two octaves lower), bring back to oct lower, ~varSawOctLo.value = 1
		if (~varSawOctLo.value == 2) {
			Pdefn(\octVarSaw, Prand([~octDefault[0]-1, ~octDefault[1]-1], inf));
			~varSawOctLo.value_(1);
			//~varSawOctHi stays at 0
			btn.value_(0);
		};
	}
	{btn.value == 2} {
		// Only able to reach state 2 if ~varSawOctLo.value == 0 so only one possibility
		// move down 2 octaves
		Pdefn(\octVarSaw, Prand([~octDefault[0]+2, ~octDefault[1]+2], inf));
	}
})
.value_(0);

/******** VARSAW OTHER (RIGHT SIDE) CONTROLS ********/
~varSawRightPanel = CompositeView(~varSawPanel, 140@200);
~varSawRightPanel.decorator = FlowLayout(~varSawRightPanel.bounds,0@0,10@10);

/******** VARSAW LEVEL SLIDER ********/
~varSawLevelPanel = CompositeView(~varSawRightPanel, 70@210);
~varSawLevelPanel.decorator = FlowLayout(~varSawLevelPanel.bounds, 20@0, 0@0);

StaticText(~varSawLevelPanel, 50@30)
.string_("LEVEL")
.font_(Font("Helvetica",10,bold:true))
.align_(\center)
.toolTip_("Controls varsaw gain");

~varSawLevel = Slider(~varSawLevelPanel, 50@170)
.action_({
	arg s;
	Pdefn(\levSaw, s.value);
})
.valueAction_(1.0)
.background_(Color.rand);

/******** VARSAW RIGHT BUTTONS ********/
~varSawButtonPanel = CompositeView(~varSawRightPanel, 60@210);
~varSawButtonPanel.decorator = FlowLayout(~varSawButtonPanel.bounds, 0@0, 0@10);

StaticText(~varSawButtonPanel, 60@30)
.string_("POWER")
.font_(Font("Helvetica",10,bold:true))
.align_(\center);

// ON/OFF button VarSaw
~varSawOnOff = Button(~varSawButtonPanel, 60@60)
.action_({
	arg btn;
	if (btn.value == 1) {
		// turn on global on/off
		~globalOnOff.value_(1);
		y = ~mtVarSaw.play(t, quant:1);
	} {
		y.stop;
		// Turn off all other buttons
		~varSawAutoPan.valueAction_(0);
		~varSawAutoWidth.valueAction_(0);
	}
})
.states_([
	["OFF", Color.black, Color.red],
	["ON", Color.black, Color.green],
])
.toolTip_("Turns varsaw synth on/off");

// RESET BUTTON
~varSawReset = Button(~varSawButtonPanel, 60@60)
.action_({
	// Reset all knobs to default value of 0.5
	10.do{
		arg i;
		~varSawKnobs[i].valueAction_(0.5);
	};
	// Turn off synth which also turns off other automation
	~varSawOnOff.valueAction_(0);
	~varSawLevel.valueAction_(1.0);

	// Reset octaver
	~varSawOctLo.value_(0);
	~varSawOctHi.value_(0);
	Pdefn(\octVarSaw, Prand(~octDefault, inf));
})
.states_([
	["RESET", Color.black, Color.fromHexString("#FEB9FF")]
])
.toolTip_("Resets all values and turns varsaw synth off");

) // <<=============================================== LOAD GUI HERE ================================


//PART 4. Create detailed instructions and comments for performing with your Pattern Machine.


// See "?" button on top left corner of window. Also, hovering over titles of components gives
// short descriptions of their functions
// Closing brackets on lines: LINES 66, 279, 1344








//Extra Credit (5 pts. each):
//(1) Give your GUI the ability to change tempo using a knob (hints: Knob.new, should control the \stretch parameter)
//(2) Give one of your sounds (at a minimum) a "busy" knob to control the busyness of the pattern (hints: \dur parameter, knob controls a Pwrand)





