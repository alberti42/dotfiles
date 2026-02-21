;;; csi-u-keys.el --- Decode CSI-u backspace keys in terminal -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Some terminal emulators can report keypresses using "CSI u" sequences
;; (sometimes described under xterm's "modifyOtherKeys" / "formatOtherKeys"):
;;
;;   ESC [ <codepoint> ; <modifiers> u
;;
;; Example (observed via `view-lossage`):
;;
;;   Shift+Backspace => ESC [ 127 ; 2 u
;;
;; When Emacs runs in a terminal, it decodes keystrokes by matching escape
;; sequences in keymaps such as `input-decode-map` / `function-key-map`.
;; Emacs has support for some xterm-style modified key reporting, but it does
;; not provide general, complete decoding for all possible CSI-u sequences.
;;
;; The main reason is architectural/compatibility-related: the ESC [ (CSI)
;; namespace already contains many other sequences (cursor keys, function keys,
;; mouse tracking, etc.). A full CSI-u parser would need to cooperate with those
;; existing bindings and avoid capturing sequences meant for other features.
;; This is discussed in the GNU Emacs bug tracker thread:
;;
;;   https://issues.guix.gnu.org/54027
;;
;; (including references to earlier work in bug#13839 and notes about potential
;; interference with other ESC-prefix users such as mouse handling).
;;
;; Pragmatic approach:
;; - Record the exact escape sequences produced by the terminal (`view-lossage`).
;; - Add explicit decoders for those sequences.
;;
;; This module sticks to decoding only.
;; It deliberately does not translate key events or bind editing commands, so
;; existing Emacs defaults (and user custom keybindings) continue to apply.
;;
;; This module implements that approach for Backspace variants.

;;; Code:

(defconst csi-u-keys-decode-alist
  '(("\e[127;2u" . [S-backspace])     ; Shift+Backspace: ESC [ 127 ; 2 u
    ("\e[8;6u"   . [C-backspace])     ; Ctrl+Backspace: ESC [ 8 ; 6 u
    ("\e[8;5u"   . [C-S-backspace]))  ; Ctrl+Shift+Backspace: ESC [ 8 ; 5 u
  "Alist mapping terminal escape sequences (CSI u) to Emacs key events.")

;; Decode the observed CSI-u sequences into Emacs key events.
(dolist (map (list input-decode-map function-key-map))
  (dolist (kv csi-u-keys-decode-alist)
    (define-key map (car kv) (cdr kv))))

(provide 'csi-u-keys)

;;; csi-u-keys.el ends here
