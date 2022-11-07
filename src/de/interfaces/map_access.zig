const std = @import("std");

const de = @import("../../de.zig");

pub fn MapAccess(
    comptime Context: type,
    comptime E: type,
    comptime nextKeySeedFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value {
            unreachable;
        }
    }.f),
    comptime nextValueSeedFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.MapAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = E;

            pub fn nextKeySeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) KeyReturn(@TypeOf(seed)) {
                return try nextKeySeedFn(self.context, allocator, seed);
            }

            pub fn nextValueSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) ValueReturn(@TypeOf(seed)) {
                return try nextValueSeedFn(self.context, allocator, seed);
            }

            //pub fn nextEntrySeed(self: Self, kseed: anytype, vseed: anytype) Error!?std.meta.Tuple(.{ @TypeOf(kseed).Value, @TypeOf(vseed).Value }) {
            //_ = self;
            //}

            pub fn nextKey(self: Self, allocator: ?std.mem.Allocator, comptime K: type) !?K {
                var seed = de.de.DefaultSeed(K){};
                const ds = seed.seed();

                return try self.nextKeySeed(allocator, ds);
            }

            pub fn nextValue(self: Self, allocator: ?std.mem.Allocator, comptime V: type) !V {
                var seed = de.de.DefaultSeed(V){};
                const ds = seed.seed();

                return try self.nextValueSeed(allocator, ds);
            }

            //pub fn nextEntry(self: Self, comptime K: type, comptime V: type) !?std.meta.Tuple(.{ K, V }) {
            //_ = self;
            //}

            fn KeyReturn(comptime Seed: type) type {
                comptime de.concepts.@"getty.de.Seed"(Seed);

                return Error!?Seed.Value;
            }

            fn ValueReturn(comptime Seed: type) type {
                comptime de.concepts.@"getty.de.Seed"(Seed);

                return Error!Seed.Value;
            }
        };

        pub fn mapAccess(self: Context) @"getty.de.MapAccess" {
            return .{ .context = self };
        }
    };
}