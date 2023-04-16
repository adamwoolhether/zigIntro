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

// FUNCTIONS

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

// DEFER

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

// ERRORS

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
