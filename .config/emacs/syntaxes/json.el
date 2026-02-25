;;; syntaxes/json.el --- JSON indentation -*- lexical-binding: t; -*-

(defvar emacs-config-syntaxes-enable-json t
  "Whether to enable JSON settings from syntaxes/json.el.")

(when emacs-config-syntaxes-enable-json
  (dolist (hook '(js-json-mode-hook   ; built-in JSON mode from js.el (Emacs 29+)
                  json-mode-hook      ; json-mode package, if installed
                  json-ts-mode-hook)) ; tree-sitter JSON mode
    (add-hook hook
              (lambda ()
                (setq-local js-indent-level 2)           ; js-json-mode / json-mode
                (setq-local json-ts-mode-indent-offset 2) ; json-ts-mode
                (setq-local indent-tabs-mode nil)))))

(provide 'syntaxes-json)

;;; syntaxes/json.el ends here
