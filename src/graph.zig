const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

// Ideas
//
// Nullable nodes: nodes are deleted in O(1) time by setting the node to null
// in the list. Then each edge access checks the node for null, and deletes
// itself if so.
//

/// `Val` is the type of values stored in `Node`s. The memory for these is
/// only ever referenced.
/// `Weight` is the type of weights or costs between `Node`s.
pub fn Graph(comptime Val: type, comptime Weight: type) type {
    return struct {
        pub const Self = @This();
        const Node = struct {
            val: Val,

            edges: AutoHashMap(*Node, Weight),

            pub fn create(allocator: Allocator, val: Val) Node {
                return Node{
                    .val = val,
                    .edges = AutoHashMap(*Node, Weight).init(allocator),
                };
            }

            pub fn destroy(node: *Node) void {
                node.edges.deinit();
            }
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

        /// Add a node to this graph, allocating and creating a copy of Val.
        /// Val will be freed when the node is removed (with `deinit`).
        pub fn add(self: *Self, val: Val) !*Node {
            var node = try self.nodes.addOne();
            node.* = Node.create(self.allocator, val);
            return node;
        }

        /// Free the memory backing this node, and remove it from the graph.
        /// TODO: delete all edges as well
        pub fn deinit(self: *Self) void {
            // Free nodes' inner memory first.
            for (self.nodes.items) |*node| {
                // Free list of edges
                node.edges.deinit();
            }
            self.nodes.deinit();
        }
    };
}

test "graph memory management" {
    const allocator = std.testing.allocator;

    var graph = Graph([]const u8, u32).init(allocator);
    defer graph.deinit();

    var node1 = try graph.add("asd");
    var node2 = try graph.add("asd2");

    try node1.edges.put(node2, 123);
}

test "simple cycle" {
    const allocator = std.testing.allocator;

    var graph = Graph([]const u8, u32).init(allocator);
    defer graph.deinit();

    var node1 = try graph.add("asd");
    var node2 = try graph.add("asd2");

    try node1.edges.put(node2, 123);
    try node2.edges.put(node1, 123);
}
