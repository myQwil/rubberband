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

pub fn build(b: *std.Build) !void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});
	const opt: Options = .init(b);

	//---------------------------------------------------------------------------
	// Library
	const upstream = b.dependency("rubberband", .{});
	const mod = b.createModule(.{
		.target = target,
		.optimize = optimize,
		.link_libcpp = true,
	});

	const mem = b.allocator;
	const os = target.result.os.tag;

	var files: std.ArrayList([]const u8) = .{};
	defer files.deinit(mem);

	try files.appendSlice(mem, &.{
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
	});

	if (os.isDarwin()) {
		mod.addCMacro("USE_PTHREADS", "1");
		mod.addCMacro("MALLOC_IS_ALIGNED", "1");
		mod.addCMacro("LACK_SINCOS", "1");
	} else if (os == .windows) {
		mod.addCMacro("_WIN32", "1");
		mod.addCMacro("NOMINMAX", "1");
		mod.addCMacro("_USE_MATH_DEFINES", "1");
		mod.addCMacro("GETOPT_API", "");
		try files.appendSlice(mem, &.{
			"ext/getopt/getopt.c",
			"ext/getopt/getopt_long.c",
		});
	} else if (os == .linux) {
		mod.addCMacro("USE_PTHREADS", "1");
		mod.addCMacro("HAVE_POSIX_MEMALIGN", "1");
	}

	mod.addCMacro("USE_BUILTIN_FFT", "1");
	mod.addCMacro("USE_BQRESAMPLER", "1");

	mod.addCSourceFiles(.{
		.root = upstream.path("src"),
		.files = files.items,
		.flags = &.{},
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

	//---------------------------------------------------------------------------
	// Zig module
	const zig_mod = b.addModule("rubberband", .{
		.root_source_file = b.path("rubberband.zig"),
		.target = target,
		.optimize = optimize,
	});
	zig_mod.linkLibrary(lib);
}
