;;; minibuffer-icomplete.el --- Icomplete/Fido minibuffer UI -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Fallback minibuffer completion UI when Vertico is unavailable.
;;

;;; Code:

(use-package icomplete
  :straight nil
  :init
  (setq icomplete-show-matches-on-no-input t
        icomplete-compute-delay 0
        icomplete-delay-completions-threshold 0)
  (fido-vertical-mode 1))

(provide 'completions-minibuffer-icomplete)
;;; minibuffer-icomplete.el ends here
