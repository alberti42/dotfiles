;;; styles.el --- Completion styles defaults -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; This module configures completion styles (matching) shared by minibuffer and
;; in-buffer completion. Orderless, if enabled, further adjusts these settings.
;;

;;; Code:

(use-package emacs
  :straight nil
  :init
  ;; Baseline styles; Orderless (if loaded) will override `completion-styles`.
  (setq completion-styles '(basic partial-completion))
  ;; Keep file completion path-friendly.
  (setq completion-category-defaults nil)
  (setq completion-category-overrides
        '((file (styles basic partial-completion)))))

(provide 'completions-styles)
;;; styles.el ends here
