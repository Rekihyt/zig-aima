const std = @import("std");
const String = @import("std").String;
const DiGraph = @import("digraph.zig").DiGraph;
const allocator = std.testing.allocator;

pub fn main() anyerror!void {
    const allo = std.heap.c_allocator;
    var graph = DiGraph([]const u8, u32).init(allo);
    const Node = graph.Self.Node;
    const EdgeHashMap = graph.Self.EdgeHashMap;
    defer graph.deinit();

    var node1 = Node{
        .val = "asd",
        .edges = EdgeHashMap.init(allocator),
    };
    var node2 = Node{
        .val = "asd2",
        .edges = EdgeHashMap.init(allocator),
    };
    try graph.addNode(node1);

    // var node1 = try graph.add("Asd1");
    // var node2 = try graph.add("Asd2");
    // var node3 = try graph.add("Asd3");

    try node1.edges.put(node2, 123);
    // defer node1.edges.deinit();
}
