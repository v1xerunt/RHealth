# Helper function to create a clean closure for parallel processing

This function acts as a factory. It creates and returns another function
(a closure) that is suitable for use with `future.apply`. The returned
function's environment is intentionally minimal, containing only the
`task` object. This prevents large objects from the parent environment
(like the full event dataframe) from being accidentally exported to
parallel workers.

## Usage

``` r
.create_task_runner(task)
```

## Arguments

- task:

  The task object to be used inside the closure.

## Value

A function that takes a patient dataframe (`pdf`) and applies the task.
