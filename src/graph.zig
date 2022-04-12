const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const helpers = @import("helpers.zig");
const mode = @import("builtin").mode;
const dbg = helpers.dbg;

/// A node in an undirected graph. It holds a value, and a hashmap representing
/// edges where each entry stores the adjacent node pointer as its key and the
/// weight as its value.
/// `Value` is the type of data to be stored in `Node`s, with copy semantics.
/// `Weight` is the type of weights or costs between `Node`s. Weights are
/// allocated twice, once in each nodes' edge hashmap.
pub fn Node(comptime Value: type, comptime Weight: type) type {
    return struct {
        pub const Self = @This();
        pub const EdgeMap = AutoHashMap(*Self, Weight);

        pub const Edge = struct {
            that: *Self,
            weight: Weight,
        };

        /// An edges between two node pointers. Isn't used by Nodes to store
        /// their edges (a hashmap is used instead) but rather when enumerating
        /// all edges in the graph.
        pub const FullEdge = struct {
            this: *Self,
            that: *Self,
            weight: Weight,
        };

        allocator: Allocator,
        value: Value,
        /// Individual edges are stored twice, once in each node in a pair
        /// that form the edge. These are separate from `FullEdge` structs, which
        /// keep track of pairs of nodes.
        edges: EdgeMap,

        /// Creates a new node, allocating a copy of Value.
        pub fn add(allocator: Allocator, value: Value) !*Self {
            var node = try allocator.create(Self);
            node.* = Self{
                .allocator = allocator,
                .value = value,
                .edges = EdgeMap.init(allocator),
            };
            return node;
        }

        /// Same as `add`, but initializes this node's hashmap to the edges
        /// passed in. Duplicate edges will only have the last copy saved.
        pub fn addWithEdges(
            allocator: Allocator,
            value: Value,
            edges: []const Edge,
        ) !*Self {
            var node = try add(allocator, value);
            // Add edges into the hashmap.
            for (edges) |edge|
                try node.addEdge(edge.that, edge.weight);

            return node;
        }

        /// Puts an edge entry into each node's hashmap.
        /// If the edge already exists, the weight will be updated.
        pub fn addEdge(self: *Self, other: *Self, weight: Weight) !void {
            // Use of `put` assumes `edges` was passed in with no
            // duplicates, otherwise will overwrite the weight.
            try self.edges.put(other, weight);
            // Add this node to the adjacent's edges
            try other.edges.put(self, weight);
        }

        // TODO: removeEdge

        /// Removes a node and all its references (equivalent to calling
        /// detach and destroy, but faster).
        /// You probably want this function instead of detach/destroy.
        pub fn remove(self: *Self) void {
            self.detach(); // Remove incoming edges
            self.destroy(); // Free
        }

        /// Detach adjacent nodes (erase their references of this node).
        /// Doesn't release the memory allocated for edges, as this function
        /// is intended for reusing a node.
        pub fn detach(self: *Self) void {
            var edge_iter = self.edges.keyIterator();
            // Free incoming references to this node in adjacents.
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
            // Free outgoing references
            self.edges.clearRetainingCapacity();
        }

        /// Free the memory backing this node, and remove it from the graph.
        /// Incoming edges will no longer be valid, so this function should
        /// only be called on detached nodes (ones without edges).
        pub fn destroy(self: *Self) void {
            self.edges.deinit(); // Free this list of edges
            self.allocator.destroy(self); // Free this node
        }

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

        /// Returns a set of all edges in this graph.
        /// Caller frees (calls `deinit`).
        pub fn edgeSet(
            self: *Self,
            allocator: Allocator,
        ) !AutoHashMap(FullEdge, void) {
            // Use a 0 size value (void) to use a hashmap as a set, in order
            // to avoid listing edges twice.
            var edge_set = AutoHashMap(FullEdge, void).init(allocator);

            // Get a view of all nodes
            var node_set = try self.nodePtrs(allocator);
            defer node_set.deinit();
            var nodes_iter = node_set.keyIterator();

            while (nodes_iter.next()) |node_ptr| { // For each node
                var edge_iter = node_ptr.*.edges.iterator(); // Get its edges
                while (edge_iter.next()) |edge_entry| { // For each edge
                    if (!edge_set.contains( // If it's reverse isn't in yet
                        FullEdge{
                            .this = edge_entry.key_ptr.*,
                            .that = node_ptr.*,
                            .weight = edge_entry.value_ptr.*,
                        },
                    ))
                        // Overwrite if the edge exists already
                        try edge_set.put(
                            FullEdge{
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
            _ = dot_settings; // TODO
            try writer.writeAll("Graph {\n");

            var node_set = try self.nodePtrs(allocator);
            defer node_set.deinit();
            var nodes_iter = node_set.keyIterator();
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

    var node1 = try Node([]const u8, u32).add(allocator, "n1");
    defer node1.destroy();

    var node2 = try Node([]const u8, u32).add(allocator, "n2");
    defer node2.destroy();

    try node1.addEdge(node2, 123);
}

test "iterate over single node" {
    const allocator = std.testing.allocator;

    var node1 = try Node([]const u8, u32).add(allocator, "n1");
    defer node1.destroy();

    var edges = try node1.edgeSet(allocator);
    defer edges.deinit();
    var edge_iter = edges.keyIterator();
    // Print nodes' values
    while (edge_iter.next()) |edge_ptr| {
        print("({s})--[{}]--({s})\n", .{
            edge_ptr.this.value,
            edge_ptr.weight,
            edge_ptr.that.value,
        });
    }
}

test "iterate over edges" {
    const allocator = std.testing.allocator;
    var node1 = try Node([]const u8, u32).add(allocator, "n1");
    defer node1.destroy();
    var node2 = try Node([]const u8, u32).addWithEdges(allocator, "n2", &.{});
    defer node2.destroy();
    var node3 = try Node([]const u8, u32).addWithEdges(allocator, "n3", &.{});
    defer node3.destroy();
    const node4 = try Node([]const u8, u32).addWithEdges(
        allocator,
        "n4",
        // Segfaults if an anon struct is used instead
        &[_]Node([]const u8, u32).Edge{
            .{ .that = node1, .weight = 41 },
        },
    );
    defer node4.destroy();

    try node1.addEdge(node2, 12);
    try node3.addEdge(node1, 31);
    try node2.addEdge(node1, 21); // should update 12 to 21
    try node2.addEdge(node1, 21); // should be a no op
    try node2.addEdge(node3, 23);

    // Allocate the current edges
    var edges = try node1.edgeSet(allocator);
    defer edges.deinit();
    // The hashmap is used as a set, so it only has keys
    var edge_iter = edges.keyIterator();

    // Print their nodes' values and the weights between them
    while (edge_iter.next()) |edge| {
        print("({s})--[{}]--({s})\n", .{
            edge.this.value,
            edge.weight,
            edge.that.value,
        });
    }
}

test "dot export" {
    const allocator = std.testing.allocator;

    var node1 = try Node([]const u8, u32).add(allocator, "n1");
    defer node1.destroy();
    var node2 = try Node([]const u8, u32).add(allocator, "n2");
    defer node2.destroy();

    try node1.addEdge(node2, 123);

    _ = try node1.exportDot(allocator, std.io.getStdOut().writer(), .{});
}
