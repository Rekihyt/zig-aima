/// This file is for cute stuff that would be in the std lib if it were
/// actually needed there.
const std = @import("std");

/// Appends an iter (anything that implements `next()`) to anything that
/// implements `add()`.
pub fn appendIter(list: anytype, iter: anytype) !usize {
    var count = 0;
    while (iter.next()) |element| {
        try list.add(element);
        count += 1;
    }
    return count;
}
