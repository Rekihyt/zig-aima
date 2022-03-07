const std = @import("std");
const ArrayList = std.ArrayList;
const HashMap = std.HashMap;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;

// pub fn Node(comptime Val: type, comptime Weight: type) type {

// }

/// So far is just a graph.
/// `Val` is the type of values stored in `Node`s.
/// `Weight` is the type of weights or costs between `Node`s.
pub fn DiGraph(comptime Val: type, comptime Weight: type) type {
    return struct {
        pub const Self = @This();
        // pub const ThisNode = Node(Val, Weight);
        pub const Node = struct {
            pub const ThisHashMap = AutoHashMap(*Node, Weight);

            val: Val,

            adjacents: ?ThisHashMap,
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

        pub fn add(self: *Self, val: Val, adjacents: ?Node.ThisHashMap) !void {
            try self.nodes.append(Node{
                .val = val,
                .adjacents = adjacents,
            });
            // return node;
        }

        pub fn deinit(self: *Self) void {
            for (self.nodes) |node| {
                node.deinit();
            }
            self.nodes.deinit();
        }
    };
}
