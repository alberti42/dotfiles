;;; wrap.el --- Soft and hard wrap helpers -*- lexical-binding: t; -*-

;; Packages
(use-package visual-fill-column
  :defer t)

(use-package adaptive-wrap
  :defer t)

(defun emacs-config-soft-wrap-enable (&optional width)
  "Enable visual soft wrapping in the current buffer.

WIDTH, when non-nil, is the target wrap column (defaults to `fill-column').
Disables hard wrapping (`auto-fill-mode') if it is active."
  (interactive "P")
  (auto-fill-mode -1)
  (require 'visual-fill-column)
  (let ((width (if width (prefix-numeric-value width) fill-column)))
    (visual-line-mode 1)
    (setq-local word-wrap t)
    (setq-local truncate-lines nil)
    (setq-local visual-fill-column-width width)
    (visual-fill-column-mode 1)))

(defun emacs-config-soft-wrap-disable ()
  "Disable visual soft wrapping in the current buffer."
  (interactive)
  (when (fboundp 'visual-fill-column-mode)
    (visual-fill-column-mode -1))
  (visual-line-mode -1)
  (dolist (var '(word-wrap truncate-lines visual-fill-column-width))
    (when (local-variable-p var)
      (kill-local-variable var))))

(defun emacs-config-soft-wrap-toggle (&optional width)
  "Toggle visual soft wrapping in the current buffer.

If enabling, WIDTH is passed to `emacs-config-soft-wrap-enable'."
  (interactive "P")
  (if (bound-and-true-p visual-fill-column-mode)
      (emacs-config-soft-wrap-disable)
    (emacs-config-soft-wrap-enable width)))

;;; Hard wrap (auto-fill-mode) — uses fill-column as the wrap column.

(defun emacs-config-hard-wrap-enable ()
  "Enable hard wrapping (auto-fill-mode) in the current buffer.

Disables soft wrapping if it is active.  The wrap column is `fill-column'."
  (interactive)
  (emacs-config-soft-wrap-disable)
  (auto-fill-mode 1))

(defun emacs-config-hard-wrap-disable ()
  "Disable hard wrapping (auto-fill-mode) in the current buffer."
  (interactive)
  (auto-fill-mode -1))

(defun emacs-config-hard-wrap-toggle ()
  "Toggle hard wrapping (auto-fill-mode) in the current buffer."
  (interactive)
  (if auto-fill-function
      (emacs-config-hard-wrap-disable)
    (emacs-config-hard-wrap-enable)))

(provide 'wrap)
;;; wrap.el ends here
