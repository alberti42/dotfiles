;;; syntaxes/markdown.el --- Markdown wrapping -*- lexical-binding: t; -*-

(defvar emacs-config-syntaxes-enable-markdown t
  "Whether to enable Markdown settings from syntaxes/markdown.el.")

(when emacs-config-syntaxes-enable-markdown
  (dolist (hook '(markdown-mode-hook gfm-mode-hook))
    (add-hook hook
              (lambda ()
                ;; Visual soft wrap at 100 columns.
                (setq-local fill-column 100)
                (emacs-config-soft-wrap-enable)
                (require 'adaptive-wrap)
                (adaptive-wrap-prefix-mode 1)))))

(provide 'syntaxes-markdown)
;;; syntaxes/markdown.el ends here
