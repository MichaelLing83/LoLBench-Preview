> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

---

# PEP 593: Flexible function and variable annotations

## Abstract
This PEP introduces a mechanism to extend the type annotations from PEP
484 with arbitrary metadata.

## Motivation
PEP 484 provides a standard semantic for the annotations introduced in
PEP 3107. PEP 484 is prescriptive but it is the de facto standard
for most of the consumers of annotations; in many statically checked
code bases, where type annotations are widely used, they have
effectively crowded out any other form of annotation. Some of the use
cases for annotations described in PEP 3107 (database mapping,
foreign languages bridge) are not currently realistic given the
prevalence of type annotations. Furthermore, the standardisation of type
annotations rules out advanced features only supported by specific type
checkers.

## Rationale
This PEP adds an `Annotated` type to the typing module to decorate
existing types with context-specific metadata. Specifically, a type
`T` can be annotated with metadata `x` via the typehint
`Annotated[T, x]`. This metadata can be used for either static
analysis or at runtime. If a library (or tool) encounters a typehint
`Annotated[T, x]` and has no special logic for metadata `x`, it
should ignore it and simply treat the type as `T`. Unlike the
`no_type_check` functionality that currently exists in the `typing`
module which completely disables typechecking annotations on a function
or a class, the `Annotated` type allows for both static typechecking
of `T` (e.g., via mypy or Pyre,
which can safely ignore `x`)
together with runtime access to `x` within a specific application. The
introduction of this type would address a diverse set of use cases of interest
to the broader Python community.

This was originally brought up as issue 600 in the typing github
and then discussed in Python ideas.

## Motivating examples
### Combining runtime and static uses of annotations
There's an emerging trend of libraries leveraging the typing annotations at
runtime (e.g.: dataclasses); having the ability to extend the typing annotations
with external data would be a great boon for those libraries.

Here's an example of how a hypothetical module could leverage annotations to
read c structs:

```
UnsignedShort = Annotated[int, struct2.ctype('H')]
SignedChar = Annotated[int, struct2.ctype('b')]

class Student(struct2.Packed):
    # mypy typechecks 'name' field as 'str'
    name: Annotated[str, struct2.ctype("<10s")]
    serialnum: UnsignedShort
    school: SignedChar

## 'unpack' only uses the metadata within the type annotations
Student.unpack(record)
## Student(name=b'raymond   ', serialnum=4658, school=264)
```
### Lowering barriers to developing new typing constructs
Typically when adding a new type, a developer need to upstream that type to the
typing module and change mypy, PyCharm, Pyre, pytype,
etc...
This is particularly important when working on open-source code that
makes use of these types, seeing as the code would not be immediately
transportable to other developers' tools without additional logic. As a result,
there is a high cost to developing and trying out new types in a codebase.
Ideally, authors should be able to introduce new types in a manner that allows
for graceful degradation (e.g.: when clients do not have a custom mypy plugin), which would lower the barrier to development and ensure some
degree of backward compatibility.

For example, suppose that an author wanted to add support for tagged unions to Python. One way to accomplish would be to annotate `TypedDict` in Python such that only one field is allowed
to be set:

```
Currency = Annotated[
    TypedDict('Currency', {'dollars': float, 'pounds': float}, total=False),
    TaggedUnion,
]
```
This is a somewhat cumbersome syntax but it allows us to iterate on this
proof-of-concept and have people with type checkers (or other tools) that don't
yet support this feature work in a codebase with tagged unions. The author could
easily test this proposal and iron out the kinks before trying to upstream tagged
union to `typing`, mypy, etc. Moreover, tools that do not have support for
parsing the `TaggedUnion` annotation would still be able to treat `Currency`
as a `TypedDict`, which is still a close approximation (slightly less strict).

## Specification
### Syntax
`Annotated` is parameterized with a type and an arbitrary list of
Python values that represent the annotations. Here are the specific
details of the syntax:

* The first argument to `Annotated` must be a valid type

* Multiple type annotations are supported (`Annotated` supports variadic
  arguments):

