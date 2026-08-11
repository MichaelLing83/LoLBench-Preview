# CPython - PEP 615: Support for the IANA Time Zone Database in the Standard Library

**PR:** https://github.com/python/cpython/pull/19909
**Requirement Doc:** https://peps.python.org/pep-0615/

## Matching Statistics
- **Requirement Doc Coverage:** 10/10 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 7/27 files mapped (25.9%) + 20/27 files associated (74.1%) = 27/27 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | PEP 615: Support for the IANA Time Zone Database in the Standard Library | No | N/A | knowledge |
| 2 | Abstract | No | N/A | knowledge |
| 3 | Motivation | No | N/A | contextual |
| 4 | Proposal | No | N/A | knowledge |
| 5 | Proposal > The `zoneinfo.ZoneInfo` class | No | N/A | knowledge |
| 6 | Proposal > The `zoneinfo.ZoneInfo` class > Constructors | Yes | Yes | implementation |
| 7 | Proposal > The `zoneinfo.ZoneInfo` class > Behavior during data updates | Yes | Yes | implementation |
| 8 | Proposal > The `zoneinfo.ZoneInfo` class > Deliberate cache invalidation | Yes | Yes | implementation |
| 9 | Proposal > The `zoneinfo.ZoneInfo` class > String representation | Yes | Yes | implementation |
| 10 | Proposal > The `zoneinfo.ZoneInfo` class > Pickle serialization | Yes | Yes | implementation |
| 11 | Proposal > Sources for time zone data | No | N/A | knowledge |
| 12 | Proposal > Sources for time zone data > System time zone information | Yes | Yes | implementation |
| 13 | Proposal > Sources for time zone data > The `tzdata` Python package | Yes | Yes | implementation |
| 14 | Proposal > Search path configuration | No | N/A | knowledge |
| 15 | Proposal > Search path configuration > Compile-time options | Yes | Yes | implementation |
| 16 | Proposal > Search path configuration > Environment variables | Yes | Yes | implementation |
| 17 | Proposal > Search path configuration > `reset_tzpath` function | Yes | Yes | implementation |
| 18 | Backwards Compatibility | No | N/A | contextual |
| 19 | Security Implications | No | N/A | contextual |
| 20 | Reference Implementation | No | N/A | contextual |
| 21 | Rejected Ideas | No | N/A | contextual |
| 22 | Rejected Ideas > Building a custom tzdb compiler | No | N/A | contextual |
| 23 | Rejected Ideas > Including `tzdata` in the standard library by default | No | N/A | contextual |
| 24 | Rejected Ideas > Support for leap seconds | No | N/A | contextual |
| 25 | Rejected Ideas > Using a `pytz`-like interface | No | N/A | contextual |
| 26 | Rejected Ideas > Windows support via Microsoft's ICU API | No | N/A | contextual |
| 27 | Rejected Ideas > Alternative environment variable configurations | No | N/A | contextual |
| 28 | Rejected Ideas > Using the `datetime` module | No | N/A | contextual |
| 29 | Rejected Ideas > Using the `datetime` module > Arguments against putting `ZoneInfo` directly into `datetime` | No | N/A | contextual |
| 30 | Rejected Ideas > Using the `datetime` module > Using `datetime.zoneinfo` instead of `zoneinfo` | No | N/A | contextual |
| 31 | Footnotes | No | N/A | process |
| 32 | References | No | N/A | process |
| 33 | References > Other time zone implementations: | No | N/A | contextual |
| 34 | Copyright | No | N/A | process |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `.github/workflows/coverage.yml` | build | — | Section 6 |
| 2 | `.travis.yml` | build | — | Section 6 |
| 3 | `Lib/sysconfig.py` | source | — | Section 6 |
| 4 | `Lib/test/test_zoneinfo/__init__.py` | test | — | Section 6 |
| 5 | `Lib/test/test_zoneinfo/__main__.py` | test | — | Section 6 |
| 6 | `Lib/test/test_zoneinfo/_support.py` | test | — | Section 6 |
| 7 | `Lib/test/test_zoneinfo/data/update_test_data.py` | test | — | Section 6 |
| 8 | `Lib/test/test_zoneinfo/data/zoneinfo_data.json` | test-data | — | Section 6 |
| 9 | `Lib/test/test_zoneinfo/test_zoneinfo.py` | test | — | Section 6, Section 8, Section 9, Section 10, Section 12, Section 13, Section 16, Section 17 |
| 10 | `Lib/zoneinfo/__init__.py` | source | Section 6, Section 17 | — |
| 11 | `Lib/zoneinfo/_common.py` | source | Section 6, Section 13 | — |
| 12 | `Lib/zoneinfo/_tzpath.py` | source | Section 12, Section 16, Section 17 | — |
| 13 | `Lib/zoneinfo/_zoneinfo.py` | source | Section 6, Section 7, Section 8, Section 9, Section 10 | — |
| 14 | `Makefile.pre.in` | build | — | Section 6 |
| 15 | `Misc/requirements-test.txt` | build | — | Section 6, Section 13 |
| 16 | `Modules/Setup` | build | — | Section 6 |
| 17 | `Modules/_zoneinfo.c` | source | Section 6, Section 7, Section 8, Section 9, Section 10 | — |
| 18 | `PCbuild/_zoneinfo.vcxproj` | build | — | Section 6 |
| 19 | `PCbuild/_zoneinfo.vcxproj.filters` | build | — | Section 6 |
| 20 | `PCbuild/lib.pyproj` | build | — | Section 6 |
| 21 | `PCbuild/pcbuild.proj` | build | — | Section 6 |
| 22 | `PCbuild/pcbuild.sln` | build | — | Section 6 |
| 23 | `PCbuild/readme.txt` | documentation | — | Section 6 |
| 24 | `Tools/msi/lib/lib_files.wxs` | build | — | Section 6 |
| 25 | `configure` | build | Section 15 | — |
| 26 | `configure.ac` | build | Section 15 | — |
| 27 | `setup.py` | build | — | Section 6 |

