;;; completion.el --- Minibuffer completion UI -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Show completion candidates immediately in the minibuffer.
;; This makes prompts like `lsp-execute-code-action` feel less "TAB-driven".
;;

;;; Code:

;; Make `M-x' context-aware by default.
;;
;; Emacs can filter the set of commands shown by `execute-extended-command'
;; based on whether they apply in the current context (major mode, minibuffer,
;; active completion UIs, etc.). This improves signal-to-noise in `M-x' and also
;; hides internal/transient commands from packages like Corfu, which are not
;; meant to be called directly.
;;
;; If you ever miss a command in `M-x', this is the knob to revisit.
(use-package emacs
  :straight nil
  :init
  (setq read-extended-command-predicate #'command-completion-default-include-p))

(use-package icomplete
  :straight nil
  :init
  (setq icomplete-show-matches-on-no-input t
        icomplete-compute-delay 0
        icomplete-delay-completions-threshold 0)
  (fido-vertical-mode 1))

(provide 'completion)

;;; completion.el ends here
