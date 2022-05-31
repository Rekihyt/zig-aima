// For search algorithms that don't have heuristics or cost functions.
const std = @import("std");
const ArrayList = std.ArrayList;
const print = std.debug.print;
const panic = std.debug.panic;
const TailQueue = std.TailQueue;
const Node = @import("graph.zig").Node;

// Uses a `TailQueue` as a LIFO data structure.
pub fn dfs(
    allocator: Allocator,
    initial: anytype,
    context: anytype,
    goalTest: fn (context: @TypeOf(initial), node: @TypeOf(initial)) bool,
) ?*@TypeOf(initial) {
    // Initially, the frontier consists of just the start node.
    const frontier = TailQueue(NodeType).init(allocator);
    _ = goalTest;
    var node = initial;
    while (!goalTest(context, node)) {
        frontier.
    }
    return node;
}

const allocator = std.testing.allocator;

test "dfs depth 0" {
    const NodeType = Node([]const u8, u32);
    const node1 = try NodeType.init(allocator, "n1");
    defer node1.deinit(allocator);

    if (dfs(
        node1,
        node1,
        struct {
            pub fn pred(initial, node: *NodeType) bool {
                return node == initial;
            }
        }.pred,
    )) |goal| {
        if (goal != node1)
            // Shouldn't be possible
            panic("Incorrect goal found");
    } else {
        panic("Node not found");
    }
}

test "dfs depth 1" {
    var node1 = try Node([]const u8, u32).init(allocator, "n1");
    defer node1.destroy();
    var node2 = try Node([]const u8, u32).initWithEdges(allocator, "n2", &.{});
    defer node2.destroy();
    var node3 = try Node([]const u8, u32).initWithEdges(allocator, "n3", &.{});
    defer node3.destroy();
    const node4 = try Node([]const u8, u32).initWithEdges(
        allocator,
        "n4",
        // Segfaults if an anon struct is used instead
        &[_]Node([]const u8, u32).Edge{
            .{
                .that = node1,
                .weight = 41,
            },
        },
    );
    defer node4.destroy();
}