```
Annotated[int, ValueRange(3, 10), ctype("char")]
```
* `Annotated` must be called with at least two arguments (
  `Annotated[int]` is not valid)

* The order of the annotations is preserved and matters for equality
  checks:

```
Annotated[int, ValueRange(3, 10), ctype("char")] != Annotated[
    int, ctype("char"), ValueRange(3, 10)
]
```
* Nested `Annotated` types are flattened, with metadata ordered
  starting with the innermost annotation:

```
Annotated[Annotated[int, ValueRange(3, 10)], ctype("char")] == Annotated[
    int, ValueRange(3, 10), ctype("char")
]
```
* Duplicated annotations are not removed:

```
Annotated[int, ValueRange(3, 10)] != Annotated[
    int, ValueRange(3, 10), ValueRange(3, 10)
]
```
* `Annotated` can be used with nested and generic aliases:

```
Typevar T = ...
Vec = Annotated[List[Tuple[T, T]], MaxLen(10)]
V = Vec[int]

V == Annotated[List[Tuple[int, int]], MaxLen(10)]
```
### Consuming annotations
Ultimately, the responsibility of how to interpret the annotations (if
at all) is the responsibility of the tool or library encountering the
`Annotated` type. A tool or library encountering an `Annotated` type
can scan through the annotations to determine if they are of interest
(e.g., using `isinstance()`).

**Unknown annotations:** When a tool or a library does not support
annotations or encounters an unknown annotation it should just ignore it
and treat annotated type as the underlying type. For example, when encountering
an annotation that is not an instance of `struct2.ctype` to the annotations
for name (e.g., `Annotated[str, 'foo', struct2.ctype("<10s")]`), the unpack
method should ignore it.

**Namespacing annotations:** Namespaces are not needed for annotations since
the class used by the annotations acts as a namespace.

**Multiple annotations:** It's up to the tool consuming the annotations
to decide whether the client is allowed to have several annotations on
one type and how to merge those annotations.

FastAPI, as the consuming library here, makes that decision explicit: the FastAPI marker (`Query`, `Path`, `Header`, `Cookie`, `Body`, `Form`, `File`, or `Depends`) is placed inside the `Annotated` metadata, and at most one such marker may apply to a given parameter. A marker written inside `Annotated` must not carry its own `default=` — the parameter's default is supplied with `=` instead — and a marker inside `Annotated` may not be combined with a second marker or with a `Depends` passed as the parameter's default value. FastAPI rejects any parameter declaration that breaks these rules when the route is registered.

Since the `Annotated` type allows you to put several annotations of
the same (or different) type(s) on any node, the tools or libraries
consuming those annotations are in charge of dealing with potential
duplicates. For example, if you are doing value range analysis you might
allow this:

```
T1 = Annotated[int, ValueRange(-10, 5)]
T2 = Annotated[T1, ValueRange(-20, 3)]
```
Flattening nested annotations, this translates to:

```
T2 = Annotated[int, ValueRange(-10, 5), ValueRange(-20, 3)]
```
### Interaction with `get_type_hints()`
`typing.get_type_hints()` will take a new argument `include_extras` that
defaults to `False` to preserve backward compatibility. When
`include_extras` is `False`, the extra annotations will be stripped
out of the returned value. Otherwise, the annotations will be returned
unchanged:

```
@struct2.packed
class Student(NamedTuple):
    name: Annotated[str, struct.ctype("<10s")]

get_type_hints(Student) == {'name': str}
get_type_hints(Student, include_extras=False) == {'name': str}
get_type_hints(Student, include_extras=True) == {
    'name': Annotated[str, struct.ctype("<10s")]
}
```
### Aliases & Concerns over verbosity
Writing `typing.Annotated` everywhere can be quite verbose;
fortunately, the ability to alias annotations means that in practice we
don't expect clients to have to write lots of boilerplate code:

```
T = TypeVar('T')
Const = Annotated[T, my_annotations.CONST]

class C:
    def const_method(self: Const[List[int]]) -> int:
        ...
```
## Rejected ideas
Some of the proposed ideas were rejected from this PEP because they would
cause `Annotated` to not integrate cleanly with the other typing annotations:

