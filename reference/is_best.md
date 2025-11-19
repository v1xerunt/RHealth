# Check if Score is Best

Compares current score with best score using criterion (max or min).

## Usage

``` r
is_best(best_score, score, monitor_criterion)
```

## Arguments

- best_score:

  Numeric. Current best score.

- score:

  Numeric. New score to compare.

- monitor_criterion:

  Character. Either "max" or "min".

## Value

Logical. TRUE if the new score is better.
