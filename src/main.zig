const std = @import("std");
const String = @import("std").String;
const Graph = @import("graph.zig").Graph;
const allocator = std.heap.c_allocator;

pub fn main() anyerror!void {
    const GraphU8U32 = Graph([]const u8, u32);

    var graph = GraphU8U32.init(allocator);
    defer graph.deinit();

    _ = try graph.add("asd");
    _ = try graph.add("asd2");

    // var node1 = try graph.add("Asd1");
    // var node2 = try graph.add("Asd2");
    // var node3 = try graph.add("Asd3");

    // try node1.edges.put(node2, 123);
    // defer node1.edges.deinit();
}
