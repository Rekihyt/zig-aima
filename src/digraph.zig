const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

pub fn Graph(comptime Val: type, comptime Weight: type) type {
    return struct {
        pub const Self = @This();
        pub const Val = Val;
        pub const Weight = Weight;
    };
}

// test "simple cycle" {
//     const allocator = std.testing.allocator;

//     var graph = DiGraph([]const u8, u32).init(allocator);
//     defer graph.deinit();

//     var node1 = try graph.addNode("n1");
//     var node2 = try graph.addNode("n2");

//     try node1.addEdge(node2, 123);
//     try node2.addEdge(node1, 123);
// }
