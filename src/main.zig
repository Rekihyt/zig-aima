const std = @import("std");
const String = @import("std").String;
const DiGraph = @import("digraph.zig").DiGraph;
const allocator = std.testing.allocator;

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "creation" {
    var graph = DiGraph([]const u8, u32).init(allocator);
    try graph.add("Asd", null);
    // try std.testing.expectEqual(
    //     2,
    // );
}
