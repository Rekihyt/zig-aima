const std = @import("std");
const options = @import("options");
const String = @import("std").String;
const Node = @import("graph.zig").Node;
const allocator = if (options.valgrind)
    std.heap.c_allocator
else
    std.heap.page_allocator;
const testing = std.testing;
const uninformed = @import("uninformed.zig");

const NodeI32 = struct {
    edges: std.AutoHashMap(*Node, void),
    value: i32,
};

fn testDfs(node: *NodeI32, goal: i32) ?*NodeI32 {
    var edge_iter = node.edges.keyIterator();
    return while (edge_iter.next()) |adjacent| {
        return if (adjacent.*.value == goal) {
            return adjacent.*;
        } else testDfs(adjacent.*, goal);
    } else null;
}

// This is here to test without testing allocator.
pub fn main() anyerror!void {
    // const NodeType = comptime Node([]const u8, u8);
    // Create a weightless graph
    var initial = try allocator.create(Node);
    initial.* = Node{
        .value = 1,
        .edges = std.AutoHashMap(*Node, void).init(allocator),
    };
    var middle = try allocator.create(Node);
    middle.* = Node{
        .value = 2,
        .edges = std.AutoHashMap(*Node, void).init(allocator),
    };
    var goal = try allocator.create(Node);
    goal.* = Node{
        .value = 3,
        .edges = std.AutoHashMap(*Node, void).init(allocator),
    };
    try middle.edges.put(goal, {});
    try initial.edges.put(middle, {});

    // std.debug.print("{}", .{goal});
    const result = testDfs(
        initial,
        3,
    );
    if (result) |found_goal|
        std.debug.print("Goal! {}\n", .{found_goal.value});
    try testing.expect(testDfs(initial, 3) != null);
}
