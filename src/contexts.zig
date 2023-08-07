const std = @import("std");
const util = @import("util");
const eval = @import("eval");

pub inline fn simpleCtx(sub_ctx: anytype) SimpleCtx(@TypeOf(sub_ctx)) {
    return .{ .sub_ctx = sub_ctx };
}
pub fn SimpleCtx(comptime SubCtx: type) type {
    return struct {
        sub_ctx: SubCtx,
        const Self = @This();

        const significant_ctx = switch (@typeInfo(util.ImplicitDeref(SubCtx))) {
            .Struct, .Union, .Enum, .Opaque => true,
            else => false,
        };
        const Ns = if (significant_ctx) util.ImplicitDeref(SubCtx) else struct {};

        pub const UnOp = enum {
            @"-",
        };
        pub const BinOp = enum {
            @"+",
            @"+|",
            @"+%",

            @"-",
            @"-|",
            @"-%",

            @"*",
            @"*|",
            @"*%",

            @"/",
            @"%",

            @"^",
            @"@",
        };
        pub const relations: eval.operator.RelationMap(BinOp) = .{
            .@"+" = .{ .prec = 1, .assoc = .left },
            .@"+|" = .{ .prec = 1, .assoc = .left },
            .@"+%" = .{ .prec = 1, .assoc = .left },

            .@"-" = .{ .prec = 1, .assoc = .left },
            .@"-|" = .{ .prec = 1, .assoc = .left },
            .@"-%" = .{ .prec = 1, .assoc = .left },

            .@"*" = .{ .prec = 2, .assoc = .left },
            .@"*|" = .{ .prec = 2, .assoc = .left },
            .@"*%" = .{ .prec = 2, .assoc = .left },

            .@"/" = .{ .prec = 2, .assoc = .left },
            .@"%" = .{ .prec = 2, .assoc = .left },

            .@"^" = .{ .prec = 3, .assoc = .right },
            .@"@" = .{ .prec = 0, .assoc = .left },
        };

        pub fn EvalProperty(comptime Lhs: type, comptime field: []const u8) type {
            if (@hasDecl(Ns, "EvalProperty")) {
                if (Ns.EvalProperty(Lhs, field) != noreturn) {
                    return Ns.EvalProperty(Lhs, field);
                }
            }
            return std.meta.FieldType(Lhs, field);
        }
        pub inline fn evalProperty(ctx: Self, lhs: anytype, comptime field: []const u8) EvalProperty(@TypeOf(lhs), field) {
            const Lhs = @TypeOf(lhs);
            if (@hasDecl(Ns, "EvalProperty")) {
                if (Ns.EvalProperty(Lhs, field) != noreturn) {
                    return ctx.sub_ctx.evalProperty(lhs, field);
                }
            }
            return @field(lhs, field);
        }

        pub fn EvalIndexAccess(comptime Lhs: type, comptime Rhs: type) type {
            if (@hasDecl(Ns, "EvalIndexAccess")) {
                if (Ns.EvalIndexAccess(Lhs, Rhs) != noreturn) {
                    return Ns.EvalIndexAccess(Lhs, Rhs);
                }
            }
            return std.meta.Elem(Lhs);
        }
        pub inline fn evalIndexAccess(ctx: Self, lhs: anytype, rhs: anytype) EvalIndexAccess(@TypeOf(lhs), @TypeOf(rhs)) {
            const Lhs = @TypeOf(lhs);
            const Rhs = @TypeOf(rhs);
            if (@hasDecl(Ns, "EvalIndexAccess")) {
                if (Ns.EvalIndexAccess(Lhs, Rhs) != noreturn) {
                    return ctx.sub_ctx.evalIndexAccess(lhs, rhs);
                }
            }
            return lhs[rhs];
        }

        pub fn EvalFuncCall(comptime Callee: type, comptime Args: type) type {
            if (@hasDecl(Ns, "EvalFuncCall")) {
                if (Ns.EvalFuncCall(Callee, Args) != noreturn) {
                    return Ns.EvalFuncCall(Callee, Args);
                }
            }
            return @typeInfo(util.ImplicitDeref(Callee)).Fn.return_type.?;
        }
        pub inline fn evalFuncCall(ctx: Self, callee: anytype, args: anytype) EvalFuncCall(@TypeOf(callee), @TypeOf(args)) {
            const Callee = @TypeOf(callee);
            const Args = @TypeOf(args);

            if (@hasDecl(Ns, "EvalFuncCall")) {
                if (Ns.EvalFuncCall(Callee, Args) != noreturn) {
                    return ctx.sub_ctx.evalFuncCall(callee, args);
                }
            }
        }

        pub fn EvalUnOp(comptime op: UnOp, comptime T: type) type {
            if (@hasDecl(Ns, "EvalUnOp")) {
                if (Ns.EvalUnOp(op, T) != noreturn) {
                    return Ns.EvalUnOp(op, T);
                }
            }
            return switch (op) {
                .@"-" => T,
            };
        }
        pub inline fn evalUnOp(ctx: Self, comptime op: UnOp, val: anytype) EvalUnOp(op, @TypeOf(val)) {
            if (@hasDecl(Ns, "EvalUnOp")) {
                if (Ns.EvalUnOp(op, @TypeOf(val)) != noreturn) {
                    return ctx.sub_ctx.evalUnOp(op, val);
                }
            }
            return switch (op) {
                .@"-" => -val,
            };
        }

        pub fn EvalBinOp(comptime Lhs: type, comptime op: BinOp, comptime Rhs: type) type {
            if (@hasDecl(Ns, "EvalBinOp")) {
                if (Ns.EvalBinOp(Lhs, op, Rhs) != noreturn) {
                    return Ns.EvalBinOp(Lhs, op, Rhs);
                }
            }

            const lhs: Lhs = std.mem.zeroes(Lhs);
            const rhs: Rhs = std.mem.zeroes(Rhs);
            return switch (op) {
                .@"+" => @TypeOf(lhs + rhs),
                .@"+%" => @TypeOf(lhs +% rhs),
                .@"+|" => @TypeOf(lhs +| rhs),

                .@"-" => @TypeOf(lhs - rhs),
                .@"-%" => @TypeOf(lhs -% rhs),
                .@"-|" => @TypeOf(lhs -| rhs),

                .@"*" => @TypeOf(lhs * rhs),
                .@"*%" => @TypeOf(lhs *% rhs),
                .@"*|" => @TypeOf(lhs *| rhs),

                .@"/" => @TypeOf(lhs / rhs),
                .@"%" => @TypeOf(lhs % rhs),

                .@"^" => @TypeOf(lhs ^ rhs),
                .@"@" => [rhs.len][lhs[0].len]@TypeOf(lhs[0][0]),
            };
        }
        pub inline fn evalBinOp(ctx: Self, lhs: anytype, comptime op: BinOp, rhs: anytype) EvalBinOp(@TypeOf(lhs), op, @TypeOf(rhs)) {
            const Lhs = @TypeOf(lhs);
            const Rhs = @TypeOf(rhs);
            if (@hasDecl(Ns, "EvalBinOp")) {
                if (Ns.EvalBinOp(Lhs, op, Rhs) != noreturn) {
                    return ctx.sub_ctx.evalBinOp(lhs, op, rhs);
                }
            }
            return switch (op) {
                .@"+" => lhs + rhs,
                .@"+%" => lhs +% rhs,
                .@"+|" => lhs +% rhs,

                .@"-" => lhs - rhs,
                .@"-%" => lhs -% rhs,
                .@"-|" => lhs -% rhs,

                .@"*" => lhs * rhs,
                .@"*%" => lhs *% rhs,
                .@"*|" => lhs *% rhs,

                .@"/" => lhs / rhs,
                .@"%" => lhs % rhs,

                .@"^" => blk: {
                    const T = @TypeOf(lhs, rhs);
                    comptime if (T == comptime_int or
                        T == comptime_float)
                    {
                        @setEvalBranchQuota(@min(std.math.maxInt(u32), rhs * 10));
                        var x: T = 1;
                        for (0..rhs) |_| x *= lhs;
                        break :blk x;
                    };

                    break :blk std.math.pow(T, lhs, rhs);
                },
                .@"@" => blk: {
                    const columns_num = lhs[0].len;
                    const rows_num = rhs.len;
                    const T = @TypeOf(lhs[0][0]);

                    @setEvalBranchQuota(1000 + rhs.len * 10);
                    var res: [columns_num][rows_num]T = undefined;
                    inline for (rhs, 0..) |prev_column, i| {
                        var column: @Vector(columns_num, T) = .{0} ** columns_num;

                        inline for (0..lhs.len) |j| {
                            const mask = ([1]i32{@intCast(j)}) ** columns_num;
                            var vi = @shuffle(T, prev_column, undefined, mask);

                            vi = vi * lhs[j];
                            column += vi;
                        }

                        res[i] = column;
                    }
                    break :blk res;
                },
            };
        }
    };
}

