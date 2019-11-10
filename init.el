;;; init.el --- Initialization file for Emacs  -*- fill-column: 78; lexical-binding: t; -*-
;;; Commentary: Emacs Startup File --- initialization for Emacs

;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; ===============================  INIT FILE  ===============================
;; ==================================== * ====================================
;; ===============================  ~ Zaeph ~  ===============================
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(setq default-directory "~")
(setq inhibit-startup-screen 1)
(setq initial-scratch-message ";; Emacs Scratch\n\n")

;; (toggle-debug-on)
;; (toggle-debug-on-quit)
;; (setq garbage-collection-messages t)

;; Alias the longform of ‘y-or-n-p’
(defalias 'yes-or-no-p 'y-or-n-p)

;; Show current filename in titlebar
(setq frame-title-format "%b")

;; Use spaces instead of tabs
(setq-default indent-tabs-mode nil)

;; Set default fill column to 78
(setq-default fill-column 78)

;; Add folders to load-path
(add-to-list 'load-path "~/.emacs.d/old-lisp")
(add-to-list 'load-path "~/.emacs.d/lisp")
(add-to-list 'load-path "/usr/share/emacs/site-lisp")

;; Point to my Emacs fork for studying built-in functions
(setq source-directory "~/projects/forks/emacs")

;; Turn off background when Emacs is run with -nt
(defun on-after-init ()
  (unless (display-graphic-p (selected-frame))
    (set-face-background 'default "unspecified-bg" (selected-frame))))
(add-hook 'window-setup-hook 'on-after-init)

;; Force horizontal splitting
;; (setq split-width-threshold 9999)    ;Default: 160

;; Suppress warning when opening large files
(setq large-file-warning-threshold nil)

;; Configure ‘display-buffer’ behaviour for some special buffers
(setq display-buffer-alist
      `(;; Messages, errors, processes, Calendar in the bottom side window
        (,(rx bos (or "*Apropos"                ; Apropos buffers
                      "*Man"                    ; Man buffers
                      ;; "*Help"                   ; Help buffers
                      "*Warnings*"              ; Emacs warnings
                      "*Process List*"          ; Processes
                      "*Proced"                 ; Proced processes list
                      "*Compile-Log*"           ; Emacs byte compiler log
                      "*compilation"            ; Compilation buffers
                      "*Flycheck errors*"       ; Flycheck error list
                      "*Calendar"               ; Calendar window
                      "*env-info"               ; Environment information
                      "*Cargo"                  ; Cargo process buffers
                      "*Word"                   ; WordNut buffers
                      "*Reconcile*"             ; Reconcile in ledger-mode
                      (and (1+ nonl) " output*"))) ; AUCTeX command output
         (display-buffer-reuse-window display-buffer-in-side-window)
         (side . bottom)
         (reusable-frames . visible)
         (window-height . 0.45))
        ;; REPLs on the bottom half
        (,(rx bos (or "*cider-repl"     ; CIDER REPL
                      "*intero"         ; Intero REPL
                      "*idris-repl"     ; Idris REPL
                      "*ielm"           ; IELM REPL
                      "*SQL"))          ; SQL REPL
         (display-buffer-reuse-window display-buffer-in-side-window)
         (side . bottom)
         (reusable-frames . visible)
         (window-height . 0.50))
        ;; Open shell in a single window
        (,(rx bos "*shell")
         (display-buffer-same-window)
         (reusable-frames . nil))
        ;; Open PDFs in the right side window
        (,(rx bos "*pdf")
         (display-buffer-reuse-window display-buffer-in-side-window)
         (side . right)
         (reusable-frames . visible)
         (window-width . 0.5))
        ;; Let `display-buffer' reuse visible frames for all buffers. This must
        ;; be the last entry in `display-buffer-alist', because it overrides any
        ;; previous entry with more specific actions.
        ("." nil (reusable-frames . visible))))

;; Enable disabled commands
(setq disabled-command-function nil)

;; Do not display continuation lines
(set-default 'truncate-lines t)

;; Enable line-restricted horizontal scrolling
(setq auto-hscroll-mode 'current-line)

;; Disable final newline insertion
(setq-default require-final-newline nil)

;; Enforce French spacing when filling paragraphs
(add-to-list 'fill-nobreak-predicate 'fill-french-nobreak-p)

;; Disable mouse focus
(setq focus-follows-mouse nil)
(setq mouse-autoselect-window nil)

;; Use a subtle visible bell
(defun zp/subtle-visible-bell ()
  "A more subtle visual bell effect."
  (invert-face 'mode-line)
  (run-with-timer 0.1 nil #'invert-face 'mode-line))

(setq visible-bell nil
      ring-bell-function #'zp/subtle-visible-bell)

;; Suppress bells for reaching beginning and end of buffer
;; Source: https://emacs.stackexchange.com/questions/10932/how-do-you-disable-the-buffer-end-beginning-warnings-in-the-minibuffer/20039
(defun zp/command-error-function (data context caller)
  "Ignore the buffer-read-only, beginning-of-buffer,
end-of-buffer signals; pass the rest to the default handler."
  (when (not (memq (car data) '(buffer-read-only
                                beginning-of-buffer
                                end-of-buffer)))
    (command-error-default-function data context caller)))

(setq command-error-function #'zp/command-error-function)

;; Maximise the frame
(toggle-frame-maximized)

;; Transparency
;; (set-frame-parameter (selected-frame) 'alpha '(95 . 95))
;; (add-to-list 'default-frame-alist '(alpha . (95 . 95)))

;; Temporary fix for helm delays
(when (= emacs-major-version 26)
  (setq x-wait-for-event-timeout nil))

;; Path to authentication sources
(setq auth-sources '("~/.authinfo.gpg" "~/.netrc"))

;; Enable recursive minibuffers
;; Necessary for for some Ivy/Helm commands
(setq enable-recursive-minibuffers t)

;; Make M-U equivalent to C-u
;; Commented out because I can’t remember why it was necessary
;; (global-set-key (kbd "M-U") 'universal-argument)
;; (define-key universal-argument-map "\M-U" 'universal-argument-more)

;; Prevent newlines insertion when moving past the end of the file
(setq next-line-add-newlines nil)

;;----------------------------------------------------------------------------
;; Helper functions & macros
;;----------------------------------------------------------------------------
(defun zp/get-string-from-file (file-path)
  "Read file content from path."
  (with-temp-buffer
    (insert-file-contents file-path)
    (buffer-string)))

;; TODO: Does it need to be macro?
(defmacro zp/advise-commands (method commands where function)
  (let ((where-keyword (intern-soft (concat ":" (symbol-name where)))))
    `(progn
       ,@(cond ((string= method 'add)
                (mapcar (lambda (command)
                          `(advice-add ',command ,where-keyword #',function))
                        commands))
               ((string= method 'remove)
                (mapcar (lambda (command)
                          `(advice-remove ',command  #',function))
                        commands))))))

(defmacro zp/add-hooks (method commands function)
  (let ((where-keyword (intern-soft (concat ":" (symbol-name where)))))
    `(progn
       ,@(cond ((string= method 'add)
                (mapcar (lambda (command)
                          `(add-hook ',command #',function))
                        commands))
               ((string= method 'remove)
                (mapcar (lambda (command)
                          `(remove-hook ',command  #',function))
                        commands))))))

(defun other-window-reverse ()
  "Select the previous window."
  (interactive)
  (select-window (previous-window)))

;;----------------------------------------------------------------------------
;; Timers
;;----------------------------------------------------------------------------
(defvar gc-cons-threshold-for-timers 800000000
  "Custom ‘gc-cons-threshold’ to be used by ‘time’.

This prevents garbage-collection from interfering with the
functions being timed.

The value needs to be sufficiently high to prevent
garbage-collection during execution, but not so high as to cause
performance problems.")

(defvar timer-output-format "%.3fs (GC: +%.3fs, Σ: %.3fs)"
  "Default output format for timers.")

(defmacro time-internal (&rest forms)
  "Compute the time taken to run FORMS.

Return a list containing:
- The return value of FORMS
- The time taken to evaluate FORMS
- The time taken to garbage collect
- The total time"
  `(let* ((body '(progn ,@forms))
          (gc-cons-threshold (progn (garbage-collect)
                                    gc-cons-threshold-for-timers))
          (start (current-time))
          (return-value (eval body))
          (end (current-time))
          (elapsed (float-time (time-subtract end start)))
          results)
     (prog1 (setq results (list return-value elapsed))
       (garbage-collect)
       (let* ((end-gc (current-time))
              (elapsed-gc (float-time (time-subtract end-gc end)))
              (elapsed-total (+ elapsed elapsed-gc)))
         (push elapsed-gc (cdr (last results)))
         (push elapsed-total (cdr (last results)))))))

(defmacro time (&rest forms)
  "Return the time taken to run FORMS as a string."
  `(let* ((results (time-internal ,@forms))
          (return-value (pop results))
          (elapsed (pop results))
          (elapsed-gc (pop results))
          (elapsed-total (pop results)))
     (format timer-output-format elapsed elapsed-gc elapsed-total)))

(defmacro time-stats (iterations multiplier &rest forms)
  "Return statistics on the execution of FORMS.

ITERATIONS is the sample-size to use for the statistics.

MULTIPLIER is an integer to specify how many times to evaluate
FORMS on each iteration."
  (declare (indent 2))
  `(let ((multiplier (or ,multiplier 1))
         list)
     ;; If only one iteration, use ‘time’ instead
     (if (or (not ,iterations) (= 1 ,iterations))
         (time
          (dotimes (y multiplier)
            ,@forms))
       (dotimes (i ,iterations)
         (message "Iteration: %s" (1+ i))
         (push (nth 1 (time-internal
                       (dotimes (y multiplier)
                         ,@forms)))
               list))
       (let ((min (apply #'min list))
             (max (apply #'max list))
             (mean (/ (apply #'+ list) (length list))))
         (format "min: %.3fs, max: %.3fs, mean: %.3fs" min max mean)))))

(defmacro with-timer (title &rest forms)
  "Run the given FORMS, counting the elapsed time.

A message including the given TITLE and the corresponding elapsed
time is displayed."
  (declare (indent 1))
  (message "%s..." title)
  `(let* ((results (time-internal ,@forms))
          (return-value (pop results))
          (elapsed (pop results))
          (elapsed-gc (pop results))
          (elapsed-total (pop results)))
     (prog1 return-value
       (message (concat "%s...done in " timer-output-format)
                ,title elapsed elapsed-gc elapsed-total))))

;;----------------------------------------------------------------------------
;; Editing commands
;;----------------------------------------------------------------------------
(defun zp/unfill-document ()
  "fill individual paragraphs with large fill column"
  (interactive)
  (let ((fill-column 100000))
    (fill-individual-paragraphs (point-min) (point-max))))

(defun zp/unfill-paragraph ()
  (interactive)
  (let ((fill-column (point-max)))
    (fill-paragraph nil)))

(defun zp/unfill-region ()
  (interactive)
  (let ((fill-column (point-max)))
    (fill-region (region-beginning) (region-end) nil)))

(defun zp/unfill-context ()
  (interactive)
  (if (region-active-p)
      (zp/unfill-region)
    (zp/unfill-paragraph)))

(defun zp/kill-other-buffer-and-window ()
  "Kill the other buffer and window if there is more than one window."
  (interactive)
  (if (not (one-window-p))
      (progn
        (select-window (next-window))
        (kill-buffer-and-window))
    (user-error "There is only one window in the frame")))

;;----------------------------------------------------------------------------
;; Custom modes
;;----------------------------------------------------------------------------
(define-minor-mode print-circle-mode
    "Mode for toggling ‘print-circle’ globally."
  :lighter " crcl"
  :global t
  (if print-circle-mode
      (setq print-circle t)
    (setq print-circle nil)))

(print-circle-mode)

(define-minor-mode always-centred-mode
  "Mode for keeping the cursor vertically centred."
  :lighter " ctr"
  (let* ((settings '((scroll-preserve-screen-position nil t)
                     (scroll-conservatively 0 0)
                     (maximum-scroll-margin 0.25 0.5)
                     (scroll-margin 0 99999)))
         (toggle (lambda (mode)
                   (dolist (data settings)
                     (cl-destructuring-bind (setting default new) data
                       (set (make-local-variable setting)
                            (if (eq mode 'on)
                                new
                              default)))))))
    (if always-centred-mode
        (funcall toggle 'on)
      (funcall toggle 'off))))

(global-set-key (kbd "M-Y") #'always-centred-mode)

;;----------------------------------------------------------------------------
;; Keys
;;----------------------------------------------------------------------------
;; Define keymap for minor mode toggles
(define-prefix-command 'zp/toggle-map)
(define-key ctl-x-map "t" 'zp/toggle-map)

(define-key zp/toggle-map (kbd "d") #'toggle-debug-on-error)
(define-key zp/toggle-map (kbd "Q") #'toggle-debug-on-quit)
(define-key zp/toggle-map (kbd "q") #'electric-quote-local-mode)
(define-key zp/toggle-map (kbd "f") #'auto-fill-mode)
(define-key zp/toggle-map (kbd "l") #'display-line-numbers-mode)
(define-key zp/toggle-map (kbd "h") #'global-hl-line-mode)
(define-key zp/toggle-map (kbd "p") #'print-circle-mode)

;; Modes
(global-set-key (kbd "C-c s") #'scroll-bar-mode)
(global-set-key (kbd "C-c H") #'global-hl-line-mode)
(global-set-key (kbd "C-c g") #'display-line-numbers-mode)
(global-set-key (kbd "M-U") #'visual-line-mode)

;; Exit Emacs with ‘C-x r q’, and kill the current frame with ‘C-x C-c’
(global-set-key (kbd "C-x r q") #'save-buffers-kill-terminal)
(global-set-key (kbd "C-x C-c") #'delete-frame)

;; Actions
(global-set-key (kbd "M-SPC") #'delete-horizontal-space)
(global-set-key (kbd "M-S-SPC") #'just-one-space)
(global-set-key (kbd "H-.") #'zp/echo-buffer-name)
(global-set-key (kbd "C-x F") #'zp/unfill-document)
(global-set-key (kbd "M-Q") #'zp/unfill-context)
(global-set-key (kbd "C-x B") #'rename-buffer)
(global-set-key (kbd "M-o") #'mode-line-other-buffer)
(global-set-key (kbd "H-j") #'other-window-reverse)
(global-set-key (kbd "H-k") #'other-window)
(global-set-key (kbd "C-x 4 1") #'zp/kill-other-buffer-and-window)

;; Ignore Kanji key in IME
(global-set-key [M-kanji] 'ignore)

;;----------------------------------------------------------------------------
;; Cosmetics
;;----------------------------------------------------------------------------
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)
(show-paren-mode 1)
(global-hl-line-mode 1)
(column-number-mode 1)

;; Set fringe sizes
(fringe-mode 20)

;;----------------------------------------------------------------------------
;; Electric
;;----------------------------------------------------------------------------
(electric-quote-mode 1)
(setq electric-quote-context-sensitive 1)

;;----------------------------------------------------------------------------
;; Backups
;;----------------------------------------------------------------------------
;; Don’t clobber symlinks
(setq backup-by-copying t)

;; Use versioned backups
(setq version-control t)

;; Number of backups to keep
(setq kept-new-versions 10
      kept-old-versions 0
      delete-old-versions t)

;; Backup directories
(setq backup-directory-alist '(("." . "~/.saves")))

;; Also backup versioned files
(setq vc-make-backup-files t)

;;----------------------------------------------------------------------------
;; diff
;;----------------------------------------------------------------------------
;; Diff backend
(setq diff-command "diff")            ;Default

;; Add ‘-u’ switch for diff
(setq diff-switches "-u")

;;----------------------------------------------------------------------------
;; Miscellaneous
;;----------------------------------------------------------------------------
;; windmove
(windmove-default-keybindings 'super)
(setq windmove-wrap-around t)

;; desktop
(desktop-save-mode 0)

;; mwheel
(setq mouse-wheel-flip-direction 1
      mouse-wheel-scroll-amount '(2 ((shift) . 1) ((control)))
      mouse-wheel-progressive-speed nil
      mouse-wheel-follow-mouse 't)

;; Disable side movements
;; (global-set-key (kbd "<mouse-6>") 'ignore)
;; (global-set-key (kbd "<mouse-7>") 'ignore)
;; (global-set-key (kbd "<triple-mouse-7>") 'ignore)
;; (global-set-key (kbd "<triple-mouse-6>") 'ignore)

;; Time
(setq display-time-default-load-average nil)
(display-time-mode 1)

;; EPG
(setq mml2015-use 'epg
      epg-user-id (zp/get-string-from-file "~/org/pp/gpg/gpg-key-id")
      mml-secure-openpgp-sign-with-sender t
      mml-secure-openpgp-encrypt-to-self t)

;;----------------------------------------------------------------------------
;; Setup package repositories
;;----------------------------------------------------------------------------
;; MELPA
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives '("gnu" . (concat proto "://elpa.gnu.org/packages/")))))

;; Disable org’s ELPA packages
(setq package-load-list '(all
                          (org nil)
                          (org-plus-contrib nil)))

;; org-elpa
(add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t)

;; Initialise packages
(package-initialize)

;; ‘use-package’ initialisation
(eval-when-compile
  ;; Following line is not needed if use-package.el is in ~/.emacs.d
  ;; (add-to-list 'load-path "<path where use-package is installed>")
  (require 'use-package))

(use-package slime)

(use-package slime-cl-indent
  :config
  (setq lisp-indent-function #'lisp-indent-function) ;Default

  ;; Change indent style for CL
  (setq common-lisp-style "sbcl")

  ;; Way to override indent for some functions
  ;; (put 'use-package 'common-lisp-indent-function 1)
  )

(use-package package
  :bind ("C-c P" . package-list-packages))

;; Start server
(use-package server
  :config
  ;; Start server if it hasn’t been started already
  (if (server-running-p)
      (setq initial-scratch-message
            (concat initial-scratch-message
                    ";; STANDALONE\n\n"))
    (server-start)))

;; (setq use-package-verbose t)

;;----------------------------------------------------------------------------
;; Packages
;;----------------------------------------------------------------------------
(use-package evil
  :config
  (evil-mode 0))

;; For handling encryption
(use-package epa-file
  :config
  (epa-file-enable)
  (setq epg-gpg-program "gpg2"))

(use-package isearch
  :bind (:map isearch-mode-map
              ("<backspace>" . 'isearch-del-char)))

;; fcitx (IME for CJK)
;; Disabled because of slow-downs in combination with visual-line-mode
;; (fcitx-aggressive-setup)

(use-package ox-hugo)

(use-package duplicate-thing
  :bind ("M-J" . duplicate-thing))

(use-package volatile-highlights
  :config
  (volatile-highlights-mode))

;; ;; Removed because of conflict with ‘use-hard-newlines’
;; (use-package clean-aindent-mode
;;   :config
;;   (add-hook 'prog-mode-hook #'clean-aindent-mode))

(use-package ws-butler
  :hook (prog-mode . ws-butler-mode))

(use-package whitespace
  :bind (("C-c w" . zp/whitespace-mode-lines-tail)
         ("C-c W" . whitespace-mode))
  :hook (prog-mode . zp/whitespace-mode-lines-tail)
  :config
  (defun zp/whitespace-mode-lines-tail ()
    (interactive)
    (if (bound-and-true-p whitespace-mode)
        (progn
          (whitespace-mode -1)
          (message "Whitespace mode disabled in current buffer"))
      (let ((whitespace-style '(face trailing lines-tail))
            (whitespace-line-column nil))
        (whitespace-mode t)
        (message "Whitespace mode enabled in current buffer")))))

(use-package info+
  :bind (:map Info-mode-map
              ("<mouse-4>" . mwheel-scroll)
              ("<mouse-5>" . mwheel-scroll)
              ("j" . next-line)
              ("k" . previous-line)))

(use-package recentf-ext)

(use-package dired
  :hook (dired-mode . turn-on-gnus-dired-mode))

(use-package diff-hl
  :hook ((dired-mode . diff-hl-dired-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (global-diff-hl-mode)
  (diff-hl-flydiff-mode))

(use-package eyebrowse)

(use-package which-key
  :config
  (which-key-mode)
  ;; (setq which-key-idle-delay 1) ;Default
)

(use-package lilypond-mode)

(use-package el-patch)

(use-package ol
  :config
  (global-set-key (kbd "C-c L") #'org-store-link))

(use-package ox
  :config
  (setq org-export-in-background t
        org-export-with-sub-superscripts nil))

(use-package ox-org)

(use-package org-mind-map)

(use-package exwm-config)

(use-package exwm
  :disabled
  :requires exwm-config
  :config
  (exwm-config-default))

;; so-long
(use-package so-long
  :hook (debugger-mode . so-long-minor-mode)
  :config
  (global-so-long-mode 1))

(use-package sh-script
  :mode (("\\zshrc\\'" . shell-script-mode)
         ("\\prompt_.*_setup\\'" . shell-script-mode)))


(use-package fish-mode
  :mode "\\.fish\\'")

(use-package prog-mode
  ;; Force fringe indicators
  :hook (prog-mode . zp/enable-visual-line-fringe-indicators)
  :config
  (defun zp/enable-visual-line-fringe-indicators ()
    "Enablle visual-line fringe-indicators."
    (setq-local visual-line-fringe-indicators '(left-curly-arrow right-curly-arrow))) )

(use-package free-keys
  :config
  (setq free-keys-modifiers '("" "C" "M" "C-M" "H")))

(use-package flycheck
  :hook ((sh-mode . flycheck-mode)
         (cperl-mode . flycheck-mode)
         (elisp-mode . flycheck-mode)
         ;; Enable flycheck everywhere
         ;; Disabled because of slow-downs in large files
         ;; (after-init . global-flycheck-mode)
         )
  :bind (:map zp/toggle-map
              ("F" . flycheck-mode))
  :config
  (setq-default flycheck-disabled-checkers '(emacs-lisp-checkdoc))
  (setq flycheck-emacs-lisp-load-path 'inherit
        flycheck-display-errors-delay 0.5))

;; Minor-mode to show Flycheck error messages in a popup
(use-package fly-check-pos-tip
  :disabled
  :requires flycheck
  :config
  (flycheck-pos-tip-mode))

(use-package lispy
  :load-path "~/projects/lispy"
  :config
  (defun lispy-mode-unbind-keys ()
    "Modify keymaps used by ‘lispy-mode’."
    (define-key lispy-mode-map (kbd "M-o") nil))
  (lispy-mode-unbind-keys)

  (setq lispy-avy-keys
        '(?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l ?m
             ?n ?o ?p ?q ?r ?s ?t ?u ?v ?w ?x ?y ?z
             ?A ?B ?C ?D ?E ?F ?G ?H ?I ?J ?K ?L ?M
             ?N ?O ?P ?Q ?R ?S ?T ?U ?V ?W ?X ?Y ?Z))

  (setq semantic-inhibit-functions
        (list (lambda () (not (eq major-mode org-mode)))))

  (add-hook 'emacs-lisp-mode-hook #'lispy-mode))

(use-package nov
  :mode ("\\.\\(epub\\|mobi\\)\\'" . nov-mode))

(use-package olivetti
  :hook (nov-mode . olivetti-mode)
  :bind ("M-O" . olivetti-mode)
  :config
  (setq-default olivetti-body-width 0.6
                olivetti-minimum-body-width 80))

(use-package fountain-mode
  :config
  (setq fountain-export-font "Courier Prime")
  (setq fountain-mode-hook '(turn-on-visual-line-mode
                             fountain-outline-hide-custom-level
                             olivetti-mode)))

(use-package yasnippet
  :config
  (yas-global-mode 1)
  (global-set-key (kbd "H-<backspace>") 'yas-prev-field))

(use-package winner
  :bind (("H-u" . winner-undo)
         ("H-i" . winner-redo))
  :config
  (winner-mode 1))

(use-package ace-window
  :bind ("H-b" . ace-window)
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
        aw-scope 'frame))

(use-package avy
  :bind (;; ("H-n" . avy-goto-goto-word-1)
         ;; ("H-n" . avy-goto-goto-char)
         ("H-n" . avy-goto-char-timer)))

(use-package ace-link
  :config
  (ace-link-setup-default))

;; (use-package dumb-jump
;;   :config
;;   (dumb-jump-mode)
;;   (global-visible-mark-mode 1))

(use-package backup-walker
  :hook (backup-walker-mode . zp/set-diff-backend-git-diff)
  :config
  (defun zp/set-diff-backend-git-diff ()
    "Set diff backend to ‘git diff’.
Modifies ‘diff-command’ and ‘diff-switches’ to use ‘git diff’."
    (setq-local diff-command "git --no-pager diff")
    (setq-local diff-switches "--textconv")))

;; Disabled since Emacs now has a native package for showing
;; line-numbers
(use-package linum
  :disabled
  ;Add spaces before and after
  (setq linum-format " %d "))

(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query))

(use-package pdf-view
  :config
  (defvar zp/pdf-annot-default-annotation-color "#389BE6"
    "Default color to use for annotations.")

  (setq zp/pdf-annot-default-annotation-color "#389BE6")

  (setq pdf-annot-default-annotation-properties
        `((t (label . ,user-full-name))
          (text (icon . "Note") (color . ,zp/pdf-annot-default-annotation-color))
          (highlight (color . "yellow"))
          (squiggly (color . "orange"))
          (strike-out (color . "red"))
          (underline (color . "blue"))))

  (defun zp/toggle-pdf-view-auto-slice-minor-mode ()
    "Toggle ‘pdf-view-auto-slice-minor-mode’ and reset slice."
    (interactive)
    (call-interactively 'pdf-view-auto-slice-minor-mode)
    (if (not pdf-view-auto-slice-minor-mode)
        (progn
          (pdf-view-reset-slice))))

  ;; Disable continuous view in pdf-view
  ;; I prefer to explicitly turn pages
  (setq pdf-view-continuous nil)

  ;; Automatically activate annotation when they’re created
  (setq pdf-annot-activate-created-annotations t)

  ;; Save after creating an annotation
  (defun zp/pdf-view-save-buffer ()
    "Save buffer and preserve midnight state."
    (save-buffer)
    (pdf-view-midnight-minor-mode 'toggle)
    (pdf-view-midnight-minor-mode 'toggle))

  (advice-add #'pdf-annot-edit-contents-commit :after 'zp/pdf-view-save-buffer)

  (defun zp/pdf-view-continuous-toggle ()
    (interactive)
    (cond ((not pdf-view-continuous)
           (setq pdf-view-continuous t)
           (message "Page scrolling: Continous"))
          (t
           (setq pdf-view-continuous nil)
           (message "Page scrolling: Constrained"))))

  (defun zp/pdf-view-open-in-evince ()
    "Open the current PDF with ‘evince’."
    (interactive)
    (save-window-excursion
      (let ((current-file (buffer-file-name))
            (current-page (number-to-string (pdf-view-current-page))))
        (async-shell-command
         (format "evince -i %s \"%s\"" current-page current-file))))
    (message "Sent to Evince"))

  (defun zp/pdf-view-show-current-page ()
    "Show the current page."
    (interactive)
    (message "Page: %s" (pdf-view-current-page)))

  ;;--------------------
  ;; Custom annotations
  ;;--------------------

  (defun zp/pdf-annot-add-custom-text-annotation (icon color)
    "Add custom annotation with ICON and COLOR."
    (let* ((icon (or icon "Note"))
           (color (or color zp/pdf-annot-default-annotation-color))
           (pdf-annot-default-annotation-properties
            `((t (label . ,user-full-name))
              (text (icon . ,icon) (color . ,color)))))
      (call-interactively #'pdf-annot-add-text-annotation)))

  (defvar zp/pdf-custom-annot-list nil
    "List of custom annotations and their settings.

Each element in list must be a list with the following elements:
- Name of the function to create
- Key binding
- Name of the icon to use
- Color to use")

  (defun zp/pdf-custom-annot-init ()
    (seq-do (lambda (settings)
              (cl-destructuring-bind (name key icon color) settings
                (let* ((root "zp/pdf-annot-add-text-annotation-")
                       (fun (intern (concat root name))))
                  (defalias fun
                    `(lambda ()
                       (interactive)
                       (zp/pdf-annot-add-custom-text-annotation ,icon ,color))
                    (format "Insert a note of type ‘%s’." name))
                  (define-key pdf-view-mode-map
                    (kbd key)
                    `,fun))))
            zp/pdf-custom-annot-list))
  (define-prefix-command 'zp/pdf-custom-annot-map)

  (define-key pdf-view-mode-map "a" 'zp/pdf-custom-annot-map)

  (setq zp/pdf-custom-annot-list
        `(("note" "T" "Note" ,zp/pdf-annot-default-annotation-color)
          ("note-yellow" "T" "Note" "#F1F23B")
          ("insert" "ai" "Insert" "#913BF2")
          ("comment" "c" "Comment" ,zp/pdf-annot-default-annotation-color)
          ("comment-red" "ac" "Comment" "#FF483E")
          ("circle" "ay" "Circle" "#38E691")
          ("cross" "an" "Cross" "#FF483E")))

  (zp/pdf-custom-annot-init)

  ;;----------
  ;; Bindings
  ;;----------

  (define-key pdf-view-mode-map (kbd "m") 'pdf-view-midnight-minor-mode)
  (define-key pdf-view-mode-map (kbd "s") 'zp/toggle-pdf-view-auto-slice-minor-mode)
  (define-key pdf-view-mode-map (kbd "M") 'pdf-view-set-slice-using-mouse)
  (define-key pdf-view-mode-map (kbd "C") 'zp/pdf-view-continuous-toggle)
  (define-key pdf-view-mode-map (kbd "w") 'pdf-view-fit-width-to-window)
  (define-key pdf-view-mode-map (kbd "RET") 'zp/pdf-view-open-in-evince)
  (define-key pdf-view-mode-map (kbd ".") 'zp/pdf-view-show-current-page)
  (define-key pdf-view-mode-map (kbd "t") 'pdf-annot-add-text-annotation)
  (define-key pdf-view-mode-map (kbd "h") 'pdf-annot-add-highlight-markup-annotation)
  (define-key pdf-view-mode-map (kbd "l") 'pdf-annot-list-annotations)
  (define-key pdf-view-mode-map (kbd "D") 'pdf-annot-delete)

  (define-key pdf-annot-edit-contents-minor-mode-map (kbd "C-c C-k") 'pdf-annot-edit-contents-abort)

  (define-prefix-command 'slice-map)
  (define-key pdf-view-mode-map (kbd "S") 'slice-map)
  (define-key pdf-view-mode-map (kbd "S b") 'pdf-view-set-slice-from-bounding-box)
  (define-key pdf-view-mode-map (kbd "S m") 'pdf-view-set-slice-using-mouse)
  (define-key pdf-view-mode-map (kbd "S r") 'pdf-view-reset-slice)

  (add-hook 'pdf-view-mode-hook #'pdf-view-midnight-minor-mode)
  (add-hook 'pdf-view-mode-hook #'pdf-view-auto-slice-minor-mode))

(use-package pdf-links
  :config
  (define-key pdf-links-minor-mode-map (kbd "f") 'pdf-view-fit-page-to-window))

;; TODO: Consider deleting this semi-useless minor-mode
(defun zp/save-buffers-kill-terminal-silently ()
  (interactive)
  (save-buffers-kill-terminal t))

(define-minor-mode save-silently-mode
  "Save buffers silently when exiting."
  :lighter " SS"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-x C-c") 'zp/save-buffers-kill-terminal-silently)
            (define-key map (kbd "C-c C-k") 'zp/kanji-add-furigana)
            (define-key map (kbd "M-n") 'zp/kanji-add-furigana)
            map))

;; Way to enable minor modes based on filenames
;; Added with the package ‘auto-minor-mode-alist’
;; But they can also be added via file-fariables or minor-modes
;; TODO: Adapt this block
(add-to-list 'auto-minor-mode-alist '("edit-in-emacs.txt" . visual-line-mode))
(add-to-list 'auto-minor-mode-alist '("edit-in-emacs.txt" . olivetti-mode))
(add-to-list 'auto-minor-mode-alist '("edit-in-emacs.txt" . flyspell-mode))
(add-to-list 'auto-minor-mode-alist '("edit-in-emacs.txt" . save-silently-mode))

;; (add-to-list 'auto-minor-mode-alist '("edit-in-emacs.html" . visual-line-mode))
;; (add-to-list 'auto-minor-mode-alist '("edit-in-emacs.html" . olivetti-mode))
;; (add-to-list 'auto-minor-mode-alist '("edit-in-emacs.html" . flyspell-mode))
(add-to-list 'auto-minor-mode-alist '("edit-in-emacs.html" . save-silently-mode))

(defun zp/kanji-add-furigana ()
  "Adds furigana to the kanji at point.
If text is selected, adds furigana to the selected kanji instead."
  (interactive)
  (if (not (region-active-p))
      (progn
        (call-interactively 'set-mark-command)
        (call-interactively 'forward-char)))
  (yas-expand-snippet (yas-lookup-snippet "anki-ruby")))

(use-package recentf
  :config
  (setq recentf-max-menu-items 100))

(use-package tramp
  :config
  (setq tramp-default-method "ssh"))

(use-package realgud
  :config
  (setq realgud-safe-mode nil))

(use-package picture
  :config
  (global-set-key (kbd "C-c \\") #'picture-mode))

(use-package hidpi-fringe-bitmaps)

(use-package thingatpt
  :bind (("C-c C-=" . increment-integer-at-point)
         ("C-c C--" . decrement-integer-at-point))
  :config
  (defun thing-at-point-goto-end-of-integer ()
    "Go to end of integer at point."
    (let ((inhibit-changing-match-data t))
      ;; Skip over optional sign
      (when (looking-at "[+-]")
        (forward-char 1))
      ;; Skip over digits
      (skip-chars-forward "[[:digit:]]")
      ;; Check for at least one digit
      (unless (looking-back "[[:digit:]]")
        (error "No integer here"))))
  (put 'integer 'beginning-op 'thing-at-point-goto-end-of-integer)

  (defun thing-at-point-goto-beginning-of-integer ()
    "Go to end of integer at point."
    (let ((inhibit-changing-match-data t))
      ;; Skip backward over digits
      (skip-chars-backward "[[:digit:]]")
      ;; Check for digits and optional sign
      (unless (looking-at "[+-]?[[:digit:]]")
        (error "No integer here"))
      ;; Skip backward over optional sign
      (when (looking-back "[+-]")
        (backward-char 1))))
  (put 'integer 'beginning-op 'thing-at-point-goto-beginning-of-integer)

  (defun thing-at-point-bounds-of-integer-at-point ()
    "Get boundaries of integer at point."
    (save-excursion
      (let (beg end)
        (thing-at-point-goto-beginning-of-integer)
        (setq beg (point))
        (thing-at-point-goto-end-of-integer)
        (setq end (point))
        (cons beg end))))
  (put 'integer 'bounds-of-thing-at-point 'thing-at-point-bounds-of-integer-at-point)

  (defun thing-at-point-integer-at-point ()
    "Get integer at point."
    (let ((bounds (bounds-of-thing-at-point 'integer)))
      (string-to-number (buffer-substring (car bounds) (cdr bounds)))))
  (put 'integer 'thing-at-point 'thing-at-point-integer-at-point)

  (defun increment-integer-at-point (&optional inc)
    "Increment integer at point by one.

With numeric prefix arg INC, increment the integer by INC amount."
    (interactive "p")
    (let ((inc (or inc 1))
          (n (thing-at-point 'integer))
          (bounds (bounds-of-thing-at-point 'integer)))
      (delete-region (car bounds) (cdr bounds))
      (insert (int-to-string (+ n inc)))))

  (defun decrement-integer-at-point (&optional dec)
    "Decrement integer at point by one.

With numeric prefix arg DEC, decrement the integer by DEC amount."
    (interactive "p")
    (increment-integer-at-point (- (or dec 1)))))

(use-package highlight-indent-guides
    :bind (:map zp/toggle-map
                ("c" . highlight-indent-guides-mode))
    :hook (prog-mode . highlight-indent-guides-mode)
    :config
    (setq highlight-indent-guides-method 'column
          highlight-indent-guides-auto-character-face-perc 20))

;;----------------------------------------------------------------------------
;; Shortcuts
;;----------------------------------------------------------------------------
;; TODO: Consider optimising this section

(define-prefix-command 'ledger-map)
(global-set-key (kbd "C-c l") 'ledger-map)

(define-prefix-command 'projects-map)
(global-set-key (kbd "C-c p") 'projects-map)

(define-prefix-command 'projects-hacking-map)
(global-set-key (kbd "C-c p h") 'projects-hacking-map)

(define-prefix-command 'classes-map)
(global-set-key (kbd "C-c p c") 'classes-map)

;; (define-prefix-command 'activism-map)
;; (global-set-key (kbd "C-c p a") 'activism-map)

(defun zp/set-shortcuts (alist)
  (mapc
   (lambda (x)
     (let ((file-shortcut (car x))
           (file-path (cdr x)))
       (global-set-key (kbd (concat "C-c " file-shortcut))
                       `(lambda ()
                          (interactive)
                          (find-file ',file-path)))))
   alist))


(setq zp/shortcuts-alist
      '(
        ;; Misc
        ("e" . "~/.emacs.d/init.el")
        ("I" . "~/org/info.org.gpg")
        ("p d" . "/ssh:asus:~/Downloads/Sharing/dl.org")

        ;; Ledger
        ("l l" . "~/org/ledger/main.ledger.gpg")
        ("l s" . "~/org/ledger/main-schedule.ledger.gpg")
        ;; ("l f" . "~/org/ledger/french-house.ledger.gpg")

        ;; Research
        ("p T" . "~/org/projects/university/research/thesis/thesis.tex")
        ;; ("p T" . "~/org/projects/university/research/presentation/presentation.tex")
        ("p b" . "~/org/bib/monty-python.bib")
        ("p B" . "~/org/projects/university/research/thesis/bibliography/bibliography.tex")
        ;; ("p c" . "~/org/projects/university/research/sty/zaeph.sty")
        ;; ("p C" . "~/org/projects/university/research/sty/presentation.sty")
        ;; ("p d" . "/tmp/asus~/Downloads/Sharing/dl.org")

        ;; Journal
        ("j" . "~/org/journal.org")

        ;; Projects
        ("p w" . "~/org/projects/writing/writing.org.gpg")
        ;; ("p t" . "~/org/projects/tavocat/tavocat.org.gpg")
        ;; ("p k". "~/org/projects/kendeskiñ/kendeskiñ.org.gpg")
        ("p t" . "~/org/projects/typography/typography.org.gpg")

        ;; University
        ("p u" . "~/org/projects/university/university.org.gpg")
        ("p r" . "~/org/projects/university/research/research.org.gpg")
        ;; ("p c l"     . "~/org/projects/university/classes/university/ling/ling.org.gpg")
        ;; ("p c u"     . "~/org/projects/university/classes/university/civ-us/civ-us.org.gpg")
        ;; ("p c g"     . "~/org/projects/university/classes/university/civ-gb/civ-gb.org.gpg")
        ;; ("p c s"     . "~/org/projects/university/classes/university/space/space.org.gpg")
        ;; ("p c i"     . "~/org/projects/university/classes/university/lit/lit.org.gpg")
        ;; ("p c s"     . "~/org/projects/university/classes/university/syn/syn.org.gpg")
        ;; ("p c t"     . "~/org/projects/university/classes/espe/tronc-commun.org.gpg")

        ;; Languages
        ("p j" . "~/org/projects/lang/ja/ja.org.gpg")
        ("p g" . "~/org/projects/lang/de/de.org.gpg")

        ;; Activism
        ("p a" . "~/org/projects/activism/politics/politics.org.gpg")
        ;; ("p a d"  . "[DATA EXPUNGED]")
        ;; ("p a s"  . "[DATA EXPUNGED]")
        ;; ("p a c"  . "[DATA EXPUNGED]")
        ;; ("p a m"  . "[DATA EXPUNGED]")

        ;; Media
        ("p n" . "~/org/projects/media/news/news.org.gpg")

        ;; Music
        ("p P" "~/org/piano.org.gpg")

        ;; Awakening
        ("p A" . "~/org/projects/awakening/awakening.org.gpg")

        ;; Psychotherapy
        ("p p" . "~/org/projects/psychotherapy/psychotherapy.org.gpg")
        ;; Sports
        ("p S" . "~/org/sports/swimming/swimming.org.gpg")
        ("p R" . "~/org/sports/running/running.org.gpg")

        ;; Hacking
        ("p h e" . "~/org/projects/hacking/emacs/emacs.org.gpg")
        ("p h l" . "~/org/projects/hacking/linux/linux.org.gpg")
        ("p h n" . "~/org/projects/hacking/linux/nixos.org")
        ("p h o" . "~/org/projects/hacking/opsec/opsec.org.gpg")
        ("p h h" . "~/org/projects/hacking/hacking.org.gpg")
        ("p h p" . "~/org/projects/hacking/python/python.org.gpg")

        ;; Media
        ("b" . "~/org/media.org.gpg")

        ;; Life
        ("o" . "~/org/life.org")))

(defun zp/set-shortcuts-all ()
  (zp/set-shortcuts zp/shortcuts-alist))

(zp/set-shortcuts-all)

;;----------------------------------------------------------------------------
;; ispell
;;----------------------------------------------------------------------------
(use-package ispell
  :bind ("C-c d" . zp/helm-ispell-preselect)
  :config
  ;; TODO: Modernise

  ;; Use aspell as the backend
  (setq-default ispell-program-name "aspell")

  ;; Allow `’` to be part of a word
  ;; Otherwise, apostrophes typed with ‘electric-quote-mode’ are not
  ;; recognised as such
  (setq ispell-local-dictionary-alist
        `((nil "[[:alpha:]]" "[^[:alpha:]]" "['\x2019]" nil ("-B") nil utf-8)
          ("english" "[[:alpha:]]" "[^[:alpha:]]" "['’]" t ("-d" "en_US") nil utf-8)
          ("british" "[[:alpha:]]" "[^[:alpha:]]" "['’]" t ("-d" "en_GB") nil utf-8)
          ("french" "[[:alpha:]]" "[^[:alpha:]]" "['’]" t ("-d" "fr_FR") nil utf-8)))

  ;; Allow curvy quotes to be considered as regular apostrophe
  (setq ispell-local-dictionary-alist
        (quote
         (("english" "[[:alpha:]]" "[^[:alpha:]]" "['’]" t ("-d" "en_US") nil utf-8)
          ("british" "[[:alpha:]]" "[^[:alpha:]]" "['’]" t ("-d" "en_GB") nil utf-8)
          ("french" "[[:alpha:]]" "[^[:alpha:]]" "['’]" t ("-d" "fr_FR") nil utf-8))))

  ;; Don't send ’ to the subprocess.
  (defun endless/replace-apostrophe (args)
    (cons (replace-regexp-in-string
           "’" "'" (car args))
          (cdr args)))
  (advice-add #'ispell-send-string :filter-args
              #'endless/replace-apostrophe)

  ;; Convert ' back to ’ from the subprocess.
  (defun endless/replace-quote (args)
    (if (not (derived-mode-p 'org-mode))
        args
      (cons (replace-regexp-in-string
             "'" "’" (car args))
            (cdr args))))
  (advice-add #'ispell-parse-output :filter-args
              #'endless/replace-quote)

  ;; Helm-Ispell
  (defvar zp/ispell-completion-data nil)
  (setq ispell-dictionary "british"
        zp/ispell-completion-data '(("English" . "british")
                                    ("French" . "french")))

  (defun zp/ispell-switch-dictionary (language)
    "Change the Ispell dictionary to LANGUAGE.

LANGUAGE should be the name of an Ispell dictionary."
    (interactive)
    (let ((name (car (rassoc language zp/ispell-completion-data))))
      (if (eq language ispell-local-dictionary)
          (message "Dictionary is already loaded for this language")
        (setq ispell-local-dictionary language)
        (flyspell-mode)
        (message (concat "Local Ispell dictionary set to " name)))
      (when flyspell-mode
        (flyspell-mode -1)
        (flyspell-mode))))

  (defun zp/ispell-query-dictionary ()
    (if (not (y-or-n-p "Writing in English? "))
        (ispell-change-dictionary "french")))

  (defvar zp/helm-ispell-actions nil)
  (setq zp/helm-ispell-actions
        '(("Change dictionary" . zp/ispell-switch-dictionary)))

  (defvar zp/helm-source-ispell nil)
  (setq zp/helm-source-ispell
        '((name . "*HELM Ispell - Dictionary selection*")
          (candidates . zp/ispell-completion-data)
          (action . zp/helm-ispell-actions)))

  (defun zp/helm-ispell-preselect (&optional lang)
    (interactive)
    (let ((current ispell-local-dictionary))
      (helm :sources '(zp/helm-source-ispell)
            :preselect (if (or
                            (eq lang "French")
                            (eq current nil)
                            (string-match-p current "british"))
                           "French"
                         "English")))))

(use-package flyspell
  :bind ("C-c f" . flyspell-mode)
  :hook (message-setup . flyspell-mode))

;;----------------------------------------------------------------------------
;; Email
;;----------------------------------------------------------------------------
(use-package message
  :hook ((message-setup . zp/message-flyspell-auto)
         (message-setup . electric-quote-local-mode)
         ;; (message-mode-hook . footnote-mode)
         )
  :config
  (setq message-send-mail-function 'message-send-mail-with-sendmail
        message-sendmail-envelope-from 'header
        message-kill-buffer-on-exit t)

  ;; Enforce f=f in message-mode
  ;; Disabled because it’s bad practice according to the netiquette
  ;; (setq mml-enable-flowed t)
  ;; (defun zp/message-mode-use-hard-newlines ()
  ;;   (use-hard-newlines t 'always))
  ;; (add-hook 'message-mode-hook #'zp/message-mode-use-hard-newlines)

  (defun zp/get-message-signature ()
    (let* ((signature-override
            (concat (file-name-as-directory "~/org/sig")
                    (downcase (message-sendmail-envelope-from))))
           (signature-file
            (if (file-readable-p signature-override)
                signature-override
              "~/.signature")))
      (when (file-readable-p signature-file)
        (with-temp-buffer
          (insert-file-contents signature-file)
          (buffer-string)))))

  (setq message-signature #'zp/get-message-signature
        message-sendmail-envelope-from 'header)

  ;; Set the marks for inserted text with message-mark-inserted-region
  (setq message-mark-insert-begin
        "--------------------------------[START]--------------------------------\n"
        message-mark-insert-end
        "\n---------------------------------[END]---------------------------------")

  ;;------------
  ;; Get emails
  ;;------------

  (defvar zp/email-private (zp/get-string-from-file "~/org/pp/private/email")
    "Email used for private communications.")

  (defvar zp/email-work (zp/get-string-from-file "~/org/pp/work/email")
    "Email used for work-related communications.")

  (defvar zp/email-work-pro (zp/get-string-from-file "~/org/pp/work-pro/email")
    "Email used for work-related communications.")

  (defun zp/get-email-with-alias (email alias &optional regex)
    "Create email alias from EMAIL and ALIAS.

If REGEX is non-nil, creates a regex to match the email alias."
    (let* ((email (cond
                   ((equal email "work")
                    zp/email-work)
                   ((equal email "private")
                    zp/email-private)
                   (t
                    email)))
           (email-alias (replace-regexp-in-string "@"
                                                  (concat "+" alias "@")
                                                  email)))
      (if regex
          (regexp-quote email-alias)
        email-alias)))

  (defvar zp/email-org (zp/get-email-with-alias "work" "org")
    "Email alias used for the org-mode mailing list.")

  (defvar zp/email-dev (zp/get-email-with-alias "work" "dev")
    "Email alias used for general development work.")

  ;;--------------------
  ;; Extended movements
  ;;--------------------

  ;; TODO: Improve

  (defun zp/message-goto-bottom-1 ()
    (let ((newline message-signature-insert-empty-line))
      (goto-char (point-max))
      (when (re-search-backward message-signature-separator nil t)
        (end-of-line (if newline -1 0)))
      (point)))

  (defun zp/message-goto-bottom ()
    "Go to the end of the message or buffer.
Go to the end of the message (before signature) or, if already there, go to the
end of the buffer."
    (interactive)
    (let ((old-position (point))
          (message-position (save-excursion (message-goto-body) (point)))
          (newline message-signature-insert-empty-line))
      (zp/message-goto-bottom-1)
      (when (equal (point) old-position)
        (goto-char (point-max)))))

  (defun zp/message-goto-top-1 ()
    "Go to the beginning of the message."
    (interactive)
    (message-goto-body-1)
    (point))

  (defun zp/message-goto-top ()
    "Go to the beginning of the message or buffer.
Go to the beginning of the message or, if already there, go to the
beginning of the buffer."
    (interactive)
    (let ((old-position (point)))
      (zp/message-goto-top-1)
      (when (equal (point) old-position)
        (goto-char (point-min)))))

  (defun zp/message-goto-body-1 ()
    "Go to the beginning of the body of the message."
    (zp/message-goto-top-1)
    (forward-line 2)
    (point))

  (defun zp/message-goto-body ()
    "Move point to the beginning of the message body."
    (interactive)
    (let ((old-position (point))
          (greeting (save-excursion
                      (zp/message-goto-top-1)
                      (re-search-forward "^[^>]+.*,$" (point-at-eol) t)))
          (modified))
      (zp/message-goto-top-1)
      (cond (greeting
             (forward-line 2))
            ((save-excursion
               (re-search-forward "writes:$" (point-at-eol) t))
             (insert "\n\n")
             (forward-char -2)
             (setq modified t))
            (t
             (insert "\n")
             (forward-char -1)
             (setq modified t)))
      ;; (cond ((re-search-forward "writes:$" (point-at-eol) t)
      ;;        (beginning-of-line)
      ;;        (insert "\n\n")
      ;;        (forward-char -2))
      ;;       ((re-search-forward "^[^>]+.*,$" (line-end-position) t)
      ;;        (zp/message-goto-body-1))
      ;;       (t
      ;;        (insert "\n")
      ;;        (forward-char -1)))
      (when (and (not modified)
                 (equal (point) old-position))
        (zp/message-goto-top-1)
        (goto-char (1- (line-end-position))))))

  (defun zp/message-goto-body-end-1 ()
    (zp/message-goto-bottom-1)
    (re-search-backward "[^[:space:]]")
    (end-of-line)
    (point))

  (defun zp/message-goto-body-end ()
    (interactive)
    (let* ((old-position (point))
           (top-posting (save-excursion
                          (zp/message-goto-top-1)
                          (re-search-forward "writes:$" nil t)
                          (when (< old-position (line-beginning-position 0))
                            (line-beginning-position))))
           (sign-off (save-excursion
                       (or
                        (progn
                          (zp/message-goto-bottom-1)
                          (beginning-of-line)
                          (re-search-forward "^[^>]+.*,$" (line-end-position) t))
                        (and top-posting
                             (progn
                               (goto-char top-posting)
                               (beginning-of-line -1)
                               (re-search-forward "^[^>]+.*,$" (line-end-position) t))))))
           (modified))
      (if sign-off
          (progn
            (goto-char sign-off)
            (beginning-of-line 0)
            (re-search-backward "^[^>[:space:]]+" nil t)
            (end-of-line))
        (cond (top-posting
               (goto-char top-posting)
               (insert "\n\n")
               (forward-char -2)
               (setq modified t))
              (t
               (zp/message-kill-to-signature)
               (unless (bolp) (insert "\n"))
               (insert "\n")
               (setq modified t))))
      (when (and (not modified)
                 (equal (point) old-position))
        (goto-char (1- sign-off)))))

  (defun zp/message-kill-to-signature (&optional arg)
    "Kill all text up to the signature.
If a numeric argument or prefix arg is given, leave that number
of lines before the signature intact."
    (interactive "P")
    (let ((newline message-signature-insert-empty-line))
      (save-excursion
        (save-restriction
          (let ((point (point)))
	    (narrow-to-region point (point-max))
	    (message-goto-signature)
	    (unless (eobp)
	      (if (and arg (numberp arg))
	          (forward-line (- -1 arg))
	        (end-of-line (if newline -2 -1))))
	    (unless (= point (point))
	      (kill-region point (point))
	      (unless (bolp)
	        (insert "\n"))))))))

  (defun zp/message-kill-to-signature (&optional arg)
    (interactive "P")
    (let ((newline message-signature-insert-empty-line)
          (at-end (save-excursion (= (point) (zp/message-goto-bottom-1)))))
      (when at-end
        (error "Already at end"))
      (message-kill-to-signature arg)
      (unless (bolp) (insert "\n"))
      (when newline
        (insert "\n")
        (forward-char -1))))

  ;;------------------------------
  ;; Automatic language detection
  ;;------------------------------

  (setq zp/message-ispell-alist
        `((,zp/email-private . "french")
          (,zp/email-work . "french")
          (,zp/email-work-pro . "french")
          (,zp/email-org . "british")
          (,zp/email-dev . "british")))

  (defun zp/message-flyspell-auto ()
    "Start Ispell with the language associated with the email.

Looks for the email in the ‘From:’ field and chooses a language
based on ‘zp/message-mode-ispell-alist’."
    (let* ((sender (downcase (message-sendmail-envelope-from)))
           (language (cdr (assoc sender zp/message-ispell-alist))))
      (zp/ispell-switch-dictionary language)))

  ;;-------------------
  ;; Unused functions
  ;;-------------------

  ;; TODO: Consider usage

  (defun zp/message-sendmail-envelope-to ()
    "Return the envelope to."
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^To: " nil t)
        (substring-no-properties
         (buffer-substring
          (point)
          (point-at-eol))))))

  (defun zp/message-retrieve-to ()
    "Create a list of emails from ‘To:’."
    (let ((to-raw (zp/message-sendmail-envelope-to))
          (emails))
      (with-temp-buffer
        (insert to-raw)
        (goto-char (point-min))
        (while (< (point) (point-max))
          (let ((bound (save-excursion
                         (if (re-search-forward "," nil t)
                             (progn (forward-char -1)
                                    (point))
                           (point-max)))))
            (re-search-forward "@")
            (if (re-search-backward " " nil t)
                (forward-char)
              (goto-char (point-min)))
            (setq framed (looking-at-p "<"))
            (push (substring-no-properties
                   (buffer-substring (if framed
                                         (1+ (point))
                                       (point))
                                     (if framed
                                         (1- bound)
                                       bound)))
                  emails)
            (goto-char (1+ bound))))
        (setq email-list emails)))))

(use-package sendmail
  :after message
  :config
  (setq send-mail-function 'sendmail-send-it))

(use-package notmuch
  :bind (("H-l" . zp/switch-to-notmuch)
         :map notmuch-hello-mode-map
         ("q" . zp/notmuch-hello-quit)
         :map notmuch-search-mode-map
         ("g" . notmuch-refresh-this-buffer)
         :map notmuch-message-mode-map
         (("C-c C-c" . zp/notmuch-confirm-before-sending)
          ("C-c C-b" . zp/message-goto-body)
          ("C-c C-." . zp/message-goto-body-end)
          ("M-<" . zp/message-goto-top)
          ("M->" . zp/message-goto-bottom)
          ("C-c C-z" . zp/message-kill-to-signature))
         :map notmuch-show-mode-map
         (("C-c C-o" . goto-address-at-point)))
  :hook ((notmuch-hello-refresh . zp/color-inbox)
         (notmuch-hello-refresh . zp/color-inbox-pro))
  :config
  (setq notmuch-always-prompt-for-sender t
        notmuch-search-oldest-first nil)

  (setq notmuch-fcc-dirs
        `((,(regexp-quote zp/email-private) .
           "private/sent -inbox +sent -unread")
          (,(regexp-quote zp/email-work) .
           "work/sent -inbox +sent -unread")
          (,(regexp-quote zp/email-work-pro) .
           "work-pro/sent -inbox +sent -unread")
          (,(regexp-quote zp/email-org) .
           "work/sent -inbox +sent -unread +org")
          (,(regexp-quote zp/email-dev) .
           "work/sent -inbox +sent -unread +dev")))

  (define-key notmuch-search-mode-map "d"
    (lambda (&optional untrash beg end)
      "mark thread as spam"
      (interactive (cons current-prefix-arg (notmuch-interactive-region)))
      (if untrash
          (notmuch-search-tag (list "-deleted"))
        (notmuch-search-tag (list "+deleted" "-inbox")) beg end)
      (notmuch-search-next-thread)))

  (define-key notmuch-show-mode-map "d"
    (lambda (&optional beg end)
      "mark thread as spam"
      (interactive (notmuch-interactive-region))
      (notmuch-show-tag (list "+deleted" "-inbox" "-draft"))
      (notmuch-show-next-thread-show)))


  (define-key notmuch-hello-mode-map "q" #'zp/notmuch-hello-quit)
  (define-key notmuch-search-mode-map "g" #'notmuch-refresh-this-buffer)

  (setq user-full-name "Leo Vivier"
        mail-host-address "hidden")

  (setq notmuch-saved-searches
        '((:name "inbox" :query "tag:inbox" :key "i")
          (:name "inbox (pro)" :query "tag:pro and tag:inbox" :key "I")
          (:name "unread" :query "tag:unread and not tag:inbox" :key "u")
          (:name "flagged" :query "tag:flagged" :key "f")
          (:name "drafts" :query "tag:draft" :key "d")
          (:name "sent (last week)" :query "tag:sent date:\"7d..today\"" :key "s")
          (:name "archive (last week)" :query "* date:\"7d..today\"" :key "a")
          (:name "sent" :query "tag:sent" :key "S")
          (:name "archive" :query "*" :key "A")
          (:name "pro (last week)" :query "tag:pro date:\"7d..today\"" :key "p")
          (:name "pro" :query "tag:pro" :key "P")
          (:name "trash" :query "tag:deleted" :key "t")))

  (defvar zp/message-ispell-alist nil
    "Alist of emails and the language they typically use.
The language should be the name of a valid Ispell dictionary.")

  (defun zp/notmuch-confirm-before-sending (&optional arg)
    (interactive "P")
    (if (y-or-n-p "Ready to send? ")
        (notmuch-mua-send-and-exit arg)))

  ;;------------------------------------------------
  ;; Highlight inbox if it contains unread messages
  ;;------------------------------------------------

  (defun zp/color-inbox-if-unread (inbox &optional search)
    "Color INBOX if SEARCH matches any unread message in inbox.

INBOX is the name of the saved search to highlight.

SEARCH is a string to be interpreted by notmuch-search."
    (interactive)
    (save-excursion
      (goto-char (point-min))
      (let* ((query-base "tag:inbox and tag:unread")
             (query (if search
                        (concat "\("
                                search
                                "\)"
                                " and "
                                "\("
                                query-base
                                "\)")
                      query-base))
             (cnt (car (process-lines "notmuch" "count" query))))
        cnt
        (when (> (string-to-number cnt) 0)
          (when (search-forward inbox (point-max) t)
            (let* ((overlays (overlays-in (match-beginning 0) (match-end 0)))
                   (overlay (car overlays)))
              (when overlay
                (overlay-put overlay 'face '((:inherit bold)
                                             (:foreground "red")
                                             (:underline t))))))))))

  (defun zp/color-inbox ()
    (zp/color-inbox-if-unread "inbox"))

  (defun zp/color-inbox-pro ()
    (zp/color-inbox-if-unread "inbox (pro)" "tag:pro"))

  ;;----------------------
  ;; Switching to notmuch
  ;;----------------------

  (defun zp/notmuch-hello-quit ()
    (interactive)
    (notmuch-bury-or-kill-this-buffer)
    (start-process-shell-command "notmuch-new" nil "systemctl --user start check-mail.service")
    (set-window-configuration zp/notmuch-before-config))

  (defun zp/switch-to-notmuch ()
    (interactive)
    (cond ((string-match "\\*notmuch-hello\\*" (buffer-name))
           (zp/notmuch-hello-quit))
          ((string-match "\\*notmuch-.*\\*" (buffer-name))
           (notmuch-bury-or-kill-this-buffer))
          (t
           (setq zp/notmuch-before-config (current-window-configuration))
           (delete-other-windows)
           (notmuch)))))

(use-package org-notmuch
  :after (:any org notmuch))

(use-package orgalist
  :after message
  :hook (message-setup . orgalist-mode))

;; Disabled because not used
;; (use-package footnote
;;   :config
;;   (setq footnote-section-tag "Footnotes: "))

;;----------------------------------------------------------------------------
;; Programming modes
;;----------------------------------------------------------------------------
(use-package cperl-mode
  :bind (:map cperl-mode-map
              ("M-RET" . zp/perl-eval-buffer)
              ("<C-return>" . zp/perl-eval-region))
  :config
  ;; Use ‘cperl-mode’ instead ‘perl-mode’
  (defalias 'perl-mode 'cperl-mode)

  (defun zp/perl-eval-region ()
    "Run selected region as Perl code"
    (interactive)
    (let ((max-mini-window-height nil))
      (call-process (mark) (point) "perl")))

  (defun zp/perl-eval-buffer-in-terminator ()
    "Run selected region as Perl code"
    (interactive)
    (call-process "terminator" (buffer-file-name) nil nil (concat "-x perl"))
    ;; (call-process (concat "terminator -x perl "
    ;;                       (buffer-file-name)))
    )

  (defun zp/perl-eval-buffer (arg)
    "Run current buffer as Perl code"
    (interactive "P")
    (let (max-mini-window-height)
      (unless arg
        (setq max-mini-window-height 999))
      (shell-command-on-region (point-min) (point-max) "perl"))))

(use-package python
  :bind (:map python-mode-map
              ("M-RET" . zp/python-eval-buffer))
  :config
  (defun zp/inferior-python-mode-config ()
    "Modify keymaps for ‘inferior-python-mode’."
    (local-set-key (kbd "C-l") #'comint-clear-buffer))

  (setq inferior-python-mode-hook 'zp/inferior-python-mode-config)

  (defun zp/python-eval-buffer (arg)
    "Run current buffer as Perl code"
    (interactive "P")
    (let (max-mini-window-height)
      (unless arg
        (setq max-mini-window-height 999))
      (shell-command-on-region (point-min) (point-max) "python")))

  ;; Prototype for something that I’ve now forgotten
  ;; (defun zp/recenter-bottom (arg)
  ;; "Recenter screen at the end of the buffer."
  ;; (interactive "p")
  ;; (let ((inhibit-message t))
  ;;   (goto-char (point-max))
  ;;   (end-of-buffer)
  ;;   (recenter-top-bottom arg)
  ;;   (recenter-top-bottom arg)
  ;;   (scroll-up-line)))
  )

(use-package racket-mode
  :bind (:map racket-mode-map
              ("M-RET" . zp/racket-eval-buffer))
  :config
  (defun zp/racket-eval-buffer (arg)
    "Run current buffer as Perl code"
    (interactive "P")
    (let (max-mini-window-height)
      (unless arg
        (setq max-mini-window-height 999))
      (let ((inhibit-message t))
        (basic-save-buffer))
      (shell-command (concat "racket " (buffer-file-name))))))

;;----------------------------------------------------------------------------
;; AUCTeX
;;----------------------------------------------------------------------------
(use-package latex
  :bind (:map LaTeX-mode-map
              (("C-x n e" . zp/LaTeX-narrow-to-environment)
               ("C-c DEL" . zp/LaTeX-remove-macro)
               ("C-c <C-backspace>" . zp/LaTeX-remove-macro)
               ("C-c <M-backspace>" . zp/LaTeX-remove-environment)
               ("C-c C-t C-v" . zp/tex-view-program-switch)))
  :hook (LaTeX-mode . visual-line-mode)
  :config
  ;; Set default library
  (setq-default TeX-engine 'luatex
                TeX-save-query nil
                TeX-parse-self t
                TeX-auto-save t
                LaTeX-includegraphics-read-file 'LaTeX-includegraphics-read-file-relative)
  (setq reftex-default-bibliography '("~/org/bib/monty-python.bib"))
  ;; (setq reftex-default-bibliography nil)
  (setq warning-suppress-types nil)
  (add-to-list 'warning-suppress-types '(yasnippet backquote-change))

  ;; Used to prevent radio tables from having trailing $
  (setq LaTeX-verbatim-environments '("verbatim" "verbatim*" "comment"))

  (setq LaTeX-csquotes-close-quote "}"
        LaTeX-csquotes-open-quote "\\enquote{")
  (setq TeX-open-quote "\\enquote{"
        TeX-close-quote "}")

  (setq font-latex-fontify-script nil)
  (setq font-latex-fontify-sectioning 'color)

  (set-default 'preview-scale-function 3)

  ;; Enable LaTeX modes for Orgmode
  (add-hook 'LaTeX-mode-hook #'turn-on-reftex)
  (add-hook 'LaTeX-mode-hook #'orgtbl-mode)

  (setq org-latex-logfiles-extensions '("aux" "bcf" "blg" "fdb_latexmk" "fls" "figlist" "idx" "nav" "out" "ptc" "run.xml" "snm" "toc" "vrb" "xdv")
        org-export-async-debug nil)

  (setq reftex-plug-into-AUCTeX t)

  (setq LaTeX-font-list '((1 #1="" #1# "\\mathcal{" "}")
                          (2 "\\textbf{" "}" "\\mathbf{" "}")
                          (3 "\\textsc{" "}")
                          (5 "\\emph{" "}")
                          (6 "\\textsf{" "}" "\\mathsf{" "}")
                          (9 "\\textit{" "}" "\\mathit{" "}")
                          (? "\\underline{" "}")
                          (13 "\\textmd{" "}")
                          (14 "\\textnormal{" "}" "\\mathnormal{" "}")
                          (18 "\\textrm{" "}" "\\mathrm{" "}")
                          (19 "\\textsl{" "}" "\\mathbb{" "}")
                          (20 "\\texttt{" "}" "\\mathtt{" "}")
                          (21 "\\textup{" "}")
                          (4 #1# #1# t)))

  ;; TeX view program
  (defvar zp/tex-view-program nil)

  ;; -----------------------------------------------------------------------------
  ;; Patch submitted to mailing list

  (defcustom TeX-view-pdf-tools-keep-focus nil
    "Whether AUCTeX retains the focus when viewing PDF files with pdf-tools.

When calling `TeX-pdf-tools-sync-view', the pdf-tools buffer
normally captures the focus. If this option is set to non-nil,
the AUCTeX buffer will retain the focus."
    :group 'TeX-view
    :type 'boolean)

  (defun TeX-pdf-tools-sync-view ()
    "Focus the focused page/paragraph in `pdf-view-mode'.
If `TeX-source-correlate-mode' is disabled, only find and pop to
the output PDF file.  Used by default for the PDF Tools viewer
entry in `TeX-view-program-list-builtin'."
    ;; Make sure `pdf-tools' is at least in the `load-path', but the user must
    ;; take care of properly loading and installing the package.  We used to test
    ;; "(featurep 'pdf-tools)", but that doesn't play well with deferred loading.
    (unless (fboundp 'pdf-tools-install)
      (error "PDF Tools are not available"))
    (unless TeX-PDF-mode
      (error "PDF Tools only work with PDF output"))
    (add-hook 'pdf-sync-backward-redirect-functions
              #'TeX-source-correlate-handle-TeX-region)
    (if (and TeX-source-correlate-mode
             (fboundp 'pdf-sync-forward-search))
        (with-current-buffer (or (when TeX-current-process-region-p
                                   (get-file-buffer (TeX-region-file t)))
                                 (current-buffer))
          (pdf-sync-forward-search))
      (let* ((pdf (concat file "." (TeX-output-extension)))
             (buffer (or (find-buffer-visiting pdf)
                         (find-file-noselect pdf))))
        (if TeX-view-pdf-tools-keep-focus
            (display-buffer buffer)
          (pop-to-buffer buffer)))))
  ;; -----------------------------------------------------------------------------

  (setq TeX-view-pdf-tools-keep-focus t)

  (defun zp/tex-view-program-set-pdf-tools ()
    (setq TeX-view-program-selection
          '((output-pdf "PDF Tools"))
          TeX-source-correlate-start-server t
          zp/tex-view-program 'pdf-tools)
    (add-hook 'TeX-after-compilation-finished-functions
              #'TeX-revert-document-buffer))

  (defun zp/tex-view-program-set-evince ()
    (setq TeX-view-program-selection
          '(((output-dvi has-no-display-manager)
             "dvi2tty")
            ((output-dvi style-pstricks)
             "dvips and gv")
            (output-dvi "xdvi")
            (output-pdf "Evince")
            (output-html "xdg-open"))
          TeX-source-correlate-start-server 'ask
          zp/tex-view-program 'evince)
    (remove-hook #'TeX-after-compilation-finished-functions
                 #'TeX-revert-document-buffer))

  (defun zp/tex-view-program-switch ()
    (interactive)
    (cond ((eq zp/tex-view-program 'pdf-tools)
           (zp/tex-view-program-set-evince)
           (message "TeX view program: Evince"))
          ((or (eq zp/tex-view-program 'evince)
               (not (bound-and-true-p zp/tex-view-program)))
           (zp/tex-view-program-set-pdf-tools)
           (message "TeX view program: pdf-tools"))))

  (zp/tex-view-program-set-pdf-tools)

  ;; Update PDF buffers after successful LaTeX runs

  ;; Smart quotes
  (setq org-export-default-language "en-gb"
        org-export-with-smart-quotes t)
  (add-to-list 'org-export-smart-quotes-alist
               '("en-gb"
                 (primary-opening   :utf-8 "‘" :html "&lsquo ;" :latex "\\enquote{"  :texinfo "`")
                 (primary-closing   :utf-8 "’" :html "&rsquo;" :latex "}"           :texinfo "'")
                 (secondary-opening :utf-8 "“" :html "&ldquo;" :latex "\\enquote*{" :texinfo "``")
                 (secondary-closing :utf-8 "”" :html "&rdquo;" :latex "}"           :texinfo "''")
                 (apostrophe        :utf-8 "’" :html "&rsquo;" :latex "'")))

  (defun zp/LaTeX-remove-macro ()
    "Remove current macro and return `t'.  If no macro at point,
return `nil'."
    (interactive)
    (when (TeX-current-macro)
      (let ((bounds (TeX-find-macro-boundaries))
            (brace  (save-excursion
                      (goto-char (1- (TeX-find-macro-end)))
                      (TeX-find-opening-brace))))
        (delete-region (1- (cdr bounds)) (cdr bounds))
        (delete-region (car bounds) (1+ brace)))
      t))

  ;; Source: https://www.reddit.com/r/emacs/comments/5f99nv/help_with_auctex_how_to_delete_an_environment/dailbtu/
  (defun zp/LaTeX-remove-environment ()
    "Remove current environment and return `t'.  If no environment at point,
return `nil'."
    (interactive)
    (when (LaTeX-current-environment)
      (save-excursion
        (let* ((begin-start (save-excursion
                              (LaTeX-find-matching-begin)
                              (point)))
               (begin-end (save-excursion
                            (goto-char begin-start)
                            (search-forward-regexp "begin{.*?}")))
               (end-end (save-excursion
                          (LaTeX-find-matching-end)
                          (point)))
               (end-start (save-excursion
                            (goto-char end-end)
                            (1- (search-backward-regexp "\\end")))))
          ;; delete end first since if we delete begin first it shifts the
          ;; location of end
          (delete-region end-start end-end)
          (delete-region begin-start begin-end)))
      t))

  ;; Movements

  (defvar zp/LaTeX-narrow-previous-positions nil)

  (defun zp/LaTeX-narrow-to-environment (&optional count)
    (interactive "p")
    (LaTeX-narrow-to-environment)
    (LaTeX-mark-environment 1)
    (TeX-pin-region (region-beginning) (region-end))
    (deactivate-mark)
    (move-end-of-line 1)
    (message "Narrowing to enviroment"))

  (defun zp/LaTeX-widen ()
    (interactive)
    (widen)
    (message "Removing narrowing"))

  (defun zp/LaTeX-narrow-forwards (&optional arg)
    (interactive "P")
    (widen)
    (when (search-forward-regexp "^\\\\begin{frame}" nil t)
      (LaTeX-narrow-to-environment)
      (unless arg
        (LaTeX-mark-environment 1)
        (TeX-pin-region (region-beginning) (region-end))
        (deactivate-mark)
        (move-end-of-line 1))
      (message "Narrowing to next frame")))

  (defun zp/LaTeX-narrow-backwards (&optional arg)
    (interactive "P")
    (widen)
    (when (and (search-backward-regexp "^\\\\begin{frame}" nil t)
               (search-backward-regexp "^\\\\begin{frame}" nil t))
      (search-forward-regexp "^\\\\begin{frame}" nil t)
      (LaTeX-narrow-to-environment)
      (unless arg
        (LaTeX-mark-environment 1)
        (TeX-pin-region (region-beginning) (region-end))
        (deactivate-mark)
        (move-end-of-line 1))
      (message "Narrowing to previous frame")))

  (defun zp/LaTeX-narrow-up ()
    (interactive)
    (widen)
    (LaTeX-mark-environment 2)
    (narrow-to-region (region-beginning) (region-end))
    (call-interactively #'narrow-to-region)
    (deactivate-mark)
    (move-end-of-line 1)
    (message "Narrowing to parent environment")))

;;----------------------------------------------------------------------------
;; org → html/tex export
;;----------------------------------------------------------------------------
(use-package ox-html
  :after (org ox)
  :config
  (setq org-html-postamble nil))

(use-package ox-latex
    :after (org ox)
    :config
    (setq org-latex-default-class "koma-article")
    (setq org-latex-compiler "luatex")

    ;; Redefine default classes
    (setq org-latex-classes
          '(("koma-article"
             "\\documentclass[
,a4paper
,DIV=12
,12pt
,abstract
,bibliography=totoc
]{scrartcl}

\\usepackage[
,babel=english
,header=false
,geometry
,autolang=hyphen
,numbers=osf
]{zpart}

\\author{Leo Vivier}"
             ("\\section{%s}" . "\\section*{%s}")
             ("\\subsection{%s}" . "\\subsection*{%s}")
             ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
             ("\\paragraph{%s}" . "\\paragraph*{%s}")
             ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))

    (setq org-latex-hyperref-template nil)

    ;; Use Minted for src-blocks
    (setq org-latex-listings 'minted)

    ;; Disable defaut packages
    (setq org-latex-default-packages-alist nil)

    ;; Legacy code for switching between long and short compilation with XeTeX
    ;; Not using it anymore because I’ve moved to LuaTeX
    ;; (defvar zp/org-latex-pdf-process-mode nil
    ;;     "Current mode for processing org-latex files.

    ;; See ‘zp/toggle-org-latex-pdf-process’ for more information.")

    ;;   (defun zp/toggle-org-latex-pdf-process ()
    ;;     "Toggle the number of steps in the XeTeX PDF process."
    ;;     (interactive)
    ;;     (if (or (not (bound-and-true-p zp/org-latex-pdf-process-mode))
    ;;             (string= zp/org-latex-pdf-process-mode "full"))
    ;;         (progn (setq org-latex-pdf-process '("xelatex -shell-escape\
    ;;                                                   -interaction nonstopmode\
    ;;                                                   -output-directory %o %f")
    ;;                      org-export-async-init-file "~/.emacs.d/async/main-short.el"
    ;;                      zp/org-latex-pdf-process-mode 'short)
    ;;                (message "XeLaTeX process mode: Short"))
    ;;       (progn (setq org-latex-pdf-process '("xelatex -shell-escape\
    ;;                                                     -interaction nonstopmode\
    ;;                                                     -output-directory %o %f"
    ;;                                            "biber %b"
    ;;                                            "xelatex -shell-escape\
    ;;                                                     -interaction nonstopmode\
    ;;                                                     -output-directory %o %f"
    ;;                                            "xelatex -shell-escape\
    ;;                                                     -interaction nonstopmode\
    ;;                                                     -output-directory %o %f")
    ;;                    org-export-async-init-file "~/.emacs.d/async/main-full.el"
    ;;                    zp/org-latex-pdf-process-mode 'full)
    ;;              (message "XeLaTeX process mode: Full"))))
    ;;   (zp/toggle-org-latex-pdf-process)

    ;; Suppress creation of labels when converting org→tex
    (defun remove-orgmode-latex-labels ()
      "Remove labels generated by org-mode"
      (interactive)
      (let ((case-fold-search nil))
        (goto-char 1)
        (replace-regexp "\\\\label{sec:org[0-9][^}]*}" "")))

    (defun zp/org-latex-remove-section-labels (string backend info)
      "Remove section labels generated by org-mode"
      (when (org-export-derived-backend-p backend 'latex)
        (replace-regexp-in-string "\\\\label{sec:.*?}" "" string)))

    (add-to-list #'org-export-filter-final-output-functions
                 #'zp/org-latex-remove-section-labels))

(use-package bibtex
  :config
  (setq bibtex-autokey-year-length '4))

(use-package ox-beamer
  :after (org beamer))

(use-package org-src
  :config
  (setq org-src-preserve-indentation t))

;;----------------------------------------------------------------------------
;; org-mode
;;----------------------------------------------------------------------------
(use-package calendar
  :config
  (setq diary-file "~/diary")

  (calendar-set-date-style 'iso)

  ;; Geo-location
  (setq calendar-week-start-day 1
        calendar-latitude 48.11198
        calendar-longitude -1.67429
        calendar-location-name "Rennes, France")

  (global-set-key (kbd "C-c c") 'calendar))

(use-package org-id
    :config
  (setq org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id))

(use-package org-habit
  :config
  (add-to-list 'org-modules 'org-habit)

  ;; Length of the habit graph
  (setq org-habit-graph-column 50))

(use-package org
  :bind (:map org-mode-map
              ("C-c i" . org-indent-mode)
              ("C-c [" . nil)
              ("C-c ]" . nil)
              ("C-c C-q" . counsel-org-tag)
              ("C-c C-." . org-time-stamp)
              ("C-c C-x r" . zp/org-set-appt-warntime)
              ("C-c C-x l" . zp/org-set-location)
              ("C-c C-x d" . org-delete-property)
              ("C-c C-x D" . org-insert-drawer)
              ("C-c C-x b" . zp/org-tree-to-indirect-buffer-folded)
              ("S-<backspace>" . zp/org-kill-spawned-ibuf)
              ("C-x n o" . zp/org-overview)
              ("C-x n a" . zp/org-show-all)
              ("C-x n u" . zp/org-narrow-up-heading-dwim)
              ("C-x n y" . zp/org-narrow-previous-heading)
              ("C-x n s" . zp/org-narrow-to-subtree)
              ("C-x n f" . zp/org-narrow-forwards)
              ("C-x n b" . zp/org-narrow-backwards)
              ("C-x n w" . zp/org-widen)
              ("C-c ," . zp/hydra-org-priority/body)
              ("M-p" . org-metaup)
              ("M-n" . org-metadown)
              ("M-P" . org-shiftmetaup)
              ("M-N" . org-shiftmetadown)
              ("M-[" . org-metaleft)
              ("M-]" . org-metaright)
              ("M-{" . org-shiftmetaleft)
              ("M-}" . org-shiftmetaright)
              ("C-a" . org-beginning-of-line)
              ("C-e" . org-end-of-line)
              ("M-I" . org-indent-mode)
              ("M-*" . zp/org-toggle-fontifications)
              ("C-c C-x C-l" . zp/org-latex-preview-dwim)
              ("C-c R" . org-display-inline-images))
  :config
  (setq org-agenda-inhibit-startup nil
        org-log-into-drawer "LOGBOOK-NOTES"
        org-use-property-inheritance '("AGENDA_GROUP")
        org-log-state-notes-insert-after-drawers nil
        org-special-ctrl-a/e 't
        org-log-done 'time
        org-enforce-todo-dependencies nil
        org-adapt-indentation nil

        org-clock-report-include-clocking-task t
        org-clock-out-remove-zero-time-clocks t

        org-hide-emphasis-markers t
        org-ellipsis "…"
        org-track-ordered-property-with-tag "ORDERED"
        org-tags-exclude-from-inheritance nil
        org-catch-invisible-edits 'error

        org-tags-column -77)

  ;; org-refile settings
  (setq org-refile-targets '((nil :maxlevel . 9))
        org-refile-use-cache nil
        org-outline-path-complete-in-steps nil
        org-refile-use-outline-path nil)

  ;; Ensure that images can be resized with deferred #+ATTR_ORG:
  (setq org-image-actual-width nil)

  ;; Prevent auto insertion of blank-lines before heading (but not for lists)
  (setq org-blank-before-new-entry (quote ((heading)
                                           (plain-list-item . auto))))

  ;; Prevent blank-lines from being displayed between headings in folded state
  (setq org-cycle-separator-lines 0)

  ;; Add curly quotes to list of pre- and post-matches for emphasis markers
  ;; Otherwise, curly quotes prevent fontification
  (setq org-emphasis-regexp-components '("-       ('‘\"“’{" "-    .,:!?;'’\"”)}\\[" "     
" "." 1))

  ;; Set the default apps to use when opening org-links
  (add-to-list 'org-file-apps
               '("\\.pdf\\'" . (lambda (file link)
                                 (org-pdfview-open link))))

  ;; Define TODO keywords
  (setq org-todo-keywords
        '(;; Default set
          (sequence "TODO(t)" "NEXT(n)" "STRT(S!)" "|" "DONE(d)")
          ;; Extra sets
          (sequence "STBY(s)" "|" "CXLD(x@/!)")
          (sequence "WAIT(w!)" "|" "CXLD(x@/!)")))

  ;; State triggers
  (setq org-todo-state-tags-triggers
        '(("CXLD" ("cancelled" . t) ("standby") ("waiting"))
          ("STBY" ("standby" . t) ("cancelled") ("waiting"))
          ("WAIT" ("waiting" . t) ("cancelled") ("standby"))
          ("TODO" ("cancelled") ("standby") ("waiting"))
          ("NEXT" ("cancelled") ("standby") ("waiting"))
          ("STRT" ("cancelled") ("standby") ("waiting"))
          ("WAIT" ("cancelled") ("standby") ("waiting"))
          ("DONE" ("cancelled") ("standby") ("waiting"))
          ("" ("cancelled") ("standby") ("waiting")))
        ;; Custom faces for specific tags
        org-tag-faces
        '(("@home" . org-tag-context)
          ("@work" . org-tag-context)
          ("@town" . org-tag-context)
          ("standby" . org-tag-standby)
          ("routine" . org-tag-routine)
          ("boring" . org-tag-special)
          ("cancelled" . org-tag-standby)
          ("waiting" . org-tag-standby)
          ("assignment" . org-tag-important)
          ("exam" . org-tag-important)
          ("important" . org-tag-important)
          ("more" . org-tag-important)
          ("curios" . org-tag-curios)
          ("french" . org-tag-french)))

  ;; Set characters used for priorities
  (setq org-highest-priority ?A
        org-default-priority ?D
        org-lowest-priority ?E)

  ;; Default settings for ‘org-columns’
  (setq org-columns-default-format "%55ITEM(Task) %TODO(State) %Effort(Effort){:} %CLOCKSUM")

  ;; Global values for properties
  (setq org-global-properties (quote (("Effort_ALL" . "0:05 0:10 0:15 0:30 0:45 1:00 1:30 2:00 2:30 3:00 3:30 4:00 4:30 5:00 5:30 6:00 0:00")
                                      ("STYLE_ALL" . "habit")
                                      ("APPT_WARNTIME_ALL" . "0 5 10 15 20 25 30 35 40 45 50 55 60 none")
                                      ("SESSION_DURATION_ALL" . "0:45 0:15 0:20 0:30 1:00"))))

  ;; Archiving location
  (setq org-archive-location "%s.archive::")

  ;; Keep hierarchy when archiving
  ;; Source: https://fuco1.github.io/2017-04-20-Archive-subtrees-under-the-same-hierarchy-as-original-in-the-archive-files.html
  (defadvice org-archive-subtree (around fix-hierarchy activate)
    (let* ((fix-archive-p (and (not current-prefix-arg)
                               (not (use-region-p))))
           (location (org-archive--compute-location
                      (or (org-entry-get nil "ARCHIVE" 'inherit)
                          org-archive-location)))
           (afile (car location))
           (buffer (or (find-buffer-visiting afile) (find-file-noselect afile))))
      ad-do-it
      (when fix-archive-p
        (with-current-buffer buffer
          (goto-char (point-max))
          (while (org-up-heading-safe))
          (let* ((olpath (org-entry-get (point) "ARCHIVE_OLPATH"))
                 (path (and olpath (split-string olpath "/")))
                 (level 1)
                 tree-text)
            (when olpath
              (org-mark-subtree)
              (setq tree-text (buffer-substring (region-beginning) (region-end)))
              (let (this-command) (org-cut-subtree))
              (goto-char (point-min))
              (save-restriction
                (widen)
                (-each path
                  (lambda (heading)
                    (if (re-search-forward
                         (rx-to-string
                          `(: bol (repeat ,level "*") (1+ " ") ,heading)) nil t)
                        (org-narrow-to-subtree)
                      (goto-char (point-max))
                      (unless (looking-at "^")
                        (insert "\n"))
                      (insert (make-string level ?*)
                              " "
                              heading
                              "\n"))
                    (cl-incf level)))
                (widen)
                (org-end-of-subtree t t)
                (org-paste-subtree level tree-text))))))))

  ;; LaTeX export
  (defvar zp/org-format-latex-default-scale 3.0
    "Initial value for the scale of LaTeX previews.")

  ;; Formatting options for LaTeX preview-blocks
  (setq org-format-latex-options
        '(:foreground default
                      :background default
                      :scale zp/org-format-latex-default-scale
                      :html-foreground "Black"
                      :html-background "Transparent"
                      :html-scale 1.0
                      :matchers ("begin" "$1" "$" "$$" "\\(" "\\[")))

  (defun zp/org-latex-preview-dwim (arg)
    "Run org-latex-preview after updating the scale."
    (interactive "P")
    (let* ((default-scale 3)
           (scale-amount (or (and (boundp 'text-scale-mode-amount)
                                  text-scale-mode-amount)
                             0))
           (new-scale (+ default-scale scale-amount)))
      (setq-local org-format-latex-options
                  (plist-put org-format-latex-options :scale new-scale))
      (org-latex-preview arg)))

  ;; Load languages with Babel
  (org-babel-do-load-languages 'org-babel-load-languages
                               '((R . t)
                                 (python . t)
                                 (latex . t)
                                 (ledger . t)
                                 (shell . t)))

  ;; Show images after executing a src-block that generated one
  ;; TODO: Limit the scope of the hook by testing if the block actually
  ;; generated an image
  (add-hook 'org-babel-after-execute-hook #'org-display-inline-images 'append)

  ;; Load library required for PlantUML
  (setq org-ditaa-jar-path "/usr/share/java/ditaa/ditaa-0.11.jar")

  ;;------
  ;; Handling ‘CREATED’
  ;;------

  (defvar zp/org-created-property-name "CREATED"
    "The name of the org-mode property that stores the creation date of the entry")

  ;; TODO: Find the source for this because I’ve improved something which
  ;; already existed
  (defun zp/org-set-created-property (&optional active name)
    "Set a property on the entry giving the creation time.

By default the property is called CREATED. If given, the ‘NAME’
argument will be used instead. If the property already exists, it
will not be modified.

If the function sets CREATED, it returns its value."
    (interactive)
    (let* ((created (or name zp/org-created-property-name))
           (fmt (if active "<%s>" "[%s]"))
           (now (format fmt (format-time-string "%Y-%m-%d %a %H:%M"))))
      (unless (org-entry-get (point) created nil)
        (org-set-property created now)
        now)))

  ;;------------------------
  ;; Narrowing & Movements
  ;;------------------------

  (defvar zp/org-after-view-change-hook nil
    "Hook run after a significant view change in org-mode.")

  (defun zp/org-overview (&optional arg keep-position keep-restriction)
    "Switch to overview mode, showing only top-level headlines.

With a ‘C-u’ prefix, do not move point.

When KEEP-RESTRICTION is non-nil, do not widen the buffer."
    (interactive "p")
    (let ((pos-before (point))
          (indirect (not (buffer-file-name)))
          (narrowed (buffer-narrowed-p)))
      (setq-local zp/org-narrow-previous-position pos-before)
      ;; Do not widen buffer if in indirect buffer
      (save-excursion
        (goto-char (point-min))
        (widen)
        (when (or (and indirect
                       narrowed)
                  keep-restriction)
          (org-narrow-to-subtree))
        (unless indirect
          (org-display-inline-images)))
      (zp/org-fold (or keep-position
                       (and arg
                            (> arg 1))))
      (when arg
        (message "Showing overview.")
        (run-hooks 'zp/org-after-view-change-hook))))

  (defun zp/org-fold (&optional keep-position)
    (let ((indirectp (not (buffer-file-name)))
          (org-startup-folded 'overview))
      ;; Fold drawers
      (org-set-startup-visibility)
      ;; Fold trees
      (org-overview)
      (unless keep-position
        (goto-char (point-min)))
      (recenter)
      (save-excursion
        (goto-char (point-min))
        (org-show-entry)
        (when (org-at-heading-p)
          (org-show-children)))))

  (defun zp/org-show-all (arg)
    (interactive "p")
    (let ((pos-before (point))
          (indirect (not (buffer-file-name))))
      (setq-local zp/org-narrow-previous-position pos-before)
      ;; Do not widen buffer if in indirect buffer
      (unless indirect
        (widen)
        (org-display-inline-images))
      ;; Unfold everything
      (org-show-all)
      (unless (eq arg 4)
        (goto-char (point-min)))
      (recenter-top-bottom)
      (when arg
        (message "Showing everything.")
        (run-hooks 'zp/org-after-view-change-hook))))

  ;; org-narrow movements

  (defun zp/org-narrow-to-subtree ()
    "Move to the next subtree at same level, and narrow the buffer to it."
    (interactive)
    (org-narrow-to-subtree)
    (zp/org-fold nil)
    (when (called-interactively-p 'any)
      (message "Narrowing to tree at point.")
      (run-hooks 'zp/org-after-view-change-hook)))

  (defun zp/org-widen ()
    "Move to the next subtree at same level, and narrow the buffer to it."
    (interactive)
    (let ((pos-before (point)))
      (setq-local zp/org-narrow-previous-position pos-before))
    (widen)
    (when (called-interactively-p 'any)
      (message "Removing narrowing.")
      (run-hooks 'zp/org-after-view-change-hook)))

  (defun zp/org-narrow-forwards ()
    "Move to the next subtree at same level, and narrow the buffer to it."
    (interactive)
    (widen)
    (org-forward-heading-same-level 1)
    (org-narrow-to-subtree)
    (zp/org-fold nil)
    (when (called-interactively-p 'any)
      (message "Narrowing to next tree.")
      (run-hooks 'zp/org-after-view-change-hook)))

  (defun zp/org-narrow-backwards ()
    "Move to the next subtree at same level, and narrow the buffer to it."
    (interactive)
    (widen)
    (org-backward-heading-same-level 1)
    (org-narrow-to-subtree)
    (zp/org-fold nil)
    (when (called-interactively-p 'any)
      (message "Narrowing to previous tree.")
      (run-hooks 'zp/org-after-view-change-hook)))

  (defun zp/org-narrow-up-heading (&optional arg keep-position)
    "Move to the upper subtree, and narrow the buffer to it."
    (interactive "p")
    (unless (buffer-narrowed-p)
      (user-error "No narrowing"))
    (let ((pos-before (point)))
      (setq-local zp/org-narrow-previous-position pos-before)
      (widen)
      (org-reveal)
      (outline-up-heading 1)
      (org-narrow-to-subtree)
      (when (or (eq arg 4)
                keep-position)
        (goto-char pos-before)
        (recenter-top-bottom))
      (zp/org-fold (or (eq arg 4)
                       keep-position))
      (when arg
        (message "Narrowing to tree above.")
        (run-hooks 'zp/org-after-view-change-hook))))

  (defun zp/org-narrow-up-heading-dwim (arg)
    "Narrow to the upper subtree, and narrow the buffer to it.

If the buffer is already narrowed to level-1 heading, overview
the entire buffer."
    (interactive "p")
    (if (save-excursion
          ;; Narrowed to a level-1 heading?
          (goto-char (point-min))
          (and (buffer-narrowed-p)
               (equal (org-outline-level) 1)))
        (zp/org-overview arg)
      (zp/org-narrow-up-heading arg)))

  (defun zp/org-narrow-previous-heading (arg)
    "Move to the previously narrowed tree, and narrow the buffer to it."
    (interactive "p")
    (if (bound-and-true-p zp/org-narrow-previous-position)
        (let ((pos-before zp/org-narrow-previous-position))
          (goto-char zp/org-narrow-previous-position)
          (org-reveal)
          (org-cycle)
          (org-narrow-to-subtree)
          (setq zp/org-narrow-previous-position nil)
          (message "Narrowing to previously narrowed tree."))
      (message "Couldn’t find a previous position.")))

  ;; Toggle fontifications
  (defun zp/org-toggle-emphasis-markers (&optional arg)
    "Toggle emphasis markers."
    (interactive "p")
    (let ((markers org-hide-emphasis-markers))
      (if markers
          (setq-local org-hide-emphasis-markers nil)
        (setq-local org-hide-emphasis-markers t))
      (when arg
        (font-lock-fontify-buffer))))

  (defun zp/org-toggle-link-display (&optional arg)
    "Toggle the literal or descriptive display of links in the current buffer."
    (interactive "p")
    (if org-link-descriptive (remove-from-invisibility-spec '(org-link))
      (add-to-invisibility-spec '(org-link)))
    (setq-local org-link-descriptive (not org-link-descriptive))
    (when arg
      (font-lock-fontify-buffer)))

  (defun zp/org-toggle-fontifications (&optional arg)
    "Toggle emphasis markers or the link display.

Without a C-u argument, toggle the emphasis markers.

With a C-u argument, toggle the link display."
    (interactive "P")
    (let ((markers org-hide-emphasis-markers)
          (links org-link-descriptive))
      (if arg
          (zp/org-toggle-link-display)
        (zp/org-toggle-emphasis-markers))
      (font-lock-fontify-buffer)))

  ;;--------------------------------
  ;; Customise exported timestamps
  ;;--------------------------------

  (add-to-list 'org-export-filter-timestamp-functions
               #'endless/filter-timestamp)
  (defun endless/filter-timestamp (trans back _comm)
    "Remove <> around time-stamps."
    (pcase back
      ((or `jekyll `html)
       (replace-regexp-in-string "&[lg]t;" "" trans))
      (`latex
       (replace-regexp-in-string "[<>]" "" trans))))

  (setq org-time-stamp-custom-formats
        '("<%d %b %Y>" . "<%d/%m/%y %a %H:%M>"))

  ;;--------------------------
  ;; Spawned indirect buffers
  ;;--------------------------

  (defun zp/org-tree-to-indirect-buffer-folded (arg &optional dedicated bury)
    "Clone tree to indirect buffer in a folded state.

When called with a ‘C-u’ prefix or when DEDICATED is non-nil,
create a dedicated frame."
    (interactive "p")
    (let* ((in-new-window (and arg
                               (one-window-p)))
           (org-indirect-buffer-display (if in-new-window
                                            'other-window
                                          'current-window))
           (last-ibuf org-last-indirect-buffer)
           (parent (current-buffer))
           (parent-window (selected-window))
           (dedicated (or dedicated
                          (eq arg 4))))
      (when dedicated
        (setq org-last-indirect-buffer nil))
      (when (and arg
                 zp/org-spawned-ibuf-mode)
        (zp/org-ibuf-spawned-dedicate))
      (org-tree-to-indirect-buffer)
      (when in-new-window
        (select-window (next-window))
        (setq zp/org-ibuf-spawned-also-kill-window parent-window))
      (if dedicated
          (setq org-last-indirect-buffer last-ibuf)
        (zp/org-spawned-ibuf-mode t))
      (when bury
        (switch-to-buffer parent nil t)
        (bury-buffer))
      (let ((org-startup-folded nil))
        (org-set-startup-visibility))
      (org-overview)
      (org-show-entry)
      (org-show-children)
      (prog1 (selected-window)
        (when arg
          (message "Cloned tree to indirect buffer.")
          (run-hooks 'zp/org-after-view-change-hook)))))

  (defun zp/org-kill-spawned-ibuf (&optional arg)
    "Kill the current buffer if it is an indirect buffer."
    (interactive "p")
    (let* ((other (not (one-window-p)))
           (indirect (buffer-base-buffer))
           (spawn zp/org-spawned-ibuf-mode)
           (parent-window zp/org-ibuf-spawned-also-kill-window))
      (unless (and indirect
                   spawn)
        (user-error "Not a spawned buffer"))
      (if (and other
               parent-window)
          (progn (kill-buffer-and-window)
                 ;; Select parent when called interactively
                 (when arg
                   (select-window parent-window)))
        (kill-buffer))
      (when arg
        (message "Killed indirect buffer."))
      (run-hooks 'zp/org-after-view-change-hook)))

  (defun zp/org-ibuf-spawned-dedicate (&optional print-message)
    (unless (and (boundp zp/org-spawned-ibuf-mode) zp/org-spawned-ibuf-mode)
      (user-error "Not in a spawned buffer"))
    (zp/org-spawned-ibuf-mode -1)
    (setq org-last-indirect-buffer nil)
    (setq header-line-format nil)
    (when print-message
      (message "Buffer is now dedicated.")))

  (defun zp/org-kill-spawned-ibuf-dwim (&optional dedicate)
    "Kill the current buffer if it is an indirect buffer.

With a ‘C-u’ argument, dedicate the buffer instead."
    (interactive "P")
    (if dedicate
        (zp/org-ibuf-spawned-dedicate t)
      (zp/org-kill-spawned-ibuf t)))

  (defvar-local zp/org-ibuf-spawned-also-kill-window nil
    "When t, also kill the window when killing a spawned buffer.

A spawned buffer is an indirect buffer created by
‘org-tree-to-indirect-buffer’ which will be replaced by
subsequent calls.")

  (defvar zp/org-spawned-ibuf-mode-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "C-c C-k") #'zp/org-kill-spawned-ibuf-dwim)
      map)
    "Keymap for ‘zp/org-spawned-ibuf-mode’.")

  (define-minor-mode zp/org-spawned-ibuf-mode
    "Show when the current indirect buffer is a spawned buffer."
    :lighter " Spawn"
    :keymap zp/org-spawned-ibuf-mode-map
    (setq header-line-format
          "Spawned indirect buffer.  Kill with ‘C-c C-k’, dedicate with ‘C-u C-c C-k’.")))

(use-package org-footnote
  :config
  (setq org-footnote-define-inline 1))

(use-package org-clock
  :config
  (setq org-clock-into-drawer "LOGBOOK-CLOCK"
        org-clock-sound t)

  (defun zp/echo-clock-string ()
    "Echo the tasks being currently clocked in the minibuffer,
along with effort estimates and total time."
    (interactive)
    (if (org-clocking-p)
        (let ((header "Current clock")
              (clocked-time (org-clock-get-clocked-time))
              (org-clock-heading-formatted (replace-regexp-in-string "%" "%%"org-clock-heading)))
          (if org-clock-effort
              (let* ((effort-in-minutes (org-duration-to-minutes org-clock-effort))
                     (work-done-str
                      (propertize (org-duration-from-minutes clocked-time)
                                  'face
                                  (if (and org-clock-task-overrun
                                           (not org-clock-task-overrun-text))
                                      'org-mode-line-clock-overrun
                                    'org-meta-line)))
                     (effort-str (org-duration-from-minutes effort-in-minutes)))
                (message (concat
                          header ": "
                          (format (propertize "[%s/%s] (%s)" 'face 'org-meta-line)
                                  work-done-str effort-str org-clock-heading-formatted))))
            (message (concat
                      header ": "
                      (format (propertize "[%s] (%s)" 'face 'org-meta-line)
                              (org-duration-from-minutes clocked-time)
                              org-clock-heading-formatted)))))
      (error "Not currently clocking any task.")))

  ;;------
  ;; Keys
  ;;------

  ;; Clocking commands
  (global-set-key (kbd "C-c C-x C-j") #'org-clock-goto)
  (global-set-key (kbd "C-c C-x C-i") #'org-clock-in)
  (global-set-key (kbd "C-c C-x C-o") #'org-clock-out)
  (global-set-key (kbd "C-c C-x C-z") #'org-resolve-clocks)

  (global-set-key (kbd "H-/") 'zp/echo-clock-string))

;; Enable resetting plain-list checks when marking a repeated tasks DONE
;; To enable that behaviour, set the ‘RESET_CHECK_BOXES’ property to t for the
;; parent
(use-package org-checklist)

(use-package org-faces
  :config
  ;; Assign faces to priorities
  (setq org-priority-faces '((?A . (:inherit org-priority-face-a))
                             (?B . (:inherit org-priority-face-b))
                             (?C . (:inherit org-priority-face-c))
                             (?D . (:inherit org-priority-face-d))
                             (?E . (:inherit org-priority-face-e))))

  ;; Assign faces for TODO keywords
  (setq org-todo-keyword-faces
        '(("TODO" :inherit org-todo-todo)
          ("NEXT" :inherit org-todo-next)
          ("STRT" :inherit org-todo-strt)
          ("DONE" :inherit org-todo-done)

          ("STBY" :inherit org-todo-stby)
          ("WAIT" :inherit org-todo-wait)
          ("CXLD" :inherit org-todo-cxld)))

  ;;-----------------
  ;; Face definition
  ;;-----------------

  ;; TODO: Optimise

  (defface org-todo-todo '((t)) nil)
  (defface org-todo-next '((t)) nil)
  (defface org-todo-strt '((t)) nil)
  (defface org-todo-done '((t)) nil)
  (defface org-todo-stby '((t)) nil)
  (defface org-todo-wait '((t)) nil)
  (defface org-todo-cxld '((t)) nil)

  (defface org-priority-face-a '((t)) nil)
  (defface org-priority-face-b '((t)) nil)
  (defface org-priority-face-c '((t)) nil)
  (defface org-priority-face-d '((t)) nil)
  (defface org-priority-face-e '((t)) nil)

  (defface org-tag-context '((t :inherit 'org-tag)) nil)
  (defface org-tag-special '((t :inherit 'org-tag)) nil)
  (defface org-tag-standby '((t :inherit 'org-tag)) nil)
  (defface org-tag-routine '((t :inherit 'org-tag-standby)) nil)
  (defface org-tag-important '((t :inherit 'org-tag)) nil)
  (defface org-tag-curios '((t :inherit 'org-tag)) nil)
  (defface org-tag-french '((t :inherit 'org-tag)) nil))

;; Babel
(use-package ob-async
  :config
  (add-hook 'ob-async-pre-execute-src-block-hook
            (lambda ()
              (setq org-ditaa-jar-path "/usr/share/java/ditaa/ditaa-0.11.jar"))))

;;----------------------------------------------------------------------------
;; Helm
;;----------------------------------------------------------------------------
(define-prefix-command 'zp/helm-map)
(global-set-key (kbd "C-c h") 'zp/helm-map)
(use-package helm
  :bind (("M-x" . helm-M-x)
         ("<menu>" . helm-M-x)
         ("M-y" . helm-show-kill-ring)
         ("C-x b" . helm-mini)
         ("C-x C-b" . helm-mini)
         ("C-x C-f" . helm-find-files)
         ("M-s M-s" . helm-occur)
         ("C-x r b" . helm-bookmarks)
         ("C-h C-SPC" . helm-all-mark-rings)
         ("C-h a" . helm-apropos)
         :map helm-map
         ("C-S-o" . helm-previous-source)
         :map zp/helm-map
         (("o" . helm-occur)
          ("f" . helm-find-files)
          ("r" . helm-regexp)
          ("x" . helm-register)
          ("b" . helm-resume)
          ("c" . helm-colors)
          ("M-:" . helm-eval-expression-with-eldoc)
          ("i" . helm-semantic-or-imenu)
          ("/" . helm-find)
          ("<tab>" . helm-lisp-completion-at-point)
          ("p" . helm-projectile)))
  :config
  ;; Increase truncation of buffer names
  (setq helm-buffer-max-length 30                 ;Default: 20
        helm-M-x-fuzzy-match t
        helm-buffers-fuzzy-matching t
        helm-recentf-fuzzy-match t
        helm-semantic-fuzzy-match t
        helm-imenu-fuzzy-match t
        helm-mode-fuzzy-match t
        helm-completion-in-region-fuzzy-match t
        helm-apropos-fuzzy-match t
        helm-lisp-fuzzy-completion t)

  ;; Disable helm-mode for some functions
  ;; Used to be necessary, but now it works just fine
  ;; (add-to-list 'helm-completing-read-handlers-alist '(org-set-property)))
  )

;;----------------------------------------------------------------------------
;; Ivy
;;----------------------------------------------------------------------------
(use-package ivy
  :config
  (ivy-mode 1)
  (setq ivy-height 10                   ;Default
        ivy-use-virtual-buffers t
        ivy-count-format "(%d/%d) ")

  (global-set-key (kbd "C-c C-r") 'ivy-resume)
  (global-set-key (kbd "<f6>") 'ivy-resume)

  ;; Commented because I use Helm for those commands
  ;; (global-set-key (kbd "C-x C-b") 'ivy-switch-buffer)
  )

(use-package swiper
  :config
  ;; Commented because I now use counsel-grep-or-swiper
  ;; (global-set-key "\C-s" #'swiper)
  )

(use-package counsel
  :after swiper
  :bind (("C-s" . zp/counsel-grep-or-swiper)
         ("C-r" . counsel-grep-or-swiper-backward)
         ;; Commented because I use the Helm equivalents
         ;; ("M-x" . counsel-M-x)
         ;; ("<menu>" . counsel-M-x)
         ;; ("C-x C-f" . counsel-find-file)
         ;; ("C-c j" . counsel-git-grep)
         ;; Commented because unused
         ;; ("C-c g" . counsel-git)
         ;; ("C-c k" . counsel-ag)
         ;; ("C-x l" . counsel-locate)
         ;; ("C-S-o" . counsel-rhythmbox)
         :map minibuffer-local-map
         ("C-r" . counsel-minibuffer-history))
  :requires swiper
  :config
  (setq counsel-find-file-at-point t)

  ;; Use rg insted of grep
  (setq counsel-grep-base-command "rg -i -M 120 --no-heading --line-number --color never %s %s")

  (defun zp/counsel-grep-or-swiper (&optional arg)
    "Call ‘swiper’ for small buffers and ‘counsel-grep’ for large ones.
Wrapper to always use swiper for gpg-encrypted files and
indirect-buffers."
    (interactive "P")
    (let* ((file (buffer-file-name))
           (ext (if file (file-name-extension file))))
      (if (or (equal arg '(4))                    ;Forcing?
              (not file)                          ;Indirect buffer?
              (string= ext "gpg"))                ;Encrypted buffer?
          (swiper)
        (counsel-grep-or-swiper)))))

;;----------------------------------------------------------------------------
;; Hydra
;;----------------------------------------------------------------------------
(use-package hydra)

(use-package hydra-org-priority
  :requires (org hydra))

;;----------------------------------------------------------------------------
;; org-super-agenda
;;----------------------------------------------------------------------------
(use-package org-super-agenda
  :load-path "~/projects/forks/org-super-agenda/"
  :after org-agenda
  :config
  (org-super-agenda-mode)

  (setq org-super-agenda-header-separator "")

  (defun zp/org-super-agenda-update-face ()
    (let ((ul-color (internal-get-lisp-face-attribute
                     'font-lock-comment-face :foreground)))
      (set-face-attribute 'org-super-agenda-header nil
                          :slant 'italic
                          :underline `(:color ,ul-color))))

  (defun zp/org-super-agenda-item-in-agenda-groups-p (item groups)
    "Check if ITEM is in agenda GROUPS."
    (let ((marker (or (get-text-property 0 'org-marker item)
                      (get-text-property 0 'org-hd-marker item))))
      (org-with-point-at marker
        (apply #'zp/org-task-in-agenda-groups-p groups))))

  (defun zp/org-super-agenda-groups (header groups)
    "Create org-super-agenda section for GROUPS with HEADER."
    `(:name ,header
            :pred (lambda (item)
                    (zp/org-super-agenda-item-in-agenda-groups-p item ',groups))))

  (defun zp/org-super-agenda-groups-all ()
    `(,(zp/org-super-agenda-groups "Inbox" '("inbox"))
      ,(zp/org-super-agenda-groups "Life" '("life"))
      ,(zp/org-super-agenda-groups "Maintenance" '("mx"))
      ,(zp/org-super-agenda-groups "Professional" '("pro"))
      ,(zp/org-super-agenda-groups "Research" '("research"))
      ,(zp/org-super-agenda-groups "Activism" '("act"))
      ,(zp/org-super-agenda-groups "Hacking" '("hack"))
      ,(zp/org-super-agenda-groups "Curiosities" '("curios"))
      ,(zp/org-super-agenda-groups "Media" '("media"))))

  (defun zp/org-super-agenda-subtask-p (item)
    (let ((marker (or (get-text-property 0 'org-marker item)
                      (get-text-property 0 'org-hd-marker item))))
      (org-with-point-at marker
        (zp/is-subtask-p))))

  (defun zp/org-super-agenda-scheduled ()
    '((:name "Past appointments"
             :face (:foreground "red")
             :timestamp past)
      (:name "Overdue"
             :face (:foreground "red")
             :scheduled past)
      (:name "Waiting"
             :and (:tag "waiting"
                        :scheduled nil)
             :and (:tag "waiting"
                        :scheduled today))
      (:name "Appointments"
             :timestamp today)
      (:name "Scheduled"
             :scheduled today)
      (:name "Subtasks"
             :and (:scheduled nil
                              :timestamp nil
                              :pred (lambda (item)
                                      (when zp/org-agenda-split-subtasks
                                        (zp/org-super-agenda-subtask-p item)))))
      (:name "Current"
             :and (:not (:scheduled t :timestamp t)
                        :not (:tag "waiting")))
      (:name "Later"
             :anything)))

  (defun zp/org-super-agenda-group-heads (item)
    (let ((marker (or (get-text-property 0 'org-marker item)
                      (get-text-property 0 'org-hd-marker item))))
      (org-entry-get marker "AGENDA_GROUP" nil)))

  (defun zp/org-super-agenda-stuck-project-p (item)
    (let ((marker (or (get-text-property 0 'org-marker item)
                      (get-text-property 0 'org-hd-marker item))))
      (org-with-point-at marker
        (zp/is-stuck-project-p))))

  (defun zp/org-super-agenda-projects ()
    '((:name "Group heads"
             :pred (lambda (item)
                     (zp/org-super-agenda-group-heads item)))
      (:name "Stuck"
             :face (:foreground "red")
             :pred (lambda (item)
                     (zp/org-super-agenda-stuck-project-p item)))
      (:name "Waiting"
             :tag "waiting")
      (:name "Current"
             :anything))))

;;----------------------------------------------------------------------------
;; org-agenda
;;----------------------------------------------------------------------------
(use-package zp-org-agenda
  :bind (("H-o" . zp/switch-to-agenda)
         :map org-agenda-mode-map
         (("M-n" . org-agenda-next-date-line)
          ("M-p" . org-agenda-previous-date-line)
          ("C-," . sunrise-sunset)
          ("C-c C-q" . counsel-org-tag-agenda)
          (":" . counsel-org-tag-agenda)
          ("," . zp/hydra-org-priority/body)
          ("M-h" . zp/toggle-org-habit-show-all-today)
          ("M-i" . zp/toggle-org-agenda-category-icons)
          ("M-t" . org-agenda-todo-yesterday)
          ("D" . zp/toggle-org-agenda-include-deadlines)
          ("S" . zp/toggle-org-agenda-include-scheduled)
          ("K" . zp/toggle-org-agenda-include-routine)
          ("H" . zp/toggle-org-agenda-include-habits)
          ("E" . zp/toggle-org-agenda-show-all-dates)
          ("Y" . zp/toggle-org-agenda-include-projects)
          ("M-d" . zp/toggle-org-deadline-warning-days-range)
          ("r" . zp/org-agenda-benchmark)
          ("R" . zp/org-agenda-garbage-collect)
          ("G" . zp/org-agenda-wipe-local-config)
          ("y" . zp/toggle-org-agenda-split-subtasks)
          ("i" . zp/toggle-org-agenda-sorting-strategy-special-first)
          ("o" . zp/toggle-org-agenda-sort-by-rev-fifo)
          ("F" . zp/toggle-org-agenda-todo-ignore-future)
          ("W" . zp/toggle-org-agenda-projects-include-waiting)
          ("C-c C-x r" . zp/org-agenda-set-appt-warntime)
          ("C-c C-x l" . zp/org-agenda-set-location)
          ("C-c C-x d" . zp/org-agenda-delete-property)
          ("C-c C-x s" . zp/org-agenda-wipe-local-config)
          (">" . zp/org-agenda-date-prompt-and-update-appt)
          ("<" . zp/ivy-org-agenda-set-category-filter)
          ("C-c C-s" . zp/org-agenda-schedule-and-update-appt)
          ("C-c C-S-w" . zp/org-agenda-refile-with-paths)
          ("Z" . zp/org-resolve-clocks)
          ("C-<return>" . org-agenda-switch-to)
          ("<return>" . zp/org-agenda-tree-to-indirect-buffer-without-grabbing-focus)
          ("S-<return>" . zp/org-agenda-tree-to-indirect-buffer)
          ("M-<return>" . zp/org-agenda-tree-to-indirect-buffer-maximise)
          ("<backspace>" . zp/org-kill-spawned-ibuf-and-window)
          ("c" . zp/org-agenda-goto-calendar))
         :map calendar-mode-map
         (("c" . zp/org-calendar-goto-agenda)
          ("<RET>" . zp/org-calendar-goto-agenda)))
  :config
  (setq org-agenda-show-future-repeats t
        org-agenda-skip-scheduled-if-done 1
        org-agenda-skip-timestamp-if-done 1
        org-agenda-skip-deadline-if-done 1
        org-agenda-skip-deadline-prewarning-if-scheduled nil
        org-agenda-tags-todo-honor-ignore-options 1
        org-agenda-todo-ignore-with-date nil
        org-agenda-todo-ignore-deadlines nil
        org-agenda-todo-ignore-timestamp nil
        org-agenda-todo-list-sublevels t
        org-agenda-dim-blocked-tasks nil
        org-agenda-include-deadlines 'all
        org-deadline-warning-days 30
        org-agenda-cmp-user-defined 'zp/org-cmp-created-dwim
        org-agenda-sorting-strategy
        '((agenda habit-down deadline-up time-up scheduled-up priority-down category-keep)
          (tags user-defined-down category-keep)
          (todo user-defined-down category-keep)
          (search category-keep))

        ;; Initialise the list structure for local variables
        zp/org-agenda-local-config
        (zp/org-agenda-local-config-init
         '(
           org-habit-show-all-today nil
           org-agenda-show-all-dates t
           org-agenda-include-deadlines t
           zp/org-agenda-include-scheduled t
           org-agenda-entry-types '(:deadline :scheduled :timestamp :sexp)
           zp/org-agenda-include-category-icons t
           zp/org-agenda-sorting-strategy-special-first nil
           zp/org-agenda-split-subtasks nil
           zp/org-agenda-include-waiting t
           zp/org-agenda-include-projects t
           zp/org-agenda-groups-extra-filters nil
           zp/org-agenda-category-filter nil

           org-habit-show-habits t
           zp/org-agenda-include-routine t

           zp/org-agenda-todo-ignore-future t
           org-agenda-todo-ignore-scheduled 'future

           zp/org-agenda-sort-by-rev-fifo nil))

        zp/org-agenda-extra-local-config
        '(("k" ((zp/org-agenda-include-routine . nil)))
          ("K" ((zp/org-agenda-include-routine . nil)))
          ("x" ((zp/org-agenda-todo-ignore-future . nil)
                (org-agenda-todo-ignore-scheduled . nil)))
          ("calendar" ((zp/org-agenda-include-routine . nil))))

        ;; View setup
        org-agenda-hide-tags-regexp "recurring\\|waiting\\|standby"
        org-agenda-tags-column -94
        org-agenda-timegrid-use-ampm nil
        org-agenda-window-setup 'current-window
        org-agenda-compact-blocks nil
        org-agenda-entry-text-maxlines 10
        org-agenda-sticky 1
        org-agenda-block-separator 126
        org-agenda-use-time-grid nil
        org-agenda-exporter-settings
        '((ps-print-color-p t)
          (ps-landscape-mode t)
          (ps-print-header nil)
          (ps-default-bg t))
        org-agenda-clockreport-parameter-plist
        '(:link t :narrow 50 :maxlevel 2 :fileskip0 t)
        org-agenda-clock-consistency-checks
        '(:max-duration "10:00"
                        :min-duration 0
                        :max-gap "0:05"
                        :gap-ok-around ("4:00" "12:30" "19:30")
                        :default-face zp/org-agenda-block-info-face
                        :gap-face nil
                        :no-end-time-face nil
                        :long-face nil
                        :short-face nil)
        org-agenda-prefix-format '((agenda . " %i %-12:c%?-12t% s")
                                   (timeline . "  % s")
                                   (todo . " %i %-12:c")
                                   (tags . " %i %-12:c")
                                   (search . " %i %-12:c")))

  (setq zp/org-agenda-category-icon-alist
      '(
        ;; Life
        ("^inbox$" "~/org/svg/icons/gmail.svg" nil nil :ascent center)
        ("^life$" "~/org/svg/icons/aperture-blue.svg" nil nil :ascent center)
        ("^curios$" "~/org/svg/icons/question.svg" nil nil :ascent center)
        ("^style$" "~/org/svg/icons/suit.svg" nil nil :ascent center)
        ("^nicolas$" "~/org/svg/icons/leaf.svg" nil nil :ascent center)
        ("^swim$" "~/org/svg/icons/wave.svg" nil nil :ascent center)
        ("^run$" "~/org/svg/icons/running.svg" nil nil :ascent center)
        ("^awakening$" "~/org/svg/icons/aperture-green.svg" nil nil :ascent center)
        ("^journal$" "~/org/svg/icons/spellbook-p.svg" nil nil :ascent center)
        ("^psy$" "~/org/svg/icons/solution.svg" nil nil :ascent center)
        ("^anki$" "~/org/svg/icons/anki-2-p.svg" nil nil :ascent center)
        ("^plan$" "~/org/svg/icons/planning-p.svg" nil nil :ascent center)
        ("^typography$" "~/org/svg/icons/typography.svg" nil nil :ascent center)

        ;; Activism
        ("^pol$" "~/org/svg/icons/fist.svg" nil nil :ascent center)

        ;; Professional
        ("^university$" "~/org/svg/icons/aperture-yellow.svg" nil nil :ascent center)
        ("^school$" "~/org/svg/icons/university.svg" nil nil :ascent center)

        ;; Research
        ("^research$" "~/org/svg/icons/research.svg" nil nil :ascent center)
        ("^d&p$" "~/org/svg/icons/university.svg" nil nil :ascent center)
        ("^cs$" "~/org/svg/icons/computer-science.svg" nil nil :ascent center)
        ("^maths$" "~/org/svg/icons/pi.svg" nil nil :ascent center)
        ("^phil$" "~/org/svg/icons/philosophy.svg" nil nil :ascent center)
        ("^history$" "~/org/svg/icons/history.svg" nil nil :ascent center)
        ("^ling$" "~/org/svg/icons/language.svg" nil nil :ascent center)

        ;; Hacking
        ("^hack$" "~/org/svg/icons/engineering-2.svg" nil nil :ascent center)
        ("^emacs$" "~/org/svg/icons/spacemacs.svg" nil nil :ascent center)
        ("^org$" "~/org/svg/icons/org-mode-unicorn.svg" nil nil :ascent center)
        ("^python$" "~/org/svg/icons/python.svg" nil nil :ascent center)
        ("^perl$" "~/org/svg/icons/perl.svg" nil nil :ascent center)
        ("^cl$" "~/org/svg/icons/common-lisp-b.svg" nil nil :ascent center)
        ("^contrib$" "~/org/svg/icons/chill.svg" nil nil :ascent center)
        ("^bug$" "~/org/svg/icons/cross.svg" nil nil :ascent center)
        ("^elisp$" "~/org/svg/icons/spacemacs-elisp.svg" nil nil :ascent center)
        ("^tex$" "~/org/svg/icons/file-2-p.svg" nil nil :ascent center)
        ("^linux$" "~/org/svg/icons/nixos.svg" nil nil :ascent center)
        ("^nixos$" "~/org/svg/icons/nixos.svg" nil nil :ascent center)
        ("^opsec$" "~/org/svg/icons/cyber-security-b.svg" nil nil :ascent center)
        ("^ranger$" "~/org/svg/icons/ranger.svg" nil nil :ascent center)
        ("^git$" "~/org/svg/icons/git.svg" nil nil :ascent center)

        ;; Media
        ("^media$" "~/org/svg/icons/library.svg" nil nil :ascent center)
        ("^news$" "~/org/svg/icons/world.svg" nil nil :ascent center)
        ("^books$" "~/org/svg/icons/book-2.svg" nil nil :ascent center)
        ("^trackers$" "~/org/svg/icons/share.svg" nil nil :ascent center)
        ("^music$" "~/org/svg/icons/compact-disc.svg" nil nil :ascent center)
        ("^film$" "~/org/svg/icons/film.svg" nil nil :ascent center)

        ;; Maintenance
        ("^mx$" "~/org/svg/icons/recycle.svg" nil nil :ascent center)
        ("^fin$" "~/org/svg/icons/money-p.svg" nil nil :ascent center)
        ("^cooking$" "~/org/svg/icons/salad.svg" nil nil :ascent center)
        ("^plants$" "~/org/svg/icons/sansevieria.svg" nil nil :ascent center)
        ("^animals$" "~/org/svg/icons/animals.svg" nil nil :ascent center)
        ("^health$" "~/org/svg/icons/health.svg" nil nil :ascent center)
        ("^supplies$" "~/org/svg/icons/box.svg" nil nil :ascent center)
        ("^social$" "~/org/svg/icons/happy.svg" nil nil :ascent center)
        ("^grooming$" "~/org/svg/icons/razor.svg" nil nil :ascent center)
        ("^clean$" "~/org/svg/icons/bucket.svg" nil nil :ascent center)

        (".*" '(space . (:width (24))) nil nil :ascent center)))

  (setq zp/org-agenda-default-agendas-list '("n" "l"))

  (setq zp/org-agenda-seekable-agendas-list '("n" "N" "k" "K"))

  (setq org-agenda-custom-commands
        `(("n" "Agenda"
           (,(zp/org-agenda-block-agenda-main "Agenda" org-agenda-files)))

          ("N" "Agenda (w/o groups)"
           (,(zp/org-agenda-block-agenda "Agenda (w/o groups)" org-agenda-files)))

          ("k" "Timestamps & Deadlines"
           (,(zp/org-agenda-block-agenda-timestamps-and-deadlines
              "Timestamps & Deadlines")))

          ("K" "Seeking Agenda"
           (,(zp/org-agenda-block-agenda-week-with-group-filter
              "Seeking Agenda" nil)))

          ("A" "Active"
           (,@(zp/org-agenda-blocks-create "Active" nil nil t)))

          ("I" "Inactive"
           (,@(zp/org-agenda-blocks-create "Inactive" nil "/STBY")))

          ("ii" "Inactive (+groups)"
           (,@(zp/org-agenda-blocks-create "Inactive (+groups)" nil "/STBY" t)))

          ("C" "Curiosities"
           (,@(zp/org-agenda-blocks-create "Curiosities" nil "+curios")))

          ("cc" "Curiosities (+groups)"
           (,@(zp/org-agenda-blocks-create "Curiosities (+groups)" nil "+curios" t)))

          ,@(zp/org-agenda-create-all
             '(("l" "Life" ("+life+mx+pro+research+act"))
               ("L" "Life (strict)" ("+life+mx"))
               ("x" "Maintenance" ("mx"))
               ("p" "Professional" ("pro"))
               ("r" "Research" ("research"))
               ("h" "Hacking" ("hack"))
               ("o" "Org" ("org"))
               ("e" "Emacs" ("emacs"))
               ("O" "OPSEC" ("opsec"))
               ("P" "Activism" ("act"))
               ("m" "Media" ("media"))
               ("f" "Film" ("film"))
               ("g" "Groupless" ("nil"))))

          ("j" "Journal entries"
           (,(zp/org-agenda-block-journal))
           ((org-agenda-files '("~/org/journal.org"))))

          ("d" "Deadlines"
           (,(zp/org-agenda-block-deadlines)))

          ("w" "Waiting list"
           (,(zp/org-agenda-block-tasks-waiting)))

          ("A" "Meditation records"
           ((agenda ""
                    ((org-agenda-files zp/org-agenda-files-awakening)
                     (org-agenda-log-mode))))
           ((org-agenda-skip-timestamp-if-done nil)))

          ("S" "Swimming records"
           ((agenda ""
                    ((org-agenda-files zp/org-agenda-files-sports))))
           ((org-agenda-skip-timestamp-if-done nil)))
          ))

  ;; Update ‘org-super-agenda-header-map’
  (use-package org-super-agenda
    :config
    (setq org-super-agenda-header-map org-agenda-mode-map)))



;;----------------------------------------------------------------------------
;; org-capture
;;----------------------------------------------------------------------------
(use-package org-capture
  :commands (zp/org-agenda-capture)
  :bind (("C-c n" . org-capture)
         :map org-agenda-mode-map
         ("k" . zp/org-agenda-capture))
  :hook ((org-capture-mode . zp/org-capture-make-full-frame)
         (org-capture-prepare-finalize . zp/org-set-created-property))
  :config
  (setq org-default-notes-file "~/org/life.org")

  ;;-----------
  ;; Templates
  ;;-----------

  (setq org-capture-templates
        `(("n" "Note" entry (file+headline "~/org/life.org" "Inbox")
           "* %?" :add-created t)
          ("f" "Todo" entry (file+headline "~/org/life.org" "Inbox")
           "* TODO %?" :add-created t)
          ("F" "Todo + Clock" entry (file+headline "~/org/life.org" "Inbox")
           "* TODO %?\n" :add-created t :clock-in t)
          ("r" "Todo with Context" entry (file+headline "~/org/life.org" "Inbox")
           "* TODO %?\n%a" :add-created t)
          ("R" "Todo with Context + Clock" entry (file+headline "~/org/life.org" "Inbox")
           "* TODO %?\n%a" :add-created t :clock-in t)
          ;; ("r" "Todo + Reminder" entry (file+headline "~/org/life.org" "Inbox")
          ;;  "* TODO %?\nSCHEDULED: %^T\n:PROPERTIES:\n:APPT_WARNTIME:  %^{APPT_WARNTIME|5|15|30|60}\n:END:")
          ;; ("T" "Todo (with keyword selection)" entry (file+headline "~/org/life.org" "Inbox")
          ;;  "* %^{State|TODO|NEXT|STBY|WAIT} %?")
          ;; ("e" "Todo + Creation time" entry (file+headline "~/org/life.org" "Inbox")
          ;;  "* TODO %?\n:PROPERTIES:\n:CREATED:  %U\n:END:")
          ;; ("C" "Todo + Clock" entry (file+headline "~/org/life.org" "Inbox")
          ;;  "* TODO %^{Task}%?" :clock-in t)
          ;; ("C" "Todo + Clock (with keyword selection)" entry (file+headline "~/org/life.org" "Inbox")
          ;;  "* %^{State|TODO|NEXT} %?" :clock-in t)
          ("d" "Date" entry (file+headline "~/org/life.org" "Calendar")
           "* %?\n" :add-created t)
          ("e" "Date + Context" entry (file+headline "~/org/life.org" "Calendar")
           "* %?\n%a" :add-created t)

          ;; ("D" "Date + Reminder" entry (file+headline "~/org/life.org" "Calendar")
          ;;  "* %?\n%^T\n\n%^{APPT_WARNTIME}p")
          ;; ("R" "Reminder" entry (file+headline "~/org/life.org" "Inbox")
          ;;  "* %?\n%^T%^{APPT_WARNTIME}p")

          ("p" "Phone-call" entry (file+headline "~/org/life.org" "Inbox")
           "* TODO Phone-call with %^{Interlocutor|Nicolas|Mum}%?\n:STATES:\n- State \"TODO\"       from              %U\n:END:" :clock-in t)
          ("m" "Meeting" entry (file+headline "~/org/life.org" "Inbox")
           "* TODO Meeting with %^{Meeting with}%?" :clock-in t)

          ("s" "Special")
          ("ss" "Code Snippet" entry (file "~/org/projects/hacking/snippets.org.gpg")
           ;; Prompt for tag and language
           "* %?\t%^g\n#+BEGIN_SRC %^{language}\n\n#+END_SRC")
          ;; ("sf" "Film recommendation" entry (file+olp "~/org/media.org.gpg" "Films" "List")
          ;;  "* %(zp/org-capture-set-media-link-letterboxd)%?%^{MEDIA_DIRECTOR}p%^{MEDIA_YEAR}p%^{MEDIA_DURATION}p")
          ;; ("sf" "Film recommendation" entry (file+olp "~/org/media.org.gpg" "Films" "List")
          ;;  "* %(zp/letterboxd-set-link)%?%^{MEDIA_DIRECTOR}p%^{MEDIA_YEAR}p%(zp/letterboxd-set-duration)")
          ("sf" "Film" entry (file+olp "~/org/media.org.gpg" "Films" "List")
           "* %(zp/letterboxd-capture)")
          ("sF" "Film (insert at top)" entry (file+olp "~/org/media.org.gpg" "Films" "List")
           "* %(zp/letterboxd-capture)" :prepend t)
          ("sw" "Swimming workout" entry (file+weektree+prompt "~/org/sports/swimming/swimming.org.gpg")
           "* DONE Training%^{SWIM_DISTANCE}p%^{SWIM_DURATION}p\n%t%(print zp/swimming-workout-default)")

          ("j" "Journal")
          ("jj" "Journal" entry (file+olp "~/org/journal.org" "Life")
           "* %^{Title|Entry}\n%T\n\n%?" :full-frame t)
          ("ja" "Awakening" entry (file+olp "~/org/journal.org" "Awakening")
           "* %^{Title|Entry}\n%T\n\n%?" :full-frame t)
          ("jp" "Psychotherapy" entry (file+olp "~/org/journal.org" "Psychotherapy")
           "* %^{Title|Entry}\n%T\n\n%?" :full-frame t)
          ("jw" "Writing" entry (file+olp "~/org/journal.org" "Writing")
           "* %^{Title|Entry} %^g\n%T\n\n%?" :full-frame t)
          ("jr" "Research" entry (file+olp "~/org/journal.org" "Research")
           "* %^{Title|Entry}\n%T\n\n%?" :full-frame t)
          ("ju" "University" entry (file+olp "~/org/journal.org" "University")
           "* %^{Title|Entry}\n%T\n\n%?" :full-frame t)
          ("jh" "Hacking" entry (file+olp "~/org/journal.org" "Hacking")
           "* %^{Title|Entry}\n%T\n\n%?" :full-frame t)
          ("jm" "Music" entry (file+olp "~/org/journal.org" "Music")
           "* %^{Title|Entry}\n%T\n\n%?" :full-frame t)
          ("js" "Swimming" entry (file+olp "~/org/journal.org" "Swimming")
           "* %^{Title|Entry}\n%T\n\n%?" :full-frame t)

          ;; Daily Record of Dysfunctional Thoughts
          ("D" "Record Dysfunctional Thoughts" entry (file+headline "~/org/journal.org" "Psychotherapy")
           "* Record of Dysfunctional Thoughts\n%T\n** Situation\n%?\n** Emotions\n** Thoughts")

          ;; Pain Diary
          ("P" "Pain Diary" entry (file+olp "~/org/life.org" "Psychotherapy" "Pain Diary")
           "* Entry: %U
** What were you doing or what happened?
%?
** What did you start struggling with psychologically?
** What thoughts came up in association with that struggle?")

          ("a" "Meditation session" entry (file+headline "~/org/projects/awakening/awakening.org.gpg" "Sessions")
           "* DONE Session%^{SESSION_DURATION}p\n%t" :immediate-finish t)

          ("WF" "S: Flat" entry (file+headline "~/org/life.org" "Inbox")
           "* %? :online:%^{PRICE}p%^{LOCATION}p%^{MEUBLÉ}p%^{M²}p
:PROPERTIES:
:LINK: [[%(print zp/org-capture-web-url)][%(print zp/org-capture-web-title)]]
:END:"
           :add-created t)))

  (defvar zp/swimming-workout-default nil
    "Default swimming workout.")

  (setq zp/swimming-workout-default "
|-----+-----------------------------------|
| 500 | warmup crawl/fly                  |
| 500 | 100 pull / 100 pull fast          |
| 500 | 5*25 kick steady / 5*25 kick fast |
| 500 | 100 pull / 100 pull fast          |
| 500 | 50 fly / 100 crawl                |
| 500 | 100 pull / 100 pull fast          |
| 500 | 50 fly / 100 crawl                |
| 100 | warmdown                          |
|-----+-----------------------------------|")

  ;;---------------------------------
  ;; Templates for ‘org-agenda-mode’
  ;;---------------------------------

  (use-package org-agenda
    :config
    ;; Special set of templates to be used in ‘org-agenda-mode’
    (setq zp/org-agenda-capture-templates
          '(("f" "Todo" entry (file+headline "~/org/life.org" "Inbox")
             "* TODO %?\n%t")
            ("r" "Todo (+time)" entry (file+headline "~/org/life.org" "Inbox")
             "* TODO %?\n%^T" :add-warntime t)

            ("d" "Date" entry (file+olp "~/org/life.org" "Life" "Calendar")
             "* %?\n%t")
            ("e" "Date (+time)" entry (file+olp "~/org/life.org" "Life" "Calendar")
             "* %?\n%^T" :add-warntime t)

            ("s" "Todo & Scheduled" entry (file+headline "~/org/life.org" "Inbox")
             "* TODO %?\nSCHEDULED: %t")
            ("w" "Todo & Scheduled (+time)" entry (file+headline "~/org/life.org" "Inbox")
             "* TODO %?\nSCHEDULED: %^T" :add-warntime t)

            ("g" "Todo + Deadline" entry (file+headline "~/org/life.org" "Inbox")
             "* TODO %?\nDEADLINE: %t")
            ("t" "Todo & Deadline (+time)" entry (file+headline "~/org/life.org" "Inbox")
             "* TODO %?\nDEADLINE: %^T" :add-warntime t)))

    (defun zp/org-agenda-capture (&optional arg)
      (interactive "P")
      (let ((org-capture-templates zp/org-agenda-capture-templates))
        (org-agenda-capture arg))))

  ;;------------------------------------------
  ;; Load extra minor modes based on template
  ;;------------------------------------------

  ;; Loading extra minor-modes with org-capture
  (defvar zp/org-capture-extra-minor-modes-alist nil
    "Alist of minors modes to load with specific org-capture templates.")

  (setq zp/org-capture-extra-minor-modes-alist nil)

  (defun zp/org-capture-load-extra-minor-mode ()
    "Load minor-mode based on based on key."
    (interactive)
    (let* ((key (plist-get org-capture-plist :key))
           (minor-mode (cdr (assoc key zp/org-capture-extra-minor-modes-alist))))
      (when (and key
                 minor-mode)
        (if minor-mode
            (funcall minor-mode)))))

  (add-hook 'org-capture-mode-hook #'zp/org-capture-load-extra-minor-mode)

  ;;-------------------------
  ;; Handling extra keywords
  ;;-------------------------

  (defun zp/org-capture-set-created-property ()
    "Conditionally set the CREATED property on captured trees."
    (let ((add-created (plist-get org-capture-plist :add-created)))
      (unless (buffer-narrowed-p)
        (error "Buffer is not narrowed"))
      (save-excursion
        (goto-char (point-min))
        (zp/org-set-created-property))))

  (use-package appt
    :hook (org-capture-mode . zp/org-capture-set-appt-warntime-if-timestamp)
    :config
    (defun zp/org-capture-set-appt-warntime-if-timestamp ()
      "Conditionally set the APPT_WARNTIME on capture trees."
      (let ((add-warntime (plist-get org-capture-plist :add-warntime)))
        (when add-warntime
          (zp/org-set-appt-warntime-if-timestamp)))))

  ;;------
  ;; Rest
  ;;------

  ;; Align tags in templates before finalising
  (add-hook 'org-capture-before-finalize-hook #'org-align-all-tags)

  ;; Restore the previous window configuration after exiting
  (defvar zp/org-capture-before-config nil
    "Window configuration before ‘org-capture’.")

  (defadvice org-capture (before save-config activate)
    "Save the window configuration before ‘org-capture’."
    (setq zp/org-capture-before-config (current-window-configuration)))

  (defun zp/org-capture-make-full-frame ()
    "Maximise the org-capture frame if :full-frame is non-nil."
    (let ((full-frame (plist-get org-capture-plist :full-frame)))
      (if full-frame
          (delete-other-windows)))))

(use-package org-capture-web
  :commands (zp/org-capture-web
             zp/org-capture-web-kill
             zp/org-capture-web-letterboxd)
  :config
  (setq zp/org-capture-web-default-target
        '(file+headline "~/org/life.org" "Inbox")))

;;----------------------------------------------------------------------------
;; hydra-org-refile
;;----------------------------------------------------------------------------
(use-package hydra-org-refile
  :commands (zp/org-jump-dwim
             zp/org-refile-dwim
             zp/hydra-org-refile)
  :bind ("C-c C-j" . zp/hydra-org-jump)
  :after (:any org org-capture)
  :init
  ;; ‘hydra-org-refile’ needs to modify the keymaps of ‘org-mode’,
  ;; ‘org-agenda-mode’, and ‘org-capture-mode’, but since those packages are
  ;; loaded lazily, we can’t simply add new key-bindings to their keymaps
  ;; because they might have not been initialised.  Instead, we defer the
  ;; feature-related key-binding assignments until their corresponding feature
  ;; has been loaded.
  (use-package org
    :bind (:map org-mode-map
                ("C-c C-j" . zp/org-jump-dwim )
                ("C-c C-w" . zp/org-refile-dwim ))
    :hook (org-mode . visual-line-mode))

  (use-package org-agenda
    :bind (:map org-agenda-mode-map
                ("C-c C-w" . zp/hydra-org-refile )))

  (use-package org-capture
    :bind (:map org-capture-mode-map
                ("C-c C-w" . zp/hydra-org-refile )))
  :config
  ;; Exclude separators in all org-refile commands
  (setq org-refile-target-verify-function
        'zp/org-refile-target-verify-exclude-separators)


  (zp/create-hydra-org-refile nil
      "
  ^Life^              ^Pages^^^
 ^^^^^^------------------------------------
  _i_: Inbox          _x_/_X_: Maintenance
  _l_: Life           _p_/_P_: Pro
  _o_: Planning       _r_/_R_: Research
  _k_: Curiosities    _m_/_M_: Media
  _s_: Social         _h_/_H_: Hacking
  _n_: Nicolas        _a_/_A_: Activism
  _S_: Swimming
  _R_: Running        _c_/_C_: Calendars
"
    (("i" "~/org/life.org" "Inbox")
     ("l" "~/org/life.org" "Life")
     ("o" "~/org/life.org" "Planning")
     ("k" "~/org/life.org" "Curiosities")
     ("s" "~/org/life.org" "Social")
     ("n" "~/org/life.org" "Nicolas")
     ("S" "~/org/life.org" "Swimming")
     ("R" "~/org/life.org" "Running")

     ("X" "~/org/life.org" "Maintenance")
     ("P" "~/org/life.org" "Professional")
     ("R" "~/org/life.org" "Research")
     ("M" "~/org/life.org" "Media")
     ("H" "~/org/life.org" "Hacking")
     ("A" "~/org/life.org" "Activism")

     ("C" "~/org/life.org" "Life" "Calendar"))
    (("x" mx)
     ("p" pro)
     ("r" research)
     ("m" media)
     ("h" hack)
     ("a" activism)
     ("c" calendars)))

  (zp/create-hydra-org-refile mx
      "
  ^Maintenance^
 ^^-------------
  _._: Root
  _f_: Finances
  _a_: Animals
  _c_: Cleaning
  _p_: Plants
  _s_: Supplies
  _k_: Cooking
  _g_: Grooming
  _h_: Health
"
    (("." "~/org/life.org" "Maintenance")
     ("f" "~/org/life.org" "Finances")
     ("a" "~/org/life.org" "Animals")
     ("c" "~/org/life.org" "Cleaning")
     ("p" "~/org/life.org" "Plants")
     ("s" "~/org/life.org" "Supplies")
     ("k" "~/org/life.org" "Cooking")
     ("g" "~/org/life.org" "Grooming")
     ("h" "~/org/life.org" "Health")))

  (zp/create-hydra-org-refile research
      "
  ^Research^
 ^^---------------------
  _._: Root
  _d_: D&P
  _c_: Computer Science
  _m_: Mathematics
  _p_: Philosophy
  _l_: Linguistics
  _h_: History
  _t_: Typography
"
    (("." "~/org/life.org" "Research")
     ("d" "~/org/life.org" "Didactics & Pedagogy")
     ("c" "~/org/life.org" "Computer Science")
     ("m" "~/org/life.org" "Mathematics")
     ("p" "~/org/life.org" "Philosophy")
     ("l" "~/org/life.org" "Linguistics")
     ("h" "~/org/life.org" "History")
     ("t" "~/org/life.org" "Typography")))

  (zp/create-hydra-org-refile pro
      "
  ^Professional^
 ^^---------------
  _._: Root
  _s_: School
  _u_: University
  _c_/_C_: Classes
"
    (("." "~/org/life.org" "Professional")
     ("s" "~/org/life.org" "School")
     ("u" "~/org/life.org" "University")
     ("C" "~/org/life.org" "Classes"))
    (("c" classes)))

  (zp/create-hydra-org-refile classes
      "
  ^Classes^
 ^^---------------
  _._: Root
  _1_: 2nde 3&4
  _2_: 2nde 1&2
  _3_: 1ère 3&4
  _4_: 1ère ST2S 1&2
"
    (("." "~/org/life.org" "Classes")
     ("1" "~/org/life.org" "Classes" "2nde" "LPOLJ-2019-2020 - 2nde 3&4")
     ("2" "~/org/life.org" "Classes" "2nde" "LPOLJ-2019-2020 - 2nde 1&2")
     ("3" "~/org/life.org" "Classes" "1ère" "LPOLJ-2019-2020 - 1ère 3&4")
     ("4" "~/org/life.org" "Classes" "1ère" "LPOLJ-2019-2020 - 1ère ST2S 1&2")))

  (zp/create-hydra-org-refile hack
      "
  ^Hacking^
 ^^----------
  _._: Root
  _e_: Emacs
  _i_: Elisp
  _o_: Org
  _r_: Ranger
  _t_: LaTeX
  _l_: Linux
  _n_: NixOS
  _g_: Git
  _p_: Python
  _P_: Perl
  _c_: Common Lisp
"
    (("." "~/org/life.org" "Hacking")
     ("e" "~/org/life.org" "Emacs")
     ("i" "~/org/life.org" "Elisp")
     ("o" "~/org/life.org" "Org")
     ("r" "~/org/life.org" "Ranger")
     ("t" "~/org/life.org" "LaTeX")
     ("l" "~/org/life.org" "Linux")
     ("n" "~/org/life.org" "NixOS")
     ("g" "~/org/life.org" "Git")
     ("p" "~/org/life.org" "Python")
     ("P" "~/org/life.org" "Perl")
     ("c" "~/org/life.org" "Common Lisp")

     ;; ("c" "~/org/life.org" "Contributing")
     ;; ("b" "~/org/life.org" "Troubleshooting")
     ))

  (zp/create-hydra-org-refile activism
      "
  ^Activism^
 ^^----------
  _._: Root
  _p_: Politics
"
    (("." "~/org/life.org" "Activism")
     ("p" "~/org/life.org" "Politics")))

  (zp/create-hydra-org-refile calendars
      "
  ^Calendars^
 ^^------------------
  _o_: Life
  _s_: Social
  _n_: Nicolas
  _x_: Maintenance
  _f_: Finances
  _a_: Animals
  _p_: Professional
  _s_: School
  _u_: University
  _r_: Research
  _h_: Hacking
  _P_: Politics
  _m_: Media
"
    (("o" "~/org/life.org" "Life" "Calendar")
     ("s" "~/org/life.org" "Social" "Calendar")
     ("n" "~/org/life.org" "Nicolas" "Calendar")
     ("x" "~/org/life.org" "Maintenance" "Calendar")
     ("f" "~/org/life.org" "Finances" "Calendar")
     ("a" "~/org/life.org" "Animals" "Calendar")
     ("p" "~/org/life.org" "Professional" "Calendar")
     ("S" "~/org/life.org" "School" "Calendar")
     ("u" "~/org/life.org" "University" "Calendar")
     ("r" "~/org/life.org" "Research" "Calendar")
     ("h" "~/org/life.org" "Hacking" "Calendar")
     ("P" "~/org/life.org" "Politics" "Calendar")
     ("m" "~/org/life.org" "Media" "Calendar"))
    nil)

  (zp/create-hydra-org-refile media
      "
  ^Media^      ^Pages^^^
 ^^^^^^------------------------
  _._: Root    _b_/_B_: Books
  _n_: News    _f_/_F_: Film
             ^^_s_/_S_: Series
             ^^_m_/_M_: Music
"
    (("." "~/org/life.org" "Media")
     ("B" "~/org/life.org" "Books")
     ("n" "~/org/life.org" "News")
     ("M" "~/org/life.org" "Music")
     ("F" "~/org/life.org" "Film")
     ("S" "~/org/life.org" "Series"))
    (("b" books)
     ("f" film)
     ("s" series)
     ("m" music)))

  (zp/create-hydra-org-refile books
      "
  ^Books^
 ^^---------
  _._: Root
  _l_: List
  _d_: Read
"
    (("." "~/org/life.org" "Books")
     ("l" "~/org/life.org" "Books" "List")
     ("d" "~/org/life.org" "Books" "Read"))
    nil
    media)

  (zp/create-hydra-org-refile film
      "
  ^Film^
 ^^------------
  _._: Root
  _l_: List
  _d_: Watched
"
    (("." "~/org/life.org" "Film")
     ("l" "~/org/life.org" "Film" "List")
     ("d" "~/org/life.org" "Film" "Watched"))
    nil
    media)

  (zp/create-hydra-org-refile series
      "
  ^Series^
 ^^------------
  _._: Root
  _l_: List
  _d_: Watched
"
    (("." "~/org/life.org" "Series")
     ("l" "~/org/life.org" "Series" "List")
     ("d" "~/org/life.org" "Series" "Watched"))
    nil
    media)

  (zp/create-hydra-org-refile music
      "
  ^Music^
 ^^-----------------
  _._: Root
  _c_: Classical
  _j_: Jazz
  _o_: Other genres
"
    (("." "~/org/life.org" "Music")
     ("c" "~/org/life.org" "Music" "List of classical pieces")
     ("j" "~/org/life.org" "Music" "List of jazz pieces")
     ("o" "~/org/life.org" "Music" "List of other genres"))
    nil
    media))

;;----------------------------------------------------------------------------
;; org-ref
;;----------------------------------------------------------------------------
(use-package org-ref
  :requires org
  :config
  (setq org-ref-bibliography-notes "~/org/bib/notes.org"
        reftex-default-bibliography '("~/org/bib/monty-python.bib")
        org-ref-default-bibliography '("~/org/bib/monty-python.bib")
        org-ref-pdf-directory "~/org/bib/pdf"))

;;----------------------------------------------------------------------------
;; org-brain
;;----------------------------------------------------------------------------
;; Disabled because I don’t use it
(use-package org-brain
  :disabled
  :config
  (setq org-brain-path "~/org/brain")

  ;; Commented because already the default
  ;; (setq org-id-track-globally t)
  ;; (setq org-id-locations-file "~/.emacs.d/.org-id-locations")
  )

;;----------------------------------------------------------------------------
;; appt
;;----------------------------------------------------------------------------
(use-package appt
  :hook (;; Update reminders when…
         ;; Saving org-agenda-files agenda
         (after-save . zp/org-agenda-to-appt-on-save)
         ;; Loading the org-agenda for the first time
         (org-agenda-finalize . zp/org-agenda-to-appt-on-load)
         ;; After marking a task with APPT_WARNTIME as DONE
         (org-after-todo-state-change . zp/org-agenda-to-appt-on-done))
  :config
  (appt-activate t)

  (setq appt-message-warning-time 15
        appt-display-interval 5
        appt-display-mode-line nil)

  (defun zp/org-appt-check-warntime (&optional pom)
    "Check APPT_WARNTIME for current item.

Return nil if APPT_WARNTIME is ‘none’"
    (not (string= "none" (org-entry-get (or pom
                                            (point))
                                        "APPT_WARNTIME"))))

  (defun zp/org-agenda-to-appt-check-warntime (arg)
    "Check APPT_WARNTIME for current item in the agenda.

This is a filter intended to be use with ‘org-agenda-to-appt’."
    (let ((marker (get-text-property (1- (length arg)) 'org-hd-marker arg)))
      (org-with-point-at marker
        (zp/org-appt-check-warntime marker))))

  ;; Use appointment data from org-mode
  (defun zp/org-agenda-to-appt (&optional arg)
    "Update appt-list based on org-agenda items."
    (interactive "p")
    (setq appt-time-msg-list nil)
    (when (eq arg 4)
      (appt-check))
    (with-temp-message (current-message)
      (org-agenda-to-appt nil 'zp/org-agenda-to-appt-check-warntime))
    (when arg
      (message
       (pcase arg
         (4 "appt has been reset and updated.")
         (_ "appt has been updated.")))))

  ;; TODO: Rename variables to more meaningful names
  ;; The name refers to the rôle they’ll have in the hook rather than to what
  ;; they’re actually doing

  (defun zp/org-agenda-to-appt-on-load ()
    "Hook to `org-agenda-finalize-hook' which creates the appt-list
on init and them removes itself."
    (zp/org-agenda-to-appt)
    (remove-hook 'org-agenda-finalize-hook #'zp/org-agenda-to-appt-on-load))

  (defun zp/org-agenda-to-appt-on-save ()
    "Update appt if buffer is visiting a file in ‘org-agenda-files’."
    (let ((file (or (buffer-file-name)
                    (buffer-file-name (buffer-base-buffer))))
          (agenda-files
           (mapcar #'expand-file-name org-agenda-files)))
      (if (member file agenda-files)
          (zp/org-agenda-to-appt))))

  (defun zp/org-agenda-to-appt-on-done ()
    "Update appt if task with APPT_WARNTIME is marked as DONE."
    (when-let* ((done (org-entry-get (point) "TODO" nil))
                (warntime (zp/org-appt-check-warntime)))
      (zp/org-agenda-to-appt)))

  (defun zp/org-set-appt-warntime (&optional arg)
    "Set the `APPT_WARNTIME' property."
    (interactive "P")
    (if arg
        (org-delete-property "APPT_WARNTIME")
      (org-set-property "APPT_WARNTIME" (org-read-property-value "APPT_WARNTIME"))))

  (defun zp/org-agenda-set-appt-warntime (arg)
    "Set the `APPT_WARNTIME' for the current entry in the agenda."
    (interactive "P")
    (zp/org-agenda-set-property 'zp/org-set-appt-warntime)
    (zp/org-agenda-to-appt arg))

  (defun zp/org-set-location ()
    "Set the `LOCATION' property."
    (interactive)
    (org-set-property "LOCATION" (org-read-property-value "LOCATION")))
  (defun zp/org-agenda-set-location ()
    "Set the `LOCATION' for the current entry in the agenda."
    (interactive)
    (zp/org-agenda-set-property 'zp/org-set-location))

  (defun zp/org-agenda-date-prompt-and-update-appt (arg)
    "Combine ‘org-agenda-date-prompt’ and ‘zp/org-agenda-to-appt’.

Check their respective docstrings for more info."
    (interactive "P")
    (org-agenda-date-prompt arg)
    (zp/org-agenda-to-appt))

  (defun zp/org-agenda-schedule-and-update-appt (arg &optional time)
    "Combine ‘org-agenda-schedule’ and ‘zp/org-agenda-to-appt’.

Check their respective dosctrings for more info."
    (interactive "P")
    (org-agenda-schedule arg time)
    (zp/org-agenda-to-appt))

  ;; ----------------------------------------
  ;; Update reminders when…

  ;; Starting Emacs
  ;; (zp/org-agenda-to-appt)

  ;; Everyday at 12:05am
  ;; (run-at-time "12:05am" (* 24 3600) 'zp/org-agenda-to-appt)
  ;; ----------------------------------------

  ;; Display appointments as a window manager notification
  (setq appt-disp-window-function 'zp/appt-display)

  ;; Prevent appt from deletingg any windows after notifying
  (setq appt-delete-window-function (lambda () t))

  ;; Notification script to handle appt
  (setq zp/appt-notification-app "~/.bin/appt-notify")

  (defun zp/appt-display (min-to-app new-time msg)
    (if (atom min-to-app)
        (start-process "zp/appt-notification-app" nil zp/appt-notification-app min-to-app msg)
      (dolist (i (number-sequence 0 (1- (length min-to-app))))
        (start-process "zp/appt-notification-app" nil zp/appt-notification-app (nth i min-to-app) (nth i msg)))))

  ;; Conditional APPT_WARNTIME
  (defun zp/org-set-appt-warntime-if-timestamp ()
    "Prompt for APPT_WARNTIME if the heading is a timestamp."
    (let ((warntime (org-entry-get (point) "APPT_WARNTIME")))
      (unless warntime
        (save-excursion
          (org-back-to-heading t)
          (let ((end (save-excursion (outline-next-heading) (point))))
            (when (re-search-forward org-stamp-time-of-day-regexp
                                     end t)
              (zp/org-set-appt-warntime)))))))

  (defun zp/org-set-appt-warntime-if-timestamp-advice (&rest args)
    "Prompt for APPT_WARNTIME if the heading is a timestamp.

This function is intended to be used as an advice.

ARGS is only there to catch the shared arguments between the
advised function and this one."
    (zp/org-set-appt-warntime-if-timestamp))

  ;; Advise timestamp-related commands
  (zp/advise-commands
   add
   (org-schedule
    org-deadline
    org-time-stamp)
   after
   zp/org-set-appt-warntime-if-timestamp-advice))

;;----------------------------------------------------------------------------
;; ledger
;;----------------------------------------------------------------------------
(use-package ledger-mode
  :bind (:map ledger-mode-map
              ("C-c C-d" . ledger-kill-current-transaction))
  :config
  (add-to-list 'auto-mode-alist '("\\.ledger$" . ledger-mode))

  (defvar ledger-use-iso-dates nil)
  (defvar ledger-reconcile-default-commodity nil)
  (defvar ledger-post-auto-adjust-amounts nil)
  (setq ledger-use-iso-dates t
        ledger-reconcile-default-commodity "EUR"
        ;; Testing
        ledger-post-auto-adjust-amounts 1
        ledger-schedule-file "~/org/ledger/main-schedule.ledger.gpg")

  (add-hook 'ledger-reconcile-mode-hook #'balance-windows)

  (defun zp/ledger-close-scheduled ()
    "Close the Ledger Scheduled buffer and window."
    (interactive)
    (if (string-match-p (regexp-quote "*Ledger Schedule*") (buffer-name))
        (progn
          (kill-buffer)
          (select-window (previous-window))
          (delete-other-windows))))
  (define-key ledger-mode-map (kbd "S-<backspace>") 'zp/ledger-close-scheduled)

  ;; Patch for inserting an empty line after copied transactions
  (defvar ledger-copy-transaction-insert-blank-line-after nil
    "Non-nil means insert blank line after a transaction inserted
  with ‘ledger-copy-transaction-at-point’.")

  (defun ledger-copy-transaction-at-point (date)
    "Ask for a new DATE and copy the transaction under point to
that date.  Leave point on the first amount."
    (interactive (list
                  (ledger-read-date "Copy to date: ")))
    (let* ((extents (ledger-navigate-find-xact-extents (point)))
           (transaction (buffer-substring-no-properties (car extents) (cadr extents)))
           (encoded-date (ledger-parse-iso-date date)))
      (ledger-xact-find-slot encoded-date)
      (insert transaction
              (if ledger-copy-transaction-insert-blank-line-after
                  "\n\n"
                "\n"))
      (beginning-of-line -1)
      (ledger-navigate-beginning-of-xact)
      (re-search-forward ledger-iso-date-regexp)
      (replace-match date)
      (ledger-next-amount)
      (if (re-search-forward "[-0-9]")
          (goto-char (match-beginning 0)))))

  (setq ledger-copy-transaction-insert-blank-line-after t)

  ;; Patch for killing transaction
  (defun ledger-kill-current-transaction (pos)
    "Delete the transaction surrounging POS."
    (interactive "d")
    (let ((bounds (ledger-navigate-find-xact-extents pos)))
      (kill-region (car bounds) (cadr bounds)))))

;;----------------------------------------------------------------------------
;; magit
;;----------------------------------------------------------------------------
(use-package magit
  :bind (("H-m" . magit-status)
         ("H-M-m" . zp/magit-stage-file-and-commit))
  :config
  (setq magit-diff-refine-hunk 'all)
  (magit-wip-mode)

  ;;----------
  ;; Commands
  ;;----------

  (defun zp/magit-stage-file-and-commit (&optional arg)
    "Stage the current file and commit the changes.

With a ‘C-u’ prefix argument, amend the last commit instead."
    (interactive "p")
    (when (buffer-modified-p)
      (save-buffer))
    (magit-stage-file (magit-file-relative-name))
    (pcase arg
      (4 (magit-commit-amend))
      (_ (magit-commit-create)))))

;;----------------------------------------------------------------------------
;; chronos
;;----------------------------------------------------------------------------
(use-package chronos
  :demand
  :bind (:map chronos-mode-map
              (("a" . 'helm-chronos-add-timer)
               ("A" . (lambda ()
                        (interactive)
                        (let ((zp/helm-chronos-add-relatively t))
                          (helm-chronos-add-timer))))
               ("q" . zp/chronos-quit)

               ;; Quick keys
               ("U" . (lambda ()
                        (interactive)
                        (zp/chronos-edit-quick "-0:00:05" "5 s")))
               ("I" . (lambda ()
                        (interactive)
                        (zp/chronos-edit-quick "+0:00:05" "5 s")))
               ("u" . (lambda ()
                        (interactive)
                        (zp/chronos-edit-quick "-0:00:15" "15 s")))
               ("i" . (lambda ()
                        (interactive)
                        (zp/chronos-edit-quick "+0:00:15" "15 s")))
               ("j" . (lambda ()
                        (interactive)
                        (zp/chronos-edit-quick "-0:01:00" "1 min")))
               ("k" . (lambda ()
                        (interactive)
                        (zp/chronos-edit-quick "+0:01:00" "1 min")))
               ("J" . (lambda ()
                        (interactive)
                        (zp/chronos-edit-quick "-0:05:00" "5 min")))
               ("K" . (lambda ()
                        (interactive)
                        (zp/chronos-edit-quick "+0:05:00" "5 min")))
               ("m" . (lambda ()
                        (interactive)
                        (zp/chronos-edit-quick "-0:10:00" "10 min")))
               ("," . (lambda ()
                        (interactive)
                        (zp/chronos-edit-quick "+0:10:00" "10 min")))))
  :config
  (setq helm-chronos-recent-timers-limit 100
        helm-chronos-standard-timers
        '(
          "Green Tea              3/Green Tea: Remove tea bag"
          "Black Tea              4/Black Tea: Remove tea bag"
          "Herbal Tea             10/Herbal Tea: Remove tea bag"
          "Timebox                25/Finish and Reflect + 5/Back to it"
          "Break                  30/Back to it"
          "Charge Phone           30/Unplug Phone"
          "Charge Tablet          30/Unplug Tablet"
          ))

  ;;---------------------
  ;; Notification system
  ;;---------------------

  (defun chronos-notify (c)
    "Notify expiration of timer C using custom script."
    (chronos--shell-command "Chronos notification"
                            "chronos-notify"
                            (list (chronos--time-string c)
                                  (chronos--message c))))

  (setq chronos-expiry-functions '(chronos-notify))

  ;;-------------
  ;; Quick edits
  ;;-------------

  (defun zp/chronos-edit-selected-line-time (time prefix)
    (interactive)
    (interactive "sTime: \nP")
    (let ((c chronos--selected-timer))
      (when (chronos--running-or-paused-p c)
        (let ((ftime (chronos--parse-timestring time
                                                (if prefix
                                                    nil
                                                  (chronos--expiry-time c)))))
          ;; (msg (read-from-minibuffer "Message: " (chronos--message c))))
          (chronos--set-expiry-time c ftime)
          ;; (chronos--set-message c msg)
          (chronos--set-action c (not (chronos--expiredp c)))
          (chronos--update-display)))))

  (defun zp/chronos-edit-quick (time string)
    (interactive)
    (zp/chronos-edit-selected-line-time time nil)
    (if (string-match-p "-" time)
        (message (concat "Subtracted " string " from selected timer."))
      (message (concat "Added " string " to selected timer."))))

  (defun zp/chronos-quit (&optional arg)
    "Kill chronos window on quit when there are no more timers
running."
    (interactive "P")
    (let* ((timers chronos--timers-list)
           (last-timer-is-now (not (nth 1(nth 0 (last timers)))))
           (no-running-timer (if (> (length timers) 1)
                                 nil
                               't)))
      (if (or (and last-timer-is-now
                   no-running-timer)
              (eq arg '(4)))
          (quit-window 1)
        (quit-window)))))

(use-package helm-chronos-patched
  :bind (("H-;" . zp/switch-to-chronos-dwim)
         ("H-M-;" . zp/helm-chronos-add))
  :after chronos
  :config
  ;; Fix for adding new timers with helm-chronos
  ;; TODO: Check if still necessary with ‘helm-chronos-patched’
  (defvar helm-chronos--fallback-source
    (helm-build-dummy-source "Enter <expiry time spec>/<message>"
      :filtered-candidate-transformer
      (lambda (_candidates _source)
        (list (or (and (not (string= helm-pattern ""))
                       helm-pattern)
                  "Enter a timer to start")))
      :action '(("Add timer" . (lambda (candidate)
                                 (if (string= helm-pattern "")
                                     (message "No timer")
                                   (helm-chronos--parse-string-and-add-timer helm-pattern)))))))

  (defun zp/switch-to-chronos (&optional print-message)
    "Switch to and from chronos’s main buffer.

Also initialise chronos if it wasn’t live.

Return t when switching to chronos, nil otherwise."
    (interactive "p")
    (cond ((derived-mode-p 'chronos-mode)
           (zp/chronos-quit)
           (when print-message
             (message "Exited chronos."))
           nil)
          (t
           (if-let ((buffer (get-buffer "*chronos*")))
               (switch-to-buffer buffer)
             (chronos-initialize))
           (when print-message
             (message "Switched to chronos."))
           t)))

  (defun zp/helm-chronos-add (&optional arg visit)
    "Add a new chronos timer with ‘helm-chronos-add-timer’.

This wrapper displays the current list of timers in the current
buffer.

With a ‘C-u’ argument or when VISIT is non-nil, stay in chronos
after adding the timer."
    (interactive "p")
    (let ((in-chronos (derived-mode-p 'chronos-mode)))
      (unless in-chronos
        (zp/switch-to-chronos))
      (helm-chronos-add-timer)
      (unless (or visit
                  (eq arg 4))
        (zp/chronos-quit)))
    (when arg
      (message "Timer has been added.")))

  (defun zp/switch-to-chronos-dwim (arg &optional add-only)
    "Conditionally switch to and from chronos’s main buffer.

With a ‘C-u’ argument or when ADD-ONLY is non-nil, only visit
chronos’s main buffer for adding a new timer."
    (interactive "p")
    (if (or add-only
            (eq arg 4))
        (zp/helm-chronos-add (when arg 1))
      (zp/switch-to-chronos arg))))

;;----------------------------------------------------------------------------
;; org-noter
;;----------------------------------------------------------------------------
(use-package org-noter
  :config
  (setq org-noter-hide-other t
        org-noter-auto-save-last-location t
        org-noter-doc-split-fraction '(0.59 0.41))

  (add-hook 'org-noter-notes-mode-hook #'visual-line-mode)

  ;; Fix for hiding truncation
  (defun org-noter--set-notes-scroll (window &rest ignored)
    nil)

  ;; Fix for visual-line-mode with PDF files
  (defun org-noter--note-after-tipping-point (point note-property view)
    nil)

  (defun zp/org-noter-indirect (arg)
    "Ensure that org-noter starts in an indirect buffer.

Without this wrapper, org-noter creates a direct buffer
restricted to the notes, but this causes problems with the refile
system.  Namely, the notes buffer gets identified as an
agenda-files buffer.

This wrapper addresses it by having org-noter act on an indirect
buffer, thereby propagating the indirectness."
    (interactive "P")
    (if (org-entry-get nil org-noter-property-doc-file)
        (with-selected-window (zp/org-tree-to-indirect-buffer-folded nil t)
          (org-noter arg)
          (kill-buffer))
      (org-noter arg)))

  (defun zp/org-noter-dwim (arg)
    "Run org-noter on the current tree, even if we’re in the agenda."
    (interactive "P")
    (let ((in-agenda (derived-mode-p 'org-agenda-mode))
          (marker))
      (cond (in-agenda
             (setq marker (get-text-property (point) 'org-marker))
             (with-current-buffer (marker-buffer marker)
               (goto-char marker)
               (unless (org-entry-get nil org-noter-property-doc-file)
                 (user-error "No org-noter info on this tree"))
               (zp/org-noter-indirect arg)))
            (t
             (zp/org-noter-indirect arg)
             (setq marker (point-marker))))
      (org-with-point-at marker
        (let ((tags (org-get-tags-at)))
          (when (and (org-entry-get nil org-noter-property-doc-file)
                     (not (member "noter" tags)))
            (org-set-tags (push "noter" tags)))))
      (unless in-agenda
        (set-marker marker nil))))

  (define-key org-noter-doc-mode-map (kbd "j") 'pdf-view-next-line-or-next-page)
  (define-key org-noter-doc-mode-map (kbd "k") 'pdf-view-previous-line-or-previous-page)

  ;; TODO: Use ‘org-agenda-keymap’ instead of setting it globally
  (global-set-key (kbd "C-c N") 'zp/org-noter-dwim))

;;----------------------------------------------------------------------------
;; Psychotherapy
;;----------------------------------------------------------------------------
(use-package psychotherapy
  :requires (org org-capture)
  :config
  ;; Setting variables
  (setq zp/cognitive-distortions
        '("All-or-nothing thinking"
          "Over-generalisation"
          "Mental filter"
          "Disqualifying the positive"
          "Mind-reading"
          "Fortune-Teller error"
          "Magnification or minimisation"
          "Emotional reasoning"
          "Should statements"
          "Labelling and mislabelling"
          "Personalisation")

        zp/emotions
        '("Anger"
          "Anxiety"
          "Boredom"
          "Disgust"
          "Dispirited"
          "Fear"
          "Guilt"
          "Laziness"
          "Loneliness"
          "Sadness"
          "Tiredness"))

  ;; Load ‘zp/psychotherapy-mode’ with the org-capture-template ‘D’
  ;; (add-to-list 'zp/org-capture-extra-minor-modes-alist
  ;;              '("D" . zp/psychotherapy-mode))
  )

;;----------------------------------------------------------------------------
;; Feedback sounds
;;----------------------------------------------------------------------------
(use-package feedback-sounds
  :hook ((org-clock-in-prepare . zp/play-sound-clock-in)
         (org-clock-out . zp/play-sound-clock-out)
         (org-after-todo-state-change . zp/play-sound-reward)
         (org-capture-mode . zp/play-sound-start-capture)
         (org-capture-after-finalize . zp/play-sound-after-capture)
         (zp/org-after-view-change . zp/play-sound-turn-page)
         (zp/org-after-refile . zp/play-sound-turn-page))
  :requires org)

;;----------------------------------------------------------------------------
;; helm-bibtex
;;----------------------------------------------------------------------------
(use-package helm-bibtex
  :bind (("H-y" . zp/helm-bibtex-with-local-bibliography)
         ("H-M-y" . zp/helm-bibtex-select-bib)
         ("C-c D" . zp/bibtex-completion-message-key-last))
  :config
  ;; TODO: Modernise
  ;; A lot of this code is baby Elisp.

  ;;------------------------
  ;; helm-bibtex-select-bib
  ;;------------------------

  (defvar zp/bibtex-completion-bib-data-alist nil
    "Alist of the bibliography files and their labels.")

  (defvar zp/bibtex-completion-bib-data nil
    "Processed alist of the bibliography files and their labels,
  including an entry with all of them.")

  (defun zp/bibtex-completion-bib-data-format ()
    (interactive)
    (setq zp/bibtex-completion-bib-data zp/bibtex-completion-bib-data-alist)
    (map-put zp/bibtex-completion-bib-data
             "All entries" (list (mapcar 'cdr zp/bibtex-completion-bib-data))))

  (defun zp/bibtex-select-bib-init ()
    (zp/bibtex-completion-bib-data-format)
    (setq bibtex-completion-bibliography
          (cdr (assoc "All entries" zp/bibtex-completion-bib-data))))

  (defun zp/bibtex-select-bib-select (candidate)
    (setq bibtex-completion-bibliography candidate
          reftex-default-bibliography candidate
          org-ref-default-bibliography (list candidate)))

  (defun zp/bibtex-select-bib-select-open (candidate)
    (zp/bibtex-select-bib-select candidate)
    (helm-bibtex))

  (setq zp/bibtex-completion-select-bib-actions
        '(("Open bibliography" . zp/bibtex-select-bib-select-open)
          ("Select bibliography" . zp/bibtex-select-bib-select)))

  (setq zp/helm-source-bibtex-select-bib
        '((name . "*HELM Bibtex - Bibliography selection*")
          (candidates . zp/bibtex-completion-bib-data)
          (action . zp/bibtex-completion-select-bib-actions)))

  (defun zp/helm-bibtex-select-bib (&optional arg)
    (interactive "P")
    (if (equal arg '(4))
        (progn
          ;; Refresh reftex if inside AUCTeX
          (when (derived-mode-p 'latex-mode)
            (reftex-reset-mode))
          ;; Refresh org-ref
          (setq org-ref-bibliography-files nil)
          (zp/bibtex-select-bib-init)))
    (helm :sources '(zp/helm-source-bibtex-select-bib)))

  ;;------------
  ;; Completion
  ;;------------

  (setq zp/bibtex-completion-bib-data-alist
        '(("Monty Python" . "~/org/bib/monty-python.bib")
          ;; ("Monty Python - Extra" . "~/org/bib/monty-python-extra.bib")
          ("FromSoftware" . "~/org/bib/fromsoftware.bib")))

  (zp/bibtex-select-bib-init)

  ;; Autokey generation
  (setq bibtex-align-at-equal-sign t
        bibtex-autokey-name-year-separator ""
        bibtex-autokey-year-title-separator ""
        bibtex-autokey-year-length 4
        bibtex-autokey-titleword-first-ignore '("the" "a" "if" "and" "an")
        bibtex-autokey-titleword-length 20
        bibtex-autokey-titlewords-stretch 0
        bibtex-autokey-titlewords 0)

  (setq bibtex-completion-pdf-field "file")

  (setq bibtex-completion-pdf-symbol "P"
        bibtex-completion-notes-symbol "N")

  ;; Set default dialect to biblatex
  (setq bibtex-dialect 'biblatex)

  ;; Additional fields
  (setq bibtex-user-optional-fields '(("subtitle" "Subtitle")
                                      ("booksubtitle" "Book subtitle")
                                      ("langid" "Language to use with BibLaTeX")
                                      ("library" "Library where the resource is held")
                                      ("shelf" "Shelf number at the library")
                                      ("annote" "Personal annotation (ignored)")
                                      ("keywords" "Personal keywords")
                                      ("tags" "Personal tags")
                                      ("file" "Path to file")
                                      ("url" "URL to reference"))

        helm-bibtex-additional-search-fields '(subtitle booksubtitle keywords tags library))

  (define-key bibtex-mode-map (kbd "C-c M-o") 'bibtex-Online)

  ;; Define which citation function to use on a buffer basis
  (setq bibtex-completion-format-citation-functions
        '(;; (org-mode      . org-ref-bibtex-completion-format-org)
          (org-mode . org-ref-format-citation)
          (latex-mode . bibtex-completion-format-citation-cite)
          (bibtex-mode . bibtex-completion-format-citation-cite)
          (markdown-mode . bibtex-completion-format-citation-pandoc-citeproc)
          (default . bibtex-completion-format-citation-default)))

  ;; Default citation command
  (setq bibtex-completion-cite-default-command "autocite")

  ;; PDF open function
  (setq bibtex-completion-pdf-open-function 'helm-open-file-with-default-tool)

  ;; Helm
  (defun zp/helm-bibtex-with-local-bibliography (&optional arg)
    "Search BibTeX entries with local bibliography.

With a prefix ARG the cache is invalidated and the bibliography
reread."
    (interactive "P")
    (let* ((local-bib-org org-ref-bibliography-files)
           (local-bib (or (bibtex-completion-find-local-bibliography)
                          (if (cl-every 'file-exists-p local-bib-org)
                              local-bib-org)))
           (bibtex-completion-bibliography (or local-bib
                                               bibtex-completion-bibliography)))
      (helm-bibtex arg local-bib)))



  ;; Custom action: Select current document

  ;; (defvar zp/current-document)
  ;; (defun zp/select-current-document ()
  ;;   (interactive)
  ;;   (setq zp/current-document
  ;;      (read-string
  ;;       (concat "Current document(s)"
  ;;               (if (bound-and-true-p zp/current-document)
  ;;                   (concat " [" zp/current-document "]"))
  ;;               ": "))))

  ;; (defun zp/bibtex-completion-select-current-document (keys)
  ;;   (setq zp/current-document (s-join ", " keys)))
  ;; (helm-bibtex-helmify-action zp/bibtex-completion-select-current-document helm-bibtex-select-current-document)

  (defvar zp/bibtex-completion-key-last nil
    "Last inserted keys.")

  (defun zp/bibtex-completion-format-citation-comma (keys)
    "Default formatter for keys, separates multiple keys with
commas."
    (s-join "," keys))

  (defun zp/bibtex-completion-format-citation-comma-space (keys)
    "Formatter for keys, separates multiple keys with
commas and space."
    (s-join ", " keys))

  (defun zp/bibtex-completion-insert-key (keys)
    "Insert BibTeX key at point."
    (let ((current-keys (zp/bibtex-completion-format-citation-comma-space keys)))
      (insert current-keys)
      (setq zp/bibtex-completion-key-last keys)))

  (defun zp/bibtex-completion-insert-key-last ()
    (interactive)
    (let ((last-keys (zp/bibtex-completion-format-citation-default
                      zp/bibtex-completion-key-last)))
      (if (bound-and-true-p last-keys)
          (insert last-keys)
        (zp/helm-bibtex-solo-action-insert-key))))

  (defun zp/bibtex-completion-message-key-last ()
    (interactive)
    (let ((keys (zp/bibtex-completion-format-citation-comma-space
                 zp/bibtex-completion-key-last)))
      (if (bound-and-true-p keys)
          (message (concat "Last key(s) used: " keys "."))
        (message "No previous key used."))))

  ;; Add to helm
  (helm-bibtex-helmify-action zp/bibtex-completion-insert-key zp/helm-bibtex-insert-key)
  (helm-delete-action-from-source "Insert BibTeX key" helm-source-bibtex)
  (helm-add-action-to-source "Insert BibTeX key" 'zp/helm-bibtex-insert-key helm-source-bibtex 4)

  ;; Define solo action: Insert BibTeX key
  (setq zp/helm-source-bibtex-insert-key '(("Insert BibTeX key" . zp/helm-bibtex-insert-key)))
  (defun zp/helm-bibtex-solo-action-insert-key ()
    (interactive)
    (let ((inhibit-message t)
          (previous-actions (helm-attr 'action helm-source-bibtex))
          (new-action zp/helm-source-bibtex-insert-key))
      (helm-attrset 'action new-action helm-source-bibtex)
      (helm-bibtex)
      ;; Wrapping with (progn (foo) nil) suppress the output
      (progn (helm-attrset 'action previous-actions helm-source-bibtex) nil))))

;;----------------------------------------------------------------------------
;; Miscellaneous
;;----------------------------------------------------------------------------
(defun zp/echo-buffer-name ()
  (interactive)
  (message (concat "Current buffer: " (replace-regexp-in-string "%" "%%" (buffer-name)))))

;;----------------------------------------------------------------------------
;; External
;;----------------------------------------------------------------------------
;; Source: https://gitlab.com/marcowahl/herald-the-mode-lined
(defun herald-the-mode-line ()
  "Show the modeline in the minibuffer.
Use case: when the modeline is to short for its content this
command reveals the other lines."
  (interactive)
  (message
   "%s"
   (format-mode-line
    (or mode-line-format
        hide-mode-line))))

(global-set-key (kbd "H-M-.") 'herald-the-mode-line)

(defun move-beginning-of-line-dwim (arg)
  "Move point back to indentation or beginning of line

Move point to the first non-whitespace character on this line.
If point is already there, move to the beginning of the line.
Effectively toggle between the first non-whitespace character and
the beginning of the line."
  (interactive "^p")
  (let ((old-point (point)))
    (back-to-indentation)
    (when (= old-point (point))
      (move-beginning-of-line arg))))

(global-set-key [remap move-beginning-of-line]
                'move-beginning-of-line-dwim)

;;----------------------------------------------------------------------------
;; Mode-line
;;----------------------------------------------------------------------------
(use-package minions
  :config
  (minions-mode 1))

(use-package moody
  :config
  (setq moody-mode-line-height 40)

  ;; TODO: Check if really useful
  (setq x-underline-at-descent-line t)

  (moody-replace-mode-line-buffer-identification)
  (moody-replace-vc-mode))

(defvar ml-selected-window nil
  "Current selected window.")

(defun ml-record-selected-window ()
  (setq ml-selected-window (selected-window)))

(defun ml-update-all ()
  (force-mode-line-update t))

(add-hook 'post-command-hook 'ml-record-selected-window)

(add-hook 'buffer-list-update-hook 'ml-update-all)

(defface mode-line-buffer-id-inactive
  '((t :inherit modeline-buffer-id))
  "Face used for inactive buffer identification parts of the mode line.")

(defun zp/propertized-buffer-identification (fmt)
  "Return a list suitable for `mode-line-buffer-identification'.
FMT is a format specifier such as \"%12b\".  This function adds
text properties for face, help-echo, and local-map to it."
  (list (propertize fmt
                    'face (if (eq ml-selected-window (selected-window))
                              'mode-line-buffer-id
                            'mode-line-buffer-id-inactive)
                    'help-echo
                    (purecopy "Buffer name
mouse-1: Previous buffer\nmouse-3: Next buffer")
                    'mouse-face 'mode-line-highlight
                    'local-map mode-line-buffer-identification-keymap)))

(defun simple-mode-line-render (left right)
  "Return a string of `window-width' length containing LEFT, and RIGHT aligned respectively."
  (let* ((available-width
          (-
           (window-total-width)
           (+
            (length
             (format-mode-line left))
            (length
             (format-mode-line right))))))
    (append left (list (format (format "%%%ds" available-width) "")) right)))

(setq-default mode-line-format
              '((:eval
                 (simple-mode-line-render
                  ;; Left
                  '("%e"
                    mode-line-front-space
                    ;; (:propertize mode-line-mule-info face (:foreground "#777"))
                    mode-line-mule-info
                    mode-line-client
                    mode-line-modified
                    mode-line-remote
                    mode-line-frame-identification
                    ;; (:eval
                    ;;  (if (eq ml-selected-window (selected-window))
                    ;;      "OK "
                    ;;    "NO "))
                    ;; (:eval (propertize "%b  " 'face 'org-tag-important
                    ;;                    'help-echo (buffer-file-name)))
                    ;; (:eval (propertize "" 'face '(:foreground "red"
                    ;;                                          :background nil)
                    ;;                    'help-echo (buffer-file-name)))
                    "   "
                    ;; mode-line-buffer-identification
                    (:eval (moody-tab
                            (format-mode-line
                             (zp/propertized-buffer-identification "%b"))
                            20 'down))
                    ;; (:propertize " [%*]" face (:foreground "#49B05C"))
                    " [%*]"
                    " "
                    ;; (:eval (propertize "test" 'face '(:foreground "red" :weight 'bold)
                    ;;                    'help-echo "buffer is read-only!!!"))
                    ;; mode-line-buffer-identification
                    ;; (:propertize minions-mode-line-modes face (:foreground "#777"))
                    minions-mode-line-modes
                    minor-mode-alist
                    ;; minions-mode-line-modes
                    ;; " %l : %c"
                    evil-mode-line-tag)
                  ;; Right
                  '(;; (:propertize "%p" face mode-line-buffer-id)
                    ;; (:propertize " | " face (:foreground "#777"))
                    "%p | %l : %c "
                    ;; mode-line-position
                    ;; (vc-mode vc-mode)
                    (vc-mode moody-vc-mode)
                    " "
                    ;; (:eval (moody-tab (substring vc-mode 1) 20 'up))
                    ;; mode-line-modes
                    mode-line-misc-info
                    "  "
                    mode-line-end-spaces)))))

;;----------------------------------------------------------------------------
;; Theme
;;----------------------------------------------------------------------------
(use-package theme
  :demand
  :bind (("C-c y" . zp/variable-pitch-mode)
         ("C-c T" . zp/switch-emacs-theme)
         :map zp/toggle-map
         (("t" . zp/switch-emacs-theme)
          ("y" . zp/helm-select-font-dwim)))
  :config
  ;; Fonts
  (zp/set-font "sarasa")
  (zp/set-font-variable "equity")

  ;; Day/night cycle
  (setq zp/time-of-day-sections '("06:00" "08:00" "16:00" "20:00" "00:00"))
  (zp/switch-theme-auto))

;;----------------------------------------------------------------------------
;; Interaction with terminal emulators
;;----------------------------------------------------------------------------
(defun zp/terminator-dwim (&optional arg)
  "Run terminator in the CWD.

Trim unnecessary TRAMP information from the path (e.g. /sudo:…),
and forward it to terminator. ARGUMENTS can be any argument
accepted by terminator (e.g. ‘-x command’).

See ‘~/.bin/terminator-dwim’ for more info."
  (interactive)
  (with-current-buffer (window-buffer (selected-window))
    (let* ((path-emacs default-directory)
           (tramp-regex "/sudo:root@.*?:")
           (path (replace-regexp-in-string
                  tramp-regex "" path-emacs)))
      (shell-command
       (concat "terminator --working-dir \"" path "\""
               (if arg (concat " " arg)))))))

;;----------------------------------------------------------------------------
;; Late packages
;;----------------------------------------------------------------------------
;; Packages which are required to be loaded late
;; TODO: See if I can handle that with use-package

;; Magnars's codes
;; expand-region causes weird flicker with repeated tasks if it's at the top
;; TODO: Confirm if this is still the case
(use-package expand-region
  :config
  (global-set-key (kbd "H-h") 'er/expand-region))

(use-package multiple-cursors-core)

(use-package mc-edit-lines
  :config
  (global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines))

(use-package mc-mark-more
  :config
  (global-set-key (kbd "C->") 'mc/mark-next-like-this)
  (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this))

;; Disable lighters for some minor-modes
(use-package diminish
  :config
  (diminish 'ivy-mode)
  (diminish 'helm-mode)
  (diminish 'auto-revert-mode)
  (diminish 'anzu-mode)
  (diminish 'yas-minor-mode)
  (diminish 'which-key-mode)
  (diminish 'volatile-highlights-mode)
  (diminish 'undo-tree-mode)
  (diminish 'whitespace-mode)
  (diminish 'magit-wip-mode)
  (diminish 'ws-butler-mode))

;;----------------------------------------------------------------------------
;; Custom
;;----------------------------------------------------------------------------
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(auth-source-save-behavior nil)
 '(gdb-many-windows t)
 '(global-hl-line-mode t)
 '(helm-external-programs-associations
   (quote
    (("xlsx" . "localc")
     ("docx" . "lowriter")
     ("gpg" . "evince")
     ("mp4" . "smplayer")
     ("mkv" . "smplayer")
     ("dvi" . "evince")
     ("svg" . "inkscape")
     ("odt" . "lowriter")
     ("png" . "gimp")
     ("html" . "firefox")
     ("pdf" . "evince"))))
 '(ledger-reports
   (quote
    (("bal-last" "ledger bal ^expenses -p last\\ week and not commons and not swimming")
     ("bal-week" "ledger bal ^expenses -p this\\ week and not commons and not swimming")
     ("bal" "ledger -f ~/org/main.ledger bal")
     ("reg" "%(binary) -f %(ledger-file) reg")
     ("payee" "%(binary) -f %(ledger-file) reg @%(payee)")
     ("account" "%(binary) -f %(ledger-file) reg %(account)"))))
 '(magit-log-arguments (quote ("--graph" "--color" "--decorate" "-n256")))
 '(magit-submodule-arguments (quote ("--recursive")))
 '(org-emphasis-alist
   (quote
    (("*" bold)
     ("/" italic)
     ("_" underline)
     ("=" org-code verbatim)
     ("~" org-verbatim verbatim)
     ("+"
      (:strike-through t))
     ("@" org-todo))))
 '(org-file-apps
   (quote
    (("\\.pdf\\'" . "evince %s")
     ("\\.epub\\'" . "ebook-viewer %s")
     ("\\.mobi\\'" . "ebook-viewer %s")
     ("\\.doc\\'" . "lowriter %s")
     (auto-mode . emacs)
     ("\\.mm\\'" . default)
     ("\\.x?html?\\'" . default)
     ("\\.pdf\\'" . default))))
 '(package-selected-packages
   (quote
    (slime highlight-indent-guides dracula-theme use-package org-brain racket-mode wgrep fountain-mode org-mind-map org org-ref orgalist ws-butler minions moody org-super-agenda backup-walker bug-hunter org-plus-contrib messages-are-flowing notmuch forge go-mode company-anaconda anaconda-mode company realgud ace-link ivy-hydra counsel lispy dumb-jump lua-mode fish-mode exwm el-patch diminish circe-notifications circe ob-async nov which-key eyebrowse diff-hl recentf-ext flycheck-pos-tip helm-projectile projectile clean-aindent-mode volatile-highlights duplicate-thing org-noter magit hydra highlight mu4e-alert ox-hugo writeroom-mode anzu flycheck spaceline helm-chronos chronos olivetti multiple-cursors expand-region ace-window auto-minor-mode ledger-mode sublimity auctex smooth-scrolling yasnippet pdf-tools htmlize helm-bibtex free-keys evil color-theme base16-theme)))
 '(safe-local-variable-values
   (quote
    ((eval add-hook
           (quote after-save-hook)
           (function org-hugo-export-wim-to-md-after-save)
           :append :local)
     nil
     (org-confirm-babel-evaluate)
     (after-save-hook . org-html-export-to-html))))
 '(send-mail-function (quote mailclient-send-it))
 '(size-indication-mode t)
 '(smtpmail-smtp-server "127.0.0.1")
 '(smtpmail-smtp-service 25))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(put 'LaTeX-narrow-to-environment 'disabled nil)
(put 'TeX-narrow-to-group 'disabled nil)
