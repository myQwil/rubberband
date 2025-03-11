const std = @import("std");

pub const Options = packed struct(c_uint) {
	/// How the time-stretcher will be invoked.
	///
	/// These options may not be changed after construction.
	const Process = enum(u1) {
		/// In this mode the input data needs to be provided
		/// twice, once to `study()`, which calculates a stretch profile
		/// for the audio, and once to `process()`, which stretches it.
		offline = 0,
		/// In this mode, only `process()` should be called, and the
		/// stretcher adjusts dynamically in response to the input audio.
		realtime = 1,
	};

	/// The component frequency phase-reset mechanism in the R2 engine,
	/// that may be used at transient points to provide clarity and realism to
	/// percussion and other significant transient sounds.
	///
	/// These options have no effect when using the R3 engine.
	///
	/// These options may be changed after construction when running in
	/// real-time mode, but not when running in offline mode.
	const Transients = enum(u2) {
		/// R2 engine only - Reset component phases at the
		/// peak of each transient (the start of a significant note or
		/// percussive event).  This, the default setting, usually
		/// results in a clear-sounding output; but it is not always
		/// consistent, and may cause interruptions in stable sounds
		/// present at the same time as transient events.  The
		/// OptionDetector flags (below) can be used to tune this to some
		/// extent.
		crisp = 0,
		/// R2 engine only - Reset component phases at the
		/// peak of each transient, outside a frequency range typical of
		/// musical fundamental frequencies.  The results may be more
		/// regular for mixed stable and percussive notes than
		/// `transients_crisp`, but with a "phasier" sound.  The
		/// balance may sound very good for certain types of music and
		/// fairly bad for others.
		mixed = 1,
		/// R2 engine only - Do not reset component phases
		/// at any point.  The results will be smoother and more regular
		/// but may be less clear than with either of the other
		/// transients flags.
		smooth = 2,
	};

	/// The type of transient detector used in the R2 engine.
	///
	/// These options have no effect when using the R3 engine.
	///
	/// These options may be changed after construction when running
	/// in real-time mode, but not when running in offline mode.
	const Detector = enum(u2) {
		/// Use a general-purpose
		/// transient detector which is likely to be good for most
		/// situations.  This is the default.
		compound = 0,
		/// Detect percussive
		/// transients.  Note that this was the default and only option
		/// in Rubber Band versions prior to 1.5.
		percussive = 1,
		/// Use an onset detector with less
		/// of a bias toward percussive transients.  This may give better
		/// results with certain material (e.g. relatively monophonic
		/// piano music).
		soft = 2,
	};

	/// The adjustment of component frequency phases in the R2 engine from
	/// one analysis window to the next during non-transient segments.
	///
	/// These options have no effect when using the R3 engine.
	///
	/// These options may be changed at any time.
	const Phase = enum(u1) {
		/// Adjust phases when stretching in
		/// such a way as to try to retain the continuity of phase
		/// relationships between adjacent frequency bins whose phases
		/// are behaving in similar ways.  This, the default setting,
		/// should give good results in most situations.
		laminar = 0,
		/// Adjust the phase in each
		/// frequency bin independently from its neighbours.  This
		/// usually results in a slightly softer, phasier sound.
		independent = 1,
	};

	/// The threading model of the stretcher.
	///
	/// These options may not be changed after construction.
	const Threading = enum(u2) {
		/// Permit the stretcher to
		/// determine its own threading model.  In the R2 engine this
		/// means using one processing thread per audio channel in
		/// offline mode if the stretcher is able to determine that more
		/// than one CPU is available, and one thread only in real-time
		/// mode.  The R3 engine does not currently have a multi-threaded
		/// mode, but if one is introduced in future, this option may use
		/// it. This is the default.
		auto = 0,
		/// Never use more than one thread.
		never = 1,
		/// Use multiple threads in any
		/// situation where `threading_auto` would do so, except omit
		/// the check for multiple CPUs and instead assume it to be true.
		always = 2,
	};

	/// The window size for FFT processing.
	/// In the R2 engine, these affect the resulting sound quality
	/// but have relatively little effect on processing speed.
	/// With the R3 engine they can dramatically affect processing speed
	/// as well as output quality.
	///
	/// These options may not be changed after construction.
	const Window = enum(u2) {
		/// Use the default window size.
		/// The actual size will vary depending on other parameters.
		/// This option is expected to produce better results than the
		/// other window options in most situations. In the R3 engine
		/// this causes the engine's full multi-resolution processing
		/// scheme to be used.
		standard = 0,
		/// Use a shorter window. This has
		/// different effects with R2 and R3 engines.
		///
		/// With the R2 engine it may result in crisper sound for audio
		/// that depends strongly on its timing qualities, but is likely
		/// to sound worse in other ways and will have similar
		/// efficiency.
		///
		/// With the R3 engine, it causes the engine to be restricted to
		/// a single window size, resulting in both dramatically faster
		/// processing and lower delay than OptionWindowStandard, but at
		/// the expense of some sound quality. It may still sound better
		/// for non-percussive material than the R2 engine.
		///
		/// With both engines it reduces the start delay somewhat (see
		/// `RubberBandStretcher::getStartDelay`) which may be useful for
		/// real-time handling.
		short = 1,
		/// Use a longer window. With the R2
		/// engine this is likely to result in a smoother sound at the
		/// expense of clarity and timing. The R3 engine currently
		/// ignores this option, treating it like OptionWindowStandard.
		long = 2,
	};

	/// The use of window-presum FFT and time-domain smoothing in the R2 engine.
	///
	/// These options have no effect when using the R3 engine.
	///
	/// These options may not be changed after construction.
	const Smoothing = enum(u1) {
		/// Do not use time-domain smoothing. This is the default.
		off = 0,
		/// Use time-domain smoothing.  This
		/// will result in a softer sound with some audible artifacts
		/// around sharp transients, but it may be appropriate for longer
		/// stretches of some instruments and can mix well with
		/// `window_short`.
		on = 1,
	};

	/// The handling of formant shape (spectral envelope) when pitch-shifting.
	///
	/// These options affect both the R2 and R3 engines.
	///
	/// These options may be changed at any time.
	const Formant = enum(u1) {
		/// Apply no special formant
		/// processing.  The spectral envelope will be pitch shifted as
		/// normal.  This is the default.
		shifted = 0,
		/// Preserve the spectral
		/// envelope of the unshifted signal.  This permits shifting the
		/// note frequency without so substantially affecting the
		/// perceived pitch profile of the voice or instrument.
		preserved = 1,
	};

	/// The method used for pitch-shifting.
	///
	/// These options affect only realtime mode.
	/// In offline mode the method is not adjustable.
	///
	/// In the R2 engine these options may be changed at any time;
	/// in the R3 engine they may be set only on construction.
	const Pitch = enum(u2) {
		/// Favour CPU cost over sound
		/// quality. This is the default. Use this when time-stretching
		/// only, or for fixed pitch shifts where CPU usage is of
		/// concern. Do not use this for arbitrarily time-varying pitch
		/// shifts (see `pitch_high_consistency`).
		speed = 0,
		/// Favour sound quality over CPU
		/// cost. Use this for fixed pitch shifts where sound quality is
		/// of most concern. Do not use this for arbitrarily time-varying
		/// pitch shifts (see OptionPitchHighConsistency below).
		quality = 1,
		/// Use a method that
		/// supports dynamic pitch changes without discontinuities,
		/// including when crossing the 1.0 pitch scale. This may cost
		/// more in CPU than the default, especially when the pitch scale
		/// is exactly 1.0. You should use this option whenever you wish
		/// to support dynamically changing pitch shift during
		/// processing.
		consistency = 2,
	};

	/// The method used for processing two-channel stereo audio.
	///
	/// These options may not be changed after construction.
	const Channels = enum(u1) {
		/// Channels are handled for maximum
		/// individual fidelity, at the expense of synchronisation. In
		/// the R3 engine, this means frequency-bin synchronisation is
		/// maintained more closely for lower-frequency content than
		/// higher.  In R2, it means the stereo channels are processed
		/// individually and only synchronised at transients.  In both
		/// engines this gives the highest quality for the individual
		/// channels but a more diffuse stereo image, an unnatural
		/// increase in "width", and generally a loss of mono
		/// compatibility (i.e. mono mixes from stereo can sound phasy).
		/// This option is the default.
		apart = 0,
		/// Channels are handled for
		/// higher synchronisation at some expense of individual
		/// fidelity. In particular, a stretcher processing two channels
		/// will treat its input as a stereo pair and aim to maximise
		/// clarity at the centre and preserve mono compatibility.  This
		/// gives relatively less stereo space and width than the
		/// default, as well as slightly lower fidelity for individual
		/// channel content, but the results may be more appropriate for
		/// many situations making use of stereo mixes.
		together = 1,
	};

	/// The core Rubber Band processing engine to be used.
	///
	/// These options may not be changed after construction.
	const Engine = enum(u1) {
		/// Use the Rubber Band Library R2
		/// (Faster) engine. This is the engine implemented in Rubber
		/// Band Library v1.x and v2.x, and it remains the default in
		/// newer versions. It uses substantially less CPU than the R3
		/// engine and there are still many situations in which it is
		/// likely to be the more appropriate choice.
		faster = 0,
		/// Use the Rubber Band Library R3
		/// (Finer) engine. This engine was introduced in Rubber Band
		/// Library v3.0. It produces higher-quality results than the R2
		/// engine for most material, especially complex mixes, vocals
		/// and other sounds that have soft onsets and smooth pitch
		/// changes, and music with substantial bass content. However, it
		/// uses much more CPU power than the R2 engine.
		///
		/// Important note: Consider calling `getEngineVersion()` after
		/// construction to make sure the engine you requested is
		/// active. That's not because engine selection can fail, but
		/// because Rubber Band Library ignores any unknown options
		/// supplied on construction - so a program that requests the R3
		/// engine but ends up linked against an older version of the
		/// library (prior to v3.0) will silently use the R2 engine
		/// instead. Calling the v3.0 function `getEngineVersion()` will
		/// ensure a link failure in this situation instead, and supply a
		/// reassuring run-time check.
		finer = 1,
	};

	process: Process = .offline,
	_process_pad: u3 = 0,

	/// Obsolete flags (elastic=0, precise=1).
	/// Provided for backward compatibility only. They are ignored by
	/// the stretcher.
	_stretch: u1 = 0,
	_stretch_pad: u3 = 0,

	transients: Transients = .crisp,

	detector: Detector = .compound,

	_phase_pad1: u1 = 0,
	phase: Phase = .laminar,
	_phase_pad2: u2 = 0,

	threading: Threading = .auto,
	_threading_pad: u2 = 0,

	window: Window = .standard,
	_window_pad: u1 = 0,

	smoothing: Smoothing = .off,

	formant: Formant = .shifted,

	pitch: Pitch = .speed,
	_pitch_pad: u1 = 0,

	channels: Channels = .apart,

	engine: Engine = .faster,

	_unused: @Type(.{.int = .{
		.signedness = .unsigned, .bits = @bitSizeOf(c_uint) - 30,
	}}) = 0,

	const default: Options = .{};
	const percussive: Options = .{ .window = .short, .phase = .independent };
};