* `Annotated` cannot infer the decorated type. You could imagine that
  `Annotated[..., Immutable]` could be used to mark a value as immutable
  while still inferring its type. Typing does not support using the
  inferred type anywhere else; it's best to not add this as a
  special case.

* Using `(Type, Ann1, Ann2, ...)` instead of
  `Annotated[Type, Ann1, Ann2, ...]`. This would cause confusion when
  annotations appear in nested positions (`Callable[[A, B], C]` is too similar
  to `Callable[[(A, B)], C]`) and would make it impossible for constructors to
  be passthrough (`T(5) == C(5)` when `C = Annotation[T, Ann]`).

This feature was left out to keep the design simple:

* `Annotated` cannot be called with a single argument. Annotated could support
  returning the underlying value when called with a single argument (e.g.:
  `Annotated[int] == int`). This complicates the specifications and adds
  little benefit.

   https://github.com/python/typing/issues/600

   https://mail.python.org/pipermail/python-ideas/2019-January/054908.html

   http://www.mypy-lang.org/

   https://pyre-check.org/

   https://www.jetbrains.com/pycharm/

   https://github.com/google/pytype

   https://github.com/python/mypy_extensions

   https://en.wikipedia.org/wiki/Tagged_union

   https://mypy.readthedocs.io/en/latest/more_types.html#typeddict

   https://github.com/python/typing/issues/276

## Linked PEP 484 — Type Hints
### Abstract

PEP 3107 introduced syntax for function annotations, but the semantics were deliberately left undefined. There has now been enough 3rd party usage for static type analysis that the community would benefit from a standard vocabulary and baseline tools within the standard library.

This PEP introduces a provisional module to provide these standard definitions and tools, along with some conventions for situations where annotations are not available.

Note that this PEP still explicitly does NOT prevent other uses of annotations, nor does it require (or forbid) any particular processing of annotations, even when they conform to this specification. It simply enables better coordination, as PEP 333 did for web frameworks.

For example, here is a simple function whose argument and return type are declared in the annotations:

```
def greeting(name: str) -> str:
    return 'Hello ' + name
```

While these annotations are available at runtime through the usual `__annotations__` attribute, *no type checking happens at runtime*. Instead, the proposal assumes the existence of a separate off-line type checker which users can run over their source code voluntarily. Essentially, such a type checker acts as a very powerful linter. (While it would of course be possible for individual users to employ a similar checker at run time for Design By Contract enforcement or JIT optimization, those tools are not yet as mature.)

The proposal is strongly inspired by mypy. For example, the type "sequence of integers" can be written as `Sequence[int]`. The square brackets mean that no new syntax needs to be added to the language. The example here uses a custom type `Sequence`, imported from a pure-Python module `typing`. The `Sequence[int]` notation works at runtime by implementing `__getitem__()` in the metaclass (but its significance is primarily to an offline type checker).

The type system supports unions, generic types, and a special type named `Any` which is consistent with (i.e. assignable to and from) all types. This latter feature is taken from the idea of gradual typing. Gradual typing and the full type system are explained in PEP 483.

### Rationale and Goals

PEP 3107 added support for arbitrary annotations on parts of a function definition. Although no meaning was assigned to annotations then, there has always been an implicit goal to use them for type hinting, which is listed as the first possible use case in said PEP.

This PEP aims to provide a standard syntax for type annotations, opening up Python code to easier static analysis and refactoring, potential runtime type checking, and (perhaps, in some contexts) code generation utilizing type information.

Of these goals, static analysis is the most important. This includes support for off-line type checkers such as mypy, as well as providing a standard notation that can be used by IDEs for code completion and refactoring.

#### Non-goals

While the proposed typing module will contain some building blocks for runtime type checking -- in particular the `get_type_hints()` function -- third party packages would have to be developed to implement specific runtime type checking functionality, for example using decorators or metaclasses. Using type hints for performance optimizations is left as an exercise for the reader.

It should also be emphasized that **Python will remain a dynamically typed language, and the authors have no desire to ever make type hints mandatory, even by convention.**

### The meaning of annotations

