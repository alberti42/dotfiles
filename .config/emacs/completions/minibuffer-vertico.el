;;; minibuffer-vertico.el --- Vertico minibuffer UI -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Vertico provides a modern minibuffer completion UI.
;;

;;; Code:

(use-package vertico
  :init
  (setq vertico-cycle t)
  (vertico-mode 1))

(provide 'completions-minibuffer-vertico)
;;; minibuffer-vertico.el ends here
