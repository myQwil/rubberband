//! This is mainly just here to get ZLS to work properly.

const std = @import("std");
const rb = @import("rubberband");

pub fn main(_: std.process.Init) !void {
	const state: *rb.State = try .init(48000, 2, 1, 1, .{
		.process = .realtime,
		// .transients = .crisp,
		// .detector = .compound,
		// .phase = .laminar,
		// .threading = .auto,
		// .window = .standard,
		// .smoothing = .off,
		// .formant = .shifted,
		// .pitch = .speed,
		.channels = .together,
		.engine = .finer,
	});
	defer state.deinit();

	std.debug.print("engine version: {}\n", .{ state.getEngineVersion() });

	std.debug.print("time ratio: {}\n", .{ state.getTimeRatio() });
	state.setTimeRatio(1.5);
	std.debug.print("time ratio: {}\n", .{ state.getTimeRatio() });
	state.setTransientsOption(.smooth);
}