Any function without annotations should be treated as having the most general type possible, or ignored, by any type checker. Functions with the `@no_type_check` decorator should be treated as having no annotations.

It is recommended but not required that checked functions have annotations for all arguments and the return type. For a checked function, the default annotation for arguments and for the return type is `Any`. An exception is the first argument of instance and class methods. If it is not annotated, then it is assumed to have the type of the containing class for instance methods, and a type object type corresponding to the containing class object for class methods. For example, in class `A` the first argument of an instance method has the implicit type `A`. In a class method, the precise type of the first argument cannot be represented using the available type notation.

(Note that the return type of `__init__` ought to be annotated with `-> None`. The reason for this is subtle. If `__init__` assumed a return annotation of `-> None`, would that mean that an argument-less, un-annotated `__init__` method should still be type-checked? Rather than leaving this ambiguous or introducing an exception to the exception, we simply say that `__init__` ought to have a return annotation; the default behavior is thus the same as for other methods.)

A type checker is expected to check the body of a checked function for consistency with the given annotations. The annotations may also be used to check correctness of calls appearing in other checked functions.

Type checkers are expected to attempt to infer as much information as necessary. The minimum requirement is to handle the builtin decorators `@property`, `@staticmethod` and `@classmethod`.

### Type Definition Syntax

The syntax leverages PEP 3107-style annotations with a number of extensions described in sections below. In its basic form, type hinting is used by filling function annotation slots with classes:

```
def greeting(name: str) -> str:
    return 'Hello ' + name
```

This states that the expected type of the `name` argument is `str`. Analogically, the expected return type is `str`.

Expressions whose type is a subtype of a specific argument type are also accepted for that argument.

#### Acceptable type hints

Type hints may be built-in classes (including those defined in standard library or third-party extension modules), abstract base classes, types available in the `types` module, and user-defined classes (including those defined in the standard library or third-party modules).

While annotations are normally the best format for type hints, there are times when it is more appropriate to represent them by a special comment, or in a separately distributed stub file. (See below for examples.)

Annotations must be valid expressions that evaluate without raising exceptions at the time the function is defined (but see below for forward references).

Annotations should be kept simple or static analysis tools may not be able to interpret the values. For example, dynamically computed types are unlikely to be understood. (This is an intentionally somewhat vague requirement, specific inclusions and exclusions may be added to future versions of this PEP as warranted by the discussion.)

In addition to the above, the following special constructs defined below may be used: `None`, `Any`, `Union`, `Tuple`, `Callable`, all ABCs and stand-ins for concrete classes exported from `typing` (e.g. `Sequence` and `Dict`), type variables, and type aliases.

All newly introduced names used to support features described in following sections (such as `Any` and `Union`) are available in the `typing` module.

PEP 484 is the standard PEP 593 builds on: it defines the `typing` module conventions (type aliases, `Any`, generics, `get_type_hints()`, etc.) that `Annotated` extends with arbitrary runtime metadata. PEP 593's prescription that consumers ignore unknown metadata mirrors PEP 484's stance that annotations not understood by a type checker should not cause errors.

*Source: https://peps.python.org/pep-0484/*

## Linked PEP 3107 — Function Annotations
### Abstract

This PEP introduces a syntax for adding arbitrary metadata annotations to Python functions.

### Rationale

Because Python's 2.x series lacks a standard way of annotating a function's parameters and return values, a variety of tools and libraries have appeared to fill this gap. Some utilise the decorators introduced in PEP 318, while others parse a function's docstring, looking for annotations there.

This PEP aims to provide a single, standard way of specifying this information, reducing the confusion caused by the wide variation in mechanism and syntax that has existed until this point.

### Fundamentals of Function Annotations

Before launching into a discussion of the precise ins and outs of Python 3.0's function annotations, let's first talk broadly about what annotations are and are not:

1. Function annotations, both for parameters and return values, are completely optional.