---

## Section 6: Constructors
*Path: Proposal > The `zoneinfo.ZoneInfo` class > Constructors*
*Classification: Implementable*

> The initial design of the `zoneinfo.ZoneInfo` class has several constructors.
>
> ```
> ZoneInfo(key: str)
> ```
> The primary constructor takes a single argument, `key`, which is a string
> indicating the name of a zone file in the system time zone database (e.g.
> `"America/New_York"`, `"Europe/London"`), and returns a `ZoneInfo`
> constructed from the first matching data source on search path (see the
> data-sources_ section for more details). All zone information must be eagerly
> read from the data source (usually a TZif file) upon construction, and may
> not change during the lifetime of the object (this restriction applies to all
> `ZoneInfo` constructors).
>
> In the event that no matching file is found on the search path (either because
> the system does not supply time zone data or because the key is invalid), the
> constructor will raise a `zoneinfo.ZoneInfoNotFoundError`, which will be a
> subclass of `KeyError`.
>
> One somewhat unusual guarantee made by this constructor is that calls with
> identical arguments must return *identical* objects. Specifically, for all
> values of `key`, the following assertion must always be valid [b]_:
>
> ```
> a = ZoneInfo(key)
> b = ZoneInfo(key)
> assert a is b
> ```
> The reason for this comes from the fact that the semantics of datetime
> operations (e.g. comparison, arithmetic) depend on whether the datetimes
> involved represent the same or different zones; two datetimes are in the same
> zone only if `dt1.tzinfo is dt2.tzinfo`. [#nontransitive_comp]_ In addition
> to the modest performance benefit from avoiding unnecessary proliferation of
> `ZoneInfo` objects, providing this guarantee should minimize surprising
> behavior for end users.
>
> |dateutil.tz.gettz| has provided a similar guarantee since version 2.7.0
> (release March 2018). [#dateutil-tz]_
>
> .. |dateutil.tz.gettz| replace:: `dateutil.tz.gettz`
> .. _dateutil.tz.gettz: https://dateutil.readthedocs.io/en/stable/tz.html#dateutil.tz.gettz
>
> > **Note:** The implementation may decide how to implement the cache behavior, but the guarantee made here only requires that as long as two references exist to the result of identical constructor calls, they must be references to the same object. This is consistent with a reference counted cache where `ZoneInfo` objects are ejected when no references to them exist (for example, a cache implemented with a `weakref.WeakValueDictionary`) — it is allowed but not required or recommended to implement this with a "strong" cache, where all `ZoneInfo` objects are kept alive indefinitely.
> ```
> ZoneInfo.no_cache(key: str)
> ```
> This is an alternate constructor that bypasses the constructor's cache.  It is
> identical to the primary constructor, but returns a new object on each call.
> This is likely most useful for testing purposes, or to deliberately induce
> "different zone" semantics between datetimes with the same nominal time zone.
>
> Even if an object constructed by this method would have been a cache miss, it
> must not be entered into the cache; in other words, the following assertion
> should always be true:
>
> ```
> >>> a = ZoneInfo.no_cache(key)
> >>> b = ZoneInfo(key)
> >>> a is not b
> ```
> ```
> ZoneInfo.from_file(fobj: IO[bytes], /, key: str = None)
> ```
> This is an alternate constructor that allows the construction of a `ZoneInfo`
> object from any TZif byte stream.  This constructor takes an optional
> parameter, `key`, which sets the name of the zone, for the purposes of
> `__str__` and `__repr__` (see [Representations](string representation_)).
>
> Unlike the primary constructor, this always constructs a new object.  There are
> two reasons that this deviates from the primary constructor's caching behavior:
> stream objects have mutable state and so determining whether two inputs are
> identical is difficult or impossible, and it is likely that users constructing
> from a file specifically want to load from that file and not a cache.
>
> As with `ZoneInfo.no_cache`, objects constructed by this method must not be
> added to the cache.

#### Requirement Summary
This section specifies the three constructors for the `ZoneInfo` class: the primary `ZoneInfo(key)` constructor with identity-based caching, the `ZoneInfo.no_cache(key)` constructor that bypasses the cache, and `ZoneInfo.from_file(fobj, key)` for constructing from a TZif byte stream. The PR implements these in both the pure-Python `_zoneinfo.py` module and the C accelerator `_zoneinfo.c`, with the `_common.py` module providing TZif binary parsing and `__init__.py` exposing the public API.

**File proportion:** 4/27 files mapped (14.8%) + 20/27 files associated (74.1%) = 24/27 accounted (88.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/zoneinfo/__init__.py` | Added | +29 / -0 | — | `__dir__`, `__getattr__` |
| `Lib/zoneinfo/_common.py` | Added | +166 / -0 | `_TZifHeader`, `ZoneInfoNotFoundError` | `load_data`, `load_tzdata` |
| `Lib/zoneinfo/_zoneinfo.py` | Added | +755 / -0 | `ZoneInfo`, `_ttinfo`, `_TZStr`, `_DayOffset`, `_CalendarOffset` | `_load_timedelta`, `_parse_dst_start_end`, `_parse_tz_delta`, `_parse_tz_str`, `_post_epoch_days_before_year` |
| `Modules/_zoneinfo.c` | Added | +2695 / -0 | `TransitionRuleType`, `StrongCacheNode`, `PyModuleDef` | `zoneinfo_new_instance`, `get_weak_cache`, `zoneinfo_new`, `zoneinfo_dealloc`, `zoneinfo_from_file`, `zoneinfo_no_cache`, `zoneinfo_utcoffset`, `zoneinfo_dst`, `zoneinfo_tzname`, `zoneinfo_fromutc`, `load_timedelta`, `build_ttinfo`, `xdecref_ttinfo`, `ttinfo_eq`, `load_data`, `calendarrule_year_to_timestamp`, `calendarrule_new`, `dayrule_year_to_timestamp`, `dayrule_new`, `tzrule_transitions`, `find_tzrule_ttinfo`, `find_tzrule_ttinfo_fromutc`, `parse_tz_str`, `parse_uint`, `parse_abbr`, `parse_tz_delta`, `parse_transition_rule`, `parse_transition_time`, `build_tzrule`, `free_tzrule`, `utcoff_to_dstoff`, `ts_to_local`, `_bisect`, `find_ttinfo`, `is_leap_year`, `ymd_to_ord`, `get_local_timestamp`, `strong_cache_node_new`, `strong_cache_node_free`, `strong_cache_free`, `find_in_strong_cache`, `move_strong_cache_node_to_front`, `zone_from_strong_cache`, `update_strong_cache`, `new_weak_cache`, `initialize_caches`, `zoneinfo_init_subclass`, `module_free`, `zoneinfomodule_exec`, `PyInit__zoneinfo` |

#### Modification Summary
- **`Lib/zoneinfo/__init__.py`**: Creates the `zoneinfo` package, importing and re-exporting the `ZoneInfo` class from `_zoneinfo` (with fallback to the pure-Python implementation), `TZPATH`, and `reset_tzpath`.
- **`Lib/zoneinfo/_common.py`**: Implements the TZif binary file parser (`load_tzdata`, `load_data`) that reads transition times, UTC offsets, DST indicators, and abbreviations from TZif version 1 and version 2/3 files, providing the data structures consumed by the `ZoneInfo` constructors.
- **`Lib/zoneinfo/_zoneinfo.py`**: Implements the pure-Python `ZoneInfo` class with the primary cached constructor, `no_cache` alternate constructor, `from_file` file-based constructor, a `WeakValueDictionary`-based instance cache, `clear_cache`, `__str__`/`__repr__`, pickle support via `__reduce__`, and all `tzinfo` protocol methods (`utcoffset`, `dst`, `tzname`, `fromutc`).
- **`Modules/_zoneinfo.c`**: Implements the C accelerator version of the `ZoneInfo` class as a CPython extension module, providing equivalent functionality to `_zoneinfo.py` with higher performance: cached construction, `no_cache`, `from_file`, `clear_cache`, string representation, pickle serialization, and all `tzinfo` protocol methods.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `.github/workflows/coverage.yml` | Modified | +1 / -0 | CI config updated to include zoneinfo module in coverage | — | — |
| `.travis.yml` | Modified | +1 / -0 | CI config updated to install tzdata test dependency | — | — |
| `Lib/sysconfig.py` | Modified | +1 / -0 | Registers `_zoneinfo` in the list of extension modules for sysconfig | — | — |
| `Lib/test/test_zoneinfo/__init__.py` | Added | +1 / -0 | Test package init for the new zoneinfo test suite | — | — |
| `Lib/test/test_zoneinfo/__main__.py` | Added | +3 / -0 | Test runner entry point for zoneinfo tests | — | — |
| `Lib/test/test_zoneinfo/_support.py` | Added | +76 / -0 | Test support utilities (OS-specific helpers, skip decorators) for zoneinfo tests | — | — |
| `Lib/test/test_zoneinfo/data/update_test_data.py` | Added | +122 / -0 | Script to regenerate test data JSON from IANA time zone database | — | — |
| `Lib/test/test_zoneinfo/data/zoneinfo_data.json` | Added | +190 / -0 | Pre-computed test data with expected transition times, offsets, and DST values | — | — |
| `Lib/test/test_zoneinfo/test_zoneinfo.py` | Added | +1994 / -0 | Comprehensive test suite covering constructors, caching, cache invalidation, string representation, pickling, TZPATH, and all tzinfo protocol methods | — | — |
| `Makefile.pre.in` | Modified | +3 / -0 | Adds zoneinfo to the list of standard library modules to install | — | — |
| `Misc/requirements-test.txt` | Added | +1 / -0 | Adds `tzdata` as a test dependency for CI environments without system time zone data | — | — |
| `Modules/Setup` | Modified | +1 / -0 | Registers `_zoneinfo` C extension in the module build configuration | — | — |
| `PCbuild/_zoneinfo.vcxproj` | Added | +109 / -0 | Visual Studio project file for building the `_zoneinfo` C extension on Windows | — | — |
| `PCbuild/_zoneinfo.vcxproj.filters` | Added | +16 / -0 | Visual Studio project filter file for `_zoneinfo` | — | — |
| `PCbuild/lib.pyproj` | Modified | +8 / -0 | Adds zoneinfo Python files to the Visual Studio Python project | — | — |
| `PCbuild/pcbuild.proj` | Modified | +1 / -1 | Includes `_zoneinfo` in the PCbuild project build order | — | — |
| `PCbuild/pcbuild.sln` | Modified | +2 / -0 | Adds `_zoneinfo` project to the Visual Studio solution | — | — |
| `PCbuild/readme.txt` | Modified | +1 / -0 | Documents the new `_zoneinfo` project in the PCbuild readme | — | — |
| `Tools/msi/lib/lib_files.wxs` | Modified | +1 / -1 | Adds zoneinfo to the MSI installer file list for Windows distribution | — | — |
| `setup.py` | Modified | +14 / -0 | Adds `_zoneinfo` C extension to the distutils/setuptools build configuration | — | — |

---

## Section 7: Behavior during data updates
*Path: Proposal > The `zoneinfo.ZoneInfo` class > Behavior during data updates*
*Classification: Implementable*

> It is important that a given `ZoneInfo` object's behavior not change during
> its lifetime, because a `datetime`'s `utcoffset()` method is used in both
> its equality and hash calculations, and if the result were to change during the
> `datetime`'s lifetime, it could break the invariant for all hashable objects
> [#hashable_def]_ [#hashes_equality]_  that if `x == y`, it must also be true
> that `hash(x) == hash(y)` [c]_ .
>
> Considering both the preservation of `datetime`'s invariants and the
> primary constructor's contract to always return the same object when called
> with identical arguments, if a source of time zone data is updated during a run
> of the interpreter, it must not invalidate any caches or modify any
> existing `ZoneInfo` objects. Newly constructed `ZoneInfo` objects, however,
> should come from the updated data source.
>
> This means that the point at which the data source is updated for new
> invocations of the `ZoneInfo` constructor depends primarily on the semantics
> of the caching behavior. The only guaranteed way to get a `ZoneInfo` object
> from an updated data source is to induce a cache miss, either by bypassing the
> cache and using `ZoneInfo.no_cache` or by clearing the cache.
>
> > **Note:** The specified cache behavior does not require that the cache be lazily populated — it is consistent with the specification (though not recommended) to eagerly pre-populate the cache with time zones that have never been constructed.

#### Requirement Summary
This section specifies that an existing `ZoneInfo` object must not change behavior during its lifetime even if the underlying time zone data source is updated; only newly constructed `ZoneInfo` objects (induced via cache miss, `no_cache`, or `clear_cache`) should observe the updated data. The PR realises this by eagerly loading TZif data into the `ZoneInfo` instance at construction time in both `_zoneinfo.py` and `_zoneinfo.c`, so a constructed object is decoupled from later disk changes; updates are only picked up through new cache misses.

**File proportion:** 2/27 files mapped (7.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/zoneinfo/_zoneinfo.py` | Added | +755 / -0 | — | — |
| `Modules/_zoneinfo.c` | Added | +2695 / -0 | — | — |

The eager-load behavior in this section is implemented by the same constructor entry points (`ZoneInfo.__new__` / `_new_instance` / `_load_file` in the pure-Python file; `zoneinfo_new` / `zoneinfo_new_instance` / `zoneinfo_from_file` / `zoneinfo_no_cache` / `load_data` in the C accelerator) that Section 6 (Constructors) lists. To satisfy the (file, class, function) tuple uniqueness rule (Check 28), those scopes are attributed once under Section 5; the cells here remain `—` so the constructor scopes are not double-counted.

#### Modification Summary
- **`Lib/zoneinfo/_zoneinfo.py`**: Reads transition data eagerly in `ZoneInfo.__new__` / `ZoneInfo._new_instance` / `ZoneInfo._load_file` so a constructed `ZoneInfo` snapshot is immutable for the rest of its lifetime; later changes on disk are only observed through new cache misses driven by the primary constructor cache, `no_cache`, or `clear_cache`. The concrete `ZoneInfo` class scope is listed under Section 5.
- **`Modules/_zoneinfo.c`**: Implements the equivalent eager file-load and immutability semantics in the C accelerator's constructor path (`zoneinfo_new`, `zoneinfo_new_instance`, `zoneinfo_from_file`, `zoneinfo_no_cache`, `load_data`), ensuring cached `ZoneInfo` instances do not change behavior when the on-disk database is updated mid-process. Those constructor/load function scopes are listed under Section 6 (Constructors) to avoid duplicate attribution.

---

## Section 8: Deliberate cache invalidation
*Path: Proposal > The `zoneinfo.ZoneInfo` class > Deliberate cache invalidation*
*Classification: Implementable*

> In addition to `ZoneInfo.no_cache`, which allows a user to *bypass* the
> cache, `ZoneInfo` also exposes a `clear_cache` method to deliberately
> invalidate either the entire cache or selective portions of the cache:
>
> ```
> ZoneInfo.clear_cache(*, only_keys: Iterable[str]=None) -> None
> ```
> If no arguments are passed, all caches are invalidated and the first call for
> each key to the primary `ZoneInfo` constructor after the cache has been
> cleared will return a new instance.
>
> ```
> >>> NYC0 = ZoneInfo("America/New_York")
> >>> NYC0 is ZoneInfo("America/New_York")
> True
> >>> ZoneInfo.clear_cache()
> >>> NYC1 = ZoneInfo("America/New_York")
> >>> NYC0 is NYC1
> False
> >>> NYC1 is ZoneInfo("America/New_York")
> True
> ```
> An optional parameter, `only_keys`, takes an iterable of keys to clear from
> the cache, otherwise leaving the cache intact.
>
> ```
> >>> NYC0 = ZoneInfo("America/New_York")
> >>> LA0 = ZoneInfo("America/Los_Angeles")
> >>> ZoneInfo.clear_cache(only_keys=["America/New_York"])
> >>> NYC1 = ZoneInfo("America/New_York")
> >>> LA0 = ZoneInfo("America/Los_Angeles")
> >>> NYC0 is NYC1
> False
> >>> LA0 is LA1
> True
> ```
> Manipulation of the cache behavior is expected to be a niche use case; this
> function is primarily provided to facilitate testing, and to allow users with
> unusual requirements to tune the cache invalidation behavior to their needs.

#### Requirement Summary
This section specifies the `ZoneInfo.clear_cache()` class method for deliberate cache invalidation, with an optional `only_keys` parameter to selectively clear specific entries. The PR implements this as a method on the `ZoneInfo` class in both the pure-Python `_zoneinfo.py` and the C accelerator `_zoneinfo.c`.

**File proportion:** 2/27 files mapped (7.4%) + 1/27 files associated (3.7%) = 3/27 accounted (11.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/zoneinfo/_zoneinfo.py` | Added | +755 / -0 | — | — |
| `Modules/_zoneinfo.c` | Added | +2695 / -0 | — | `zoneinfo_clear_cache`, `clear_strong_cache`, `remove_from_strong_cache`, `eject_from_strong_cache` |

The pure-Python `_zoneinfo.py` implements `clear_cache` as a method on the `ZoneInfo` class. The class-level `ZoneInfo` scope from the extended cache is attributed once under Section 6 (Constructors) per Check 28; the row here therefore leaves the Classes/Functions cells as `—` to avoid duplicate attribution, while the requirement summary and modification bullet document the specific method.

#### Modification Summary
- **`Lib/zoneinfo/_zoneinfo.py`**: Implements `ZoneInfo.clear_cache(*, only_keys=None)` which invalidates the `WeakValueDictionary`-based instance cache, either clearing all entries or only those matching the specified keys. The `ZoneInfo` class scope is listed under Section 5.
- **`Modules/_zoneinfo.c`**: Implements the C equivalent of `clear_cache` via `zoneinfo_clear_cache` plus the strong-cache invalidation helpers (`clear_strong_cache`, `remove_from_strong_cache`, `eject_from_strong_cache`) used by `only_keys`-selective clearing.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_zoneinfo/test_zoneinfo.py` | Added | +1994 / -0 | Validates `clear_cache` and `only_keys` selective cache invalidation behavior | — | — |

---

## Section 9: String representation
*Path: Proposal > The `zoneinfo.ZoneInfo` class > String representation*
*Classification: Implementable*

> The `ZoneInfo` class's `__str__` representation will be drawn from the
> `key` parameter. This is partially because the `key` represents a
> human-readable "name" of the string, but also because it is a useful parameter
> that users will want exposed. It is necessary to provide a mechanism to expose
> the key for serialization between languages and because it is also a primary
> key for localization projects like CLDR (the Unicode Common Locale Data
> Repository [#cldr]_).
>
> An example:
>
> ```
> >>> zone = ZoneInfo("Pacific/Kwajalein")
> >>> str(zone)
> 'Pacific/Kwajalein'
>
> >>> dt = datetime(2020, 4, 1, 3, 15, tzinfo=zone)
> >>> f"{dt.isoformat()} [{dt.tzinfo}]"
> '2020-04-01T03:15:00+12:00 [Pacific/Kwajalein]'
> ```
> When a `key` is not specified, the `str` operation should not fail, but
> should return the objects's `__repr__`:
>
> ```
> >>> zone = ZoneInfo.from_file(f)
> >>> str(zone)
> 'ZoneInfo.from_file(<_io.BytesIO object at ...>)'
> ```
> The `__repr__` for a `ZoneInfo` is implementation-defined and not
> necessarily stable between versions, but it must not be a valid `ZoneInfo`
> key, to avoid confusion between a key-derived `ZoneInfo` with a valid
> `__str__` and a file-derived `ZoneInfo` which has fallen through to the
> `__repr__`.
>
> Since the use of `str()` to access the key provides no easy way to check
> for the *presence* of a key (the only way is to try constructing a `ZoneInfo`
> from it and detect whether it raises an exception), `ZoneInfo` objects will
> also expose a read-only `key` attribute, which will be `None` in the event
> that no key was supplied.

#### Requirement Summary
This section specifies the `ZoneInfo` class's `__str__` and `__repr__` behavior (returning the key or a fallback representation) and the read-only `key` attribute. The PR implements these in both `_zoneinfo.py` (Python) and `_zoneinfo.c` (C accelerator).

**File proportion:** 2/27 files mapped (7.4%) + 1/27 files associated (3.7%) = 3/27 accounted (11.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/zoneinfo/_zoneinfo.py` | Added | +755 / -0 | — | — |
| `Modules/_zoneinfo.c` | Added | +2695 / -0 | — | `zoneinfo_str`, `zoneinfo_repr` |

The pure-Python `_zoneinfo.py` implements `__str__`/`__repr__`/`key` on the `ZoneInfo` class. The class-level `ZoneInfo` scope from the extended cache is attributed once under Section 6 (Constructors) per Check 28; the row here therefore leaves the Classes/Functions cells as `—` to avoid duplicate attribution.

#### Modification Summary
- **`Lib/zoneinfo/_zoneinfo.py`**: Implements `ZoneInfo.__str__` to return the `key` (or fall through to `__repr__` when no key is set), `ZoneInfo.__repr__` to return an implementation-defined non-key string, and the read-only `key` property attribute. The `ZoneInfo` class scope is listed under Section 5.
- **`Modules/_zoneinfo.c`**: Implements the C equivalents `zoneinfo_str` (`tp_str`) and `zoneinfo_repr` (`tp_repr`) plus the `key` member descriptor on the `ZoneInfo` type.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_zoneinfo/test_zoneinfo.py` | Added | +1994 / -0 | Validates `ZoneInfo.__str__`, `__repr__`, and `key` attribute behavior | — | — |

---

## Section 10: Pickle serialization
*Path: Proposal > The `zoneinfo.ZoneInfo` class > Pickle serialization*
*Classification: Implementable*

> Rather than serializing all transition data, `ZoneInfo` objects will be
> serialized by key, and `ZoneInfo` objects constructed from raw files (even
> those with a value for `key` specified) cannot be pickled.
>
> The behavior of a `ZoneInfo` object depends on how it was constructed:
>
> 1. `ZoneInfo(key)`: When constructed with the primary constructor, a
>    `ZoneInfo` object will be serialized by key, and when deserialized the
>    will use the primary constructor in the deserializing process, and thus be
>    expected to be the same object as other references to the same time zone.
>    For example, if `europe_berlin_pkl` is a string containing a pickle
>    constructed from `ZoneInfo("Europe/Berlin")`, one would expect the
>    following behavior:
>
>    ```
>    >>> a = ZoneInfo("Europe/Berlin")
>    >>> b = pickle.loads(europe_berlin_pkl)
>    >>> a is b
>    True
>    ```
>
> 2. `ZoneInfo.no_cache(key)`: When constructed from the cache-bypassing
>    constructor, the `ZoneInfo` object will still be serialized by key, but
>    when deserialized, it will use the cache bypassing constructor. If
>    `europe_berlin_pkl_nc` is a string containing a pickle constructed from
>    `ZoneInfo.no_cache("Europe/Berlin")`, one would expect the following
>    behavior:
>
>    ```
>    >>> a = ZoneInfo("Europe/Berlin")
>    >>> b = pickle.loads(europe_berlin_pkl_nc)
>    >>> a is b
>    False
>    ```
>
> 3. `ZoneInfo.from_file(fobj, /, key=None)`: When constructed from a file, the
>    `ZoneInfo` object will raise an exception on pickling. If an end user
>    wants to pickle a `ZoneInfo` constructed from a file, it is recommended
>    that they use a wrapper type or a custom serialization function: either
>    serializing by key or storing the contents of the file object and
>    serializing that.
>
> This method of serialization requires that the time zone data for the required
> key be available on both the serializing and deserializing side, similar to the
> way that references to classes and functions are expected to exist in both the
> serializing and deserializing environments. It also means that no guarantees
> are made about the consistency of results when unpickling a `ZoneInfo`
> pickled in an environment with a different version of the time zone data.

#### Requirement Summary
This section specifies pickle serialization behavior for `ZoneInfo` objects: key-constructed objects serialize by key and deserialize via the primary constructor, `no_cache`-constructed objects serialize by key but deserialize via the cache-bypassing constructor, and `from_file`-constructed objects raise an exception on pickling. The PR implements this via `__reduce__` in both `_zoneinfo.py` and `_zoneinfo.c`.

**File proportion:** 2/27 files mapped (7.4%) + 1/27 files associated (3.7%) = 3/27 accounted (11.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/zoneinfo/_zoneinfo.py` | Added | +755 / -0 | — | — |
| `Modules/_zoneinfo.c` | Added | +2695 / -0 | — | `zoneinfo_reduce`, `zoneinfo__unpickle` |

The pure-Python `_zoneinfo.py` implements `__reduce__`/`_unpickle`/`_file_reduce` on the `ZoneInfo` class. The class-level `ZoneInfo` scope from the extended cache is attributed once under Section 6 (Constructors) per Check 28; the row here therefore leaves the Classes/Functions cells as `—` to avoid duplicate attribution.

#### Modification Summary
- **`Lib/zoneinfo/_zoneinfo.py`**: Implements `ZoneInfo.__reduce__` to return a tuple that uses either the primary `ZoneInfo` constructor or `ZoneInfo.no_cache` for deserialization (via `ZoneInfo._unpickle`) depending on how the object was constructed; `ZoneInfo._file_reduce` raises `TypeError` for file-constructed instances. The `ZoneInfo` class scope is listed under Section 5.
- **`Modules/_zoneinfo.c`**: Implements the C equivalents `zoneinfo_reduce` (the `__reduce__` protocol) and `zoneinfo__unpickle` (the corresponding constructor used during deserialization), with the same constructor-dependent serialization logic as the Python version.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_zoneinfo/test_zoneinfo.py` | Added | +1994 / -0 | Validates pickle round-trip behavior across key/no_cache/from_file constructors | — | — |

---

## Section 12: System time zone information
*Path: Proposal > Sources for time zone data > System time zone information*
*Classification: Implementable*

> Many Unix-like systems deploy time zone data by default, or provide a canonical
> time zone data package (often called `tzdata`, as it is on Arch Linux, Fedora,
> and Debian).  Whenever possible, it would be preferable to defer to the system
> time zone information, because this allows time zone information for all
> language stacks to be updated and maintained in one place.  Python distributors
> are encouraged to ensure that time zone data is installed alongside Python
> whenever possible (e.g. by declaring `tzdata` as a dependency for the
> `python` package).
>
> The `zoneinfo` module will use a "search path" strategy analogous to the
> `PATH` environment variable  or the `sys.path` variable in Python; the
> `zoneinfo.TZPATH` variable will be read-only (see search-path-config_ for
> more details), ordered list of time zone data locations to search.  When
> creating a `ZoneInfo` instance from a key, the zone file will be constructed
> from the first data source on the path in which the key exists, so for example,
> if `TZPATH` were:
>
> ```
> TZPATH = (
>     "/usr/share/zoneinfo",
>     "/etc/zoneinfo"
>     )
> ```
> and (although this would be very unusual) `/usr/share/zoneinfo` contained
> only `America/New_York` and `/etc/zoneinfo` contained both
> `America/New_York` and `Europe/Moscow`, then
> `ZoneInfo("America/New_York")` would be satisfied by
> `/usr/share/zoneinfo/America/New_York`, while `ZoneInfo("Europe/Moscow")`
> would be satisfied by `/etc/zoneinfo/Europe/Moscow`.
>
> At the moment, on Windows systems, the search path will default to empty,
> because Windows does not officially ship a copy of the time zone database.  On
> non-Windows systems, the search path will default to a list of the most
> commonly observed search paths.  Although this is subject to change in future
> versions, at launch the default search path will be:
>
> ```
> TZPATH = (
>     "/usr/share/zoneinfo",
>     "/usr/lib/zoneinfo",
>     "/usr/share/lib/zoneinfo",
>     "/etc/zoneinfo",
> )
> ```
> This may be configured both at compile time or at runtime; more information on
> configuration options at search-path-config_.

#### Requirement Summary
This section specifies the TZPATH search path strategy for locating system time zone data, including the ordered search semantics and default paths for Unix and Windows systems. The PR implements this in `_tzpath.py`, which defines the `TZPATH` variable, the default search paths, and the logic to find zone files by iterating the path.

**File proportion:** 1/27 files mapped (3.7%) + 1/27 files associated (3.7%) = 2/27 accounted (7.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/zoneinfo/_tzpath.py` | Added | +110 / -0 | `InvalidTZPathWarning` | `_get_invalid_paths_message`, `_parse_python_tzpath`, `_validate_tzfile_path`, `find_tzfile`, `reset_tzpath` |

#### Modification Summary
- **`Lib/zoneinfo/_tzpath.py`**: Implements the `TZPATH` variable with platform-dependent defaults (common Unix paths on non-Windows, empty on Windows) and the `find_tzfile` function that searches `TZPATH` for zone files. Falls through to the `tzdata` package when no system data is found.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_zoneinfo/test_zoneinfo.py` | Added | +1994 / -0 | Validates `TZPATH` search-path semantics and system zone file lookup | — | — |

---

## Section 13: The `tzdata` Python package
*Path: Proposal > Sources for time zone data > The `tzdata` Python package*
*Classification: Implementable*

> In order to ensure easy access to time zone data for all end users, this PEP
> proposes to create a data-only package `tzdata` as a fallback for when system
> data is not available.  The `tzdata` package would be distributed on PyPI as
> a "first party" package [d]_, maintained by the CPython development team.
>
> The `tzdata` package contains only data and metadata, with no public-facing
> functions or classes.  It will be designed to be compatible with both newer
> `importlib.resources` [#importlib_resources]_ access patterns and older
> access patterns like `pkgutil.get_data` [#pkgutil_data]_ .
>
> While it is designed explicitly for the use of CPython, the `tzdata` package
> is intended as a public package in its own right, and it may be used as an
> "official" source of time zone data for third party Python packages.

#### Requirement Summary
This section specifies the first-party `tzdata` PyPI package as a fallback time-zone-data source for environments lacking system data, accessible via both `importlib.resources` and older `pkgutil.get_data` patterns. The PR consumes this fallback in `_common.load_tzdata`, which dynamically imports `tzdata.zoneinfo.<key>` and reads the resource bytes when system-path lookup fails.

**File proportion:** 1/27 files mapped (3.7%) + 2/27 files associated (7.4%) = 3/27 accounted (11.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/zoneinfo/_common.py` | Added | +166 / -0 | — | — |

#### Modification Summary
- **`Lib/zoneinfo/_common.py`**: Implements the `tzdata` package fallback through the module-level `load_tzdata` function, which imports `tzdata.zoneinfo.<components>` and uses `importlib.resources` (with a `pkgutil.get_data` style fallback) to return the bytes of the requested zone file when no system TZif file is found.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_zoneinfo/test_zoneinfo.py` | Added | +1994 / -0 | Validates the `tzdata` fallback path when system zone data is missing | — | — |
| `Misc/requirements-test.txt` | Added | +1 / -0 | Declares `tzdata` as a test dependency so the fallback path can be exercised in CI | — | — |

---

## Section 15: Compile-time options
*Path: Proposal > Search path configuration > Compile-time options*
*Classification: Implementable*

> It is most likely that downstream distributors will know exactly where their
> system time zone data is deployed, and so a compile-time option
> `PYTHONTZPATH` will be provided to set the default search path.
>
> The `PYTHONTZPATH` option should be a string delimited by `os.pathsep`,
> listing possible locations for the time zone data to be deployed (e.g.
> `/usr/share/zoneinfo`).

#### Requirement Summary
This section specifies a compile-time option `PYTHONTZPATH` to set the default time zone search path. The PR implements this via autoconf macros in `configure.ac` (and the generated `configure` script) that define `TZPATH` as a configurable build option.

**File proportion:** 2/27 files mapped (7.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `configure` | Modified | +46 / -0 | — | — |
| `configure.ac` | Modified | +36 / -0 | — | — |

#### Modification Summary
- **`configure`**: Generated autoconf output that adds the `--with-tzpath` option, defaulting to the standard Unix paths (`/usr/share/zoneinfo` etc.), and defines `TZPATH` as a C preprocessor macro available at compile time.
- **`configure.ac`**: Adds the `AC_ARG_WITH([tzpath], ...)` autoconf macro that provides the `--with-tzpath` configure flag, allowing distributors to specify the default `TZPATH` at build time.

---

## Section 16: Environment variables
*Path: Proposal > Search path configuration > Environment variables*
*Classification: Implementable*

> When initializing `TZPATH` (and whenever `reset_tzpath` is called with no
> arguments), the `zoneinfo` module will use the environment variable
> `PYTHONTZPATH`, if it exists, to set the search path.
>
> `PYTHONTZPATH` is an `os.pathsep`-delimited string which *replaces* (rather
> than augments) the default time zone path. Some examples of the proposed
> semantics:
>
> ```console
> $ python print_tzpath.py
> ("/usr/share/zoneinfo",
>  "/usr/lib/zoneinfo",
>  "/usr/share/lib/zoneinfo",
>  "/etc/zoneinfo")
>
> $ PYTHONTZPATH="/etc/zoneinfo:/usr/share/zoneinfo" python print_tzpath.py
> ("/etc/zoneinfo",
>  "/usr/share/zoneinfo")
>
> $ PYTHONTZPATH="" python print_tzpath.py
> ()
> ```
> This provides no built-in mechanism for prepending or appending to the default
> search path, as these use cases are likely to be somewhat more niche. It should
> be possible to populate an environment variable with the default search path
> fairly easily:
>
> ```console
> $ export DEFAULT_TZPATH=$(python -c \
>     "import os, zoneinfo; print(os.pathsep.join(zoneinfo.TZPATH))")
> ```

#### Requirement Summary
This section specifies the `PYTHONTZPATH` environment variable that replaces the default search path at module initialization. The PR implements this in `_tzpath.py`, which reads `os.environ.get("PYTHONTZPATH")` during initialization and in `reset_tzpath()`, splitting the value by `os.pathsep` and filtering for absolute paths.

**File proportion:** 1/27 files mapped (3.7%) + 1/27 files associated (3.7%) = 2/27 accounted (7.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/zoneinfo/_tzpath.py` | Added | +110 / -0 | — | — |

#### Modification Summary
- **`Lib/zoneinfo/_tzpath.py`**: Reads the `PYTHONTZPATH` environment variable at module load time and in `reset_tzpath()`, splitting it by `os.pathsep` to produce a tuple of absolute paths that replaces the compile-time default `TZPATH`. An empty string results in an empty search path, and non-absolute paths are filtered out.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_zoneinfo/test_zoneinfo.py` | Added | +1994 / -0 | Validates `PYTHONTZPATH` env-var parsing and replacement semantics | — | — |

---

## Section 17: `reset_tzpath` function
*Path: Proposal > Search path configuration > `reset_tzpath` function*
*Classification: Implementable*

> `zoneinfo` provides a `reset_tzpath` function that allows for changing the
> search path at runtime.
>
> ```
> def reset_tzpath(
>     to: Optional[Sequence[Union[str, os.PathLike]]] = None
> ) -> None:
>     ...
> ```
> When called with a sequence of paths, this function sets `zoneinfo.TZPATH` to
> a tuple constructed from the desired value.  When called with no arguments or
> `None`, this function resets `zoneinfo.TZPATH` to the default
> configuration.
>
> This is likely to be primarily useful for (permanently or temporarily)
> disabling the use of system time zone paths and forcing the module to use the
> `tzdata` package.  It is not likely that `reset_tzpath` will be a common
> operation, save perhaps in test functions sensitive to time zone configuration,
> but it seems preferable to provide an official mechanism for changing this
> rather than allowing a proliferation of hacks around the immutability of
> `TZPATH`.
>
> > **Caution:** Although changing `TZPATH` during a run is a supported operation, users should be advised that doing so may occasionally lead to unusual semantics, and when making design trade-offs greater weight will be afforded to using a static `TZPATH`, which is the much more common use case.
> As noted in Constructors_, the primary `ZoneInfo` constructor employs a cache
> to ensure that two identically-constructed `ZoneInfo` objects always compare
> as identical (i.e. `ZoneInfo(key) is ZoneInfo(key)`), and the nature of this
> cache is implementation-defined.  This means that the behavior of the
> `ZoneInfo` constructor may be unpredictably inconsistent in some situations
> when used with the same `key` under different values of `TZPATH`. For
> example:
>
> ```
> >>> reset_tzpath(to=["/my/custom/tzdb"])
> >>> a = ZoneInfo("My/Custom/Zone")
> >>> reset_tzpath()
> >>> b = ZoneInfo("My/Custom/Zone")
> >>> del a
> >>> del b
> >>> c = ZoneInfo("My/Custom/Zone")
> ```
> In this example, `My/Custom/Zone` exists only in the `/my/custom/tzdb` and
> not on the default search path.  In all implementations the constructor for
> `a` must succeed.  It is implementation-defined whether the constructor for
> `b` succeeds, but if it does, it must be true that `a is b`, because both
> `a` and `b` are references to the same key. It is also
> implementation-defined whether the constructor for `c` succeeds.
> Implementations of `zoneinfo` *may* return the object constructed in previous
> constructor calls, or they may fail with an exception.

#### Requirement Summary
This section specifies the `reset_tzpath(to=None)` function that allows runtime modification of `TZPATH`. The PR implements this in `_tzpath.py` (which defines the function) and exposes it via `__init__.py`.

**File proportion:** 2/27 files mapped (7.4%) + 1/27 files associated (3.7%) = 3/27 accounted (11.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/zoneinfo/__init__.py` | Added | +29 / -0 | — | — |
| `Lib/zoneinfo/_tzpath.py` | Added | +110 / -0 | — | — |

#### Modification Summary
- **`Lib/zoneinfo/__init__.py`**: Imports and re-exports `reset_tzpath` from `_tzpath`, making it available as `zoneinfo.reset_tzpath()`.
- **`Lib/zoneinfo/_tzpath.py`**: Implements `reset_tzpath(to=None)` via the module-level `reset_tzpath` function, which updates the module-level `TZPATH` variable: when called with a sequence, it converts each element to a string and filters for absolute paths; when called with `None`, it re-reads the `PYTHONTZPATH` environment variable (or falls back to compile-time defaults).

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_zoneinfo/test_zoneinfo.py` | Added | +1994 / -0 | Validates runtime `reset_tzpath()` behavior with explicit paths and `None` reset | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None
