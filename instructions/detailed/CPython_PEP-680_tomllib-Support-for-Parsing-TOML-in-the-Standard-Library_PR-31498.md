> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

---

# PEP 680: tomllib: Support for Parsing TOML in the Standard Library

## Abstract
This PEP proposes adding the `tomllib` module to the standard library for
parsing TOML (Tom's Obvious Minimal Language,
[https://toml.io](https://toml.io/en/)).

## Motivation
TOML is the format of choice for Python packaging, as evidenced by
PEP 517, PEP 518 and PEP 621. This creates a bootstrapping
problem for Python build tools, forcing them to vendor a TOML parsing
package or employ other undesirable workarounds, and causes serious issues
for repackagers and other downstream consumers. Including TOML support in
the standard library would neatly solve all of these issues.

Further, many Python tools are now configurable via TOML, such as
`black`, `mypy`, `pytest`, `tox`, `pylint` and `isort`.
Many that are not, such as `flake8`, cite the lack of standard library
support as a [main reason why](https://github.com/PyCQA/flake8/issues/234#issuecomment-812800722).
Given the special place TOML already has in the Python ecosystem, it makes sense
for it to be an included battery.

Finally, TOML as a format is increasingly popular (for the reasons
outlined in PEP 518), with various Python TOML libraries having about
2000 reverse dependencies on PyPI (for comparison, `requests` has about
28000 reverse dependencies). Hence, this is likely to be a generally useful
addition, even looking beyond the needs of Python packaging and related tools.

## Rationale
This PEP proposes basing the standard library support for reading TOML on the
third-party library `tomli`
([github.com/hukkin/tomli](https://github.com/hukkin/tomli)).

Many projects have recently switched to using `tomli`, such as `pip`,
`build`, `pytest`, `mypy`, `black`, `flit`, `coverage`,
`setuptools-scm` and `cibuildwheel`.

`tomli` is actively maintained and well-tested. It is about 800 lines
of code with 100% test coverage, and passes all tests in the
[proposed official TOML compliance test suite](https://github.com/toml-lang/compliance/pull/8), as well as
[the more established BurntSushi/toml-test suite](https://github.com/BurntSushi/toml-test).

## Specification
A new module `tomllib` will be added to the Python standard library,
exposing the following public functions:

```
def load(
    fp: SupportsRead[bytes],
    /,
    *,
    parse_float: Callable[[str], Any] = ...,
 ) -> dict[str, Any]: ...

def loads(
    s: str,
    /,
    *,
    parse_float: Callable[[str], Any] = ...,
) -> dict[str, Any]: ...
```
`tomllib.load` deserializes a binary file-like object containing a
TOML document to a Python `dict`.
The `fp` argument must have a `read()` method with the same API as
`io.RawIOBase.read()`.

`tomllib.loads` deserializes a `str` instance containing a TOML document
to a Python `dict`.

The `parse_float` argument is a callable object that takes as input the
original string representation of a TOML float, and returns a corresponding
Python object (similar to `parse_float` in `json.load`).
For example, the user may pass a function returning a `decimal.Decimal`,
for use cases where exact precision is important. By default, TOML floats
are parsed as instances of the Python `float` type.

The returned object contains only basic Python objects (`str`, `int`,
`bool`, `float`, `datetime.{datetime,date,time}`, `list`, `dict` with
string keys), and the results of `parse_float`.

`tomllib.TOMLDecodeError` is raised in the case of invalid TOML.

Note that this PEP does not propose `tomllib.dump` or `tomllib.dumps`
functions; see `Including an API for writing TOML`_ for details.


### Implementation Guidance

1. Add `Lib/tomllib/__init__.py`. Package init file that exposes the public API: imports and re-exports `loads`, `load` from `_parser` and `TOMLDecodeError` from `_parser`, defining the `__all__` list for the module.

2. Add `Lib/tomllib/_parser.py` defining `Flags`, `NestedDict`, `Output`, and `TOMLDecodeError` with functions `coord_repr`, `create_dict_rule`, `create_list_rule`, `is_unicode_scalar_value`, `key_value_rule`, `load`, `loads`, `make_safe_parse_float`, `parse_array`, `parse_basic_str`, `parse_basic_str_escape`, `parse_basic_str_escape_multiline`, `parse_hex_char`, `parse_inline_table`, `parse_key`, `parse_key_part`, `parse_key_value_pair`, `parse_literal_str`, `parse_multiline_str`, `parse_one_line_basic_str`, `parse_value`, `safe_parse_float`, `skip_chars`, `skip_comment`, `skip_comments_and_array_ws`, `skip_until`, `suffixed_err`, `Flags.__init__`, `Flags.add_pending`, `Flags.finalize_pending`, `Flags.is_`, `Flags.set`, `Flags.unset_all`, `NestedDict.__init__`, `NestedDict.append_nest_to_list`, and `NestedDict.get_or_create_nest`. The core TOML parser implementation (691 lines), ported from the `tomli` library. Implements the `load` and `loads` public functions, the `TOMLDecodeError` exception class, and a complete TOML 1.0.0 compliant parser that handles all TOML data types including strings (basic, literal, multiline), integers (decimal, hex, octal, binary), floats (including special values inf/nan), booleans, datetimes (offset, local, date, time), arrays, inline tables, standard tables, and arrays of tables. Supports the `parse_float` callback for custom float parsing.

3. Add `Lib/tomllib/_re.py` defining functions `cached_tz`, `match_to_datetime`, `match_to_localtime`, and `match_to_number`. Regular expression patterns and helper functions used by the parser for matching TOML datetime formats, and for caching and compiling the regex patterns used during parsing.

4. Add `Lib/tomllib/_types.py`. Type alias definitions used internally by the parser, including the `Key` type and `ParseFloat` callable type alias.

5. In `Python/stdlib_module_names.h`, apply the required changes. Adds `"tomllib"` to the frozen set of stdlib module names so the interpreter recognizes it as a built-in standard library module.
## Maintenance Implications
### Stability of TOML
The release of TOML 1.0.0 in January 2021 indicates the TOML format should
now be officially considered stable. Empirically, TOML has proven to be a
stable format even prior to the release of TOML 1.0.0. From the
[changelog](https://github.com/toml-lang/toml/blob/master/CHANGELOG.md), we
can see that TOML has had no major changes since April 2020, and has had
two releases in the past five years (2017-2021).

In the event of changes to the TOML specification, we can treat minor
revisions as bug fixes and update the implementation in place. In the event of
major breaking changes, we should preserve support for TOML 1.x.

### Maintainability of proposed implementation
The proposed implementation (`tomli`) is pure Python, well tested and
weighs in at under 1000 lines of code. It is minimalist, offering a smaller API
surface area than other TOML implementations.

The author of `tomli` is willing to help integrate `tomli` into the standard
library and help maintain it, [as per this post](https://github.com/hukkin/tomli/issues/141#issuecomment-998018972).
Furthermore, Python core developer Petr Viktorin has indicated a willingness
to maintain a read API, [as per this post](https://discuss.python.org/t/adopting-recommending-a-toml-parser/4068/88).

Rewriting the parser in C is not deemed necessary at this time. It is rare for
TOML parsing to be a bottleneck in applications, and users with higher performance
needs can use a third-party library (as is already often the case with JSON,
despite Python offering a standard library C-extension module).

### TOML support a slippery slope for other things
As discussed in the `Motivation`_ section, TOML holds a special place in the
Python ecosystem, for reading PEP 518 `pyproject.toml` packaging
and tool configuration files.
This chief reason to include TOML in the standard library does not apply to
other formats, such as YAML or MessagePack.

In addition, the simplicity of TOML distinguishes it from other formats like
YAML, which are highly complicated to construct and parse.

An API for writing TOML may, however, be added in a future PEP.

## Backwards Compatibility
This proposal has no backwards compatibility issues within the standard
library, as it describes a new module.
Any existing third-party module named `tomllib` will break, as
`import tomllib` will import the standard library module.
However, `tomllib` is not registered on PyPI, so it is unlikely that any
module with this name is widely used.

Note that we avoid using the more straightforward name `toml` to avoid
backwards compatibility implications for users who have pinned versions of the
current `toml` PyPI package.
For more details, see the `Alternative names for the module`_ section.

## Security Implications
Errors in the implementation could cause potential security issues.
However, the parser's output is limited to simple data types; inability to load
arbitrary classes avoids security issues common in more "powerful" formats like
pickle and YAML. Also, the implementation will be in pure Python, which reduces
security issues endemic to C, such as buffer overflows.

## How to Teach This
The API of `tomllib` mimics that of other well-established file format
libraries, such as `json` and `pickle`. The lack of a `dump` function will
be explained in the documentation, with a link to relevant third-party libraries
(e.g. `tomlkit`, `tomli-w`, `pytomlpp`).

## Rejected Ideas
### Basing on another TOML implementation
Several potential alternative implementations exist:

* `tomlkit` is well established, actively maintained and supports TOML 1.0.0.
  An important difference is that `tomlkit` supports style roundtripping. As a
  result, it has a more complex API and implementation (about 5x as much code as
  `tomli`). Its author does not believe that `tomlkit` is a good choice for
  the standard library.

* `toml` is a very widely used library. However, it is not actively
  maintained, does not support TOML 1.0.0 and has a number of known bugs. Its
  API is more complex than that of `tomli`. It allows customising output style
  through a complicated encoder API, and some very limited and mostly unused
  functionality to preserve input style through an undocumented decoder API.
  For more details on its API differences from this PEP, refer to [Appendix A](PEP 680 Appendix A_).

* `pytomlpp` is a Python wrapper for the C++ project `toml++`. Pure Python
  libraries are easier to maintain than extension modules.

* `rtoml` is a Python wrapper for the Rust project `toml-rs` and hence has
  similar shortcomings to `pytomlpp`.
  In addition, it does not support TOML 1.0.0.

* Writing an implementation from scratch. It's unclear what we would get from
  this; `tomli` meets our needs and the author is willing to help with its
  inclusion in the standard library.

### Including an API for writing TOML
There are several reasons to not include an API for writing TOML.

The ability to write TOML is not needed for the use cases that motivate this
PEP: core Python packaging tools, and projects that need to read TOML
configuration files.

Use cases that involve editing an existing TOML file (as opposed to writing a
brand new one) are better served by a style preserving library. TOML is
intended as a human-readable and -editable configuration format, so it's
important to preserve comments, formatting and other markup. This requires
a parser whose output includes style-related metadata, making it impractical
to output plain Python types like `str` and `dict`. Furthermore, it
substantially complicates the design of the API.

Even without considering style preservation, there are too many degrees of
freedom in how to design a write API. For example, what default style
(indentation, vertical and horizontal spacing, quotes, etc) should the library
use for the output, and how much control should users be given over it?
How should the library handle input and output validation? Should it support
serialization of custom types, and if so, how? While there are reasonable
options for resolving these issues, the nature of the standard library is such
that we only get "one chance to get it right".

Currently, no CPython core developers have expressed willingness to maintain a
write API, or sponsor a PEP that includes one. Since it is hard to change
or remove something in the standard library, it is safer to err on the side of
exclusion for now, and potentially revisit this later.

Therefore, writing TOML is left to third-party libraries. If a good API and
relevant use cases for it are found later, write support can be added in a
future PEP.

### Assorted API details
#### Types accepted as the first argument of `tomllib.load`
The `toml` library on PyPI allows passing paths (and lists of path-like
objects, ignoring missing files and merging the documents into a single object)
to its `load` function. However, allowing this here would be inconsistent
with the behavior of `json.load`, `pickle.load` and other standard library
functions. If we agree that consistency here is desirable,
allowing paths is out of scope for this PEP. This can easily and explicitly
be worked around in user code, or by using a third-party library.

The proposed API takes a binary file, while `toml.load` takes a text file and
`json.load` takes either. Using a binary file allows us to ensure UTF-8 is
the encoding used (ensuring correct parsing on platforms with other default
encodings, such as Windows), and avoid incorrectly parsing files containing
single carriage returns as valid TOML due to universal newlines in text mode.

#### Type accepted as the first argument of `tomllib.loads`
While `tomllib.load` takes a binary file, `tomllib.loads` takes
a text string. This may seem inconsistent at first.

Quoting the [TOML v1.0.0 specification](https://toml.io/en/v1.0.0#spec):

    A TOML file must be a valid UTF-8 encoded Unicode document.

`tomllib.loads` does not intend to load a TOML file, but rather the
document that the file stores. The most natural representation of
a Unicode document in Python is `str`, not `bytes`.

It is possible to add `bytes` support in the future if needed, but
we are not aware of any use cases for it.

### Controlling the type of mappings returned by `tomllib.load[s]`
The `toml` library on PyPI accepts a `_dict` argument in its `load[s]`
functions, which works similarly to the `object_hook` argument in
`json.load[s]`. There are several uses of `_dict` found on
https://grep.app; however, almost all of them are passing
`_dict=OrderedDict`, which should be unnecessary as of Python 3.7.
We found two instances of relevant use: in one case, a custom class was passed
for friendlier KeyErrors; in the other, the custom class had several
additional lookup and mutation methods (e.g. to help resolve dotted keys).

Such a parameter is not necessary for the core use cases outlined in the
`Motivation`_ section. The absence of this can be pretty easily worked around
using a wrapper class, transformer function, or a third-party library. Finally,
support could be added later in a backward-compatible way.

### Removing support for `parse_float` in `tomllib.load[s]`
This option is not strictly necessary, since TOML floats should be implemented
as "IEEE 754 binary64 values", which is equivalent to a Python `float` on most
architectures.

The TOML specification uses the word "SHOULD", however, implying a
recommendation that can be ignored for valid reasons. Parsing floats
differently, such as to `decimal.Decimal`, allows users extra precision beyond
that promised by the TOML format. In the author of `tomli`'s experience, this
is particularly useful in scientific and financial applications. This is also
useful for other cases that need greater precision, or where end-users include
non-developers who may not be aware of the limits of binary64 floats.

There are also niche architectures where the Python `float` is not a IEEE 754
binary64 value. The `parse_float` argument allows users to achieve correct
TOML semantics even on such architectures.

### Alternative names for the module
Ideally, we would be able to use the `toml` module name.

However, the `toml` package on PyPI is widely used, so there are backward
compatibility concerns. Since the standard library takes precedence over third
party packages, libraries and applications who current depend on the `toml`
package would likely break when upgrading Python versions due to the many
API incompatibilities listed in [Appendix A](PEP 680 Appendix A_),
even if they pin their dependency versions.

To further clarify, applications with pinned dependencies are of greatest
concern here. Even if we were able to obtain control of the `toml` PyPI
package name and repurpose it for a backport of the proposed new module,
we would still break users on new Python versions that included it in the
standard library, regardless of whether they have pinned an older version of
the existing `toml` package. This is unfortunate, since pinning
would likely be a common response to breaking changes introduced by repurposing
the `toml` package as a backport (that is incompatible with today's `toml`).

Finally, the `toml` package on PyPI is not actively maintained, but as of
yet, efforts to request that the author add other maintainers
[have been unsuccessful](https://github.com/uiri/toml/issues/361),
so action here would likely have to be taken without the author's consent.

Instead, this PEP proposes the name `tomllib`. This mirrors `plistlib`
and `xdrlib`, two other file format modules in the standard library, as well
as other modules, such as `pathlib`, `contextlib` and `graphlib`.

Other names considered but rejected include:

* `tomlparser`. This mirrors `configparser`, but is perhaps somewhat less
  appropriate if we include a write API in the future.
* `tomli`. This assumes we use `tomli` as the basis for implementation.
* `toml` under some namespace, such as `parser.toml`. However, this is
  awkward, especially so since existing parsing libraries like `json`,
  `pickle`, `xml`, `html` etc. would not be included in the namespace.

## Previous Discussion
* [bpo-40059: Provide a toml module in the standard library](https://bugs.python.org/issue40059)
* [[Python-Dev] Adding a toml module to the standard lib?](https://mail.python.org/pipermail/python-dev/2019-May/157405.html)
* [[Python-Ideas] Python standard library TOML module](https://mail.python.org/archives/list/[email-redacted]/thread/IWJ3I32A4TY6CIVQ6ONPEBPWP4TOV2V7/)
* [[Packaging] Adopting/recommending a toml parser?](https://discuss.python.org/t/adopting-recommending-a-toml-parser/4068)
* [hukkin/tomli#141: Please consider pushing tomli into the stdlib](https://github.com/hukkin/tomli/issues/141)

.. _PEP 680 Appendix A:

## Appendix A: Differences between proposed API and `toml`
This appendix covers the differences between the API proposed in this PEP and
that of the third-party package `toml`. These differences are relevant to
understanding the amount of breakage we could expect if we used the `toml`
name for the standard library module, as well as to better understand the design
space. Note that this list might not be exhaustive.

#. No proposed inclusion of a write API (no `toml.dump[s]`)

   This PEP currently proposes not including a write API; that is, there will
   be no equivalent of `toml.dump` or `toml.dumps`, as discussed at
   `Including an API for writing TOML`_.

   If we included a write API, it would be relatively straightforward to
   convert most code that uses `toml` to the new standard library module
   (acknowledging that this is very different from a compatible API, as it
   would still require code changes).

   A significant fraction of `toml` users rely on this, based on comparing
   [occurrences of "toml.load"](https://grep.app/search?q=toml.load&filter[lang][0]=Python)
   to [occurrences of "toml.dump"](https://grep.app/search?q=toml.dump&filter[lang][0]=Python).

#. Different first argument of `toml.load`

   `toml.load` has the following signature:

   ```
   def load(
       f: Union[SupportsRead[str], str, bytes, list[PathLike | str | bytes]],
       _dict: Type[MutableMapping[str, Any]] = ...,
       decoder: TomlDecoder = ...,
   ) -> MutableMapping[str, Any]: ...
   ```

   This is quite different from the first argument proposed in this PEP:
   `SupportsRead[bytes]`.

   Recapping the reasons for this, previously mentioned at
   `Types accepted as the first argument of tomllib.load`_:

   * Allowing paths (and even lists of paths) as arguments is inconsistent with
     other similar functions in the standard library.
   * Using `SupportsRead[bytes]` allows us to ensure UTF-8 is the encoding used,
     and avoid incorrectly parsing single carriage returns as valid TOML.

   A significant fraction of `toml` users rely on this, based on manual
   inspection of [occurrences of "toml.load"](https://grep.app/search?q=toml.load&filter[lang][0]=Python).

#. Errors

   `toml` raises `TomlDecodeError`, vs. the proposed PEP 8-compliant
   `TOMLDecodeError`.

   A significant fraction of `toml` users rely on this, based on
   [occurrences of "TomlDecodeError"](https://grep.app/search?q=TomlDecodeError&case=true&filter[lang][0]=Python).

#. `toml.load[s]` accepts a `_dict` argument

   Discussed at `Controlling the type of mappings returned by tomllib.load[s]`_.

   As mentioned there, almost all usage consists of `_dict=OrderedDict`,
   which is not necessary in Python 3.7 and later.

#. `toml.load[s]` support an undocumented `decoder` argument

   It seems the intended use case is for an implementation of comment
   preservation. The information recorded is not sufficient to roundtrip the
   TOML document preserving style, the implementation has known bugs, the
   feature is undocumented and we could only find one instance of its use on
   https://grep.app.

   The [toml.TomlDecoder interface](https://github.com/uiri/toml/blob/3f637dba5f68db63d4b30967fedda51c82459471/toml/decoder.pyi#L36)
   exposed is far from simple, containing nine methods.

   Users are likely better served by a more complete implementation of
   style-preserving parsing and writing.

#. `toml.dump[s]` support an `encoder` argument

   Note that we currently propose to not include a write API; however, if that
   were to change, these differences would likely become relevant.

   The `encoder` argument enables two use cases:

   * control over how custom types should be serialized, and
   * control over how output should be formatted.

   The first is reasonable; however, we could only find two instances of
   this on https://grep.app. One of these two used this ability to add
   support for dumping `decimal.Decimal`, which a potential standard library
   implementation would support out of the box.
   If needed for other types, this use case could be well served by the
   equivalent of the `default` argument in `json.dump`.

   The second use case is enabled by allowing users to specify subclasses of
   [toml.TomlEncoder](https://github.com/uiri/toml/blob/3f637dba5f68db63d4b30967fedda51c82459471/toml/encoder.pyi#L9)
   and overriding methods to specify parts of the TOML writing process. The API
   consists of five methods and exposes substantial implementation detail.

   There is some usage of the `encoder` API on https://grep.app; however, it
   appears to account for a tiny fraction of the overall usage of `toml`.

#. Timezones

   `toml` uses and exposes custom `toml.tz.TomlTz` timezone objects. The
   proposed implementation uses `datetime.timezone` objects from the standard
   library.

## Linked PEP 517 — A build-system independent format for source trees
### Abstract

While `distutils` / `setuptools` have taken us a long way, they suffer from three serious problems: (a) they're missing important features like usable build-time dependency declaration, autoconfiguration, and even basic ergonomic niceties like DRY-compliant version number management, and (b) extending them is difficult, so while there do exist various solutions to the above problems, they're often quirky, fragile, and expensive to maintain, and yet (c) it's very difficult to use anything else, because distutils/setuptools provide the standard interface for installing packages expected by both users and installation tools like `pip`.

Previous efforts (e.g. distutils2 or setuptools itself) have attempted to solve problems (a) and/or (b). This proposal aims to solve (c).

The goal of this PEP is get distutils-sig out of the business of being a gatekeeper for Python build systems. If you want to use distutils, great; if you want to use something else, then that should be easy to do using standardized methods. The difficulty of interfacing with distutils means that there aren't many such systems right now, but to give a sense of what we're thinking about see flit or bento. Fortunately, wheels have now solved many of the hard problems here -- e.g. it's no longer necessary that a build system also know about every possible installation configuration -- so pretty much all we really need from a build system is that it have some way to spit out standard-compliant wheels and sdists.

We therefore propose a new, relatively minimal interface for installation tools like `pip` to interact with package source trees and source distributions.

### Terminology and goals

A *source tree* is something like a VCS checkout. We need a standard interface for installing from this format, to support usages like `pip install some-directory/`.

A *source distribution* is a static snapshot representing a particular release of some source code, like `lxml-3.4.4.tar.gz`. Source distributions serve many purposes: they form an archival record of releases, they provide a stupid-simple de facto standard for tools that want to ingest and process large corpora of code, possibly written in many languages (e.g. code search), they act as the input to downstream packaging systems like Debian/Fedora/Conda/..., and so forth. In the Python ecosystem they additionally have a particularly important role to play, because packaging tools like `pip` are able to use source distributions to fulfill binary dependencies, e.g. if there is a distribution `foo.whl` which declares a dependency on `bar`, then we need to support the case where `pip install bar` or `pip install foo` automatically locates the sdist for `bar`, downloads it, builds it, and installs the resulting package.

Source distributions are also known as *sdists* for short.

A *build frontend* is a tool that users might run that takes arbitrary source trees or source distributions and builds wheels from them. The actual building is done by each source tree's *build backend*. In a command like `pip wheel some-directory/`, pip is acting as a build frontend.

An *integration frontend* is a tool that users might run that takes a set of package requirements (e.g. a requirements.txt file) and attempts to update a working environment to satisfy those requirements. This may require locating, building, and installing a combination of wheels and sdists. In a command like `pip install lxml==2.4.0`, pip is acting as an integration frontend.

PEP 517 defines the build-backend hook interface (`build_wheel`, `build_sdist`, etc.) that frontends invoke after reading the build requirements declared in `pyproject.toml` (per PEP 518). It is one of the two PEPs that motivate having a TOML parser in the Python standard library: any tool implementing the build-frontend role must read `pyproject.toml` before it knows what build backend or dependencies to install, creating the bootstrapping problem that PEP 680 resolves.

*Source: https://peps.python.org/pep-0517/*

## Linked PEP 518 — Specifying Minimum Build System Requirements for Python Projects
### Abstract

This PEP specifies how Python software packages should specify what build dependencies they have in order to execute their chosen build system. As part of this specification, a new configuration file is introduced for software packages to use to specify their build dependencies (with the expectation that the same configuration file will be used for future configuration details).

### Rationale

When Python first developed its tooling for building distributions of software for projects, distutils was the chosen solution. As time went on, setuptools gained popularity to add some features on top of distutils. Both used the concept of a `setup.py` file that project maintainers executed to build distributions of their software (as well as users to install said distribution).

Using an executable file to specify build requirements under distutils isn't an issue as distutils is part of Python's standard library. Having the build tool as part of Python means that a `setup.py` has no external dependency that a project maintainer needs to worry about to build a distribution of their project. There was no need to specify any dependency information as the only dependency is Python.

But when a project chooses to use setuptools, the use of an executable file like `setup.py` becomes an issue. You can't execute a `setup.py` file without knowing its dependencies, but currently there is no standard way to know what those dependencies are in an automated fashion without executing the `setup.py` file where that information is stored. It's a catch-22 of a file not being runnable without knowing its own contents which can't be known programmatically unless you run the file.

This PEP attempts to rectify the situation by specifying a way to list the minimal dependencies of the build system of a project in a declarative fashion in a specific file. This allows a project to list what build dependencies it has to go from e.g. source checkout to wheel, while not falling into the catch-22 trap that a `setup.py` has where tooling can't infer what a project needs to build itself. Implementing this PEP will allow projects to specify what build system they depend on upfront so that tools like pip can make sure that they are installed in order to run the build system to build the project.

### Specification (File Format)

The build system dependencies will be stored in a file named `pyproject.toml` that is written in the TOML format.

This format was chosen as it is human-usable (unlike JSON), it is flexible enough (unlike configparser), stems from a standard (also unlike configparser), and it is not overly complex (unlike YAML). The TOML format is already in use by the Rust community as part of their Cargo package manager and in private email stated they have been quite happy with their choice of TOML. The authors do realize, though, that choice of configuration file format is ultimately subjective and a choice had to be made and the authors prefer TOML for this situation.

#### build-system table

The `[build-system]` table is used to store build-related data. Initially only one key of the table will be valid and is mandatory for the table: `requires`. This key must have a value of a list of strings representing PEP 508 dependencies required to execute the build system.

For the vast majority of Python projects that rely upon setuptools, the `pyproject.toml` file will be:

```
[build-system]
# Minimum requirements for the build system to execute.
requires = ["setuptools"]  # PEP 508 specifications.
```

Because the use of setuptools is so expansive in the community at the moment, build tools are expected to use the example configuration file above as their default semantics when a `pyproject.toml` file is not present.

#### tool table

The `[tool]` table is where any tool related to your Python project, not just build tools, can have users specify configuration data as long as they use a sub-table within `[tool]`, e.g. the flit tool would store its configuration in `[tool.flit]`.

We need some mechanism to allocate names within the `tool.*` namespace, to make sure that different projects don't attempt to use the same sub-table and collide. Our rule is that a project can use the subtable `tool.$NAME` if, and only if, they own the entry for `$NAME` in the Cheeseshop/PyPI.

PEP 518 is what makes `pyproject.toml` the canonical configuration file consumed by Python build tools — and therefore the file that forces every build tool, including pip itself, to be able to parse TOML before it can install anything. This is the chief reason PEP 680 considers TOML support a battery that belongs in the standard library.

*Source: https://peps.python.org/pep-0518/*

## Linked PEP 621 — Storing project metadata in pyproject.toml
### Abstract

This PEP specifies how to write a project's core metadata in a `pyproject.toml` file for packaging-related tools to consume.

### Motivation

The key motivators of this PEP are:

- Encourage users to specify core metadata statically for speed, ease of specification, unambiguity, and deterministic consumption by build back-ends
- Provide a tool-agnostic way of specifying metadata for ease of learning and transitioning between build back-ends
- Allow for more code sharing between build back-ends for the "boring parts" of a project's metadata

To speak specifically to the motivation for static metadata, that has been an overall goal of the packaging ecosystem for some time. As such, making it easy to specify metadata statically is important. This also means that raising the cost of specifying data as dynamic is acceptable as users should skew towards wanting to provide static metadata.

Requiring the distinction between static and dynamic metadata also helps with disambiguation for when metadata isn't specified. When any metadata *may* be dynamic, it means you never know if the absence of metadata is on purpose or because it is to be provided later. By requiring that dynamic metadata be specified, it disambiguates the intent when metadata goes unspecified.

This PEP does **not** attempt to standardize all possible metadata required by a build back-end, only the metadata covered by the core metadata specification which are very common across projects and would stand to benefit from being static and consistently specified. This means build back-ends are still free and able to innovate around patterns like how to specify the files to include in a wheel. There is also an included escape hatch for users and build back-ends to use when they choose to partially opt-out of this PEP (compared to opting-out of this PEP entirely, which is also possible).

### Rationale

The design guidelines the authors of this PEP followed were:

- Define a representation of as much of the core metadata in `pyproject.toml` as is reasonable
- Define the metadata statically with an escape hatch for those who want to define it dynamically later via a build back-end
- Use familiar names where it makes sense, but be willing to use more modern terminology
- Try to be ergonomic within a TOML file instead of mirroring how build back-ends specify metadata at a low-level when it makes sense
- Learn from other build back-ends in the packaging ecosystem which have used TOML for their metadata
- Don't try to standardize things which lack a pre-existing standard at a lower-level
- *When* metadata is specified using this PEP, it is considered canonical

### Specification (Details)

When specifying project metadata, tools MUST adhere and honour the metadata as specified in this PEP. If metadata is improperly specified then tools MUST raise an error to notify the user about their mistake.

Data specified using this PEP is considered canonical. Tools CANNOT remove, add or change data that has been statically specified. Only when a field is marked as `dynamic` may a tool provide a "new" value.

#### Table name

Tools MUST specify fields defined by this PEP in a table named `[project]`. No tools may add fields to this table which are not defined by this PEP or subsequent PEPs. For tools wishing to store their own settings in `pyproject.toml`, they may use the `[tool]` table as defined in PEP 518. The lack of a `[project]` table implicitly means the build back-end will dynamically provide all fields.

PEP 621 extends `pyproject.toml` so it carries not just build-system requirements (PEP 518) but the project's static core metadata (name, version, dependencies, classifiers, entry points, etc.). This makes TOML parsing a prerequisite for every Python install/build/publish tool, reinforcing the bootstrapping argument behind PEP 680.

*Source: https://peps.python.org/pep-0621/*

## Linked Issue #84240 — Provide a toml module in the standard library (bpo-40059)

BPO | 40059
--- | :---
Nosy | @brettcannon, @tiran, @mcepl, @njsmith, @encukou, @agronholm, @mgorny, @dstufft, @pradyunsg, @eli-schwartz, @miss-islington, @tirkarthi, @skoslowski, @erlend-aasland, @hauntsaninja, @domdfcoding, @hukkin, @YakoYakoYokuYoku
PRs | python/cpython#31498, python/cpython#31784

This issue (originally tracked as bpo-40059 on the legacy bug tracker, now migrated to GitHub as python/cpython#84240) is the canonical CPython tracker entry that PEP 680 lists under "Previous Discussion." It records the request to add a TOML parser to the standard library, predates the PEP, and is the issue referenced from the linked PR (#31498) and from hukkin/tomli#141. The migrated record shows the issue was filed 2020-03-25 by `mgorny` with type `enhancement` and components `Library (Lib)`; PR-31498 is one of the two PRs linked from this issue and is the implementation landed for Python 3.11.

*Source: https://github.com/python/cpython/issues/84240*

## Linked Issue #141 (hukkin/tomli) — Please consider pushing tomli into stdlib

Long story short, having a TOML parser in Python stdlib would be great and tomli seems to be the best implementation available right now, so also the best candidate for stdlib. Would you be interested in trying to push it?

The relevant CPython bug is: https://bugs.python.org/issue40059

This is the upstream issue cited by PEP 680's "Maintainability of proposed implementation" section as evidence that the author of `tomli` is willing to help integrate `tomli` into the standard library and help maintain it. PR-31498 acts on this offer by importing the `tomli` parser into `Lib/tomllib/` as the basis for the stdlib `tomllib` module.

*Source: https://github.com/hukkin/tomli/issues/141*
