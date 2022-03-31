const std = @import("std");
const String = @import("std").String;
const Node = @import("graph.zig").Node;
const allocator = std.heap.c_allocator;

// This is here to test without testing allocator.
pub fn main() anyerror!void {
    var node1 = try Node([]const u8, u32).create(allocator, "n1");
    defer node1.destroy();

    var node2 = try Node([]const u8, u32).create(allocator, "n2");
    defer node2.destroy();

    try node1.addEdge(node2, 123);
}