2. Function annotations are nothing more than a way of associating arbitrary Python expressions with various parts of a function at compile-time.

   By itself, Python does not attach any particular meaning or significance to annotations. Left to its own, Python simply makes these expressions available as described in `Accessing Function Annotations` below.

   The only way that annotations take on meaning is when they are interpreted by third-party libraries. These annotation consumers can do anything they want with a function's annotations. For example, one library might use string-based annotations to provide improved help messages, like so:

   ```
   def compile(source: "something compilable",
               filename: "where the compilable thing comes from",
               mode: "is this a single statement or a suite?"):
       ...
   ```

   Another library might be used to provide typechecking for Python functions and methods. This library could use annotations to indicate the function's expected input and return types, possibly something like:

   ```
   def haul(item: Haulable, *vargs: PackAnimal) -> Distance:
       ...
   ```

   However, neither the strings in the first example nor the type information in the second example have any meaning on their own; meaning comes from third-party libraries alone.

3. Following from point 2, this PEP makes no attempt to introduce any kind of standard semantics, even for the built-in types. This work will be left to third-party libraries.

### Syntax

#### Parameters

Annotations for parameters take the form of optional expressions that follow the parameter name:

```
def foo(a: expression, b: expression = 5):
    ...
```

In pseudo-grammar, parameters now look like `identifier [: expression] [= expression]`. That is, annotations always precede a parameter's default value and both annotations and default values are optional. Just like how equal signs are used to indicate a default value, colons are used to mark annotations. All annotation expressions are evaluated when the function definition is executed, just like default values.

Annotations for excess parameters (i.e., `*args` and `**kwargs`) are indicated similarly:

```
def foo(*args: expression, **kwargs: expression):
    ...
```

Annotations for nested parameters always follow the name of the parameter, not the last parenthesis. Annotating all parameters of a nested parameter is not required:

```
def foo((x1, y1: expression),
        (x2: expression, y2: expression)=(None, None)):
    ...
```

#### Return Values

The examples thus far have omitted examples of how to annotate the type of a function's return value. This is done like so:

```
def sum() -> expression:
    ...
```

That is, the parameter list can now be followed by a literal `->` and a Python expression. Like the annotations for parameters, this expression will be evaluated when the function definition is executed.

#### Lambda

`lambda`'s syntax does not support annotations. The syntax of `lambda` could be changed to support annotations, by requiring parentheses around the parameter list. However it was decided not to make this change because:

1. It would be an incompatible change.
2. Lambdas are neutered anyway.
3. The lambda can always be changed to a function.

### Accessing Function Annotations

Once compiled, a function's annotations are available via the function's `__annotations__` attribute. This attribute is a mutable dictionary, mapping parameter names to an object representing the evaluated annotation expression.

There is a special key in the `__annotations__` mapping, `"return"`. This key is present only if an annotation was supplied for the function's return value.

For example, the following annotation:

```
def foo(a: 'x', b: 5 + 6, c: list) -> max(2, 9):
    ...
```

would result in an `__annotations__` mapping of:

```
{'a': 'x',
 'b': 11,
 'c': list,
 'return': 9}
```

The `return` key was chosen because it cannot conflict with the name of a parameter; any attempt to use `return` as a parameter name would result in a `SyntaxError`.

`__annotations__` is an empty, mutable dictionary if there are no annotations on the function or if the functions was created from a `lambda` expression.

PEP 3107 establishes the very `__annotations__` storage that PEP 593's `Annotated[T, x]` populates with mixed type-and-metadata values. PEP 593 cites PEP 3107's database-mapping / foreign-language-bridge use cases as motivation, observing that PEP 484's prescriptive type annotations have crowded those uses out.

*Source: https://peps.python.org/pep-3107/*

## Linked Issue #600 — Add support for external annotations in the typing module
We propose adding an `Annotated` type to the typing module to decorate existing types with context-specific metadata. Specifically, a type `T` can be annotated with metadata `x` via the typehint `Annotated[T, x]`. This metadata can be used for either static analysis or at runtime. If a library (or tool) encounters a typehint `Annotated[T, x]` and has no special logic for metadata `x`, it should ignore it and simply treat the type as `T`. Unlike the `no_type_check` functionality that current exists in the `typing` module which completely disables typechecking annotations on a function or a class, the `Annotated` type allows for both static typechecking of `T` (e.g., via MyPy or Pyre, which can safely ignore `x`) together with runtime access to `x` within a specific application. We believe that the introduction of this type would address a diverse set of use cases of interest to the broader Python community.

