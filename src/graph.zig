const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const helpers = @import("helpers.zig");
const mode = @import("builtin").mode;

/// `Value` is the type of data to be stored in `Node`s, with copy semantics.
/// `Weight` is the type of weights or costs between `Node`s. Weights are
/// allocated twice, once in each nodes' edge hashmap.
pub fn Node(comptime Value: type, comptime Weight: type) type {
    return struct {
        pub const Self = @This();

        allocator: Allocator,

        value: Value,

        /// Individual edges are stored twice, once in each node in a pair
        /// that form the edge. These are separate from `Edge` structs, which
        /// keep track of pairs of nodes.
        edges: AutoHashMap(*Self, Weight),

        /// Creates a new node, allocating a copy of Value.
        pub fn create(allocator: Allocator, value: Value) !*Self {
            var node = try allocator.create(Self);
            node.* = Self{
                .allocator = allocator,
                .value = value,
                .edges = AutoHashMap(*Self, Weight).init(allocator),
            };
            return node;
        }

        // TODO: removeNode

        /// Free the memory backing this node, and remove it from the graph.
        /// Allocates and frees a set of all node pointers using `nodePtrs`.
        pub fn destroy(self: *Self) void {
            var edge_iter = self.edges.keyIterator();

            // Free each reference to this node in adjacents.
            while (edge_iter.next()) |adjacent| {
                var removed = adjacent.*.edges.remove(self);
                // TODO: check only if debug is enabled, as `removed` should
                // always be true
                // comptime {
                // if (mode == .Debug)
                if (!removed)
                    @panic("While freeing this node, an adjacent node's reference to it wasn't removed.");
                // }
            }
            // Free this list of edges
            self.edges.deinit();
            // Free this node
            self.allocator.destroy(self);
        }

        /// An edges between two node pointers. Isn't used by Nodes to store
        /// their edges (a hashmap is used instead) but rather when enumerating
        /// all edges in the graph.
        pub const Edge = struct {
            this: *Self,
            that: *Self,
            weight: Weight,
        };

        /// Returns a set of all nodes in this graph.
        /// Caller frees (calls `deinit`).
        // Node pointers must be used because HashMaps don't allow structs
        // containing slices.
        pub fn nodes(
            self: *const Self,
            allocator: Allocator,
        ) !AutoHashMap(*const Self, void) {
            var node_set = AutoHashMap(*const Self, void).init(allocator);
            // A stack to add nodes reached across edges
            var to_visit = ArrayList(*const Self).init(allocator);
            defer to_visit.deinit();

            // Greedily add all neighbors to `to_visit`, then loop until
            // no new neighbors are found.
            try to_visit.append(self);
            while (to_visit.popOrNull()) |node_ptr| {
                // If the node is unvisited
                if (!node_set.contains(node_ptr)) {
                    // Add to set (marks as visited)
                    try node_set.put(node_ptr, {});
                    // Save adjacent nodes to check later
                    var adjacents = self.edges.keyIterator();
                    while (adjacents.next()) |adjacent_ptr| {
                        try to_visit.append(adjacent_ptr.*);
                    }
                }
            }
            return node_set;
        }

        /// Returns a set of all node pointers in this graph.
        /// If you don't need to mutate any nodes, call `nodes` instead.
        /// Caller frees (calls `deinit`).
        pub fn nodePtrs(
            self: *Self,
            allocator: Allocator,
        ) !AutoHashMap(*Self, void) {
            var node_set = AutoHashMap(*Self, void).init(allocator);
            // A stack to add nodes reached across edges
            var to_visit = ArrayList(*Self).init(allocator);
            defer to_visit.deinit();

            // Greedily add all neighbors to `to_visit`, then loop until
            // no new neighbors are found.
            try to_visit.append(self);
            while (to_visit.popOrNull()) |node_ptr| {
                // If the node is unvisited
                if (!node_set.contains(node_ptr)) {
                    // Add to set (marks as visited)
                    try node_set.put(node_ptr, {});
                    // Save adjacent nodes to check later
                    var adjacents = self.edges.keyIterator();
                    while (adjacents.next()) |adjacent_ptr| {
                        try to_visit.append(adjacent_ptr.*);
                    }
                }
            }
            return node_set;
        }

        /// Returns a set of all edge pointers in this graph.
        /// Caller frees (calls `deinit`).
        // Edge pointers must be used because HashMaps don't allow structs
        // containing slices.
        pub fn edgeSet(
            self: *Self,
            allocator: Allocator,
        ) !AutoHashMap(Edge, void) {
            // Use a 0 size value (void) to use a hashmap as a set, in order
            // to avoid listing edges twice.
            var edge_set = AutoHashMap(*Edge, void).init(allocator);
            const node_set = try self.nodePtrs(allocator);
            var nodes_iter = node_set.keyIterator();
            while (nodes_iter.next()) |node_ptr| {
                var edge_iter = node_ptr.*.edges.iterator();
                while (edge_iter.next()) |edge_entry| {
                    try edge_set.put(
                        Edge{
                            .this = node_ptr.*,
                            .that = edge_entry.key_ptr.*,
                            .weight = edge_entry.value_ptr.*,
                        },
                        {}, // The 0 size "value"
                    );
                }
            }
            return edge_set;
        }

        /// Allocates twice in both nodes' `edges` hashmaps.
        /// If the edge already exists, the weight will be updated.
        pub fn addEdge(self: *Self, other: *Self, weight: Weight) !void {
            try self.edges.put(other, weight);
            try other.edges.put(self, weight);
        }

        // TODO: removeEdge

        /// Pass into `exportDot` to configure dot output.
        pub const DotSettings = struct {
            // graph_setting: ?String = null,
            // node_setting: ?String = null,
            // edge_setting: ?String = null,
        };

        /// Writes the graph out in dot (graphviz) to the given `writer`.
        /// Node value types currently must be `[]const u8`.
        pub fn exportDot(
            self: *Self,
            allocator: Allocator,
            writer: anytype,
            dot_settings: DotSettings,
        ) !void {
            _ = dot_settings;
            try writer.writeAll("DiGraph {\n");

            var nodes_iter = (try self.nodes(allocator)).keyIterator();
            while (nodes_iter.next()) |node_ptr| {
                try writer.print(
                    "{s} [];\n",
                    .{node_ptr.*.value},
                );
            }

            var edge_set = try self.edgeSet(self.allocator);
            defer edge_set.deinit();

            var edge_iter = edge_set.keyIterator();
            while (edge_iter.next()) |edge| {
                try writer.print(
                    "{s} -- {s} [label={}];\n",
                    .{
                        edge.this.value,
                        edge.that.value,
                        edge.weight,
                    },
                );
            }

            try writer.writeAll("}\n");
        }
    };
}