test simpleCtx {
    try util.testing.expectEqual(5, eval.eval("a + b", simpleCtx({}), .{ .a = 2, .b = 3 }));
    try util.testing.expectEqual(1, eval.eval("a +% b", simpleCtx({}), .{ .a = @as(u8, std.math.maxInt(u8)), .b = 2 }));
    try util.testing.expectEqual(59049, eval.eval("3^(2 * a + -b)", simpleCtx({}), .{ .a = 7, .b = 4 }));

    try util.testing.expectEqual([2][2]u16{ .{ 140, 320 }, .{ 146, 335 } }, eval.eval("a @ b", simpleCtx({}), .{
        .a = [3][2]u16{ .{ 1, 4 }, .{ 2, 5 }, .{ 3, 6 } },
        .b = [2][3]u16{ .{ 10, 20, 30 }, .{ 11, 21, 31 } },
    }));
    try util.testing.expectEqual([2][2]u16{ .{ 188, 422 }, .{ 207, 468 } }, eval.eval("a @ b @ c", simpleCtx({}), .{
        .a = [3][2]u16{ .{ 1, 4 }, .{ 2, 5 }, .{ 3, 6 } },
        .b = [2][3]u16{ .{ 1, 2, 4 }, .{ 2, 3, 6 } },
        .c = [2][2]u16{ .{ 8, 2 }, .{ 3, 6 } },
    }));
}

