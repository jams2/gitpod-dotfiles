(setq custom-file "~/.emacs.d/josh-custom.el"
      gc-cons-threshold 100000000
      read-process-output-max (* 1024 1024)
      lsp-use-plists t
      backup-directory-alist `(("." . ,(concat user-emacs-directory ".backups")))
      backup-by-copying t
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)

(defvar bootstrap-version)

(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setq straight-vc-git-default-protocol 'ssh)

(straight-use-package 'use-package)
(setq straight-use-package-by-default t
      use-package-verbose t)

(require 'treesit)
(setq treesit-extra-load-path '("/usr/local/lib/"))

(use-package emacs
  :after (exec-path-from-shell)
  :demand t
  :ensure nil
  :init
  (scroll-bar-mode -1)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (xclip-mode 1)
  (add-to-list 'default-frame-alist '(font . "PragmataPro Liga 11"))
  (add-to-list 'initial-frame-alist '(font . "PragmataPro Liga 11"))
  (add-to-list 'default-frame-alist '(alpha-background . 100))
  (add-to-list 'initial-frame-alist '(alpha-background . 100))

  (defun josh-delete-trailing-whitespace ()
    "Delete all trailing whitespace and trailing lines."
    (interactive)
    (if (not delete-trailing-lines)
        (setq delete-trailing-lines t))
    (delete-trailing-whitespace 0 nil))

  (defun josh/indent-buffer ()
    (interactive)
    (save-excursion
      (indent-region (point-min) (point-max))))

  (defconst python-c-style
    '("python"
      (indent-tabs-mode . nil)
      (c-basic-offset . 4))
    "Rectified CPython style")

  (c-add-style "python3" python-c-style)

  (defun my-eval-region-or-buffer ()
    (interactive)
    (if (region-active-p)
        (call-interactively 'eval-region)
      (call-interactively 'eval-buffer)))

  (defun my-emacs-lisp-mode-hook ()
    (bind-key "C-c C-c" #'my-eval-region-or-buffer 'emacs-lisp-mode-map)
    (bind-key "C-c e" #'macrostep-expand 'emacs-lisp-mode-map))

  :config
  (put 'downcase-region 'disabled nil)
  (put 'narrow-to-region 'disabled nil)

  (global-prettify-symbols-mode 1)
  (setq-default prettify-symbols-unprettify-at-point 'right-edge)

  (show-paren-mode 1)
  (setq shell-command-switch "-lc"
        completion-ignore-case t
        completion-styles '(flex basic)
        read-file-name-completion-ignore-case t
        read-buffer-completion-ignore-case t
        c-default-style '((c-mode . "gnu"))
        read-file-completion-ignore-case t
        read-buffer-completion-ignore-case t
        vc-follow-symlinks t
        show-paren-delay 0)
  (savehist-mode 1)
  (global-auto-revert-mode 1)
  (add-to-list 'auto-mode-alist '("Dockerfile" . dockerfile-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.rs?\\'" . rust-ts-mode))

  (setq tramp-default-method "ssh")

  :bind (("M-j" . join-line)
         ("M-SPC" . cycle-spacing)
         ("<f5>" . josh-delete-trailing-whitespace)
         ("C-M-\\" . josh/indent-buffer)
         ("C-M-i" . company-complete))
  :hook
  (emacs-lisp-mode . my-emacs-lisp-mode-hook))

(use-package ielm
  :bind (:map ielm-map
              ("C-j" . electric-newline-and-maybe-indent))
  :config
  (defun my-ielm-init-history ()
    (let ((path (expand-file-name "ielm/history" user-emacs-directory)))
      (make-directory (file-name-directory path) t)
      (setq-local comint-input-ring-file-name path))
    (setq-local comint-input-ring-size 10000)
    (setq-local comint-input-ignoredups t)
    (comint-read-input-ring))

  (defun g-ielm-write-history (&rest _args)
    (with-file-modes #o600
      (comint-write-input-ring)))

  (advice-add 'ielm-send-input :after 'g-ielm-write-history)

  (defun my-ielm-mode-hook ()
    (electric-pair-local-mode 1)
    (eldoc-mode 1)
    (my-ielm-init-history))
  :hook (ielm-mode . my-ielm-mode-hook))

(use-package ef-themes)

(use-package standard-themes)

(use-package ace-window
  :config
  (defun my-ace-window (&optional arg)
    "Use `other-window' if there's only two windows visible."
    (interactive "p")
    (if (and (= (length (window-list)) 2)
             (= arg 1))
        (call-interactively 'other-window)
      (call-interactively 'ace-window)))

  (setq aw-keys '(?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9))

  :bind
  ("M-o" . my-ace-window))

(use-package xclip
  :demand t)

(use-package browse-url
  :defer t
  :config
  (setq browse-url-browser-function 'browse-url-generic
        browse-url-generic-program "firefox"))

(use-package ripgrep)

(use-package rg)

(use-package exec-path-from-shell
  :demand t
  :init
  (when (daemonp)
    (exec-path-from-shell-initialize)))

(use-package vterm
  :config
  (setq vterm-max-scrollback 10000)
  :commands (vterm vterm-other-window))

(use-package magit
  :config (setq magit-view-git-manual-method 'man))

(use-package async
  :defer t)

(use-package with-editor
  :defer t)

(use-package orderless
  :init
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (setq orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch)
  ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package vertico
  :init
  (setq completion-category-defaults nil)
  (vertico-mode))

(use-package consult
  :bind (("C-c r" . consult-ripgrep)))

(use-package jsonrpc)

(use-package electric
  :hook
  ((emacs-lisp-mode python-mode python-ts-mode scheme-mode inferior-scheme-mode)
   . electric-pair-local-mode))

(use-package undo-tree
  :demand t
  :init
  (setq my-undo-dir (expand-file-name "~/.emacs.d/undo-history/"))
  (if (not (file-exists-p my-undo-dir))
      (mkdir my-undo-dir))
  :config
  (setq undo-tree-history-directory-alist
        `(("." . ,my-undo-dir)))
  (global-undo-tree-mode))

(use-package projectile
  :bind (("C-c j" . projectile-find-file))
  :defer t)

(use-package flymake
  :config
  (defun my-window-bottom-left-side-window-p (buf act)
    (with-current-buffer buf (member major-mode '(flymake-diagnostics-buffer-mode))))

  (add-to-list 'display-buffer-alist
               '(my-window-bottom-left-side-window-p
                 (display-buffer-in-side-window)
                 (window-height . 0.30)
                 (window-width . 0.55)
                 (dedicated . t)
                 (side . bottom)
                 (slot . 0)
                 (window-parameters . ((mode-line-format . 'none)))))

  (defun my-hide-flymake-buffer-diagnostics ()
    (interactive)
    (dolist (buf (buffer-list))
      (when (string-prefix-p "*Flymake diagnostics" (buffer-name buf))
        (let ((window (get-buffer-window (buffer-name buf))))
          (when window
            (quit-window nil window))))))

  (bind-key "C-c ! l" #'flymake-show-buffer-diagnostics 'flymake-mode-map)
  (bind-key "C-c ! n" #'flymake-goto-next-error 'flymake-mode-map)
  (bind-key "C-c ! p" #'flymake-goto-prev-error 'flymake-mode-map)
  (bind-key "C-c ! q" #'my-hide-flymake-buffer-diagnostics 'flymake-mode-map))

(use-package company
  :demand t
  :bind
  ("C-M-i" . company-complete)
  :init
  (global-company-mode 1)
  :config
  (setq company-minimum-prefix-length 3
        company-idle-delay nil))  ;; default is 0.2

(defun my-eglot-hook ()
  (add-hook 'flymake-diagnostic-functions 'eglot-flymake-backend nil t)
  (when (eglot-managed-p)
    (bind-keys :map eglot-mode-map ("<C-M-i>" . company-complete))
    (flymake-mode 1)))

(add-hook 'eglot-managed-mode-hook 'my-eglot-hook)

(use-package web-mode
  :defer t
  :init
  (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
  :config
  (add-to-list 'web-mode-content-types-alist '("jsx" . "\\.js[x]?\\'"))
  (setq web-mode-django-control-blocks-regexp (regexp-opt web-mode-django-control-blocks t)
        web-mode-engines-alist '(("django" . ".*html"))
        web-mode-enable-auto-expanding t
        web-mode-attr-indent-offset 4
        web-mode-attr-value-indent-offset 4
        web-mode-markup-indent-offset 4
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 4))

(use-package yaml-mode
  :defer t
  :init
  (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode)))

(use-package js
  :init
  (add-to-list 'auto-mode-alist '("\\.jsx?\\'" . js-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
  (defun josh-js-mode-hook ()
    (setq prettify-symbols-alist nil)
    (bind-key "M-." #'xref-find-definitions 'js-mode-map)
    (bind-key "M-?" #'xref-find-references 'js-mode-map)
    (bind-key "M-," #'xref-go-back 'js-mode-map))
  :hook
  ((js-mode . electric-pair-local-mode)
   (js-mode . josh-js-mode-hook)))

(add-to-list 'auto-mode-alist '("\\.py[iw]?\\'" . python-ts-mode))

(defun my-setup-python-shell ()
  (add-to-list 'comint-output-filter-functions #'python-comint-render-svg)
  (electric-pair-mode))

(defun my-python-shell-send-buffer ()
  (interactive)
  (save-excursion
    (python-shell-send-buffer)))

(setq python-prettify-symbols-alist '(("lambda"  . ?𝛌))
      python-indent-def-block-scale 1)

(defun start-yas-before-eglot ()
  (yas-minor-mode-on)
  (eglot-ensure))

(defun my-python-mode-hook ()
  (start-yas-before-eglot)
  (electric-indent-mode 1)
  (electric-pair-local-mode 1)
  (bind-key "C-c C-c" #'my-python-shell-send-buffer 'python-mode-map)
  (bind-key "C-c C-c" #'my-python-shell-send-buffer 'python-ts-mode-map)
  (bind-key "C-M-i" #'company-complete 'python-ts-mode-map))

(add-hook 'inferior-python-mode-hook 'my-setup-python-shell)
(add-hook 'python-ts-mode-hook 'my-python-mode-hook)
(add-hook 'python-mode-hook #'remove-flymake-python-backend 100)

(use-package python-black
  :config
  (setq python-black-extra-args '("--target-version" "py310"))
  :commands
  (python-black-region
   python-black-buffer
   python-black-partial-dwim
   python-black-statement))

(use-package virtualenvwrapper
  :demand t
  :commands (venv-workon venv-deactivate))

(defun length= (sequence i)
  (= (length sequence) i))

(defun length> (sequence i)
  (> (length sequence) i))

(use-package gud
  :init
  (defconst gud-window-register 123456)

  :config
  (defun gud-quit ()
    (interactive)
    (gud-basic-call "quit"))

  (defun my-gud-mode-hook ()
    (gud-tooltip-mode)
    (window-configuration-to-register gud-window-register))

  (setq-default gdb-many-windows t
                gdb-use-separate-io-buffer t)

  (advice-add 'gdb-setup-windows :after
              (lambda () (set-window-dedicated-p (selected-window) t)))

  (advice-add 'gud-sentinel :after
              (lambda (proc msg)
                (when (memq (process-status proc) '(signal exit))
                  (jump-to-register gud-window-register)
                  (bury-buffer))))
  :hook
  (gud-mode . my-gud-mode-hook))



