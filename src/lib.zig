pub const ser = struct {
    const Interfaces = struct {
        pub usingnamespace @import("ser/interfaces/serializer.zig");
        pub usingnamespace @import("ser/interfaces/visitor.zig");
        pub const Map = @import("ser/interfaces/serialize/map.zig").Serialize;
        pub const Sequence = @import("ser/interfaces/serialize/sequence.zig").Serialize;
        pub const Structure = @import("ser/interfaces/serialize/structure.zig").Serialize;
        pub const Tuple = Sequence;
    };

    const Implementations = struct {
        pub const ArrayListVisitor = @import("ser/impls/visitors/array_list.zig");
        pub const StringHashMapVisitor = @import("ser/impls/visitors/string_hash_map.zig");
    };

    pub usingnamespace Interfaces;
    pub usingnamespace Implementations;
};

pub const de = struct {
    const Interfaces = struct {
        pub usingnamespace @import("de/interfaces/deserializer.zig");
        pub usingnamespace @import("de/interfaces/seed.zig");
        pub usingnamespace @import("de/interfaces/visitor.zig");
        pub const SequenceAccess = @import("de/interfaces/access/sequence.zig").Access;
    };

    const Implementations = struct {
        pub usingnamespace @import("de/impls/seed.zig");
        pub const BoolVisitor = @import("de/impls/visitors/bool.zig");
        pub const FloatVisitor = @import("de/impls/visitors/float.zig").Visitor;
        pub const IntVisitor = @import("de/impls/visitors/int.zig").Visitor;
        pub const VoidVisitor = @import("de/impls/visitors/void.zig");
    };

    pub usingnamespace Interfaces;
    pub usingnamespace Implementations;
};

pub usingnamespace @import("ser/serialize.zig");
pub usingnamespace @import("de/deserialize.zig");
