// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ASSIGNMENT
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// (const|var) identifier[: type] = value
// We can omit the `:`, the type annotation for `indentifier`, if the `value` can be inferred.
const constant: i32 = 5; // signed 32-bit constant
var variable: u32 = 5000; // unsigned 32-bit variable

// @as to perform an explicit type coercion.
const inferred_constant = @as(i32, 5);
var inferred_variable = @as(u32, 5000);

// consts and vars must have a value. Otherwise, the `undefined` value, which coeres to any type
// may be used as long as a type annotation is provided.
// const values are preferred over var values.
const aa: i32 = undefined;
var bb: u32 = undefined;

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ARRAYS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// [N]T
// `N` is the number of elements and `T` is the type of those elemements.
// `N` may b replaced with `_` to infer the array's size for array literals.
const cc = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
const d = [_]u8{ 'w', 'o', 'r', 'l', 'd' };
// The get the array's size, lens the `len` field.
const array = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
const length = array.len; // 5

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IF
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Only accepts a bool of `true`/`false`. No truthy/falsy values.
// zig test 01-basics.zig
const expect = @import("std").testing.expect;
test "if statement" {
    const boolean = true;
    var x: u16 = 0;
    if (boolean) {
        x += 1;
    } else {
        x += 2;
    }

    try expect(x == 1);
}

test "if statement expression" {
    const boolean = true;
    var x: u16 = 0;
    x += if (boolean) 1 else 2;

    try expect(x == 1);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// WHILE
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Zig while loops have three parts: condition, block, and continue expression.
// zig test 01-basics.zig
test "while" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }

    try expect(i == 128);
}

test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }

    try expect(sum == 55);
}

test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) continue;
        sum += i;
    }
    try expect(sum == 4);
}

test "while with a break" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) break;
        sum += i;
    }

    try expect(sum == 1);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FOR
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// To iterate over arrays(and other types). For loops can also use `break` and `continue`.
// In the example below, we use `_`, as Zig doesn't allow unused values.
test "for" {
    const string = [_]u8{ 'a', 'b', 'c' };

    for (string) |character, index| {
        _ = character;
        _ = index;
    }

    for (string) |character| {
        _ = character;
    }

    for (string) |_, index| {
        _ = index;
    }

    for (string) |_| {}
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// All functions are immutable. If a copy is desired, you must explicitly make one.
// camelCase is usedd for functions. (vars are snake_case)
fn addFive(x: u32) u32 {
    return x + 5;
}

test "function" {
    const y = addFive(0);
    try expect(@TypeOf(y) == u32);
    try expect(y == 5);
}

// Recursion example: Not that with recursion, the compiler is no longer able to work out
// the maximum stack size, leading to potentially unsafe behavior. We'll caover how to do
// this safely later.
// We can ignore values with `_` in place of the var/const declaration. This only works within
// function scopes and blocks, not globally.
fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "fucntion recursion" {
    const x = fibonacci(10);
    try expect(x == 55);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DEFER
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}
// multiple defers in a single block will be executed in reverse order.
test "multi defet" {
    var x: f32 = 5;
    {
        defer x += 2; // exec'd second
        defer x /= 2; // exec's first
    }

    try expect(x == 4.5);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ERRORS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Erros set's are similar to an enum, where each error in the set is a value.
// No exceptions in Zig: errors are values.
const FileOpenError = error{ // create an error set
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};
// Erorr sets coerce to their supersets.
const AllocationError = error{OutOfMemory};

test "coerce error from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}

// Error set types and normal types can be combined with the `!` operator for form an error union type.
// Values of these types may be an error value, or value of the normal type.
// We'll use `catch` to create a value of an error union type. `catch` is followed by an expression
// which is evaluated when the value before it is an error, it's used to provide a fallback value.
// We could alternatively use a `noreturn` - the type of `return`, `while (true)` and others.
test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}

// Functions often return error unions. Heres one that uses a catch, with `|err|` syntax
// that receives the value of the error. This is called "payload capturing", and used in
// many places. (This is not used for lambdas, as is with some langs).
fn failingFunction() error{Oops}!void {
    return error.Oops;
}

test "returning an error" {
    failingFunction() catch |err| {
        try expect(err == error.Oops);
        return;
    };
}

// `try x` is shortcut for `x catch |err| return err`. It's common where handling an error
// isn't appropriate. Zig's `try` and `catch` are unrelated to other langs' try-catch.
fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12); // is never reached
}

// `errdefer` works like `defer`, but only executes when a function is returned from
// with an error inside of the `errdefer`'s block.'
var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}

