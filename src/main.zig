const std = @import("std");
const String = @import("std").String;
const Graph = @import("graph.zig").Graph;
const allocator = std.heap.c_allocator;

pub fn main() anyerror!void {
    var graph = Graph([]const u8, u32).init(allocator);
    defer graph.deinit();

    var node1 = try graph.add("asd");
    var node2 = try graph.add("asd2");

    try node1.edges.put(node2, 123);
}
