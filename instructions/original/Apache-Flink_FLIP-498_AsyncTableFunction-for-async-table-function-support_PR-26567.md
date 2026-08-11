> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

---

# FLIP-498: AsyncTableFunction for async table function support

_Document the state by adding a label to the FLIP page with one of "discussion", "accepted", "released", "rejected"._
  
# Motivation

In order to handle table UDF calls efficiently, including ones which may call external systems, an asynchronous approach can be used. For example, there is `AsyncScalarFunction` ([FLIP](<https://cwiki.apache.org/confluence/display/FLINK/FLIP-400%3A+AsyncScalarFunction+for+asynchronous+scalar+function+support>)) which can be used to do a transformation on a scalar value, with multiple in-flight at a time, allowing results to be returned when completed.

This FLIP aims for exactly the same approach, but for Table Functions – in effect returns multiple results rather than a single one. In fact, such a class already exists: `AsyncTableFunction`. It’s used for Lookup joins, but isn’t exposed properly to the end user as other UDF types. This aims to expose it in just the same way as `AsyncScalarFunction`.

This seems to be effectively the same as [FLIP-313](<https://cwiki.apache.org/confluence/display/FLINK/FLIP-313%3A+Add+support+of+User+Defined+AsyncTableFunction>).

## Scope

The goal is to allow `AsyncTableFunction` to be used in the same place as normal `TableFunction`s. Namely:

  * Correlate Query (e.g. `SELECT * FROM t1, LATERAL TABLE(func(f1))`)

Changelog modes will be passed through, similar to how async scalar functions behave. The implementation referenced in this FLIP will be limited to the following:

  * Ordered Async operators: Some SQL queries could be compatible with an operator which allowed unordered results, which could provide a performance benefit. For now we'll only consider an operator that retains the input ordering.

  * Streaming mode: Some of the design considerations we're considering are focused on streaming. To get good performance on batch, it's possible we might want to allow batching of async calls, but we're not addressing this at the moment.

Public Interfaces

The API is unchanged from how `AsyncTableFunction`s are defined for lookup joins with a couple small exceptions. Lookup joins support inferring the input and output types based on `LookupCallContext` and so a generic `Row` can be used without specifying what it contains. This FLIP won’t cover those cases, but the more straightforward ones where both arguments and output types are well specified, as with a conventional `TableFunction`. For example:

  * An explicit hint with a `Row` type, as here for the output:

  * For output, a single field of any non-`Row` type can be used and it will be implicitly wrapped in a `Row` :  

New configurations will be introduced for the functionality, identical in nature to `table.exec.async-scalar.*` :  

Specifically, the following new configurations will be added:  

**Name (Prefix** _**table.exec.async-table**_)| **Meaning**  
---|---  
max-concurrent-operations| The number of outstanding requests the operator allows at once  
timeout| The total time which can pass before the invocation (including retries) is considered timed out and task execution is failed  
retry-strategy| FIXED_DELAY is for a retry after a fixed amount of time  
retry-delay| The time to wait between retries for the FIXED_DELAY strategy. Could be the base delay time for a (not yet proposed) exponential backoff.  
max-retries| The maximum number of attempts while retrying.  
  
Note: the async-table option keys are `max-concurrent-operations` and `max-retries`, which differ from the async-scalar keys `buffer-capacity` and `max-attempts`.  
  
# Proposed Changes

## Planner Changes

### Split Rules

One of the guiding philosophies to simplify code generation is to allow only a single call (the main async one) at a time at the given operator. To do this, we would like to split out any other calls to their own calcs.

There is an existing rule `PythonCorrelateSplitRule` which is useful for splitting things out from corrolates to their own calc. This should be factored out to be reusable as `RemoteCorrelateSplitRule`, taking a `RemoteCalcCallFinder`, which can be passed an instance looking for async table function calls.

Example SQL:

**Original RelNode**| **Becomes**  
---|---  
`FlinkLogicalCorrelate:`  
` left: FlinkLogicalCalc: projections: f0`  
` right: FlinkLogicalTableFunctionScan `  
` call: asyncTable(scalarFunction($cor0.f0))`| `FlinkLogicalCorrelate:`  
` left: FlinkLogicalCalc: projections: f1, scalarFunction(f1) as f0`  
` right: FlinkLogicalTableFunctionScan`  
` call: asyncTable($1)`  
  
### Physical Rules

There will also need to be a `StreamPhysicalAsyncCorrelateRule`, which converts `FlinkLogicalCorrelate`s to `StreamPhysicalAsyncCorrelate`s. This will check for the existence of any async table function calls in the correlate call to determine whether to do that conversion.

## Runtime Changes

### Code Generation

The primary change is to extends `DelegatingResultFuture`, which currently handles just lookup joins, to handle wrapping the result in a `Row` if appropriate since we now handle implicit row wrapping. Beyond that, the call to `FunctionCodeGenerator.generateFunction` will ask for a `AsyncFunction`, similar to async calcs.

### Operator

Since the call to the `AsyncTableFunction` is wrapped in a `AsyncFunction` taking input rows, we have the benefit of using the existing `AsyncWaitOperator`, which handles ordering, checkpointing, timeouts and other implementation details. Since only ordered results are handled in this scope, `ORDERED` will be the behavior.

# Compatibility, Deprecation, and Migration Plan

This should work with all of the existing Lookup Join cases, so there should be no issues – It’s utilizing the same interface, but shouldn’t change existing behavior.

New uses for correlate query calls are newly supported, and require no backwards compatibility.

# Rejected Alternatives

Look up joins:

  * \+ Code already exists

  * \- These are close, though support different queries that what are currently supported by `TableFunction`s, namely correlate queries.

  * \- They don’t have full UDF support in the table API. E.g.

` tEnv.createTemporarySystemFunction("func", new MyTableFunction());  tEng.executeSql(...);`

## Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support

### Motivation

A common UDF type is the _ScalarFunction_. This works well for CPU-intensive operations, but less well for IO bound or otherwise long-running computations. One example of this is remote calls to external systems where networking, serialization, and database lookups might dominate the execution time. _StreamTask_ has a single thread serially executing operators and their contained calls, which happen synchronously in the remote call case. Since each call can take, say, 1 second or more, that limits throughput and the overall performance, potentially accumulating backpressure to the upstream operator. The solution is to either: increase the parallelism of the query (resulting in a higher resource cost, overhead, etc.) or asynchronously fire off many requests concurrently and receive results as they complete. This FLIP aims to address the latter solution by introducing AsyncScalarFunction, a new UDF type which allows for issuing concurrent function calls.

### Scope

There are lots of combinations of modes and Job types in Flink such as the changelog mode and streaming vs batch. To make clear the scope this FLIP intends to cover, the functionality will be limited to the following:

  * Ordered Async operators: Much discussion has been centered around which changelog modes, SQL queries could be compatible with an operator which allowed unordered results, since there is a performance benefit. For now we'll only consider an operator that retains the input ordering.
  * Streaming mode: Some of the design considerations we're considering are focused on streaming. To get good performance on batch, it's possible we might want to allow batching of async calls, but we're not addressing this at the moment.

  
Public Interfaces

The primary public class is _AsyncScalarFunction_ , for being the base class of all async scalar functions.   
The type is parameterized with a return type for the eval call. This is similar to the definition of _AsyncTableFunction_.
    
    
    public class AsyncScalarFunction extends UserDefinedFunction {
        @Override
        public final FunctionKind getKind() {
            return FunctionKind.ASYNC_SCALAR;
        }
    
        @Override
        public TypeInference getTypeInference(DataTypeFactory typeFactory) {
            TypeInference val = TypeInferenceExtractor.forAsyncScalarFunction(typeFactory, getClass());
            return val;
        }
    }

  
An example implementing class could be the following:
    
    
    public class RemoteCallFunction extends AsyncScalarFunction {
    
        private ExternalClient client;
        private ExecutorService executor;
    
        public RemoteCallFunction() {
        }
    
        @Override
        public void open(FunctionContext context) throws Exception {
            client = new Client();
            executor = Executors.newFixedThreadPool(
                context.getJobParameter("in-flight-requests", 10));
        }
    
        @Override
        public void close() throws Exception {
            client.close();
            executor.shutdownNow();
        }
    
        public final void eval(
                CompletableFuture<String> future,
                String param1,
                int param2) {
            executor.submit(() -> {
                try {
                    String resp = client.rpc(param1, param2);
                    future.complete(resp);
                } catch (Throwable t) {
                    future.completeExceptionally(t);
                }
            });
        }
    }

As with the standard _ScalarFunction_ , there is an _eval_ method, but with a 0th parameter of the type _CompletableFuture <String>_ future. This is the primary method used to invoke the async functionality. The generic parameter of the future is used to infer the return type for the type system.

  
New configurations will be introduced for the functionality, similar in nature to `table.exec.async-lookup.*` :
    
    
    table.exec.async-scalar.buffer-capacity: 10
    table.exec.async-scalar.timeout: 30s
    table.exec.async-scalar.retry-strategy: FIXED_DELAY
    table.exec.async-scalar.fixed-delay: 10s
    table.exec.async-scalar.max-attempts: 3

  
These options ideally would be function scoped, but since `ConfigOption` doesn't make it easy to have a per-function config, they are global. Future work could allow these to be overridden on a per definition basis.

  
The following configurations will be available:

**Name (Prefix _table.exec.async-scalar_**)| **Meaning**  
---|---  
buffer-capacity| The number of outstanding requests the operator allows at once  
timeout| The total time which can pass before the invocation (including retries) is considered timed out and task execution is failed  
retry-strategy| FIXED_DELAY is for a retry after a fixed amount of time  
retry-delay| The time to wait between retries for the FIXED_DELAY strategy. Could be the base delay time for a (not yet proposed) exponential backoff.  
max-attempts| The maximum number of attempts while retrying.  
  
### Proposed Changes

#### Planner Changes

##### Split Rules

One of the areas that have been used as inspiration for planner changes are the python calc rules. Most of the split rules (rules for complex calc nodes being split into multiple simpler calc nodes) will be generalized and  
shared between the two, since remote python calls and async calls more generally share much of the same structure. If done correctly, the intention is to simplify the async operator to handle only FlinkLogicalCalcs   
which contain async UDF calls in projections and no other calc logic (non async calls, field accesses, conditions).   
  
The high level motivation is that anything that comes after an async call is easier to chain as a series of operators rather than internally within a single operator.

Specifically, _PythonCalcSplitRuleBase_ will be generalized into _RemoteCalcSplitRuleBase_. It will be parameterized with a _RemoteCalcCallFinder_ which can be used to analyze the _`RexNode`_ s to look for python or async calls.
    
    
    public interface RemoteCalcCallFinder {
        // This RexNode contains either directly or indirectly a remote call
        // of the specified type.
        boolean containsRemoteCall(RexNode node);
        // This RexNode contains either directly or indirectly a call which is not
        // the specified remote type.
        boolean containsNonRemoteCall(RexNode node);
        // This RexNode is a remote call of the specified type.
        boolean isRemoteCall(RexNode node);
        // This RexNode is a call that is not the specified type.
        boolean isNonRemoteCall(RexNode node);
    }

This will allow for _PythonCalcCallFinder_ and _AsyncCalcCallFinder_ implementations.  
  
The rules we intend to adopt split up a _FlinkLogicalCalc_ into two (or more ultimately) _FlinkLogicalCalc_ s which feed into one another. The async split rules shared with Python will be:

**Rule**| **Original RelNode**  
**(IX are inputs from previous operator)**| **Becomes (Bottom == > Top)**  
**(IX are inputs from previous operator)**  
---|---|---  
SPLIT_CONDITIONSplits FlinkLogicalCalcs which contain Remote functions in the condition into  
multiple FlinkLogicalCalcs with the function call in a projection of one and the  
condition checked in another using the result of the first.| 
    
    
    FlinkLogicalCalc
    Projections:
    Condition: func(...) AND I0

| 
    
    
    FlinkLogicalCalc
    Projections: I0 AS F0, func(...) AS F1
    Condition:

==>
    
    
    FlinkLogicalCalc
    Projections:
    Condition: F1 AND F0  
  
SPLIT_PROJECTSplits projections with async functions and non async  
into two FlinkLogicalCalcs| 
    
    
    FlinkLogicalCalc
    Projections: Concat(func(...), I1)
    Condition: 

  
| 
    
    
    FlinkLogicalCalc
    Projections: I1 AS F0, func(...) as F1
    Condition:

==>
    
    
    FlinkLogicalCalc
    Projections: Concat(F1, F0) 
    Condition:  
  
SPLIT_PROJECTION_REX_FIELDSplits field accesses from the result of an async call in projections   
into two FlinkLogicalCalcs| 
    
    
    FlinkLogicalCalc
    Projections:func(...).foobar
    Condition: 

| 
    
    
    FlinkLogicalCalc
    Projections: func(...) as F0
    Condition:

==>
    
    
    FlinkLogicalCalc
    Projections: F0.foobar
    Condition:  
  
SPLIT_CONDITION_REX_FIELDSplits field accesses from the result of an async call in condition  
into two FlinkLogicalCalcs| 
    
    
    FlinkLogicalCalc
    Projections:
    Condition: func(...).foobar

| 
    
    
    FlinkLogicalCalc
    Projections: 
    Condition: func(...)

==>
    
    
    FlinkLogicalCalc
    Projections: 
    Condition: I0.foobar  
  
EXPAND_PROJECTSplits field accesses as inputs to async calls into two FlinkLogicalCalcs.| 
    
    
    FlinkLogicalCalc
    Projections: func(I5.foobar)
    Condition: 

| 
    
    
    FlinkLogicalCalc
    Projections: I5.foobar as F0
    Condition:

==>
    
    
    FlinkLogicalCalc
    Projections: func(F0)
    Condition:   
  
PUSH_CONDITIONPushes conditions down to minimize rows requiring the async call,   
creating two FlinkLogicalCalcs| 
    
    
    FlinkLogicalCalc
    Projections: func(...)
    Condition: C1

  
| 
    
    
    FlinkLogicalCalc
    Projections: 
    Condition: C1

==>
    
    
    FlinkLogicalCalc
    Projections: func(...)
    Condition:  
  
**Async Specific** : NESTED_SPLITIf there is a call with an async call as an argument, then it needs to be split  
into two FlinkLogicalCalc with one feeding into the next.| 
    
    
    FlinkLogicalCalc
    Projections: func(func(...))
    Condition:

  
| 
    
    
    FlinkLogicalCalc
    Projections: func(...) as F0
    Condition:

==>
    
    
    FlinkLogicalCalc
    Projections: func(F0)
    Condition:  
  
**Async Specific** : ONE_ASYNC_PROJECTION_PER_CALCIf there are multiple projections containing async calls, it splits them into two  
FlinkLogicalCalc with one feeding into the next.| `FlinkLogicalCalc   
``Projections: func(...), func(...)  
``Condition:`| 
    
    
    FlinkLogicalCalc
    Projections: func(...) as F0
    Condition:

==>
    
    
    FlinkLogicalCalc
    Projections: F0, func(...)
    Condition:  
  
##### Physical Rules

In additional the split rules, there will also need to be a _PhysicalAsyncCalcRule_ which converts `_FlinkLogicalCalc_ s to _PhysicalAsyncCalcs._`This will check for the existence of any async calls in the calc, using the same AsyncCalcCallFinder logic above.

##### Disallowing Async functionality when not supported

It is most prudent to only allow async behavior where it is known to not violate SQL semantics. To do this, rules will be introduced which contain query structures which we don’t want to allow and if found, all of the async calls will be executed in synchronous mode.

This can be done by introducing a new trait _AsyncOperatorModeTrait_ , which comes in sync mode and async mode (default), and which will be attached to a _FlinkLogicalCalc_ if it contains async calls which we would prefer to execute in sync mode. Execution in synchronous mode just utilizes the same stack of as async, but waits on the result immediately after issuing the request.

An example of a query which could have unintended results without explicit handling:

  * Queries with ordering semantics:
    * e.g. **SELECT func(f1) FROM Table ORDER BY f2;**  
Here, we expect that the results of the query will be ordered by _f2_. We wouldn't want to return results in the completion order from async function _func_.   
We can solve it by either outputting in ORDERED, and ensuring that we return the results in the input order, or by putting it into synchronous mode and ensuring ordering by doing one at a time.
  * Others? Would be great to get feedback on other cases that should be considered.

For the first version of this functionality where the operator outputs only in ordered mode, synchronous mode may not need to be enabled.

#### Runtime Changes

##### Code Generation

Current code generation in Flink for _ScalarFunction s_ assume that one call can be synchronously fed into another and results can be set on the output record right after being issued.  
Neither of these will hold once we have async support. There are two phases for generated async code:

  * Call issuing phase

    * Same as a normal sync invocation w.r.t. to converting all of the parameters and calling the UDF, but with the result being returned with a `Future`.

  * Result collection phase

    * Must wait for all async calls issued and also convert result types, if appropriate.

    * Only once all results are ready can an output record be created and set.

    * Must happen with a callback on the `Future`s rather than synchronously.

  
Note that how the operator is going to invoke the generated code has to do with what planner rules are in effect above. If every Async Operator is guaranteed to have only parallel async calls and no other generated Java/sql operations, then the generated code can be simplified, leaving support for everything else to existing Flink operators. This is a similar approach to that taken by Python. With the last split rule above, the code can be simplified further by requiring only one async request per operator.

Since the code generator already supports generating _AsyncFunction s_ (currently used by lookup joins), this will be used with the main logic in _asyncInvoke_. The body of that method will use existing code generation to call the UDF and do the appropriate casting for the various arguments. Additional logic will capture the UDF result _Future_ , set a callback, convert results, and complete the output row _._

Utilizing a class _AsyncDelegatingResultFuture_ similar to the existing _DelegatingResultFuture_ (used for lookup joins), the generated method could look similar to the following:
    
    
    @Override
    public void asyncInvoke(RowData input, ResultFuture<RowData> resultFuture) throws Exception {
       // Invokes callbacks on resultFuture once the async call is complete.
       final AsyncDelegatingResultFuture delegatingFuture = AsyncDelegatingResultFuture(resultFuture);
    
       try {
           Function<Object, GenericRowData> outputFactory = new Function<Object, GenericRowData>() {
               @Override
               public GenericRowData apply(Object udfResult) {
    			   // Gather the results and return the output object
                   final GenericRowData out = new GenericRowData(2);
                   out.setField(0, delegatingFuture.getSynchronousResult(0));
                   out.setField(1, udfResult);
                   return out;
               }
           };
    
    	   // Once it sees that the async future is done, the factory will be used to get the resulting output row
           delegatingFuture.setOutputFactory(outputFactory);
    
           // If an input is needed in the next operator, pass it along
           int passThroughField = input.getInt(0);
           delegatingFuture.addSynchronousResult(passThroughField);
    
    	   // Create a new future object and invoke the UDF.
           // The result will be converted to the internal type before calling the output factory.
           CompletableFuture<?> udfResultFuture = delegatingFuture.createAsyncFuture(typeConverter);
           asyncScalarFunctionUdf.eval(udfResultFuture);
        } catch (Throwable e) {
          resultFuture.completeExceptionally(e);
        }
    }

##### Operator

Since the call to the _AsyncScalarFunction_ is wrapped in a _AsyncFunction_ taking input rows, we have the benefit of using the existing class _AsyncWaitOperator_ , which handles ordering, checkpointing, timeouts and other implementation details. Since only ordered results are handled in this scope, ORDERED will be the default behavior.

The `_PhysicalAsyncCalcs_` mentioned in the planning phase will translate to an exec node, which creates the transformation containing this operator.

  
Compatibility, Deprecation, and Migration Plan

This is only introducing new code paths, namely the use of AsyncScalarFunction, so there should be no compatibility issues with existing jobs/SQL queries.

### Rejected Alternatives

#### AsyncTableFunction using a lookup Join

This requires you to model the lookups as a [join with a table](<https://nightlies.apache.org/flink/flink-docs-release-1.17/docs/dev/table/sql/queries/joins/#lookup-join>). For example:
    
    
    create TEMPORARY TABLE RemoteTable(table_lookup_key string, resp string,
        PRIMARY KEY (table_lookup_key) NOT ENFORCED) with ('connector' = 'remote_call');
    SELECT i.table_lookup_key, resp FROM Inputs as i JOIN RemoteTable r FOR SYSTEM_TIME
        AS OF i.proc_time as a ON i.table_lookup_key = r.table_lookup_key;

  * \+ Already implemented

  * \+ High performance

  * \+ Good for modeling external databases with a table interface

  * \- Can’t easily invoke the lookup multiple times per joining row

  * \- Requires _proc_time_ time attribute, which may be unnecessary or not already exist on a pre defined table

  * \- Unintuitive compared to a scalar function

#### Polymorphic table function

This already exists in some capacity in Flink with [window functions](<https://nightlies.apache.org/flink/flink-docs-master/docs/dev/table/sql/queries/window-tvf/>).   
This would allow you to effectively specify a number of input keys for some remote call and issue calls at a high volume. For example:
    
    
    SELECT * FROM TABLE (REMOTE_CALL (Input => Table(TableToLookup) as d,
        Col => DESCRIPTOR("table_lookup_key")));

  * \+ More intuitive than a lookup join

  * \- No support for user defined functions with PTFs.

*Source: https://cwiki.apache.org/confluence/display/FLINK/FLIP-400%3A+AsyncScalarFunction+for+asynchronous+scalar+function+support*

## Linked FLIP-313 — Add support of User Defined AsyncTableFunction

### Motivation

Currently, async table function are special functions for table source to perform async lookup. However, it's worth to support the user defined async table function. In this way, the end SQL user can leverage it to perform the async operation which is useful to maximum the system throughput especially for IO bottleneck case. 

Take a job perform RPC call (IO intensive) as an example.

##### Perform async operation with lookup join 

Let's see how we can perform an async RPC call with lookup join:

(1) Implement an AsyncTableFunction with RPC call logic. 

(2) Implement a `LookupTableSource` connector run with the async udtf defined in (1).

(3) Then define a DDL of this look up table in SQL
    
    
    CREATE TEMPORARY TABLE Customers (
      id INT,
      name STRING,
      country STRING,
      zip STRING
    ) WITH (
      'connector' = 'custom'
    );

(4) Run with the query as below:
    
    
    SELECT o.order_id, o.total, c.country, c.zip
    FROM Orders AS o
      JOIN Customers FOR SYSTEM_TIME AS OF o.proc_time AS c
        ON o.customer_id = c.id;

This example is from [doc](<https://nightlies.apache.org/flink/flink-docs-release-1.17/docs/dev/table/sql/queries/joins/#lookup-join>).You can image the look up process as an async RPC call process.

##### Perform async operation by join table function

Let's see how we can perform an async RPC call by join table function:

(1) Implement an AsyncTableFunction with RPC call logic.   
  
(2) Run query with 
    
    
    CREATE FUNCTION f1 AS '...' ;
    
    SELECT o.order_id, o.total, c.country, c.zip FROM Orders, lateral table (f1(order_id)) as T(...);

  
As you can see, join with table function version is more simple and intuitive to users. Users do not have to wrap a LookupTableSource for the purpose of using async table function, and not forced to join on an equality join condition. Also, User-defined asynchronous table functions allow complex parameters (e.g., Row type) to be passed to function rather than using 'join … on ...'.

### Public Interfaces

#### AsyncTableFunction

We already have AsyncTableFunction as below, it will be extension for the user to implement the custom async table function.
    
    
    @PublicEvolving
    public abstract class AsyncTableFunction<T> extends UserDefinedFunction {
    
        @Override
        public final FunctionKind getKind() {
            return FunctionKind.ASYNC_TABLE;
        }
    
        @Override
        @SuppressWarnings({"unchecked", "rawtypes"})
        public TypeInference getTypeInference(DataTypeFactory typeFactory) {
            return TypeInferenceExtractor.forAsyncTableFunction(typeFactory, (Class) getClass());
        }
    }

A example async table function.
    
    
        public static class JavaAsyncTableFunc0 extends AsyncTableFunction<Row> {
    
            private ExecutorService executor;
    
            @Override
            public void open(FunctionContext context) throws Exception {
                super.open(context);
                this.executor = Executors.newSingleThreadExecutor();
            }
    
            @DataTypeHint(value = "ROW<c0 VARCHAR, c1 VARCHAR>")
            public void eval(CompletableFuture<Collection<Row>> resultFuture, String input) {
                CompletableFuture.supplyAsync(
                                () -> {
                                    if (!input.contains(";")) {
                                        return Collections.EMPTY_LIST;
                                    } else {
                                        String[] splits = input.split(";");
                                        List<Row> res = new ArrayList<>();
                                        for (int i = 0; i <= splits.length - 1; i += 2) {
                                            if (i + 1 > splits.length - 1) {
                                                res.add(Row.of(splits[i], null));
                                            } else {
                                                res.add(Row.of(splits[i], splits[i + 1]));
                                            }
                                        }
                                        return res;
                                    }
                                },
                                executor)
                        .thenAccept(resultFuture::complete);
            }
    
            @Override
            public void close() throws Exception {
                super.close();
                if (executor != null) {
                    executor.shutdown();
                }
            }
         }

  
The SQL syntax is same with the current lateral table to describe the async correlate
    
    
    # inner join 
    
    SELECT a, c1, c2
    FROM T1, lateral TABLE (async_split(b)) AS T(c1, c2)
    
    # left join 
    SELECT a, c1, c2
    FROM T1
    LEFT JOIN lateral TABLE (async_split(b)) AS T(c1, c2) ON true

#### ConfigOption

##### Hint

Similar to the lookup join's hint config option, async join with table function will also support hint options to config the async operator buffer capacity, timeout and order. (see some rejected alternatives in the end)

option name| required| value type| default value| description  
---|---|---|---|---  
function| N| string| null| If specified, then the option below will applied to the target function, and other's will use the default. If not set, all the function in a single SELECT clause will all use the default option below.  
output-mode| N| string| ordered| value can be 'ordered' or 'allow_unordered'.  
'allow_unordered' means if users allow unordered result, it will attempt to use AsyncDataStream.OutputMode.UNORDERED when it does not affect the correctness of the result, otherwise ORDERED will be still used.  
capacity| N| integer| 100| the buffer capacity for the backend asyncWaitOperator of the async operator.  
timeout| N| duration| 300s| timeout from first invoke to final completion of asynchronous operation, will be reset in case of failover  
  
  
    ASYNC_TABLE_FUNC('output-mode' = 'ordered', 'capacity' = '200', 'timeout' = '180s')

  
    SELECT /*+ ASYNC_TABLE_FUNC('output-mode' = 'ordered', 'capacity' = '200', 'timeout' = '180s') */ a, c1, c2
    FROM T1
    LEFT JOIN LATERAL TABLE (async_split(b)) AS T(c1, c2) ON true

  
    SELECT /*+ ASYNC_TABLE_FUNC('output-mode' = 'ordered', 'capacity' = '200', 'timeout' = '180s'), ASYNC_TABLE_FUNC('function' = 'async_split2', 'output-mode' = 'allow_unordered', 'capacity' = '100', 'timeout' = '60s') */ a, c1, c2
    FROM T1
    LEFT JOIN LATERAL TABLE (async_split(b)) AS T(c1, c2) ON true
    JOIN LATERAL TABLE(async_split2(b)) AS T2(c3, c4) ON TRUE

In this query, the `async_split` will run with option `'output-mode' = 'ordered', 'capacity' = '200', 'timeout' = '180s'` and the `async_split2` will run with option `'output-mode' = 'allow_unordered', 'capacity' = '100', 'timeout' = '60s'` . We use the `function` to distinguish different table function call in the SELECT clause. The default global option can also be used by omitting the `function` option.

  
### Proposed Changes

As shown above, we will use lateral table syntax to support the async table function. So the planner will also treat this statement to a `CommonExecCorrelate` node. So the runtime code should be generated in `CorrelatedCodeGenerator` . In CorrelatedCodeGenerator, we will know the TableFunction's Kind of `FunctionKind.Table` or `FunctionKind.ASYNC_TABLE` .

For `FunctionKind.ASYNC_TABLE` type we can generate a AsyncWaitOperator to execute the async table function. It can leverage most facility in `org.apache.flink.table.planner.plan.nodes.exec.common.CommonExecLookupJoin#createAsyncLookupJoin` to generate an async correlate node.

### Performance

sync version

async version

In the testing, the evaluation is a blocking call which will cost 100ms in average, and the sync correlate and async correlate are all execute in 1 parallelism. The async function is implemented in a async fashion with a thread pool of 2 threads.

The async version's tps is significant double of the sync version. 

  
### Compatibility, Deprecation, and Migration Plan

  * A new user defined function is introduced no compatibility problem

### Rejected Alternatives

##### Job level config
    
    
    public static final ConfigOption<Integer> TABLE_EXEC_ASYNC_CORRELATE_BUFFER_CAPACITY =
            key("table.exec.async-udtf.buffer-capacity")
                    .intType()
                    .defaultValue(100)
                    .withDescription(
                            "The max number of async i/o operation that the async lateral join can trigger.");
    
    public static final ConfigOption<Duration> TABLE_EXEC_CORRELATE_TIMEOUT =
            key("table.exec.async-udtf.timeout")
                    .durationType()
                    .defaultValue(Duration.ofMinutes(3))
                    .withDescription(
                            "The async timeout for the asynchronous operation to complete.");
    
    public static final ConfigOption<AsyncOutputMode> TABLE_EXEC_ASYNC_CORRELATE_OUTPUT_MODE =
            key("table.exec.async-udtf.output-mode")
                    .enumType(AsyncOutputMode.class)
                    .defaultValue(AsyncOutputMode.ORDERED)
                    .withDescription(
                            "Output mode for asynchronous operations which will convert to {@see AsyncDataStream.OutputMode}, ORDERED by default. "
                                    + "If set to ALLOW_UNORDERED, will attempt to use {@see AsyncDataStream.OutputMode.UNORDERED} when it does not "
                                    + "affect the correctness of the result, otherwise ORDERED will be still used.");

These config options are the counterpart of the lookup join eg: `table.exec.async-lookup.buffer-capacity. `But using hints is more flexible and can avoid introduce too much similar options, so I abandon this choice.

*Source: https://cwiki.apache.org/confluence/display/FLINK/FLIP-313%3A+Add+support+of+User+Defined+AsyncTableFunction*