pub inline fn fnMethodCtx(
    sub_ctx: anytype,
    /// must be a struct literal wherein each field name is an operator,
    /// with a string literal value corresponding to the method name, or a list of possible method names.
    /// ie `.{ .@"+" = "add", .@"-" = &.{ "sub", "neg" } }`
    comptime method_names: anytype,
) FnMethodCtx(@TypeOf(sub_ctx), method_names) {
    return .{ .sub_ctx = sub_ctx };
}
pub fn FnMethodCtx(
    comptime SubCtx: type,
    comptime method_names: anytype,
) type {
    {
        const Deduped = DedupedMethodNames(method_names);
        if (@TypeOf(method_names) != Deduped) {
            return FnMethodCtx(SubCtx, Deduped{});
        }
    }
    return struct {
        sub_ctx: SubCtx,
        const Self = @This();

        pub const UnOp = SubCtx.UnOp;
        pub const BinOp = SubCtx.BinOp;
        pub const relations = SubCtx.relations;

        pub fn EvalProperty(comptime Lhs: type, comptime field: []const u8) type {
            return SubCtx.EvalProperty(Lhs, field);
        }
        pub inline fn evalProperty(ctx: Self, lhs: anytype, comptime field: []const u8) !EvalProperty(@TypeOf(lhs), field) {
            return ctx.sub_ctx.evalProperty(lhs, field);
        }

        pub fn EvalIndexAccess(comptime Lhs: type, comptime Rhs: type) type {
            return SubCtx.EvalIndexAccess(Lhs, Rhs);
        }
        pub inline fn evalIndexAccess(ctx: Self, lhs: anytype, rhs: anytype) !EvalIndexAccess(@TypeOf(lhs), @TypeOf(rhs)) {
            return ctx.sub_ctx.evalIndexAccess(lhs, rhs);
        }

        pub fn EvalFuncCall(comptime Callee: type, comptime Args: type) type {
            return SubCtx.EvalFuncCall(Callee, Args);
        }
        pub inline fn evalFuncCall(ctx: Self, callee: anytype, args: anytype) !EvalFuncCall(@TypeOf(callee), @TypeOf(args)) {
            return ctx.sub_ctx.evalFuncCall(callee, args);
        }

        pub fn EvalUnOp(comptime op: UnOp, comptime T: type) type {
            if (getOpMapping(T, @tagName(op), method_names, 1)) |name| {
                const Method = util.ImplicitDeref(@TypeOf(@field(T, name)));
                const method_info = @typeInfo(Method).Fn;
                if (method_info.return_type) |Ret| return Ret;

                const val: (method_info.params[0].type orelse *const T) = undefined;
                return @TypeOf(@field(T, name)(val));
            }
            return SubCtx.EvalUnOp(op, T);
        }
        pub inline fn evalUnOp(ctx: Self, comptime op: UnOp, val: anytype) !EvalUnOp(op, @TypeOf(val)) {
            const Val = @TypeOf(val);
            if (comptime getOpMapping(Val, @tagName(op), method_names, 1)) |name| {
                return @field(Val, name)(val);
            }
            return ctx.sub_ctx.evalUnOp(op, val);
        }

        pub fn EvalBinOp(comptime Lhs: type, comptime op: BinOp, comptime Rhs: type) type {
            if (comptime getOpMapping(Lhs, @tagName(op), method_names, 2)) |name| {
                const Method = util.ImplicitDeref(@TypeOf(@field(Lhs, name)));
                const method_info = @typeInfo(Method).Fn;
                if (method_info.return_type) |Ret| return Ret;

                const lhs: (method_info.params[0].type orelse *const Lhs) = undefined;
                const rhs: (method_info.params[1].type orelse *const Rhs) = undefined;
                return @TypeOf(@field(Lhs, name)(lhs, rhs));
            }
            return SubCtx.EvalBinOp(Lhs, op, Rhs);
        }
        pub inline fn evalBinOp(ctx: Self, lhs: anytype, comptime op: BinOp, rhs: anytype) !EvalBinOp(@TypeOf(lhs), op, @TypeOf(rhs)) {
            const Lhs = @TypeOf(lhs);
            if (comptime getOpMapping(Lhs, @tagName(op), method_names, 2)) |name| {
                return @field(Lhs, name)(lhs, rhs);
            }
            return ctx.sub_ctx.evalBinOp(lhs, op, rhs);
        }
    };
}

