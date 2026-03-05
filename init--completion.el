;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ==============================
;;; ===== IVY SWIPER COUNSEL =====
;;; ==============================

(my-init--with-duration-measured-section 
 t
 "Ivy, swiper, counsel A (ivy)"
 
 ;; ivy, counsel, swiper ... who does what?
 ;; (1) ivy is a completion framework, like helm --> it completes based on a predefined list
 ;; (2) counsel uses ivy to select a file in a directory, choose an M-x command, ...
 ;; (3) swiper uses ivy to search within a text
 
 ;;; ivy: ~C-M-j~ to force

 (use-package ivy
   ;; requires emacs-24.1
   ;; ivy = a generic completion mechanism for Emacs
   :defer nil
   :bind (
          ;; ("C-s" . swiper) ; see below
          ("C-x b" . ivy-switch-buffer)
          ("C-x 4 b" . ivy-switch-buffer-other-window))
   ;; :commands (ivy-read)
   :config
   (define-key global-map (kbd "C-s")
               (lambda ()
                 (interactive)
                 (if (equal current-prefix-arg nil) ; no C-u
                     (swiper)
                   (isearch-forward))))
   (my-init--message-package-loaded "ivy")
   (ivy-mode 1)
   ;; (setq ivy-use-virtual-buffers t)
   (setq ivy-count-format "(%d/%d) "))) ; end of init section

(my-init--with-duration-measured-section
 t
 "Ivy, swiper, counsel B"

 (defun my-init--recent-directories ()
   "Open Dired in BUFFER, showing the recently used directories."
   (interactive)
   (let ((dirs  (delete-dups
                 (mapcar (lambda (f/d)
                           (if (file-directory-p f/d)
                               f/d
                             (file-name-directory f/d)))
                         recentf-list))))
     (ivy-read "Recentd: " dirs
               :action (lambda (f)
                         (with-ivy-window
                           (find-file f)))
               :require-match t
               :caller 'counsel-recentf)))
 ;; inspired by https://stackoverflow.com/questions/23328037/in-emacs-how-to-maintain-a-list-of-recent-directories
 ;; and the code for counsel-recentf

 (defun my-init--recent-files-or-directories ()
   "Open Dired in BUFFER, showing the recently used files, or directories if C-u prefix."
   (interactive)
   (if (equal current-prefix-arg nil) ; no C-u
       (counsel-recentf)
     (my-init--recent-directories)))) ; end of init section

(my-init--with-duration-measured-section
 t
 "Ivy, swiper, counsel C (counsel)"

 (use-package counsel
   ;; :requires ivy
   :defer nil                    ; otherwise C-x C-r = find-file-read-only
   :config (my-init--message-package-loaded "counsel")
   :bind (("M-x" . counsel-M-x) ; enriched by ivy-rich ; (global-set-key (kbd "M-x") 'counsel-M-x)
          ("C-x C-f" . counsel-find-file) ; (global-set-key (kbd "C-x C-f") 'counsel-find-file)
          ("C-x C-r" . my-init--recent-files-or-directories) ; files: counsel-recentf enriched by ivy-rich
          ("C-c b" . counsel-bookmark) ; enriched by ivy-rich ; file bookmark - see below
          ("C-:" . counsel-company)
          ("C-h v" . counsel-describe-variable) ; enriched by ivy-rich
          ))) ; end of init section

(my-init--with-duration-measured-section
 nil ; <----------------- not loaded
 "Ivy, swiper, counsel D (all-the-icons-ivy)"

 (use-package all-the-icons-ivy
   ;; :init (add-hook 'after-init-hook 'all-the-icons-ivy-setup)
   ;; :after (ivy)
   :config
   (all-the-icons-ivy-setup)
   (my-init--message-package-loaded "all-the-icons-ivy"))) ; end of init section

(my-init--with-duration-measured-section
 nil ; <-----------------  not loaded
 "Ivy, swiper, counsel E (ivy-rich)"

 (use-package ivy-rich
   ;; :after (ivy)
   ;; :defer nil
   ;; :after (counsel ivy)
   :config
   (my-init--message-package-loaded "ivy-rich")
   (setcdr (assq t ivy-format-functions-alist) #'ivy-format-function-line)
   (ivy-rich-mode 1))
 ;; to avoid error, use melpa and not melpa-stable
 ;; see https://github.com/Yevgnen/ivy-rich/issues/88
 ;; calls dired
 ) ; end of init section

(my-init--with-duration-measured-section
 nil ; <---------------- not loaded
 "Ivy, swiper, counsel F (all-the-icons-ivy-rich)"

 (use-package all-the-icons-ivy-rich
   ;; :after (ivy)
   :config
   (all-the-icons-ivy-rich-mode 1)
   (my-init--message-package-loaded "all-the-icons-ivy-rich"))

 ;; note: ivy-switch-buffer is modified by ivy-rich
 ) ; end of init section

(my-init--with-duration-measured-section
 t
 "Ivy, swiper, counsel G"

 ;; problem: when we want to create a file with C-x C-f:
 ;;   - ivy is enabled, which is not very useful
 ;;   - Shift-Space erase what we wrote

 (defun my/default-find-file ()
   "Original find-file function."
   (interactive)
   (let ((completing-read-function 'completing-read-default))
     (call-interactively 'find-file)))

 (global-set-key (kbd "C-x C-n") #'my/default-find-file)

 ;; problem: when we want to create a directory with +:
 ;;    - ivy is enabled, which is not very useful
 ;;    - Shift-Space erase what we wrote

 (defun my/default-create-directory ()
   "Original create directory function."
   (interactive)
   (let  ((completing-read-function 'completing-read-default))
     (call-interactively 'dired-create-directory)))

 (with-eval-after-load 'dired
   (define-key dired-mode-map (kbd "+") #'my/default-create-directory))

 ) ; end of init section



;;; end of init--completion.el
