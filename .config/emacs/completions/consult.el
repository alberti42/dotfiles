;;; consult.el --- Consult commands and integrations -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Consult provides a set of high-quality narrowing commands that work well
;; with Vertico (or other completing-read UIs).
;;

;;; Code:

(use-package consult
  :bind (
         ;; A small, mnemonic prefix for search/navigation.
         ("C-c s b" . consult-buffer)
         ("C-c s l" . consult-line)
         ("C-c s r" . consult-ripgrep)
         ("C-c s i" . consult-imenu)
         ("C-c s m" . consult-mark)
         ("C-c s k" . consult-keep-lines)
         ;; Replace project-find-file with fd-backed consult-fd.
         ("C-x p f" . consult-fd))
  :init
  ;; Use Consult for xref UI when available.
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  ;; Include hidden directories in fd search, but exclude .git.
  (setq consult-fd-args '("fd" "--hidden" "--exclude" ".git" "--color=never" "--full-path")))

(provide 'completions-consult)
;;; consult.el ends here
