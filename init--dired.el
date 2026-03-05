;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; =================
;;; ===== DIRED =====
;;; =================

(my-init--with-duration-measured-section
 t
 "Dired"

 ;; === Change permissions on Downloads

 ;; change permissions on Downloads to 777 so that C-x C-q do not trigger a "make editable?" question 
 (if (my-init--directory-exists-p *downloads-directory*)
     (unless (file-writable-p *downloads-directory*)
       (chmod *downloads-directory* #o777)
       (message "Changing permissions on Downloads directory (%s) so that C-x C-q do not trigger a 'make editable?' question ; now writable = %s" *downloads-directory* (file-writable-p *downloads-directory*)))
   (message "ERROR: *downloads-directory* is nil or does not exist: %s" *downloads-directory*))

 ;; === (1) Dired package

 (progn
   ;; instead of a hard delete, move a file to the trash:
   (setq delete-by-moving-to-trash t) 
   ;; (setq dired-recursive-deletes t)
   (setq dired-recursive-copies 'always)
   ;; directories at top:
   (setq ls-lisp-dirs-first t)
   ;; @ for symlinks:
   (setq dired-ls-F-marks-symlinks t)
   ;; other window as default target:
   (setq dired-dwim-target t)
   ;; hide details by default:
   (add-hook 'dired-mode-hook 'dired-hide-details-mode))

 ;; === (2) Dired+ (for color and reuse?) ; color --> see next file 25

 ;; In dired+ code, I have desactivated two hooks related to
 ;; colors, in order 'diredfl' to work (see below).
 ;; The two lines above are an old note. Still valid?
 
 (unless (my-init--directory-exists-p *dired+-directory*)
   (my-init--warning (format "!! directory is nil or does not exist: *dired+-directory* = %s" *dired+-directory*)))

 (add-to-list 'load-path *dired+-directory*)

 (defvar *my-init--dired+-not-loaded-yet* t)
 (add-hook
  'dired-mode-hook
  (lambda ()
    (when *my-init--dired+-not-loaded-yet*
      (require 'dired+)
      (my-init--message-package-loaded "dired+")
      (diredp-toggle-find-file-reuse-dir 1)
      (setq *my-init--dired+-not-loaded-yet* nil))))

 ;; === (3) Dired narrow

 (use-package dired-narrow
   :after (dired+)
   :config (my-init--message-package-loaded "dired-narrow")
   :bind (:map dired-mode-map ("/" . dired-narrow)))
 ;; "g" to revert back

 ;; === (4) Dired jump (incl. C-x C-j)

 ;; C-x C-j for dired-bind-jump

 ;; and:
 (defun my/kill-buffer-and-dired-jump ()
   "Closes buffer and dired-jump."
   (interactive)
   (let ((file-name buffer-file-name))
     (kill-buffer)
     (dired (file-name-directory file-name))))

 (global-set-key (kbd "C-x C-h") #'my/kill-buffer-and-dired-jump)

 ;; === (5) Dired ranger (for copy/paste ring)

 (use-package dired-ranger
   ;; :defer t
   :after (dired+)                      ; to overshadow direp+ 's C-w
   :config
   (my-init--message-package-loaded "dired-ranger")
   (setq dired-ranger-copy-ring-size 1)
   (define-key dired-mode-map (kbd "C-w")
               (lambda ()
                 (interactive)
                 (dired-ranger-copy nil) ; t adds item to dired-ranger-copy-ring
                 (define-key dired-mode-map (kbd "C-y") #'dired-ranger-move)))
   (define-key dired-mode-map (kbd "M-w")
               (lambda ()
                 (interactive)
                 (dired-ranger-copy nil)
                 (define-key dired-mode-map (kbd "C-y") #'dired-ranger-paste))))
 ;; see http://pragmaticemacs.com/emacs/copy-and-paste-files-with-dired-ranger/
 ;; see https://emacs.stackexchange.com/questions/39116/simple-ways-to-copy-paste-files-and-directories-between-dired-buffers?rq=1

 ;; === (6) Editable dired

 ;; Modify the code of wdired.el = comment (;) the line containing 'dired-filetype-setup' and compile again
 ;; Otherwise wdired will complain that 'dired-filetype-setup' function is not defined
 ;; The two lines above are an old note. Still valid?
 
 ;; === (7) Peep dired

 ;; void

 ;; === (8) Integration with Windows

 (when *my-init--windows-p*
   (use-package w32-browser
     ;; requires nothing
     :after (dired+)
     :config
     (my-init--message-package-loaded "w32-browser")))

 ;; Quote of documentaton:
 ;; (‘M-RET’) You can use Windows file associations to act on a file or folder. For example, if you have the application Adobe Acrobat associated with *.pdf files, then clicking ‘mouse-2’ on a *.pdf file in Dired will open the file in Adobe Acrobat.
 ;; (‘C-RET’) You can open Windows Explorer on a file or folder. If a file, its containing folder is opened and the file is selected (in Windows Explorer).
 ;; (`^’) When at the root of a Windows drive (e.g. `C:/’) and you use `^’ (‘dired-up-directory’), you get a list of drives to choose from. (This feature is based on the contribution at WThirtyTwoBrowseNetDrives.)

 ;; On my computer, 'M-RET' and 'C-RET' work.

 (defun my/dired-open-path-in-clipboard ()
   "Open dired with Windows path previously copied in clipboard"
   (interactive)
   (with-temp-buffer (yank))
   (let ((directory (car kill-ring)))
     (if (my-init--directory-exists-p directory)
         (progn
           (message "Opening dired with Windows path previously copied in clipboard: %s" directory)
           (dired (replace-regexp-in-string "\\\\" "/" directory)))
       (message "Trying to open invalid directory in dired:%s" directory))))
 ;; available in general hydra

 (defun my/open-current-dired-directory-in-file-manager ()
   "Open current dired directory in the system file manager."
   (interactive)
   (unless (equal major-mode 'dired-mode)
     (error "This is not a dired buffer"))
   (let ((dir (expand-file-name default-directory)))
     (if *my-init--windows-p*
         (progn
           (message "Opening this dired directory in Windows Explorer")
           (w32explore dir))
       (message "Opening this dired directory in file manager")
       (call-process "xdg-open" nil 0 nil dir))))

 (defalias 'my/open-current-dired-directory-in-windows-explorer
   #'my/open-current-dired-directory-in-file-manager)
 ;; available in dired hydra

 ;; === (9) Copy file here

 (defun my/copy-file-here ()
   "Copy file as another file (adding ' (2)' at the end) in same dired folder.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (string= major-mode "dired-mode")
     (error "Trying to copy file when not in dired-mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Trying to copy several files in same folder."))
   (let* ((current-path-and-name (car (dired-get-marked-files)))
          (current-path (file-name-directory current-path-and-name))
          (current-name (file-name-nondirectory current-path-and-name))
          (suggested-new-name (concat (file-name-sans-extension current-name) " (2)." (file-name-extension current-name)))
          (new-name (read-string "Copy into: " suggested-new-name))
          (new-path-and-name (concat current-path new-name)))
     (message "Copying %s into %s within %s." current-name new-name current-path) 
     (copy-file current-path-and-name new-path-and-name)
     (revert-buffer)                     ; to update dired
     (dired-goto-file new-path-and-name) ; cursor on new file
     ))

 ;; === (10) Paste image from clipboard to here

 (defun my/paste-image-from-clipboard-to-here ()
   "Paste image from clipboard to the current Dired buffer as png file.
Uses ImageMagick.
(v1, available in occisn/emacs-utils GitHub repository + adaptations)"
   (interactive)

   (unless (string= major-mode "dired-mode")
     (error "Trying to paste image from clipboard while not in dired-mode"))

   (cl-labels ((paste-image-from-clipboard-to-file-with-imagemagick (destination-file-with-path)
                 "Paste image from clipboard fo file DESTINATION-FILE-WITH-PATH with ImageMagick.
(v1, available in occisn/emacs-utils GitHub repository + adaptations)"
                 (if *my-init--windows-p*
                     (progn
                       (unless (my-init--file-exists-p *imagemagick-convert-program*)
                         (error "Unable to paste image from clipboard to file, since *imagemagick-convert-program* does not contain valid content: %s" *imagemagick-convert-program*))
                       (let ((cmd (concat "\"" *imagemagick-convert-program* "\" " "clipboard: " destination-file-with-path)))
                         (message "Pasting image from clipboard to %s with ImageMagick." destination-file-with-path)
                         (call-process-shell-command cmd)))
                   ;; Linux: use xclip to get image from clipboard
                   (let ((cmd (concat "xclip -selection clipboard -t image/png -o > " (shell-quote-argument destination-file-with-path))))
                     (message "Pasting image from clipboard to %s with xclip." destination-file-with-path)
                     (call-process-shell-command cmd))))) ; end of labels definition

     (let* ((file-short-name (read-string "File name without suffix: "))
            (suffix ".png")
            (destination-file-with-path1 (concat default-directory file-short-name suffix))
            (destination-file-with-path2 (concat "\"" destination-file-with-path1 "\"")))

       (paste-image-from-clipboard-to-file-with-imagemagick destination-file-with-path2)
       (revert-buffer)                               ; update dired
       (dired-goto-file destination-file-with-path1) ; cursor on created file
       (message "Image in clipboard pasted to %s" destination-file-with-path1))))

 ;; === (11) Recent files

 (recentf-mode 1)
 (setq recentf-max-menu-items 100)
 (setq recentf-max-saved-items 100)
 ;; (setq recentf-auto-cleanup 'never)

 ;; linked to 'counsel' below

 ;; C-c C-o to export list of recent files to a (non-dired) buffer
 ;; see https://emacs.stackexchange.com/questions/44589/how-show-recent-files

 ;; === (12) Dired icons

 (use-package all-the-icons-dired
   ;; :defer t
   ;; :after (dired)
   :hook (dired-mode . all-the-icons-dired-mode)
   :config
   (my-init--message-package-loaded "all-the-icons-dired")  
   ;; (add-hook 'dired-mode-hook 'all-the-icons-dired-mode)
   )

 ;; === (13) Copy file last modification date to clipboard

 (defun my/copy-file-last-modification-date-to-clipboard ()
   "In Dired, copy the date of last modification of file into clipboard under YYYY-MM-DD format."
   (interactive)

   (unless (string= major-mode "dired-mode")
     (error "Not in dired-mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Several files marked."))

   (cl-labels ((get-file-last-modification-date (file-full-name)
                 "Return the date of last modification (as Lisp timestamp) of FILE-FULL-NAME file.
(v1, available in occisn/elisp-utils GitHub repository)"
                 (nth 5 (file-attributes file-full-name)))
               (lisp-timestamp-to-YYYY-MM-DD (date1)
                 "Convert lisp timestamp DATE1 to YYYY-MM-DD format.
(v1, available in occisn/elisp-utils GitHub repository)"
                 (format-time-string "%Y-%m-%d" date1))
               (insert-string-in-clipboard (str)
                 "Insert STR (a string) in clipboard.
(v1, available in occisn/emacs-utils GitHub repository)"
                 (with-temp-buffer
                   (insert str)
                   (clipboard-kill-region (point-min) (point-max)))))
     
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (date1 (get-file-last-modification-date file-full-name)) ; as Lisp timestamp
            (date2 (lisp-timestamp-to-YYYY-MM-DD date1))) ; as YYYY-MM-DD
       
       (insert-string-in-clipboard date2))))

 ;; ===  (14) Mutiple deletions

 ;; hack to allow multiple deletions through D D D D X
 (unless (fboundp 'dired-pop-to-buffer)
   (defun dired-pop-to-buffer (buffer &optional noreselect)
     "Compatibility shim for missing dired-pop-to-buffer."
     (pop-to-buffer buffer nil noreselect)))

 ;; === (15) Hydra

 (defhydra hydra-dired (:exit t :hint nil)
   "
^Dired hydra:
^------------
handy : ~ | C-s to search | Windows drives: C: then ^ | copy path to clipboard: M-< then w
C-x C-n to create file without ivy | C-x C-q and C-c C-c to edit dired buffer
M-w, C-w and C-y to copy/paste files (dired-ranger)
i to include content of subdirectory (C-u k to remove display) | o to open file or subdirectory in other window
_c_: _c_opy file here (M-x my/copy-file-here)
_h_: paste image from clipboard to _h_ere (M-x my/paste-image-from-clipboard-to-here)
/ and g to narrow | P and q to peep-dired (M-x doc-view-dired-cache, M-x doc-view-clear-cache)

Open with:
   _w_: open this dired directory in file manager (M-x my/open-current-dired-directory-in-file-manager)
   _s_: open with PDF viewer
   _i_: open with image viewer
   M-RET to open file with external application | C-RET to open directory in file manager (similar to _w_ above)

Find: my/find1 (native, buffer), my/_f_ind2 (projectile), my/find3 (projectile, buffer)
Grep:
   _x_ah / grep in current dired directory
   a_g_ / grep in current dired directory (pb encoding)
   _p_t / grep in current dired directory
   see also project tools
Filetags --> see project hydra

Copy last modification date to clipboard: M-x my/copy-file-last-modification-date-to-clipboard
_a_: clean build artifacts
Zip: _u_nzip, _z_ip content of current directory;
     _l_ist zip content, my/zip-add-to-archive-present-in-same-directory
pdf: M-x my/pdf-burst, M-x my/pdf-extract, M-x my/pdf-join
Files: my/list-big-files-in-current-directory-and-subdirectories, my/list-directories-with-many-files-or-direct-subdirectories (# of files), my/list-directories-of-big-size, my/list-directories-containing-zip-files, my/find-files-with-same-size-in-same-subdirectory
Attach file to mail: C-c RET C-a (gnus-dired-attach) {end}"
   ("a" #'my/dired-clean-build-artifacts)
   ("c" #'my/copy-file-here)
   ("h" #'my/paste-image-from-clipboard-to-here)
   ("i" #'my/open-with-Irfan)
   ("f" #'my/find2)
   ("g" #'my/ag-grep-in-current-dired-directory)
   ("l" #'my/list-zip-content)
   ("p" #'my/pt-grep-in-current-dired-directory)
   ("s" #'my/open-with-Sumatra)
   ("u" #'my/unzip)
   ("w" #'my/open-current-dired-directory-in-file-manager)
   ("x" #'xah-grep-in-current-dired-directory)
   ("z" #'my/zip-content-of-current-directory)) ; end of hydra

 ) ; end of init section


;;; ===
;;; ============================================
;;; ===== DIRED COLORS VIA ADAPTED-DIREDFL =====
;;; ============================================

(my-init--with-duration-measured-section
 t
 "Dired colors"

 (my-init--load-additional-init-file "init--dired-colors.el")
 )



;;; end of init--dired.el
