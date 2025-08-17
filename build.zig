const std = @import("std");
const LinkMode = std.builtin.LinkMode;

const Options = struct {
	linkage: LinkMode = .static,

	fn init(b: *std.Build) Options {
		const defaults: Options = .{};
		return .{
			.linkage = b.option(LinkMode, "linkage",
				"Library linking method"
			) orelse defaults.linkage,
		};
	}
};

pub fn build(b: *std.Build) void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});
	const opt: Options = .init(b);

	//---------------------------------------------------------------------------
	// Library
	const lib = blk: {
		const upstream = b.dependency("rubberband", .{});

		const mod = b.createModule(.{
			.target = target,
			.optimize = optimize,
			.link_libcpp = true,
		});
		mod.addCSourceFiles(.{
			.root = upstream.path("src"),
			.files = &.{
				"rubberband-c.cpp",
				"RubberBandStretcher.cpp",
				"RubberBandLiveShifter.cpp",
				"faster/AudioCurveCalculator.cpp",
				"faster/CompoundAudioCurve.cpp",
				"faster/HighFrequencyAudioCurve.cpp",
				"faster/SilentAudioCurve.cpp",
				"faster/PercussiveAudioCurve.cpp",
				"faster/R2Stretcher.cpp",
				"faster/StretcherChannelData.cpp",
				"faster/StretcherProcess.cpp",
				"common/Allocators.cpp",
				"common/FFT.cpp",
				"common/Log.cpp",
				"common/Profiler.cpp",
				"common/Resampler.cpp",
				"common/StretchCalculator.cpp",
				"common/sysutils.cpp",
				"common/mathmisc.cpp",
				"common/Thread.cpp",
				"finer/R3Stretcher.cpp",
				"finer/R3LiveShifter.cpp",
				"common/BQResampler.cpp",
			},
			.flags = &.{
				// "-DHAVE_LIBSAMPLERATE",
				"-DUSE_BQRESAMPLER",
				"-DUSE_BUILTIN_FFT",
				"-DUSE_PTHREADS",
				"-DHAVE_POSIX_MEMALIGN",
			},
		});

		const lib = b.addLibrary(.{
			.name = "rubberband",
			.linkage = opt.linkage,
			.root_module = mod,
		});
		lib.installHeadersDirectory(upstream.path("rubberband"), "", .{
			.include_extensions = &.{
				"rubberband-c.h",
				"RubberBandStretcher.h",
				"RubberBandLiveShifter.h",
			},
		});
		b.installArtifact(lib);
		break :blk lib;
	};

	//---------------------------------------------------------------------------
	// Zig module
	const zig_mod = b.addModule("rubberband", .{
		.root_source_file = b.path("rubberband.zig"),
		.target = target,
		.optimize = optimize,
	});
	zig_mod.linkLibrary(lib);
}
