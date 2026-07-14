;;; csl-mode.el --- Major mode for CSL files  -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 Taro Sato
;;
;; Author: Taro Sato <okomestudio@gmail.com>
;; Keywords: languages, wp
;; Version: 0.1.1
;; Package-Requires: ((emacs "30.1"))
;;
;; This file is NOT part of GNU Emacs.
;;
;;; Commentary:
;;
;; A major mode for editing Citation Style Language (CSL) files.
;;
;;; Code:

(require 'nxml-mode)

(defgroup csl nil
  "Customization group for `csl-mode', Citation Style Language (CSL) mode."
  :group 'languages
  :prefix "csl-")

(defcustom csl-indent-offset 2
  "Number of spaces for local indentation in CSL files."
  :type 'integer
  :safe #'integerp
  :group 'csl)

(defvar csl--tags-abbrev
  '(("choose" . "c")
    ("group" . "g")
    ("else-if" . "elif")
    ("macro" . "m")
    ("style" . "s")
    ("substitute" . "sub"))
  "Abbreviations for tags.")

(defvar csl--attrs-abbrev
  '(("delimiter" . "d")
    ("macro" . "m")
    ("name" . "n")
    ("prefix" . "pre")
    ("suffix" . "suf")
    ("value" . "val")
    ("variable" . "v"))
  "Abbreviations for attributes.")

(defun csl--tag-attrs (tag-name attrs)
  "Format ATTRS of TAG-NAME for display as string."
  (if-let*
      ((val
        (pcase tag-name
          ((or "if" "else-if")
           (let* ((beg 0)
                  (kv-re "\\([a-zA-Z0-9:._-]+\\)=\"\\([^\"]*\\)\"")
                  kvs)
             (while (string-match kv-re attrs beg)
               (let* ((k (match-string 1 attrs))
                      (k (or (alist-get k csl--attrs-abbrev nil nil #'equal)
                             k)))
                 (push (cons k (match-string 2 attrs)) kvs))
               (setq beg (match-end 0)))
             (mapconcat (lambda (it) (format "%s(%s)" (car it) (cdr it)))
                        (reverse kvs) " ")))
          (_
           (let* ((beg 0)
                  (valid-attrs '("delimiter" "id" "macro" "name" "prefix" "suffix" "type" "value" "variable"))
                  (kv-re (format "\\b\\(%s\\)=\"\\([^\"]*\\)\""
                                 (string-join valid-attrs "\\|")))
                  kvs)
             (while (string-match kv-re attrs beg)
               (let* ((k (match-string 1 attrs))
                      (k (or (alist-get k csl--attrs-abbrev nil nil #'equal)
                             k)))
                 (push (cons k (match-string 2 attrs)) kvs))
               (setq beg (match-end 0)))
             (when kvs
               (mapconcat (lambda (it) (format "%s(%s)" (car it) (cdr it)))
                          (reverse kvs) " ")))))))
      (format "%s[%s]"
              (or (alist-get tag-name csl--tags-abbrev nil nil #'equal)
                  tag-name)
              val)
    (or (alist-get tag-name csl--tags-abbrev nil nil #'equal)
        tag-name)))

(defun csl-imenu-index-builder ()
  "Imenu index builder for citation style language (CSL) in XML."
  (let* ((comment-re "<!--\\(\\(?:.\\|\n\\)*?\\)-->")
         (valid-tag-re "<\\(/\\)?\\([a-zA-Z0-9:._-]+\\)\\([^>]*\\)>")
         (tag-re (string-join (list comment-re valid-tag-re) "\\|"))
         (delim " ➤ ")
         index stack)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward tag-re nil t)
        (let* ((comment (match-string 1))
               (is-close (match-string 2))
               (tag-name (match-string 3))
               (attrs (match-string 4))
               (pos (match-beginning 0)))
          (cond
           (comment nil)      ; skip comments
           (is-close
            ;; Unwind stack safely to handle mismatched/malformed XML tags:
            (while (and stack (not (string= (caar stack) tag-name)))
              (pop stack))
            (pop stack))
           (t                 ; opening tag or self-closing tag
            (let* ((label (csl--tag-attrs tag-name attrs))
                   (parents (mapcar #'cdr (reverse stack)))
                   (path (string-join (append parents (list label)) delim)))
              (push (cons path pos) index)
              (unless (and attrs (string-suffix-p "/" attrs)) ; self-closing tag
                (push (cons tag-name label) stack))))))))
    (nreverse index)))

;;;###autoload
(define-derived-mode csl-mode nxml-mode "CSL"
  "Major mode for editing Citation Style Language (CSL) files."
  ;; Custom settings for your derived mode go here:
  (setq-local tab-width csl-indent-offset)

  (with-eval-after-load 'imenu
    (setq-local imenu-create-index-function #'csl-imenu-index-builder)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.csl\\'" . csl-mode))

(provide 'csl-mode)
;;; csl-mode.el ends here
