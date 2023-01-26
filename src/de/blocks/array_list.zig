const std = @import("std");
const t = @import("../testing.zig");

const ArrayListVisitor = @import("../impls/visitor/array_list.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "array_list");
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeSeq(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return ArrayListVisitor(T);
}

test "deserialize - array list" {
    {
        var expected = std.ArrayList(void).init(std.testing.allocator);
        defer expected.deinit();

        try t.run(deserialize, Visitor, &.{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        }, expected);
    }

    {
        var expected = std.ArrayList(isize).init(std.testing.allocator);
        defer expected.deinit();

        try expected.append(1);
        try expected.append(2);
        try expected.append(3);

        try t.run(deserialize, Visitor, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .I8 = 1 },
            .{ .I32 = 2 },
            .{ .I64 = 3 },
            .{ .SeqEnd = {} },
        }, expected);
    }

    {
        const free = @import("../free.zig").free;

        const Child = std.ArrayList(isize);
        const Parent = std.ArrayList(Child);

        var expected = Parent.init(std.testing.allocator);
        var a = Child.init(std.testing.allocator);
        var b = Child.init(std.testing.allocator);
        var c = Child.init(std.testing.allocator);
        defer {
            expected.deinit();
            a.deinit();
            b.deinit();
            c.deinit();
        }

        try b.append(1);
        try c.append(2);
        try c.append(3);
        try expected.append(a);
        try expected.append(b);
        try expected.append(c);

        const tokens = &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
            .{ .SeqEnd = {} },
        };

        // Test manually since the `t` function cannot recursively test
        // user-defined containers containers without ugly hacks.
        var v = Visitor(Parent){};
        const visitor = v.visitor();

        var d = t.DefaultDeserializer.init(tokens);
        const deserializer = d.deserializer();

        const got = deserialize(std.testing.allocator, Parent, deserializer, visitor) catch return error.UnexpectedTestError;
        defer free(std.testing.allocator, got);

        try std.testing.expectEqual(expected.capacity, got.capacity);
        for (got.items) |l, i| {
            try std.testing.expectEqual(expected.items[i].capacity, l.capacity);
            try std.testing.expectEqualSlices(isize, expected.items[i].items, l.items);
        }
    }
}
