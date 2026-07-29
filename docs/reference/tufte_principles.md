# Tufte's principles, and what implements them

Returns the table this package is built around: each principle, the book
it comes from, the function or functions that put it into practice, and
whether
[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
can check it automatically. Principles that no function can check are
listed too, with `audited` set to `FALSE`, because the honest version of
"implements all of Tufte's principles" says which ones a package cannot
reach.

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
`implemented_by` and `audited`.

## Examples

``` r
tufte_principles()
#> # A tibble: 26 × 5
#>    principle                    source     statement      implemented_by audited
#>    <chr>                        <chr>      <chr>          <chr>          <lgl>  
#>  1 Above all else show the data VDQI ch. 4 The graphic e… theme_tufte()  TRUE   
#>  2 Maximise the data-ink ratio  VDQI ch. 4 A large share… data_ink_rati… TRUE   
#>  3 Erase non-data ink           VDQI ch. 4 Ink that does… theme_tufte()  TRUE   
#>  4 Erase redundant data-ink     VDQI ch. 4 Ink that repe… geom_col_tuft… TRUE   
#>  5 Revise and edit              VDQI ch. 4 Graphics are … check_labels_… TRUE   
#>  6 The range-frame              VDQI ch. 6 The frame sho… geom_rangefra… TRUE   
#>  7 The dot-dash plot            VDQI ch. 6 The axis can … geom_dotdash() FALSE  
#>  8 The lie factor               VDQI ch. 2 The effect sh… lie_factor()   TRUE   
#>  9 Graphical integrity          VDQI ch. 2 Bars measure … tufte_audit()  TRUE   
#> 10 Maximise data density        VDQI ch. 8 A graphic sho… data_density(… TRUE   
#> # ℹ 16 more rows
subset(tufte_principles(), !audited)$principle
#> [1] "The dot-dash plot"          "Shrink the graphic"        
#> [3] "Position beats length"      "Micro and macro readings"  
#> [5] "Show comparisons"           "Show causality"            
#> [7] "Show multivariate data"     "Sparklines"                
#> [9] "Content counts most of all"
```
