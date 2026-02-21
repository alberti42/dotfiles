;;; lsp-core.el --- LSP core configuration -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Base LSP configuration used by language-specific modules.
;;

;;; Code:

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")
  ;; Suppress "no server installed" popups for file types like plist/XML.
  (setq lsp-warn-no-matched-clients nil)
  ;; Performance: increase the amount of data Emacs reads from subprocesses.
  ;; This helps with LSP servers that send larger JSON payloads.
  (setq read-process-output-max (* 1024 1024))
  (add-hook 'lsp-mode-hook #'lsp-enable-which-key-integration)
  :config
  ;; lsp-mode includes an icon shim (lsp-icons-get-by-file-ext). In setups
  ;; without an icon backend, it can effectively return nothing.
  (defconst lsp-icons--nerd-font-file-icon
    (let ((ch (decode-char 'ucs #xf15b)))
      (if ch (char-to-string ch) ""))
    "Single Nerd Font file icon glyph used for headerline breadcrumbs.")

  (defun lsp-icons-get-by-file-ext (_file-ext &optional _context)
    "Return an icon string for FILE-EXT.

This local shim returns a single Nerd Font file icon. If the glyph is not
displayable in the current frame, return an empty string."
    (if (and (> (length lsp-icons--nerd-font-file-icon) 0)
             (char-displayable-p (aref lsp-icons--nerd-font-file-icon 0)))
        lsp-icons--nerd-font-file-icon
      ""))

  (with-eval-after-load 'lsp-headerline
    (defun emacs-config-lsp-headerline--indent-prefix ()
      "Return a headerline prefix aligned to the buffer text.

This accounts for line-number margin width (via `header-line-indent-width') and
for `git-gutter-mode' reserving columns inside the buffer text area in TTY."
      (let* ((line-numbers-width
              (if (bound-and-true-p header-line-indent-mode)
                  (or (and (boundp 'header-line-indent-width)
                           header-line-indent-width)
                      0)
                0))
             (git-gutter-width
              (if (and (bound-and-true-p git-gutter-mode)
                       (boundp 'git-gutter:window-width))
                  git-gutter:window-width
                0))
             (px (+ line-numbers-width git-gutter-width)))
        (make-string (max 0 (if (integerp px) px 0)) ?\s)))

    (defconst emacs-config-lsp-headerline--breadcrumb-format-with-indent
      '(t (:eval
           (concat
            (emacs-config-lsp-headerline--indent-prefix)
            (or (window-parameter nil 'lsp-headerline--string) ""))))
      "Header-line-format element for lsp breadcrumbs aligned to buffer text.")

    (defun emacs-config-lsp-headerline--fixup-breadcrumb-headerline (&rest _)
      "Align lsp breadcrumb headerline with display-line-numbers.

When `lsp-headerline-breadcrumb-mode' is enabled, replace lsp-mode's default
headerline element with an indented variant and enable
`header-line-indent-mode' when available."
      (let ((lsp-default '(t (:eval (window-parameter nil 'lsp-headerline--string)))))
        (cond
         ((bound-and-true-p lsp-headerline-breadcrumb-mode)
          (when (fboundp 'header-line-indent-mode)
            (header-line-indent-mode 1))
          (when (listp header-line-format)
            (setq header-line-format (remove lsp-default header-line-format))
            (add-to-list 'header-line-format
                         emacs-config-lsp-headerline--breadcrumb-format-with-indent)))
         (t
          (when (fboundp 'header-line-indent-mode)
            (header-line-indent-mode -1))
          (when (listp header-line-format)
            (setq header-line-format
                  (remove emacs-config-lsp-headerline--breadcrumb-format-with-indent
                          header-line-format)))))))

    (advice-add 'lsp-headerline-breadcrumb-mode :after
                #'emacs-config-lsp-headerline--fixup-breadcrumb-headerline)

    ;; lsp-mode's upstream implementation always inserts a space after the icon
    ;; even when the icon shim returns an empty string.
    (defun lsp-headerline--build-file-string ()
      "Build the file-segment string for the breadcrumb.

This local override only inserts the icon and following space when the icon is
non-empty."
      (let* ((file-path (or (buffer-file-name) ""))
             (filename (f-filename file-path)))
        (if-let* ((file-ext (f-ext file-path)))
            (let ((icon (lsp-icons-get-by-file-ext file-ext 'headerline-breadcrumb)))
              (concat
               (when (and (stringp icon)
                          (> (length icon) 0)
                          (not (string-match-p "\\`[[:space:]]*\\'" icon)))
                 (concat icon " "))
               (propertize filename
                           'font-lock-face
                           (lsp-headerline--face-for-path file-path))))
          filename)))
    ))
(use-package lsp-ui
  :after lsp-mode
  :commands lsp-ui-mode
  :init
  (add-hook 'lsp-mode-hook #'lsp-ui-mode)
  (setq lsp-ui-doc-position 'at-point))

(provide 'lsp-core)

;;; lsp-core.el ends here
