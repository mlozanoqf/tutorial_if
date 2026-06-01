# Option Pricing with R

This repository contains the source files for **Option Pricing with R**, a Quarto book by Dr. Martin Lozano. The book introduces core option-pricing ideas through reproducible R code, numerical examples, and graphics.

Published site: <https://mlozanoqf.github.io/tutorial_if/>

## Scope

The current version focuses on:

- Option payoffs and profit diagrams
- Option properties and put-call parity
- Binomial valuation
- Risk-neutral reasoning
- Black-Scholes intuition
- Wiener processes and their role in continuous-time models
- Foundations for future extensions, including Greeks

## Book Structure

- `index.qmd`: preface and publication metadata
- `01-payoff-functions.qmd`: payoff functions
- `02-options-properties.qmd`: option properties and valuation relationships
- `03-wiener-processes.qmd`: Wiener processes
- `references.qmd`: references

The book configuration lives in `_quarto.yml`.

## Repository Layout

- `R/`: helper scripts used during rendering
- `_freeze/`: cached execution results used by Quarto's `freeze: auto`
- `_book/`: generated HTML output created by `quarto render`
- `.github/workflows/publish.yml`: GitHub Actions workflow for rendering and deploying the book to GitHub Pages
- `styles.css` and `*.html` partials: custom navigation, layout, and page behavior
- `references.bib`: bibliography

## Render Locally

Install Quarto and R, then render the book from the repository root:

```bash
quarto render
```

For interactive local preview:

```bash
quarto preview
```

The GitHub Actions workflow installs the R packages needed for deployment. For local rendering, the main package set is:

- `dplyr`
- `ggplot2`
- `kableExtra`
- `knitr`
- `plotly`
- `rmarkdown`
- `tidyr`
- `vembedr`
- `xfun`

## Publication

Pushing to `main` triggers the GitHub Actions workflow. The workflow renders the Quarto book and deploys the `_book` artifact to GitHub Pages.

## Maintenance Notes

- Edit the source `.qmd` files, `_quarto.yml`, `styles.css`, or the HTML partials.
- Treat `_book/` as generated output.
- Because `freeze: auto` is enabled, Quarto reuses cached execution results when source chunks have not changed.
- After removing or renaming chapters, check `_quarto.yml`, `sidebar-chapter-sections.html`, `_freeze/`, and the rendered `_book/` output for stale references.

## License

This project is licensed under the GNU General Public License v3.0. See `LICENCE`.
