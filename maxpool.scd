s.boot;
s.quit;

(
~poolSize=2;
~lpfs = {|inArray| (inArray.size-1).collect({|i| (inArray[i+1] + inArray[i])/2 })};
~hpfs = {|inArray| (inArray.size-1).collect({|i| (inArray[i]-inArray[i+1])/2})};
~convs=[~lpfs, ~hpfs];

~arraymax = { |ugenArray| ugenArray.inject(DC.kr(-1), {|runningMax, in| in.max(runningMax)})};

~maxpools = { |in|
	var pools = [[LPF,HPF].collect({|conv| (~poolSize).collect({|i|
		conv.ar(DelayN.ar(in,i*4/44100,i*4/44100))})})
	].postln;

	pools = Array.geom(6,2/44100,2).inject(pools, {|layers, period|
		var lastMax = layers.last.collect({|convs| ~arraymax.value(convs)});
		var history = PulseDivider.ar(Impulse.ar(1/period), ~poolSize+1, Array.series(~poolSize+1));
		var lastValues = lastMax.collect({|oneMax| Latch.ar(oneMax, history)}).postln;

		"period samples: ".post;
		(period*44100).postln;
		layers.add(lastValues.collect({ |lastValueIn, i|
			~convs[i].value(lastValueIn)}));
});
	pools.postln;

pools[pools.size-1] = A2K.kr(pools.last);

pools = Array.geom(14, 128/44100,2).inject(pools, {
	|layers, period|
		var lastMax = layers.last.collect({|convs| ~arraymax.value(convs)});
		var history = PulseDivider.kr(Impulse.kr(1/period), ~poolSize+1, Array.series(~poolSize+1));
		var lastValues = lastMax.collect({|oneMax| Latch.kr(oneMax, history)}).postln;

		"period samples: ".post;
		(period*44100).postln;
		layers.add(lastValues.collect({ |lastValueIn, i|
			~convs[i].value(lastValueIn)}));});
};

~logistic = { |ins|
	var activation = ins.distort.madd(0.5, 0.5);
	Poll.kr(Impulse.kr(1),~arraymax.value(activation), "max logistic activation");
	activation;
};

~tanh = { |ins|
	var activation = ins.distort;
	Poll.kr(Impulse.kr(1),~arraymax.value(activation), "max tanh activation");
	activation;
};

~softmax = { |ins|
	var exp = ins.exp;
	var max = ~arraymax.value(exp++[1e-10]);
	Poll.kr(Impulse.kr(1),max, "max exp sum for softmax");
	Poll.kr(Impulse.kr(1),~arraymax.value(0-(exp/max)).neg, "min softmax activation");
	exp/max;
};

~rectlin = { |ins|
	Poll.kr(Impulse.kr(1),~arraymax.value(ins), "max activation for rectlin");
	ins.max(0)
};

~activations = { |ins, weights, biases, activation_func|
	activation_func.value(
		biases.collect({|bias, j|
			ins.collect({|activation, i|
				activation * weights[j][i]}).sum.madd(MouseX.kr(-1,1),MouseY.kr(0,bias));
	}));
};

~nearness = {|source_size, source_index, target_size, target_index|
	var distance = (1.0*target_index/target_size) - (1.0*source_index/source_size);
	"nearness weight for ".post;
	source_index.post;
	" -> ".post;
	target_index.post;
	" with scale ".post;
	(distance * distance + 1).reciprocal.post;
	": ".post;
	(distance * distance + 1).reciprocal.sum3rand.postln;
};

~gaussian = { |source_size, source_index, target_size, target_index|
	"gaussian weight for ".post;
	source_index.post;
	" -> ".post;
	target_index.post;
	" with scale ".post;
	source_size.sqrt.reciprocal.post;
	": ".post;
	source_size.sqrt.reciprocal.sum3rand.postln;
};

~network = { |ins, layer_descriptions|
	var layer_dicts = layer_descriptions.collect({|desc| Dictionary.newFrom(desc)});
	var sizes = ([ins.size] ++ layer_dicts.collect({|ld| ld[\size]})).postln;
	var weights = layer_dicts.collect({|layer_dict, prev_layer_num|
		var layer_num = prev_layer_num+1;
		var target_size = sizes[layer_num];
		target_size.collect({|target_index|
			var source_size = sizes[prev_layer_num];
			source_size.collect({|source_index|
				layer_dict[\weight_init_func].value(source_size, source_index, target_size, target_index)})})});
	var biases = (sizes.size-1).collect({|prev_layer_num|
		sizes[prev_layer_num+1].collect({|target_size|
				1.0.sum3rand})});
	"network weights: shape=".post;
	weights.shape.postln;
	weights.collect({|layer, i|
		layer.size.post;
		" sets of weights in layer ".post;
		i.post;
		": ".post;
		layer.postln;
	});
	Array.series(sizes.size-1).inject(ins, {|prev_activations, layer_num|
		~activations.value(prev_activations, weights[layer_num], biases[layer_num],layer_dicts[layer_num][\activation_func])});
};

{
	var inlayer = ~maxpools.value(SoundIn.ar()).flatten(2).postln;
	var net = ~network.value(inlayer, [
		[size: 6, weight_init_func: ~nearness, activation_func: ~tanh],
		[size: 4, weight_init_func: ~gaussian, activation_func: ~tanh],
		[size: 12, weight_init_func: ~nearness, activation_func: { |ins| ~rectlin.value(~tanh.value(ins));}]]);
	var out=SinOsc.ar([40,47,52,55,57,59,62,64,67,69,71,74].midicps,0,net);
	Poll.kr(Impulse.kr(1), inlayer[32], "inlayer 32");
	"network shape: ".post;
	net.shape.postln;
	//LocalOut.ar(out.sum);
	Splay.ar(out);
}.play;
)
s.boot

~desc=Dictionary.newFrom([\size:8, \activation_func: {|in| in.distort}])
~desc[\size]
desc

1.16.sqrt
[1,2]++[]

-1.0.max(0)
[[1],[2]].shape
[[[1],[2]],[3],[4]].shape
(
{
	~maxpools.value(SoundIn.ar()).collect({|value| SinOsc.ar(value.flatten.madd(800,20),mul:0.05)}).sum;
}.play;
)

{~arraymax.value(SinOsc.ar([440,50,3],0,0.5))}.scope

SinOsc.ar([440,450,453]).maxItem

[-1,-2,-3].inject(-inf, {|sum, term| max(sum, term)});

[1,2,9].size

Array.series(~poolSize+1)

[1,2,9].add(3)
a=[1,2,9];
a.[a.size-1] = 8;
a;

[[[1,2],[1,2]]].last