inline fn getOpMapping(
    comptime Operand: type,
    comptime op: []const u8,
    comptime mapping: anytype,
    comptime arity: comptime_int,
) ?[]const u8 {
    comptime {
        if (!@hasField(@TypeOf(mapping), op)) return null;
        const entry = @field(mapping, op);

        const T = util.ImplicitDeref(Operand);
        switch (@typeInfo(T)) {
            .Struct, .Union, .Enum, .Opaque => {},
            else => return null,
        }

        const is_single = @TypeOf(entry) == []const u8;
        const entry_list: []const []const u8 = if (is_single) &.{entry} else entry;

        var idx: comptime_int = entry_list.len;

        const result = for (entry_list, 0..) |name, i| {
            if (!@hasDecl(T, name)) continue;
            const Fn = util.ImplicitDeref(@TypeOf(@field(T, name)));
            if (@typeInfo(Fn).Fn.params.len != arity) continue;
            idx = i + 1;
            break name;
        } else null;

        for (entry_list[idx..]) |next_name| {
            if (!@hasDecl(T, next_name)) continue;
            const NextFn = util.ImplicitDeref(@TypeOf(@field(T, next_name)));
            if (@typeInfo(NextFn).Fn.params.len != arity) continue;
            @compileError("Ambiguous resolution between method '" ++ result.? ++ "' and '" ++ next_name ++ "'");
        }

        return result;
    }
}

fn DedupedMethodNames(comptime method_names: anytype) type {
    const info = @typeInfo(@TypeOf(method_names)).Struct;

    @setEvalBranchQuota(1000 + info.fields.len * 10);
    var fields: [info.fields.len]std.builtin.Type.StructField = undefined;
    for (&fields, info.fields) |*new, old| {
        const T = switch (@typeInfo(old.type)) {
            .Pointer => |pointer| switch (@typeInfo(pointer.child)) {
                .Int, .ComptimeInt => []const u8,
                .Array => |array| switch (@typeInfo(array.child)) {
                    .Int, .ComptimeInt => []const u8,
                    else => []const []const u8,
                },
                else => []const []const u8,
            },
            else => @compileError("Unexpected type " ++ @typeName(old.type)),
        };
        const old_value: T = @as(*align(1) const old.type, @ptrCast(old.default_value)).*;
        new.* = .{
            .name = util.dedupeSlice(u8, old.name),
            .type = T,
            .is_comptime = true,
            .default_value = @ptrCast(util.dedupeValue(old_value)),
            .alignment = 0,
        };
    }

    const deduped_fields = util.dedupeSlice(std.builtin.Type.StructField, &fields);
    return DedupedMethodNamesImpl(deduped_fields);
}
fn DedupedMethodNamesImpl(comptime fields: []const std.builtin.Type.StructField) type {
    return @Type(.{ .Struct = .{
        .layout = .Auto,
        .backing_integer = null,
        .is_tuple = false,
        .decls = &.{},
        .fields = fields,
    } });
}

test fnMethodCtx {
    const CustomNum = enum(i32) {
        _,

        pub inline fn add(self: @This(), other: @This()) @This() {
            return @enumFromInt(@intFromEnum(self) + @intFromEnum(other));
        }
        pub inline fn sub(self: @This(), other: @This()) @This() {
            return @enumFromInt(@intFromEnum(self) - @intFromEnum(other));
        }
        pub inline fn neg(self: @This()) @This() {
            return @enumFromInt(-@intFromEnum(self));
        }
    };

    const fm_ctx = fnMethodCtx(simpleCtx({}), .{
        .@"+" = "add",
        .@"-" = &.{ "sub", "neg" },
    });
    try util.testing.expectEqual(@as(CustomNum, @enumFromInt(2)), eval.eval("a + -b - c", fm_ctx, .{
        .a = @as(CustomNum, @enumFromInt(22)),
        .b = @as(CustomNum, @enumFromInt(9)),
        .c = @as(CustomNum, @enumFromInt(11)),
    }));
}
