;;; orderless.el --- Orderless completion style -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Orderless allows space-separated patterns to match candidates in any order.
;; Great for "command palette" style completion.
;;

;;; Code:

(use-package orderless
  :init
  (setq completion-styles '(orderless basic))
  (setq completion-category-defaults nil)
  (setq completion-category-overrides
        '((file (styles basic partial-completion)))))

(provide 'completions-orderless)
;;; orderless.el ends here
