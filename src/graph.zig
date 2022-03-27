const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const helpers = @import("helpers");

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
        edges: AutoHashMap(*Node, Weight),

        /// Creates a new node, allocating a copy of Value.
        pub fn init(allocator: Allocator, value: Value) !*Node {
            var node = try allocator.create(Node);
            node.* = Node{
                .value = value,
                .edges = AutoHashMap(*Node, Weight).init(self.allocator),
            };
            return node;
        }

        // TODO: removeNode

        /// Free the memory backing this node, and remove it from the graph.
        pub fn deinit(self: *Self) void {
            // Free each reference to this node in adjacents.
            for (self.edges.keyIterator) |adjacent| {
                adjacent.edges.remove(self);
            }
            // Free the list of edges
            node.edges.deinit();
        }

        /// An edges between two node pointers. Isn't used by Nodes to store
        /// their edges (a hashmap is used instead) but rather when enumerating
        /// all edges in the graph.
        pub const Edge = struct {
            this: *Node,
            that: *Node,
            weight: Weight,
        };

        /// Returns a set of all nodes in this graph.
        /// Caller frees (calls `deinit`).
        pub fn nodes(
            self: Self,
            allocator: Allocator,
        ) !AutoHashMap(Edge, void) {
            var node_set = AutoHashMap(*Node, void).init(allocator);
            // A stack to add nodes reached across edges
            var to_visit = ArrayList(*Node).init(allocator);
            defer to_visit.deinit();

            // Greedily add all neighbors to `to_visit`, then loop until
            // no new neighbors are found.
            try to_visit.add(self);
            while (to_visit.popOrNull()) |node| {
                // If the node is unvisited
                if (!node_set.contains(node)) {
                    // Add to set (marks as visited)
                    node_set.put(node);
                    // Save its adjacent nodes to check later
                    for (self.edges.keyIterator) |adjacent| {
                        _ = helpers.appendIter(to_visit, that.edges.iter());
                    }
                }
            }
            return node_set;
        }

        /// Returns a set of all edges in this graph.
        /// Caller frees (calls `deinit`).
        pub fn edges(
            self: Self,
            allocator: Allocator,
        ) !AutoHashMap(Edge, void) {
            // Use a 0 size value (void) to use a hashmap as a set, in order
            // to avoid listing edges twice.
            var edge_set = AutoHashMap(Edge, void).init(allocator);
            for (self.nodes.items) |node| {
                var edge_iter = node.edges.iterator();
                while (edge_iter.next()) |edge_entry| {
                    try edge_set.put(
                        Edge{
                            .this = node,
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
            self: Self,
            writer: anytype,
            dot_settings: DotSettings,
        ) !void {
            _ = dot_settings;
            try writer.writeAll("DiGraph {\n");

            for (self.nodes.items) |node| {
                try writer.print(
                    "{s} [];\n",
                    .{node.value},
                );
            }

            var edge_set = try self.edges(self.allocator);
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
    const allocator = std.testing.allocator;

    var node = Node([]const u8, u32).init(allocator);
    defer node.deinit();

    var node1 = try node.init("n1");
    var node2 = try node.init("n2");

    try node1.addEdge(node2, 123);
}

test "iterate over single node" {
    const allocator = std.testing.allocator;

    var node1 = Node([]const u8, u32).init(allocator);
    defer node1.deinit();

    var node1 = try node.init("n1");

    // Print nodes' values
    while (node1.nodes()) |edge| {
        print("({s})--[{}]--({s})\n", .{
            edge.this.value,
            edge.weight,
            edge.that.value,
        });
    }
}

test "iterate over edges" {
    const allocator = std.testing.allocator;

    var node = Node([]const u8, u32).init(allocator);
    defer node.deinit();

    var node1 = try node.init("n1");
    var node2 = try node.init("n2");

    try node1.addEdge(node2, 123);
    // Allocate the current edges
    var edges = try node.edges(allocator);
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
    std.testing.log_level = .debug;
    const allocator = std.testing.allocator;

    var node = Node([]const u8, u32).init(allocator);
    defer node.deinit();

    var node1 = try node.init("n1");
    var node2 = try node.init("n2");
    try node1.addEdge(node2, 123);

    _ = try node.exportDot(std.io.getStdOut().writer(), .{});
}
