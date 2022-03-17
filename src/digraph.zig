const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

pub fn Graph(comptime Val: type, comptime Weight: type) type {
    return struct {
        pub const Self = @This();
        pub const Val = Val;
        pub const Weight = Weight;
    };
}
