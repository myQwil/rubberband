const std = @import("std");
const LinkMode = std.builtin.LinkMode;

const Options = struct {
	linkage: LinkMode = .static,
};

pub fn build(b: *std.Build) void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});

	const defaults = Options{};
	const opt = Options{
		.linkage = b.option(LinkMode, "linkage", "Library linking method")
			orelse defaults.linkage,
	};

	const lib = b.addLibrary(.{
		.name = "rubberband",
		.linkage = opt.linkage,
		.root_module = b.createModule(.{
			.target = target,
			.optimize = optimize,
			.link_libcpp = true,
		}),
	});

	const upstream = b.dependency("rubberband", .{});
	lib.addCSourceFiles(.{
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
	lib.installHeadersDirectory(upstream.path("rubberband"), "", .{
		.include_extensions = &.{
			"rubberband-c.h",
			"RubberBandStretcher.h",
			"RubberBandLiveShifter.h",
		},
	});
	b.installArtifact(lib);

	const mod = b.addModule("rubberband", .{
		.root_source_file = b.path("rubberband.zig"),
		.target = target,
		.optimize = optimize,
	});
	mod.linkLibrary(lib);
}
