# Tufte's principles, and what implements them

Look up each principle, its source, and the functions that implement it.
The table also records whether
[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
can check it.

## Usage

``` r
tufte_principles(audited_only = FALSE)
```

## Arguments

- audited_only:

  Logical. Return only the principles the audit can check? Defaults to
  `FALSE`.

## Value

A tibble with columns `principle`, `source`, `statement`,
`implemented_by`, `audited` and `criterion`. `implemented_by` is a
comma-separated list of functions in this package, or `NA` for the
principles no function reaches. `audited` and `criterion` are both
logical: `audited` says whether any function reports on the principle,
and `criterion` whether Tufte states a threshold, so that `criterion` is
the column that separates what the audit grades from what it only
measures.

## Details

The `criterion` column identifies principles with a stated rule, such as
a zero baseline for bars or a lie factor between 0.95 and 1.05. Tufte
asks that data-ink be maximised "within reason" and that data density
increase, but doesn't give them numerical targets. The audit reports
those measurements without grading them.

Principles the package can't check are included with `audited = FALSE`.
I've kept them in the table so the limits of the audit are visible.

## Examples

``` r
tufte_principles()
#> # A tibble: 26 × 6
#>    principle                   source statement implemented_by audited criterion
#>    <chr>                       <chr>  <chr>     <chr>          <lgl>   <lgl>    
#>  1 Above all else show the da… VDQI … The grap… theme_tufte()  FALSE   FALSE    
#>  2 Maximise the data-ink ratio VDQI … A large … data_ink_rati… TRUE    FALSE    
#>  3 Erase non-data ink          VDQI … Ink that… theme_tufte()  TRUE    TRUE     
#>  4 Erase redundant data-ink    VDQI … Ink that… geom_col_tuft… TRUE    TRUE     
#>  5 Revise and edit             VDQI … Graphics… check_labels_… TRUE    TRUE     
#>  6 The range-frame             VDQI … The fram… geom_rangefra… TRUE    TRUE     
#>  7 The dot-dash plot           VDQI … The axis… geom_dotdash() FALSE   FALSE    
#>  8 The lie factor              VDQI … The effe… lie_factor()   TRUE    TRUE     
#>  9 Graphical integrity         VDQI … Bars mea… tufte_audit()  TRUE    TRUE     
#> 10 Maximise data density       VDQI … A graphi… data_density(… TRUE    FALSE    
#> # ℹ 16 more rows
# Principles Tufte states a testable criterion for:
subset(tufte_principles(), criterion)$principle
#>  [1] "Erase non-data ink"               "Erase redundant data-ink"        
#>  [3] "Revise and edit"                  "The range-frame"                 
#>  [5] "The lie factor"                   "Graphical integrity"             
#>  [7] "Proportion and scale"             "Legibility"                      
#>  [9] "Integrate word, number and image" "Documentation"                   
```