### Motivating examples

#### READING binary data

The `struct` module provides a way to read and write C structs directly from their byte representation. It currently relies on a string representation of the C type to read in values:

```py
record = b'raymond   \x32\x12\x08\x01\x08'
name, serialnum, school, gradelevel = unpack('<10sHHb', record)
```

The documentation suggests using a named tuple to unpack the values and make this a bit more tractable:

```py
from collections import namedtuple
Student = namedtuple('Student', 'name serialnum school gradelevel')
Student._make(unpack('<10sHHb', record))
# Student(name=b'raymond   ', serialnum=4658, school=264, gradelevel=8)
```

However, this recommendation is somewhat problematic; as we add more fields, it's going to get increasingly tedious to match the properties in the named tuple with the arguments in `unpack`.

Instead, annotations can provide better interoperability with a type checker or an IDE without adding any special logic outside of the `struct` module:

```py
from typing import NamedTuple
UnsignedShort = Annotated[int, struct.ctype('H')]
SignedChar = Annotated[int, struct.ctype('b')]

@struct.packed
class Student(NamedTuple):
  # MyPy typechecks 'name' field as 'str'
  name: Annotated[str, struct.ctype("<10s")]
  serialnum: UnsignedShort
  school: SignedChar
  gradelevel: SignedChar

# 'unpack' only uses the metadata within the type annotations
Student.unpack(record))
# Student(name=b'raymond   ', serialnum=4658, school=264, gradelevel=8)
```

#### dataclasses

Here's an example with dataclasses that is a problematic from the typechecking standpoint:

```py
from dataclasses import dataclass, field

@dataclass
class C:
  myint: int = 0
  # the field tells the @dataclass decorator that the default action in the
  # constructor of this class is to set "self.mylist = list()"
  mylist: List[int] = field(default_factory=list)
```

Even though one might expect that `mylist` is a class attribute accessible via `C.mylist` (like `C.myint` is) due to the assignment syntax, that is not the case. Instead, the `@dataclass` decorator strips out the assignment to this attribute, leading to an `AttributeError` upon access:

```py
C.myint  # Ok: 0
C.mylist  # AttributeError: type object 'C' has no attribute 'mylist'
```

This can lead to confusion for newcomers to the library who may not expect this behavior. Furthermore, the typechecker needs to understand the semantics of dataclasses and know to not treat the above example as an assignment operation in (which translates to additional complexity).

It makes more sense to move the information contained in `field` to an annotation:

```py
@dataclass
class C:
    myint: int = 0
    mylist: Annotated[List[int], field(default_factory=list)]

# now, the AttributeError is more intuitive because there is no assignment operator
C.mylist  # AttributeError

# the constructor knows how to use the annotations to set the 'mylist' attribute
c = C()
c.mylist  # []
```

The main benefit of writing annotations like this is that it provides a way for clients to gracefully degrade when they don't know what to do with the extra annotations (by just ignoring them). If you used a typechecker that didn't have any special handling for dataclasses and the `field` annotation, you would still be able to run checks as though the type were simply:

```py
class C:
    myint: int = 0
    mylist: List[int]
```

#### lowering barriers to developing new types

Typically when adding a new type, we need to upstream that type to the typing module and change MyPy, PyCharm, Pyre, pytype, etc. This is particularly important when working on open-source code that makes use of our new types, seeing as the code would not be immediately transportable to other developers' tools without additional logic (this is a limitation of MyPy plugins, which allow for extending MyPy but would require a consumer of new typehints to be using MyPy and have the same plugin installed). As a result, there is a high cost to developing and trying out new types in a codebase. Ideally, we should be able to introduce new types in a manner that allows for graceful degradation when clients do not have a custom MyPy plugin, which would lower the barrier to development and ensure some degree of backward compatibility.

For example, suppose that we wanted to add support for tagged unions to Python. One way to accomplish would be to annotate TypedDict in Python such that only one field is allowed to be set:

