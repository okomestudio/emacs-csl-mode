;;; csl-mode.el --- Major mode for CSL files  -*- lexical-binding: t; -*-

;;; Code:

(require 'nxml-mode)

;;;###autoload
(define-derived-mode csl-mode nxml-mode "CSL"
  "Major mode for editing Citation Style Language (CSL) files."
  ;; Custom settings for your derived mode go here:
  (setq-local tab-width 2))

(provide 'csl-mode)
;;; csl-mode.el ends here
