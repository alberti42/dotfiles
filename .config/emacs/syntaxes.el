;;; syntaxes.el --- Load per-syntax configuration files -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Loads every .el file found in the syntaxes/ subdirectory next to this file.
;; To add settings for a new language, drop a file in syntaxes/.
;;

;;; Code:

;; Global indentation defaults
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(setq-default standard-indent 2)

;; Indent/unindent region by tab-width (like Sublime's option-[ / option-])
(defun emacs-config-indent-left ()
  "Shift selected lines (or current line) left by `tab-width' columns."
  (interactive)
  (let ((beg (if (use-region-p) (region-beginning) (line-beginning-position)))
        (end (if (use-region-p) (region-end) (line-end-position))))
    (indent-rigidly beg end (- tab-width))
    (setq deactivate-mark nil)))

(defun emacs-config-indent-right ()
  "Shift selected lines (or current line) right by `tab-width' columns."
  (interactive)
  (let ((beg (if (use-region-p) (region-beginning) (line-beginning-position)))
        (end (if (use-region-p) (region-end) (line-end-position))))
    (indent-rigidly beg end tab-width)
    (setq deactivate-mark nil)))

(bind-key* "C-," #'emacs-config-indent-left)
(bind-key* "C-." #'emacs-config-indent-right)

;; Load all syntax files in the syntaxes/ subdirectory 
(let ((dir (expand-file-name "syntaxes" emacs-config-dir)))
  (when (file-directory-p dir)
    (dolist (file (directory-files dir t "\\.el\\'"))
      (load file nil 'nomessage))))

(provide 'syntaxes)

;;; syntaxes.el ends here