```py
Currency = Annotated(
  TypedDict('Currency', {'dollars': float, 'pounds': float}, total=False),
  TaggedUnion,
)
```

This is a somewhat cumbersome syntax but it allows us to iterate on this proof-of-concept and have people with non-patched IDEs work in a codebase with tagged unions. We could easily test this proposal and iron out the kinks before trying to upstream tagged union to `typing`, MyPy, etc. Moreover, tools that do not have support for parsing the `TaggedUnion` annotation would still be able able to treat `Currency` as a `TypedDict`, which is still a close approximation (slightly less strict).

### Details of proposed changes to `typing`

#### Syntax

`Annotated` is parameterized with a type and an arbitrary list of Python values that represent the annotations. Here are the specific details of the syntax:

* The first argument to `Annotated` must be a valid `typing` type
* Multiple type annotations are supported (Annotated supports variadic arguments): `Annotated[int, ValueRange(3, 10), ctype("char")]`
* When called with no extra arguments `Annotated` returns the underlying value: `Annotated[int] == int`
* The order of the annotations is preserved and matters for equality checks: `Annotated[int, ValueRange(3, 10), ctype("char")] != Annotated[int, ctype("char"), ValueRange(3, 10)]`
* Nested `Annotated` types are flattened, with metadata ordered starting with the innermost annotation: `Annotated[Annotated[int, ValueRange(3, 10)], ctype("char")] == Annotated[int, ValueRange(3, 10), ctype("char")]`
* Duplicated annotations are not removed: `Annotated[int, ValueRange(3, 10)] != Annotated[int, ValueRange(3, 10), ValueRange(3, 10)]`

#### consuming annotations

Ultimately, the responsibility of how to interpret the annotations (if at all) is the responsibility of the tool or library encountering the `Annotated` type. A tool or library encountering an `Annotated` type can scan through the annotations to determine if they are of interest (e.g., using `isinstance`).

**Unknown annotations:**
When a tool or a library does not support annotations or encounters an unknown annotation it should just ignore it and treat annotated type as the underlying type. For example, if we were to add an annotation that is not an instance of `struct.ctype` to the annotation for name (e.g., `Annotated[str, 'foo', struct.ctype("<10s")]`), the unpack method should ignore it.

**Namespacing annotations:**
We do not need namespaces for annotations since the class used by the annotations acts as a namespace.

**Multiple annotations:**
It's up to the tool consuming the annotations to decide whether the client is allowed to have several annotations on one type and how to merge those annotations.

Since the `Annotated` type allows you to put several annotations of the same (or different) type(s) on any node, the tools or libraries consuming those annotations are in charge of dealing with potential duplicates. For example, if you are doing value range analysis you might allow this:

```py
T1 = Annotated[int, ValueRange(-10, 5)]
T2 = Annotated[T1, ValueRange(-20, 3)]
```

Flattening nested annotations, this translates to:

```py
T2 = Annotated[int, ValueRange(-10, 5), ValueRange(-20, 3)]
```

An application consuming this type might choose to reduce these annotations via an intersection of the ranges, in which case `T2` would be treated equivalently to `Annotated[int, ValueRange(-10, 3)]`.

An alternative application might reduce these via a union, in which case `T2` would be treated equivalently to `Annotated[int, ValueRange(-20, 5)]`.

In this example whether we reduce those annotations using union or intersection can be context dependant (covarient vs contravariant); this is why we have to preserve all of them and let the consumers decide how to merge them.

Other applications may decide to not support multiple annotations and throw an exception.

#### related bugs

+ issue 482: Mixing typing and non-typing information in annotations has some discussion about this problem but none of the proposed solutions (using intersection types, passing dictionaries of annotations) seemed to garner enough steam. We hope this solution is non-intrusive and compelling enough to make it in the standard library.

PEP 593's body cites this issue as the origin: "This was originally brought up as issue 600 in the typing github". The proposal here is the seed of `Annotated[T, x]` semantics, the consuming-annotations rules, and the motivating struct/dataclass examples that PEP 593 later formalizes.

*Source: https://github.com/python/typing/issues/600*
