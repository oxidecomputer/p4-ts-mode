# p4-ts-mode: An Emacs Major Mode for P4 Using Tree-sitter

P4 (`P4_16`) mode for emacs using tree-sitter.

This mode uses [tree-sitter][tree-sitter], requiring Emacs 29+'s `treesit`
package for syntax highlighting and code navigation.

If you're running an Emacs that's older than 29 or a version compiled without
`treesit`, we'll eventually provide a fallback mode.

<!-- ![Screenshot](ss.png?raw=true "Screenshot") -->

## Installation

Currently this project is not yet on MELPA, but you can fetch and install it
directly through this repository, depending on your package manager/builder of
choice.

### quelpa

```elisp
(quelpa '(p4-ts-mode :repo "oxidecomputer/p4-ts-mode" :fetcher github))
```

### Doom Emacs

```elisp
(package! p4-ts-mode :recipe (:host github :repo "oxidecomputer/p4-ts-mode"))
```

### straight.el

```elisp
(straight-use-package
 '(p4-ts-mode :type git :host github :repo "oxidecomputer/p4-ts-mode"))
```

## Setup

Once installed, you can we recommend `use-package` to load the package
and setup any configuration.

```elisp
(use-package p4-ts-mode
  :mode (rx ".p4" eos)

;; If you're using Doom Emacs, you can add the following to your `config.el` file:
;; (use-package! p4-ts-mode)
```

## Tree-sitter Grammar

Unless you have the [P4 tree-sitter grammar][p4-grammar] installed and
`treesit` knows what path to find it, you'll want to run:

```
M-x p4-ts-install-grammar
```

This will download the grammar and compile it for you.

*Note*: This requires a `C` compiler to be installed on your system.

## Contributing

`p4-ts-mode` is still a work in progress.

To contribute, just open a pull request!

## Useful links

- How to get started with tree-sitter -
  [https://www.masteringemacs.org/article/how-to-get-started-tree-sitter](https://www.masteringemacs.org/article/how-to-get-started-tree-sitter)

- Tree-sitter and the Complications of Parsing Languages -
  [https://www.masteringemacs.org/article/tree-sitter-complications-of-parsing-languages](https://www.masteringemacs.org/article/tree-sitter-complications-of-parsing-languages)

- Let's write a tree-sitter major mode -
  [https://www.masteringemacs.org/article/lets-write-a-treesitter-major-mode](https://www.masteringemacs.org/article/lets-write-a-treesitter-major-mode)

- P4_16 Language Specification -
  [https://p4.org/p4-spec/docs/P4-16-v1.0.0-spec.html](https://p4.org/p4-spec/docs/P4-16-v1.0.0-spec.html)

- The de facto P4_16 mode for emacs -
  [https://github.com/p4lang/tutorials/blob/master/vm/p4_16-mode.el](https://github.com/p4lang/tutorials/blob/master/vm/p4_16-mode.el)


[tree-sitter]: https://tree-sitter.github.io/tree-sitter/
