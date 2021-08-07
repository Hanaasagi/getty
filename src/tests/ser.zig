const std = @import("std");
const ser = @import("getty").ser;

const mem = std.mem;
const meta = std.meta;
const testing = std.testing;

const Elem = enum {
    Undefined,
    Bool,
    Element,
    Entry,
    Field,
    Float,
    Int,
    Key,
    MapEnd,
    MapStart,
    Null,
    SequenceEnd,
    SequenceStart,
    String,
    StructEnd,
    StructStart,
    TupleEnd,
    TupleStart,
    Value,
    Variant,
};

const Serializer = struct {
    buf: [4]Elem = .{.Undefined} ** 4,
    idx: usize = 0,

    const Self = @This();

    const Ok = void;
    const Error = mem.Allocator.Error;

    const Map = *Self;
    const Sequence = *Self;
    const Structure = *Self;
    const Tuple = *Self;

    /// Implements `getty.ser.Serializer`.
    pub fn serializer(self: *Self) S {
        return .{ .context = self };
    }

    const S = ser.Serializer(
        *Self,
        Ok,
        Error,
        Map,
        Sequence,
        Structure,
        Tuple,
        _S.serializeBool,
        _S.serializeFloat,
        _S.serializeInt,
        _S.serializeNull,
        _S.serializeSequence,
        _S.serializeString,
        _S.serializeMap,
        _S.serializeStruct,
        _S.serializeTuple,
        _S.serializeVariant,
    );

    const _S = struct {
        fn serializeBool(self: *Self, _: bool) Error!Ok {
            self.buf[self.idx] = .Bool;
            self.idx += 1;
        }

        fn serializeFloat(self: *Self, _: anytype) Error!Ok {
            self.buf[self.idx] = .Float;
            self.idx += 1;
        }

        fn serializeInt(self: *Self, _: anytype) Error!Ok {
            self.buf[self.idx] = .Int;
            self.idx += 1;
        }

        fn serializeNull(self: *Self) Error!Ok {
            self.buf[self.idx] = .Null;
            self.idx += 1;
        }

        fn serializeSequence(self: *Self, length: ?usize) Error!Sequence {
            _ = length;

            self.buf[self.idx] = .SequenceStart;
            self.idx += 1;

            return self;
        }

        fn serializeString(self: *Self, _: anytype) Error!Ok {
            self.buf[self.idx] = .String;
            self.idx += 1;
        }

        fn serializeMap(self: *Self, length: ?usize) Error!Map {
            _ = length;

            self.buf[self.idx] = .MapStart;
            self.idx += 1;

            return self;
        }

        fn serializeStruct(self: *Self, name: []const u8, length: usize) Error!Structure {
            _ = name;
            _ = length;

            self.buf[self.idx] = .StructStart;
            self.idx += 1;

            return self;
        }

        fn serializeTuple(self: *Self, length: ?usize) Error!Tuple {
            _ = length;

            self.buf[self.idx] = .TupleStart;
            self.idx += 1;

            return self;
        }

        fn serializeVariant(self: *Self, value: anytype) Error!Ok {
            _ = value;

            self.buf[self.idx] = .Variant;
            self.idx += 1;
        }
    };

    /// Implements `getty.ser.Sequence`.
    pub fn sequence(self: *Self) SE {
        return .{ .context = self };
    }

    const SE = ser.Sequence(
        *Self,
        Ok,
        Error,
        _SE.serializeElement,
        _SE.end,
    );

    const _SE = struct {
        fn serializeElement(self: *Self, value: anytype) Error!void {
            _ = value;

            self.buf[self.idx] = .Element;
            self.idx += 1;
        }

        fn end(self: *Self) Error!Ok {
            self.buf[self.idx] = .SequenceEnd;
            self.idx += 1;
        }
    };

    /// Implements `getty.ser.Map`.
    pub fn map(self: *Self) M {
        return .{ .context = self };
    }

    const M = ser.Map(
        *Self,
        Ok,
        Error,
        _M.serializeKey,
        _M.serializeValue,
        _M.serializeEntry,
        _M.end,
    );

    const _M = struct {
        fn serializeKey(self: *Self, key: anytype) Error!void {
            _ = key;

            self.buf[self.idx] = .Key;
            self.idx += 1;
        }

        fn serializeValue(self: *Self, value: anytype) Error!void {
            _ = value;

            self.buf[self.idx] = .Value;
            self.idx += 1;
        }

        fn serializeEntry(self: *Self, key: anytype, value: anytype) Error!void {
            _ = key;
            _ = value;

            self.buf[self.idx] = .Entry;
            self.idx += 1;
        }

        fn end(self: *Self) Error!Ok {
            self.buf[self.idx] = .MapEnd;
            self.idx += 1;
        }
    };

    /// Implements `getty.ser.Structure`.
    pub fn structure(self: *Self) ST {
        return .{ .context = self };
    }

    const ST = ser.Structure(
        *Self,
        Ok,
        Error,
        _ST.serializeField,
        _ST.end,
    );

    const _ST = struct {
        fn serializeField(self: *Self, comptime key: []const u8, value: anytype) Error!void {
            _ = key;
            _ = value;

            self.buf[self.idx] = .Field;
            self.idx += 1;
        }

        fn end(self: *Self) Error!Ok {
            self.buf[self.idx] = .StructEnd;
            self.idx += 1;
        }
    };

    /// Implements `getty.ser.Tuple`.
    pub fn tuple(self: *Self) T {
        return .{ .context = self };
    }

    const T = ser.Tuple(
        *Self,
        Ok,
        Error,
        _T.serializeElement,
        _T.end,
    );

    const _T = struct {
        fn serializeElement(self: *Self, value: anytype) Error!void {
            _ = value;

            self.buf[self.idx] = .Element;
            self.idx += 1;
        }

        fn end(self: *Self) Error!Ok {
            self.buf[self.idx] = .TupleEnd;
            self.idx += 1;
        }
    };
};

