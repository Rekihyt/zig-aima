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
// - Optimize this further with hueristics like starting to search
// for a place to create a new node at a nullable node at the last deleted node.
//

/// `Value` is the type of values stored in `Node`s. The memory for these is
/// only ever referenced.
/// `Weight` is the type of weights or costs between `Node`s. Weights are
/// allocated twice, once in each nodes' edge hashmap.
pub fn Graph(comptime Value: type, comptime Weight: type) type {
    return struct {
        pub const Self = @This();

        const Node = struct {
            value: Value,

            edges: AutoHashMap(*Node, Weight),

            /// Add an edge to this graph, allocating twice in both nodes' hashmaps.
            /// If the edge already exists, the weight will be updated.
            pub fn addEdge(self: *Node, other: *Node, weight: Weight) !void {
                try self.edges.put(other, weight);
                try other.edges.put(self, weight);
            }

            // TODO: remove edge fn
        };

        /// An edges between two node pointers. Isn't used by Nodes to store
        /// their edges (a hashmap is used instead) but rather when enumerating
        /// all edges in the graph.
        pub const Edge = struct {
            this: *Node,
            that: *Node,
            weight: Weight,
        };

        allocator: Allocator,

        /// Keeps track of the nodes allocated
        nodes: ArrayList(*Node),

        pub fn init(allocator: Allocator) Self {
            return Self{
                .allocator = allocator,
                .nodes = ArrayList(*Node).init(allocator),
            };
        }

        /// Add a node to this graph, allocating and creating a copy of Value.
        pub fn addNode(self: *Self, value: Value) !*Node {
            var node = try self.allocator.create(Node);
            // If this fails, do not init a new node (Keep this line above `node.* = ...`)
            try self.nodes.append(node);
            node.* = Node{
                .value = value,
                .edges = AutoHashMap(*Node, Weight).init(self.allocator),
            };
            return node;
        }

        // TODO: removeNode

        /// Free the memory backing this node, and remove it from the graph.
        pub fn deinit(self: *Self) void {
            // Free each node's inner memory first.
            for (self.nodes.items) |node| {
                // Free the list of edges
                node.edges.deinit();
                // Then free the node itself
                self.allocator.destroy(node);
            }
            self.nodes.deinit();
        }

        /// Returns a set of all edges in this graph.
        /// Caller frees (calls `deinit`).
        pub fn edges(
            self: Self,
            allocator: Allocator,
        ) AutoHashMap(*Node, void) {
            // Use a 0 size value (void) to use a hashmap as a set, in order
            // to avoid listing edges twice.
            var edge_set = AutoHashMap(Edge, void).init(allocator);
            for (self.nodes.items) |node| {
                var edge_iter = node.edges.iterator();
                while (edge_iter.next()) |edge_entry| {
                    edge_set.put(Edge{
                        .this = node,
                        .that = edge_entry.key,
                        .weight = edge_entry.value,
                    });
                }
            }
        }

        /// Writes the graph out in dot (graphviz) to the given `writer`.
        pub fn exportDot(self: Self, writer: anytype) !void {
            writer.write("DiGraph {\n");
            defer writer.write("}\n");

            _ = self.nodes.iterator();

            writer.print("{}\n", .{});
            writer.print("{} -> {}\n", .{});
        }
    };
}

// TODO: test memory under rare conditions:
// - allocator failure
// - inside add: allocator succeeds but list append fails

test "graph memory management" {
    const allocator = std.testing.allocator;

    var graph = Graph([]const u8, u32).init(allocator);
    defer graph.deinit();

    var node1 = try graph.addNode("asd");
    var node2 = try graph.addNode("asd2");

    try node1.addEdge(node2, 123);
}

test "simple cycle" {
    const allocator = std.testing.allocator;

    var graph = Graph([]const u8, u32).init(allocator);
    defer graph.deinit();

    var node1 = try graph.addNode("asd");
    var node2 = try graph.addNode("asd2");

    try node1.addEdge(node2, 123);
    try node2.addEdge(node1, 123);
}

test "edges" {
    const allocator = std.testing.allocator;

    var graph = Graph([]const u8, u32).init(allocator);
    defer graph.deinit();

    var node1 = try graph.addNode("asd");
    var node2 = try graph.addNode("asd2");

    try node1.addEdge(node2, 123);

    for (graph.edges(std.testing.allocator)) |edge| {}
}
