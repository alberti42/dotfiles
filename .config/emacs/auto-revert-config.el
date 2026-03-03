;;; auto-revert-config.el -*- lexical-binding: t; tab-width: 2; -*-

;; Smart file watching: silently revert unmodified buffers when the file changes
;; on disk; prompt before reverting buffers that have unsaved local edits.

(require 'filenotify)

(defvar-local emacs-config--file-watcher nil
  "File notification watcher descriptor for the current buffer.")

(defun emacs-config--file-changed (event)
  "Handle a file change EVENT."
  (when (eq (nth 1 event) 'changed)
    (let* ((file (nth 2 event))
           (buf  (find-buffer-visiting file)))
      (when (buffer-live-p buf)
        (with-current-buffer buf
          ;; `verify-visited-file-modtime' returns t when Emacs already
          ;; knows about this mtime (e.g. right after a save by Emacs
          ;; itself).  Only act when the file genuinely changed externally.
          (unless (verify-visited-file-modtime buf)
            (if (buffer-modified-p)
                ;; Unsaved local edits — ask before discarding them.
                (when (yes-or-no-p
                       (format "File '%s' modified externally. Revert and lose your changes? "
                               (buffer-name)))
                  (revert-buffer t t t))
              ;; Clean buffer — silently sync to disk.
              (revert-buffer t t t))))))))

(defun emacs-config--setup-file-watcher ()
  "Attach a file-system watcher to the current buffer's file."
  (when (and buffer-file-name (file-exists-p buffer-file-name))
    (condition-case err
        (setq-local emacs-config--file-watcher
                    (file-notify-add-watch buffer-file-name
                                           '(change)
                                           #'emacs-config--file-changed))
      (error
       (message "auto-revert-config: could not watch %s: %s"
                buffer-file-name err)))))

(defun emacs-config--teardown-file-watcher ()
  "Remove the file-system watcher when the buffer is killed."
  (when emacs-config--file-watcher
    (file-notify-rm-watch emacs-config--file-watcher)
    (setq emacs-config--file-watcher nil)))

(add-hook 'find-file-hook  #'emacs-config--setup-file-watcher)
(add-hook 'kill-buffer-hook #'emacs-config--teardown-file-watcher)

(provide 'auto-revert-config)
