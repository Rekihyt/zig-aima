const std = @import("std");
const ArrayList = std.ArrayList;
const HashMap = std.HashMap;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

/// So far is just a graph.
/// `Val` is the type of values stored in `Node`s. The memory for these is
/// only ever referenced.
/// `Weight` is the type of weights or costs between `Node`s.
pub fn DiGraph(comptime Val: type, comptime Weight: type) type {
    return struct {
        pub const Self = @This();
        pub const EdgeHashMap = AutoHashMap(*Node, Weight);
        pub const Node = struct {
            val: Val,

            edges: EdgeHashMap,

            // pub fn putEdge(self: Node, adjacent: *Node, weight: Weight) !void {
            //     try self.edges.put(adjacent);
            // }

            // pub fn fetchPutEdge(self: Node, adjacent: *Node, weight: Weight) !void {
            //     try self.edges.fetchPut(adjacent);
            // }
        };

        allocator: Allocator,

        /// The memory storage for the nodes
        nodes: ArrayList(Node),

        pub fn init(allocator: Allocator) Self {
            return Self{
                .allocator = allocator,
                .nodes = ArrayList(Node).init(allocator),
            };
        }

        pub fn addNode(self: *Self, node: *Node) !void {
            try self.nodes.append(node);
        }
        /// Add a node to this graph.
        /// edges is either 
        pub fn add(self: *Self, val: Val) !*Node {
            var node = Node{
                .val = val,
                .edges = EdgeHashMap.init(self.allocator),
            };
            try self.nodes.append(node);

            return &node;
        }

        pub fn deinit(self: *Self) void {
            // Free nodes' inner memories first.
            for (self.nodes.items) |*node| {
                // print("{*}\n", .{node});
                // Free list of edges
                node.edges.deinit();
            }
            print("{any}\n", .{self.nodes.items});
            self.nodes.deinit();
        }
    };
}

test "creation" {
    const allo = std.heap.c_allocator;
    var graph = DiGraph([]const u8, u32).init(allo);
    defer graph.deinit();

    var node1 = try graph.add("Asd1");
    var node2 = try graph.add("Asd2");
    // var node3 = try graph.add("Asd3");

    try node1.edges.put(&node2, 123);

    // try node2.edges.put(&node3, 64);

    // try std.testing.expectEqual(
    //     2,
    // );
}

// TODO: use in a undirgraph node
// Adds edges from an iterator of nodes.
// No-op if `null` is passed or the iterator is empty.
// pub fn addedges(self: *Node, edges: anytype) !void {
//     if (edges) |iter|
//         while (iter.next()) |adjacent|
//             try self.edges.append(adjacent);
// }
