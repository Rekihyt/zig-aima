// For search algorithms that don't have heuristics or cost functions.
const std = @import("std");
const ArrayList = std.ArrayList;
const print = std.debug.print;
const Node = @import("graph.zig").Node;
const allocator = std.testing.allocator;
const testing = std.testing;
const mem = std.mem;

pub fn dfs(comptime NodeType: type, node: *NodeType, goalTest: anytype) ?*NodeType {
    var edge_iter = node.edges.keyIterator();
    while (edge_iter.next()) |adjacent| {
        // return if (goalTest(adjacent.*))
        return if (adjacent.*.value == goalTest)
            adjacent.*
        else
            dfs(NodeType, adjacent.*, goalTest);
    }
    return null;
}

test "dfs" {
    const NodeType = Node(u8);
    // Create a weightless graph
    var initial = try NodeType.add(allocator, 0);
    defer initial.destroy();
    // var middle = try NodeType.add(allocator, 1);
    // defer middle.destroy();
    var goal = try NodeType.add(allocator, 2);
    defer goal.destroy();
    try initial.edges.put(goal, {});
    try goal.edges.put(initial, {});
    try initial.addEdge(goal);
    const result = dfs(NodeType, initial, 2);
    _ = result;
    // try testing.expect(initial.value == 0);
    _ = initial.edges.get(goal).? == {};
    // try testing.expect(initial.edges.get(goal) == null);
}

pub fn intTest1(node: anytype) bool {
    return node.value == 2;
}

test "dfs string" {
    const NodeType = Node([]const u8, void);
    // Create a weightless graph
    var initial = try NodeType.add(allocator, "initial");
    defer initial.destroy();
    var middle = try NodeType.add(allocator, "middle");
    defer middle.destroy();
    var goal = try NodeType.add(allocator, "goal");
    defer goal.destroy();
    try initial.addEdge(middle, {});
    try middle.addEdge(goal, {});
    // std.debug.print("{}", .{goal});
    _ = dfs(NodeType, initial, "goal"); // != null;
}

pub fn strTest1(node: anytype) bool {
    _ = node;
    return false;
    // return mem.eql(u8, node.value, "goal");
}

// Zig bug tests

// test "zig nullable comparison" {
//     var y: ?void = {};
//     _ = y == {};
// }

// test "zig nullable pointer comparison" {
// var x: ?*void = {};
// _ = x == &{};
// _ = x == null;
// }
