# Tufte's principles, and what implements them

Returns the table this package is built around: each principle, the book
it comes from, the function that puts it into practice, whether
[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
can check it, and whether Tufte states a criterion a graphic either
meets or doesn't.

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
principles no function reaches.

## Details

The `criterion` column is the important one. Tufte gives a testable line
for some principles: bars are measured from zero, the lie factor lies
between 0.95 and 1.05, graphics are wider than they're tall. For others
he gives only a direction, asking that the data-ink ratio be maximised
"within reason" and that data density be increased, and names no
threshold. The audit grades the first kind and merely measures the
second, because any line drawn across the second kind would be the
package author's and not Tufte's.

Principles no function can reach are listed too, with `audited` set to
`FALSE`, because the honest version of "implements all of Tufte's
principles" says which ones it can't.

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