pub const State = opaque {
	/// Construct a time and pitch stretcher object to run at the given
	/// sample rate, with the given number of channels.
	///
	/// Both of the stretcher engines provide their best balance of
	/// quality with efficiency at sample rates of 44100 or 48000 Hz.
	/// Other rates may be used, and the stretcher should produce
	/// sensible output with any rate from 8000 to 192000 Hz, but you
	/// are advised to use 44100 or 48000 where practical. Do not use
	/// rates below 8000 or above 192000 Hz.
	///
	/// Initial time and pitch scaling ratios and other processing
	/// options may be provided. In particular, the behaviour of the
	/// stretcher depends strongly on whether offline or real-time mode
	/// is selected on construction (via `Option.process_offline` or
	/// `Option.process_realtime` - offline is the default).
	/// 
	/// In offline mode, you must provide the audio block-by-block in
	/// two passes: in the first pass calling `study()`, in the second
	/// pass calling `process()` and receiving the output via
	/// `retrieve()`. In real-time mode, there is no study pass, just a
	/// single streaming pass in which the audio is passed to `process()`
	/// and output received via `retrieve()`.
	///
	/// In real-time mode you can change the time and pitch ratios at
	/// any time, but in offline mode they are fixed and cannot be
	/// changed after the study pass has begun. (However, see
	/// `setKeyFrameMap()` for a way to do pre-planned variable time
	/// stretching in offline mode.)
	pub fn new(
		sampleRate: c_uint,
		channels: c_uint,
		options: Options,
		timeRatio: f64,
		pitchScale: f64,
	) !*State {
		const s = rubberband_new(sampleRate, channels, options, timeRatio, pitchScale);
		return if (s) |state| state else error.OutOfMemory;
	}
	extern fn rubberband_new(c_uint, c_uint, Options, f64, f64) ?*State;

	pub const delete = rubberband_delete;
	extern fn rubberband_delete(*State) void;

	/// Reset the stretcher's internal buffers.  The stretcher should
	/// subsequently behave as if it had just been constructed
	/// (although retaining the current time and pitch ratio).
	pub const reset = rubberband_reset;
	extern fn rubberband_reset(*State) void;

	/// Return the active internal engine version, according to the \c
	/// OptionEngine flag supplied on construction. This will return 2
	/// for the R2 (Faster) engine or 3 for the R3 (Finer) engine.
	///
	/// This function was added in Rubber Band Library v3.0.
	pub const getEngineVersion = rubberband_get_engine_version;
	extern fn rubberband_get_engine_version(*State) c_uint;

	/// Set the time ratio for the stretcher.  This is the ratio of
	/// stretched to unstretched duration -- not tempo.  For example, a
	/// ratio of 2.0 would make the audio twice as long (i.e. halve the
	/// tempo); 0.5 would make it half as long (i.e. double the tempo);
	/// 1.0 would leave the duration unaffected.
	/// 
	/// If the stretcher was constructed in Offline mode, the time
	/// ratio is fixed throughout operation; this function may be
	/// called any number of times between construction (or a call to
	/// `reset()`) and the first call to `study()` or `process()`, but may
	/// not be called after `study()` or `process()` has been called.
	/// 
	/// If the stretcher was constructed in real-time mode, the time
	/// ratio may be varied during operation; this function may be
	/// called at any time, so long as it is not called concurrently
	/// with `process()`.  You should either call this function from the
	/// same thread as `process()`, or provide your own mutex or similar
	/// mechanism to ensure that setTimeRatio and `process()` cannot be
	/// run at once (there is no internal mutex for this purpose).
	pub const setTimeRatio = rubberband_set_time_ratio;
	extern fn rubberband_set_time_ratio(*State, ratio: f64) void;

	/// Set the pitch scaling ratio for the stretcher.  This is the
	/// ratio of target frequency to source frequency.  For example, a
	/// ratio of 2.0 would shift up by one octave; 0.5 down by one
	/// octave; or 1.0 leave the pitch unaffected.
	///
	/// To put this in musical terms, a pitch scaling ratio
	/// corresponding to a shift of S equal-tempered semitones (where S
	/// is positive for an upwards shift and negative for downwards) is
	/// pow(2.0, S / 12.0).
	///
	/// If the stretcher was constructed in Offline mode, the pitch
	/// scaling ratio is fixed throughout operation; this function may
	/// be called any number of times between construction (or a call
	/// to `reset()`) and the first call to `study()` or `process()`, but may
	/// not be called after `study()` or `process()` has been called.
	///
	/// If the stretcher was constructed in real-time mode, the pitch
	/// scaling ratio may be varied during operation; this function may
	/// be called at any time, so long as it is not called concurrently
	/// with `process()`.  You should either call this function from the
	/// same thread as `process()`, or provide your own mutex or similar
	/// mechanism to ensure that `setPitchScale` and `process()` cannot be
	/// run at once (there is no internal mutex for this purpose).
	pub const setPitchScale = rubberband_set_pitch_scale;
	extern fn rubberband_set_pitch_scale(*State, scale: f64) void;

	/// Set a pitch scale for the vocal formant envelope separately
	/// from the overall pitch scale.  This is a ratio of target
	/// frequency to source frequency.  For example, a ratio of 2.0
	/// would shift the formant envelope up by one octave; 0.5 down by
	/// one octave; or 1.0 leave the formant unaffected.
	///
	/// By default this is set to the special value of 0.0, which
	/// causes the scale to be calculated automatically. It will be
	/// treated as 1.0 / the pitch scale if `formant_preserved` is
	/// specified, or 1.0 for `formant_shifted`.
	///
	/// Conversely, if this is set to a value other than the default
	/// 0.0, formant shifting will happen regardless of the state of
	/// the `formant_preserved/formant_shifted` option.
	///
	/// This function is provided for special effects only. You do not
	/// need to call it for ordinary pitch shifting, with or without
	/// formant preservation - just specify or omit the
	/// `formant_preserved` option as appropriate. Use this function
	/// only if you want to shift formants by a distance other than
	/// that of the overall pitch shift.
	/// 
	/// This function is supported only in the R3 (`engine_finer`)
	/// engine. It has no effect in R2 (`engine_faster`).
	///
	/// This function was added in Rubber Band Library v3.0.
	pub const setFormantScale = rubberband_set_formant_scale;
	extern fn rubberband_set_formant_scale(*State, scale: f64) void;

	/// Return the last time ratio value that was set (either on
	/// construction or with `setTimeRatio()`).
	pub const getTimeRatio = rubberband_get_time_ratio;
	extern fn rubberband_get_time_ratio(*const State) f64;

	/// Return the last pitch scaling ratio value that was set (either
	/// on construction or with setPitchScale()).
	pub const getPitchScale = rubberband_get_pitch_scale;
	extern fn rubberband_get_pitch_scale(*const State) f64;

	/// Return the last formant scaling ratio that was set with
	/// `setFormantScale`, or 0.0 if the default automatic scaling is in
	/// effect.
	/// 
	/// This function is supported only in the R3 (`engine_finer`)
	/// engine. It always returns 0.0 in R2 (`engine_faster`).
	///
	/// This function was added in Rubber Band Library v3.0.
	pub const getFormantScale = rubberband_get_formant_scale;
	extern fn rubberband_get_formant_scale(*const State) f64;

	/// In real-time mode (unlike in Offline mode) the stretcher
	/// performs no automatic padding or delay/latency compensation at
	/// the start of the signal. This permits applications to have
	/// their own custom requirements, but it also means that by
	/// default some samples will be lost or attenuated at the start of
	/// the output and the correct linear relationship between input
	/// and output sample counts may be lost.
	///
	/// Most applications using real-time mode should solve this by
	/// calling `getPreferredStartPad()` and supplying the returned
	/// number of (silent) samples at the start of their input, before
	/// their first "true" process() call; and then also calling
	/// `getStartDelay()` and trimming the returned number of samples
	/// from the start of their stretcher's output.
	///
	/// Ensure you have set the time and pitch scale factors to their
	/// proper starting values before calling `getRequiredStartPad()` or
	/// `getStartDelay()`.
	///
	/// In Offline mode, padding and delay compensation are handled
	/// internally and both functions always return zero.
	///
	/// This function was added in Rubber Band Library v3.0.
	pub const getPreferredStartPad = rubberband_get_preferred_start_pad;
	extern fn rubberband_get_preferred_start_pad(*const State) c_uint;

	/// Return the output delay of the stretcher.  This is the number
	/// of audio samples that one should discard at the start of the
	/// output, after padding the start of the input with
	/// getPreferredStartPad(), in order to ensure that the resulting
	/// audio has the expected time alignment with the input.
	///
	/// Ensure you have set the time and pitch scale factors to their
	/// proper starting values before calling getPreferredStartPad() or
	/// getStartDelay().
	///
	/// In Offline mode, padding and delay compensation are handled
	/// internally and both functions always return zero.
	/// 
	/// This function was added in Rubber Band Library v3.0. Previously
	/// it was called getLatency(). It was renamed to avoid confusion
	/// with the number of samples needed at input to cause a block of
	/// processing to handle (returned by getSamplesRequired()) which
	/// is also sometimes referred to as latency.
	pub const getStartDelay = rubberband_get_start_delay;
	extern fn rubberband_get_start_delay(*const State) c_uint;

	/// Return the number of channels this stretcher was constructed
	/// with.
	pub const getChannelCount = rubberband_get_channel_count;
	extern fn rubberband_get_channel_count(*const State) c_uint;

	/// Change a Transients configuration setting. This may be
	/// called at any time in real-time mode.  It may not be called in
	/// Offline mode (for which the transients option is fixed on
	/// construction). This has no effect when using the R3 engine.
	pub fn setTransientsOption(self: *State, opt: Options.Transients) void {
		rubberband_set_transients_option(self, .{ .transients = opt });
	}
	extern fn rubberband_set_transients_option(*State, Options) void;

	/// Change a Detector configuration setting.  This may be
	/// called at any time in real-time mode.  It may not be called in
	/// Offline mode (for which the detector option is fixed on
	/// construction). This has no effect when using the R3 engine.
	pub fn setDetectorOption(self: *State, opt: Options.Detector) void {
		rubberband_set_detector_option(self, .{ .detector = opt });
	}
	extern fn rubberband_set_detector_option(*State, Options) void;

	/// Change a Phase configuration setting.  This may be
	/// called at any time in any mode. This has no effect when using
	/// the R3 engine.
	///
	/// Note that if running multi-threaded in Offline mode, the change
	/// may not take effect immediately if processing is already under
	/// way when this function is called.
	pub fn setPhaseOption(self: *State, opt: Options.Phase) void {
		rubberband_set_phase_option(self, .{ .phase = opt });
	}
	extern fn rubberband_set_phase_option(*State, Options) void;

	/// Change a Formant configuration setting.  This may be
	/// called at any time in any mode.
	///
	/// Note that if running multi-threaded in Offline mode, the change
	/// may not take effect immediately if processing is already under
	/// way when this function is called.
	pub fn setFormantOption(self: *State, opt: Options.Formant) void {
		rubberband_set_formant_option(self, .{ .formant = opt });
	}
	extern fn rubberband_set_formant_option(*State, Options) void;

	/// Change a Pitch configuration setting.  This may be
	/// called at any time in real-time mode.  It may not be called in
	/// Offline mode (for which the pitch option is fixed on
	/// construction). This has no effect when using the R3 engine.
	pub fn setPitchOption(self: *State, opt: Options.Pitch) void {
		rubberband_set_pitch_option(self, .{ .pitch = opt });
	}
	extern fn rubberband_set_pitch_option(*State, Options) void;

	/// Tell the stretcher exactly how many input sample frames it will
	/// receive.  This is only useful in Offline mode, when it allows
	/// the stretcher to ensure that the number of output samples is
	/// exactly correct.  In real-time mode no such guarantee is
	/// possible and this value is ignored.
	///
	/// Note that the value of "samples" refers to the number of audio
	/// sample frames, which may be multi-channel, not the number of
	/// individual samples. (For example, one second of stereo audio
	/// sampled at 44100Hz yields a value of 44100 sample frames, not
	/// 88200.)  This rule applies throughout the Rubber Band API.
	pub const setExpectedInputDuration = rubberband_set_expected_input_duration;
	extern fn rubberband_set_expected_input_duration(*State, c_uint) void;

	/// Ask the stretcher how many audio sample frames should be
	/// provided as input in order to ensure that some more output
	/// becomes available.
	/// 
	/// If your application has no particular constraint on processing
	/// block size and you are able to provide any block size as input
	/// for each cycle, then your normal mode of operation would be to
	/// loop querying this function; providing that number of samples
	/// to process(); and reading the output (repeatedly if necessary)
	/// using available() and retrieve().  See setMaxProcessSize() for
	/// a more suitable operating mode for applications that do have
	/// external block size constraints.
	///
	/// Note that this value is only relevant to process(), not to
	/// study() (to which you may pass any number of samples at a time,
	/// and from which there is no output).
	///
	/// Note that the return value refers to the number of audio sample
	/// frames, which may be multi-channel, not the number of
	/// individual samples. (For example, one second of stereo audio
	/// sampled at 44100Hz yields a value of 44100 sample frames, not
	/// 88200.)  This rule applies throughout the Rubber Band API.
	pub const getSamplesRequired = rubberband_get_samples_required;
	extern fn rubberband_get_samples_required(*const State) c_uint;

	/// Tell the stretcher the maximum number of sample frames that you
	/// will ever be passing in to a single process() call.  If you
	/// don't call this, the stretcher will assume that you are calling
	/// getSamplesRequired() at each cycle and are never passing more
	/// samples than are suggested by that function.
	///
	/// If your application has some external constraint that means you
	/// prefer a fixed block size, then your normal mode of operation
	/// would be to provide that block size to this function; to loop
	/// calling process() with that size of block; after each call to
	/// process(), test whether output has been generated by calling
	/// available(); and, if so, call retrieve() to obtain it.  See
	/// getSamplesRequired() for a more suitable operating mode for
	/// applications without such external constraints.
	///
	/// This function may not be called after the first call to study()
	/// or process().
	///
	/// Note that this value is only relevant to process(), not to
	/// study() (to which you may pass any number of samples at a time,
	/// and from which there is no output).
	///
	/// Despite the existence of this call and its use of a size_t
	/// argument, there is an internal limit to the maximum process
	/// buffer size that can be requested. Call getProcessSizeLimit()
	/// to query that limit. The Rubber Band API is essentially
	/// block-based and is not designed to process an entire signal
	/// within a single process cycle.
	///
	/// Note that the value of "samples" refers to the number of audio
	/// sample frames, which may be multi-channel, not the number of
	/// individual samples. (For example, one second of stereo audio
	/// sampled at 44100Hz yields a value of 44100 sample frames, not
	/// 88200.)  This rule applies throughout the Rubber Band API.
	pub const setMaxProcessSize = rubberband_set_max_process_size;
	extern fn rubberband_set_max_process_size(*State, c_uint) void;

	/// Obtain the overall maximum supported process buffer size in
	/// sample frames, which is also the maximum acceptable value to
	/// pass to setMaxProcessSize(). This value is fixed across
	/// instances and configurations. As of Rubber Band v3.3 it is
	/// always 524288 (or 2^19), but in principle it may change in
	/// future releases.
	///
	/// This function was added in Rubber Band Library v3.3.
	pub const getProcessSizeLimit = rubberband_get_process_size_limit;
	extern fn rubberband_get_process_size_limit(*State) c_uint;

	/// Provide a set of mappings from "before" to "after" sample
	/// numbers so as to enforce a particular stretch profile.  The
	/// argument is a map from audio sample frame number in the source
	/// material, to the corresponding sample frame number in the
	/// stretched output.  The mapping should be for key frames only,
	/// with a "reasonable" gap between mapped samples.
	///
	/// This function cannot be used in RealTime mode.
	///
	/// This function may not be called after the first call to
	/// process().  It should be called after the time and pitch ratios
	/// have been set; the results of changing the time and pitch
	/// ratios after calling this function are undefined.  Calling
	/// reset() will clear this mapping.
	///
	/// The key frame map only affects points within the material; it
	/// does not determine the overall stretch ratio (that is, the
	/// ratio between the output material's duration and the source
	/// material's duration).  You need to provide this ratio
	/// separately to setTimeRatio(), otherwise the results may be
	/// truncated or extended in unexpected ways regardless of the
	/// extent of the frame numbers found in the key frame map.
	pub const setKeyFrameMap = rubberband_set_key_frame_map;
	extern fn rubberband_set_key_frame_map(
		*State,
		len: c_uint,
		from: [*]c_uint,
		to: [*]c_uint
	) void;

	/// Provide a block of "frames" sample frames for the stretcher to
	/// study and calculate a stretch profile from.
	///
	/// This is only meaningful in Offline mode, and is required if
	/// running in that mode.  You should pass the entire input through
	/// study() before any process() calls are made, as a sequence of
	/// blocks in individual study() calls, or as a single large block.
	///
	/// "input" should point to de-interleaved audio data with one
	/// float array per channel. Sample values are conventionally
	/// expected to be in the range -1.0f to +1.0f.  "frames" supplies
	/// the number of audio sample frames available in "input". If
	/// "frames" is zero, "input" may be NULL.
	/// 
	/// Set "final" to true if this is the last block of data that will
	/// be provided to study() before the first process() call.
	pub fn study(
		self: *State,
		input: [*]const [*]const f32,
		frames: c_uint,
		final: bool,
	) void {
		rubberband_study(self, input, frames, @intFromBool(final));
	}
	extern fn rubberband_study(*State, [*]const [*]const f32, c_uint, c_uint) void;

	/// Provide a block of "frames" sample frames for processing.
	/// See also getSamplesRequired() and setMaxProcessSize().
	///
	/// "input" should point to de-interleaved audio data with one
	/// float array per channel. Sample values are conventionally
	/// expected to be in the range -1.0f to +1.0f.  "frames" supplies
	/// the number of audio sample frames available in "input".
	///
	/// Note that the value of "frames" refers to the number of audio
	/// sample frames, which may be multi-channel, not the number of
	/// individual samples. (For example, one second of stereo audio
	/// sampled at 44100Hz yields a value of 44100 sample frames, not
	/// 88200.)  This rule applies throughout the Rubber Band API.
	///
	/// Set "final" to true if this is the last block of input data.
	pub fn process(
		self: *State,
		input: [*]const [*]const f32,
		frames: c_uint,
		final: bool,
	) void {
		rubberband_process(self, input, frames, @intFromBool(final));
	}
	extern fn rubberband_process(*State, [*]const [*]const f32, c_uint, c_uint) void;

	/// Ask the stretcher how many audio sample frames of output data
	/// are available for reading (via retrieve()).
	/// 
	/// This function returns 0 if no frames are available: this
	/// usually means more input data needs to be provided, but if the
	/// stretcher is running in threaded mode it may just mean that not
	/// enough data has yet been processed.  Call getSamplesRequired()
	/// to discover whether more input is needed.
	///
	/// Note that the return value refers to the number of audio sample
	/// frames, which may be multi-channel, not the number of
	/// individual samples. (For example, one second of stereo audio
	/// sampled at 44100Hz yields a value of 44100 sample frames, not
	/// 88200.)  This rule applies throughout the Rubber Band API.
	///
	/// This function returns -1 if all data has been fully processed
	/// and all output read, and the stretch process is now finished.
	pub const available = rubberband_available;
	extern fn rubberband_available(*const State) c_int;

	/// Obtain some processed output data from the stretcher.  Up to
	/// "frames" samples will be stored in each of the output arrays
	/// (one per channel for de-interleaved audio data) pointed to by
	/// "output".  The number of sample frames available to be
	/// retrieved can be queried beforehand with a call to available().
	/// The return value is the actual number of sample frames
	/// retrieved.
	///
	/// Note that the value of "frames" and the return value refer to
	/// the number of audio sample frames, which may be multi-channel,
	/// not the number of individual samples. (For example, one second
	/// of stereo audio sampled at 44100Hz yields a value of 44100
	/// sample frames, not 88200.)  This rule applies throughout the
	/// Rubber Band API.
	pub const retrieve = rubberband_retrieve;
	extern fn rubberband_retrieve(*const State, [*]const [*]f32, c_uint) c_uint;

	/// Force the stretcher to calculate a stretch profile.  Normally
	/// this happens automatically for the first process() call in
	/// offline mode.
	///
	/// This function is provided for diagnostic purposes only and is
	/// supported only with the R2 engine.
	pub const calculateStretch = rubberband_calculate_stretch;
	extern fn rubberband_calculate_stretch(*State) void;

	/// Set the level of debug output.  The supported values are:
	///
	/// 0. Report errors only.
	/// 
	/// 1. Report some information on construction and ratio
	/// change. Nothing is reported during normal processing unless
	/// something changes.
	/// 
	/// 2. Report a significant amount of information about ongoing
	/// stretch calculations during normal processing.
	/// 
	/// 3. Report a large amount of information and also (in the R2
	/// engine) add audible ticks to the output at phase reset
	/// points. This is seldom useful.
	///
	/// The default is whatever has been set using
	/// setDefaultDebugLevel(), or 0 if that function has not been
	/// called.
	///
	/// All output goes to `cerr` unless a custom
	/// RubberBandStretcher::Logger has been provided on
	/// construction. Because writing to `cerr` is not RT-safe, only
	/// debug level 0 is RT-safe in normal use by default. Debug levels
	/// 0 and 1 use only C-string constants as debug messages, so they
	/// are RT-safe if your custom logger is RT-safe. Levels 2 and 3
	/// are not guaranteed to be RT-safe in any conditions as they may
	/// construct messages by allocation.
	pub const setDebugLevel = rubberband_set_debug_level;
	extern fn rubberband_set_debug_level(*State, c_uint) void;

	/// Set the default level of debug output for subsequently
	/// constructed stretchers.
	pub const setDefaultDebugLevel = rubberband_set_default_debug_level;
	extern fn rubberband_set_default_debug_level(level: c_uint) void;
};
