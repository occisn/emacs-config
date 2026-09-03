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
   (unless (derived-mode-p 'dired-mode)
     (error "This is not a dired buffer"))
   (let ((dir (expand-file-name default-directory)))
     (cond
      (*my-init--windows-p*
       (message "Opening this dired directory in Windows Explorer")
       (w32explore dir))
      (*my-init--wsl-p*
       (message "Opening this dired directory in Windows Explorer (WSL)")
       (call-process "explorer.exe" nil 0 nil
                     (string-trim (shell-command-to-string
                                   (format "wslpath -w %s" (shell-quote-argument dir))))))
      (t
       (message "Opening this dired directory in file manager")
       (call-process "xdg-open" nil 0 nil dir)))))

 (defalias 'my/open-current-dired-directory-in-windows-explorer
   #'my/open-current-dired-directory-in-file-manager)
 ;; available in dired hydra

 (when *my-init--wsl-p*
   (defun my/dired-wsl-open-file-externally ()
     "Open the file at point with its associated Windows application via explorer.exe."
     (interactive)
     (let* ((file (dired-get-file-for-visit))
            (win-path (string-trim (shell-command-to-string
                                    (format "wslpath -w %s" (shell-quote-argument file))))))
       (message "Opening %s with Windows application" (file-name-nondirectory file))
       (call-process "explorer.exe" nil 0 nil win-path)))

   (defun my/dired-wsl-open-in-explorer ()
     "Open the directory of file at point in Windows Explorer, selecting the file."
     (interactive)
     (let* ((file (dired-get-file-for-visit))
            (win-path (string-trim (shell-command-to-string
                                    (format "wslpath -w %s" (shell-quote-argument file))))))
       (message "Opening in Explorer: %s" win-path)
       (call-process "explorer.exe" nil 0 nil (concat "/select," win-path))))

   (with-eval-after-load 'dired
     (define-key dired-mode-map (kbd "<M-return>") #'my/dired-wsl-open-file-externally)
     (define-key dired-mode-map (kbd "<C-return>") #'my/dired-wsl-open-in-explorer)))

 ;; === (9) Copy file here

 (defun my/copy-file-here ()
   "Copy file as another file (adding ' (2)' at the end) in same dired folder.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (derived-mode-p 'dired-mode)
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

   (unless (derived-mode-p 'dired-mode)
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

   (unless (derived-mode-p 'dired-mode)
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

 ;; === (13.5) Prepend EXIF date taken to image filenames

 (defun my/dired-image-prepend-exif-date-taken ()
   "In Dired, prepend \"YYYY-MM-DD _\" to each marked image file, where the
date is the EXIF DateTimeOriginal (the moment the photo was taken) --
NOT the file modification date.

Works on the file at point if nothing is marked, or on all marked files
otherwise.  Skips (with a message) non-image files, files whose EXIF
has no DateTimeOriginal, and files already prefixed with YYYY-MM-DD _.
Requires ImageMagick `identify' (on Windows: via
`*imagemagick-identify-program*'; on Linux/WSL: via PATH)."
   (interactive)
   (unless (derived-mode-p 'dired-mode)
     (error "Not in dired-mode."))
   (if *my-init--windows-p*
       (unless (and (boundp '*imagemagick-identify-program*)
                    (my-init--file-exists-p *imagemagick-identify-program*))
         (error "*imagemagick-identify-program* is not a valid path: %s"
                (and (boundp '*imagemagick-identify-program*)
                     *imagemagick-identify-program*)))
     (unless (executable-find "identify")
       (error "ImageMagick `identify' not found on PATH.")))

   (cl-labels
       ((image-extension-p (ext)
          "Return non-nil if EXT (case-insensitive) is a recognized image extension."
          (and ext (member (downcase ext)
                           '("jpg" "jpeg" "heic" "heif" "png"
                             "tiff" "tif" "cr2" "nef" "arw" "dng"))))
        (already-prefixed-p (name)
          "Return non-nil if NAME already starts with YYYY-MM-DD _."
          (string-match-p "\\`[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} _" name))
        (exif-date-for (file)
          "Return \"YYYY-MM-DD\" for FILE's EXIF DateTimeOriginal, or nil.
Uses ImageMagick `identify'.  stderr is discarded so missing-EXIF
warnings do not pollute the buffer.  Success is detected by regex on
stdout: `identify' exits 0 even when the tag is absent."
          (let* ((program (if *my-init--windows-p*
                              *imagemagick-identify-program*
                            "identify"))
                 (args (list "-format" "%[EXIF:DateTimeOriginal]" file)))
            (with-temp-buffer
              (apply #'call-process program nil (list t nil) nil args)
              (let ((out (string-trim (buffer-string))))
                (when (string-match
                       "\\`\\([0-9]\\{4\\}\\):\\([0-9]\\{2\\}\\):\\([0-9]\\{2\\}\\) "
                       out)
                  (format "%s-%s-%s"
                          (match-string 1 out)
                          (match-string 2 out)
                          (match-string 3 out)))))))
        (process-one (full-path)
          "Rename FULL-PATH by prepending YYYY-MM-DD _, or skip with a message.
Return the new full path on success, nil on skip."
          (let* ((dir  (file-name-directory full-path))
                 (name (file-name-nondirectory full-path))
                 (ext  (file-name-extension full-path)))
            (cond
             ((not (image-extension-p ext))
              (message "Skipping (not an image): %s" name) nil)
             ((already-prefixed-p name)
              (message "Skipping (already date-prefixed): %s" name) nil)
             (t
              (let ((date (exif-date-for full-path)))
                (if (null date)
                    (progn
                      (message "Skipping (no EXIF DateTimeOriginal): %s" name)
                      nil)
                  (let ((new-full (concat dir date " _" name)))
                    (rename-file full-path new-full)
                    (message "Renamed: %s -> %s" name
                             (file-name-nondirectory new-full))
                    new-full))))))))

     (let* ((files (dired-get-marked-files))
            (last-new nil))
       (dolist (f files)
         (let ((res (process-one f)))
           (when (stringp res) (setq last-new res))))
       (revert-buffer)
       (when last-new (dired-goto-file last-new))
       (message "Done.  %d file(s) processed." (length files)))))

 ;; === (13.6) Show file head/tail (line count + first n + last n)

 (defun my/dired-show-file-head-tail (n)
   "In Dired, display in a buffer the total line count plus the first N
and last N lines of the file at point.

Designed for huge files: only a small chunk near each end is read to
extract the head/tail.  The line count reads the whole file but in
1 MiB chunks without loading it all into memory; when the `wc'
executable is on PATH it is used instead (much faster on multi-GB
files)."
   (interactive (list (read-number "Number of head/tail lines (n): " 10)))
   (unless (derived-mode-p 'dired-mode)
     (error "Not in dired-mode."))
   (when (< n 0)
     (error "n must be non-negative."))

   (cl-labels
       ((read-bytes (file beg end)
          "Return raw bytes [BEG, END) of FILE as a unibyte string."
          (with-temp-buffer
            (set-buffer-multibyte nil)
            (insert-file-contents-literally file nil beg end)
            (buffer-substring-no-properties (point-min) (point-max))))

        (drop-trailing-empty (lines)
          "Drop a trailing empty element in LINES (when text ended with \\n)."
          (if (and lines (string= "" (car (last lines))))
              (butlast lines)
            lines))

        (first-n-from-text (text k)
          (let ((lines (drop-trailing-empty (split-string text "\n" nil))))
            (mapconcat #'identity (seq-take lines k) "\n")))

        (last-n-from-text (text k chunk-starts-mid-file)
          ;; If we started reading mid-file, the first split element is a
          ;; partial line and must be discarded -- unless we have at most
          ;; k elements, in which case keeping it would still be wrong.
          (let* ((lines (drop-trailing-empty (split-string text "\n" nil)))
                 (lines (if chunk-starts-mid-file (cdr lines) lines))
                 (count (length lines))
                 (start (max 0 (- count k))))
            (mapconcat #'identity (nthcdr start lines) "\n")))

        (count-lines-via-wc (file)
          (when (executable-find "wc")
            (with-temp-buffer
              (let ((status (call-process "wc" file t nil "-l")))
                (when (and (eq status 0)
                           (progn (goto-char (point-min))
                                  (looking-at "[ \t]*\\([0-9]+\\)")))
                  (string-to-number (match-string 1)))))))

        (count-lines-elisp (file)
          (let ((size (file-attribute-size (file-attributes file)))
                (chunk-size (* 1024 1024))
                (count 0)
                (pos 0))
            (with-temp-buffer
              (set-buffer-multibyte nil)
              (while (< pos size)
                (let ((end (min size (+ pos chunk-size))))
                  (erase-buffer)
                  (insert-file-contents-literally file nil pos end)
                  (goto-char (point-min))
                  (while (search-forward "\n" nil t)
                    (setq count (1+ count)))
                  (setq pos end))))
            count))

        (count-lines-of (file)
          (or (count-lines-via-wc file) (count-lines-elisp file))))

     (let* ((file (dired-get-file-for-visit))
            (basename (file-name-nondirectory file)))
       (when (file-directory-p file)
         (error "%s is a directory" basename))
       (let* ((size (file-attribute-size (file-attributes file)))
              ;; ~4 KiB/line is generous; ensure at least 64 KiB; cap at file size.
              (chunk (min size (max 65536 (* (max n 1) 4096))))
              (head-text (read-bytes file 0 chunk))
              (tail-beg (max 0 (- size chunk)))
              (tail-text (read-bytes file tail-beg size))
              (head-block (first-n-from-text head-text n))
              (tail-block (last-n-from-text tail-text n (> tail-beg 0)))
              (_ (message "Counting lines in %s ..." basename))
              (total-lines (count-lines-of file))
              (buf-name (format "*head-tail: %s*" basename)))
         (with-current-buffer (get-buffer-create buf-name)
           (let ((inhibit-read-only t))
             (erase-buffer)
             (insert (format "File:        %s\n" file))
             (insert (format "Size:        %s bytes\n" size))
             (insert (format "Total lines: %d\n" total-lines))
             (insert (format "\n=== First %d line(s) ===\n" n))
             (insert head-block)
             (unless (or (string= "" head-block)
                         (string-suffix-p "\n" head-block))
               (insert "\n"))
             (insert (format "\n=== Last %d line(s) ===\n" n))
             (insert tail-block)
             (unless (or (string= "" tail-block)
                         (string-suffix-p "\n" tail-block))
               (insert "\n")))
           (goto-char (point-min))
           (special-mode))
         (pop-to-buffer buf-name)
         (message "Done. %d total line(s)." total-lines)))))

 ;; === (13.7) Count files in current directory and all its sub-directories

 (defun my/dired-count-files-recursively ()
   "In Dired, count files in the current directory and all its sub-directories.

Display in a separate buffer the recursive total (number of files,
number of sub-directories, cumulated size), plus a breakdown per
direct sub-directory sorted by decreasing number of files.

Hidden files are counted.  Symbolic links are counted as files and are
never followed, so the walk cannot loop.  Directories that cannot be
read are skipped and listed at the end of the buffer."
   (interactive)
   (unless (derived-mode-p 'dired-mode)
     (error "Not in dired-mode."))
   (let ((root (expand-file-name default-directory))
         (start-time (current-time))
         (unreadable nil))
     (cl-labels
         ((walk (dir)
            "Return (FILES SUBDIRS SIZE) found below DIR, recursively."
            (let ((files 0) (subdirs 0) (size 0))
              (condition-case nil
                  (dolist (entry (directory-files-and-attributes dir t nil t))
                    (let* ((name (car entry))
                           (attrs (cdr entry))
                           (type (file-attribute-type attrs)))
                      (cond
                       ((member (file-name-nondirectory name) '("." "..")))
                       ((eq type t)     ; real sub-directory
                        (let ((sub (walk name)))
                          (setq subdirs (+ subdirs 1 (nth 1 sub))
                                files (+ files (nth 0 sub))
                                size (+ size (nth 2 sub)))))
                       (t               ; file, or symlink (not followed)
                        (setq files (1+ files)
                              size (+ size (or (file-attribute-size attrs) 0)))))))
                (file-error (push dir unreadable)))
              (list files subdirs size))))

       (message "Counting files below %s ..." root)
       (let ((direct-files 0)
             (direct-size 0)
             (per-subdir nil))
         ;; Walk the root itself, keeping one entry per direct sub-directory.
         (condition-case nil
             (dolist (entry (directory-files-and-attributes root t nil t))
               (let* ((name (car entry))
                      (attrs (cdr entry))
                      (type (file-attribute-type attrs)))
                 (cond
                  ((member (file-name-nondirectory name) '("." "..")))
                  ((eq type t)
                   (push (cons name (walk name)) per-subdir))
                  (t
                   (setq direct-files (1+ direct-files)
                         direct-size (+ direct-size (or (file-attribute-size attrs) 0)))))))
           (file-error (push root unreadable)))

         (let* ((per-subdir (sort per-subdir
                                  (lambda (a b) (> (nth 1 a) (nth 1 b)))))
                (total-files (+ direct-files
                                (apply #'+ (mapcar (lambda (x) (nth 1 x)) per-subdir))))
                (total-dirs (+ (length per-subdir)
                               (apply #'+ (mapcar (lambda (x) (nth 2 x)) per-subdir))))
                (total-size (+ direct-size
                               (apply #'+ (mapcar (lambda (x) (nth 3 x)) per-subdir))))
                (results-buffer (generate-new-buffer
                                 (format "*File count: %s*"
                                         (directory-file-name root)))))
           (switch-to-buffer results-buffer)
           (newline)
           (insert (format "In %.3f seconds...\n" (float-time (time-since start-time))))
           (newline)
           (insert (format "Directory: %s\n\n" root))
           (insert (format "Total (recursive): %s file(s), %s sub-directory(ies), %s\n"
                           (my--add-number-grouping total-files)
                           (my--add-number-grouping total-dirs)
                           (file-size-human-readable total-size 'iec " ")))
           (insert (format "Directly in this directory: %s file(s), %s\n"
                           (my--add-number-grouping direct-files)
                           (file-size-human-readable direct-size 'iec " ")))
           (if (null per-subdir)
               (insert "\nNo sub-directory.\n")
             (insert "\nPer direct sub-directory (counted recursively):\n\n")
             (dolist (x per-subdir)
               (my--insert-dired-button (lambda (_button) (dired (car x))))
               (insert (format " %10s file(s) %10s  %s\n"
                               (my--add-number-grouping (nth 1 x))
                               (file-size-human-readable (nth 3 x) 'iec " ")
                               (file-name-nondirectory (directory-file-name (car x)))))))
           (when unreadable
             (insert (format "\n%s directory(ies) could not be read:\n\n"
                             (length unreadable)))
             (dolist (dir (nreverse unreadable))
               (insert (format "  %s\n" dir))))
           (goto-char (point-min))
           (special-mode)
           (message "Done.  %s file(s) in %s sub-directory(ies), %s."
                    (my--add-number-grouping total-files)
                    (my--add-number-grouping total-dirs)
                    (file-size-human-readable total-size 'iec " ")))))))

 ;; ===  (14) Mutiple deletions

 ;; hack to allow multiple deletions through D D D D X
 (unless (fboundp 'dired-pop-to-buffer)
   (defun dired-pop-to-buffer (buffer &optional noreselect)
     "Compatibility shim for missing dired-pop-to-buffer."
     (pop-to-buffer buffer nil noreselect)))

 ;; === (14.5) Project-specific keybindings in Dired
 ;;
 ;; C-c C-l / C-c C-m / C-c C-r / C-c C-t dispatch to the right
 ;; project command based on project type (C/Makefile or Common Lisp/.asd).

 (defun my-init--dired-project-type ()
   "Detect the project type from the current dired buffer.
Returns `c' for C/Makefile projects, `common-lisp' for ASDF/Common Lisp
projects, or nil if unrecognized.
Detection is based on the projectile project root."
   (let ((root (ignore-errors (projectile-project-root))))
     (cond
      ((null root) nil)
      ((file-exists-p (expand-file-name "Makefile" root)) 'c)
      ((directory-files root nil "\\.asd\\'" t) 'common-lisp)
      (t nil))))

 (defun my/dired-project-clean (&optional force)
   "Dispatch project clean/load command based on project type.
In C projects, run `make clean'.  In CL projects, load the ASDF system
\(with FORCE prefix, force reload)."
   (interactive "P")
   (let ((type (my-init--dired-project-type)))
     (cond
      ((eq type 'c) (require 'cc-mode) (my/c-projectile-make-clean))
      ((eq type 'common-lisp) (my/slime-load-or-force-reload-current-system force))
      (t (user-error "Trying to use C or Common Lisp keybinding in a project of unrecognized type")))))

 (defun my/dired-project-build (&optional _arg)
   "Dispatch project build/main command based on project type.
In C projects, run `make'.  In CL projects, call main."
   (interactive "P")
   (let ((type (my-init--dired-project-type)))
     (cond
      ((eq type 'c) (require 'cc-mode) (my/c-projectile-make))
      ((eq type 'common-lisp) (my/slime-call-main))
      (t (user-error "Trying to use C or Common Lisp keybinding in a project of unrecognized type")))))

 (defun my/dired-project-run ()
   "Dispatch project run command based on project type.
In C projects, run `make run'.  In CL projects, restart inferior lisp."
   (interactive)
   (let ((type (my-init--dired-project-type)))
     (cond
      ((eq type 'c) (require 'cc-mode) (my/c-projectile-make-run))
      ((eq type 'common-lisp)
       (slime-switch-to-output-buffer)
       (slime-restart-inferior-lisp))
      (t (user-error "Trying to use C or Common Lisp keybinding in a project of unrecognized type")))))

 (defun my/dired-project-test (&optional force)
   "Dispatch project test command based on project type.
In C projects, run `make test'.  In CL projects, test the ASDF system
\(with FORCE prefix, force test)."
   (interactive "P")
   (let ((type (my-init--dired-project-type)))
     (cond
      ((eq type 'c) (require 'cc-mode) (my/c-projectile-make-test))
      ((eq type 'common-lisp) (my/slime-test-or-force-test-current-system force))
      (t (user-error "Trying to use C or Common Lisp keybinding in a project of unrecognized type")))))

 (with-eval-after-load 'dired
   (define-key dired-mode-map (kbd "C-c C-l") #'my/dired-project-clean)
   (define-key dired-mode-map (kbd "C-c C-m") #'my/dired-project-build)
   (define-key dired-mode-map (kbd "C-c C-r") #'my/dired-project-run)
   (define-key dired-mode-map (kbd "C-c C-t") #'my/dired-project-test))

 ;; === (14.6) Project-specific dired hydras

 (defhydra hydra-dired-c (:exit t :hint nil)
   "
^Specific dired hydra (C project):
^---------------------------------

C-c C-l to clean (C-c p c c > make clean)
C-c C-m to make (C-c p c c > make clean)
C-c C-r to run (C-c p c c > make run) (or C-c p u ?)
C-c C-t to test (C-c p c c > make test)

[d]: normal dired hydra"
   ("d" #'hydra-dired/body))

 (defhydra hydra-dired-cl (:exit t :hint nil)
   "
^Specific dired hydra (Common Lisp project):
^-------------------------------------------

    C-c C-l  load
C-u C-c C-l  force load
    C-c C-t  test
C-u C-c C-t  force test
C-c C-r      restart inferior lisp
C-c C-m      execute main

[d]: normal dired hydra"
   ("d" #'hydra-dired/body))

 ;; === (15) Hydra

 (defhydra hydra-dired (:exit t :hint nil)
   "
^Dired hydra:
^------------
handy : ~ | C-s to search | Windows drives: C: then ^ | copy path to clipboard: M-< then w
C-x C-n to create file without ivy | C-x C-q and C-c C-c to edit dired buffer
M-w, C-w and C-y to copy/paste files (dired-ranger)
i to include content of subdirectory (C-u k to remove display) | o to open file or subdirectory in other window
[c]: copy file here (M-x my/copy-file-here)
[h]: paste image from clipboard to here (M-x my/paste-image-from-clipboard-to-here)
/ and g to narrow | P and q to peep-dired (M-x doc-view-dired-cache, M-x doc-view-clear-cache)

Open with:
   [w]: open this dired directory in file manager (M-x my/open-current-dired-directory-in-file-manager)
   [s]: open with PDF viewer
   [i]: open with image viewer
   M-RET to open file with external application | C-RET to open directory in file manager (similar to [w] above)

Find: my/find1 (native, buffer), my/[f]ind2 (projectile), my/find3 (projectile, buffer)
Grep:
   [x]ah / grep in current dired directory
   a[g] / grep in current dired directory (pb encoding)
   [p]t / grep in current dired directory
   see also project tools
Filetags --> see project hydra

Copy last modification date to clipboard: M-x my/copy-file-last-modification-date-to-clipboard
[a]: clean build artifacts
Zip: [u]nzip, [z]ip content of current directory;
     [l]ist zip content, my/zip-add-to-archive-present-in-same-directory
pdf: M-x my/pdf-burst, M-x my/pdf-extract, M-x my/pdf-join
Files: my/list-big-files-in-current-directory-and-subdirectories, my/list-directories-with-many-files-or-direct-subdirectories (# of files), my/list-directories-of-big-size, my/list-directories-containing-zip-files, my/find-files-with-same-size-in-same-subdirectory
[n]: show line count + first n / last n lines of file at point (default n=10)
[#]: count files here and in all sub-directories (M-x my/dired-count-files-recursively)
     (for a plain count of the current buffer only: t then * N)
Attach file to mail: C-c RET C-a (gnus-dired-attach)
Project: C-c C-l clean/load | C-c C-m make/main | C-c C-r run/restart | C-c C-t test (detects C vs CL)"
   ("#" #'my/dired-count-files-recursively)
   ("a" #'my/dired-clean-build-artifacts)
   ("c" #'my/copy-file-here)
   ("h" #'my/paste-image-from-clipboard-to-here)
   ("i" #'my/open-with-Irfan)
   ("f" #'my/find2)
   ("g" #'my/ag-grep-in-current-dired-directory)
   ("l" #'my/list-zip-content)
   ("n" #'my/dired-show-file-head-tail)
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

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (with-eval-after-load 'dired
    (load-file (concat dir "init--dired-colors.el"))))



;;; end of init--dired.el
