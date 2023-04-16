// ASSIGNMENT

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
const a: i32 = undefined;
var b: u32 = undefined;

// ARRAYS

// [N]T
// `N` is the number of elements and `T` is the type of those elemements.
// `N` may b replaced with `_` to infer the array's size for array literals.
const c = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
const d = [_]u8{ 'w', 'o', 'r', 'l', 'd' };
// The get the array's size, lens the `len` field.
const array = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
const length = array.len; // 5

// IF

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

// WHILE

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

// FOR

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
