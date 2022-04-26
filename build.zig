const std = @import("std");
const Step = std.build.Step;

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("Aima", "src/main.zig");
    // TODO: conditionally compile without linking libc ideally without
    // requiring a flag
    exe.linkLibC();
    exe.setTarget(target);
    exe.setBuildMode(mode);

    const options = b.addOptions();
    exe.addOptions("options", options);

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const valgrind_exe = b.addExecutable("Valgrind-Aima", "src/main.zig");

    valgrind_exe.linkLibC();
    valgrind_exe.setTarget(target);
    valgrind_exe.setBuildMode(mode);
    valgrind_exe.install();
    valgrind_exe.valgrind_support = true;
    valgrind_exe.addOptions("options", options);

    var valgrind_cmd = b.addSystemCommand(&.{
        "valgrind",
        b.getInstallPath(.bin, "Valgrind-Aima"),
        "--leak-check=full",
        "--track-origins=yes",
        "--show-leak-kinds=all",
        "--num-callers=15",
    });
    valgrind_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const valgrind_step = b.step("valgrind", "Test with valgrind");
    options.addOption(bool, "valgrind", true);
    valgrind_step.dependOn(&valgrind_cmd.step);

    // valgrind_step.makeFn = struct {
    //     options: ,
    //     fn make(self: *Step) !void {
    //         _ = self;
    //         @This().options.addOption(bool, "valgrind", true);
    //     }
    // }.make;

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const digraph_tests = b.addTest("src/digraph.zig");
    digraph_tests.setTarget(target);
    digraph_tests.setBuildMode(mode);

    const graph_tests = b.addTest("src/graph.zig");
    graph_tests.setTarget(target);
    graph_tests.setBuildMode(mode);

    const uninformed_tests = b.addTest("src/uninformed.zig");
    uninformed_tests.setTarget(target);
    uninformed_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
    test_step.dependOn(&digraph_tests.step);
    test_step.dependOn(&graph_tests.step);
    test_step.dependOn(&uninformed_tests.step);
}
