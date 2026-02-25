;;; syntaxes/sh.el --- Shell script indentation -*- lexical-binding: t; -*-

(defvar emacs-config-syntaxes-enable-sh t
  "Whether to enable shell settings from syntaxes/sh.el.")

(when emacs-config-syntaxes-enable-sh
  (add-hook 'sh-mode-hook
            (lambda ()
              (setq sh-basic-offset 2)
              (setq indent-tabs-mode nil))))

(provide 'syntaxes-sh)

;;; syntaxes/sh.el ends here