// Error unions returned from a func can have their error sets inferred by not having
// an explicit error set. The inferred error set contains all possible errors which
// the function may return.
fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    // type coercion successfully takes place
    const x: error{AccessDenied}!void = createFile();

    // Zig doesn't let us ignore error unions via `_ = x;`,
    // we must unwrap it with `try`, `catch`, or `if` by any means.
    _ = x catch {};
}

// Error sets can also be merged.
const A = error{ NotDir, PathNotFound };
const B = error{ OutOfMemory, PathNotFound };
const C = A || B;

// We should generally avoid `anyerror`. It's the global error set, superset of all error sets,
// and can have an error from any set coerce to a value of it.

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SWITCH
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Works as both a statement and an expression. All possible values must have an associated branch - values
// can't be left out. Cases can't fall through to other branches.
test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            // Special handling needed for dividing signed ints.
            x = @divExact(x, 10);
        },
        else => {},
    }

    try expect(x == 1);
}

test "swith expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };

    try expect(x == 1);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// RUNTIME SAFETY
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Zig safety allows problems to be found during execution.
// Safety can be left on or turned off. detectable illegal behavior will result in
// a panic with safety turned on, or undefined behavior if turned off.
// Safety is off for some build modes.

// Demo runtime safety from out of bounds slice:
// test "out of bounds" {
//     const j = [3]u8{ 1, 2, 3 };
//     var index: u8 = 5;

//     const k = j[index];
//     _ = k;
// }

// We can disable runtime safety for the current block with the built-in `@setRuntimeSafety`
test "out of bounds no safety" {
    @setRuntimeSafety(false);
    const j = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;

    const k = j[index];
    _ = k;
}

// UNREACHABLE

//  `unreachable` asserts to the compiler that a statement will not be reached. It's used
// to inform compiler that a branch is impossible, allowing the optimiser to take advantage.
// Reaching `unreachable` is detectable illegal behavior.
// test "unreachable" {
//     const x: i32 = 1;
//     const y: u32 = if (x == 2) 5 else unreachable;
//     _ = y;
// }

// Demonstrating an unreachable switch.
fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "unreachable switch" {
    try expect(asciiToUpper('a') == 'A');
    try expect(asciiToUpper('A') == 'A');
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// POINTERS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Normal pointers in Zig can't have 0 or null as a value.
// Syntax: `*T`
// Referencing is done with `&variable` and dereferencing with `variable.*`
fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);

    try expect(x == 2);
}

// Setting a *T to 0 value is detectable illegal behavior.
// test "naughty pointer" {
//     var x: u16 = 0;
//     var y: *u8 = @intToPtr(*u8, x);
//     _ = y;
// }

// const pointers cannot be used to modify the referenced data. Referencind a const variable yields a const pointer.
// test "const pointers" {
//     const x: u8 = 1;
//     var y = &x;
//     y.* += 1;
// }

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// POINTER SIZED INTEGERS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// `usize` and `isize` are given as unsigned and signted integers with the same size as pointers.
test "useize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MANY-ITEM POINTERS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// `[*]T` is used when we have a pointer to an unknown amount of elements.
// It works like `*T` but supports indexing syntax, pointer arithmetic and slicing.
// It can't point to a type which doesn't have a known size, unlike `*T`.
// `*T` coerces to `[*]T`.
// Many pointers can point to any amount of elements, including 0 & 1.

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SLICES
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Slices are a pair of `[*]T`, pointing to the data, and a `usize`, the element count.
// `[]T` is the syntax. Slices have the same attributes as pointers: there are also const slices.
// For loops are used to iterate.
// String literals coerce to `[]const u8`.
// `x[n..m]` is the syntax to create a slice from an array, aka "slicing",
// creating a slice of elements starting at `x[]n` and ending at `x[m-1]`.

// Below example uses a const slice as the values which the slice points to don't need to be modified.
fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;

    return sum;
}
test "slices" {
    const arrayConst = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = arrayConst[0..3];

    try expect(total(slice) == 6);
}

// if the `n` and `m` values are known at compile time, slicing will produce a pointer to an array.
// This is ok because a pointer to an array `*[N]T` will coerce to `[]T`.
test "slices 2" {
    const arrayConst = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = arrayConst[0..3];

    try expect(@TypeOf(slice) == *const [3]u8);
}