// TODO: test memory under rare conditions:
// - allocator failure
// - inside add: allocator succeeds but list append fails

test "graph memory management" {
    std.testing.log_level = .debug;
    const allocator = std.testing.allocator;

    var node1 = try Node([]const u8, u32).create(allocator, "n1");
    defer node1.destroy();

    var node2 = try Node([]const u8, u32).create(allocator, "n2");
    defer node2.destroy();

    try node1.addEdge(node2, 123);
}

test "iterate over single node" {
    const allocator = std.testing.allocator;

    var node1 = try Node([]const u8, u32).create(allocator, "n1");
    defer node1.destroy();

    // var edge_iter = (try node1.edgeSet(allocator)).keyIterator();
    // Print nodes' values
    // while (edge_iter.next()) |edge_ptr| {
    //     print("({s})--[{}]--({s})\n", .{
    //         edge_ptr.this.value,
    //         edge_ptr.weight,
    //         edge_ptr.that.value,
    //     });
    // }
}

// test "iterate over edges" {
//     const allocator = std.testing.allocator;

//     var node1 = try Node([]const u8, u32).create(allocator, "n1");
//     defer node1.destroy();
//     var node2 = try Node([]const u8, u32).create(allocator, "n2");
//     defer node2.destroy();

//     try node1.addEdge(node2, 123);
//     // Allocate the current edges
//     var edges = try node1.edgeSet(allocator);
//     defer edges.deinit();
//     // The hashmap is used as a set, so it only has keys
//     var edge_iter = edges.keyIterator();

//     // Print their nodes' values and the weights between them
//     while (edge_iter.next()) |edge| {
//         print("({s})--[{}]--({s})\n", .{
//             edge.this.value,
//             edge.weight,
//             edge.that.value,
//         });
//     }
// }

// test "dot export" {
//     const allocator = std.testing.allocator;

//     var node1 = try Node([]const u8, u32).create(allocator, "n1");
//     defer node1.destroy();
//     var node2 = try Node([]const u8, u32).create(allocator, "n2");
//     defer node2.destroy();

//     try node1.addEdge(node2, 123);

//     _ = try node1.exportDot(allocator, std.io.getStdOut().writer(), .{});
// }
