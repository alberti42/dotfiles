;;; syntaxes/text.el --- Text wrapping -*- lexical-binding: t; -*-

(defvar emacs-config-syntaxes-enable-text t
  "Whether to enable text-mode settings from syntaxes/text.el.")

(when emacs-config-syntaxes-enable-text
  (add-hook 'text-mode-hook
            (lambda ()
              ;; Visual soft wrap at 100 columns.
              (setq-local fill-column 100)
              (emacs-config-soft-wrap-enable))))

(provide 'syntaxes-text)
;;; syntaxes/text.el ends here
