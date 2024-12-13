;;; p4-ts-mode.el --- Major mode for the P4_16 programming language  -*- lexical-binding: t; -*-

;; Copyright (C) 2024- Oxide Computer
;; Author: Zeeshan Lakhani <zeeshan@oxidecomputer.com>
;;
;; Maintainer: Zeeshan Lakhani <zeeshan@oxidecomputer.com>
;; Created: 04 December 2024
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1
;; Keywords: languages p4_16 p4
;; Homepage: https://github.com/oxidecomputer/p4-ts-mode

;; This file is NOT part of GNU Emacs.

;; This program is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;; Provides syntax highlighting and indentation for the P4 (P4_16-specification)
;; domain-specific programming language.
;;
;; P4: https://p4.org/
;; P4_16-specification: https://p4.org/p4-spec/docs/P4-16-v1.2.0-spec.html

;; Inspiration comes from the gleam tree-sitter implementation
;; (https://github.com/gleam-lang/gleam-mode/blob/main/gleam-ts-mode.el)
;; and the tree-sitter-p4 grammar (https://github.com/oxidecomputer/tree-sitter-p4)

;;; Code:

(require 'prog-mode)
(require 'treesit)
;; Imenu support
(require 'imenu)
;; Cscope Support
(require 'xcscope)

;;; Customization

(defgroup p4-ts nil
  "Major mode for editing P4_16."
  :prefix "p4-ts-"
  :group 'languages)

(defcustom p4-ts-indent-offset 4
  "Indentation offset for `p4-ts-mode'."
  :type 'integer
  :safe 'integerp
  :group 'p4-ts)

;; Tree-sitter font-locking

(defvar p4-ts--font-lock-settings
  (treesit-font-lock-rules

   :feature 'keyword
   :language 'p4
   '([
      "header"
      "struct"
      "typedef"
      "extern"
      "parser"
      "state"
      "if"
      "else"
      "transition"
      "select"
      "apply"
      "control"
      "package"
      "action"
      "table"
      "key"
      "size"
      "range"
      "lpm"
      "exact"
      "ternary"
      "optional"
      "actions"
      "default"
      "default_action"
      "return"
      "NoAction"
      "const"
      "meters"
      "counters"
      "_"
      (direction)
      ] @font-lock-keyword-face)

   :feature 'comment
   :language 'p4
   '((comment) @font-lock-comment-face)

   :feature 'number
   :language 'p4
   '((number) @font-lock-number-face)

   :feature 'const-builtin
   :language 'p4
   '([
      "true"
      "false"
      (identifier_preproc)
      ] @font-lock-constant-face)

   :feature 'binop
   :language 'p4
   '((binop) @font-lock-operator-face)

   :feature 'preproc-keyword
   :language 'p4
   '(["#define"
      "#if"
      "#else"
      ;; we define #include as part of preproc below
      ] @font-lock-preprocessor-face)

   :feature 'type
   :language 'p4
   '(["bool"
      "error"
      "int"
      "bit"
      "tuple"
      "varbit"
      "packet_in"
      "packet_out"] @font-lock-type-face)

   :feature 'ext-type
   :language 'p4
   '([(bit_type)
      (varbit_type)
      (tuple_type)] @font-lock-type-face)

   :feature 'type-identifier
   :language 'p4
   '((type_identifier) @font-lock-type-face)

   :feature 'function-name
   :language 'p4
   '([(method_not_constant)
      (method_identifier)] @font-lock-function-name-face)

   :feature 'preproc
   :language 'p4
   '([(preproc)] @font-lock-preprocessor-face)

   :feature 'annotation
   :language 'p4
   '((annotation) @font-lock-builtin-face)))

(defvar p4-ts-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry  ?_  "w"      st)
    (modify-syntax-entry  ?/  ". 124b" st)
    (modify-syntax-entry  ?*  ". 23"   st)
    (modify-syntax-entry  ?\n  "> b"   st)
    st)
  "Syntax table for `p4-ts-mode'.")

