;;; dired-config.el --- Dired and file manager configuration -*- lexical-binding: t; -*-

;;; Code:

(use-package dired
  :straight nil
  :custom
  ;; reuse single dired buffer when navigating instead
  ;; of opening new buffer for each directory
  (dired-kill-when-opening-new-dired-buffer t)) 

;; dired-preview: automatic file preview in a side window as you navigate.
(use-package dired-preview
  :hook (dired-mode . dired-preview-mode)
  :custom
  (dired-preview-delay 0.005)
  (dired-preview-max-size (* 10 1024 1024))
  (dired-preview-ignored-extensions-regexp
    (concat "\\."
            (regexp-opt '("mkv" "mp4" "mp3" "ogg" "gz" "zst") t)
            "\\'"))
  :config
  ;; In TTY frames, skip image and PDF previews — they would render as binary garbage.
  (defun dired-config--tty-skip-unsupported (file)
    (and (not (display-graphic-p))
         (string-match-p
           (rx "." (or "jpg" "jpeg" "png" "gif" "svg" "webp" "bmp" "tif" "tiff" "pdf") string-end)
           (downcase file))))
  (advice-add 'dired-preview-display-file :before-until
              #'dired-config--tty-skip-unsupported))

;; dired-narrow: live-filter the dired listing as you type.
(use-package dired-narrow
  :after dired
  :bind (:map dired-mode-map
         ("/" . dired-narrow)))

(provide 'dired-config)
;;; dired-config.el ends here