// `x[n..]` is used to slice all the way to the end.
test "slice 3" {
    var arrayTest = [_]u8{ 1, 2, 3, 4, 5 };
    var slice = arrayTest[0..];
    _ = slice;
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ENUMS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Enums allow defining types which have a restricted set of named values.

const Direction = enum { noth, south, east, west };

// Enumbs may have specified (integer) tag types.
const Value = enum(u2) { zero, one, two };

// Ordinal values start at 0. Acess is done with the built-in `@enumToIn`.
test "enum ordinal value" {
    try expect(@enumToInt(Value.zero) == 0);
    try expect(@enumToInt(Value.one) == 1);
    try expect(@enumToInt(Value.two) == 2);
}

// Values can be overridden, with the next values continuing from there.
const Value2 = enum(u32) {
    hundred = 100,
    thousand = 1000,
    million = 1000000,
    next,
};

test "set num ordinal value" {
    try expect(@enumToInt(Value2.hundred) == 100);
    try expect(@enumToInt(Value2.thousand) == 1000);
    try expect(@enumToInt(Value2.million) == 1000000);
    try expect(@enumToInt(Value2.next) == 1000001);
}

// Methods can be assigned to enums.
// They will act as namespaced functions and can be called via dot syntax.
const Suit = enum {
    clubs,
    spades,
    diamonds,
    hearts,
    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};

test "enum method" {
    try expect(Suit.spades.isClubs() == Suit.isClubs(.spades));
}

// Enums can also be assigned to var and const declarations, acting as namespaced
// globals. Thei values are unrelated and unattached to instances of the enum type.
const Mode = enum {
    var count: u32 = 0;
    on,
    off,
};

test "hmm" {
    Mode.count += 1;
    try expect(Mode.count == 1);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// STRUCTS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// The most common kind of composit data type in Zig, allow defining types that can store
// a fixed set of named fields. There is no guarantee about the in-memory order of struct-
// fields or its size.
// Syntax: T{}

// Declaring and filling a struct:
const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

test "struct usage" {
    const my_vector = Vec3{
        .x = 0,
        .y = 100,
        .z = 50,
    };
    _ = my_vector;
}

// All fields must be given a value. This test will fail.
// test "missing struct field" {
//     const my_vector = Vec3{
//         .x = 0,
//         .z = 50,
//     };
//     _ = my_vector;
// }

// Fields can be given defaults
const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32 = 0,
    w: f32 = undefined,
};

test "struct defaults" {
    const my_vector = Vec4{
        .x = 25,
        .y = -50,
    };
    _ = my_vector;
}

// Struct can contain func declarations.
// When given a pointer to a struct, one level of dereferencing is done automatically
// when accessing the fields. Notice in this example: `self.x` and `self.y` are accessed
// in the swap function without needing to derefernce the self pointer.
const Stuff = struct {
    x: i32,
    y: i32,
    fn swap(self: *Stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "automatic dereference" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// UNIONS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Unions allow defining types that store one value of many possible typed
// fields; only one field may be active at a time.

// Bare unions don't have a guaranteed memory layout. As such, bare unions can be
// used to reinterpret memory. Accessing a field in a union that isn't active is
// detectable illegal behavior.
const Result = union {
    int: i64,
    float: f64,
    bool: bool,
};
// This test will fail
// test "simple union" {
//     var result = Result{ .int = 1234 };
//     result.float = 12.35;
// }

// Tagged unions use enums to detect which field is active. In this example, we use payload capturing
// to detect which field is active.
// Here, a `pointer capture` is used; captured values are immutable, but with the `|*value|` syntax we
// can captures a pointer to the values themselves. This allows dereferencing to mutate the original value.
const Tag = enum { a, b, c };

const Tagged = union(Tag) { a: u8, b: f32, c: bool };

test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    try expect(value.b == 3);
}

// The type of a tagged union can also be inferred. This is the same as the Tagged type above.
const Tagged2 = union(enum) { a: u8, b: f32, c: bool };
// `void` member types have their types ommitted from the syntax. Here, `none` is type `void`.
const Tagged3 = union(enum) { a: u8, b: f32, c: bool, none };

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// INTEGER RULES
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Zig supports hex, octal, and binary integer literals.
const decimal_int: i32 = 98222;
const hex_int: u8 = 0xff;
const another_hex_int: u8 = 0xFF;
const octal_int: u16 = 0o755;
const binary_int: u8 = 0b11110000;

// Underscores can also be used between digits for readability.
const one_billion: u64 = 1_000_000_000;
const binary_mask: u64 = 0b1_1111_1111;
const permissions: u64 = 0o7_5_5;
const big_address: u64 = 0xFF80_0000_0000_0000;

// "Integer Widening" means integeres of a type can coerce to an integer of another type, provided that the
// new type can fit all of the values that the old type can.
test "integer widening" {
    const a: u8 = 250;
    const b: u16 = a;
    const c: u32 = b;
    try expect(c == a);
}
// If a value can't coerce to the desired type, `@intCast` can explicitly convert from on type to another.
// If the value is out of the destination type's range, this is detectable illegal behavior.
test "@intCat" {
    const x: u64 = 200;
    const y = @intCast(u8, x);
    try expect(@TypeOf(y) == u8);
}

// Integers are by default not allowed to overflow, which is detectable illegal behavior. If an
// overflow is desired, Zig provides overflow operators.
// Normal Operator | Wrapping Operator
// +               |    +%
// -               |    -%
// *               |    *%
// +=              |    +%=
// -=              |    -%=
// *=              |    *%=
test "well defined overflow" {
    var a: u8 = 255;
    a +%= 1;
    try expect(a == 0);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FLOATS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Floats are IEEE compliant unless the `@setFloatMode(.Optimized)` is used, the equivalent to GCC's `-ffast-math`.
// Floats coerce to larger float types.
test "float widening" {
    const a: f16 = 0;
    const b: f16 = a;
    const c: f16 = b;
    try expect(c == @as(f128, a));
}

// Floats support multiple kinds of literal。
const floating_point: f64 = 123.0E+77;
const another_float: f64 = 123.0;
const yet_another: f64 = 123.0e+77;

const hex_floating_point: f64 = 0x103.70p-5;
const another_hex_float: f64 = 0x103.70;
const yet_another_hex_float: f64 = 0x103.70P-5;

// Underscores can be used for readability:
const lightspeed: f64 = 299_792_458.000_000;
const nanosecond: f64 = 0.000_000_001;
const more_hex: f64 = 0x1234_5678.9ABC_CDEFp-10;

// Integers and floats can be converted with built-ins `@intToFloat` and `@floatToInt`.
// `@intToFloat` is always safe, but `@floatToInt` is DEB if the float value can't fit in the integer dest type.
test "int-float conversion" {
    const a: i32 = 0;
    const b = @intToFloat(f32, a);
    const c = @floatToInt(i32, b);
    try expect(c == a);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LABELLED LOOPS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Loops can also be given labels, allowing us to `break` or `continue` to outer loops.
test "nested continue" {
    var count: usize = 0;
    outer: for ([_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }) |_| {
        for ([_]i32{ 1, 2, 3, 4, 5 }) |_| {
            count += 1;
            continue :outer;
        }
    }
    try expect(count == 8);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LOOPS AS EXPRESSIONS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// we can use `break` to return a value, just like `return`.

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "while loop expression" {
    try expect(rangeHasNumber(0, 10, 3));
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// OPTIONALS
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Syntax: `?T`, optionals are used to store the data `null` or a value of type `T`.
// ************************************************************** BROKEN
// test "optional" {
//     var found_index: ?usize = null;
//     const data = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 12 };
//     for (data, 0..) |v, i| {
//         if (v == 10) found_index = i;
//     }
//     try expect(found_index == null);
// }

// optionals support "orelse" expression, which acts when the optional is `null`, unwrapping
// the optional to its child type.
test "orelse" {
    var a: ?f32 = null;
    var b = a orelse 0;
    try expect(b == 0);
    try expect(@TypeOf(b) == f32);
}

// `.?` is shorthand for `orelse unreachable`. This is used when it's impossible for an
// optional value to be null, and using it to unwrap a `null` value is detectable illegal behavior.
test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?;
    try expect(b == c);
    try expect(@TypeOf(c) == f32);
}

// Payload capturing works in many places for optionals,
// meaning that if it's non-null we can "capture" its non-null value.
// This example will uses an 'if' optional payload capture. `a` and `b` are equivalent.
// `if (b) |value|` captures the value of `b` if it's non-null, making its value available as `value`.
// The captured value is immutable.
test "if optional payload capture" {
    const a: ?i32 = 5;
    if (a != null) {
     const value = a.?;
     _ = value;
    }

    var b: ?i32 = 5;
    if (b) |*value| {
        value.* += 1;
    }
    try expect(b.? == 6);
}

// using while
var numbers_left: u32 = 4;
fn eventuallyNullSequence() ?u32 {
    if (numbers_left == 0) return null;
    numbers_left -= 1;
    return numbers_left;
}

test "while null capture" {
    var sum: u32 = 0;
    while (eventuallyNullSequence()) |value| {
        sum += value;
    }
    try expect(sum == 6); // 3 + 2 + 1
}
// Optional pointer/slice types don't take up extra memory, compared to non-nil ones becasuse
// they use the 0 value of the pointer for null.
// Null pointers in Zig must be unwrapped to a non-optional before dereferencing.
// This stops null pointer dereferences from happening accidentally.

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// COMPTIME
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Blocks of code can be forcibly executed at compile time with `comptime`.
// `x` and `y` are equivalent in this example.

test "comptime blocks" {
    var x = comptime fibonacci(10);
    _ = x;

    var y = comptime blk: {
        break :blk fibonacci(10);
    };

    _ = y;
}

// Integer literals are of `comptime_int` type. They're special in that they have no size(can't be used at runtime)
// and have arbitrary precision. `comptime_int` values coerce to any integer type that can hold them.
// They also coerce to floats. Character literals are also of this type.
test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    _ = c;
    const u: f32 = b;
    _ = u;
}

// `comptime_float`, internally an f123, is also available.
// They can't be coerced to integers, even if they hold a value.
// Type in Zig are values of the type `type`. They're available at compiule time.
test "branching on types" {
    const a = 5;
    const b: if (a < 10) f32 else i32 = 5;
    _ = b;
}

// Func parameters in Zig can be tagged as a `comptime`. The value passed to that function parameter must be known
// at compile time.
// Here we make a function that returns a type. Notice the func is PascalCase, as it returns a type.
fn Matrix(
    comptime T: type,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    return [height][width]T;
}

test "returning a type" {
    try expect(Matrix(f32, 4, 4) == [4][4]f32);
}

// We can reflect upon types with builtin `@typeInfo`, which returns a type and returns a tagged
// union. The tagged union can be found in `std.builtin.TypeInfo`.
// ************************************************************** BROKEN
// fn addSmallInts(comptime T: type, a: T, b: T) T {
//     return switch (@typeInfo(T)) {
//         .ComptimeInt => a + b,
//         .Int => |info| if (info.bits <= 16)
//             a + b
//         else
//             @compileError("ints too large"),
//         else => @compileError("only ints accepted"),
//     };
// }
//
// test "typeinfo switch" {
//     const x = addSmallInts(u16, 20, 30);
//     try expect(@TypeOf(x) == 16);
//     try expect(x == 50);
// }

// a `@Type` func can create a type from `@typeInfo`. `@Type` is implemented for most types,
// but notably unimplemented for enums, unions, functions, and structs.
// This example uses an anonymous struct syntax with `.{}`, because `T` in `T{}` can be inferred.
// This example will give us a compile error if the `Int` tag isn't set.
fn GetBiggerInt(comptime T: type) type {
    return @Type(.{
        .Int = .{
            .bits = @typeInfo(T).Int.bits + 1,
            .signedness = @typeInfo(T).Int.signedness,
        },
    });
}

test "@Type" {
    try expect(GetBiggerInt(u8) == u9);
    try expect(GetBiggerInt(i31) == i32);
}

// Returning a struct type is how to make generic data structs in Zig.
// `@This` is required here, which gets the type of the inntermost struct,
// union, or enum. `std.mem.eql` is used here to compare two slices.
// ************************************************************** BROKEN
// fn Vec(
//     comptime count: comptime_int,
//     comptime T: type,
// ) type {
//     return struct {
//         data: [count]T,
//         const Self = @This();
//
//         fn abs(self: Self) Self {
//             var tmp = Self{ .data = undefined };
//             for (self.data, 0..) |elem, i| {
//                 tmp.data[i] = if (elem < 0)
//                     -elem
//                 else
//                     elem;
//             }
//             return tmp;
//         }
//
//         fn init(data: [count]T) Self {
//             return Self{ .data = data };
//         }
//     };
// }
//
//
const eql = @import("std").mem.eql;
//
// test "generic vector" {
//     const x = Vec(3, f32).init([_]f32{ 10, -10, 5});
//     const y = x.abs();
//     try expect(eql(f32, &y.data, &[_]f32{ 10, 10, 5 }));
// }

// Function parameter types can also be inferred by using `anytime` in place of `type`. `@TypeOf` can then be used.
fn plusOne(x: anytype) @TypeOf(x) {
    return x + 1;
}

test "inferred function parameter" {
    try expect(plusOne(@as(u32, 1)) == 2);
}

// Comptime also introduces the `++` and `**` operators for concatenation and repeating arrays/slices.
// These operators don't work at runtime.
test "++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    const new = y ++ b;
    try expect(new.len == 10);
}

test "**" {
    const pattern = [_]u8{ 0xCC, 0xAA };
    const memory = pattern ** 3;
    try expect(eql(u8, &memory, &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }));
}