(defvar p4-ts-map
  (let ((map (make-keymap)))
    (define-key map "\C-j" 'newline-and-indent)
    map)
  "Keymap for `p4-ts-mode'.")

;;; Indentation

(defun p4-ts-indent-rules ()
  "Indent current line for any balanced-paren-mode'."
  (let ((indent-col 0)
        (indentation-increasers "[{(]")
        (indentation-decreasers "[})]"))
    (save-excursion
      (beginning-of-line)
      (condition-case nil
          (while t
            (backward-up-list 1)
            (when (looking-at indentation-increasers)
              (setq indent-col (+ indent-col p4-ts-indent-offset))))
        (error nil)))
    (save-excursion
      (back-to-indentation)
      (when (and (looking-at indentation-decreasers)
                 (>= indent-col p4-ts-indent-offset))
        (setq indent-col (- indent-col p4-ts-indent-offset))))
    (indent-line-to indent-col)))

(defvar p4-ts-imenu-generic-expression
  '(
    ("Controls"      "^ *control +\\([A-Za-z0-9_]*\\)"      1)
    ("Externs"       "^ *extern +\\([A-Za-z0-9_]*\\) *\\([A-Za-z0-9_]*\\)" 2)
    ("Tables"        "^ *table +\\([A-Za-z0-9_]*\\)"        1)
    ("Actions"       "^ *action +\\([A-Za-z0-9_]*\\)"       1)
    ("Parsers"       "^ *parser +\\([A-Za-z0-9_]*\\)"       1)
    ("Parser States" "^ *state +\\([A-Za-z0-9_]*\\)"        1)
    ("Headers"       "^ *header +\\([A-Za-z0-9_]*\\)"       1)
    ("Header Unions" "^ *header_union +\\([A-Za-z0-9_]*\\)" 1)
    ("Structs"       "^ *struct +\\([A-Za-z0-9_]*\\)"       1))
  "Imenu generic expression for `p4-ts-mode'.")

(defun p4-ts-install-grammar ()
  "Install the Gleam tree-sitter grammar."
  (interactive)
  (if (and (treesit-available-p) (boundp 'treesit-language-source-alist))
      (let ((treesit-language-source-alist
             (cons
              '(p4 . ("https://github.com/oxidecomputer/tree-sitter-p4" "main" "src"))
              treesit-language-source-alist)))
        (treesit-install-language-grammar 'p4))
    (display-warning 'treesit "Emacs' treesit package does not appear to be available")))

(define-derived-mode p4-ts-mode prog-mode "P4"
  "Major mode for editing P4 with tree-sitter.
\\{p4-ts-map}"
  :group 'p4-ts
  :syntax-table p4-ts-syntax-table

  (cond
   ((treesit-ready-p 'p4)
    (treesit-parser-create 'p4)

    (setq-local treesit-font-lock-settings p4-ts--font-lock-settings)
    (setq-local treesit-font-lock-level 4)
    (setq-local treesit-font-lock-feature-list
                '((comment const-builtin binop)
                  (keyword preproc-keyword number type ext-type type-identifier)
                  (function-name)
                  (preproc annotation)))

    ;; cscope
    (cscope-minor-mode)

    ;; indent
    (setq-local treesit-simple-indent-rules 'p4-ts-indent-rules)

    ;; comments
    (setq-local comment-start "// ")
    (setq-local comment-end "")
    (setq-local comment-start-skip "//+\\s-*")

    ;; Multi-line comment support
    (setq-local comment-multi-line t)
    (setq-local comment-style 'multi-line)
    (setq-local block-comment-start "/* ")
    (setq-local block-comment-end " */")

    ;; imenu
    (setq-local treesit-simple-imenu-settings p4-ts-imenu-generic-expression)
    (treesit-major-mode-setup))
   (t
    (message
     "Cannot load tree-sitter-p4. Try running `p4-ts-install-grammar' and report a bug if the issue reoccurs"))))

(if (treesit-ready-p 'p4)
    (add-to-list 'auto-mode-alist
                 '("\\.p4\\'" . p4-ts-mode)))


(provide 'p4-ts-mode)

;;; Footer:

;;; p4-ts-mode.el ends here
