// For search algorithms that don't have heuristics or cost functions.
const std = @import("std");
const ArrayList = std.ArrayList;
const print = std.debug.print;
const panic = std.debug.panic;
const TailQueue = std.TailQueue;
const graph = @import("graph.zig");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const LinearFifo = std.fifo.LinearFifo;

pub fn bfs(
    allocator: Allocator,
    initial: anytype, // a node pointer type
    context: anytype, // anytype
    goalTest: fn (context: @TypeOf(context), node: @TypeOf(initial)) bool,
) ?@TypeOf(initial) {
    const Node = @TypeOf(initial);
    const frontier = LinearFifo(u8, .Dynamic).init(allocator);
    defer frontier.deinit();

    var explored = AutoHashMap(*Node, void).init(allocator);
    defer explored.deinit();

    var node = initial;
    while (!goalTest(context, frontier.read())) {
        //for
        try frontier.write(node.edges.keys());
    }
    return node;
}

// Uses a `TailQueue` as a FIFO data structure.
// pub fn dfs(
//     allocator: Allocator,
//     initial: anytype, // a node pointer type
//     context: anytype, // anytype
//     goalTest: fn (context: @TypeOf(context), node: @TypeOf(initial)) bool,
// ) ?@TypeOf(initial) {
//     const Node = @TypeOf(initial);
//     // Initially, the frontier consists of just the start node.
//     const frontier = TailQueue(Node).init(allocator);
//     defer frontier.deinit();

//     _ = goalTest;
//     var node = initial;
//     while (!goalTest(context, node)) {
//         frontier.popFirst();
//         // for
//         try fifo.write("HELLO");
//     }
//     return node;
// }

test "bfs depth 0" {
    const NodeType = graph.Node([]const u8, u32);
    const allocator = std.testing.allocator;
    const node1 = try NodeType.init(allocator, "n1");
    defer node1.deinit(allocator);

    if (bfs(allocator, node1, node1, struct {
        pub fn pred(initial: *NodeType, node: *NodeType) bool {
            return node == initial;
        }
    }.pred)) |goal| {
        if (goal != node1)
            // Shouldn't be possible
            panic("Incorrect goal found", .{});
    } else {
        panic("Node not found", .{});
    }
}

test "dfs depth 1" {
    const allocator = std.testing.allocator;
    var node1 = try graph.Node([]const u8, u32).init(allocator, "n1");
    defer node1.destroy();
    var node2 = try graph.Node([]const u8, u32).initWithEdges(allocator, "n2", &.{});
    defer node2.destroy();
    var node3 = try graph.Node([]const u8, u32).initWithEdges(allocator, "n3", &.{});
    defer node3.destroy();
    const node4 = try graph.Node([]const u8, u32).initWithEdges(
        allocator,
        "n4",
        // Segfaults if an anon struct is used instead
        &[_]graph.Node([]const u8, u32).Edge{
            .{
                .that = node1,
                .weight = 41,
            },
        },
    );
    defer node4.destroy();
}