test "Array" {
    try t([_]i8{ 1, 2 }, &.{ .SequenceStart, .Element, .Element, .SequenceEnd });
}

test "Boolean" {
    try t(true, &.{ .Bool, .Undefined, .Undefined, .Undefined });
    try t(false, &.{ .Bool, .Undefined, .Undefined, .Undefined });
}

test "Enum" {
    try t(enum { Foo }.Foo, &.{ .Variant, .Undefined, .Undefined, .Undefined });
    try t(.Foo, &.{ .Variant, .Undefined, .Undefined, .Undefined });
}

test "Error value" {
    try t(error.Elem, &.{ .String, .Undefined, .Undefined, .Undefined });
}

test "Integer" {
    try t(1, &.{ .Int, .Undefined, .Undefined, .Undefined });
    try t(@as(u8, 1), &.{ .Int, .Undefined, .Undefined, .Undefined });
    try t(@as(i8, -1), &.{ .Int, .Undefined, .Undefined, .Undefined });
}

test "Optional" {
    try t(@as(?bool, true), &.{ .Bool, .Undefined, .Undefined, .Undefined });
    try t(@as(?bool, null), &.{ .Null, .Undefined, .Undefined, .Undefined });
}

test "String" {
    try t("h\x65llo", &.{ .String, .Undefined, .Undefined, .Undefined });
    try t(&[_]u8{65}, &.{ .String, .Undefined, .Undefined, .Undefined });
}

test "Struct" {
    const A = struct {
        x: i32,
        y: i32,
    };

    const B = struct {
        x: i32,
        y: i32,

        /// Skips serializing `y`.
        pub fn serialize(self: @This(), serializer: anytype) !void {
            const s = (try serializer.serializeStruct(@typeName(@This()), meta.fields(@This()).len)).structure();
            try s.serializeField("x", @field(self, "x"));
            try s.end();
        }
    };

    const a = A{ .x = 0, .y = 0 };
    const b = B{ .x = 0, .y = 0 };

    try t(a, &.{ .StructStart, .Field, .Field, .StructEnd });
    try t(b, &.{ .StructStart, .Field, .StructEnd, .Undefined });
}

test "Tagged union" {
    const Union = union(enum) { Int: u8, Bool: bool };

    try t(Union{ .Int = 0 }, &.{ .Int, .Undefined, .Undefined, .Undefined });
    try t(Union{ .Bool = true }, &.{ .Bool, .Undefined, .Undefined, .Undefined });
}

test "Tuple" {
    try t(.{ 1, true }, &.{ .TupleStart, .Element, .Element, .TupleEnd });
}

test "Vector" {
    try t(@splat(2, @as(u32, 1)), &.{ .SequenceStart, .Element, .Element, .SequenceEnd });
}

fn t(input: anytype, output: []const Elem) !void {
    var s = Serializer{};
    const serializer = s.serializer();

    try ser.serialize(&serializer, input);
    try testing.expectEqualSlices(Elem, &s.buf, output);
}

comptime {
    testing.refAllDecls(@This());
}
