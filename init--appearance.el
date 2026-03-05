;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; =================
;;; ===== FONTS =====
;;; =================


(my-init--with-duration-measured-section 
 t
 "Fonts"

 (defun my-init--default-font ()
   "Return default font as a string."  
   (let* ((tmp1 (face-attribute 'default :font))
          (tmp2 (prin1-to-string tmp1))
          (tmp3 (split-string tmp2 "-")))
     (elt tmp3 3)))

 (defun my/get-default-font ()
   "Print default font (message)."
   (interactive)
   (message "Default font: %s" (my-init--default-font)))

 ;; redundant with above?
 (defun my/know-current-font ()
   "Print a message with info on current font."
   (interactive)
   (let ((font (face-attribute 'default :family))
         (size (face-attribute 'default :height)))
     (message "Current font family: %s, Size: %d" font (/ size 10))))
 
 (defun my/list-all-system-available-fonts ()
   "List all available fonts in a new buffer."
   (interactive)
   (let ((buf (generate-new-buffer "*Available fonts*"))
         (fonts-list (sort (font-family-list) #'string<)))
     (switch-to-buffer buf)
     (cl-loop for font-name in fonts-list
              for i from 1
              do (insert (format "%s %s \n" i font-name)))
     (goto-char (point-min))))

 (defun my-init--font-exists-p (font-name)
   "Check if font identified by NAME is available."
   (member font-name (font-family-list)))
 ;; inspiration: Xah Lee in http://ergoemacs.org/emacs/emacs_list_and_set_font.html
 ;; alternative: (find-font (font-spec :name name))

 (defun my-init--set-font-if-exists (font-name size)
   "Set font identified by FONT-NAME with size SIZE if font is available; otherwise error."
   (if (my-init--font-exists-p font-name)
       (set-frame-font (format "%s %s" font-name size) nil t)
     (error "Font is not available: %s" font-name)))

 (when nil

   ;; WARNING reference to free variable ‘efs/default-font-size’
   
   (defun my/set-firacode-fonts ()
     "Sets Fira code fonts."
     (if (not (my-init--font-exists-p "Fira Code Retina"))
         (error "Font is not available: Fira Code Retina")
       (if (not (my-init--font-exists-p "Cantarell"))
           (error "Font is not available: Cantarell")
         (defvar efs/default-font-size 80))       ; 90 ; 180
       (defvar efs/default-variable-font-size 80) ; 90 ; 180
       (set-face-attribute 'default nil :font "Fira Code Retina" :height efs/default-font-size)
       ;; Set the fixed pitch face
       (set-face-attribute 'fixed-pitch nil :font "Fira Code Retina" :height efs/default-font-size)
       ;; Set the variable pitch face
       (set-face-attribute 'variable-pitch nil :font "Cantarell" :height efs/default-variable-font-size :weight 'regular)))

   (defun my/set-firacode-fonts80 ()
     "Sets Fira code fonts."
     (if (not (my-init--font-exists-p "Fira Code Retina"))
         (error "Font is not available: Fira Code Retina")
       (if (not (my-init--font-exists-p "Cantarell"))
           (error "Font is not available: Cantarell")
         (defvar efs/default-font-size 80))       ; 90 ; 180
       (defvar efs/default-variable-font-size 80) ; 90 ; 180
       (set-face-attribute 'default nil :font "Fira Code Retina" :height efs/default-font-size)
       ;; Set the fixed pitch face
       (set-face-attribute 'fixed-pitch nil :font "Fira Code Retina" :height efs/default-font-size)
       ;; Set the variable pitch face
       (set-face-attribute 'variable-pitch nil :font "Cantarell" :height efs/default-variable-font-size :weight 'regular)))

   (defun my/set-firacode-fonts85 ()
     "Sets Fira code fonts."
     (if (not (my-init--font-exists-p "Fira Code Retina"))
         (error "Font is not available: Fira Code Retina")
       (if (not (my-init--font-exists-p "Cantarell"))
           (error "Font is not available: Cantarell")
         (defvar efs/default-font-size 85))       ; 90 ; 180
       (defvar efs/default-variable-font-size 85) ; 90 ; 180
       (set-face-attribute 'default nil :font "Fira Code Retina" :height efs/default-font-size)
       ;; Set the fixed pitch face
       (set-face-attribute 'fixed-pitch nil :font "Fira Code Retina" :height efs/default-font-size)
       ;; Set the variable pitch face
       (set-face-attribute 'variable-pitch nil :font "Cantarell" :height efs/default-variable-font-size :weight 'regular)))

   (defun my/set-firacode-fonts90 ()
     "Sets Fira code fonts."
     (if (not (my-init--font-exists-p "Fira Code Retina"))
         (error "Font is not available: Fira Code Retina")
       (if (not (my-init--font-exists-p "Cantarell"))
           (error "Font is not available: Cantarell")
         (defvar efs/default-font-size 90))       ; 90 ; 180
       (defvar efs/default-variable-font-size 90) ; 90 ; 180
       (set-face-attribute 'default nil :font "Fira Code Retina" :height efs/default-font-size)
       ;; Set the fixed pitch face
       (set-face-attribute 'fixed-pitch nil :font "Fira Code Retina" :height efs/default-font-size)
       ;; Set the variable pitch face
       (set-face-attribute 'variable-pitch nil :font "Cantarell" :height efs/default-variable-font-size :weight 'regular)))) ; end of when nil

 (defvar *my-fonts*

   '(("Aptos Mono" 9)
     ("B612 Mono" 8)
     ;; B612 Mono: https://crankysec.com/blog/broken/
     ;; Berkeley Mono (not free): https://laplab.me/posts/whats-that-touchscreen-in-my-room/
     ("Cantarell" 9)
     ("Cascadia Code" 9) ; (my-init--set-font-if-exists "Cascadia Code" 9)
     ("Cascadia Code Medium" 9) ; (my-init--set-font-if-exists "Cascadia Code Medium" 9)
     ;; Cascadia Mono: https://emacsredux.com/blog/2023/03/16/setting-the-default-font-for-emacs/
     ("Consolas" 9)
     ("Consolas" 10)
     ;; Consolas: Notepad
     ;; Consolas: default monospace font on browser
     ;; Consolas: https://neat-lang.github.io/
     ;; Consolas: https://tusharhero.codeberg.page/why_emacs.html
     ;; Consolas: https://computer.rip/2024-02-11-the-top-of-the-DNS-hierarchy.html
     ;; Consolas: https://quiltro.org/code/blit/doc/tip/README.md
     ("Courier New" 10)
     ("Cousine" 8)
     ("Cousine" 9)
     ("CPMono_v07 Plain" 8)
     ("D-DIN" 11)
     ("D2Coding" 9)
     ("DejaVu Sans Mono" 7)
     ("DejaVu Sans Mono" 8)
     ("DM Mono" 8)
     ("DM Mono" 9)
     ("Droid Sans Mono" 8)
     ("Droid Sans Mono" 9) 
     ("Fantasque Sans Mono" 10)
     ("Fira Code Retina" 8)
     ("Fira Code Retina" 9)
     ("FreeMono" 10) ; (my-init--set-font-if-exists "FreeMono" 10)
     ("Go Mono" 8)
     ;; Go Mono: https://twitter.com/TeXtip/status/1537606991987843072
     ("Hack" 8)
     ("Hack" 9)
     ("Hasklig" 9)
     ("IBM Plex Mono" 8) 
     ("IBM Plex Mono" 9)
     ;; IBM Plex Mono: https://vsekar.me/blog/log_coffee/chapter_0.html
     ;; IBM Plex Mono: https://thediggers.co/start/
     ("Inconsolata" 9)
     ;; Inconsolata: https://lock.cmpxchg8b.com/index.html
     ;; Inconsolata: http://antirez.com/news/140
     ("InputMono" 8)
     ("Iosevka" 9)
     ;; Iosevka: https://fy.blackhats.net.au/blog/2024-04-26-passkeys-a-shattered-dream/ 
     ("JetBrains Mono" 8)
     ("JetBrains Mono" 9)
     ("Lekton04" 9)
     ("Liberation Mono" 8)
     ("Lucida Console" 10)
     ;; Lucida Console: https://pluralistic.net/2022/08/21/great-taylors-ghost/#solidarity-or-bust
     ("Luxi Mono" 9)
     ("Martian Mono" 8)
     ("Menlo" 8)
     ("Menlo" 9)
     ("Meslo LG S DZ" 8)                ; from Olivetti mode
     ("Monoid" 7)
     ("Monoid" 8)
     ("Monospace" 10)
     ;; Monospace: https://benjamin.computer/posts/2022-08-17-calculators.html
     ;; Monospace: https://sancarn.github.io/vba-articles/why-do-people-use-vba.html
     ("Noto Sans Mono" 8)
     ("Noto Sans Mono" 9)
     ("Office Code Pro" 9)
     ("Perfect DOS VGA 437" 8)
     ;; Pitch Sans: pop-up of https://www.sequoiacap.com/article/pmf-framework/
     ("PT Mono" 9)
     ;; PT Mono: https://aboutideasnow.com/?q=Common+Lisp
     ("Reddit Mono" 9)
     ("Roboto Mono" 8)
     ("Roboto Mono" 9)
     ;; Roboto Mono: https://jakobgreenfeld.com/insight-porn
     ;; Roboto Mono: https://www.vitling.xyz/i-need-to-grow-away-from-these-roots/
     ;; Roboto Mono: https://blog.kagi.com/kagi-wolfram
     ("Source Code Pro" 8)
     ("Space Mono" 8)
     ("Ubuntu Mono" 10)
     ("Ubuntu Mono" 11)
     ("Victor Mono" 9)
     ("ZX Spectrum" 6))
   "my mono fonts")                     ; end of defvar

 (defvar *my-mono-available-fonts* nil)
 (defvar *my-mono-unavailable-fonts* nil)

 (defun identify-available-and-unavailable-fonts-if-not-done-yet ()
   "Identify available and unavailable fonts if not done yet, by populating '*my-mono-available-fonts*' and '*my-mono-unavailable-fonts*'."
   (when (null *my-mono-available-fonts*)
     (dolist (font1 *my-fonts*)
       (if (my-init--font-exists-p (car font1))
           (push font1 *my-mono-available-fonts*)
         (push (car font1) *my-mono-unavailable-fonts*))) ; (car font1) = family
     (setq *my-mono-available-fonts* (reverse *my-mono-available-fonts*))
     (setq *my-mono-unavailable-fonts* (reverse *my-mono-unavailable-fonts*))))

 (defun my/generate-personal-font-buffer ()
   "Create a buffer showing available fonts and useful commands."
   (interactive)
   (let ((fox-text "The quick brown fox jumps over the lazy dog - 1234567890 - âéùïøçÃĒÆœ - oO08 iIlL1 g9qCGQ 8%& <([{}])> .,;: -_=")
         (buf (get-buffer-create "*My Fonts*"))
         (max-length-of-font-name 0))

     ;; (1) populate *my-mono-available-fonts* and *my-mono-unavailable-fonts*
     (identify-available-and-unavailable-fonts-if-not-done-yet)
     
     ;; (2) Calculate maximum length of font name
     (dolist (font1 *my-mono-available-fonts*)
       (setq max-length-of-font-name
             (max max-length-of-font-name (length (format "%s %s" (car font1) (cadr font1))))))

     ;; (3) Create '*My Fonts*' buffer
     (with-current-buffer buf
       (when (eq buffer-read-only t)
         (read-only-mode -1))
       (erase-buffer)
       (insert "My fonts:\n---------\n")
       (newline)
       (insert "Useful commands:\n")
       (insert "   my/know-current-font\n")
       (insert "   my/list-all-system-available-fonts\n")
       (insert "   M-x text-scale-adjust then +-0\n")
       (newline)
       (insert "(1) Available fonts:\n")
       (insert "Click on any button to change font ;)\n")
       
       (dolist (font1 *my-mono-available-fonts*)
         (let* ((family1 (car font1))
                (height1 (cadr font1))  ; typically: 8, 9
                (string1 (format "%s %s" family1 height1))
                (string2 (format (format "%%-%ds" max-length-of-font-name) string1)))
           (let ((start (point)))
             (insert (format "%s " string2))
             (make-text-button start (point)
                               'action (lambda (_button)
                                         (my-init--set-font-if-exists family1 height1)
                                         (message "Font changed to %s %s" family1 height1)
                                         )
                               'follow-link t
                               'face '(:box (:line-width 2 :color "gray50" :style released-button)
                                            :background "lightgray"
                                            :foreground "black"
                                            :weight bold)
                               'mouse-face '(:box (:line-width 2 :color "gray30" :style pressed-button)
                                                  :background "darkgray"
                                                  :foreground "black"
                                                  :weight bold)
                               'help-echo "Click this button"))
           (insert (propertize fox-text 'face `(:family ,family1 :height ,(* 10 height1))))
           (insert "\n")))

       (insert "\n(2) Unavailable fonts:\n")
       (dolist (family1 *my-mono-unavailable-fonts*)
         (insert family1)
         (insert "\n"))
       
       (goto-char (point-min))
       (read-only-mode 1))              ; end of with-current-buffer

     (switch-to-buffer buf)))           ; end of defun

 ;; The font which is chosen:
 (if (my-init--font-exists-p "DM Mono")
     (my-init--set-font-if-exists "DM Mono" 9)
   (my-init--warning "Font is not available: DM Mono"))
 ;; I like also:
 (when nil
   (my-init--set-font-if-exists "Cascadia Code" 9)
   (my-init--set-font-if-exists "Droid Sans Mono" 8)
   (my-init--set-font-if-exists "Consolas" 9)
   (my-init--set-font-if-exists "Meslo" 10)
   (my-init--set-font-if-exists "Hack" 8)
   (my-init--set-font-if-exists "Roboto Mono" 8)
   (my-init--set-font-if-exists "Fira Code" 9)
   (my-init--set-font-if-exists "Martian Mono" 8) ; to be tested
   )                                              ; end of when nil
 ) ; end of init section


;;; ===
;;; =================
;;; ===== ICONS =====
;;; =================

(my-init--with-duration-measured-section 
 t
 "Icons"

 ;; check if all icons for all-the-icons are available:
 (let ((all-the-icons-font-list '("all-the-icons" "file-icons" "FontAwesome" "Material Icons" "github-octicons" "Weather Icons")))
   (dolist (font-name all-the-icons-font-list)
     (unless (my-init--font-exists-p font-name)
       (my-init--warning "all-the-icons font is not available: %s" font-name))))

 ;; redundant:
 (when nil
   (use-package all-the-icons
     :hook (dired-mode . all-the-icons-dired-mode)
     ;; :commands (dired)
     ;; :after (dired)
     :config
     (my-init--message-package-loaded "all-the-icons")))
 ;; to display all icons: (all-the-icons-insert-icons-for 'fileicon)

 (when nil
   (push '("\\.pbix$" all-the-icons-octicon "graph" :v-adjust 0.0 :face all-the-icons-dblue) all-the-icons-icon-alist)
   (push '("\\.xls[xm]?$"   all-the-icons-fileicon "excel" :face all-the-icons-blue) all-the-icons-icon-alist))
 
 ;; fonts shall be installed
 ;; M-x all-the-icons-install-fonts allows downloading theme

 ;; Slow Rendering:
 ;; If you experience a slow down in performance when rendering multiple icons simultaneously,
 ;; you can try setting the following variable
 ;; (setq inhibit-compacting-font-caches t) 
 ) ; end of init section


;;; ===
;;; ===============================
;;; ==== FEATURES FOR ALL MODES ===
;;; ===============================

(my-init--with-duration-measured-section
 t
 "Features for all modes"
 
 (defun my/copy-word ()
   "Copy word."
   (interactive)
   (let ((bounds (bounds-of-thing-at-point 'symbol))
         (found nil))
     (when bounds
       (setq found t)
       (copy-region-as-kill (car bounds) (cdr bounds))
       (message "Copied word: %s" (buffer-substring-no-properties (car bounds) (cdr bounds))))
     found))

 (global-set-key (kbd "C-c c") 'my/copy-word)) ; end of init section


;;; ===
;;; ======================
;;; ===== DECORATION =====
;;; ======================

(my-init--with-duration-measured-section
 t
 "Decoration"

 ;; No window decoration:
 (tool-bar-mode -1)           ; no icon bar
 ;; (tooltip-mode -1) 
 (menu-bar-mode -1)           ; no menu bar
 (scroll-bar-mode -1)         ; (toggle-scroll-bar -1) ; no scroll bar
 ;; (global-display-line-numbers-mode 1) ; Show line numbers everywhere
 
 ;; Some breathing room:
 (set-fringe-mode 10)                   ; 
 
 ;; Show column and line numbers in the mode line:
 (setq column-number-mode t)

 ;; When line number on the left, highlight them:
 (custom-set-faces
  '(line-number-current-line ((t (:inherit line-number :foreground "white")))))
 ;; inspired by https://stackoverflow.com/questions/54294435/change-color-of-current-line-number-for-spacemacs-emacs
 ;; (custom-set-faces
 ;;     '(line-number-current-line ((t (:inherit line-number :background "white" :foreground "color-16")))))

 (defun my/toggle-menu-bar-mode ()
   "Show or hide menu bar."
   (interactive)
   (if menu-bar-mode
       (menu-bar-mode -1)
     (menu-bar-mode 1)))
 ;; for hydra

 (defun my/toggle-tool-bar-mode ()
   "Show or hide tool bar."
   (interactive)
   (if tool-bar-mode
       (tool-bar-mode -1)
     (tool-bar-mode 1)))
 ;; for hydra

 (defun my/toggle-scroll-bar-mode ()
   "Show or hide scroll bar."
   (interactive)
   (if scroll-bar-mode
       (scroll-bar-mode -1)
     (scroll-bar-mode 1)))
 ;; for hydra

 ;; visible bell:
 (setq visible-bell t)

 ;; no dialog box:
 (setq use-dialog-box nil)

 ;; pixel scrolling:
 (if (>= emacs-major-version 29)
     (pixel-scroll-precision-mode 1)
   (my-init--warning "Could not set pixel-scroll-precision-mode, since Emacs version is not >= 29"))

 ;; parenthesis:
 ;; (setq show-paren-mode nil) ; 1 by default since Emacs 28.1

 ) ; end of init section


;;; ===
;;; ============
;;; === TABS ===
;;; ============

(my-init--with-duration-measured-section
 t
 "Tabs"

 ;; eyebrowse
 (when nil
   (use-package eyebrowse ; allows having several working environments
     ;; requires dash-2.7.0, emacs-24.3.1
     :config
     (my-init--message-package-loaded "eyebrowse")
     (eyebrowse-mode t)))
 ;; Eyebrowse to have several working environments (C-c C-w 2 etc...)
 ;; Eyebrowse shall be loaded at the end since to interference with org-mode bindings

 (global-set-key (kbd "C-x -") #'window-swap-states))


;;; ===
;;; ===============
;;; === BUFFERS ===
;;; ===============

(my-init--with-duration-measured-section
 
 "Buffers"
 ;; Better-looking list of buffers:
 (defalias 'list-buffers 'ibuffer) ; make ibuffer default

 ;; icons for ibuffer C-x C-b, not be confounded with C-x b
 (use-package all-the-icons-ibuffer
   :commands (list-buffers)
   :config
   (all-the-icons-ibuffer-mode 1)
   (my-init--message-package-loaded "all-the-icons-ibuffer"))

 (defun my/kill-all-buffers-except-stars ()
   "Save buffers, then kill all buffers except those beginning with a star (*). Concerned: files and directories. (2024-04-16)"
   (interactive)
   (save-some-buffers)
   (mapc 'kill-buffer
         (cl-remove-if-not
          (lambda (buff)
            (not (or (string-prefix-p "*" (buffer-name buff))
                     (string-prefix-p " *" (buffer-name buff))
                     (string-prefix-p "  *" (buffer-name buff)))))
          (buffer-list))))

 ;; Save cursor position in files:
 (save-place-mode 1)

 ;; Update buffers when files change on disk:
 (global-auto-revert-mode 1)

 ;; Better scrolling:
 (when nil
   (setq scroll-conservatively 101)     ; Don't jump around
   (setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
   (setq mouse-wheel-progressive-speed nil))) ; end of init section


;;; ===
;;; ==============
;;; === CURSOR ===
;;; ==============

(my-init--with-duration-measured-section
 t
 "Cursor"

 ;; Cursor type:
 ;; (setq-default cursor-type 'bar)
 
 ;; Cursor width:
 (setq x-stretch-cursor t)
 ;; make cursor the width of the character it is under,
 ;; i.e. full width of a TAB

 ;; to avoid blinking cursor:
 (when nil
   (blink-cursor-mode -1))

 ;; cursor color:
 ;; (set-cursor-color "#7FFF00") ; green (chartreuse)
 ;; (set-cursor-color "yellow")
 ;; (set-cursor-color "violet")

 (defun my/green-cursor ()
   "Set cursor cursor to green."
   (interactive)
   (if (my-init--light-background-p)
       (set-cursor-color "#228B22")     ; forest green
     (set-cursor-color "#7FFF00")       ; green (chartreuse)
     ))
 
 (defun my/violet-cursor ()
   "Set cursor cursor to violet."
   (interactive)
   (set-cursor-color "violet"))

 (defun my/yellow-cursor ()
   "Set cursor cursor to yellow."
   (interactive)
   (set-cursor-color "yellow"))

 (defun my/orange-cursor ()
   "Set cursor cursor to orange."
   (interactive)
   (set-cursor-color "orange"))

 (defun my/blue-cursor ()
   "Set cursor cursor to blue."
   (interactive)
   (set-cursor-color "deep sky blue"))

 ;; start with specific color for the cursor:
 (add-hook 'emacs-startup-hook
           (lambda ()
             (my/orange-cursor)))
 ) ; end of init section


;;; ===
;;; ========================
;;; === APPAREANCE HYDRA ===
;;; ========================

(my-init--with-duration-measured-section 
 t
 "Appearance hydra"

 (defhydra hydra-appearance (:exit t :hint nil)
   "
^Appearance hydra:
^-----------------

_m_: toogle _m_enu bar
_s_: toggle _s_croll bar
_t_: toggle _t_ool bar

M-x keycast-mode: show current key and its meaning on the command line
"
   ("m" #'my/toggle-menu-bar-mode)
   ("s" #'my/toggle-scroll-bar-mode)
   ("t" #'my/toggle-tool-bar-mode))) ; end of init section


;;; ===
;;; ==================
;;; ===== THEMES =====
;;; ==================

(my-init--with-duration-measured-section 
 t 
 "Themes"

 (defun my-init--set-transparency (level)
   "Set frame transparency at ( LEVEL . LEVEL )"
   (set-frame-parameter (selected-frame) 'alpha (cons level level))
   (setf (alist-get 'alpha default-frame-alist) (cons level level)))

 (defun my/change-transparency ()
   "Ask for LEVEL and change transparency to ( LEVEL . LEVEL )"
   (interactive)
   (my-init--set-transparency (read-number "Transparency level (0 to 100 = opaque): ")))

 (defun my/get-transparency ()
   "Print transparency."
   (interactive)
   (message "Default transparency is: %s"
            (cdr (assoc 'alpha default-frame-alist))))

 (defvar *my-themes* nil)

 (defun my/get-background ()
   "Print background (light or dark)"
   (interactive)
   (message "Background is (light/dark): %s"
            (frame-parameter nil 'background-mode)))

 (defun my-init--light-background-p ()
   "Return t if light background"
   (eq (frame-parameter nil 'background-mode) 'light))

 (defun my-init--dark-background-p ()
   "Return t if dark background"
   (eq (frame-parameter nil 'background-mode) 'dark))

 (defun my/disable-all-themes ()
   "Disable all themes."
   (interactive)
   (while custom-enabled-themes
     (message "Disabling theme: %s" (car custom-enabled-themes))
     (disable-theme (car custom-enabled-themes)))
   (message "All themes disabled."))

 ;; == Afternoon theme

 (use-package afternoon-theme
   :defer t
   :config (my-init--message-package-loaded "afternoon-theme"))
 (push '("Afternoon" (lambda () (load-theme 'afternoon t)) "dark") *my-themes*)

 ;; == Alect theme

 (use-package alect-themes
   :defer t
   :config (my-init--message-package-loaded "alect-themes"))
 (push '("Alect dark" (lambda () (load-theme 'alect-dark t)) "dark") *my-themes*)
 (push '("Alect light" (lambda () (load-theme 'alect-light t)) "light") *my-themes*)

 ;; === Doom themes

 (use-package doom-themes
   :defer t
   :config
   (setq doom-themes-enable-bold t ; if nil, bold is universally disabled
         doom-themes-enable-italic t) ; if nil, italics is universally disabled
   (my-init--message-package-loaded "doom-themes"))
 (push '("Doom Pale Night" (lambda () (load-theme 'doom-palenight t)) "dark") *my-themes*)
 (push '("Doom One" (lambda () (load-theme 'doom-one t)) "dark") *my-themes*)
 (push '("Doom Vibrant" (lambda () (load-theme 'doom-vibrant t)) "dark") *my-themes*)
 (push '("Doom City Lights" (lambda () (load-theme 'doom-city-lights t)) "dark") *my-themes*)
 (push '("Doom One Light" (lambda () (load-theme 'doom-one-light t)) "light") *my-themes*) 
 (push '("Doom Challenger Deep" (lambda () (load-theme 'doom-challenger-deep t)) "dark") *my-themes*)

 ;; === Flatland theme

 (use-package flatland-theme
   :defer t
   :config (my-init--message-package-loaded "flatland-theme"))
 (push '("Flatland" (lambda () (load-theme 'flatland t)) "dark") *my-themes*)
 
 ;; === Gruvbox theme

 (use-package gruvbox-theme
   :defer t
   :config (my-init--message-package-loaded "gruvbox-theme"))
 (push '("Gruvbox dark medium" (lambda () (load-theme 'gruvbox-dark-medium t)) "dark") *my-themes*)
 (push '("Gruvbox light soft" (lambda () (load-theme 'gruvbox-light-soft t)) "light") *my-themes*)
 (push '("Gruvbox light medium" (lambda () (load-theme 'gruvbox-light-medium t)) "light") *my-themes*)

 ;; === Leuven theme

 (push '("Leuven" (lambda () (load-theme 'leuven t)) "light") *my-themes*)

 ;; === Modus Vivendi

 (push '("Modus Vivendi" (lambda () (load-theme 'modus-vivendi t)) "dark") *my-themes*)
 (defun my/load-modus-vivendi-customized ()
   (load-theme 'modus-vivendi t)
   ;; (add-to-list 'org-emphasis-alist '("*" (bold :foreground "yellow")))
   (custom-set-faces '(org-level-1 ((t (:foreground "#da70d6" :weight bold))))))
 (push '("Modus Vivendi (customized)" #'my/load-modus-vivendi-customized "dark") *my-themes*)

 ;; === Moe theme

 (use-package moe-theme
   :commands (moe-light)
   :config (my-init--message-package-loaded "moe-theme"))
 (push '("Moe Light" #'moe-light "light") *my-themes*)

 ;; === Monokai theme

 (use-package monokai-theme
   :defer t
   :config (my-init--message-package-loaded "monokai-theme"))
 (push '("Monokai" (lambda () (load-theme 'monokai t)) "dark") *my-themes*)

 ;; === My dark theme

 (defun my/dark-theme ()
   "Set my dark theme."
   (interactive)
   (unless (null custom-enabled-themes)
     (my/disable-all-themes))
   (when (my-init--light-background-p)
     (invert-face 'default))
   ;; Note: Powershell colors are light gray 1 36 86 on dark blue background 238 237 240
   )
 (push '("_My dark" #'my/dark-theme "dark") *my-themes*)

 ;; === My light theme

 (defun my/light-theme ()
   "Set my light theme."
   (interactive)
   (unless (null custom-enabled-themes)
     (my/disable-all-themes))
   (when (my-init--dark-background-p)
     (invert-face 'default))
   (set-background-color "antique white") ; "honey dew"
   )
 (push '("_My light" #'my/light-theme "light") *my-themes*)

 ;; === Nimbus theme

 (use-package nimbus-theme
   :defer t
   :config (my-init--message-package-loaded "nimbus-theme"))
 (push '("Nimbus" (lambda () (load-theme 'nimbus t)) "dark") *my-themes*)
 
 ;; === Nord theme

 (use-package nord-theme
   :defer t
   :config
   (add-to-list 'custom-theme-load-path (expand-file-name "~/.emacs.d/themes/"))
   (my-init--message-package-loaded "nord-theme"))
 (push '("Nord" (lambda () (load-theme 'nord t)) "dark") *my-themes*)

 ;; === Poet theme

 (use-package poet-theme
   :defer t
   :config (my-init--message-package-loaded "poet-theme"))
 (push '("Poet" (lambda () (load-theme 'poet t)) "light") *my-themes*)

 ;; === Purple haze theme

 (use-package purple-haze-theme
   :defer t
   :config
   (my-init--message-package-loaded "purple-haze-theme"))
 (push '("Purple Haze" (lambda () (load-theme 'purple-haze t)) "dark") *my-themes*)

 ;; === Raw dark theme

 (defun my/raw-dark-theme ()
   "Set raw dark theme."
   (interactive)
   (unless (null custom-enabled-themes)
     (my/disable-all-themes))
   (when (my-init--light-background-p)
     (invert-face 'default))
   (when nil (set-frame-font "Courier New 10" nil t)))
 (push '("_Raw dark" #'my/raw-dark-theme "dark") *my-themes*)

 ;; === Raw light theme

 (defun my/raw-light-theme ()
   "Set raw light theme."
   (interactive)
   (unless (null custom-enabled-themes)
     (my/disable-all-themes))
   (when (my-init--dark-background-p)
     (invert-face 'default))
   (when nil (set-frame-font "Courier New 10" nil t)))
 (push '("_Raw light" #'my/raw-light-theme "light") *my-themes*)

 ;; === Shades of purple theme

 (use-package shades-of-purple-theme
   :defer t
   :config (my-init--message-package-loaded "shades-of-purple-theme"))
 (when nil
   (custom-theme-set-faces
    'shades-of-purple
    '(org-block ((t (:foreground "#B362FF"))))))
 ;; #494685 dark violet
 ;; #B362FF light violet
 (push '("Shades of purple" (lambda () (load-theme 'shades-of-purple t)) "dark") *my-themes*)
 (defun my/load-shade-of-purple-customized ()
   (load-theme 'shades-of-purple t)
   (add-hook 'org-mode-hook
             (lambda ()

               ;; (1) org-mode level 1 headers:
               (custom-set-faces
                '(org-level-1 ((t (:foreground "violet" :height 1.25 :weight bold)))))
               ;; possible alternative:
               (when nil
                 (set-face-attribute 'org-level-1 nil
                                     :foreground "violet"
                                     :height 1.25
                                     :weight 'bold))


               ;; (2) org-mode quote blocks
               (setq org-fontify-quote-and-verse-blocks t)
               (set-face-attribute 'org-quote nil
                                   :foreground "#FFFFFF" ; white
                                   :background "#3a3a3a")  ; light gray

               ;; (3) org-mode source blocks:
               (set-face-attribute 'org-block nil
                                   :foreground "#FFFFFF" ; white
                                   :background "#3a3a3a") ; light gray
               
               )))
 (push '("Shades of purple (customized)" #'my/load-shade-of-purple-customized "dark") *my-themes*)
 
 ;; === Solarized theme

 (use-package solarized-theme
   :defer t
   :config (my-init--message-package-loaded "solarized-theme"))
 (push '("Solarized light" (lambda () (load-theme 'solarized-light t)) "light") *my-themes*)
 (push '("Solarized dark" (lambda () (load-theme 'solarized-dark t)) "dark") *my-themes*)

 ;; === Soothe theme

 (use-package soothe-theme
   :defer t
   :config (my-init--message-package-loaded "soothe-theme"))
 (push '("Soothe" (lambda () (load-theme 'soothe t)) "dark") *my-themes*)

 ;; === Spacemacs theme

 (use-package spacemacs-theme
   :defer t
   :config (my-init--message-package-loaded "spacemacs-theme"))
 (push '("Spacemacs dark" (lambda () (load-theme 'spacemacs-dark t)) "dark") *my-themes*)
 (push '("Spacemacs light" (lambda () (load-theme 'spacemacs-light t)) "light") *my-themes*)

 ;; === Tron legacy theme

 (use-package tron-legacy-theme
   :defer t
   :config (my-init--message-package-loaded "tron-legacy-theme"))
 (push '("Tron Legacy" (lambda () (load-theme 'tron-legacy t)) "dark") *my-themes*)

 ;; === Vscode theme

 (use-package vscode-dark-plus-theme
   :defer t
   :config (my-init--message-package-loaded "vscode-dark-plus-theme"))
 (push '("VScode dark plus" (lambda () (load-theme 'vscode-dark-plus t)) "dark") *my-themes*)

 ;; === Zenburn theme

 (use-package zenburn-theme
   :defer t
   :config (my-init--message-package-loaded "zenburn-theme"))
 (push '("Zenburn" (lambda () (load-theme 'zenburn t)) "dark") *my-themes*)

 ;; ===

 (dolist (theme *my-themes*)
   (let ((light-or-dark (caddr theme)))
     (unless (or (string= "light" light-or-dark) (string= "dark" light-or-dark))
       (my-init--warning "Unrecognized light/dark parameter for theme %s: %s" (car theme) light-or-dark))))
 
 (defun my--load-theme-by-name (theme-name)
   "Load theme identified by THEME-NAME in *my-themes*"
   (let ((theme-fn (cadr (assoc theme-name *my-themes*))))
     (if (null theme-fn)
         (message "No theme associated with this name: %s" theme-name)
       (funcall (eval theme-fn)))))

 

 ;; and also:
 ;; - Dracula theme
 ;; - Tomorrow deep blue
 ;;     https://www.jamescherti.com/emacs-tomorrow-night-deepblue-theme-a-refreshing-color-scheme-with-a-deep-blue-background/
 ;; - standard-themes / standard-ligh-tinted
 ;; - green-is-the-new-black-theme

 ;; The theme which is chosen:
 ;; (my--load-theme-by-name "Moe Light")
 (my/load-shade-of-purple-customized)

 ;; I like also:
 (when nil

   ;; LIGHT:
   (my--load-theme-by-name "Leuven") ; perhaps to be repeated at the end of init file
                                        ; otherwise effects are missing: note titles, color or =xxx=, etc.
   ;; standard light tinted
   (my--load-theme-by-name "Moe Light")
   
   ;; DARK:
   (my--load-theme-by-name "Shades of purple")
   (my--load-theme-by-name "Shades of purple (customized)")
   (my--load-theme-by-name "Modus Vivendi")
   (my--load-theme-by-name "Modus Vivendi (customized)") ; <-- preferred dark
   ;; tomorrow deep blue
   ;; dracula
   (my--load-theme-by-name "Doom Challenger Deep")
   (my--load-theme-by-name "_My dark")
   ) ; end of when nil

 (defun my/generate-personal-theme-buffer () 
   "Create a buffer showing available themes and useful commands."
   (interactive)
   (let ((buf (get-buffer-create "*My Themes*"))
         (max-length-of-theme-name 0))

     (setq *my-themes*
           (sort (copy-sequence *my-themes*)
                 (lambda (a b)
                   (string< (car a) (car b)))))

     ;; Calculate maximum length of theme name
     (dolist (theme1 *my-themes*)
       (setq max-length-of-theme-name
             (max max-length-of-theme-name (length (car theme1)))))

     ;; (Create '*My Fonts*' buffer
     (with-current-buffer buf
       (when (eq buffer-read-only t)
         (read-only-mode -1))
       (erase-buffer)
       (insert "My themes:\n---------\n")
       (newline)
       (insert "Useful commands:\n")
       (insert "   current theme: (car custom-enabled-themes)\n")
       (insert "   my/disable-all-themes\n")
       (insert "   my/get-background\n")
       (insert "   my/get-transparency\n")
       (newline)
       (insert "Click on any button to change theme ;)\n")

       (insert "\n(1) Light themes:\n")
       
       (dolist (theme1 (seq-filter (lambda (item)
                                     (string= (nth 2 item) "light"))
                                   *my-themes*))
         (let* ((theme-name (car theme1))
                (theme-fn (cadr theme1))
                (string2 (format (format "%%-%ds" max-length-of-theme-name) theme-name)))
           (let ((start (point)))
             (insert (format "%s " string2))
             (make-text-button start (point)
                               'action (lambda (_button)
                                         (funcall (eval theme-fn))) 
                               'follow-link t
                               'face '(:box (:line-width 2 :color "gray50" :style released-button)
                                            :background "lightgray"
                                            :foreground "black"
                                            :weight bold)
                               'mouse-face '(:box (:line-width 2 :color "gray30" :style pressed-button)
                                                  :background "darkgray"
                                                  :foreground "black"
                                                  :weight bold)
                               'help-echo "Click this button"))
           (insert "\n")))

       (insert "\n(2) Dark themes:\n")
       
       (dolist (theme1 (seq-filter (lambda (item)
                                     (string= (nth 2 item) "dark"))
                                   *my-themes*))
         (let* ((theme-name (car theme1))
                (theme-fn (cadr theme1))
                (string2 (format (format "%%-%ds" max-length-of-theme-name) theme-name)))
           (let ((start (point)))
             (insert (format "%s " string2))
             (make-text-button start (point)
                               'action (lambda (_button)
                                         (funcall (eval theme-fn))) 
                               'follow-link t
                               'face '(:box (:line-width 2 :color "gray50" :style released-button)
                                            :background "lightgray"
                                            :foreground "black"
                                            :weight bold)
                               'mouse-face '(:box (:line-width 2 :color "gray30" :style pressed-button)
                                                  :background "darkgray"
                                                  :foreground "black"
                                                  :weight bold)
                               'help-echo "Click this button"))
           (insert "\n")))
       
       (goto-char (point-min))
       (read-only-mode 1))              ; end of with-current-buffer

     (switch-to-buffer buf)))); end of init section

;;; ===
;;; ============
;;; === TABS ===
;;; ============

(my-init--with-duration-measured-section
 t
 "Tabs"

 (setq tab-bar-close-button nil)
 (setq tab-bar-new-tab-choice "*scratch*")
 (setq tab-bar-tab-hints nil)
 (setq tab-bar-format '(tab-bar-format-tabs tab-bar-separator))
 (if (my-init--light-background-p)
     (progn
       (set-face-attribute 'tab-bar-tab nil :weight 'bold :foreground "blue" :background "light yellow")
       (set-face-attribute 'tab-bar-tab-inactive nil :weight 'normal :foreground "black" :background "grey"))
   (progn
     (set-face-attribute 'tab-bar-tab nil :weight 'bold :foreground "white" :background "dark violet")
     (set-face-attribute 'tab-bar-tab-inactive nil :weight 'normal :foreground "white" :background "violet")))

 (tab-bar-mode 1)

 ) ; end of init section


;;; end of init--appearance.el
