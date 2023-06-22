(


(
Ndef('granulate_input').addSpec(
	// \recLevel, [0,1],
	// \preLevel, [0,1],
	\feedback, [-2.0,2],
	\inAmp, \inAmp,
	\wet, \bipolar,
	\inputAmp, [0,30],
	\tFreqMF, [0,200],
	\tFreqMD, [0,200],
	\offsetMF, \widefreq,
	\offsetMD, [0.0,1],
	\rateMF, \widefreq,
	\rateMD, [0.0,1],
	\offset, [0.0,1],
	\rate, \bipolar,
	\tFreq, [1,22050, \exp],
	\overlap, [0.01,512.0, \exp],
	\grHpf, \freq,
	\grLpf, \freq,
	\wet, [0.0,1],
	\dry, [0.0,1],
	\outAmp, [0.0,4],
);
);

s.scope(index:2, numChannels: 2);
Ndef('granulate_input').clear;
	Ndef('granulate_input').ar(2);
Ndef('granulate_input').edit;


(
Ndef('granulate_input', {|
	input1=4, input2=5, recGate=1,
	inAmp=1, outAmp=1, overlap=3, tFreq=20, tFreqMF=0, tFreqMD=0,
	rate=1, rateMF=0, rateMD=0,
	offset = 0, offsetMF=0, offsetMD=0|

	var input;
	var gDur, readPos, signal, writePos, grained, balance;

	var t, bufFrames, bufRateScale;
	var buf, bufdur;

	var tFreqMod = {
		SinOsc.ar(tFreqMF, Rand(0.0,2pi)) * tFreqMD;
	};

	var rateMod = {
		SinOsc.ar(rateMF, Rand(0.0,2pi)).range(rateMD.neg, rateMD);
		// SinOsc.ar(rateMF, Rand(0.0,2pi)).range(0, rateMD);
	};

	var offsetMod = {
		SinOsc.ar(offsetMF, Rand(0.0,2pi)).range(0, offsetMD);
		// LFDNoise3.ar(offsetMF).range(0,offsetMD(0.0))
	};


	tFreq = tFreq + tFreqMod.dup;
	rate = rate - rateMod.dup;


	bufFrames = 2**16;
	buf = {LocalBuf(bufFrames).clear}!2;
	bufdur = BufDur.ir(buf);


	writePos = Phasor.ar( end: bufFrames );


	t = Impulse.ar(tFreq);


	readPos =
	writePos
	- 64 // looks like a controlblocksize ------ why?
	/ bufFrames
	- offset
	- offsetMod.dup;
	// readPos = readPos.clip( 0, bufFrames - 64 / bufFrames );

	readPos = Wrap.ar(readPos, 0, 1);

/*
	(
		offset * bufFrames + 64 / SampleRate.ir
	).poll(10, \delaytime);
*/



	grained = GrainBufJ.ar(
		numChannels:1,
		loop: 1,
		trigger:t,
		dur: overlap / tFreq,
		sndbuf: buf,
		rate: rate,
		pos: readPos,
		interp: 4,
		pan: 0,
		envbufnum:-1
	);


	grained  = HPF.ar( grained, \grHpf.kr(40) );
	grained  = LPF.ar( grained, \grLpf.kr(15000) );




	input = SoundIn.ar([input1,input2]) * inAmp * recGate;

	// writing granulated + input back to grain buffer
	buf.do { |b i|

		BufWr.ar(grained[i] * \feedback.kr(0.3) + input[i], b, writePos)

		// RecordBuf has an option to overdub, might be of any use for big mess
		// RecordBuf.ar(
		// 	grained[i] * \feedback.kr(0.3) + input[i],
		// 	b,
		// 	recLevel: \recLevel.kr(1),
		// 	preLevel: \preLevel.kr(0),
		// );

	};
	signal = Mix([
		grained * \wet.kr(1),
		input * \dry.kr(1)
	]) * outAmp;

	// signal.tanh
	Out.ar(0, signal.tanh);

}).play

);


MIDIIn.connectAll;

2.0.wait;


~overlap_spec = [0.01,5.0,\exp,0.001].asSpec;
~tfreq_spec = [22050,1,\exp,0.001].asSpec;
~offset_spec = [0.01,1,\linear,0.001].asSpec;

~ratemf_spec = [0.0,2000,\linear,0.001].asSpec;
~ratemd_spec = [0.0,1.0,\linear,0.001].asSpec;
~trigmf_spec = [0.01,200,\linear,0.001].asSpec;
~trigmd_spec = [0.01,200,\linear,0.001].asSpec;

MIDIdef.cc(\nanoKtest, {| val num chan src|
	[num,val].postln;

	case
	//button for changing recinput
	{ num == 16 }
	{
	if ( val == 0 , {
			"radio".postln;
			Ndef('granulate_input').set(\input1, 4, \input2, 5);
		}, {
		"guitar".postln;
			Ndef('granulate_input').set(\input1, 6, \input2, 7);
		});

	}
	//button for settings bar 4
	{ num == 17 }
	{	"settings bar 4".postln;

	Ndef('granulate_input').set('offset', 0.158, 'wet', 1.0, 'rate', 0.25035754779845, 'tFreq', 4.127, 'grLpf', 18851.464465481, 'input1', 4, 'rateMF', 220.472, 'tFreqMF', 7.884, 'tFreqMD', 0.01, 'input2', 5, 'rateMD', 0.0, 'overlap', 2.072, 'dry', 0.0, 'feedback', 0.64928932685149);

	}
	//button for switching rec on / off
	{ num == 24 }
	{
	if ( val == 0, {
			"recgate off".postln;
			Ndef('granulate_input').set(\recGate, 0);

		},
		{
			"recgate on".postln;
			Ndef('granulate_input').set(\recGate, 1);
		});

	}
	//granular
	{ num == 0 }
	{
		Ndef(\granulate_input).set(\dry, (val/127) , \wet, (1 - (val/127) ));
	}
	{ num == 32 } {
		Ndef(\granulate_input).set(\overlap, ~overlap_spec.map(val/127), \tFreq, ~tfreq_spec.map(val/127); ); }
	{ num == 33 } {
		Ndef(\granulate_input).set(\offset, ~offset_spec.map(val/127) ); }
	{ num == 34 } {
		Ndef(\granulate_input).set(\rateMF, ~ratemf_spec.map(val/127) ); }
	{ num == 35 } {
		Ndef(\granulate_input).set(\rateMD, ~ratemd_spec.map(val/127) ); }
	{ num == 36 } {
		Ndef(\granulate_input).set(\tFreqMF, ~trigmf_spec.map(val/127) ); }
	{ num == 37 } {
		Ndef(\granulate_input).set(\tFreqMD, ~trigmd_spec.map(val/127) ); };

});




)