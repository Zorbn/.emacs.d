(defvar nic/default-font-size 120)          ;; For monospaced fonts
(defvar nic/default-variable-font-size 120) ;; For non-monospaced fonts

(setq gc-cons-threshold (* 50 1000 1000))   ;; Increased to speed up loading

(defun nic/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                     (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'nic/display-startup-time)

;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(use-package auto-package-update
  :custom
  (auto-package-update-interval 7)
  (auto-package-update-prompt-before-update t)
  (auto-package-update-hide-results t)
  :config
  (auto-package-update-maybe)
  (auto-package-update-at-time "09:00"))

;; Properly organize auto-generated files
(use-package no-littering)
(setq auto-save-file-name-transforms
      `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
(setq custom-file (concat user-emacs-directory "/custom.el"))

;; Remove default clutter
(setq inhibit-startup-message t)
(setq initiali-scratch-message ";; Hello World")

(scroll-bar-mode -1)              ; Disable visible scrollbar
(tool-bar-mode -1)                ; Disable the toolbar
(tooltip-mode -1)                 ; Disable tooltips
(set-fringe-mode 10)              ; Give some breathing room
(menu-bar-mode -1)                ; Disable the menu bar
(setq ring-bell-function 'ignore) ; Disable the bell

;; Scroll one line at a time (less "jumpy" than defaults)
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))) ;; One line at a time
(setq mouse-wheel-progressive-speed nil)            ;; Don't accelerate scrolling
(setq mouse-wheel-follow-mouse 't)                  ;; Scroll window under mouse
(setq scroll-step 1)                                ;; Keyboard scroll one line at a time

;; Enable line numbers
(column-number-mode)
(global-display-line-numbers-mode 'relative)

;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                treemacs-mode-hook
                eshell-mode-hook
                vterm-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(defun nic/set-fonts ()
  ;; Set monospaced fonts
  (set-face-attribute 'default nil :font "JetBrains Mono" :height nic/default-font-size)
  (set-face-attribute 'fixed-pitch nil :font "JetBrains Mono" :height nic/default-font-size)
  ;; Set proportional fonts
  (set-face-attribute 'variable-pitch nil :font "Ubuntu" :height nic/default-variable-font-size :weight 'regular))

(if (daemonp)
  (add-hook 'server-after-make-frame-hook 'nic/set-fonts)
  (nic/set-fonts))

;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; General terminal utils
(defun nic/set-term-prompt-regexp ()
  (setq term-prompt-regexp "^[^#$%>\n]*[#$%>] *"))

(use-package eterm-256color
  :hook (term-mode . eterm-256color-mode))

;; VTerm
(use-package vterm
  :commands vterm
  :config
  (nic/set-term-prompt-regexp) ;; Custom prompt
  (setq vterm-timer-delay 0.01)
  (setq vterm-max-scrollback 10000))

;; EShell
(defun nic/configure-eshell ()
  ;; Save command history when commands are entered
  (add-hook 'eshell-pre-command-hook 'eshell-save-some-history)

  ;; Truncate buffer for performance
  (add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)

  ;; Bind some useful keys for evil-mode
  (evil-define-key '(normal insert visual) eshell-mode-map (kbd "C-r") 'counsel-esh-history)
  (evil-define-key '(normal insert visual) eshell-mode-map (kbd "<home>") 'eshell-bol)
  (evil-normalize-keymaps)

  (setq eshell-history-size         10000
        eshell-buffer-maximum-lines 10000
        eshell-hist-ignoredups t
        eshell-scroll-to-bottom-on-input t))

(use-package eshell-git-prompt
  :after eshell)

(use-package eshell
  :hook (eshell-first-time-mode . nic/configure-eshell)
  :config

  (with-eval-after-load 'esh-opt
    (setq eshell-destroy-buffer-when-process-dies t)
    (setq eshell-visual-commands '("htop" "zsh" "vim")))

  (eshell-git-prompt-use-theme 'powerline))

;; Term
(use-package term
  :commands term
  :config
  (setq explicit-shell-file-name "bash")

  ;; Should match the vterm prompt
  (nic/set-term-prompt-regexp))

(defun toggle-maximize-buffer () "Maximize buffer"
  (interactive)
  (if (= 1 (length (cl-remove-if #'treemacs-is-treemacs-window? (window-list))))
      (jump-to-register '_) 
    (progn
      (window-configuration-to-register '_)
      (delete-other-windows))))

;; Leader keybinds
(use-package general
  :after evil
  :config
  (general-create-definer nic/leader-keys
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")

  (nic/leader-keys
    "t" '(:ignore t :which-key "Toggle")
    "tt" '(treemacs :which-key "Treemacs")
    "tm" '(toggle-maximize-buffer :which-key "Maximized buffer")
    "o" '(:ignore t :which-key "Open")
    "ot" '(vterm :which-key "VTerm")
    "os" '(eshell :which-key "EShell")
    "l"  '(:package lsp-mode :keymap lsp-command-map :which-key "LSP commands")
    "m" '(:ignore t :which-key "Move")
    "mtd" '(treemacs-select-directory :whick-key "Treemacs directory")
    "mf" '(centaur-tabs-forward :which-key "To next tab")
    "mb" '(centaur-tabs-backward :which-key "To previous tab")))

(use-package which-key
  :defer 0
  :diminish which-key-mode
  :config
  (which-key-mode)
  (setq which-key-idle-delay 1))

;; Become EVIL
(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  :config
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)

  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; Themes
(use-package doom-themes
  :init (load-theme 'doom-one t))

(use-package all-the-icons)

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 32)))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(blink-cursor-mode 0)

;; LSP
(defun nic/lsp-mode-setup ()
  (setq lsp-headerline-breadcrumb-segments '(path-up-to-project file symbols))
  (lsp-headerline-breadcrumb-mode))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :hook (lsp-mode . nic/lsp-mode-setup)
  :config
  (lsp-enable-which-key-integration t))

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-doc-position 'bottom))

(use-package lsp-treemacs
  :after lsp)

(use-package treemacs-all-the-icons
  :config
  (treemacs-load-theme "all-the-icons"))

(use-package lsp-ivy
  :after lsp)

;; Dired
(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :custom ((dired-listing-switches "-agho --group-directories-first"))
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-single-up-directory
    "l" 'dired-single-buffer))

(use-package dired-single
  :commands (dired dired-jump))

(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))

;; Enables external programs for opening files with
;; (use-package dired-open
;;   :commands (dired dired-jump)
;;   :config
;;   ;; Set these to your preffered media viewers
;;   (setq dired-open-extensions '(("png" . "feh")
;;                                 ("mkv" . "mpv"))))

;; Tabs
(use-package centaur-tabs
  :demand
  :config
  (setq centaur-tabs-style "bar"
	centaur-tabs-set-icons t
	centaur-tabs-height 32
	centaur-tabs-set-bar 'under
	x-underline-at-descent-line t
	centaur-tabs-gray-out-icons 'buffer)
  (centaur-tabs-headline-match)
  (centaur-tabs-mode t))

;; Make gc pauses faster by decreasing the threshold.
;; Belongs after all setup has taken place
(setq gc-cons-threshold (* 2 1000 1000))
