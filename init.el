;;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-
;;;; the second parameter is to avoid 'Warning: docstring wider than 80 characters' when byte-compiling

(message "Entering init file...")


;;; ===
;;; ================
;;; === PREAMBLE ===
;;; ================

;;; ===
;;; === How to test

;;; Some below functions have tests associated with them.
;;; In order to test everything: M-x my/launch-tests
;;; See 'tests' below


;;; ===
;;; === Rules to be followed if modifications to this init.el

;;; - Do not use 'message' but use 'my-init--message2' which prints timestamp and respect '*my-init--startup-message-verbose*' flag
;;; - Do not use 'load-file' but use 'my-init--load-additional-init-file'
;;; - Warnings shall be launched with 'my-init--warning'
;;; - Everything shall be encapsulated into 'my-init--with-duration-measured-section'
;;; - Use 'use-package' to load package
;;;    and systematically add
;;;           :config (my-init--message-package-loaded "xxx")
;;; - Use 'my-init--path-to-directory-or-file-exists-p' to check if a path is non-null and is a valid file or directory
;;;       or 'my-init--directory-exists-p' or 'my-init--file-exists-p'
;;; - When using a program or directory:
;;;     (i) when loading this file: check it exists; otherwise, issue a warning with 'my-init--warning'
;;;     (ii) during execution of the actual function: check it exists; otherwise issue an error

;;; ===
;;; === Fonts and themes

;;; Font: see 'The font which is chosen' below
;;; Theme: see 'The theme which is chosen' below

;;; ===
;;; === How to spot mistakes?

;;; 'M-x byte-compile' allow identifying problems ;)

;;; ===
;;; === Byte compilation

;; To check that a function is byte-compiled:
;;    (symbol-function 'a-function)= --> (lambda ...) = interpreted
;;    (symbol-function 'a-function)= --> #[... = byte-compiled

;;; ===
;;; === Native compilation

;;; check if available: (native-comp-available-p)
;;     and (featurep 'comp)

;;; needs 'libccjit.dll' in PATH

;;; To disable native compilation if needed:
;;; (setq native-comp-deferred-compilation nil)
;;; (setq native-comp-enable-subr-trampolines nil)

;;; To check that a function is native-compiled:
;;;   (symbol-function 'a-function) --> #<subr... = native-compiled

;;; ===
;;; === Initialization flags

(defvar *my-init--load-sections-p* t
  "If nil, no 'my-init--with-duration-measured-section' section will be read in this file, which so becomes empty.")

(defvar *my-init--startup-message-verbose* t
  "If t, start-up information will be printed.")

;;; ===
;;; === Customized init messages

(defun my-init--message-with-timestamp (&rest args)
  "Equivalent of 'MESSAGE', with a timestamp at the beginning of the line, for instance [20:26:26]."
  (let* ((time (current-time))
         ;; (seconds (float-time time))
         (microseconds (nth 2 time))
         (milliseconds (/ microseconds 1000)))
    (apply #'message (cons (concat "[%s.%03d] " (car args))
                           (cons 
                            (format-time-string "%H:%M:%S" time)
                            (cons milliseconds
                                  (cdr args)))))))

(defun my-init--message2 (&rest rest)
  "Print message (with timestamp) only if *my-init--startup-message-verbose* flag is true."
  (when *my-init--startup-message-verbose*
    (apply #'my-init--message-with-timestamp rest)))

(defvar *my-init--warnings-list* nil
  "Warnings list (for final screen).")

(defun my-init--warning (&rest rest)
  ""
  (apply #'my-init--message2 rest)
  (push (apply #'format rest) *my-init--warnings-list*))

;;; ====
;;; === Some functions related fo files

(defun my-init--directory-exists-p (path)
  "Check if PATH is non-null and a valid directory."
  (and path (file-directory-p path)))

(defun my-init--file-exists-p (path)
  "Check if PATH is non-null and a valid file."
  (and path (file-exists-p path)))

(defun my-init--path-to-directory-or-file-exists-p (path)
  "Check if PATH is non-null and a valid file or directory."
  (and path
       (or (file-directory-p path)
           (file-exists-p path))))

;;; ===
;;; === Function to load additional init file

(defun my-init--load-additional-init-file (filename1)
  "Load additional init file, for instance 'init-abbrev', and throws a message (no error) if it does not exist."
  (let ((file-with-path (concat (file-name-directory (or load-file-name buffer-file-name)) filename1)))
    (if (my-init--file-exists-p file-with-path)
        (progn
          (my-init--message2 "Loading %s..." filename1)
          (load-file file-with-path))
      (progn
        (my-init--warning "Could not load '%s'" filename1)
        (message "Could not load '%s'" filename1)))))


;;; ===
;;; === "Warning: ‘let’ with empty body" attributable to paredit

;;; (September 2025)

;;; *Compile-Log* indicates: c:/Users/.../Dropbox/emacs-config/init.el: Warning: ‘let’ with empty body

;;; This is attributable to paredit.

;;; How has it been found?

;;; The initial warning in *Compile-Log* was:
;;;      Warning (bytecomp): ‘let’ with empty body

;;; To identify the file trigerring the warning, the following advice is implemented:
(defun dont-delay-compile-warnings (fun type &rest args)
  (if (eq type 'bytecomp)
      (let ((after-init-time t))
        (apply fun type args))
    (apply fun type args)))
(advice-add 'display-warning :around #'dont-delay-compile-warnings)

;;; We obtain
;;;      c:/Users/.../Dropbox/emacs-config/init.el: Warning: ‘let’ with empty body
;;; So the problem is arising from 'init.el'
;;;         ... or in a file loaded by 'init.el'?

;;; Let's try the following trick:
(when nil
  (defun log-to-compile-buffer (msg)
    (with-current-buffer (get-buffer-create "*Compile-Log*")
      (goto-char (point-max))
      (insert (format "%s\n" msg))))
  (advice-add 'load :before 
              (lambda (file &rest _) 
                (log-to-compile-buffer (format "Loading: %s" file))))
  (advice-add 'require :before 
              (lambda (feature &rest _) 
                (log-to-compile-buffer (format "Requiring: %s" feature)))))

;;; *Compile-Log* indicates:
;; Requiring: paredit
;; Requiring: bytecomp
;; c:/Users/.../Dropbox/emacs-config/init.el: Warning: ‘let’ with empty body
;; Requiring: package

;;; Conclusion: paredit is the culprit

;;; Confirmation: if we renounce to load it from 'init.el', the warning disappears.

;;; ===
;;; === Macro to measure duration of each section of init.el file

(defvar *my-init--section-durations* nil
  "List of below sections loaded and loading times.")

(defmacro my-init--with-duration-measured-section (to-be-loaded-p label &rest body)
  "If TO-BE-LOADED-P is 'nil', this macro replaces BODY with void code. Otherwise, this macro surrounds BODY with instrumentation for time measurement. After execution, the duration of the excution BODY, together with LABEL, will be added to *MY-INIT--SECTION-DURATIONS*."
  `(when (and ,*my-init--load-sections-p* ,to-be-loaded-p)
     (let ((beginning-time2 (float-time)))
       (my-init--message2 "=== Entering section '%s'." ,label)
       ,@body
       (let* ((end-time2 (float-time))
              (duration2 (* 1000 (float-time
                                  (time-subtract end-time2 beginning-time2)))))
         (push (cons ,label duration2) *my-init--section-durations*)
         (my-init--message2 "... Exiting section '%s', executed in %.0f ms." ,label duration2)
         ))))
;;; from Emacs 29.1, 'current-cpu-time' could alternatively be used.
;;; Possible tool for profiling: esup


;;; ===
;;; =========================================
;;; === Tricks to speed-up initialization ===
;;; =========================================

(my-init--with-duration-measured-section
 t
 "Initialization speed-up"

 (my-init--message2 "Garbage collector threshold is %s." gc-cons-threshold) ; 800 K
 (setq gc-cons-threshold (* 100 1000 1000))
 (setq gc-cons-threshold most-positive-fixnum)
 (my-init--message2 "Garbage collector threshold set at %s." gc-cons-threshold)
 
 ;; Trick to speed up start-up: file-name-handler-alist
 (defvar init--file-name-handler-alist-original file-name-handler-alist)
 (setq file-name-handler-alist nil)

 ;; avoid loading packages twice
 (setq package-enable-at-startup nil)

 ;; Avoid splash screen (C-h C-a to display splash screen later):
 (setq inhibit-startup-screen t)
 (setq inhibit-startup-message t)) ; end of my-init--with-duration-measured-section


;;; ===
;;; =====================================================
;;; === Some tools for this initialization monitoring ===
;;; =====================================================

(my-init--with-duration-measured-section
 t
 "Tools for initialization monitoring"

 ;; some hooks to detect some critical package loading:
 (with-eval-after-load 'dired
   (my-init--message2 "Packages: dired is loaded (info from with-eval-after-load)"))
 (with-eval-after-load 'dired+
   (my-init--message2 "Packages: dired+ is loaded (info from with-eval-after-load)"))
 (with-eval-after-load 'org
   (my-init--message2 "Packages: org is loaded (info from with-eval-after-load)"))
 (with-eval-after-load 'slime
   (my-init--message2 "Packages: slime is loaded (info from with-eval-after-load)"))
 (with-eval-after-load 'company
   (my-init--message2 "Packages: company is loaded (info from with-eval-after-load)"))) ; end of init section


;;; ===
;;; ==================================
;;; === Utilities for files system ===
;;; ==================================

(my-init--with-duration-measured-section 
 t
 "Utilities for files system (1)"

 (defun my-init--replace-linux-slash-with-two-windows-slashes (path)
   "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def"
   (replace-regexp-in-string  "/" "\\\\" path))

 (ert-deftest my-init--replace-linux-slash-with-two-windows-slashes ()
   :tags '(init)
   (should (string= "abc\\def" (my-init--replace-linux-slash-with-two-windows-slashes "abc/def"))))) ; end of init section

(my-init--with-duration-measured-section
 t
 "Utilities for files system (2)"

 (use-package f
   :commands (f-files f-directories)
   :config
   (my-init--message-package-loaded "f"))

 (defun my/list-big-files-in-current-directory-and-subdirectories ()
   "List big files in current dired directory and its sub-directories.
The list is printed on a separate buffer.
Requires 'f' package.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (string-equal major-mode "dired-mode")
     (error "Not in dired-mode."))
   (cl-labels ((file-size-Mo (filename)
                 "Return file size of FILENAME in Mo.
(v1, available in occisn/elisp-utils GitHub repository)"
                 (round
                  (/
                   (file-attribute-size
                    (file-attributes filename))
                   1000000)))
               (add-number-grouping (number &optional separator)
                 "Return a string corresponding to NUMBER, which each 3-digit group separated by SEPARATOR, by default a comma.
For instance: 123456 as a number--> 123,456 as a string
(v1, available in occisn/elisp-utils GitHub repository)"
                 (let ((num (number-to-string number))
                       (op (or separator ",")))
                   (while (string-match "\\(.*[0-9]\\)\\([0-9][0-9][0-9].*\\)" num)
                     (setq num (concat 
                                (match-string 1 num) op
                                (match-string 2 num))))
                   num))) ; end of function definitions within cl-labels
     (let ((root default-directory)
           (size0 (string-to-number (read-string "Minimal size in Mo (default = 50): " "" nil "50")))
           (results-buffer (generate-new-buffer "*Big files*"))
           (list1 nil)
           (list2 nil)
           (start-time (current-time)))
       (f-files root
                (lambda (file)
                  (when (> (file-size-Mo file) size0)
                    (push (cons file (file-size-Mo file)) list1))
                  nil)
                t)
       (setq list2 (sort list1 (lambda (a b) (> (cdr a) (cdr b)))))
       (switch-to-buffer results-buffer)
       (newline)
       (insert (format "In %.3f seconds...\n" (float-time (time-since start-time))))
       (newline)
       (cond ((> (length list2) 1)
              (insert (format "%s files found > %s Mo:\n\n" (length list2) size0)))
             ((= (length list2) 1)
              (insert (format "1 file found > %s Mo:\n\n" size0)))
             (t (insert (format "0 file found > %s Mo.\n" size0))))
       (dolist (x list2)
         (let ((start (point)))
           (insert "DIRED")
           (make-text-button start (point)
                             'action (lambda (_button)
                                       (dired (file-name-directory (car x)))
                                       (dired-goto-file (car x))) 
                             'follow-link t
                             'face '(:box (:line-width 2 :color "gray50" :style released-button)
                                          :background "lightgray"
                                          :foreground "black"
                                          :weight bold)
                             'mouse-face '(:box (:line-width 2 :color "gray30" :style pressed-button)
                                                :background "darkgray"
                                                :foreground "black"
                                                :weight bold)
                             'help-echo "Click this button")) ; end of let (button)
         (insert (format " %s Mo = %s\n" (add-number-grouping (cdr x)) (car x))))) ; end of insert
     (goto-char (point-min)))) ; end of defun

 (defun my/list-directories-with-many-files-or-direct-subdirectories ()
   "List directories with many files or direct sub-directories.
The list is printed on a separate buffer.
Requires 'f' package.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (string-equal major-mode "dired-mode")
     (error "Not in dired-mode."))
   (cl-labels ((nb-of-elements-in-directory (folder)
                 "Return number of elements in FOLDER, including sub-folders (no recursive investigation of subdirectories).
(v1, available in occisn/elisp-utils GitHub repository)"
                 (- (length (directory-files folder)) 2))
               (add-number-grouping (number &optional separator)
                 "Return a string corresponding to NUMBER, which each 3-digit group separated by SEPARATOR, by default a comma.
For instance: 123456 as a number--> 123,456 as a string
(v1, available in occisn/elisp-utils GitHub repository)"
                 (let ((num (number-to-string number))
                       (op (or separator ",")))
                   (while (string-match "\\(.*[0-9]\\)\\([0-9][0-9][0-9].*\\)" num)
                     (setq num (concat 
                                (match-string 1 num) op
                                (match-string 2 num))))
                   num))) ; end of functions definitions within cl-labels
     (let ((root default-directory)
           (nb0 (string-to-number (read-string "Minimal number (default = 100): " "" nil "100")))
           (results-buffer (generate-new-buffer "*Folders with many files or direct subdirectories*"))
           (list1 nil)
           (list2 nil)
           (start-time (current-time)))
       (f-directories root
                      (lambda (folder)
                        (when (> (nb-of-elements-in-directory folder) nb0)
                          (push (cons folder (nb-of-elements-in-directory folder)) list1))
                        nil)
                      t)
       (setq list2 (sort list1 (lambda (a b) (> (cdr a) (cdr b)))))
       (switch-to-buffer results-buffer)
       (newline)
       (insert (format "In %.3f seconds...\n" (float-time (time-since start-time))))
       (newline)
       (cond ((> (length list2) 1)
              (insert (format "%s directories found with more than %s files or direct subdirectories:\n\n" (length list2) nb0)))
             ((= (length list2) 1)
              (insert (format "1 directory found with more than %s files or direct subdirectories:\n\n" nb0)))
             (t (insert (format "0 directory found with more than %s files or direct subdirectories.\n" nb0))))
       (dolist (x list2)
         (let ((start (point)))
           (insert "DIRED")
           (make-text-button start (point)
                             'action (lambda (_button)
                                       (dired (car x))) 
                             'follow-link t
                             'face '(:box (:line-width 2 :color "gray50" :style released-button)
                                          :background "lightgray"
                                          :foreground "black"
                                          :weight bold)
                             'mouse-face '(:box (:line-width 2 :color "gray30" :style pressed-button)
                                                :background "darkgray"
                                                :foreground "black"
                                                :weight bold)
                             'help-echo "Click this button")) ; end of let (button)
         (insert (format " %s = %s" (add-number-grouping (cdr x)) (car x)))
         (newline))
       (goto-char (point-min)))))

 (defun my/list-directories-of-big-size ()
   "List directories of big size.
The list is printed on a separate buffer.
Requires 'f' package.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (when (not (string-equal major-mode "dired-mode"))
     (error "Not in dired-mode."))
   (let ((root default-directory)
         (minimal-size (string-to-number (read-string "Minimal size in Mo (default = 100): " "" nil "100")))
         (results-buffer (generate-new-buffer "*Folders with big size*"))
         (list1 nil)
         (list2 nil)
         (start-time (current-time)))
     (cl-labels ((file-size-o (filename)
                   "Return file size of FILENAME in o.
(derived from v1, available in occisn/elisp-utils GitHub repository)"
                   (file-attribute-size (file-attributes filename)))
                 (list-size-of-directory-and-subdirectories (current-root)
                   "Compute size of CURRENT-ROOT directory by adding size of its files and recursively examining size of subdirectories.
During this process, each time a directory size exceeds MINIMAL-SIZE (bound in englobing environment), add this directory to LIST1 (bound in englobing environment)."
                   (let ((size 0)
                         (files (f-files current-root))
                         (subdirectories (f-directories current-root)))
                     (dolist (file1 files)
                       (setq size (+ size (file-size-o file1))))
                     (dolist (subdir1 subdirectories)
                       (setq size (+ size (list-size-of-directory-and-subdirectories subdir1))))
                     (when (> size (* 1000000 minimal-size))
                       (push (cons current-root (round (/ size 1000000))) list1))
                     size))
                 (add-number-grouping (number &optional separator)
                   "Return a string corresponding to NUMBER, which each 3-digit group separated by SEPARATOR, by default a comma.
For instance: 123456 as a number--> 123,456 as a string
(v1, available in occisn/elisp-utils GitHub repository)"
                   (let ((num (number-to-string number))
                         (op (or separator ",")))
                     (while (string-match "\\(.*[0-9]\\)\\([0-9][0-9][0-9].*\\)" num)
                       (setq num (concat 
                                  (match-string 1 num) op
                                  (match-string 2 num))))
                     num))) ; end of functions definition within cl-labels
       (list-size-of-directory-and-subdirectories root)
       (setq list2 (sort list1 (lambda (a b) (> (cdr a) (cdr b)))))
       (switch-to-buffer results-buffer)
       (newline)
       (insert (format "In %.3f seconds...\n" (float-time (time-since start-time))))
       (newline)
       (cond ((> (length list2) 1)
              (insert (format "%s directories weighing more than %s Mo:\n\n" (length list2) minimal-size)))
             ((= (length list2) 1)
              (insert (format "1 directory weighing more than %s Mo:\n\n" minimal-size)))
             (t (insert (format "0 directory weighing more than %s Mo.\n" minimal-size))))
       (dolist (x list2)
         (let ((start (point)))
           (insert "DIRED")
           (make-text-button start (point)
                             'action (lambda (_button)
                                       (dired (car x))) 
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
         (insert (format " %s Mo = %s\n" (add-number-grouping (cdr x)) (car x))))
       (goto-char (point-min)))))

 (defun my/list-directories-containing-zip-files ()
   "List directories with ZIP files.
The list is printed on a separate buffer.
Directories listed in ALREADY-OK-FOLDERS list are not investigated.
Requires 'f' package.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to perform an my/list-directories-containing-zip-files when not in dired-mode."))
   (let ((already-OK-folders nil)
         (root default-directory)
         (results-buffer (generate-new-buffer "*Folders with ZIP files*"))
         (suspect-folders nil)
         (sorted-suspect-folders nil)
         (start-time (current-time)))
     (cl-labels ((string-suffix-p (suffix str &optional ignore-case)
                   "Return t if STR finished by SUFFIX.
Ignore case.
(v1, available in occisn/elisp-utils GitHub repository)
Source: https://stackoverflow.com/questions/22403751/check-if-a-string-ends-with-a-suffix-in-emacs-lisp" 
                   (let ((begin2 (- (length str) (length suffix)))
                         (end2 (length str)))
                     (when (< begin2 0) (setq begin2 0))
                     (eq t (compare-strings suffix nil nil
                                            str begin2 end2
                                            ignore-case))))
                 (file-size-Mo (filename)
                   "Return file size of FILENAME in Mo.
(v1, available in occisn/elisp-utils GitHub repository)"
                   (round
                    (/ (file-attribute-size
                        (file-attributes filename))
                       1000000)))) ; end of functions definition within cl-labels
       (f-directories root
                      (lambda (folder)
                        (let ((zip-files-and-sizes nil)
                              (sorted-zip-files-and-sizes nil)
                              (biggest-zip-file-and-size nil))
                          (f-files folder
                                   (lambda (file)
                                     (when (string-suffix-p ".zip" file)
                                       (push (cons file (file-size-Mo file)) zip-files-and-sizes))
                                     nil)
                                   nil ; not recursive
                                   ) 
                          (when (not (null zip-files-and-sizes))
                            (setq sorted-zip-files-and-sizes (sort zip-files-and-sizes (lambda (a b) (> (cdr a) (cdr b)))))
                            (setq biggest-zip-file-and-size (car sorted-zip-files-and-sizes))
                            (if (cl-loop for suffix in already-OK-folders
                                         always (not (string-suffix-p suffix folder)))
                                (push (list folder (cdr biggest-zip-file-and-size) (car biggest-zip-file-and-size)) suspect-folders)
                              (message "ZIP file in %s but skipped" folder)))) ; if
                        nil)
                      t)
       (setq sorted-suspect-folders (sort suspect-folders (lambda (a b) (> (cadr a) (cadr b)))))
       (switch-to-buffer results-buffer)
       (newline)
       (insert (format "In %.3f seconds...\n" (float-time (time-since start-time))))
       (newline)
       (cond ((> (length sorted-suspect-folders) 1)
              (insert (format "%s directories found with ZIP file(s):\n\n" (length sorted-suspect-folders))))
             ((= (length sorted-suspect-folders) 1)
              (insert (format "1 directory found with ZIP file(s):\n\n")))
             (t (insert (format "0 directory found with ZIP file(s).\n"))))
       
       (dolist (x sorted-suspect-folders)
         (insert (format "%s Mo zip in %s" (cadr x) (car x)))
         (newline)
         (insert "      ")
         (let ((start (point)))
           (insert "DIRED")
           (make-text-button start (point)
                             'action (lambda (_button)
                                       (dired (file-name-directory (caddr x)))
                                       (dired-goto-file (caddr x))) 
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
         (insert (format " %s\n" (file-name-nondirectory (caddr x)))))
       (goto-char (point-min)))))

 (cl-defun my/find-files-with-same-size-in-same-subdirectory (&optional (epsilon 0))
   "From current directory, and recursively, list files with same size in same subdirectory.
Presents the results as a dired buffer.
(v2, available in occisn/emacs-utils GitHub repository; v1 as of December 21th, 2021)"
   (interactive)
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to perform my/find-files-with-same-size-in-same-subdirectory when not in dired-mode."))
   (cl-labels ((insert-directories-in-file-list (files)
                 "Take a list of files, and return the same list with directories intertwined.
For instance :
d1/a.org d1/b.org d2/c.org d3/d.org
-->
d1/ d1/a.org d1/b.org d2/ d2/c.org d3/ d3/d.org
(v1, available in occisn/elisp-utils GitHub repository)"
                 (let ((current-dir "")
                       (files-intertwined-with-directories nil))
                   (cl-loop for filename in files
                            for dir1 = (file-name-directory filename)
                            do (progn
                                 (when (not (string= current-dir dir1))
                                   (push dir1 files-intertwined-with-directories)
                                   (setq current-dir dir1))
                                 (push filename files-intertwined-with-directories)))
                   (reverse files-intertwined-with-directories)))) ; end of functions definition within cl-labels
     (let ((start-time (current-time)))
       (aprogn
        ;; start with current dired directory:
        default-directory
        ;; obtain a list of all files and subdirectories, recursively:
        (directory-files-recursively it "" t)
        ;; only keep directories:
        (cl-remove-if-not #'file-directory-p it)
        ;; list all suspect files:
        (cl-loop for directory in it append
                 ;; for each directory...
                 (aprogn
                  ;; list of files and directories within subdirectory:
                  (directory-files directory t "^\\([^.]\\|\\.[^.]\\|\\.\\..\\)")
                  ;; remove directories:
                  (cl-remove-if-not #'file-regular-p it)
                  ;; sort by file size:
                  (cl-sort it '< :key #'(lambda (file) (file-attribute-size (file-attributes file))))
                  ;; list of suspects in current directory:
                  (cl-loop for (file1 file2) on it by #'cdr while file2
                           for size1 = (file-attribute-size (file-attributes file1))
                           for size2 = (file-attribute-size (file-attributes file2))
                           when (<= (abs (- size1 size2)) epsilon)
                           append (list file1 file2))))
        ;; intertwin directories within list of suspect files:
        (insert-directories-in-file-list it)
        ;; print nb of suspects and list under dired form:
        (progn
          (message "%s suspects found in %.3f seconds" (length it) (float-time (time-since start-time)))
          (dired (cons "Results (same size within same subdirectory):" it))))))) ; end of defun

 ) ; end of init section


;;; ===
;;; =========================================================
;;; === PATH TO DIRECTORIES AND FILES, AND SOME CONSTANTS ===
;;; =========================================================

(my-init--with-duration-measured-section 
 t
 "Paths to directories and files, and some constants"

 ;; the following 'nil' shall be replaced,
 ;; within 'personal--directories-and-files.el'
 ;; by the relevant paths.

 (setq *context* nil)                   ; 'perso, 'pro1 etc.

 (setq *dropbox-directory* "C:/Users/.../Dropbox/"
       *local-repos-directory* "C:/Users/.../local-repos"
       *emacs-config-directory* nil ; directory containing this init.el
       *this-init-file* "C:/.../init.el"
       *downloads-directory* "C:/.../Downloads/"
       *my-main-directory* "C:/.../MyFiles/"
       *ongoing-directory* "C:/.../WorkInProgress/"
       *temp-directory* "C:/Users/.../AppData/Local/Temp/"
       ;; note: it also exists built-in 'temporary-file-directory'
       *F12-temp-file* "C:/.../temp.org"
       
       ;; whatever the context (perso or pro), we define both F10 files
       ;; in order to be able to switch:
       *F10-file-perso* "C:/.../todo.org"
       *F10-file-pro1* "C:/.../todo.org"
       ;; initial F10 file:
       *F10-file* "C:/.../todo.org"
       
       *dired+-directory* "C:/.../dired+/"
       *xah-find-file* "C://xah-find-20210805.2124/xah-find.el"

       *imagemagick-convert-program* "c:/.../ImageMagick-7.0.11-4-portable-Q16-x64/convert.exe"

       *python-executable--in-libreoffice-for-unoconv* "c:/.../LibreOfficePortable/App/libreoffice/program/python.exe"
       *python-path-1--in-libreoffice-for-unoconv* "c:/.../LibreOfficePortable/App/libreoffice/program"
       *python-path-2--in-libreoffice-for-unoconv* "c:/.../LibreOfficePortable/App/libreoffice/program/python-core-3.7.7/bin"

       *gs-program* "c:/.../Ghostscript/bin/gswin64c.exe"
       *gs-bin-directory* "C:/.../Ghostscript/bin"
       *gs-lib-directory* "C:/.../Ghostscript/lib"

       *libreoffice-directory* "C:/.../LibreOfficePortable"

       *pt-directory* "c:/.../pt_windows_amd64/"
       *ag-directory* "c:/.../ag-2020-07-05_2.2.0-58-g5a1c8d8-x64/"

       *sbcl--inferior-lisp-program* "sbcl"
       *sbcl--common-lisp-directory* "C:/.../SBCL 2.4.10"
       *sbcl--common-lisp-program* "C:/.../SBCL 2.4.10/sbcl.exe"

       *clisp--inferior-lisp-program* "clisp"
       *clisp--common-lisp-directory* "C:/.../clisp-2.49"
       *clisp--common-lisp-program* "C:/.../clisp-2.49/clisp.exe"

       *ccl--inferior-lisp-program* "wx86cl64"
       *ccl--common-lisp-directory* "C:/.../ccl-1.13-windowsx86/ccl"
       *ccl--common-lisp-program* "C:/.../ccl-1.13-windowsx86/ccl/wx86cl64.exe"

       *abcl--inferior-lisp-program* "abcl"
       *abcl--common-lisp-directory* "C:/.../abcl-bin-1.7.1/abcl-bin-1.7.1"
       *abcl--common-lisp-program* "C:/.../abcl-bin-1.7.1/abcl-bin-1.7.1/abcl.bat"
       ;; this bat file contains: java -jar "C:\...\abcl-bin-1.7.1\abcl-bin-1.7.1\abcl.jar"

       *emacs-c-source* "c:/.../emacs-30.2-source/src/"

       *sumatra-program* "c:/.../SumatraPDF-3.1.2-64/SumatraPDF.exe"

       *miktex-directory* "c:/.../MiKTeX 21.8 portable/texmfs/install/miktex/bin/x64"
       *latex-preview-pics-directory* "C:/Users/.../AppData/Local/Temp/emacs-latex-preview-pics/"

       *gnuplot-directory* "c:/.../GnuPlot/gp527-win64-mingw/gnuplot/bin"
       *gnuplot-program* "c:/.../GnuPlot/gp527-win64-mingw/gnuplot/bin/gnuplot.exe"

       *unzip-program* "c:/.../7-ZipPortable/App/7-Zip64/7z.exe"

       *pdftk-program-name* "PDFtk Server"
       *pdftk-program* "c:/.../PDFTKBuilderPortable/App/pdftkbuilder/pdftk.exe"

       *irfanview-program* "c:/.../IrfanViewPortable/IrfanViewPortable.exe"

       *ditaa-jar* "c:/.../ditaa/ditaa0_9.jar"

       *R-executable* "c:/.../R-Portable/App/R-Portable/bin/x64/R.exe"
       *Rterm-executable* "c:/.../R-Portable/App/R-Portable/bin/x64/Rterm.exe"

       *msys2-bash-executable* "C:/.../msys2.exe"
       *msys2-shell-cmd* "C:/.../msys2_shell.cmd"
       
       *git-bash-executable* "C:/.../Git/bin/bash.exe"
       *git-executable-directory* "C:/.../Git/bin"
       *git-diff3-directory* "C:/.../Git/usr/bin"    

       *tesseract-tessdata-dir* "C:/.../Tesseract-OCR/tessdata"
       *tesseract-exe* "C:/.../Tesseract-OCR/tesseract.exe"

       *maxima-directory* "C:/.../maxima-5.47.0/bin"

       *pandoc-directory* "c:/.../pandoc-3.1.11.1"
       *pandoc-executable-name* "pandoc.exe"

       *my-signature* "(my signature for mail)"

       *my-commun-directory* "c:/.../"

       *word-path* "C:/.../WINWORD.EXE"
       *excel-path* "C:/.../EXCEL.EXE"
       *powerpoint-path* "C://.../POWERPNT.EXE"
       *teams-path* "C:/.../Teams.exe"
       *firefox-path* "C:/../firefox.exe"
       *thunderbird-executable* "C:/.../Thunderbird.exe"
       *chrome-executable "C:/.../chrome.exe"

       *gcc-path* "C:/.../bin"
       *gpp-path* "C:/.../bin"
       *gpp-exe* "C:/.../bin/g++.exe"
       *clangd-path* "c:/.../clangd_21.1.0/bin/"
       *c-tree-sitter-dll* "c:/.../.emacs.d/tree-sitter/libtree-sitter-c.dll"
       *cpp-tree-sitter-dll* "c:/.../.emacs.d/tree-sitter/libtree-sitter-cpp.dll"
       
       ) ; end of setq
 
 (my-init--load-additional-init-file "personal--directories-and-files-and-constants.el")

 ) ; end of init section


;;; ===
;;; =====================
;;; === BEGIN STARTUP ===
;;; =====================

(my-init--with-duration-measured-section 
 t
 "Begin startup and hook for end of startup"

 (defun my/number-to-string-with-comma-as-thousand-separator (num)
   "Return a string corresponding to number NUM formatted with thousand separators (commas).
For instance: 1234 --> '1,234'
v1 as of 2025-09-07; available in occisn/elisp-utils GitHub repository"
   (let ((str (number-to-string num)))
     (while (string-match "\\(.*[0-9]\\)\\([0-9]\\{3\\}\\)" str)
       (setq str (replace-match "\\1,\\2" nil nil str)))
     str))
 
 ;; prepare final display of start-up duration:
 (add-hook
  'emacs-startup-hook
  (lambda ()

    (message "%sEmacs %s.%s ready in %s with %d garbage collections (font: %s)."
             (if (> (length *my-init--warnings-list*) 0)
                 (if (> (length *my-init--warnings-list*) 1)
                     (format "/!\\ %d WARNINGS /!\\ -- " (length *my-init--warnings-list*))
                   "/!\\ 1 WARNING /!\\ -- ")
               "")
             emacs-major-version
             emacs-minor-version
             (format "%.2f seconds"
                     (float-time
                      (time-subtract after-init-time before-init-time)))
             gcs-done
             (my-init--default-font))

    (when *my-init--load-sections-p*
      (with-current-buffer (get-buffer-create "*init-stats*")
        (insert "Welcome back in Emacs, Nicolas! :)\n")

        (newline)
        (insert "INITIALIZATION STATISTICS\n")
        (insert "-------------------------\n")

        (newline)
        (insert (format "Emacs %s.%s ready in %s with %d garbage collections\n"
                        emacs-major-version
                        emacs-minor-version
                        (format "%.2f seconds"
                                (float-time
                                 (time-subtract after-init-time before-init-time)))
                        gcs-done))

        (newline)
        (insert (format "Computer: %s on %s, %s\n" (system-name) system-type system-configuration))

        (newline)
        (insert (format "Native compilation: %s, %s and %s\n" (featurep 'native-compile) (native-comp-available-p) (featurep 'comp)))

        (newline)
        (insert (format "Context: %s\n" *context*))

        (newline)
        (identify-available-and-unavailable-fonts-if-not-done-yet)
        (insert (format "Current font: %s (within %s mono available fonts)\n" (my-init--default-font) (length (delete-dups (mapcar #'car *my-mono-available-fonts*)))))
        
        (newline)
        (insert (format "Current theme: %s (within %s available themes); background is %s\n" (car custom-enabled-themes) (length *my-themes*) (frame-parameter nil 'background-mode)))

        (newline)
        (insert (format "Number of abbreviations: %d\n" (my/number-of-abbreviations)))

        (newline)
        (insert (format "Current garbage collector threshold: %s\n" (my/number-to-string-with-comma-as-thousand-separator gc-cons-threshold)))

        (newline)
        (insert "Warnings:\n")
        (if (null *my-init--warnings-list*)
            (insert "   (void)\n")
          (cl-loop for m in (reverse *my-init--warnings-list*)
                   do (insert (format "   - %s\n" m))))
        
        (newline)
        (insert "Duration of loading of packages:\n")
        (cl-loop for i from 0 to 7
                 for x in *packages-loading-durations*
                 do (insert (format "   loading of %s took %s ms\n" (car x) (cdr x))))

        (newline)
        (insert "Duration of configuring of packages:\n")
        (cl-loop for i from 0 to 7
                 for x in *packages-configuring-durations*
                 do (insert (format "   configuring of %s took %s ms\n" (car x) (cdr x))))

        (newline)
        (insert (format "%s packages loaded:\n" (length *my-init--packages-loaded*)))
        (cl-loop for x in (reverse *my-init--packages-loaded*)
                 do (insert (format "   %s\n" x)))

        (newline)
        (insert (format "Sections loading longest durations: (%s sections loaded in total)\n" (length *my-init--section-durations*)))
        (cl-loop with durations-alist = (sort *my-init--section-durations* (lambda (a b) (> (cdr a) (cdr b))))
                 for i from 0 to 10
                 for x in durations-alist
                 do (insert (format "    '%s' section took %d ms to load\n" (car x) (cdr x))))
        
        (newline)
        (insert "(end)")

        (goto-char (point-min)))        ; end of with-current-buffer

      (switch-to-buffer (get-buffer-create "*init-stats*"))) ; end of when

    (when (= 2 (count-windows))
      (read-string "Two windows detected. Press ENTER to focus on 'scratch' window: ")
      (delete-other-windows)))) ; end of add-hook
 ;; https://blog.d46.us/advanced-emacs-startup/

 ;; Inhibit the initial startup echo area message
 (setq inhibit-startup-echo-area-message t)

 ;; Avoid freezing at start-up:
 (setq w32-get-true-file-attributes nil)

 ;; Start with full screen:
 (add-to-list 'initial-frame-alist '(fullscreen . maximized))
 (add-to-list 'default-frame-alist '(fullscreen . maximized))) ; end of init section


;;; ===
;;; ================
;;; === PACKAGES ===
;;; ================

(my-init--with-duration-measured-section 
 t
 "Packages (use-package)"

 (setq package-archives
       '(("melpa" . "https://melpa.org/packages/") ; "http://melpa.milkbox.net/packages/"
         ("melpa-stable" . "https://stable.melpa.org/packages/")
         ("gnu" . "http://elpa.gnu.org/packages/")
         ;; ("marmalade" . "http://marmalade-repo.org/packages/")
         ))

 (when nil
   (package-initialize))

 (require 'use-package)

 (when nil
   (unless package-archive-contents
     (package-refresh-contents)))

 ;; Print messages on package loading:
 (setq use-package-verbose *my-init--startup-message-verbose*)
 (setq use-package-minimum-reported-time 0.0); report all loading times, no matter how fast

 ;; Install all packages if absent:
 (setq use-package-always-ensure t)

 (defvar *my-init--packages-loaded* '()
   "List of packages loaded.")

 (defun my-init--message-package-loaded (package-name)
   "If relevant flag is OK, print a message indicating that PACKAGE-NAME is loaded, and add PACKAGE-NAME to the list of packages loaded.
Shall be used in the 'config' section of each package."
   (push package-name *my-init--packages-loaded*)
   (my-init--message2 "Package %s loaded." package-name))
 ) ; end of init section


;;; ===
;;; ==================
;;; === LOAD HYDRA ===
;;; ==================

(my-init--with-duration-measured-section 
 t
 "Hydra package"
 
 (use-package hydra
   :ensure t
   :defer t
   :config
   (my-init--message-package-loaded "hydra")))


;;; ===
;;; ==================
;;; ===== MACROS =====
;;; ==================

(my-init--with-duration-measured-section 
 t
 "Macros"

 (defmacro aprogn (&rest body)
   "Anaphoric progn.
(v1, available in occisn/elisp-utils GitHub repository)"
   `(let*
        ,@(cl-loop for remaining-clauses on body
                   until (<= (length remaining-clauses) 1)
                   collect `(it ,(car remaining-clauses)) into bindings
                   finally (return (list bindings (car remaining-clauses))))))

 (defmacro amapcar (form list)
   "Anaphoric mapcar.
(v1, available in occisn/elisp-utils GitHub repository)"
   `(mapcar (lambda (it) ,form) ,list))

 (defmacro awhen (test &rest body)
   "Anaphoric when.
(v1, available in occisn/elisp-utils GitHub repository)"
   `(let ((it ,test))
      (when it ,@body)))

 (defmacro aif (test clause1 clause2)
   "Anaphoric if.
(v1, available in occisn/elisp-utils GitHub repository)"
   `(let ((it ,test))
      (if it ,clause1 ,clause2)))) ; end of init section


;;; ===
;;; ==================================================
;;; === UTILS: UTILITIES FOR ENVIRONMENT VARIABLES ===
;;; ==================================================

(my-init--with-duration-measured-section 
 t
 "Utilities for environment variables"

 ;; About PATH et exec-path:
 ;; https://emacs.stackexchange.com/questions/27326/gui-emacs-sets-the-exec-path-only-from-windows-environment-variable-but-not-from

 (defun my/add-to-environment-variable (envt-variable-name prog-name directory)
   "Add DIRECTORY corresponding to PROG-NAME to environment variable ENVT-VARIABLE-NAME. DIRECTORY may have a final slash.
(v1, available in occisn/emacs-utils GitHub repository) + messages"
   (let ((envt-variable-content (getenv envt-variable-name)))
     (if (cl-search directory envt-variable-content)
         (my-init--message2 "No need to add %s to Windows %s environment variable since already in: %s" prog-name envt-variable-name directory)
       (setenv envt-variable-name (concat directory ";" envt-variable-content))
       (my-init--message2 "%s is added to %s environment variable." prog-name envt-variable-name))))

 (defun my-init--add-to-path (prog-name directory)
   "Add DIRECTORY corresponding to PROG-NAME to Windows 'PATH' environment variable.
DIRECTORY may have a final slash"
   (my/add-to-environment-variable "PATH" prog-name directory))

 (defun my-init--add-to-exec-path (prog-name directory)
   "Add DIRECTORY corresponding to PROG-NAME to exec-path."
   (if (member directory exec-path)
       (my-init--message2 "No need to add %s to exec-path since already in: %s" prog-name directory)
     (add-to-list 'exec-path directory)
     (my-init--message2 "%s is added to exec-path." prog-name)))

 (defun my-init--add-to-path-and-exec-path (prog-name directory)
   "Add DIRECTORY corresponding to PROG-NAME to Windows 'PATH' and exec-path.
DIRECTORY may have a final slash"
   (my-init--add-to-path prog-name directory)
   (my-init--add-to-exec-path prog-name directory))) ; end of init section


;;; ===
;;; ====================================
;;; === UTILS: UTILITIES FOR WINDOWS ===
;;; ====================================

(my-init--with-duration-measured-section 
 t
 "Utilities for Windows"

 (defun my-init--open-windows-executable (exe-name exe-path)
   "Open Windows executable EXE-NAME located at EXE-PATH.
First check that the path is correct."
   (unless (my-init--file-exists-p exe-path)
     (error (concat "Impossible to open " exe-name " from Emacs, since no path is known")))
   (message (concat "Opening " exe-name " from Emacs"))
   (call-process-shell-command exe-path nil 0))

 (defun my-init--open-with-external-program (program-name build-cmd-fn)
   "Open the current file or dired marked files in external program named PROGRAM-NAME (this name is just used for messages).
BUILD-CMD-FN is a function which accepts a file name as argument, and returns the command to be executed.
Inspiration: http://ergoemacs.org/emacs/emacs_dired_open_file_in_ext_apps.html "
   (let* ((file-list
           (if (eq major-mode 'dired-mode)
               (dired-get-marked-files)
             (list (buffer-file-name))))
          (do-it-p (if (<= (length file-list) 5)
                       t
                     (y-or-n-p "Open more than 5 files? "))))
     (when do-it-p
       (if (= (length file-list) 1)
           (message "Open %S with %s" (file-name-nondirectory (car file-list)) program-name)
         (message "Open %S with %s" (mapcar #'file-name-nondirectory file-list) program-name))
       (mapc
        (lambda (fpath)
          (let* ((cmd (funcall build-cmd-fn fpath)))
            (call-process-shell-command cmd nil 0)))
        file-list))))) ; end of init section


;;; ===
;;; ==================================
;;; ===== UTILS: DATES AND TIMES =====
;;; ==================================

(my-init--with-duration-measured-section 
 t
 "Utilities for dates and times"
 
 (cl-defun my/today-in-French (&optional with-day-in-week-p)
   "Return '25 août 2023' or similar.
If WITH-DAY-IN-WEEK-P, return 'mardi 25 août 2023' or similar
(v2, available in occisn/elisp-utils GitHub repository)"
   (let* ((today-DD (format-time-string "%d"))   ; 01, 02
          (day-number-in-French
           (cond
            ((string= today-DD  "01") "1er")
            ((string= today-DD  "02") "2")
            ((string= today-DD  "03") "3")
            ((string= today-DD  "04") "4")
            ((string= today-DD  "05") "5")
            ((string= today-DD  "06") "6")
            ((string= today-DD  "07") "7")
            ((string= today-DD  "08") "8")
            ((string= today-DD  "09") "9")
            (t today-DD)))
          (today-MM (format-time-string "%m"))   ; 01, 02
          (month-in-French
           (cond
            ((string= today-MM  "01") "janvier")
            ((string= today-MM  "02") "février")
            ((string= today-MM  "03") "mars")
            ((string= today-MM  "04") "avril")
            ((string= today-MM  "05") "mai")
            ((string= today-MM  "06") "juin")
            ((string= today-MM  "07") "juillet")
            ((string= today-MM  "08") "août")
            ((string= today-MM  "09") "septembre")
            ((string= today-MM  "10") "octobre")
            ((string= today-MM  "11") "novembre")
            ((string= today-MM  "12") "décembre")
            (t (error "Month not recognized: %s" today-MM)))
           )
          (today-YYYY (format-time-string "%Y")) ; 2023
          (today-in-French
           (concat day-number-in-French
                   " "
                   month-in-French
                   " "
                   today-YYYY))) ; end of let*
     
     (if with-day-in-week-p
         (let* ((day-in-week (format-time-string "%u")) ; 1, 2... 7
                (day-in-week-in-French
                 (cond
                  ((string= day-in-week "1") "lundi")
                  ((string= day-in-week "2") "mardi")
                  ((string= day-in-week "3") "mercredi")
                  ((string= day-in-week "4") "jeudi")
                  ((string= day-in-week "5") "vendredi")
                  ((string= day-in-week "6") "samedi")
                  ((string= day-in-week "7") "dimanche")
                  (t (error "Day in week not recognized: %s" day-in-week)))))
           (concat day-in-week-in-French " " today-in-French))
       today-in-French))) ; end of defun

 ) ; end of init section


;;; ====
;;; =========================
;;; ===== FUNCTION KEYS =====
;;; =========================

(my-init--with-duration-measured-section 
 t
 "Function keys"

 ;; F1 = init.el
 
 (if (my-init--file-exists-p *this-init-file*)
     (global-set-key '[(f1)] (lambda () (interactive)
                               (find-file *this-init-file*)))
   (my-init--warning "Cannot assign f1 to *this-init-file* since its content is not valid: %s" *this-init-file*))
 
 ;; F2 = free

 ;; F3, F4 = Emacs macros

 ;; F5 = free

 ;; F6, F7 = calc (see below)

 (global-set-key '[(f6)] #'my/calc-read-macro)

 (global-set-key '[(f7)] #'my/calc-select-markdown-code-and-read-calc-macro)

 ;; F8

 (global-set-key '[(f8)] (lambda () (interactive)
                           (insert (format-time-string "%Y-%m-%d"))))
 ;; 2025-10-15 or similar
 ;; see 'my/today-YYYY-MM-DD' in occisn/elisp-utils GitHub repository
 
 (global-set-key '[(M-f8)] (lambda () (interactive)
                             (insert (my/today-in-French t)))) 
 
 (global-set-key '[(C-f8)] (lambda () (interactive)
                             (if (not (eq major-mode 'org-mode))
                                 (message "Cannot implement C-F8 since not in org-mode.")
                               (progn
                                 (insert "#+TITLE: ")
                                 (newline)
                                 (insert "#+DATE: ")
                                 (newline)
                                 (newline)
                                 (insert "Participants : ")
                                 (newline)
                                 (newline)
                                 (forward-line -6)
                                 (org-end-of-line)))))
 
 ;; F9

 (if (my-init--file-exists-p *my-main-directory*)
     (global-set-key '[(f9)] (lambda () (interactive)
                               ;; open dired at the root of main project
                               (require 'projectile)
                               (require 'counsel-projectile)
                               (let ((projectile-switch-project-action
                                      (lambda ()
                                        (projectile-dired))))
                                 (counsel-projectile-switch-project-by-name *my-main-directory*))) )
   (my-init--warning "Cannot assign f9 to *my-main-directory* since its content is not valid: %s" *my-main-directory*))
 
 

 ;; F10

 (if (my-init--file-exists-p *F10-file*)
     (global-set-key '[(f10)] (lambda () (interactive)
                                (find-file *F10-file*)))
   (my-init--warning "Cannot assign f10 to *F10-file* since its content is not valid: %s" *F10-file*))
 

 ;; F11 = full screen

 ;; F12

 (if (my-init--file-exists-p *F12-temp-file*)
     (global-set-key '[(f12)] (lambda () (interactive)
                                (find-file *F12-temp-file*)))
   (my-init--warning "Cannot assign f12 to *F12-temp-file* since its content is not valid: %s" *F12-temp-file*))) ; end of init section


;;; ====
;;; =====================
;;; ===== CLIPBOARD =====
;;; =====================


(my-init--with-duration-measured-section 
 t
 "Clipboard"

 (unless (my-init--file-exists-p *imagemagick-convert-program*)
   (my-init--warning "*imagemagick-convert-program* does not contain valid content: %s" *imagemagick-convert-program*))

 ) ; end of init section


;;; ===
;;; ==================================
;;; ===== HELP AND DOCUMENTATION =====
;;; ==================================

(my-init--with-duration-measured-section 
 t
 "Help and documentation"

 (use-package helpful
   :commands (helpful-callable helpful-variable helpful-command helpful-key)
   :custom
   (counsel-describe-function-function #'helpful-callable)
   (counsel-describe-variable-function #'helpful-variable)
   :config (my-init--message-package-loaded "helpful")
   :bind
   ([remap describe-function] . counsel-describe-function)
   ([remap describe-command] . helpful-command)
   ([remap describe-variable] . counsel-describe-variable)
   ([remap describe-key] . helpful-key))

 (defhydra hydra-help (:exit t :hint nil) ;  :columns 1)
   "
^Help and documentation:
^-----------------------

C-h v describe variable
C-h P describe package
C-h k describe key
C-h i info
C-h l previous keystrokes
C-h m describe major and minor modes
C-h f describe function
C-c C-h list of avaible commands, mode by mode
C-h C-a splash screen
C-h r Emacs manual
M-x emacs-index-search
C-u C-x = shows face under point, among other information

l to go back in Emacs documentation

M-x list-_c_olors-display

(end)
"
   ("c" #'list-colors-display))) ; end of init section

;;; ===
;;; ===================
;;; ===== GENERAL =====
;;; ===================

(my-init--with-duration-measured-section 
 t
 "General"

 ;; Disable autosave :
 (setq auto-save-default nil)

 ;; avoid custom:
 (setq custom-file (concat user-emacs-directory "/custom.el"))
 ;; "If you don't load the file with (load-file custom-file) somewhere in your init.el,
 ;; none of the settings defined via customize will be applied."

 ;; 'which key': Propose way to finish a command, for instance: "C-x..."
 (when nil
   (use-package which-key
     :ensure t
     :config
     (which-key-mode)
     (my-init--message-package-loaded "which-key")))
 ;; "which-key is a minor mode for Emacs that displays the key bindings following your currently entered incomplete command (a prefix) in a popup. For example, after enabling the minor mode if you enter C-x and wait for the default of 1 second the minibuffer will expand with all of the available key bindings that follow C-x (or as many as space allows given your settings)."
 ;; q to escape
 ;; may negatively interfere with ESUP
 
 ;; how unfinished commands in the echo area:
 (setq echo-keystrokes 0.1) ; or -1
 ;; documentation: M-x describe-variable (C-h v) echo-keystrokes
 ;;
 ;; " When you start typing a multi-key command (like C-x which begins many commands),
 ;; Emacs will show what you've typed so far in the echo area
 ;; The value determines the delay (in seconds) before showing these incomplete keystrokes"
 ;;
 ;; inspiration: https://www.emacswiki.org/emacs/EmacsNiftyTricks
 ;;
 ;; possible alernative: use-package command-log-mode
 ;;    then (command-log-mode)

 ;; Have a persistent scratch buffer:
 (when nil
   (use-package persistent-scratch
     :config
     (persistent-scratch-setup-default)
     (my-init--message-package-loaded "persistent-scratch")))

 ;; backup files:
 (setq backup-directory-alist `((".*" . ,temporary-file-directory)))
 (setq auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

 (use-package keycast
   :commands (keycast-mode)
   :config (my-init--message-package-loaded "keycast"))

 ;; to launch:
 ;;    (keycast-mode-line-mode 1)
 ;;    M-x keycast-mode

 ;; multiple cursor:

 (when nil
   (require 'multiple-cursors)
   (global-set-key (kbd "C->") 'mc/mark-next-like-this)
   (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
   (global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)
   (global-set-key (kbd "C-c m l") 'mc/edit-lines))
 
 ) ; end of init section


;;; ===
;;; ====================
;;; ===== ENCODING =====
;;; ====================

(my-init--with-duration-measured-section 
 t
 "Encoding"

 ;; You can force Emacs to read a file in a specific encoding with ‘C-x RET c C-x C-f’.
 
 ;; If you opened a file and EMACS determined the encoding incorrectly, you can use ‘M-x revert-buffer-with-coding-system’, to reload the file with a named encoding.
 
 ;; reference: https://www.masteringemacs.org/article/working-coding-systems-unicode-emacs

 ;; Notepad file shall be saved under UTF8 format in order to be properly read in Emacs

 ;; https://superuser.com/questions/549497/how-to-switch-back-text-encoding-to-utf-8-with-emacs
 ;; C-h C <ret> and you'll see a buffer explaining the characteristics of your buffer.
 ;; M-x revert-buffer-with-coding-system. One of latin-1 or utf-8 should work, depending on the file.
 ;; You can also mark the entire file with C-x h and then try M-x recode-region.
 ;; It will ask you for Text was really in and But was interpreted as.
 ;; For the first file in your question, it looks like it should be latin-1 and utf-8,
 ;; and for the second example it should probably be the other way around, utf-8 and latin-1.

 (prefer-coding-system 'utf-8)
 (my-init--message2 "Encoding: (prefer-coding-system 'utf-8)")
 ;; "Add CODING-SYSTEM at the front of the priority list for automatic detection.
 ;; This also sets the following coding systems:
 ;;   o coding system of a newly created buffer
 ;;   o default coding system for subprocess I/O
 ;; This also sets the following values:
 ;;   o default value used as ‘file-name-coding-system’ for converting file names
 ;;   o default value for the command ‘set-terminal-coding-system’
 ;; o default value for the command ‘set-keyboard-coding-system’"

 (set-default-coding-systems 'utf-8)
 (my-init--message2 "Encoding: (set-default-coding-systems 'utf-8)")
 ;; Set default value of various coding systems to CODING-SYSTEM.
 ;; This sets the following coding systems:
 ;;  o coding system of a newly created buffer
 ;;  o default coding system for subprocess I/O
 ;;This also sets the following values:
 ;;  o default value used as ‘file-name-coding-system’ for converting file names
 ;;      if CODING-SYSTEM is ASCII-compatible
 ;;  o default value for the command ‘set-terminal-coding-system’
 ;;  o default value for the command ‘set-keyboard-coding-system’
 ;;      if CODING-SYSTEM is ASCII-compatible

 ;; (set-selection-coding-system 'utf-8) 

 (set-terminal-coding-system 'utf-8)
 (my-init--message2 "Encoding: (set-terminal-coding-system 'utf-8)")
 
 ;; Set coding system of terminal output to CODING-SYSTEM.
 ;; All text output to TERMINAL will be encoded with the specified coding system.

 (let ((tmp (if (boundp 'keyboard-coding-system) keyboard-coding-system "UNBOUND")))
   (set-keyboard-coding-system 'utf-8)
   (my-init--message2 "Encoding: keyboard-coding-system was %s and is now %s" tmp keyboard-coding-system))
 ;; Set coding system for keyboard input

 ;; new 2019-12-27 :
 (set-language-environment 'utf-8)
 (my-init--message2 "Encoding: (set-language-environment 'utf-8)")
 ;; Set up multilingual environment

 (let ((tmp (if (boundp 'locale-coding-system) locale-coding-system "UNBOUND")))
   (setq locale-coding-system 'utf-8)
   (my-init--message2 "Encoding: locale-coding-system was %s and is now %s" tmp locale-coding-system))
 
 ;; Coding system to use with system messages.
 ;; Also used for decoding keyboard input on X Window system, and for encoding standard output and error streams.

 ;; backwards compatibility as default-buffer-file-coding-system is deprecated in 23.2.
 (let ((tmp (if (boundp 'buffer-file-coding-system) buffer-file-coding-system "UNBOUND")))
   (setq buffer-file-coding-system 'utf-8)
   (my-init--message2 "Encoding: buffer-file-coding-system was %s and is now %s" tmp buffer-file-coding-system))
 ;; buffer-file-coding-system = Coding system to be used for encoding the buffer contents on saving.

 ;; Treat clipboard input as UTF-8 string first; compound text next, etc.
 (let ((tmp (if (boundp 'x-select-request-type) x-select-request-type "UNBOUND")))
   (setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))
   (my-init--message2 "Encoding: x-select-request-type was %s and is now %s" tmp x-select-request-type))
 ;; Data type request for X selection.

 ;; redundant with above?
 (set-language-environment "UTF-8")
 (my-init--message2 "Encoding: (set-language-environment \"UTF-8\")")
 ;; Most recently used system locale for messages.

 (let ((tmp (if (boundp 'slime-net-coding-system) slime-net-coding-system "UNBOUND")))
   (setq slime-net-coding-system 'utf-8-unix)
   (my-init--message2 "Encoding: slime-net-coding-system was %s and is now %s" tmp slime-net-coding-system))
 ;; Coding system used for network connections.

 (let ((tmp (if (boundp 'coding-system-for-read) coding-system-for-read "UNBOUND")))
   (setq coding-system-for-read 'utf-8-dos)
   (my-init--message2 "Encoding: coding-system-for-read was %s and is now %s" tmp coding-system-for-read))
 ;; crucial for FIND et projectile
 ;; Specify the coding system for read operations.

 ;; to solve the problem encountered with doc-view related to accent in file name: 
 (let ((tmp (if (boundp 'default-process-coding-system) default-process-coding-system "UNBOUND")))
   (setq default-process-coding-system '(utf-8 . latin-1))
   (my-init--message2 "Encoding: default-process-coding-system was %s and is now %s" tmp default-process-coding-system))
 ;; (setq default-process-coding-system '(utf-8 . latin-1)) ; cp1252-dos cp850-dos
 ;; (setq file-name-coding-system 'latin-1)
 ;; (setq default-process-coding-system '(utf-8-dos . cp1251-dos))
 ;; (setq default-process-coding-system '(utf-8 . cp1251-dos))
 ;; the above allows 'my-init--open-with-external-program' (Sumatra, Irfan, ...), unzip, pdf to work properly
 ;;     without 'encode-filename-or-directory-for-cmd' just below

 (defun my-init--encode-filename-or-directory-for-cmd (file-name)
   "Return FILE-NAME (which can also be a directory or a path) in an encoding which allows injecting in cmd"
   (encode-coding-string file-name 'latin-1))

 (defun my-w32explore-fix-encoding (orig-fun &rest args)
   "Solve the issue with Ctrl-RET in dired, which was not able to open directory when accents in path.
This advice changes the encoding of the argument given to w32explore function in w32-browser.el, which calls shell-execute"
   (let* ((file-name (car args))
          (file-name-with-fixed-encoding (my-init--encode-filename-or-directory-for-cmd file-name)))
     (apply orig-fun file-name-with-fixed-encoding (cdr args))))
 (advice-add 'w32explore :around #'my-w32explore-fix-encoding)

 ;; PREVIOUS VERSION:
 ;; ... which was triggering:
 ;;      Warning: ‘defadvice’ is an obsolete macro (as of 30.1); use ‘advice-add’ or ‘define-advice’
 ;;  (defadvice w32explore (before w32explore-fix-encoding (arg))
 ;;    "Solve the issue with Ctrl-RET in dired, which was not enable to open directory when accents in path.
 ;; This advice changes the encoding of the argument given to w32explore function in w32-browser.el, which calls shell-execute"
 ;;    (let* ((file-name (ad-get-arg 0))
 ;;       (file-name-with-fixed-encoding (my-init--encode-filename-or-directory-for-cmd file-name)))
 ;;      (ad-set-arg 0 file-name-with-fixed-encoding)))
 ;;  (ad-activate 'w32explore)
 ) ; end of init section


;;; ===
;;; ========================================
;;; ==== UNICODE AND FRENCH CHARACTERS =====
;;; ========================================

;;; αβγδεζηθικλμνξοπρστυφχψω
;;; ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ

;;; Unicode : http://xahlee.info/comp/unicode_index.html

(my-init--with-duration-measured-section 
 t
 "Unicode and French characters"

 ;; Keybinding for french capital letters with accent or similar:

 (global-set-key (kbd "C-é") (lambda () (interactive) (insert "É")))
 (global-set-key (kbd "C-è") (lambda () (interactive) (insert "È")))
 (global-set-key (kbd "C-à") (lambda () (interactive) (insert "À")))
 (global-set-key (kbd "C-ç") (lambda () (interactive) (insert "Ç")))
 (global-set-key (kbd "C-ù") (lambda () (interactive) (insert "œ")))

 ;; C-x = --> it displays information about the character currently under the cursor.

 ;; To search and insert Unicode : C-x 8 RET or M-x counsel-unicode-char

 ;; http://ergoemacs.org/emacs/emacs_n_unicode.html
 ;; https://stackoverflow.com/questions/2030810/accented-characters-on-emacs
 ) ; end of init section


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
 (my-init--set-font-if-exists "DM Mono" 9)
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
 (pixel-scroll-precision-mode 1)

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
   (when (not (null custom-enabled-themes))
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
   (when (not (null custom-enabled-themes))
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
   (when (not (null custom-enabled-themes))
     (my/disable-all-themes))
   (when (my-init--light-background-p)
     (invert-face 'default))
   (when nil (set-frame-font "Courier New 10" nil t)))
 (push '("_Raw dark" #'my/raw-dark-theme "dark") *my-themes*)

 ;; === Raw light theme

 (defun my/raw-light-theme ()
   "Set raw light theme."
   (interactive)
   (when (not (null custom-enabled-themes))
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
 (my--load-theme-by-name "Moe Light")
 ;;(my/load-shade-of-purple-customized)

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

;;; ===
;;; =============================
;;; ===== OTHER EMACS TOOLS =====
;;; =============================

(my-init--with-duration-measured-section 
 t
 "Other Emacs tools"

 ;; Calculator
 
 ;; Battery
 ;;    M-x battery

 ;; Calendar
 ;;    M-x calendar
 ;;    then PAGE-UP et PAGE-DOWN to navigate

 ;; Colors
 ;;   M-x list-colors-display

 ;; M-x memory-report

 ;; Key frequency

 ) ; end of init section


;;; ===
;;; =======================
;;; ===== USER MACROS =====
;;; =======================

(my-init--with-duration-measured-section 
 t
 "User macros"

 (defun my/repeat-macro-until-error ()
   "Repeat previously stored macro until error"
   (interactive)
   (kmacro-end-and-call-macro 0))

 )


;;; ===
;;; ================
;;; ===== TEXT =====
;;; ================

(my-init--with-duration-measured-section 
 t
 "Text"

 ;; indentation by space and not by tabs:
 (setq-default indent-tabs-mode nil)
 ;; see https://github.com/bbatsov/emacs-lisp-style-guide
 
 ;; (setq-default tab-width 4)           ; 4 spaces per tab
 ;; (setq require-final-newline t)       ; Files end with newline
 
 ;; Enable useful disabled commands:
 (put 'narrow-to-region 'disabled nil)
 (put 'upcase-region 'disabled nil)
 (put 'downcase-region 'disabled nil)

 ;; Visual line mode
 (global-visual-line-mode 1)
 ;; "Visual Line mode provides support for editing by visual lines.
 ;; It turns on word-wrapping in the current buffer, and rebinds C-a, C-e, and C-k
 ;; to commands that operate by visual lines instead of logical lines.
 ;; This is a more reliable replacement for longlines-mode."

 ;; Indent when new line
 (define-key global-map (kbd "RET") 'newline-and-indent)

 ;; Ace-jump
 ;; Byte-compilation warning: Package cl is deprecated
 (use-package ace-jump-mode
   :init
   (setq byte-compile-warnings '(not cl-functions obsolete))
   :config (my-init--message-package-loaded "ace-jump-mode")
   :bind ("C-c C-SPC" . ace-jump-mode)) 

 ;; alternative = avy
 (when nil
   (use-package avy
     :config
     (progn
       (global-set-key (kbd "C-c C-SPC") #'avy-goto-word-1)
       (global-set-key (kbd "C-c C-SPC") #'avy-goto-char-timer)
       (my-init--message-package-loaded "avy")))) ; end of when nil

 ;; C-w kills only if region selected
 (defun my-init--kill-only-if-region-selected (_arg)
   "C-w kills region only if region is selected"
   (interactive "*p")
   (if (and transient-mark-mode mark-active)
       (kill-region (region-beginning) (region-end))
     (message "Attempting to kill (C-w) whereas no region was selected. No action done.")))
 (global-set-key (kbd "C-w") #'my-init--kill-only-if-region-selected)
 ;; inspiration: https://andreyorst.gitlab.io/posts/2020-04-29-text-editors/

 
 ;; C-c ; adds ';' comment at the beginning of line
 (when nil
   (defun my/add-comment-symbol-at-beginning-of-line (nb)
     "Add ';' character NB times (default: once)  at the beginning of the line."
     (interactive "p")
     (save-excursion
       (beginning-of-line)
       (dotimes (i (if (null nb) 1 nb))
         (insert ";"))
       (insert " ")))
   (global-set-key (kbd "C-c ;") #'my/add-comment-symbol-at-beginning-of-line)) ; end of when nil

 (defun xah-show-kill-ring ()
   "Insert all `kill-ring' content in a new buffer named *copy history*.
URL `http://ergoemacs.org/emacs/emacs_show_kill_ring.html'
Version 2019-12-02"
   (interactive)
   (let ((buf (generate-new-buffer "*copy history*")))
     (progn
       (switch-to-buffer buf)
       (funcall 'fundamental-mode)
       (dolist (x kill-ring )
         (insert x "\n\nhh=============================================================================\n\n"))
       (goto-char (point-min)))))) ; end of init section


;;; ===
;;; ====================
;;; ===== ORG-MODE =====
;;; ====================

(my-init--with-duration-measured-section
 t
 "org-mode A"

 ;; to unindent :
 ;; unfold then deselect all
 ;; then C-x C-i LEFT LEFT LEFT LEFT...
 ;; see https://stackoverflow.com/questions/22388868/how-can-i-indent-a-paragraph-of-plain-text-in-emacs-org-mode

 (setq org-startup-indented nil)


 (setq org-modules nil) ; Stop Org from loading any default extra modules
 ;; 44% of the org-mode start-up time was spent on org-load-modules-maybe
 ;; org-modules was containig (ol-doi ol-w3m ol-bbdb ol-bibtex ol-docview ol-gnus ol-info ol-irc ol-mhe ol-rmail ol-eww)

 
 ) ; end of init section


(my-init--with-duration-measured-section 
 t
 "org-mode B (require org)"
 
 ;; (require 'org)

 ) ; end of init section


(my-init--with-duration-measured-section 
 t 
 "org-mode C1"
 
 ;; Highlight bold, etc:
 (defvar org-emphasis-alist) ; to avoid compilation warning
 (with-eval-after-load 'org
   (if (my-init--dark-background-p)
       (add-to-list 'org-emphasis-alist '("*" (bold :foreground "yellow")))
     (add-to-list 'org-emphasis-alist '("*" (bold :foreground "blue"))))
   ;; ref: https://github.com/syl20bnr/spacemacs/blob/develop/doc/FAQ.org#why-do-some-of-my-org-related-settings-cause-problems
   )
 
 (when nil
   (with-eval-after-load 'org
     (setq org-emphasis-alist
           '(("*" (bold :foreground "Orange" ))
             ("/" italic)
             ("_" underline)
             ("=" (:background "maroon" :foreground "white"))
             ("~" (:background "deep sky blue" :foreground "MidnightBlue"))
             ("+" (:strike-through t))))))
 ;; source : https://emacs.stackexchange.com/questions/44081/how-to-tweak-org-emphasis-alist-to-put-e-g-neon-yellow-over-bold-or-italic

 ;; hide bold and italics marks in org-mode:
 (when nil
   (setq org-hide-emphasis-markers t))
 ;; source:  https://howardism.org/Technical/Emacs/orgmode-wordprocessor.html

 ;; do not deleted invisible text:
 (setq-default org-catch-invisible-edits 'smart) 

 ;; disable C-TAB in org-mode so that this key binding could be used
 ;; to change tab
 (with-eval-after-load 'org
   (define-key org-mode-map [(control tab)] nil)
   ;; https://stackoverflow.com/questions/4333467/override-ctrl-tab-in-emacs-org-mode
   )
 
 (declare-function org-occur "org")
 ;; the above to avoid:
 ;;  the function ‘org-occur’ might not be defined at runtime.
 (defun my/org-occur-and-hide-content ()
   "Interactively call `org-occur' and hide body lines after."
   (interactive)
   (call-interactively #'org-occur)
   (outline-hide-body))
 ;; source: https://emacs.stackexchange.com/questions/53208/show-headings-only-in-sparse-tree

 (when nil
   (require 'centered-cursor-mode) ; à transformer en use-package / commands
   (centered-cursor-mode)
   ;; https://davidbosman.fr/tux/post/emacs-typewriter-mode/
   )) ; end of init section

(my-init--with-duration-measured-section 
 t 
 "org-mode C2 (embedded images)"

 ;; C-c C-x C-v to make images appear

 ;; images:
 (setq org-startup-with-inline-images nil)

 (declare-function org-insert-link "org")
 (with-eval-after-load 'org
   (defun my/paste-image-from-clipboard-as-link ()
     "Paste image from clipboard to the current org-mode buffer as link. The image itself is pasted into the directory of the org file."
     (interactive)
     (unless (string-equal major-mode "org-mode")
       (error "Trying to paste image from clipboard while not in org-mode"))
     (cl-labels ((string-remove-surrounding-quotes (s)
                   "Remove quotes at the beginning and at the end of a string.
(v1, available in occisn/elisp-utils GitHub repository)"
                   (aprogn
                    s
                    (string-remove-prefix "\"" it)
                    (string-remove-suffix "\"" it)))
                 (paste-image-from-clipboard-to-file-with-imagemagick (destination-file-with-path)
                   "Paste image from clipboard fo file DESTINATION-FILE-WITH-PATH with ImageMagick.
(v1, available in occisn/emacs-utils GitHub repository + adaptations)"
                   (unless (my-init--file-exists-p *imagemagick-convert-program*)
                     (error "Unable to paste image from clipboard to file, since *imagemagick-convert-program* does not contain valid content: %s" *imagemagick-convert-program*))
                   (let ((cmd (concat "\"" *imagemagick-convert-program* "\" " "clipboard: " destination-file-with-path)))
                     (message "Pasting image from clipboard to %s with ImageMagick." destination-file-with-path)
                     (call-process-shell-command cmd nil 0)))) ; end of labels definitions
       (let* (
              ;; Ask for sub-directory name ; if "pics" already exists, propose it as default
              (subdirectory-name
               (if (file-directory-p (concat default-directory "pics/"))
                   (read-string "Subdirectory: " "pics")
                 (read-string "Subdirectory: ")))
              (subdirectory-path
               (if (string= "" subdirectory-name)
                   default-directory
                 (let ((res (concat default-directory subdirectory-name "/")))
                   (when (not (file-directory-p res))
                     (make-directory res)
                     (message "Creating directory \"%s\" within %s" subdirectory-name default-directory))
                   res)))
              ;; Ask for file name:
              (file-short-name (concat
                                (read-string "File name without date-hour completion and suffix (default:pic): " nil nil "pic")
                                (format-time-string "_%Y%m%d_%H%M%S")
                                ".png"))
              ;; Build destination path:
              (destination-file-with-path (concat "\"" subdirectory-path file-short-name "\"")))
         ;; Paste to file:
         (paste-image-from-clipboard-to-file-with-imagemagick destination-file-with-path)
         ;; Add link:
         (org-insert-link t (concat "file:" (string-remove-surrounding-quotes destination-file-with-path)))
         ;; (org-display-inline-images)
         )))) ; end of defun
 ) ; end of init section

(my-init--with-duration-measured-section 
 t 
 "org-mode C3 (embedded LaTeX)"

 ;; Highlight LaTeX:
 ;; (setq org-highlight-latex-and-related '(latex)) ; attention, peut ralentir considérablement org-mode ; see notes
 ;; Then inline latex like $y=mx+c$ will appear in a different colour in an org-mode file to help it stand out.
 ;; Caution
 (when nil
   (setq org-highlight-latex-and-related nil))
 
 ;; LaTeX fragments: change the directory for storage of temporary pics:
 (when nil
   (setq-local org-preview-latex-image-directory *latex-preview-pics-directory*))
 ;; ref : https://emacs.stackexchange.com/questions/16392/rendering-latex-code-inside-begin-latex-end-latex-in-org-mode-8-3-1
 ;; but directory seems empty?
 
 ;; C-c C-x C-l (org-latex-preview) to preview forms as:
 ;;   $\int_a^b x^2\mathrm{d}x$
 ;;   If $a^2=b$ and \( b=2 \), then the solution must be either $$ a=+\sqrt{2} $$ or \[ a=-\sqrt{2} \].
 ;; C-u C-x C-x C-l to cancel preview

 ;; works also with complete LaTeX environments
 ;;    \begin{equation}
 ;;    y=a+b
 ;;    \end{equation}

 ;; In order formulas to be visible as soon as the document is open:
 ;; # + STARTUP: latexpreview

 ;; In order formulas to be visible at each save,
 ;; add at the end of the document with a # and a space before each line:
 ;;    L ocal variables:
 ;;    a fter-save-hook: org-preview-latex-fragment
 ;;    e nd:
 ;; See https://emacs.stackexchange.com/questions/38198/automatically-preview-latex-in-org-mode-as-soon-as-i-finish-typing
 ) ; end of init section

(my-init--with-duration-measured-section 
 t
 "org-mode C4 (agenda)"

 (define-key global-map "\C-ca" 'org-agenda)

 (defun my/org-agenda-switch-to-perso-file ()
   (interactive)
   (find-file *F10-file-perso*))
 
 ) ; end of init section

(my-init--with-duration-measured-section 
 t
 "org-mode D (babel and source blocks)"

 ;; source blocks:
 (declare-function org-babel-mark-block "org") ; to avoid compilation warning
 (declare-function org-babel-goto-src-block-head "org") ; to avoid compilation warning
 (declare-function org-hide-block-toggle "org") ; ; to avoid compilation warning
 (with-eval-after-load 'org
   (defun my/copy-block ()
     (interactive)
     (call-interactively 'set-mark-command) ; sets mark A
     (org-babel-mark-block)  ; mark (select) src block = C-c C-v C-M-h
     (kill-new (buffer-substring (region-beginning) (region-end))) ; copy region
     (deactivate-mark)                      ; suppress highlighting
     (setq current-prefix-arg '(4))         ; C-u
     (call-interactively 'set-mark-command) ; to end of region
     (setq current-prefix-arg '(4))
     (call-interactively 'set-mark-command) ; to mark A
     (org-babel-goto-src-block-head)        ; go to beginning of block
     (org-fold-hide-block-toggle)           ; fold block
     ;; ‘org-hide-block-toggle’ is an obsolete function (as of 9.6); use ‘org-fold-hide-block-toggle’ instead.
     (message "src block copied to clipboard, and folded")))
 ;; ‘org-hide-block-toggle’ is an obsolete function (as
 ;;    of 9.6); use ‘org-fold-hide-block-toggle’ instead.

 ) ; end of init section

(my-init--with-duration-measured-section
 t
 "org-mode E (copy block)"

 (defun my/org-copy-link-or-inline-code-or-verbatim-or-block ()
   "Copy link, inline code between = or ~ signs in org-mode, or content of org block.
Fallback : current word.
(v2, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (let ((found nil))
     
     ;; (1) inline code?
     (let ((start-pos (point)))
       (save-excursion
         ;; Find the opening = before cursor
         (when (re-search-backward "=" (line-beginning-position) t)
           (let ((open-pos (point)))
             (goto-char start-pos)
             (when (re-search-forward "=" (line-end-position) t)
               (let ((close-pos (point)))
                 (when (and (> start-pos open-pos) (< start-pos close-pos))
                   (let ((content (buffer-substring-no-properties (1+ open-pos) (1- close-pos))))
                     (when (and (> (length content) 0)
                                (not (string-match-p "\n" content)))
                       (kill-new content)
                       (setq found t)
                       (message "Copied inline code: %s" content))))))))))
     
     ;; (2) inline verbatim?
     (unless found
       (let ((start-pos (point)))
         (save-excursion
           ;; Find the opening = before cursor
           (when (re-search-backward "~" (line-beginning-position) t)
             (let ((open-pos (point)))
               (goto-char start-pos)
               (when (re-search-forward "~" (line-end-position) t)
                 (let ((close-pos (point)))
                   (when (and (> start-pos open-pos) (< start-pos close-pos))
                     (let ((content (buffer-substring-no-properties (1+ open-pos) (1- close-pos))))
                       (when (and (> (length content) 0)
                                  (not (string-match-p "\n" content)))
                         (kill-new content)
                         (setq found t)
                         (message "Copied inline verbatim: %s" content)))))))))))
     
     ;; (3) org block?
     (unless found
       (let ((content-begin nil)
             (content-end nil)
             (element (org-element-context)))
         ;; (message "element = %s" element)
         ;; (message "(org-element-type element) = %s" (org-element-type element))
         (while (and element
                     (not (memq (org-element-type element)
                                '(src-block example-block export-block quote-block verse-block center-block special-block comment-block))))
           ;; (message "element = %s" element)
           ;; (message "(org-element-type element) = %s" (org-element-type element))
           (setq element (org-element-property :parent element)))
         (when element
           (save-excursion
             (goto-char (org-element-property :begin element))
             (forward-line 1)
             (setq content-begin (point))
             (re-search-forward "^#\\+END_" (org-element-property :end element) t)
             (beginning-of-line)
             (setq content-end (point))
             (kill-ring-save content-begin content-end)
             (setq found t)
             (message "Org block content copied.")))))

     ;; (4) Link in org-mode ?
     (unless found
       (let ((url (thing-at-point 'url t)))
         (when url
           (setq found t)
           (kill-new url)
           (message "Copied link: %s" url))))

     ;; (5) Word ?
     (unless found
       (set found (my/copy-word)))
     
     (unless found
       (message "No word, link, inline code, verbatim text or block found at point."))))

 (with-eval-after-load 'org
   (define-key org-mode-map (kbd "C-c c") #'my/org-copy-link-or-inline-code-or-verbatim-or-block))

 ) ; end of init section

(my-init--with-duration-measured-section
 t
 "org-mode F (copy to clipboard with format conversion)"

 (defun my/org-copy-region-ready-to-be-pasted-into-Word-Teams-Thunderbird-Gmail ()
   "Export Org-mode region to Windows CF_HTML clipboard format (including StartHTML, EndHTML, StartFragment, EndFragment markers).
Clipboard can be pasted into Microsoft Word, Microsoft Teams, Thunderbird and Gmail.
(v1 as of 2025-10-28, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (if (not (use-region-p))
       (message "No active region to export")
     (let* ((region-start (region-beginning))
            (region-end (region-end))
            (html-body (org-export-string-as
                        (buffer-substring region-start region-end)
                        'html t '(:with-toc nil 
                                            :html-postamble nil
                                            :preserve-breaks t))))
       
       ;; Extract body content and replace <p> tags with <br>
       (setq html-body
             (with-temp-buffer
               (insert html-body)
               (goto-char (point-min))
               (if (re-search-forward "<body[^>]*>\\(\\(.\\|\n\\)*\\)</body>" nil t)
                   (match-string 1)
                 html-body)))
       
       ;; Replace paragraph tags with line breaks
       (setq html-body
             (replace-regexp-in-string "<p[^>]*>" "" html-body))
       (setq html-body
             (replace-regexp-in-string "</p>" "<br>" html-body))
       
       ;; Build CF_HTML format (use \n only, Windows will handle conversion)
       (let* ((html-fragment (concat "<!--StartFragment-->" html-body "<!--EndFragment-->"))
              (html-full (concat "<html>\n<body>\n" html-fragment "\n</body>\n</html>"))
              (header "Version:0.9\nStartHTML:%010d\nEndHTML:%010d\nStartFragment:%010d\nEndFragment:%010d\n")
              (header-length (length (format header 0 0 0 0)))
              (start-html header-length)
              (end-html (+ start-html (string-bytes html-full)))
              (start-fragment (+ start-html 
                                 (string-bytes (substring html-full 0 (string-match "<!--StartFragment-->" html-full)))
                                 (string-bytes "<!--StartFragment-->")))
              (end-fragment (+ start-html (string-bytes (substring html-full 0 (string-match "<!--EndFragment-->" html-full)))))
              (cf-html (concat (format header start-html end-html start-fragment end-fragment)
                               html-full)))
         
         ;; Write to temp file and use PowerShell to set clipboard
         (let ((temp-file (make-temp-file "cf-html-" nil ".txt")))
           (with-temp-file temp-file
             (set-buffer-file-coding-system 'utf-8-unix)
             (insert cf-html))
           
           (call-process "powershell.exe" nil nil nil
                         "-Command"
                         (format "$content = Get-Content -Path '%s' -Raw -Encoding UTF8; Add-Type -AssemblyName System.Windows.Forms; $data = New-Object System.Windows.Forms.DataObject; $bytes = [System.Text.Encoding]::UTF8.GetBytes($content); $stream = New-Object System.IO.MemoryStream(,$bytes); $data.SetData('HTML Format', $stream); [System.Windows.Forms.Clipboard]::SetDataObject($data, $true); $stream.Close()"
                                 (replace-regexp-in-string "/" "\\\\" temp-file)))
           
           (delete-file temp-file)
           (message "Region copied as CF_HTML to clipboard"))))))
 
 (defun my/PREVIOUS-org-copy-to-clipboard-for-microsoft-word-and-teams ()
   "Copy buffer to clipboard as HTML.
Clipboard can then be pasted to Microsoft Word or Microsoft Teams. 
But pasting to Thunderbird or Gmail does not work.
Requires my/save-region-as-html."
   (unless (my-init--directory-exists-p *temp-directory*)
     (error "Temp directory is not valid: %s" *temp-directory*))
   (let* ((temp-file-name (concat *temp-directory* "org_mode_export_to_outlook_temp.html"))
          (cmd (concat "powershell -Command \"Get-Content '" temp-file-name "' | Set-Clipboard -AsHtml\"")))

     ;; (1) Convert to HTML and save in file
     (my/save-region-as-html temp-file-name)

     ;; (2) copy temporary file to clipboard as HTML: 
     (call-process-shell-command cmd nil 0)
     ;; (message cmd)
     (message "Content of the buffer exported to clipboard as HTML.")))
 
 (defun my/PREVIOUS-org-export-to-html-page-for-thunderbird-outlook-or-gmail ()
   "Convert buffer to html page and open it.
Requires my/save-region-as-html."
   (unless (my-init--directory-exists-p *temp-directory*)
     (error "Temp directory is not valid: %s" *temp-directory*))
   (let* ((temp-file-name (concat *temp-directory* "org_mode_export_to_outlook_temp.html"))
          (cmd (concat "powershell -Command \"& {type '" temp-file-name "' | Set-Clipboard -AsHtml}\"")))

     ;; (1) Convert to HTML and save in file
     (my/save-region-as-html temp-file-name)

     ;; (2) copy temporary file to clipboard as HTML: 
     ;; (w32-shell-execute 1 temp-file-name)
     ))

 ) ; end of init section

(my-init--with-duration-measured-section
 t
 "org-mode G (copy/paste from clipboard with format conversion)"

 (defun my/paste-clipboard-as-raw-html ()
   "Insert raw HTML from the Windows clipboard (CF_HTML) into current buffer, with visible tags.
(v1 as of 2025-10-28, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (let* ((html-raw
           (with-temp-buffer
             (call-process
              "powershell.exe" nil t nil
              "-NoProfile" "-Command"
              "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::Html)")
             (buffer-string)))
          ;; Extract fragment between <!--StartFragment--> and <!--EndFragment-->
          (fragment
           (if (string-match "<!--StartFragment-->(.*)<!--EndFragment-->" html-raw)
               (match-string 1 html-raw)
             html-raw)))
     (insert fragment)))

 (defun my/html-to-org (html)
   "Convert HTML string to org-mode format.
(v1 as of 2025-10-29, available in occisn/emacs-utils GitHub repository)"
   (with-temp-buffer
     (insert html)
     ;; Convert common HTML elements to org-mode
     (goto-char (point-min))
     
     ;; Headers (h1-h6)
     (dolist (level '(6 5 4 3 2 1))
       (goto-char (point-min))
       (let ((stars (make-string level ?*)))
         (while (re-search-forward (format "<h%d[^>]*>\\(.*?\\)</h%d>" level level) nil t)
           (replace-match (format "%s \\1" stars)))))
     
     ;; Bold
     (goto-char (point-min))
     (while (re-search-forward "<\\(b\\|strong\\)[^>]*>\\(.*?\\)</\\(b\\|strong\\)>" nil t)
       (replace-match "*\\2*"))
     
     ;; Italic
     (goto-char (point-min))
     (while (re-search-forward "<\\(i\\|em\\)[^>]*>\\(.*?\\)</\\(i\\|em\\)>" nil t)
       (replace-match "/\\2/"))
     
     ;; Code
     (goto-char (point-min))
     (while (re-search-forward "<code[^>]*>\\(.*?\\)</code>" nil t)
       (replace-match "~\\1~"))
     
     ;; Links
     (goto-char (point-min))
     (while (re-search-forward "<a[^>]*href=\"\\([^\"]+\\)\"[^>]*>\\(.*?\\)</a>" nil t)
       (replace-match "[[\\1][\\2]]"))
     
     ;; Unordered lists
     (goto-char (point-min))
     (while (re-search-forward "<li[^>]*>\\(.*?\\)</li>" nil t)
       (replace-match "- \\1"))
     
     ;; Paragraphs (add newlines)
     (goto-char (point-min))
     (while (re-search-forward "<p[^>]*>\\(.*?\\)</p>" nil t)
       (replace-match "\\1\n"))
     
     ;; Line breaks
     (goto-char (point-min))
     (while (re-search-forward "<br[^>]*>" nil t)
       (replace-match "\n"))
     
     ;; Remove remaining HTML tags
     (goto-char (point-min))
     (while (re-search-forward "<[^>]+>" nil t)
       (replace-match ""))
     
     ;; Decode HTML entities
     (goto-char (point-min))
     (while (re-search-forward "&nbsp;" nil t)
       (replace-match " "))
     (goto-char (point-min))
     (while (re-search-forward "&amp;" nil t)
       (replace-match "&"))
     (goto-char (point-min))
     (while (re-search-forward "&lt;" nil t)
       (replace-match "<"))
     (goto-char (point-min))
     (while (re-search-forward "&gt;" nil t)
       (replace-match ">"))
     (goto-char (point-min))
     (while (re-search-forward "&quot;" nil t)
       (replace-match "\""))
     
     ;; Clean up extra whitespace
     (goto-char (point-min))
     (while (re-search-forward "\n\n\n+" nil t)
       (replace-match "\n\n"))
     
     (string-trim (buffer-string))))

 (defun my/org-paste-from-Teams-Word-as-org ()
   "Paste from clipboard and convert to org-mode format.
Content of the clipboard may come from Microsoft Teams or Word.
Does not work as such from Thunderbird. Not tested from Gmail.
Requires my/html-to-org.
(v1 as of 2025-10-29, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (let* ((powershell-cmd "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::Html)")
          (html-content (shell-command-to-string 
                         (format "powershell.exe -Command \"%s\"" powershell-cmd))))
     (if (string-empty-p (string-trim html-content))
         (message "No HTML content in clipboard")
       ;; Extract the actual HTML fragment (Windows clipboard includes metadata)
       (let* ((fragment-start (string-match "<!--StartFragment-->" html-content))
              (fragment-end (string-match "<!--EndFragment-->" html-content))
              (html (if (and fragment-start fragment-end)
                        (substring html-content 
                                   (+ fragment-start (length "<!--StartFragment-->"))
                                   fragment-end)
                      html-content))
              (org-content (my/html-to-org html)))
         (insert org-content)))))

 (cl-defun my/org-region-to-markdown-clipboard ()
   "Convert Org-mode region to Markdown and copy to clipboard.
With prefix argument NO-TOC, suppress table of contents."
   (interactive)
   (if (use-region-p)
       (let* ((region-start (region-beginning))
              (region-end (region-end))
              (org-content (buffer-substring-no-properties region-start region-end))
              (no-toc t)
              (markdown-content
               (with-temp-buffer
                 (insert org-content)
                 (org-mode)
                 (let ((org-export-with-toc (not no-toc))
                       (org-export-preserve-breaks t)
                       (org-export-show-temporary-export-buffer nil))
                   (org-md-export-as-markdown))
                 (with-current-buffer "*Org MD Export*"
                   (prog1 (buffer-string)
                     (kill-buffer))))))
         (kill-new markdown-content)
         (message "Region converted to Markdown and copied to clipboard%s"
                  (if no-toc " (no TOC)" "")))
     (message "No region selected")))

 (defun my/markdown-region-to-org-clipboard ()
   "Convert Markdown region to Org-mode and copy to clipboard."
   (interactive)
   (if (use-region-p)
       (let* ((region-start (region-beginning))
              (region-end (region-end))
              (markdown-content (buffer-substring-no-properties region-start region-end))
              (mode1 "manually")
              (org-content
               (with-temp-buffer
                 (insert markdown-content)
                 ;; Use pandoc if available, otherwise basic conversion
                 (if (executable-find "pandoc2")
                     
                     (progn
                       (setq mode1 "with pandoc")
                       (shell-command-on-region (point-min) (point-max)
                                                "pandoc -f markdown -t org 2>NUL"
                                                (current-buffer) t)
                       ;; 2>NUL to avoid the warning:
                       ;;    [WARNING] input is not UTF-8 encoded: falling back to latin1.

                       ;; Remove trailing backslashes
                       (goto-char (point-min))
                       (while (re-search-forward "\\\\\\\\$" nil t)
                         (replace-match ""))
                       (buffer-string)) ; end of Pandoc branch

                   
                   ;; Fallback: basic manual conversion


                   (goto-char (point-min))
                   ;; Convert headers
                   (while (re-search-forward "^\\(#+\\) \\(.*\\)$" nil t)
                     (replace-match (concat (make-string (length (match-string 1)) ?*) 
                                            " " (match-string 2))))
                   ;; Convert bold **text** to temporary marker first
                   (goto-char (point-min))
                   (while (re-search-forward "\\*\\*\\([^*]+\\)\\*\\*" nil t)
                     (replace-match "⟨BOLD⟩\\1⟨/BOLD⟩"))
                   ;; Convert italic *text* to /text/
                   (goto-char (point-min))
                   (while (re-search-forward "\\*\\([^*]+\\)\\*" nil t)
                     (replace-match "/\\1/"))
                   ;; Convert italic _text_ to /text/
                   (goto-char (point-min))
                   (while (re-search-forward "_\\([^_]+\\)_" nil t)
                     (replace-match "/\\1/"))
                   ;; Now convert bold markers to org format
                   (goto-char (point-min))
                   (while (re-search-forward "⟨BOLD⟩\\([^⟨]+\\)⟨/BOLD⟩" nil t)
                     (replace-match "*\\1*"))
                   ;; Convert code `text` to =text=
                   (goto-char (point-min))
                   (while (re-search-forward "`\\([^`]+\\)`" nil t)
                     (replace-match "=\\1="))
                   ;; Convert links [text](url) to [[url][text]]
                   (goto-char (point-min))
                   (while (re-search-forward "\\[\\([^]]+\\)\\](\\([^)]+\\))" nil t)
                     (replace-match "[[\\2][\\1]]"))
                   (buffer-string)

                   
                   
                   
                   ))))
         (kill-new org-content)
         (message "Region converted to Org-mode (%s) and copied to clipboard" mode1))
     (message "No region selected")))

 (defun my--markdown-to-org-convert (text)
   "Convert markdown TEXT to org-mode format."
   (with-temp-buffer
     (insert text)
     (goto-char (point-min))
     
     ;; Convert headers (# to *)
     (while (re-search-forward "^\\(#+\\) " nil t)
       (replace-match (make-string (length (match-string 1)) ?*) nil nil nil 1))
     
     ;; Convert code blocks FIRST (```lang to #+BEGIN_SRC lang)
     ;; Track if we're opening or closing blocks
     (goto-char (point-min))
     (let ((in-block nil))
       (while (re-search-forward "^```\\([a-zA-Z0-9_+-]*\\)[ \t]*$" nil t)
         (let ((lang (match-string 1)))
           (if in-block
               (progn
                 (replace-match "#+END_SRC")
                 (setq in-block nil))
             (replace-match (format "#+BEGIN_SRC %s" lang))
             (setq in-block t)))))
     
     ;; Convert bold and italic in one pass to avoid interference
     ;; First handle bold: **text** or __text__ -> use placeholder
     (goto-char (point-min))
     (while (re-search-forward "\\*\\*\\([^*\n]+?\\)\\*\\*" nil t)
       (replace-match "⚿BOLD⚿\\1⚿BOLD⚿"))
     (goto-char (point-min))
     (while (re-search-forward "__\\([^_\n]+?\\)__" nil t)
       (replace-match "⚿BOLD⚿\\1⚿BOLD⚿"))
     
     ;; Now handle italic: *text* or _text_ -> /text/
     (goto-char (point-min))
     (while (re-search-forward "\\*\\([^*\n]+?\\)\\*" nil t)
       (replace-match "/\\1/"))
     (goto-char (point-min))
     (while (re-search-forward "_\\([^_\n]+?\\)_" nil t)
       (replace-match "/\\1/"))
     
     ;; Replace bold placeholders with org-mode bold
     (goto-char (point-min))
     (while (re-search-forward "⚿BOLD⚿\\([^⚿]+?\\)⚿BOLD⚿" nil t)
       (replace-match "*\\1*"))
     
     ;; Convert inline code (`code` to ~code~)
     (goto-char (point-min))
     (while (re-search-forward "`\\([^`]+\\)`" nil t)
       (replace-match "~\\1~"))
     
     ;; Convert links ([text](url) to [[url][text]])
     (goto-char (point-min))
     (while (re-search-forward "\\[\\([^]]+\\)\\](\\([^)]+\\))" nil t)
       (replace-match "[[\\2][\\1]]"))
     
     ;; Convert unordered lists (- or * to -)
     (goto-char (point-min))
     (while (re-search-forward "^\\([ \t]*\\)[*+-] " nil t)
       (replace-match "\\1- "))
     
     ;; Convert images (![alt](url) to [[url]])
     (goto-char (point-min))
     (while (re-search-forward "!\\[\\([^]]*\\)\\](\\([^)]+\\))" nil t)
       (replace-match "[[\\2]]"))
     
     (buffer-string)))

 (defun my/paste-markdown-as-org ()
   "Paste clipboard content, converting from markdown to org-mode format."
   (interactive)
   (let* ((markdown-text (current-kill 0))
          (org-text (my--markdown-to-org-convert markdown-text)))
     (insert org-text)))


 ) ; end of init section

(my-init--with-duration-measured-section 
 t
 "org-mode H (miscellaneous and hydra)"

;;; avoid electric indentation:
 (when (fboundp 'electric-indent-mode) (electric-indent-mode -1))

 (use-package olivetti
   :defer t
   :config (my-init--message-package-loaded "olivetti"))

 (defun my-org-occur ()
   (interactive)
   (occur ";;;\\s-===\\|^;;;\\s-===")
   ;; if "^" at the beginning: beginning of line
   )

 (defun my/switch-between-language-org-files ()
   "When in code buffer, switch between 'en' and 'fr' files. Useful when working on website."
   (interactive)
   (let* ((buffer-file-name1 (buffer-file-name)) ; c:/.../abc.org
          (target
           (cond ((string-match "/en/" buffer-file-name1)
                  (replace-regexp-in-string "/en/" "/fr/" buffer-file-name1))
                 ((string-match "/fr/" buffer-file-name1)
                  (replace-regexp-in-string "/fr/" "/en/" buffer-file-name1))
                 (t (error "Neither '/en/' or '/fr/' found in file path: %s" buffer-file-name1)))))
     (find-file target)))

 (defun my-org-fontify-dollar-words ()
   "Fontify words beginning with $ followed by letters as verbatim in org-mode."
   (font-lock-add-keywords
    nil
    '(("\\$[a-zA-Z]+" 0 'org-verbatim prepend))
    ;; org-code to be displayed as code
    ))

 (add-hook 'org-mode-hook 'my-org-fontify-dollar-words)

 (defhydra hydra-org-mode (:exit t :hint nil)
   "
^Org-mode hydra:
^---------------
_h_: occur in _h_eadlines (based on org-occur)
_o_: _o_ccur in all document || M-x occur (M-s o) || _c_ : my occur
Navigate in text: C-UP or C-DOWN to move by paragraphs | M-h to select paragraph
                  Alt-V to scroll up | C-v to scroll down
                  C-c C-SPC ace jump | C-l to center screen
                  C-SPC to mark | C-u C-SPC to go to previous mark
         in tree: C-c C-n or C-c C-p to move by heading | C-c C-b or C-c C-f same level
                  C-c C-u to move to parent heading
         search in headings : C-s [swiper] * foo | C-M-s > ^*.* foo > C-s or C-r 
Blocks: copy src _b_lock || C-(cvu) to go to block header || TAB sur BEGIN ou END || (org-show-all) (org-hide-block-all)
                   #+STARTUP: hideblocks #+STARTUP: nohideblocks
Embedded: C-c C-x C-v = org-toggle-inline-images ; #+ STARTUP: inlineimages
          LaTeX : C-c C-x C-l ; #+ STARTUP: latexpreview
Tree: TAB and Shift-TAB to develop or reduce the current or whole tree
      M-(SHIFT-)LEFT to modify the current level (so Ctrl to move)
      M-UP to move a block
      _n_, _w_: _n_arrow (C-x n s or M-x org-narrow-to-subtree) then _w_iden (C-x n w or M-x widen)
      C-c / r : sparse-tree  
Links: C-c C-l to create or edit [ [file:abc][name] ], [ [myimage.png] ]
       C-c C-o to follow
Abbrev: C-_, C-q SPACE, M-x unexpand-abbrev
Table: C-c } to see raw/col # | C-c C-c to update (in TBLFM) |  org-table-export pour exporter une table en CSV | M-S-RIGHT to insert column
Appearance : _v_ olivetti-mode
_e_ : import/export
Agenda: C-c a a || C-c a 1 pour custom ; et C-a t pour tasks
LaTeX fragments: C-c C-x C-l (org-toggle-latex-fragment)
Web site: _s_witch between FR and EN org files {end}"
   ("b" #'my/copy-block)
   ("c" #'my-org-occur)
   ("e" #'hydra-org-export/body)
   ;; ("d" #'my/ispell-show-personal-directories)
   ("h" #'my/org-occur-and-hide-content)
   ("n" #'org-narrow-to-subtree)
   ("o" #'org-occur)
   ("s" #'my/switch-between-language-org-files)
   ("v" #'olivetti-mode)
   ("w" #'widen)
   ("1" #'my/org-agenda-switch-to-perso-file)) ; end of hydra


 (defhydra hydra-org-export (:exit t :hint nil)
   "
^Org-mode import/export hydra:
^-----------------------------

Copy from org to clipboard, under following format:
   _1_ Word / Teams / Thunderbird / Gmail
   _2_ markdown

Paste into org-mode from clipboard under following format:
   _3_ from Word / Teams into org
   _4_ from markdown into org
"
   ("1" #'my/org-copy-region-ready-to-be-pasted-into-Word-Teams-Thunderbird-Gmail)
   ("2" #'my/org-region-to-markdown-clipboard)
   ("3" #'my/org-paste-from-Teams-Word-as-org)
   ("4" #'my/paste-markdown-as-org)
   ) ; end of hydra
 
 ) ; end of init section


;;; ===
;;; ============
;;; === CALC ===
;;; ============

(my-init--with-duration-measured-section 
 t
 "Calc"

 ;; launch: M-x calc or C-x * c
 ;; exit: q

 ;; Some references:
 ;; https://www.emacswiki.org/emacs/Calc_Tutorials_by_Andrew_Hyatt
 ;; https://www.johndcook.com/blog/2010/10/11/emacs-calc/
 ;; http://nullprogram.com/blog/2009/06/23/
 ;; https://news.ycombinator.com/item?id=15939165
 ;; https://www.gnu.org/software/emacs/manual/html_node/calc/index.html#Top

 (defvar org-babel-load-languages)      ; to avoid compilation warning

 (defun my--org-babel-load-calc (&rest _args)
   (message "Preparing org-mode babel for calc...")
   (add-to-list 'org-babel-load-languages '(calc . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-calc))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-calc)
 ;; https://www.reddit.com/r/emacs/comments/i6zuau/calc_source_blocks_in_orgmode_best_practices/
 ;; https://github.com/dfeich/org-babel-examples/blob/master/calc/calc.org
 
 (defun my/calc-read-macro ()
   "Interpret selected region as a Calc macro and jump to Calc stack, where the macro can be executed by pressing X.
(v2 as of 2024-01-27, v1 as of 2024-01-23)"
   (interactive)
   (if (use-region-p)
       (let* ((region-as-string (buffer-substring-no-properties (region-beginning) (region-end))))
         (read-kbd-macro (region-beginning) (region-end))
         (message "Ready to execute (X): %s ... %s"
                  (substring region-as-string 0 10)
                  (substring region-as-string -10 nil))
         (let ((w (get-buffer-window "*Calculator*")))
           (if (null w)
               (message "No window is displaying Calc!")
             (select-window w))))
     (message "No region selected!")))

 (declare-function calc-call-last-kbd-macro "calc") ; to avoid compilation warning
 (with-eval-after-load 'calc
   (defun my/calc-read-and-execute-macro ()
     "Interpret selected region as a Calc macro, jump to Calc stack, and execute it while printing execution duration as a message.
(v1 as of 2025-01-12)"
     (interactive)
     (if (use-region-p)
         (let* ((region-as-string (buffer-substring-no-properties (region-beginning) (region-end))))
           (read-kbd-macro (region-beginning) (region-end))
           (message "Ready to execute (X): %s ... %s"
                    (substring region-as-string 0 10)
                    (substring region-as-string -10 nil))
           (let ((w (get-buffer-window "*Calculator*")))
             (if (null w)
                 (message "No window is displaying Calc!")
               (progn
                 (select-window w)
                 (let ((beginning-time2 (float-time)))
                   (calc-call-last-kbd-macro nil) ; equivalent of X
                   (let* ((end-time2 (float-time))
                          (duration2 (* 1000 (float-time
                                              (time-subtract end-time2 beginning-time2)))))
                     (message "Calc macro executed in %.0f ms." duration2)))))))
       (message "No region selected!")))

   (defun my/calc-select-markdown-code-read-and-execute-calc-macro ()
     "Select markdown code block surrounding the cursor, interpret it as a Calc macro, jump to Calc stack and execute it while printing execution duration as a message.
(v1 as of 2025-01-12)"
     (interactive)
     (search-backward "```")
     (forward-line)
     (beginning-of-line)
     (call-interactively 'set-mark-command)
     (search-forward "```")
     (beginning-of-line)
     (my/calc-read-and-execute-macro)))

 (defun my/calc-select-markdown-code-and-read-calc-macro ()
   "Select markdown code block surrounding the cursor, interpret it as a Calc macro and jump to Calc stack, where the macro can be executed by pressing X.
(v2 as of 2024-01-27, v1 as of 2024-01-23)"
   (interactive)
   (search-backward "```")
   (forward-line)
   (beginning-of-line)
   (call-interactively 'set-mark-command)
   (search-forward "```")
   (beginning-of-line)
   (my/calc-read-macro))

 

 (declare-function calc-push "calc")    ; to avoid compilation warning
 (with-eval-after-load 'calc
   (defun calc-push-time-in-milliseconds ()
     "Push time expressed in milliseconds into Calc stack."
     (interactive)
     (calc-push (round (* (float-time (current-time)) 1000)))))

 (add-hook 'calc-mode-hook
           (lambda ()
             (local-set-key (kbd "d") 'calc-push-time-in-milliseconds)))

 (defhydra hydra-calc (:exit t :hint nil)
   "
^Calc hydra:
^-----------

Start and stop :
   M-x calc
   C-x * *
   q

Digit grouping: 'd g' to activate | d , SPC to set separator

Empty stack: C-u 0 DEL

Toggle algebraic mode on/off : m a 

Copy the stack (to past in another window) : M-w

` to edit top element of the stack

Macros :
   C-x (   |   C-x ) 
   X sinon C-x e
   Z `  ...  Z ' to protect registers
   Z K 3 then z 3 to store and execute macro
   Z E to edit
   M-x read kbd macro to read a macro from text file

F6 M-x my/calc-read-macro
F7 M-x my/calc-select-markdown-code-and-read-calc-macro

reset: M-x calc-reset

{end}
" 
   ;; ("e" #'a-function)
   )                                    ; end of hydra

 ) ; end of init section


;;; ===
;;; ==================
;;; ===== SHELLS =====
;;; ==================

(my-init--with-duration-measured-section
 t
 "shells"

 ;; === eshell

 (defun my--org-babel-load-eshell (&rest _args)
   (message "Preparing org-mode babel for eshell...")
   (add-to-list 'org-babel-load-languages '(eshell . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-eshell))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-eshell)

 (with-eval-after-load 'org
   (add-to-list 'org-babel-load-languages '(eshell . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages))

 (defun my--eshell-open-if-necessary ()
   "Check that eshell is open. Otherwise, open it."
   (let ((eshell-buffer (get-buffer "*eshell*")))
     (unless (and eshell-buffer (buffer-live-p eshell-buffer))
       (message "eshell is not opened... opening eshell...")
       (eshell))))

 (declare-function eshell-send-input "eshell") ; to avoid compilation warning
 (with-eval-after-load 'eshell
   (defun my--eshell-send-cmd (cmd)
     "Send CMD to eshell REPL (and open eshell before if necessary)."
     (interactive)
     (my--eshell-open-if-necessary)
     (with-current-buffer "*eshell*"
       (message "Sending command to eshell: %s" cmd)
       (goto-char (point-max))
       (insert cmd)
       (eshell-send-input))))

 (declare-function my--eshell-send-cmd "eshell") ; to avoid compilation warning
 (with-eval-after-load 'eshell
   (defun my--eshell-cd-to-directory-of-current-buffer-if-not-the-case ()
     "Send cd command to eshell REPL so that to change eshell current directory to the directory of the current buffer, only if already not the case"
     (interactive)
     (my--eshell-open-if-necessary)
     (if (string=
          default-directory
          (with-current-buffer "*eshell*" default-directory))
         (message "eshell current directory is already the right one")
       (my--eshell-send-cmd (concat "cd " default-directory)))))

 (defvar eshell-prompt-regexp)
 ;; to avoid Warning: reference to free variable ‘eshell-prompt-regexp’
 (with-eval-after-load 'eshell
   (defun my--eshell-wait-command-termination ()
     "Wait current command is eshell is terminated."
     (let ((eshell-buffer (get-buffer "*eshell*")))
       (with-current-buffer eshell-buffer
         (let ((prompt-regexp eshell-prompt-regexp))
           (while (progn
                    (goto-char (point-max))
                    (forward-line 0)
                    (not (looking-at-p prompt-regexp)))
             (accept-process-output (get-buffer-process eshell-buffer) 0.1)))))))

 ;; === cmd shell

 (defun my/open-cmd-shell-external ()
   "Open cmd in a native window, within the directory of current buffer (if it is a dired or a file)."
   (interactive)
   (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
       (let ((proc (start-process "cmd" nil "cmd.exe" "/C" "start" "cmd.exe" "/K" "cd" default-directory)))
         (set-process-query-on-exit-flag proc nil)
         (message "Native cms window opened in %s" default-directory))
     (let ((proc (start-process "powershell" nil "cmd.exe" "/C" "start" "cmd.exe")))
       (set-process-query-on-exit-flag proc nil)
       (message "No directory identified. Native cmd window opened."))))

 (defun my/open-cmd-shell-in-emacs ()
   "Open a Windows cmd.exe shell inside an Emacs buffer, using UTF-8 encoding and starting in the current buffer's directory (if any)."
   (interactive)
   (let* ((default-dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                           (file-name-directory (or (buffer-file-name) default-directory))
                         (expand-file-name "~")))
          (buffer-name (generate-new-buffer-name "*cmd*"))
          (coding-system-for-read 'utf-8)
          (coding-system-for-write 'utf-8))
     (with-current-buffer (get-buffer-create buffer-name)
       (setq default-directory default-dir)
       ;; Start cmd in UTF-8 mode (codepage 65001) and set to correct directory
       (apply #'make-comint-in-buffer "cmd" (current-buffer)
              "cmd.exe" nil
              (list "/K" (format "chcp 65001 > nul && cd /d \"%s\"" default-dir)))
       (pop-to-buffer (current-buffer))
       (message "cmd.exe started in %s (UTF-8 mode)" default-dir))))

 ;; === powershell

 (defun my/open-powershell-external ()
   "Open Powershell in a native window, within the directory of current buffer (if it is a dired or a file)."
   (interactive)
   (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
       (let ((proc (start-process "powershell" nil "cmd.exe" "/C" "start" "powershell.exe" "-NoExit" "-Command" (format "Set-Location '%s'" default-directory))))
         (set-process-query-on-exit-flag proc nil)
         (message "Native Powershell window opened in %s" default-directory))
     (let ((proc (start-process "powershell" nil "cmd.exe" "/C" "start" "powershell.exe" "-NoExit")))
       (set-process-query-on-exit-flag proc nil)
       (message "No directory identified. Native Powershell window opened."))))

 (defun my/open-powershell-in-emacs ()
   "Open PowerShell inside an Emacs buffer, using UTF-8 encoding,
and starting in the current buffer's directory (if any)."
   (interactive)
   (let* ((default-dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                           (file-name-directory (or (buffer-file-name) default-directory))
                         (expand-file-name "~")))
          (buffer-name (generate-new-buffer-name "*PowerShell*"))
          (process-environment (cons "CHCP=65001" process-environment))
          (coding-system-for-read 'utf-8)
          (coding-system-for-write 'utf-8))
     (with-current-buffer (get-buffer-create buffer-name)
       (setq default-directory default-dir)
       ;; Use UTF-8 mode and set console codepage to 65001 inside PowerShell
       (apply #'make-comint-in-buffer "PowerShell" (current-buffer)
              "powershell.exe" nil
              '("-NoExit" "-Command" "chcp 65001; [Console]::OutputEncoding = [Text.Encoding]::UTF8"))
       (pop-to-buffer (current-buffer))
       (message "PowerShell started in %s (UTF-8 mode)" default-dir))))

 ;; === msys2 bash

 (defun my/open-msys2-external ()
   "Open MSYS2 in a native window, within the directory of current buffer (if it is a dired or a file)."
   (interactive)
   (let ((msys2-shell-cmd (or (bound-and-true-p *msys2-shell-cmd*)
                              "C:/msys64/msys2_shell.cmd")))
     (unless (file-exists-p msys2-shell-cmd)
       (user-error "Could not find MSYS2 shell script at %s" msys2-shell-cmd))
     (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
         (let ((dir default-directory))
           (start-process "msys2" nil msys2-shell-cmd "-defterm" "-here" "-mingw64")
           (message "Native MSYS2 window opened in %s" dir))
       (start-process "msys2" nil msys2-shell-cmd "-defterm" "-mingw64")
       (message "Native MSYS2 window opened."))))

 (defun my/open-msys2-in-emacs ()
   "Open MSYS2 shell inside an Emacs buffer, using UTF-8 encoding
and starting in the current buffer's directory (if any)."
   (interactive)
   (let* ((default-dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                           (file-name-directory (or (buffer-file-name) default-directory))
                         (expand-file-name "~")))
          ;; Path to msys2_shell.cmd
          (msys2-shell-cmd *msys2-shell-cmd*)
          (buffer-name (generate-new-buffer-name "*MSYS2*"))
          (coding-system-for-read 'utf-8)
          (coding-system-for-write 'utf-8))
     (unless (file-exists-p msys2-shell-cmd)
       (user-error "Could not find MSYS2 shell script at %s" msys2-shell-cmd))
     (let ((process-environment (cons "MSYSTEM=MSYS"
                                      (cons "CHERE_INVOKING=1"
                                            process-environment)))
           (process-connection-type t))
       (with-current-buffer (get-buffer-create buffer-name)
         (setq default-directory default-dir)
         (comint-mode)
         ;; Set a custom prompt regexp for better prompt detection
         (setq-local comint-prompt-regexp "^.*\\$ ")
         ;; Launch via cmd.exe which can handle .cmd files
         (let ((proc (make-process
                      :name "MSYS2"
                      :buffer (current-buffer)
                      :command (list "cmd.exe" "/c" msys2-shell-cmd "-defterm" "-no-start" "-here")
                      :connection-type 'pty
                      :coding 'utf-8
                      :filter #'comint-output-filter)))
           (unless (process-live-p proc)
             (user-error "Failed to start MSYS2 process"))
           ;; Insert fake prompt immediately after process is created
           (goto-char (point-max))
           (insert (format "%s@%s MSYS %s\n$ " 
                           (user-login-name)
                           (system-name)
                           default-dir))
           (set-marker (process-mark proc) (point))
           ;; Give it time to initialize
           (sit-for 0.2)
           ;; Send cd command
           (comint-send-string proc (format "cd '%s'\n" default-dir)))
         (pop-to-buffer (current-buffer))
         (message "MSYS2 shell started in %s (UTF-8 mode)" default-dir)))))

 ;; === git bash

 (defun my/open-git-bash-external ()
   "Open Git Bash in a native window, within the directory of current buffer (if it is a dired or a file)."
   (interactive)
   (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
       (let ((proc (start-process "git-bash" nil "cmd.exe" "/C" 
                                  "cd" "/d" default-directory "&&"
                                  "start" "" *git-bash-executable* "--login" "-i")))
         (set-process-query-on-exit-flag proc nil)
         (message "Native Git Bash window opened in %s" default-directory))
     (let ((proc (start-process "git-bash" nil "cmd.exe" "/C" "start" "" 
                                *git-bash-executable* "--login" "-i")))
       (set-process-query-on-exit-flag proc nil)
       (message "No directory identified. Native Git Bash window opened."))))

 (defun my/open-git-bash-in-emacs ()
   "Open Git Bash inside an Emacs buffer, using UTF-8 encoding
and starting in the current buffer's directory (if any)."
   (interactive)
   (let* ((default-dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                           (file-name-directory (or (buffer-file-name) default-directory))
                         (expand-file-name "~")))
          ;; Adjust the path if Git is installed elsewhere:
          (bash-path *git-bash-executable*)
          (buffer-name (generate-new-buffer-name "*Git Bash*"))
          (coding-system-for-read 'utf-8)
          (coding-system-for-write 'utf-8))
     (unless (file-exists-p bash-path)
       (user-error "Could not find Git Bash executable (bash.exe)"))
     (let ((process-environment (cons "MSYS_NO_PATHCONV=1" process-environment)))
       (with-current-buffer (get-buffer-create buffer-name)
         (setq default-directory default-dir)
         ;; Use --login to load ~/.bashrc and -i for interactivity
         (apply #'make-comint-in-buffer "Git Bash" (current-buffer)
                bash-path nil '("--login" "-i"))
         ;; Send cd command to ensure directory is correct
         (comint-send-string (get-buffer-process (current-buffer))
                             (format "cd '%s'\n" default-dir))
         (pop-to-buffer (current-buffer))
         (message "Git Bash started in %s (UTF-8 mode)" default-dir)))))

 ;; === wsl bash

 ;; to install WSL on Windows :
 ;;   [cmd] wsl.exe --install
 ;; then, to know available distributions:
 ;;   [cmd] wsl.exe --list --online
 ;; and to install one:
 ;;   [cmd] wsl.exe --install Ubuntu
 ;; then to update it:
 ;;   [wsl] sudo apt update && sudo apt full-upgrade

 (defun my/open-wsl-shell-external ()
   "Open a visible WSL terminal (bash) window in the directory of the current buffer."
   (interactive)
   (let* ((dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                   (file-name-directory (or (buffer-file-name) default-directory))
                 (expand-file-name "~")))
          ;; Convert Windows path to WSL path (/mnt/c/Users/...)
          (wsl-dir (string-trim
                    (shell-command-to-string
                     (format "wsl wslpath '%s'" dir)))))
     (message "wsl-dir = %s" wsl-dir)
     (if (and wsl-dir (not (string-empty-p wsl-dir)))
         ;; Use `cmd /C start` to open a visible terminal window
         (let ((proc (start-process
                      "wsl" nil
                      "cmd.exe" "/C" "start" "wsl.exe" "~"
                      "-e" "bash" "-c"
                      (format "cd '%s' && exec bash" wsl-dir))))
           (set-process-query-on-exit-flag proc nil)
           (message "Opened WSL shell in %s" wsl-dir))
       (let ((proc (start-process "wsl" nil "cmd.exe" "/C" "start" "wsl.exe")))
         (set-process-query-on-exit-flag proc nil)
         (message "Opened WSL shell in home directory.")))))

 (defun my--wsl-comint-preoutput-filter (output)
   "Filter to handle WSL output."
   (replace-regexp-in-string "\r" "" output))

 (defun my/open-wsl-shell-in-emacs ()
   "Open WSL Bash inside an Emacs comint buffer with UTF-8 encoding, starting in the current buffer's directory, and avoiding CR issues.
The prompt is 'fake' and is not updated with successive 'cd'."
   (interactive)

   (let* ((win-dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                       (file-name-directory (or (buffer-file-name) default-directory))
                     (expand-file-name "~")))
          ;; Convert Windows path to WSL path
          (wsl-dir (string-trim
                    (shell-command-to-string
                     (format "wsl wslpath '%s'" (expand-file-name win-dir)))))
          (buffer-name (generate-new-buffer-name "*WSL*"))
          (coding-system-for-read 'utf-8-unix)
          (coding-system-for-write 'utf-8-unix)
          (wsl-path (or (executable-find "wsl.exe")
                        (user-error "Could not find wsl.exe"))))

     (with-current-buffer (get-buffer-create buffer-name)
       (setq default-directory win-dir)
       (comint-mode)
       (add-hook 'comint-preoutput-filter-functions 
                 'my--wsl-comint-preoutput-filter nil t)
       (let ((proc (make-process
                    :name "WSL"
                    :buffer (current-buffer)
                    :command (list wsl-path "bash" "-i")
                    :coding 'utf-8-unix
                    :connection-type 'pipe
                    :filter 'comint-output-filter)))
         (set-process-query-on-exit-flag proc nil)
         (when (and proc wsl-dir)
           (sit-for 1)
           (process-send-string proc (format "cd '%s'\n" wsl-dir))
           (sit-for 0.3)
           ;; Configure bash to always show prompt
           (process-send-string proc "export PROMPT_COMMAND='echo -n \"[WSL:$(pwd)]$ \"'\n")
           (sit-for 0.2)
           (process-send-string proc "\n")))
       (pop-to-buffer (current-buffer))
       (goto-char (point-max))
       (message "WSL (comint) started in %s" win-dir))))

 ;; === hydra

 (defhydra hydra-shells (:exit t :hint nil)
   "
^Shells hydra:
^-------------

eshell :     _e_ in buffer
cmd shell :  _c_ external or _d_ in buffer
powershell : _p_ external or _o_ in buffer
msys2 :      _m_ external or _y_ in buffer
git bash :   _g_ external or _i_ in buffer (Windows native equivalents)
wsl shell :  _w_ external or _s_ in buffer
"
   ("c" #'my/open-cmd-shell-external)
   ("d" #'my/open-cmd-shell-in-emacs)
   ("e" #'eshell)
   ("i" #'my/open-git-bash-in-emacs)
   ("g" #'my/open-git-bash-external)
   ("o" #'my/open-powershell-in-emacs)
   ("m" #'my/open-msys2-external)
   ("p" #'my/open-powershell-external)
   ("s" #'my/open-wsl-shell-in-emacs)
   ("w" #'my/open-wsl-shell-external)
   ("y" #'my/open-msys2-in-emacs)
   )

 ) ; end of init section


;;; ===
;;; ================
;;; ===== HTML =====
;;; ================

(my-init--with-duration-measured-section 
 t 
 "HTML"

 (defun my/save-region-as-html (temp-file-name)
   "Save region, otherwise buffer to HTML file.
(v1, available in occisn/emacs-utils GitHub repository)"
   (cl-labels ((replace-regexp (a b)
                 ""
                 (while (re-search-forward a nil t)
                   (replace-match b)))

               (html-add-b-u-i-br-tags ()
                 "Within an existing buffer, add <b></b> <u></u> <i></i> and <br/> tags."
                 (let ((p nil))
                   (goto-char 1)
                   (setq p (point))
                   (replace-regexp "’" "'")
                   (goto-char p)
                   (replace-regexp "\\*\\(.*?\\)\\*" "<b>\\1</b>")
                   (goto-char p)
                   (replace-regexp "_\\(.*?\\)_" "<u>\\1</u>")
                   (goto-char p)
                   (replace-regexp "\\([^<]\\)\\/\\([^ ].*?[^ ]\\)\\/" "\\1<i>\\2</i>")
                   (goto-char p)
                   (while (search-forward "\n" nil t) (replace-match "<br/>" nil t)) ; \r\n
                   ;; for line above, refer to https://stackoverflow.com/questions/5194294/how-to-remove-all-newlines-from-selected-region-in-emacs
                   (goto-char p)))) ; end of labels definitions
     
     (let* ((regionp (region-active-p))
            (beg (and regionp (region-beginning)))
            (end (and regionp (region-end)))
            (buf (current-buffer)))
       (when (file-exists-p temp-file-name) (delete-file temp-file-name))
       (with-temp-buffer
         (insert-buffer-substring buf beg end)
         (html-add-b-u-i-br-tags)
         (insert "<?xml version=\"1.0\" encoding=\"utf-8\"?>")
         (insert "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">")
         (insert "<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">")
         (insert "<html>")
         (insert "<head>")
         (insert "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>")
         (insert "</head>")
         (insert "<body>")
         ;;(insert "<pre white-space=\"-moz-pre-wrap\">")
         (insert "<font face='Calibri'>") ; size=\"-1\" 
         (insert "<div style=\"white-space: pre-wrap;\">")
         (insert "<div style=\"font-size:14.5px\">") ; to have Calibri 11
         (goto-char (point-max))
         (insert "</div>")            ; font-size
         (insert "</div>")            ; white-space
         (insert "</font>")
         ;;(insert "</pre>")
         (insert "</body>")
         (insert "</html>")
         ;; (set-buffer-file-coding-system 'utf-8)

         ;; (2) Save buffer as temporary HTML file
         (write-file temp-file-name)
         (kill-buffer)))))

 ;; https://www.html.am/reference/html-special-characters.cfm

 ) ; end of init section


;;; ===
;;; ===============
;;; ===== SES =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "SES"

 (defhydra hydra-ses (:exit t :hint nil)
   "
^SES hydra:
^----------

C-o to insert row (M-x ses-insert-row)
w   to resize cell
"
   ;; ("e" #'a-function)
   )) ; end of init section


;;; ===
;;; ====================
;;; ===== SPELLING =====
;;; ====================

(my-init--with-duration-measured-section 
 t
 "Spelling"

 ) ; end of init secton


;;; ===
;;; ===============
;;; === KAMOJIS ===
;;; ===============

;;; ¯\_(ツ)_/¯
;;; https://emojidb.org/ascii-emoticons-emojis


;;; ===
;;; ==================
;;; ===== ABBREV =====
;;; ==================

(my-init--with-duration-measured-section 
 t
 "Abbrev"

 ;; M-x list-abbrevs
 
 ;; M-x edit-abbrev then C-c C-c

 ;; delete ~/.emacs.d/abbrev-defs to empty cache

 ;; M-x unexpand-abbrev
 ;; C-q pour ne pas étendre avec SPACE

 (setq abbrev-file-name ;; tell emacs where to read abbrev
       "~/.emacs.d/abbrev-defs")

 (setq save-abbrevs 'silently)  

 (defun my/number-of-abbreviations ()
   "Return the number of abbreviations."
   (let ((count 0))
     (mapatoms (lambda (_) (setq count (1+ count))) global-abbrev-table)
     count))
 
 (define-skeleton quote-skeleton 
   "quote skeleton"
   "Title: "
   "#+BEGIN_QUOTE " str "\n"
   _ "\n"
   "#+END_QUOTE\n")
 (define-abbrev global-abbrev-table "qquote"
   "" 'quote-skeleton)

 (define-skeleton block-skeleton 
   "block skeleton"
   "Title: "
   "#+BEGIN " str "\n"
   _ "\n"
   "#+END\n")
 (define-abbrev global-abbrev-table "blockk"
   "" 'block-skeleton)

 (define-skeleton src-skeleton 
   "SRC skeleton"
   "Langage: "
   "#+BEGIN_SRC " str "\n"
   _ "\n"
   "#+END_SRC\n")
 (define-abbrev global-abbrev-table "srcc"
   "" 'src-skeleton)

 (define-abbrev-table 'global-abbrev-table
   '(("ualpha" "α")
     ("ubeta" "β")
     ("ugamma" "γ")
     ("udelta" "δ")
     ("uepsilon" "ε")
     ("uzeta" "ζ")
     ("ueta" "η")
     ("utheta" "θ")
     ("uiota" "ι")
     ("ukappa" "κ")
     ("ulambda" "λ")
     ("umeta" "μ")
     ("umu" "μ")
     ("unu" "ν")
     ("uxi" "ξ")
     ("uomicron" "ο")
     ("upi" "π")
     ("urho" "ρ")
     ("usigma" "σ")
     ("usigma2" "ς")
     ("utau" "τ")
     ("uupsilon" "υ")
     ("uphi" "φ")
     ("ukhi" "χ")
     ("upsi" "ψ")
     ("uomega" "ω")

     ;; lettres grecques majuscules :
     ("uAlpha" "Α")
     ("uBeta" "Β")
     ("uGamma" "Γ")
     ("uDelta" "Δ")
     ("uEpsilon" "Ε")
     ("uZeta" "Ζ")
     ("uEta" "Η")
     ("uTheta" "Θ")
     ("uIota" "Ι")
     ("uKappa" "Κ")
     ("uLambda" "Λ")
     ("uMu" "Μ")
     ("uNu" "Ν")
     ("uXi" "Ξ")
     ("uOmicron" "Ο")
     ("uPi" "Π")
     ("uRho" "Ρ")
     ("uSigma" "Σ")
     ("uTau" "Τ")
     ("uUpsilon" "Υ")
     ("uPhi" "Φ")
     ("ukhi" "Χ")
     ("upsi" "Ψ")
     ("uOmega" "Ω")))

 (define-abbrev-table 'global-abbrev-table
   '(("ajd" "aujourd'hui")
     ("qu'ajd" "qu'aujourd'hui")
     ("bcp" "beaucoup")
     ("Bcp" "Beaucoup")
     ("càd" "c'est-à-dire")
     ("chgt" "changement")
     ("chgts" "changements")
     ;; ("cmt" "comment")
     ("dvt" "développement")
     ("ê" "être")
     ("envt" "environnement")
     ("fàf" "face-à-face")
     ("impt" "important")
     ("jms" "jamais")
     ("l'odj" "l'ordre du jour")
     ("màd" "mise à disposition")
     ("màj" "mise à jour")
     ("mvs" "mauvais")
     ("mvt" "mouvement")
     ("mvts" "mouvements")
     ("nbx" "nombreux")
     ;; ("odj" "ordre du jour")
     ("pb" "problème")
     ("pbs" "problèmes")
     ("pê" "peut-être")
     ("prq" "pourquoi")
     ("Prq" "Pourquoi")
     ("qqc" "quelque chose")
     ("qqes" "quelques")
     ("qqun" "quelqu'un")
     ("qqx" "quelquefois")
     ("tjs" "toujours")
     ("uel" "eλ")
     ("ufin" "=fin=")
     ("upsy" "Ψ")
     ("vàv" "vis-à-vis")

     ("ué" "É")
     ("d'Ecole" "d'École")
     ("l'Ecole" "l'École")
     ("L'Ecole" "L'École")

     ("u(1)" "①")
     ("u(2)" "②")
     
     ("oeil" "œil")
     ("oeuf" "œuf")
     ("oeufs" "œufs")
     ("oeuvre" "œuvre")
     ("d'oeuvre" "d'œuvre")
     ("l'oeuvre" "l'œuvre")
     ("oeuvres" "œuvres")
     ;; ("coefficients" "cœfficients")
     ;; ("coefficient" "cœfficient")
     ("coeur" "cœur")
     ("coeurs" "cœurs")
     ("soeur" "sœur")
     ("soeurs" "sœurs")
     ("noeud" "nœud")
     ("noeuds" "nœuds")
     ("voeu" "vœu")
     ("voeux" "vœux")
     ("oe" "œ")
     ;; ("ae" "æ")
     ("Oe" "Œ")
     ("OE" "Œ")
     ;; ("AE" "Æ")
     ("manoeuvre" "manœuvre")

     ("ugg" "«")
     ("ugd" "»")
     
     ;; arrows:
     ("udonc" "⇒")                       ; ==> =>
     ("udownarrow" "↓")
     ("udownrightarrow" "↘")
     ("uequ" "⇔")
     ("uequiv" "⇔")
     ("uequivalence" "⇔")
     ("uimplique" "⇒")
     ("uleftarrow" "←")
     ("urightarrow" "→")                 ; pour fonctions: ↦
     ("uuparrow" "↑")
     ("uuprightarrow" "↗")
     ("uevolue" "↝")
     ("uévolue" "↝")

     ;; mathematical symbols:
     ("u+-" "±")
     ("u<>" "≠")
     ("uM" "M̄")
     ("udif" "≠")
     ("udiff" "≠")
     ("udifferent" "≠")
     ("udifférent" "≠")
     ("udiv" "÷")
     ("udivision " "÷")
     ("uemptyset" "∅")
     ("uensemblevide" "∅")
     ("uenv" "≃")
     ("uenviron" "≃")
     ("uexist" "∃")
     ("uexists" "∃")
     ("uf" "ƒ")
     ("uforall" "∀")
     ("uinclus" "⊂" )
     ("uinf" "≤")                        ; <=
     ("uinfini" "∞")
     ("uneg" "¬")
     ("unegation" "¬")
     ("univeau" "≡")
     ("unon" "¬")
     ("uplusminus" "±")
     ("uplusmoins" "±")
     ("upourtout" "∀")
     ("uprob" "ℙ")
     ("usousensemble" "⊂" )
     ("usup" "≥")                        ; >=

     ;; other symbols :
     ("uattention" "⚠")
     ("ubemol" "♭")
     ("ubémol" "♭")
     ("ucroix" "✝")
     ("udiametre" "⌀")
     ("uell" "ℓ")
     ("uhomme" "♂")
     ("ufemale" "♀")
     ("ufemme" "♀")
     ("umale" "♂")
     ("upointmedian" "·")
     ("uquadrillage" "▦") 
     ("urip" "✝")
     ("uRIP" "✝")
     ("utick" "✓")
     ("uwarning" "⚠")
     
     ;; http://xahlee.info/comp/unicode_index.html

     ("lb" ";;; -*- lexical-binding: t; -*-")))

 (my-init--load-additional-init-file "personal--abbrev.el")

 (dolist (hook '(org-mode-hook
                 text-mode-hook))
   (add-hook hook #'abbrev-mode))

 (write-abbrev-file))


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
     (when (not (file-writable-p *downloads-directory*))
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

 (use-package w32-browser
   ;; requires nothing
   :after (dired+)
   :config
   (my-init--message-package-loaded "w32-browser"))

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

 (defun my/open-current-dired-directory-in-windows-explorer ()
   "Open curent dired directory in Windows Explorer"
   (interactive)
   (if (equal major-mode 'dired-mode)
       (progn
         (message "Opening this dired directory in Windows explorer")
         (w32explore (expand-file-name default-directory)))
     (error "This is not a dired buffer. Could not be open in Windows Explorer")))
 ;; available in dired hydra

 ;; === (9) Copy file here

 (defun my/copy-file-here ()
   "Copy file as another file (adding ' (2)' at the end) in same dired folder.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (when (not (string-equal major-mode "dired-mode"))
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

   (unless (string-equal major-mode "dired-mode")
     (error "Trying to paste image from clipboard while not in dired-mode"))

   (cl-labels ((paste-image-from-clipboard-to-file-with-imagemagick (destination-file-with-path)
                 "Paste image from clipboard fo file DESTINATION-FILE-WITH-PATH with ImageMagick.
(v1, available in occisn/emacs-utils GitHub repository + adaptations)"
                 (unless (my-init--file-exists-p *imagemagick-convert-program*)
                   (error "Unable to paste image from clipboard to file, since *imagemagick-convert-program* does not contain valid content: %s" *imagemagick-convert-program*))
                 (let ((cmd (concat "\"" *imagemagick-convert-program* "\" " "clipboard: " destination-file-with-path)))
                   (message "Pasting image from clipboard to %s with ImageMagick." destination-file-with-path)
                   (call-process-shell-command cmd)))) ; end of labels definition
     
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

   (when (not (string-equal major-mode "dired-mode"))
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
   _w_: open this dired directory in _w_indows Explorer (M-x my/open-current-dired-directory-in-windows-explorer)
   _a_: open with Sum_a_tra
   _i_: open with _i_rfan View
   M-RET to open file with Windows application | C-RET to open directory in Windows Explorer (similar to _w_ above)

Find: my/find1 (native, buffer), my/_f_ind2 (projectile), my/find3 (projectile, buffer)
Grep:
   _x_ah / grep in current dired directory
   a_g_ / grep in current dired directory (pb encoding)
   _p_t / grep in current dired directory
   see also project tools
Filetags --> see project hydra

Copy last modification date to clipboard: M-x my/copy-file-last-modification-date-to-clipboard
Zip: _u_nzip, _z_ip content of current directory;
     _l_ist zip content, my/zip-add-to-archive-present-in-same-directory
pdf: M-x my/pdf-burst, M-x my/pdf-extract, M-x my/pdf-join
Files: my/list-big-files-in-current-directory-and-subdirectories, my/list-directories-with-many-files-or-direct-subdirectories (# of files), my/list-directories-of-big-size, my/list-directories-containing-zip-files, my/find-files-with-same-size-in-same-subdirectory
Attach file to mail: C-c RET C-a (gnus-dired-attach) {end}"
   ("a" #'my/open-with-Sumatra)
   ("c" #'my/copy-file-here)
   ("h" #'my/paste-image-from-clipboard-to-here)
   ("i" #'my/open-with-Irfan)
   ("f" #'my/find2)
   ("g" #'my/ag-grep-in-current-dired-directory)
   ("l" #'my/list-zip-content)
   ("p" #'my/pt-grep-in-current-dired-directory)
   ("u" #'my/unzip)
   ("w" #'my/open-current-dired-directory-in-windows-explorer)
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


;;; ===
;;; ======================================================================
;;; === PYTHON IN PATH (FOR UNOCONV USED BY DOCVIEW AND PYTHON ITSELF) ===
;;; ======================================================================

(my-init--with-duration-measured-section
 t
 "Python in PATH"

 ;; Personal note:
 ;;
 ;; Download LibreOffice from PortableApps
 ;;
 ;; It’s possible that python.exe is being hidden by a Windows 10 prompt to download it from the Microsoft Store.
 ;; The Store opens automatically when you type python in the command line.
 ;; Solution: go to “App execution aliases” (French: "Alias d'exécution d'application") and disable Python.

 ;; For unoconv, we shall use the Python provided by LibreOffice

 (unless (my-init--file-exists-p *python-executable--in-libreoffice-for-unoconv*)
   (my-init--warning "!! *python-executable--in-libreoffice-for-unoconv* is nil or does not exist: %s" *python-executable--in-libreoffice-for-unoconv*))

 (if (my-init--directory-exists-p *python-path-1--in-libreoffice-for-unoconv*)
     (progn
       (my-init--add-to-path "Python path (1) [in Libre Office, for unoconv]" *python-path-1--in-libreoffice-for-unoconv*)
       (my-init--add-to-exec-path "Python path (1) [in Libre Office, for unoconv]" *python-path-1--in-libreoffice-for-unoconv*))
   (my-init--warning "!! *python-path-1--in-libreoffice-for-unoconv* is nil or does not exist: %s" *python-path-1--in-libreoffice-for-unoconv*))

 (if (my-init--directory-exists-p *python-path-2--in-libreoffice-for-unoconv*)
     (progn
       (my-init--add-to-path "Python path (2) [in Libre Office, for unoconv]" *python-path-2--in-libreoffice-for-unoconv*)
       (my-init--add-to-exec-path "Python path (2) [in Libre Office, for unoconv]" *python-path-2--in-libreoffice-for-unoconv*))
   (my-init--warning "!! *python-path-2--in-libreoffice-for-unoconv* is nil or does not exist: %s" *python-path-2--in-libreoffice-for-unoconv*))
 
 ) ; end of init section


;;; ===
;;; ============================
;;; ===== DOCVIEW AND PEEP =====
;;; ============================

(my-init--with-duration-measured-section 
 t
 "Docview and peep"
 
 ;; ghostscript:
 (if (my-init--file-exists-p *gs-program*)
     (setq doc-view-ghostscript-program *gs-program*)
   (my-init--warning "!! *gs-program* is nil or does not exist: %s" *gs-program*))
 
 ;; for .ps :
 (if (my-init--directory-exists-p *gs-bin-directory*)
     (my-init--add-to-path "Ghostscript" *gs-bin-directory*)
   (my-init--warning "!! *gs-bin-directory* is nil or does not exist: %s" *gs-bin-directory*))
 
 ;; for .dvi :
 ;; in below directory, rename dvipdf into dvipdf.bat
 (if (my-init--directory-exists-p *gs-lib-directory*)
     (my-init--add-to-exec-path "dvipdf" (my-init--replace-linux-slash-with-two-windows-slashes *gs-lib-directory*))
   (my-init--warning "!! *gs-lib-directory* is nil or does not exist: %s" *gs-lib-directory*))
 ;; To check: (executable-find doc-view-dvipdf-program)
 ;; do not seem to work on pro1 computer (2025-12-07)
 
 ;; Python:
 ;; It is necessary for unoconv
 ;; See "PYTHON IN PATH" section above

 ;; Unoconv:
 ;; Zip can be downloaded from Github
 ;;
 (if (my-init--directory-exists-p *libreoffice-directory*)
     (let ((prog-name "LibreOffice for unoconv")
           (directory (my-init--replace-linux-slash-with-two-windows-slashes *libreoffice-directory*))
           (path-env (getenv "UNOPATH")))
       (if (cl-search directory path-env)
           (my-init--message2 "No need to add %s to Windows UNOPATH since already in: %s" prog-name directory)
         (setenv "UNOPATH" (concat directory ";" (getenv "UNOPATH")))
         (my-init--message2 "%s is added to UNOPATH." prog-name)))
   (my-init--warning "!! *libreoffice-directory* is nil or does not exist: %s" *libreoffice-directory*))
 ;;
 ;; test 1: "python unoconv -h" on command line shall give the list of possible unoconv arguments
 ;; test 2 : put a test file next to unoconv
 ;;     "python unoconv -f pdf test_powerpoint_pptx.pptx"
 ;;     on command line shall convert the file into pdf

 ;; doc-view... shall work
 ;;
 ;; M-x doc-view-dired-cache leads to doc-view cache in dired
 ;; (doc-view-clear-cache)
 ;;
 ;; tutorial : https://emacsnotes.wordpress.com/2018/08/09/222/

 ;; Addition of links:
 ;;
 ;; see https://emacs.stackexchange.com/questions/73017/how-to-associate-pdf-file-extension-with-pdf-tools
 ;;
 ;; .doc :
 (add-to-list 'auto-mode-alist '("\\.[dD][oO][cC]\\'" . doc-view-mode-maybe))
 ;; .odt :
 (add-to-list 'auto-mode-alist '("\\.[oO][dD][tT]\\'" . doc-view-mode-maybe))

 ;; preview with peep-dired:
 (use-package peep-dired
   ;; :defer t
   ;; :after (dired)
   :bind (:map dired-mode-map ("P" . peep-dired))
   :config (my-init--message-package-loaded "peep-dired"))
 
 ;; hydra:
 (defhydra hydra-docview (:exit t :hint nil)
   "
^Docview hydra:
^--------------

n, p     change page
M-<, M-> go to the top or bottom of the document
W        fit width
H        see all height
P        see all page
C-s C-s  search
q        quit
C-c C-c  change mode
C-c C-t  undrlying text

doc-view-cache-directory
M-x doc-view-dired-cache   leads to doc-view cache into _d_ired
M-x doc-view-clear-cache   _c_lears cache

(end)
"
   ("c" #'doc-view-clear-cache)
   ("d" #'doc-view-dired-cache))) ; end of init section


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


;;; ===
;;; ===================================
;;; ===== PROJECT AND PROJECTILE ===== 
;;; ==================================

(my-init--with-duration-measured-section
 t
 "Project and Projectile A (projectile)"
 
 (use-package projectile
   ;; projectile = project interaction library for Emacs 
   ;; requires emacs-24.3, pkg-info-0.4
   :defer nil
   :bind-keymap ("C-c p" . projectile-command-map)
   ;; :bind (:map projectile-mode-map
   ;;             ;; ("s-p" . projectile-command-map)
   ;;             ("C-c p" . projectile-command-map))
   ;; :requires ivy
   ;; :commands (projectile-dired my-init--counsel-projectile-switch-project-action-dired)
   :init (setq projectile-keymap-prefix (kbd "C-c p"))
   ;; should be in "init"
   ;; see https://github.com/bbatsov/projectile/issues/1258
   ;; :bind-keymap ("C-c p" . projectile-command-map)
   :config
   (my-init--message-package-loaded "projectile")
   (projectile-mode +1)
   ;; (global-set-key (kbd "C-c p h") #'hydra-project/body)
   (bind-key "h" #'hydra-project/body projectile-command-map)

   (defun my-init--counsel-projectile-switch-project-action-dired (project)
     "Open ‘dired’ at the root of the project."
     (require 'counsel-projectile)
     (let ((projectile-switch-project-action
            (lambda ()
              (projectile-dired))))
       (counsel-projectile-switch-project-by-name project)))
   
   (setq projectile-completion-system 'ivy)
   (setq projectile-indexing-method 'native)
   (setq projectile-enable-caching t)
   (setq projectile-auto-update-cache nil) ; to avoid intempestive index refreshing
   (setq projectile-file-exists-remote-cache-expire nil) ; idem
   (setq projectile-files-cache-expire nil)              ; idem
   ;; (add-to-list 'projectile-globally-ignored-files "*.el~") ;; en fait, à mettre dans .gitignore --
   (projectile-mode 1)) ; end of use-package

 ) ; end of init section

(my-init--with-duration-measured-section 
 t
 "Project and Projectile B (counsel-projectile)"

 (use-package counsel-projectile
   ;; requires counsel-0.10.0, projectile-0.14.0
   :defer nil
   :after (projectile)
   ;; :requires (projectile)
   ;; :commands (my-init--counsel-projectile-switch-project-action-dired counsel-projectile-switch-project-by-name)
   ;; :requires (projectile)
   :config

   (my-init--message-package-loaded "counsel-projectile")

   (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

   (counsel-projectile-mode)

   (when nil
     (ivy-set-actions
      'counsel-projectile-switch-project
      '(("z" (lambda (x) (message "hello")) "hello"))))
   ;; for C-c p p, addition of "open dired at the root of the project"
   
   (counsel-projectile-modify-action
    'counsel-projectile-switch-project-action
    '((add ("." my-init--counsel-projectile-switch-project-action-dired
            "open ‘dired’ at the root of the project")
           1)))
   ;; see https://github.com/ericdanan/counsel-projectile/issues/58

   ;; for C-c p f, addition of "open dired for the directory of the file"
   (counsel-projectile-modify-action
    'counsel-projectile-find-file-action
    '((add ("d" (lambda (file)
                  (dired (file-name-directory (projectile-expand-root file)))
                  (dired-goto-file (projectile-expand-root file))       
                  )
            "open in dired")
           1)))) ; end of use-package
 
 ;; problem: counsel-projectile-find-dir and counsel-projectile-find-file
 ;; systematically regenerate cache
 ;; to avoid this behaviour, we override a function:
 (with-eval-after-load 'counsel-projectile
   (defun counsel-projectile-find-dir (&optional arg)
     "Browse directories in project."
     (interactive "P")
     (if (and (eq projectile-require-project-root 'prompt)
              (not (projectile-project-p)))
         (counsel-projectile-find-dir-action-switch-project)
       (when nil (projectile-maybe-invalidate-cache arg))
       (ivy-read (projectile-prepend-project-name "Find dir: ")
                 (counsel-projectile--project-directories)
                 :require-match t
                 :sort counsel-projectile-sort-directories
                 :action counsel-projectile-find-dir-action
                 :caller 'counsel-projectile-find-dir))) ; end of defun
   (defun counsel-projectile-find-file (&optional arg dwim)
     "Jump to a file in the current project."
     (interactive "P")
     (if (and (eq projectile-require-project-root 'prompt)
              (not (projectile-project-p)))
         (counsel-projectile-find-file-action-switch-project)
       (when nil (projectile-maybe-invalidate-cache arg))
       (let* ((project-files (projectile-current-project-files))
              (files (and dwim (projectile-select-files project-files))))
         (ivy-read (projectile-prepend-project-name "Find file: ")
                   (or files project-files)
                   :matcher #'counsel-projectile--find-file-matcher
                   :require-match t
                   :sort counsel-projectile-sort-files
                   :action counsel-projectile-find-file-action
                   :caller 'counsel-projectile-find-file)))) ; end of defun
   ) ; end of with-eval-after-load
 ) ; end of init section

(my-init--with-duration-measured-section
 t
 "Project and Projectile C (filetags)"

 ;; filetags

 (defun my-init--list-all-filetags-in-project ()
   "Return the list of all filetags within project."
   (interactive)
   (message "Looking for all filetags used in current project...")
   
   (cl-labels ((string-suffix-p (suffix str &optional ignore-case)
                 "Return t if STR finished by SUFFIX.
Ignore case.
(v1, available in occisn/elisp-utils GitHub repository)" 
                 (let ((begin2 (- (length str) (length suffix)))
                       (end2 (length str)))
                   (when (< begin2 0) (setq begin2 0))
                   (eq t (compare-strings suffix nil nil
                                          str begin2 end2
                                          ignore-case))))) ; end of labels definition

     (if (and (eq projectile-require-project-root 'prompt)
              (not (projectile-project-p)))
         
         (counsel-projectile-switch-project 'my-init--list-all-filetags-in-project)
       
       (let* ((project-files (projectile-current-project-files))
              (org-files (cl-remove-if-not (lambda (file1) (string-suffix-p ".org" file1)) project-files))
              (tags-list '()))
         
         (with-temp-buffer

           ;; byte-compile warning: value from call to ‘cl-remove-if-not’ is unused
           (cl-remove-if-not (lambda (file1)
                               (let ((file11 (projectile-expand-root file1)))
                                 (when (file-exists-p file11)
                                   (erase-buffer)
                                   (insert-file-contents file11)
                                   (let ((tags-string1 (cadar (org-collect-keywords '("FILETAGS")))))
                                     (when (not (null tags-string1))
                                       (cl-loop for tag0 in (split-string tags-string1 " ")
                                                do
                                                (when (not (member tag0 tags-list))
                                                  (push tag0 tags-list)))))))) ; end of lambda
                             org-files) ; end of cl-remove-if-not
           ) ; end of with-temp-buffer
         tags-list)))) ; end of defun

 (defun my-init--alist-of-all-filetags-in-project-with-number-of-occurrences ()
   "Return an alist of all filetags within project, together with number of occurences."

   (cl-labels ((string-suffix-p (suffix str &optional ignore-case)
                 "Return t if STR finished by SUFFIX.
Ignore case.
(v1, available in occisn/elisp-utils GitHub repository)" 
                 (let ((begin2 (- (length str) (length suffix)))
                       (end2 (length str)))
                   (when (< begin2 0) (setq begin2 0))
                   (eq t (compare-strings suffix nil nil
                                          str begin2 end2
                                          ignore-case)))))
     
     (if (and (eq projectile-require-project-root 'prompt)
              (not (projectile-project-p)))
         
         (counsel-projectile-switch-project 'my-init--alist-of-all-filetags-in-project-with-number-of-occurrences)
       
       (let* ((project-files (projectile-current-project-files))
              (org-files (cl-remove-if-not (lambda (file1) (string-suffix-p ".org" file1)) project-files))
              (tags-alist '()))
         
         (with-temp-buffer

           ;; byte-compile warning: value from call to ‘cl-remove-if-not’ is unused
           
           (cl-remove-if-not (lambda (file1)
                               (let ((file11 (projectile-expand-root file1)))
                                 (when (file-exists-p file11)
                                   (erase-buffer)
                                   (insert-file-contents file11)
                                   (let ((tags-string1 (cadar (org-collect-keywords '("FILETAGS")))))
                                     (when (not (null tags-string1))
                                       (cl-loop for tag0 in (split-string tags-string1 " ")
                                                do
                                                (if (assoc tag0 tags-alist)
                                                    (setf (cdr (assoc tag0 tags-alist))
                                                          (+ 1 (cdr (assoc tag0 tags-alist))))
                                                  (push (cons tag0 0) tags-alist)))))))) ; end of lambda
                             org-files))

         tags-alist)))) ; end of defun

 (defun my/list-all-filetags-in-project ()
   "Open a new buffer, and list inside all filetags in current project."
   (interactive)
   
   (let ((tags-alist (my-init--alist-of-all-filetags-in-project-with-number-of-occurrences)))
     
     (switch-to-buffer (generate-new-buffer "*All tags in project*"))
     (insert "All tags in project:")
     (newline)
     (insert "--------------------")
     (newline)
     (when (null tags-alist)
       (insert "None.")
       (newline))
     (cl-loop for tag0 in tags-alist
              do (progn (insert (car tag0) " (" (number-to-string (cdr tag0)) ")")
                        (newline))))) ; end of defun

 (defun my/find-file-with-given-filetag ()
   "Ask the user for (i) tag(s) with available project tags,
                    (ii) desired output : ivy or dired
  and propose all org files contaning this/these tag(s) in its #+FILETAGS, 
    (i) either with ivy, in order the user to choose and open one,
    (ii) or as a dired buffer."
   (interactive)
   (cl-labels ((string-suffix-p (suffix str &optional ignore-case)
                 "Return t if STR finished by SUFFIX.
Ignore case.
(v1, available in occisn/elisp-utils GitHub repository)" 
                 (let ((begin2 (- (length str) (length suffix)))
                       (end2 (length str)))
                   (when (< begin2 0) (setq begin2 0))
                   (eq t (compare-strings suffix nil nil
                                          str begin2 end2
                                          ignore-case)))))
     
     (let ((tags-string "")
           (output-type "")
           (all-tags (my-init--list-all-filetags-in-project)))

       (when (null all-tags)
         (error "No filetag found in current project."))
       
       (ivy-read "Filetag: " all-tags
                 :action (lambda (f) (setq tags-string f))
                 :require-match t)

       (ivy-read "Output as: " '("dired" "ivy")
                 :action (lambda (f) (setq output-type f))
                 :require-match t)
       
       (if (and (eq projectile-require-project-root 'prompt)
                (not (projectile-project-p)))
           
           (counsel-projectile-switch-project 'my/find-file-with-given-filetag)
         
         (let*  ((project-files (projectile-current-project-files))
                 (org-files (cl-remove-if-not (lambda (file1) (string-suffix-p ".org" file1)) project-files)))
           
           (if (string= "" tags-string)
               
               ;; Case 1: no filetag is specified by user
               ;; -- actually impossible --
               
               (ivy-read (projectile-prepend-project-name (format "Find file among %s org files of current project: " (length org-files))) 
                         org-files
                         :matcher #'counsel-projectile--find-file-matcher
                         :require-match t
                         :sort counsel-projectile-sort-files
                         :action counsel-projectile-find-file-action
                         :caller 'my/find-file-with-given-filetag)
             
             ;; Case 2: filetag(s) is/are specified by user
             
             (let* ((tags-list0 (split-string tags-string " "))
                    (tags-string1 "")
                    (matching-files 
                     (progn
                       (message "Searching files containing filetag(s) '%s' within %s org files of current project..." tags-string (length org-files))
                       (with-temp-buffer
                         (cl-remove-if-not
                          (lambda (file1)
                            (let ((file11 (projectile-expand-root file1)))
                              (if (not (file-exists-p file11))
                                  nil
                                (progn
                                  (erase-buffer)
                                  (insert-file-contents file11)
                                  (setq tags-string1 (cadar (org-collect-keywords '("FILETAGS"))))
                                  (if (null tags-string1)
                                      nil
                                    (cl-loop for tag0 in tags-list0
                                             always (member tag0 (split-string tags-string1 " ")))))))) ; lambda
                          org-files)))))
               
               (if (null matching-files)
                   
                   (message "No file with filetag(s) '%s' found in project '%s'." tags-string (projectile-project-name))
                 
                 (cond ((equal output-type "ivy")
                        (ivy-read (projectile-prepend-project-name (format "Find file containing filetags '%s': " tags-string)) 
                                  matching-files
                                  :matcher #'counsel-projectile--find-file-matcher
                                  :require-match t
                                  :sort counsel-projectile-sort-files
                                  :action counsel-projectile-find-file-action
                                  :caller 'my/find-file-with-given-filetag))
                       
                       ((equal output-type "dired")
                        (dired (cons "Results"
                                     (cl-loop for file0 in matching-files
                                              collect (format "%s%s" (projectile-project-root) file0)))))
                       
                       (t (error "Output type not recognized: %s" output-type))))))))))) ; end of defun 


 ;; hydra:
 
 (defhydra hydra-project (:exit t :hint nil)
   "
^Project hydra:
^--------------
Projectile:
(M-o dans liste du mini-buffer)
- C-c p i    invalidate cache
- C-c p p    choose project
- C-c p m    projectile commander
- C-c p C-h  all keybindings 
- C-c p a    toggle among extensions (à configurer ?)
- C-c p s g  (grep by pt ?)
- C-c p b    project buffers open
- C-c p o    multi-occur ; mais uniquement sur les buffers ouverts
- C-c p D    open root in dired (idem C-p p modifié)
- C-c p e    recently-visited project file (not enabled?)
- C-c p ESC  switch to the most recently selected Projectile buffer.
- _a_ list of projets (~/.emacs.d/projectile-bookmarks.eld)

Find:
- C-c p d
- C-c p f

Git : C-x g to access the status buffer

FILETAGS:
- _t_: my/find-file-with-given-filetag
- _l_: my/list-all-filetags-in-project

Grep : 
- projectile-_p_t
- my projectile _s_earch (pb accents)
- _x_ah / grep in projectile project
- a_g_ / grep in projectile project (pb encoding ?)

Search & replace:
- C-c p r : search and replace (Y to approve all) {end}"
   ("a" (lambda () (interactive) (find-file "~/.emacs.d/projectile-bookmarks.eld")))
   ("g" #'my/ag-grep-in-projectile-project)
   ("l" #'my/list-all-filetags-in-project)
   ("p" #'projectile-pt)
   ("s" #'my/projectile-search)
   ("t" #'my/find-file-with-given-filetag)
   ("x" #'xah-grep-in-projectile-project)) ; end of hydra

 ) ; end of init section


;;; ===
;;; ================
;;; ===== FIND =====
;;; ================

(my-init--with-duration-measured-section 
 t
 "Find"

;;; === (1) in a project : projectile

;;; === (2) in a directory, native
 
 (defun my/find1 ()
   "Find in current dired directory with native Emacs tools, output as buffer."
   (interactive)
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to perform a my/find1 when not in dired-mode."))
   
   (cl-labels ((insert-directories-in-file-list (files)
                 "Take a list of files, and return the same list with directories intertwined.
For instance :
d1/a.org d1/b.org d2/c.org d3/d.org
-->
d1/ d1/a.org d1/b.org d2/ d2/c.org d3/ d3/d.org
(v1, available in occisn/elisp-utils GitHub repository)"
                 
                 (let ((current-dir "")
                       (files-intertwined-with-directories nil))
                   
                   (cl-loop for filename in files
                            for dir1 = (file-name-directory filename)
                            do (progn
                                 (when (not (string= current-dir dir1))
                                   (push dir1 files-intertwined-with-directories)
                                   (setq current-dir dir1))
                                 (push filename files-intertwined-with-directories)))
                   (reverse files-intertwined-with-directories)))) ; end of labels definition
     
     (let ((regexp (read-string "Regex: " ""))
           (root0 default-directory))
       
       (aprogn
        ;; list of absolute files:
        (directory-files-recursively root0 "" nil)
        ;; matching files:
        (cl-remove-if-not
         (lambda (filename) (string-match regexp filename))
         it)
        ;; matching files intertwined with directories:
        (insert-directories-in-file-list it)
        ;; results:
        (if (null it)
            (message "No file found (my/find1).")
          (dired (cons "Results (my/find1):" it))))))) ; end of defun

;;; === (3) dans un répertoire avec projectile :

 (defun my/find2 ()
   "Find in current dired directory with projectile."
   (interactive)
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to perform a my/find2 when not in dired-mode."))
   (let* ((directory default-directory)
          (file (projectile-completing-read
                 "Find file in current directory: "
                 (projectile-dir-files directory))))
     (find-file (expand-file-name file directory)))) ; end of defun

;;; === (4) dans un répertoire avec projectile, sortie sous forme de buffer

 (defun my/find3 ()
   "Find in current dired directory with projectile, output as buffer."
   (interactive)
   
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to perform a my/find3 when not in dired-mode."))

   (cl-labels ((insert-directories-in-file-list (files)
                 "Take a list of files, and return the same list with directories intertwined.
For instance :
d1/a.org d1/b.org d2/c.org d3/d.org
-->
d1/ d1/a.org d1/b.org d2/ d2/c.org d3/ d3/d.org
(v1, available in occisn/elisp-utils GitHub repository)"
                 
                 (let ((current-dir "")
                       (files-intertwined-with-directories nil))
                   
                   (cl-loop for filename in files
                            for dir1 = (file-name-directory filename)
                            do (progn
                                 (when (not (string= current-dir dir1))
                                   (push dir1 files-intertwined-with-directories)
                                   (setq current-dir dir1))
                                 (push filename files-intertwined-with-directories)))
                   (reverse files-intertwined-with-directories)))) ; end of labels definition
     
     (let ((regexp (read-string "Regex: " ""))
           (root0 default-directory))
       
       (aprogn
        ;; list of relative files and dirs:
        (projectile-dir-files root0)
        ;; list of absolute files and dirs:
        (mapcar (lambda (filename) (concat root0 filename)) it)
        ;; list of absolute files:
        (cl-remove-if #'file-directory-p it)
        ;; matching files:
        (cl-remove-if-not
         (lambda (filename) (string-match regexp filename))
         it)
        ;; matching files intertwined with directories:
        (insert-directories-in-file-list it)
        ;; results:
        (if (null it)
            (message "No file found (my/find3).")
          (dired (cons "Results (my/find3):" it))))))) ; end of defun

 ) ; end of init section


;;; ===
;;; ================
;;; ===== GREP =====
;;; ================

(my-init--with-duration-measured-section 
 t
 "Grep"

 ;; my projectile search:

 (defun my/projectile-search (&optional arg)
   ""
   (interactive)
   (let* ((directory (if arg
                         (file-name-as-directory
                          (read-directory-name "Search in directory: "))
                       (projectile-acquire-root)))
          (regexp (read-string "Regexp: "))
          (files (projectile-files-with-string regexp directory))
          (case-fold 'default)
          (count 0))
     (fileloop-initialize
      files
      (lambda ()
        (let ((case-fold-search (fileloop--case-fold regexp case-fold)))
          (re-search-forward regexp nil t)))
      (lambda ()
        (let ((case-fold-search (fileloop--case-fold regexp case-fold)))
          ;; (re-search-forward regexp nil t)
          (setq count (+ count 1))
          (when (string= "" (read-string (format "%s already found - go to next? (enter) " count)))
            (fileloop-continue)
            ))))
     (fileloop-continue))) ; end of defun
 ;; lexical needed?
 ;; problem with accents in path?
 
 ;; projectile-pt (platinum):

 (if (my-init--directory-exists-p *pt-directory*)
     (my-init--add-to-path-and-exec-path "pt" *pt-directory*)
   (my-init--warning "!! *pt-directory* is nil or does not exist: %s" *pt-directory*))
 
 (use-package pt
   :commands (my/pt-grep-in-current-dired-directory projectile-pt)
   :config (my-init--message-package-loaded "pt")

   (defun my/pt-grep-in-current-dired-directory ()
     ""
     (interactive)
     (pt-regexp-file-pattern
      (read-string "Searched string (regex): ")
      default-directory
      (read-string "Files: " "org|el|sql|txt")))) ; end of use-package

 ;; ag (silver):

 (if (my-init--directory-exists-p *ag-directory*)
     (my-init--add-to-path-and-exec-path "ag" *ag-directory*)
   (my-init--warning "!! *ag-directory* is nil or does not exist: %s" *ag-directory*))

 (use-package ag
   :commands (my/ag-grep-in-current-dired-directory my/ag-grep-in-projectile-project)
   :config
   (my-init--message-package-loaded "ag")

   (defun my/ag-grep-in-current-dired-directory ()
     ""
     (interactive)
     (ag
      (read-string "Search string: ")
      default-directory)
     (other-window 1)
     (let ((buffer-read-only nil)
           (text (buffer-substring (point-min) (point-max))))
       (delete-region (point-min) (point-max))
       (insert (decode-coding-string (encode-coding-string text 'utf-8-dos) 'latin-1))))
   
   (defun my/ag-grep-in-projectile-project ()
     ""
     (interactive)
     (ag
      (read-string "Search string: ")
      (projectile-acquire-root))
     (other-window 1)
     (revert-buffer-with-coding-system 'latin-1 t))) ; end of use-package

 ;; xah:

 (if (my-init--file-exists-p *xah-find-file*)
     (load-file *xah-find-file*)
   (my-init--warning "!! *xah-find-file* is nil or does not exist: %s" *xah-find-file*))

 (defun xah-grep-in-current-dired-directory ()
   ""
   (interactive)
   (xah-find-text 
    (read-string "Searched string: ")
    default-directory
    (read-string "Files: " "[.*]\\(org\\|lisp\\|el\\|sql\\|txt\\)$") ; "[.*][org\|el\|sql\|txt]$"
    nil t))

 (defun xah-grep-in-projectile-project ()
   ""
   (interactive)
   (xah-find-text
    (read-string "Searched string: ")
    (projectile-acquire-root)
    (read-string "Files: " "[.*]\\(org\\|lisp\\|el\\|sql\\|txt\\)$")
    nil t))
 
 ;; (use-package xah-find
 ;;   :commands (xah-grep-in-projectile-project xah-grep-in-current-dired-directory) ; to defer
 ;;   :config
 ;;   (my-init--message-package-loaded "xah-find"))

 ) ; end of init section


;;; ===
;;; ============================
;;; ===== EMACS AS LISP IDE ====
;;; ============================

(my-init--with-duration-measured-section 
 t
 "Emacs as Lisp IDE"

 ;; ===
 ;; === (EL) interpretor in mini-buffer
 
 ;; ~M-:~
 ;; ~C-u M-:~ insert the result into current buffer instead of printing it in the echo area.

 ;; ===
 ;; === (EL) C-x C-e anywhere
 
 ;; C-x C-e
 ;;
 ;; in scratch, we can type lisp and interpret with C-j

 ;; ==
 ;; == (CL) Choice of Common Lisp flavour
 
 (setq *common-lisp-flavor* "sbcl")
 
 ;; ==
 ;; == (CL) Assignments subsequent to the choice of Lisp flavour

 (cond ((string= *common-lisp-flavor* "sbcl")
        (progn
          (setq *inferior-lisp-program* *sbcl--inferior-lisp-program*)
          (setq *common-lisp-directory* *sbcl--common-lisp-directory*)
          (setq *common-lisp-program* *sbcl--common-lisp-program*)))
       ((string= *common-lisp-flavor* "clisp")
        (progn
          (setq *inferior-lisp-program* *clisp--inferior-lisp-program*)
          (setq *common-lisp-directory* *clisp--common-lisp-directory*)
          (setq *common-lisp-program* *clisp--common-lisp-program*)))
       ((string= *common-lisp-flavor* "ccl")
        (progn
          (setq *inferior-lisp-program* *ccl--inferior-lisp-program*)
          (setq *common-lisp-directory* *ccl--common-lisp-directory*)
          (setq *common-lisp-program* *ccl--common-lisp-program*)))
       ((string= *common-lisp-flavor* "abcl")
        (progn
          (setq *inferior-lisp-program* *abcl--inferior-lisp-program*)
          (setq *common-lisp-directory* *abcl--common-lisp-directory*)
          (setq *common-lisp-program* *abcl--common-lisp-program*)))
       (t (my-init--warning "Lisp flavour not recognized: %s" *common-lisp-flavor*))) ; end of cond

 ;; set directory is valid and set path:
 (if (my-init--directory-exists-p *common-lisp-directory*)
     (my-init--add-to-path-and-exec-path "Common Lisp" *common-lisp-directory*)
   (my-init--warning "Common Lisp directory nil or not valid: %s" *common-lisp-directory*))

 ;; check program is valid:
 (if (my-init--file-exists-p *common-lisp-program*)
     nil
   (my-init--warning "Common Lisp program nil or not valid: %s" *common-lisp-program*))

 ;; ===
 ;; === (CL) Start Common Lisp without slime ===

 (defun my/start-external-common-lisp ()
   "Starts external Common Lisp."
   (interactive)
   (let ((cmd (concat "\"" (my-init--replace-linux-slash-with-two-windows-slashes *common-lisp-program*) "\"")))
     (w32-shell-execute "open" cmd)
     (message "External Common Lisp opened.")))
 ;; available in hydra      

 (defun my/start-common-lisp-as-buffer ()
   "Starts Common Lisp within a buffer"
   (interactive)
   (let ((cmd (concat "\"" (my-init--replace-linux-slash-with-two-windows-slashes *common-lisp-program*) "\"")))
     (async-shell-command cmd nil nil)))

 ;; ==
 ;; == (CL) Slime

 ;; M-x slime should work

 ;; Always show compilation notes buffer
 ;; (setq slime-compilation-finished-hook 'slime-maybe-show-compilation-log)

 ;; Show compilation buffer even with no errors
 ;; (setq slime-display-compilation-output t)

 ;; Display compilation notes in the REPL window
 (setq slime-display-compilation-output t)

 ;; Configure display-buffer to reuse REPL window for compilation notes
 (add-to-list 'display-buffer-alist
              '("\\*slime-compilation\\*"
                (display-buffer-reuse-window display-buffer-same-window)
                (reusable-frames . t)
                (inhibit-same-window . nil)))

 ;; if necessary:
 ;; M-x slime-show-compilation-log

 ;; ==
 ;; === (EL+CL) Babel
 
 (defun my--org-babel-load-lisp (&rest _args)
   (message "Preparing org-mode babel for lisp...")
   (add-to-list 'org-babel-load-languages '(lisp . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-lisp))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-lisp)

 (defun my--org-babel-load-emacs-lisp (&rest _args)
   (message "Preparing org-mode babel for emacs-lisp...")
   (add-to-list 'org-babel-load-languages '(emacs-lisp . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-emacs-lisp))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-emacs-lisp)
 
 ;; ===
 ;; === (EL+CL) Show line number on the left

 (dolist (mode '(emacs-lisp-mode-hook lisp-mode-hook))
   (add-hook mode (lambda () (display-line-numbers-mode 1))))
 
 ;; ===
 ;; === (EL+CL) Indentation

 ;; (1) Emacs Lisp

 (setq lisp-indent-function 'lisp-indent-function)
 ;; (setq lisp-indent-function 'common-lisp-indent-function)
 ;; indent : http://ergoemacs.org/emacs/emacs_indentation.html
 ;;   http://ergoemacs.org/emacs/emacs_tabs_space_indentation_setup.html

 ;; (2) Common Lisp

 ;; CL indentation instead of Emacs Lisp indentation :
 (add-hook 'lisp-mode-hook
           (lambda ()
             (set (make-local-variable lisp-indent-function)
                  'common-lisp-indent-function)))
 ;; see https://lispcookbook.github.io/cl-cookbook/emacs-ide.html

 ;; (3) Common:

 (dolist (mode '(emacs-lisp-mode-hook lisp-mode-hook))
   (add-hook mode (lambda () (electric-indent-local-mode 1))))

 (defun my/indent-lisp-buffer ()
   "Indent Lisp buffer."
   (interactive)
   (save-excursion
     (let ((nb-tabs (count-matches "\t")))

       ;; (1) untabify if necessary:
       (when (> nb-tabs 0)
         (if (= nb-tabs 1)
             (message "1 tab identified... untabifying buffer")
           (message "%d tabs identified... untabifying buffer" nb-tabs))
         (goto-char (point-min))
         (push-mark)
         (goto-char (point-max))
         (untabify (point) (mark))
         (pop-mark))

       ;; (2) indent:       
       (indent-region (point-min) (point-max))

       (recenter-top-bottom))))

 (when nil
   (use-package aggressive-indent
     ;; defer
     :config
     (add-hook 'emacs-lisp-mode-hook #'aggressive-indent-mode)
     (add-hook 'lisp-mode-hook #'aggressive-indent-mode)
     (my-init--message-package-loaded "aggressive-indent")))

 ;; ===
 ;; === (EL+CL) Extra font (for bound variables and quoted expressions)

 ;; This package highlights the location where local variables is created (bound, for example by let) as well as quoted and backquoted constant expressions.
 (use-package lisp-extra-font-lock
   :defer nil
   :mode ("\\.el\\'" . emacs-lisp-mode)
   ("\\.lisp\\'" . lisp-mode)
   :hook ((emacs-lisp-mode lisp-mode slime-repl-mode) . lisp-extra-font-lock-global-mode)
   :config
   (my-init--message-package-loaded "lisp-extra-font-lock")
   ;; (lisp-extra-font-lock-global-mode 1)
   )
 ;; see also: (font-lock-add-keywords 'lisp-mode '(("(\\(\\(define-\\|do-\\|with-\\)\\(\\s_\\|\\w\\)*\\)" 1 font-lock-keyword-face)))

 ;; ===
 ;; === (EL+CL) Code folding (hs-minor-mode)

 (add-hook 'emacs-lisp-mode-hook #'hs-minor-mode)
 (add-hook 'lisp-mode-hook #'hs-minor-mode)

 ;; ===
 ;; === (EL+CL) my occur

 (defun my-elisp-occur ()
   (interactive)
   (occur "\\s-*(defhydra [^%]\\|\\s-*(use-\\package [^%]\\|\\s-*(defun [^%]\\|\\s-*(cl\\-defun [^%]\\|\\s-*(defvar [^%]\\|\\s-*(defface [^%]\\|\\s-*(defcustom [^%]\\|\\s-*(defmacro [^%]\\|\\s-*(cl-\\defmacro [^%]\\|\\s-*(defparameter [^%]\\|\\s-*(global-set-key[^%]\\|\\s-*;;*\\s-===\\|\\s-*(ert-deftest [^%]"))
 ;; ^ = beginning of line
 ;; \s-* = Zero or more whitespace characters (spaces, tabs, etc.); to be preceded by an additional \
 ;; \s- = one whitespace character; to be preceded by an additional \
 ;; ;;* = 3 or more ;

 (defun my-cl-occur ()
   (interactive)
   (occur "\\s-*(defparameter [^%]\\|\\s-*(deftype [^%]\\|\\s-*(defstruct [^%]\\|\\s-*(defun [^%]\\|\\s-*(defmacro [^%]\\|\\s-*;;*\\s-===\\|\\s-*(define-test [^%]\\|\\s-*(parachute:define-test [^%]")
   (other-window 1))
 ;; ^ = beginning of line
 ;; \s-* = Zero or more whitespace characters (spaces, tabs, etc.); to be preceded by an additional \
 ;; \s- = one whitespace character; to be preceded by an additional \
 ;; ;;* = 3 or more ;

 ;; ===
 ;; === (EL+CL) Expand region with C-=

 (use-package expand-region
   ;; :defer nil
   :config (my-init--message-package-loaded "expand-region")
   :bind ("C-=". er/expand-region))

 ;; ===
 ;; === (EL+CL) Completion (company & ac-slime)

 ;; C-M-i, C-:

 ;; (1) Emacs Lisp: company

 ;; Company is a text completion framework for Emacs. The name stands for "complete anything".
 ;; It uses pluggable back-ends and front-ends to retrieve and display completion candidates.

 (use-package company                   ; company-mode
   :defer nil
   :hook ((emacs-lisp-mode lisp-mode) . company-mode) 
   :config
   ;; (add-hook 'after-init-hook 'global-company-mode)
   ;; (add-hook 'after-init-hook 'global-company-mode)
   ;; (setq company-idle-delay 0) ; no delay in showing suggestions
   ;; (setq company-minimum-prefix-length 1) ; show suggestions after entering one character
   ;; (setq company-selection-wrap-around t)
   ;; (company-tng-configure-default) ; use tab key to cycle through suggestions ('tng' means 'tab and go')
   (setq company-idle-delay nil)        ; no automatic start
   (define-key emacs-lisp-mode-map (kbd "C-M-i") #'company-complete)
   (define-key lisp-mode-map (kbd "C-M-i") #'company-complete)
   (my-init--message-package-loaded "company-mode"))
 ;; C-: associated with counsel-company

 ;; (2) Common Lisp with company and slime-company

 ;; above 'use-package company' already proposes configuration for lisp-mode

 (use-package slime-company
   :after (slime company)
   :config 
   (setq slime-company-completion 'fuzzy
         slime-company-after-completion 'slime-company-just-one-space)
   (define-key company-active-map (kbd "\C-d") 'company-show-doc-buffer)
   (define-key company-active-map (kbd "M-.") 'company-show-location)
   (when nil
     (defun slime-show-description (string package)
       "source: https://github.com/digikar99/emacs-noob/blob/slime-company/init.el"
       (let ((bufname (slime-buffer-name :description)))
         (slime-with-popup-buffer (bufname :package package
                                           :connection t
                                           :select slime-description-autofocus)
           (when (string= bufname "*slime-description*")
             (with-current-buffer bufname (slime-company-doc-mode)))
           (princ string)
           (goto-char (point-min))))))
   (my-init--message-package-loaded "slime-company"))

 ;; and activate slime-company in slime below

 (defun ora-slime-completion-in-region (_fn completions start end)
   ""
   (funcall completion-in-region-function start end completions))

 (advice-add
  'slime-display-or-scroll-completions
  :around #'ora-slime-completion-in-region)
 ;; reference: https://www.reddit.com/r/emacs/comments/dkz7tm/using_ivy_w_slime/

 ;; To complete in buffer: (mini-buffer?)
 (define-key lisp-mode-map (kbd "C-M-i") #'complete-symbol) ; counsel-cl is deprecated
 ;; (define-key slime-repl-mode-map (kbd "C-M-i") #'complete-symbol) 

 ;; (3) NOT USED Common Lisp : ac-slime

 (when nil
   (use-package auto-complete
     :config
     (setq-default ac-sources '(ac-source-abbrev ac-source-dictionary ac-source-words-in-same-mode-buffers))
     (add-hook 'auto-complete-mode-hook 'ac-common-setup)
     ;; (global-auto-complete-mode t)
     (add-to-list 'ac-modes 'lisp-mode)
     (setq ac-auto-start 2)
     (my-init--message-package-loaded "auto-complete"))

   (use-package ac-slime
     :after (slime auto-complete)
     :config
     (add-hook 'slime-mode-hook 'set-up-slime-ac)
     (add-hook 'slime-repl-mode-hook 'set-up-slime-ac)
     (eval-after-load "auto-complete"
       '(add-to-list 'ac-modes 'slime-repl-mode))
     (setq ac-auto-show-menu 0.3)
     (my-init--message-package-loaded "ac-slime")
     ;; (define-key ac-mode-map (kbd "C-M-i") 'ac-complete)
     )) ; end of when nil

 ;;; ===
 ;;; === (EL) Jump to REPL (IELM) and variants
 ;;; ===

 (defun my/toggle-ielm ()
   "If another window shows `*ielm*`, switch to it.
Otherwise, split vertically and start (or show) ielm in the other window."
   (interactive)
   (let* ((ielm-buffer (get-buffer "*ielm*"))
          (other-win (when (> (count-windows) 1)
                       (next-window))))
     (if (and other-win
              (eq (window-buffer other-win) ielm-buffer))
         ;; Case 1: ielm is already in the other window
         (other-window 1)
       ;; Case 2: no other window with ielm
       (unless (> (count-windows) 1)
         (split-window-right))
       (other-window 1)
       (if ielm-buffer
           (switch-to-buffer ielm-buffer)
         (ielm)))))

 (define-key emacs-lisp-mode-map (kbd "C-c C-z")  #'my/toggle-ielm)

 (defun my/ielm-insert-defun-name ()
   "Insert the name of the current defun into the *ielm* buffer."
   (interactive)
   (let ((defun-name (add-log-current-defun))
         (ielm-buffer (get-buffer "*ielm*")))
     (if (not defun-name)
         (message "Not inside a defun")
       (my/toggle-ielm)
       (goto-char (point-max))
       (insert "(")
       (insert defun-name)
       (insert ")"))))

 (define-key emacs-lisp-mode-map (kbd "C-c C-y")  #'my/ielm-insert-defun-name)

 (defun my/ielm-insert-defun-name-with-time-measurement ()
   "Insert the name of the current defun into the *ielm* buffer, with time measurement."
   (interactive)
   (let ((defun-name (add-log-current-defun))
         (ielm-buffer (get-buffer "*ielm*")))
     (if (not defun-name)
         (message "Not inside a defun")
       (my/toggle-ielm)
       (goto-char (point-max))
       (insert (format "(let ((start-time (current-time)))
  (prog1
      (%s)
    (print (format \"Elapsed: %s s\" (float-time (time-since start-time))))))" defun-name "%.06f")))))

 (define-key emacs-lisp-mode-map (kbd "C-c C-x")  #'my/ielm-insert-defun-name-with-time-measurement)

 (defun my/elisp-execute-defun ()
   "Execute the defun at point."
   (interactive)
   (save-excursion
     ;; Move to the beginning of the defun
     (beginning-of-defun)
     ;; Evaluate the defun
     ;; (eval-defun nil)
     ;; Get the function name by parsing the defun form
     (let ((func-name (save-excursion
                        (down-list)
                        (forward-sexp)
                        (skip-chars-forward " \t\n")
                        (thing-at-point 'symbol t))))
       (if func-name
           (progn
             (message "Executing: %s" func-name)
             ;; Execute the function interactively
             (call-interactively (intern func-name)))
         (error "Could not determine function name: %s" func-name)))))

 (define-key emacs-lisp-mode-map (kbd "C-c M-x")  #'my/elisp-execute-defun)

 ;; ===
 ;; === (CL) Slime, including arguments ala eldoc
 ;; ===      C-c C-x pour time monitoring

 (defun his-tracing-function (orig-fun &rest args)
   (message "fn called with args %S" args)
   (let ((res (apply orig-fun args)))
     (message "fn returned %S" res)
     res))

 (advice-add 'slime-retrieve-arglist :around #'his-tracing-function)

 (use-package slime
   ;; :defer nil

   :commands (slime slime-connect)
   
   :config
   
   (my-init--message-package-loaded "slime")
   
   (setq slime-contribs '(slime-cl-indent
                          slime-autodoc ; to propose arguments
                          slime-fancy
                          slime-asdf
                          slime-quicklisp
                          ))
   
   (setq inferior-lisp-program *inferior-lisp-program*)
   ;; --dynamic-space-size 2048" ; 1024 by default ; otherwis "sbcl --dynamic-space-size 2048" ; "nohup sbcl"?

   (when nil
     (setf asdf:*compile-file-warnings-behaviour* :error))
   ;; ... so that the compilation notes goes foreground
   ;; source : http://hectorhon.blogspot.com/2020/02/getting-compilation-output-of-asdfload.html
   
   ;; (setq slime-auto-connect 'ask)
   ;; Byte-compile warning:
   ;;    ‘slime-auto-connect’ is an obsolete variable (as of 2.5)
   ;;    use ‘slime-auto-start’ instead.
   (setq slime-auto-start 'ask)

   (when nil
     (setq slime-compilation-finished-hook 'slime-show-compilation-log)) ; end of when nil
   ;; see https://github.com/slime/slime/blob/master/slime.el

   ;; Removing the compilation error prompt
   ;; "If the Common Lisp implementation fails to compile the file,
   ;; SLIME will ask the user if they want to load the fasl file
   ;; (i.e. the compiled form of the file) anyway.
   ;; I cannot find a reason why one would want to load the ouput
   ;; of a file that failed to compile, and having to decline every time
   ;; is quite annoying."
   (setq slime-load-failed-fasl 'never)
   ;; see https://www.n16f.net/blog/slime-compilation-tips/

   ;; Custom command to execute a function in REPL surrounded by (time...)   
   ;; C-c C-x
   (defvar slime-repl-input-start-mark) ; to avoid compilation warning
   (declare-function slime-parse-toplevel-form "slime-parse.el") ; to avoid compilation warning
   (declare-function slime-switch-to-output-buffer "slime.el") ; to avoid compilation warning
   (declare-function slime-lisp-package "slime-repl.el") ; to avoid compilation warning
   (defun my/slime-call-defun--with-time-monitoring ()
     "Insert a call to the toplevel form defined around point into the REPL, surrounded by (time...).
Modified from official 'slime-call-defun'"
     (interactive)
     (cl-labels ((insert-call
                   (name &key (function t)
                         defclass)
                   (let* ((setf (and function
                                     (consp name)
                                     (= (length name) 2)
                                     (eql (car name) 'setf)))
                          (symbol (if setf
                                      (cadr name)
                                    name))
                          (qualified-symbol-name
                           (slime-qualify-cl-symbol-name symbol))
                          (symbol-name (slime-cl-symbol-name qualified-symbol-name))
                          (symbol-package (slime-cl-symbol-package
                                           qualified-symbol-name))
                          (call (if (cl-equalp (slime-lisp-package) symbol-package)
                                    symbol-name
                                  qualified-symbol-name)))
                     (slime-switch-to-output-buffer)
                     (goto-char slime-repl-input-start-mark)
                     (insert (if function
                                 "(time (" ; my modification
                               " "))
                     (when setf
                       (insert "setf ("))
                     (if defclass
                         (insert "make-instance '"))
                     (insert call)
                     (cond (setf
                            (insert " ")
                            (save-excursion (insert ") )")))
                           (function
                            (insert " ")
                            (save-excursion (insert "))")))) ; my modification
                     (unless function
                       (goto-char slime-repl-input-start-mark)))))
       (let ((toplevel (slime-parse-toplevel-form)))
         (if (symbolp toplevel)
             (error "Not in a function definition")
           (slime-dcase toplevel
             (((:defun :defgeneric :defmacro :define-compiler-macro) symbol)
              (insert-call symbol))
             ((:defmethod symbol &rest args)
              ;; (declare (ignore args))
              (insert-call symbol))
             (((:defparameter :defvar :defconstant) symbol)
              (insert-call symbol :function nil))
             (((:defclass) symbol)
              (insert-call symbol :defclass t))
             (t
              (error "Not in a function definition")))))))

   (define-key slime-mode-map (kbd "C-c C-x")  #'my/slime-call-defun--with-time-monitoring)

   ;; Custom command to test a function in REPL
   ;; C-c SPC
   
   (defun my/slime-test ()
     "Test the current test by sending to the REPL something similar to
(parachute:test 'toolbox-tests::floor-to-power-of-10-same-results-2)"
     (interactive)
     (cl-labels ((split-string-at-first-delimiter (s)
                   "Split string S at the first occurrence of either a space or a line return.
For instance: 'aa bb cc' --> ('aa' 'bb cc')
(v1, available in occisn/elisp-utils GitHub repository)"
                   (if (string-match "\\( \\|\n\\)" s)
                       (list (substring s 0 (match-beginning 0))
                             (substring s (match-end 0)))
                     (list s))))        ; end of labels definitions
       (let* ((all-toplevel-sexp (slime-defun-at-point))
              (toplevel-sexp-without-defxxx (cadr (split-string-at-first-delimiter all-toplevel-sexp)))
              (defun-name (car (split-string-at-first-delimiter toplevel-sexp-without-defxxx)))
              (package-name (substring (slime-current-package) 1 nil)) ; substring to delete initial ':'
              (cmd (concat "("
                           "parachute:test "
                           "'"
                           package-name
                           "-tests::test-"
                           defun-name
                           ")"
                           )))
         (slime-switch-to-output-buffer)
         (goto-char slime-repl-input-start-mark)
         (insert cmd))))

   (define-key slime-mode-map (kbd "C-c SPC")  #'my/slime-test)

   ) ; end of use-package slime

 ;; ===
 ;; === (EL+CL) paredit: structured editing of sexps;
 ;; ===                  parenthesis management       

 (use-package paredit
   :hook ((emacs-lisp-mode lisp-mode slime-repl-mode) . paredit-mode)
   :config
   (my-init--message-package-loaded "paredit"))
 ;; paredit animated documentation: http://danmidwood.com/content/2014/11/21/animated-paredit.html


 ;; check parens before saving:
 (add-hook 'emacs-lisp-mode-hook 
           (lambda () 
             (add-hook 'after-save-hook #'check-parens nil 'make-it-local)))
 (add-hook 'lisp-mode-hook 
           (lambda () 
             (add-hook 'after-save-hook #'check-parens nil 'make-it-local)))

 ;; Paren mode (by default since Emacs 28.1) + fix for echo of beginning of sexp:
 (show-paren-mode t)                    ; by default since Emac 28.1
 ;; video: https://web.archive.org/web/20121024123050/http://img8.imageshack.us/img8/9479/openparen.gif

 ;; problem: paredit disables paren-mode: (let ((show-paren-mode nil))
 ;; so we no longer have access to the echo in the mini-buffer
 ;; of the beginning of closing parentheses
 ;; we need to specifically launch this paren-mode function
 ;; from paredit:
 (defun my-echo-paren-matching-line-2 (orig-fun &rest args)
   "If a matching paren is off-screen, echo the matching line."
   (prog1 (apply orig-fun args)
     (when (char-equal (char-syntax (char-before (point))) ?\))
       (let ((_matching-text (blink-matching-open)))
         (when nil (message "hello")) ; to avoid compilation warning: ‘let’ with empty body
         ;; (when _matching-text
         ;;   (message _matching-text))
         ))))
 (advice-add 'paredit-blink-paren-match :around #'my-echo-paren-matching-line-2)
 ;; inspiration: https://stackoverflow.com/questions/13575554/display-line-of-matching-bracket-in-the-minibuffer

 ;; === 
 ;; === (CL) Paredit in REPL

 (add-hook 'slime-repl-mode-hook 'enable-paredit-mode)

 ;; Stop SLIME's REPL from grabbing DEL,
 ;; which is annoying when backspacing over a '('
 (defvar slime-repl-mode-map) ; to avoid compilation warning
 (defun override-slime-repl-bindings-with-paredit ()
   (define-key slime-repl-mode-map
               (read-kbd-macro paredit-backward-delete-key)
               nil))
 (add-hook 'slime-repl-mode-hook 'override-slime-repl-bindings-with-paredit)
 ;; source: https://wikemacs.org/wiki/Paredit-mode

 ;; ===
 ;; === Electric return to add a line when RETURN before )

 (dolist (mode '(emacs-lisp-mode-hook lisp-mode-hook))
   (add-hook mode
             (lambda ()
               
               (defvar electrify-return-match
                 "[\]}\)\"]"
                 "If this regexp matches the text after the cursor, do an \"electric\"
  return.")

               ;; we write again the function to add a line:
               (defun paredit-RET ()
                 "Default key binding for RET in Paredit Mode.
Normally, inserts a newline, like traditional Emacs RET.
With Electric Indent Mode enabled, inserts a newline and indents
  the new line, as well as any subexpressions of it on subsequent
  lines; see `paredit-newline' for details and examples."
                 (interactive)
                 (if (paredit-electric-indent-mode-p)
                     (progn
                       ;; (message "** paredit-electric-indent-mode-p = t")
                       (let ((electric-indent-mode nil))
                         (if (looking-at electrify-return-match)
                             (progn
                               ;; (message "** add one line")
                               (save-excursion (paredit-newline))))
                         (paredit-newline)))
                   (newline)))))) ; end of dolist

 ;; ===
 ;; === (EL) Evaluation : eval-defun (C-c C-c)and eval-buffer (C-c C-k)

 ;; C-c C-c to eval defun

 (add-hook 'emacs-lisp-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-c") 'eval-defun)))

 ;; C-c C-k to eval buffer

 (defun my-save-buffer-if-modified (&rest _args)
   "Propose to save the current buffer if it has been modified."
   (interactive)
   (when (and (buffer-file-name)
              (string-suffix-p ".el" (buffer-file-name))
              (buffer-modified-p))
     (if (y-or-n-p (format "Emacs Lisp buffer %s will be evaluated (eval-buffer), but has been modified; save it? " (buffer-name)))
         (save-buffer)
       (message "Buffer not saved"))))

 (advice-add 'eval-buffer :before #'my-save-buffer-if-modified)
 ;; to have similar behaviour with C-c C-k for Common Lisp
 
 (defun my-eval-buffer-advice2 (&rest _args)
   "Print a message when eval-buffer is called."
   (message "Buffer %s has been evaluated (eval-buffer)" 
            (buffer-name)))
 ;; (note: apparently, 'eval-buffer' is also called for the first
 ;; opening of an org-file in the session.)
 
 (advice-add 'eval-buffer :after #'my-eval-buffer-advice2)

 (define-key emacs-lisp-mode-map (kbd "C-c C-k") 'eval-buffer)

 ;; ===
 ;; === (EL) Byte-compilation (C-c C-b)

 (defun my/byte-compile-elisp ()
   "Delete .elc and .eln files if they exist and byte-compile current elisp buffer."
   (interactive)
   (let* ((el-file (buffer-file-name))
          (elc-file (concat el-file "c"))
          (eln-file (concat el-file "n")))
     
     ;; Delete .elc file if it exists
     (when (file-exists-p elc-file)
       (delete-file elc-file)
       (message "Deleted %s" elc-file))
     
     ;; Delete .eln file if it exists
     (when (file-exists-p eln-file)
       (delete-file eln-file)
       (message "Deleted %s" eln-file))

     ;; Clear *Compile-Log* buffer
     (let ((buf (get-buffer "*Compile-Log*")))
       (when buf
         (with-current-buffer buf
           (let ((inhibit-read-only t))
             (erase-buffer)))))
     
     ;; Compile
     (message "Byte-compiling %s..." el-file)
     (save-buffer)
     (byte-compile-file el-file)))

 ;; Bind it to C-c C-b only in emacs-lisp-mode
 (define-key emacs-lisp-mode-map (kbd "C-c C-b") 'my/byte-compile-elisp)
 ;; previous binding of C-c C-b: elisp-byte-compile-buffer

 ;; ===
 ;; === (EL) native compilation

 (defun my/native-compile-elisp ()
   "Delete .elc and .eln files if they exist and native-compile current elisp buffer."
   (interactive)

   (if (native-comp-available-p)
       (let* ((el-file (buffer-file-name))
              (elc-file (concat el-file "c"))
              (eln-file (concat el-file "n")))
         
         ;; Delete .elc file if it exists
         (when (file-exists-p elc-file)
           (delete-file elc-file)
           (message "Deleted %s" elc-file))
         
         ;; Delete .eln file if it exists
         (when (file-exists-p eln-file)
           (delete-file eln-file)
           (message "Deleted %s" eln-file))

         ;; Clear *Compile-Log* buffer
         (let ((buf (get-buffer "*Compile-Log*")))
           (when buf
             (with-current-buffer buf
               (let ((inhibit-read-only t))
                 (erase-buffer)))))
         
         ;; Compile
         (message "Native-compiling %s..." el-file)
         (save-buffer)
         (native-compile el-file)) ; end of 'then'
     
     (message "Native compilation not available.")))


 ;; Bind it to C-c C-n only in emacs-lisp-mode
 (define-key emacs-lisp-mode-map (kbd "C-c C-n") 'my/native-compile-elisp)
 
 ;; ===
 ;; === (EL) Documentation

 (when nil
   (use-package suggest
     ;; :mode ("\\.el\\'" . emacs-lisp-mode)
     :commands suggest
     :config (my-init--message-package-loaded "suggest")))

 ;; ===
 ;; === (EL) Propose function arguments: eldoc

 ;; EL : by default
 ;; CL : slime-autodoc

 ;; ===
 ;; === (EL) Goto defun

 (use-package elisp-slime-nav
   :defer t
   ;; :mode ("\\.el\\'" . emacs-lisp-mode)
   ;; :demand t ; to force
   :hook ((emacs-lisp-mode ielm-mode slime-repl-mode) . elisp-slime-nav-mode)
   :config 
   ;;(dolist (hook '(emacs-lisp-mode-hook ielm-mode-hook))
   ;;  (add-hook hook 'elisp-slime-nav-mode))
   (my-init--message-package-loaded "elisp-slime-nav"))
 ;; source: http://emacsredux.com/blog/2014/06/18/quickly-find-emacs-lisp-sources/
 ;; this enables M-. and M-, as in Slime for Common Lisp
 ;; --
 ;; This package provides Slime's convenient "M-." and "M-," navigation
 ;; in `emacs-lisp-mode', together with an elisp equivalent of
 ;; `slime-describe-symbol', bound by default to `C-c C-d d`.
 ;;
 ;;   When navigating into Emacs' C source, "M-," will not be bound to
 ;;   the same command, but "M-*" will typically do the trick.


 ;; ===
 ;; === (EL+CL) Find defun: imenu

 (add-hook 'emacs-lisp-mode-hook #'imenu-add-menubar-index)
 (add-hook 'lisp-mode-hook #'imenu-add-menubar-index)

 ;; ===
 ;; === (EL+CL) Find defun: imenu-list (sidebar)

 (use-package imenu-list
   :bind ((:map c-mode-map
                ("C-'" . imenu-list-smart-toggle))
          (:map c-ts-mode-map
                ("C-'" . imenu-list-smart-toggle))
          (:map lisp-mode-map
                ("C-'" . imenu-list-smart-toggle))
          (:map emacs-lisp-mode-map
                ("C-'" . imenu-list-smart-toggle)))
   :config
   (my-init--message-package-loaded "imenu-list"))

 ;; ===
 ;; === (EL+CL) Outline

 (add-hook 'emacs-lisp-mode-hook 
           (lambda ()
             (setq outline-regexp ";; === ")
             (outline-minor-mode)))
 (add-hook 'lisp-mode-hook 
           (lambda ()
             (setq outline-regexp ";; === ")
             (outline-minor-mode)))

 ;; ===
 ;; === (EL) Emacs C sources

 (if (my-init--directory-exists-p *emacs-c-source*)
     (setq find-function-C-source-directory (my-init--replace-linux-slash-with-two-windows-slashes *emacs-c-source*))
   (my-init--warning "!! Emacs C sources directory is not valid: %s" *emacs-c-source*))
 ;; sources downloaded from https://ftp.gnu.org/pub/gnu/emacs/
 ;; or rather: http://git.savannah.gnu.org/cgit/emacs.git

 ;; example of use: M-. on (defmacro

 ;; ===
 ;; === (EL) Macro expander

 ;; (1) macro expander 1 for Emacs Lisp

 (use-package macrostep
   :bind (:map emacs-lisp-mode-map ("C-c e" . macrostep-expand))
   :config (my-init--message-package-loaded "macrostep"))

 ;; (2) macro expander 2 for Emacs Lisp

 ;; source: https://github.com/marcoheisig/.emacs.d
 ;; The language Emacs Lisp is a fine blend of Maclisp, Common Lisp and some language for editing text. Unsurprisingly Emacs is well suited for editing Emacs Lisp. The only worthwhile addition provided here is a simple Macro stepper called `macroexpand-point’.

 (define-derived-mode emacs-lisp-macroexpand-mode emacs-lisp-mode
   "Macro Expansion"
   "Major mode for displaying Emacs Lisp macro expansions."
   (setf buffer-read-only t))

 (define-key emacs-lisp-mode-map
             (kbd "C-c m") 'macroexpand-point)

 (defun macroexpand-point (arg)
   "Apply `macroexpand' to the S-expression at point and show
the result in a temporary buffer. If already in such a buffer,
expand the expression in place.

With a prefix argument, perform `macroexpand-all' instead."
   (interactive "P")
   (let ((bufname "*emacs-lisp-macroexpansion*")
         (bounds (bounds-of-thing-at-point 'sexp))
         (expand (if arg #'macroexpand-all #'macroexpand)))
     (unless bounds
       (error "No S-expression at point."))
     (let* ((beg (car bounds))
            (end (cdr bounds))
            (expansion
             (funcall expand
                      (first
                       (read-from-string
                        (buffer-substring beg end))))))
       (if (eq major-mode 'emacs-lisp-macroexpand-mode)
           (let ((inhibit-read-only t)
                 (full-sexp
                  (car (read-from-string
                        (concat
                         (buffer-substring (point-min) beg)
                         (prin1-to-string expansion)
                         (buffer-substring end (point-max)))))))
             (delete-region (point-min) (point-max))
             (save-excursion
               (pp full-sexp (current-buffer)))
             (goto-char beg))
         (let ((temp-buffer-show-hook '(emacs-lisp-macroexpand-mode)))
           (with-output-to-temp-buffer bufname
             (pp expansion)))))))


 ;; ===
 ;; === (CL) Navigate between source and test files

 (defun my/switch-between-src-and-tests ()
   "When in code buffer, switch between src and test files."
   (interactive)
   (let* ((buffer-file-name1 (buffer-file-name)) ; c:/.../abc.lisp
          (directory (file-name-directory buffer-file-name1))
          (file-name (file-name-nondirectory buffer-file-name1)) ; abc.lisp
          (file-name-base1 (file-name-base buffer-file-name1)) ; abc
          (len (length file-name-base1))
          (test-file-p
           (and (> len 6)
                (string= "-tests" (substring file-name-base1 (- len 6) (- len 0)))))
          (target
           (if test-file-p
               (concat directory "../src/" (substring file-name-base1 0 (- len 6)) ".lisp")
             (concat directory "../tests/" file-name-base1 "-tests.lisp"))))
     (if (file-exists-p target)
         (progn
           (message "Switching to %s file" (if test-file-p "source" "test"))
           (find-file target))
       (message "No %s file for %s" (if test-file-p "source" "test") file-name))))

 (defun my/go-to-asd ()
   "Open unique .asd file in parent directory."
   (interactive)
   (let* ((directory (file-name-directory (buffer-file-name)))
          (asd-files (directory-files (concat directory "../") nil "\\.asd$")))
     (when (null asd-files) (error "No .asd file in parent directory"))
     (if (> (length asd-files) 1)
         (progn
           (message "More than one .asd file in parent directory, jumping to directory")
           (dired (concat directory "../")))
       (progn
         (message "Opening asd file")
         (find-file (concat directory "../" (car asd-files)))))))

 (defun my/go-to-package ()
   "Open unique package file in the parent directory."
   (interactive)
   (let* ((current-dir (file-name-directory (buffer-file-name)))
          (parent-dir  (file-name-directory
                        (directory-file-name current-dir)))
          (package-files (directory-files parent-dir nil "^package")))
     (when (null package-files)
       (error "No package file in parent directory"))
     (when (> (length package-files) 1)
       (error "More than one package file in parent directory"))
     (find-file (expand-file-name (car package-files) parent-dir))))

 ;; ===
 ;; === (CL) delete fasl files

 (defun my/delete-fasl-files ()
   "Delete all FASL files in the current dired directory.
(v1 as of 2025-10-31)"
   (interactive)
   (let ((files (directory-files default-directory t "\\.\\(fasl\\|fasl\\)$")))
     (if files
         (progn
           (dolist (file files)
             (delete-file file))
           (revert-buffer)
           (message "Deleted %d fasl file(s)" (length files)))
       (message "No fasl file identfied."))))

 ;; ===
 ;; === (CL) show to *slime-compilation* buffer

 (defun my/jump-to-slime-compilation ()
   "Jump to *slime-compilation* buffer in other window if it exists, otherwise show error. (2025-11-02)"
   (interactive)
   (let ((buffer (get-buffer "*slime-compilation*")))
     (if buffer
         (switch-to-buffer-other-window buffer)
       (message "Buffer *slime-compilation* does not exist"))))

 ;; ===
 ;; === (CL) filter compilation report

 (defun my/slime-compilation-delete-float-coercion-notes ()
   "Remove sections containing 'float to pointer coercion' from *slime-compilation* buffer.
(v1 as of 2025-11-01)"
   (interactive)
   (with-current-buffer "*slime-compilation*"
     (let ((inhibit-read-only t)
           (filter-string "float to pointer coercion")
           (nb-deletions 0))
       (save-excursion
         (goto-char (point-min))
         (while (re-search-forward (regexp-quote filter-string) nil t)
           (setq nb-deletions (1+ nb-deletions))
           ;; Find the start of this warning/note section
           (let ((end (line-end-position)))
             (beginning-of-line)
             ;; Search backward for the section start (typically a blank line or buffer start)
             (while (and (not (bobp))
                         (not (looking-at "^$"))
                         (looking-at "^[; ]"))
               (forward-line -1))
             (when (looking-at "^$")
               (forward-line 1))
             (let ((start (point)))
               ;; Search forward for section end (blank line or end of buffer)
               (goto-char end)
               (while (and (not (eobp))
                           (not (looking-at "^$")))
                 (forward-line 1))
               (delete-region start (point))))))
       (beginning-of-buffer)
       (cond ((= 0 nb-deletions)
              (message "No deletion performed."))
             ((= 1 nb-deletions)
              (message "1 deletion performed."))
             (t
              (message "%s deletions performed" nb-deletions))))))

 ;; ===
 ;; === (CL) ASDF

 (defun my/asdf-system-name-from-buffer ()
   "Return the ASDF system name associated with the current buffer (file or dired).
Ignores any .asd files whose names contain 'test' (case-insensitive).
Return NIL if no system found.
(v1, as of 2025-11-02)"
   (interactive)
   (let* ((start-dir
           (cond
            ((derived-mode-p 'dired-mode)
             (dired-current-directory))
            ((buffer-file-name)
             (file-name-directory (buffer-file-name)))
            (t nil)))
          (asdf-system-name nil))
     (when start-dir
       (when-let* ((dir
                    (locate-dominating-file
                     start-dir
                     (lambda (d)
                       (seq-some
                        (lambda (f)
                          (and (string-match-p "\\.asd\\'" f)
                               (let ((case-fold-search t))
                                 (not (string-match-p "test" f)))))
                        (directory-files d))))))
         (when-let ((asd
                     (car (seq-filter
                           (lambda (f)
                             (and (string-match-p "\\.asd\\'" f)
                                  (let ((case-fold-search t))
                                    (not (string-match-p "test" f)))))
                           (directory-files dir t)))))
           
           (setq asdf-system-name (file-name-base asd)))))
     asdf-system-name))

 (defun my/asdf-force-reload-system-corresponding-to-current-buffer ()
   "Force reload current ASDF system.
(v1, as of 2025-11-02)"
   (interactive)
   (let ((asdf-system-name (my/asdf-system-name-from-buffer)))
     (if (null asdf-system-name)
         (message "No ASDF system found.")
       (slime-eval-async `(asdf:load-system ,asdf-system-name :force t)
         (lambda (_result)
           (message "System %s has been force-reloaded" asdf-system-name))))))

 (defun my/asdf-force-test-system-corresponding-to-current-buffer ()
   "Force test current ASDF system.
(v1, as of 2025-11-02)
"
   (interactive)
   (let ((asdf-system-name (my/asdf-system-name-from-buffer)))
     (if (null asdf-system-name)
         (message "No ASDF system found.")
       (slime-eval-async `(asdf:test-system ,asdf-system-name :force t)
         (lambda (_result)
           (message "System %s has been force-tested" asdf-system-name))))))

 ;; ===
 ;; === my/dired-clean-build-artifacts

 (defun my/delete-to-recycle-bin (file)
   "Move FILE to Windows Recycle Bin using PowerShell.
Returns t on success, nil on failure.
Note: (setq delete-by-moving-to-trash t) does not seem enough.
(v1, available in occisn/emacs-utils GitHub repository, 2025-12-27)"
   (let* ((file-path (convert-standard-filename file))
          (ps-command (format 
                       "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('%s', 'OnlyErrorDialogs', 'SendToRecycleBin')"
                       file-path)))
     (condition-case err
         (progn
           (call-process "powershell.exe" nil nil nil
                         "-NoProfile" "-NonInteractive" "-Command" ps-command)
           (not (file-exists-p file)))
       (error nil))))


 (defun dired-clean--find-files-recursively (dir extensions exceptions)
   "Recursively find files with EXTENSIONS in DIR, excluding EXCEPTIONS.
Returns a flat list of matching files."
   (let ((result '()))
     (dolist (file (directory-files dir t))
       (let ((basename (file-name-nondirectory file)))
         (unless (member basename '("." ".."))
           (cond
            ;; If it's a directory, recurse into it
            ((file-directory-p file)
             (setq result (append (dired-clean--find-files-recursively file extensions exceptions) result)))
            
            ;; If it's a regular file matching our criteria
            ((and (file-regular-p file)
                  (member (file-name-extension file) extensions)
                  (not (member basename exceptions)))
             (push file result))))))
     result))

 (defun dired-clean--get-immediate-subdir (file root-dir)
   "Get the immediate subdirectory of ROOT-DIR that contains FILE.
Returns the immediate subdirectory path, or nil if FILE is directly in ROOT-DIR."
   (let* ((relative (file-relative-name file root-dir))
          (parts (split-string relative "/")))
     (when (> (length parts) 1)
       (expand-file-name (car parts) root-dir))))

 (defun my/dired-clean-build-artifacts ()
   "Delete .o, .fasl, and .exe files recursively in subdirectories.
EXCEPTIONS are defined within the function.
Files are moved to Windows Recycle Bin.
Results are grouped by immediate subdirectory."
   (interactive)
   (let* ((dir (dired-current-directory))
          (extensions '("o" "fasl" "exe"))
          (exception-list '("cloc-2.06.exe" "scc.exe"))
          (deleted-files '())
          (failed-files '())
          (buffer-name "*Deleted Build Artifacts*"))
     
     ;; Validate we're in a dired buffer
     (unless (derived-mode-p 'dired-mode)
       (error "This command must be run from a dired buffer"))
     
     (message "Recursively scanning directories and moving files to Recycle Bin...")
     
     ;; Find all matching files recursively
     (let ((all-files (dired-clean--find-files-recursively dir extensions exception-list)))
       
       ;; Try to delete each file and group by immediate subdirectory
       (dolist (file all-files)
         (let ((immediate-subdir (dired-clean--get-immediate-subdir file dir)))
           (when immediate-subdir
             (if (my/delete-to-recycle-bin file)
                 (let ((existing (assoc immediate-subdir deleted-files)))
                   (if existing
                       (setcdr existing (cons file (cdr existing)))
                     (push (cons immediate-subdir (list file)) deleted-files)))
               (push file failed-files))))))
     
     ;; Display results
     (with-current-buffer (get-buffer-create buffer-name)
       (erase-buffer)
       (insert (format "Build Artifacts Cleanup Report\n"))
       (insert (format "Directory: %s\n" dir))
       (insert (format "Search: Recursive (grouped by immediate subdirectory)\n"))
       (insert (format "Time: %s\n" (current-time-string)))
       (insert (make-string 70 ?=) "\n\n")
       
       (if deleted-files
           (progn
             (insert (format "Successfully moved to Recycle Bin (%d files from %d subdirectories):\n\n"
                             (apply #'+ (mapcar (lambda (x) (length (cdr x))) deleted-files))
                             (length deleted-files)))
             (dolist (subdir-entry (sort deleted-files 
                                         (lambda (a b) (string< (car a) (car b)))))
               (let* ((subdir (car subdir-entry))
                      (files (cdr subdir-entry))
                      (subdir-name (file-name-nondirectory (directory-file-name subdir))))
                 (insert (format "\n%s/ (%d files):\n" subdir-name (length files)))
                 (dolist (file (sort files #'string<))
                   (let ((relative (file-relative-name file dir)))
                     (insert (format "  ✓ %s\n" relative)))))))
         (insert "No build artifact files found to delete.\n\n"))
       
       (when failed-files
         (insert (format "\n\nFailed to move (%d files):\n" (length failed-files)))
         (dolist (file failed-files)
           (insert (format "  ✗ %s\n" (file-relative-name file dir)))))
       
       (goto-char (point-min))
       (display-buffer (current-buffer)))
     
     (if deleted-files
         (message "Moved %d files to Recycle Bin from %d immediate subdirectories. Check Recycle Bin!"
                  (apply #'+ (mapcar (lambda (x) (length (cdr x))) deleted-files))
                  (length deleted-files))
       (message "No build artifact files found to delete"))))

 ;; ===
 ;; === abbrev

 (dolist (hook '(lisp-mode-hook
                 emacs-lisp-mode-hook))
   (add-hook hook #'abbrev-mode))

 ;; ===
 ;; === sidebar

 ;; speedbar
 ;; alternative to speedbar: treemacs, neotree, dired-sidebar

 ;; ===
 ;; === tests

 ;; Emacs Lisp : ERT

 ;; ===
 ;; === project management

 ;; including find, grep, search & replace --> see projectile

 ;; ===
 ;; === find usage of a function

 ;; ...
 
 ;; ===
 ;; === debugger

 ;; ...
 
 ;; ===
 ;; === profiler

 ;; ...

 ;; ===
 ;; === Hydra compilation

 (defhydra hydra-compilation (:exit t :hint nil)
   "
^Compilation hydra:
^------------------

M-n, M-p to navigate

RET to follow link

_f_ilter 'float to pointer coercion' notes

{end}
"

   ("f" #'my/slime-compilation-delete-float-coercion-notes))

 ;; ===
 ;; === Hydra Emacs Lisp

 (defhydra hydra-emacs-lisp (:exit t :hint nil)
   "
^Emacs Lisp hydra:
^-----------------
FILES: n/a
MOVEMENT:
   Navigate top-level sexp : C-UP and C-DOWN to move within top-level sexps
                             C-M-a/e to move to beginning/end of current or preceding defun (beginning-of-defun, end-of-defun)
   Navigate sexp: M-LEFT ou -RIGHT navigate
                  C-M-f/b          navigate among sexp siblings
                  C-M-up           go to beginning of (...) or higher one
                  C-M-f            go to closing parenthesis
                  C-M-down         go to inner (...)
JUMP TO TOP-LEVEL EXP: _m_: i_m_enu || M-x occur (M-s o) || _c_ : my occur || C-' (list in sidebar)
SELECT: C-= to expand region (expand-region) || C-M-h to put region around whole current or following defun (mark-defun)
MANIPULATE EXP: M-(              wrap an sexp (paredit)
                M-UP             splice (remove delimiter of current sexp) and kill previous
                M-r              raise and delete siblings
                M-s              splice (remove delimiter of current sexp)
                C-q ) or C-u DEL force add/delete parenthesis
                C-LEFT or C-}    barf out (force a closing parenthesis) ; (a b|c d e f) --> (a b) c d e f
                C-RIGHT or C-)   slurp in next sexp (paredit) ; (a b|c) d --> (a b c d)
                C-M-t            transpose sexps or make them circulate
COLLAPSE: [Outline: _o_utline-hide-body vs outline-show-_a_ll ; collapse/expand: _h_ide vs _s_how]
MACROS: Macro expander: C-c m ou C-c e || q
INDENT: C-M-q on current sexp || _i_: _i_ndent-buffer (M-x my/indent-lisp-buffer)
COMMENT: region M-; to comment/uncomment (paredit)
DOCUMENTATION: 'C-h i m elisp' or 'C-h r TAB ENT' elisp manual, then 'i' for index -- 'or M-x elisp-index-search'
               'M-x info-apropos' search in all info documents || M-x elisp-index-search
               C-h f {incl. under cursor}, C-h v, C-h S (symbol in doc), M-x suggest
REFERENCES: M-. and M-, to navigate to definition and come back (elisp-slime-nav)
            [who calls, etc.]
ABBREV: M-x unexpand-abbrev
COMPLETE: C-: counsel-company (mini-buffer)
          C-M-i company-complete (at point) ; C-d to see doc ; M-. to jump to source ; q to come back
REFACTOR: [...]
EXECUTE: 
   Eval: C-M-x to eval defun (M-x eval-defun) || C-x C-e to eval last sexp || C-c C-k = M-x eval-buffer
   REPL (IELM): C-c C-z (jump to REPL) | C-c C-y (send function to REPL) | C-c C-x (idem with time measurement) | C-c M-x to execute (M-x)
DEBUG: (1) unexpected : c(ontinue), e(val), q(uit) (2) edebug: C-u C-M-x --> SPACE, h, f, o i, ? (3) (debug) within code
{end}"
   ("a" #'outline-show-all)
   ("c" #'my-elisp-occur)
   ("h" #'hs-hide-all)
   ("i" #'my/indent-lisp-buffer)
   ("m" #'imenu)
   ("o" #'outline-hide-body)
   ("s" #'hs-show-all)
   ("t" #'hs-toggle-hiding))

 ;; ===
 ;; === Hydra Common Lisp

 (defhydra hydra-common-lisp (:exit t :hint nil)
   "
^Common Lisp hydra:
^------------------
FILES: _s_witch between src and tests | go to _a_sd | go to _p_ackage
MOVEMENT:
   Navigate top-level sexp : C-UP and C-DOWN to move within top-level sexps
                             C-M-a/e to move to beginning/end of current or preceding defun (beginning-of-defun, end-of-defun)
   Navigate sexp: M-LEFT ou -RIGHT navigate
                  C-M-f/b          navigate among sexp siblings
                  C-M-up           go to beginning of (...) or higher one
                  C-M-f            go to closing parenthesis
                  C-M-down         go to inner (...)
JUMP TO TOP-LEVEL EXP: _m_: i_m_enu || M-x occur (M-s o) ||  _c_ : my occur || C-' (list in sidebar) 
SELECT: C-= to expand region (expand-region) || C-M-h to put region around whole current or following defun (mark-defun)
MANIPULATE EXP: M-(              wrap an sexp (paredit)
                M-UP             splice (remove delimiter of current sexp) and kill previous
                M-r              raise and delete siblings
                M-s              splice (remove delimiter of current sexp)
                C-q ) ou C-u DEL force add/delete parenthesis
                C-LEFT or C-}    barf out (force closing parenthesis) ; (a b|c d e f) --> (a b) c d e f
                C-RIGHT or C-)   slurp in next sexp (paredit) ; (a b|c) d --> (a b c d)
                C-M-t            transpose sexps or make them circulate
COLLAPSE: _o_utline-hide-body vs outline-show-all ; collapse/expand: _h_ide vs hs-show-all | hs-toggle-hiding
MACROS: Macro expander: C-c RETURN || C-c C-m || C-c M-m to fully expand
INDENT: C-M-q on current sexp || _i_: _i_ndent-buffer (M-x my/indent-lisp-buffer)
COMMENT: region M-; to comment/uncomment (paredit)
DOCUMENTATION: docstring global var: C-c C-d d, (describe var) || fields (inspect var), q || hyperspec C-c C-d h || (apropos 'ts-get') || C-h m [l to go back]
REFERENCES: M-. and M-, to navigate to definition and come back
            who calls a fn : C-c < ; who is called C-c > ; who refers global var C-c C-w r 
ABBREV: M-x unexpand-abbrev
COMPLETE: C-:     counsel-company (mini-buffer)
          C-M-i   company-complete, replacing complete-symbol ; C-d to see doc ; M-. to jump to source ; q to come back
          C-c M-i  fuzzy   ||   C-c TAB completion at point
REFACTOR: [projectile]
EXECUTE: 
   Eval: C-c C-c compile defun || C-M-x eval defun || C-x C-e to eval last sexp || C-c C-k || C-c C-y to send to REPL || C-c C-x idem with (time...)
   REPL: C-c C-z to jump in REPL || C-c C-j to execute in REPL || M-n || M-p || *,** || /,// || (foo M-
   ASDF : _f_l force load | _f_t force test           |  M-x slime-compile-system (compiles an ASDF system)
   Test in REPL: C-c SPC || _j_ump to slime compilation report || delete fasl (from dired): M-x my/delete-fasl-files
   Clear screen: C-c M-o              ||   q to hide compilation window
DEBUG: Debug: q || v to jump into code, RETURN, M-., i, e, r
       Disassemble : C-c M-d | Inspect : C-c I 'foo ; l to go back   | Trace: C-c C-t on the symbol | Navigate within warnings/errors: M-n, M-p
CLEAN: my/dired-clean-build-artifacts
SPECIFIC: Slime: _e_ : slime || M-x slime || ,quit
{end}"
   ("a" #'my/go-to-asd)
   ("c" #'my-cl-occur)
   ("e" #'slime)
   ("f" (lambda () 
          (interactive)
          (let ((key (read-char "l (force-reload) or t (force-test): ")))
            (cond 
             ((eq key ?l) (my/asdf-force-reload-system-corresponding-to-current-buffer))
             ((eq key ?t) (my/asdf-force-test-system-corresponding-to-current-buffer)))))
    "submenu f")
   ("h" #'hs-hide-all)
   ("i" #'my/indent-lisp-buffer)
   ("j" #'my/jump-to-slime-compilation)
   ("m" #'imenu)
   ("o" #'outline-hide-body)
   ("p" #'my/go-to-package)
   ("s" #'my/switch-between-src-and-tests))            ; end of hydra

 ;; ===
 ;; === Hydra REPL

 (defhydra hydra-slime-repl (:exit t :hint nil)
   "
^Common Lisp Slime REPL hydra:
^-----------------------------

C-j to start a new line

M-p : previous command

to come back to last prompt: M-> (with shift), which jumps to the end of buffer

,restart-inferior-lisp

(end)"
   ;; ("e" #'a-function)
   ) 
 
 ) ; end of init section


;;; ===
;;; ================
;;; ===== IELM =====
;;; ================

(my-init--with-duration-measured-section 
 t
 "IELM"

 ;; ~M-x ielm~

 ;; about IELM : https://www.reddit.com/r/lisp/comments/mz94vu/whats_the_value_in_using_a_repl_for_elisp/

 ;; ielm = i(nteractif) el(isp)m(ode)

 (when nil
   (defun ielm-auto-complete ()
     "Enables `auto-complete' support in \\[ielm]."
     (setq ac-sources '(ac-source-functions
                        ac-source-variables
                        ac-source-features
                        ac-source-symbols
                        ac-source-words-in-same-mode-buffers))
     (add-to-list 'ac-modes 'inferior-emacs-lisp-mode)
     (auto-complete-mode 1)
     (add-hook 'ielm-mode-hook 'ielm-auto-complete)))

 ;; https://www.masteringemacs.org/article/evaluating-elisp-emacs

 (defhydra hydra-ielm (:exit t :hint nil)
   "
^IELM hydra:
^-----------
RET to insert newline or evaluate
M-RET to evaluate without printing
TAB [ielm-tab] || C-M-i to complete
M-p to access previous command
*, **, *** to access previous results
C-c C-b to define current working buffer
"
   )) ; end of init section


;;; ===
;;; ===============
;;; ===== CSV =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "CSV"

 (use-package csv-mode
   :mode ("\\.[Cc][Ss][Vv]\\'" . csv-mode)
   :config
   ;; (setq csv-separators '("," ";" "|" " "))
   (setq csv-separators (append '(";") csv-separators))
   (my-init--message-package-loaded "csv-mode")
   
   ;; C-c C-M-a: align only visible part
   (add-hook 'csv-mode-hook
             (lambda ()
               "source: https://stackoverflow.com/questions/10616525/is-there-a-good-emacs-mode-for-displaying-and-editing-huge-delimiter-separated-f"
               (define-key csv-mode-map (kbd "C-c C-M-a")
                           (defun csv-align-visible (&optional _arg)
                             "Align visible fields"
                             (interactive "P")
                             (csv-align-fields nil (window-start) (window-end)))))))

 (defhydra hydra-csv (:exit t :hint nil)
   "
^CSV hydra:
^----------

C-c C-s (csv-sort-fields)         sorts lexicographically on a specified filed or column
C-c C-n (csv-sort-numeric-fields) sorts numerically on a specified filed or column
C-c C-r (csv-reverse-region)      reverses the order
C-c C-a (csv-align-fields)        aligns fields into columns and C-c C-u (csv-unalign-fields) undoes such alignment
C-c C-t (csv-transpose)           interchanges rows and columns.

C-c C-M-a align only visible part
(end)"
   ;; ("e" #'a-function)
   ) ; end of hydra
 
 ) ; end of init section


;;; ===
;;; =======================
;;; ===== SUMATRA PDF =====
;;; =======================

(my-init--with-duration-measured-section 
 t
 "Sumatra PDF"

 (setq *pdf-viewer-program* nil)

 (if (my-init--file-exists-p *sumatra-program*)
     (setq *pdf-viewer-program*
           (list (list
                  "Sumatra PDF"
                  (concat "\"" *sumatra-program* "\" -reuse-instance %o"))))
   (my-init--warning "!! *sumatra-program* is nil or does not exist: %s" *sumatra-program*))

 (when (null *pdf-viewer-program*)
   (my-init--warning "!! *pdf-viewer-program* is nil: %s" *pdf-viewer-program*))
 
 (defun my/open-with-Sumatra ()
   "Open the current file or dired marked files in Sumatra.
To be called from hydra."
   (interactive)
   (unless (my-init--file-exists-p *sumatra-program*)
     (error "Impossible to launch Sumatra since program path not known: %s" *sumatra-program*))
   (my-init--open-with-external-program
    "Sumatra"
    (lambda (file-name)
      (concat "\"" *sumatra-program* "\"" " -reuse-instance " "\"" file-name "\""))))

 ) ; end of init section


;;; ===
;;; =================
;;; ===== LATEX =====
;;; =================

(my-init--with-duration-measured-section 
 t
 "LaTeX"

 ;; Sumatra: see above

 (if (my-init--directory-exists-p *miktex-directory*)
     (my-init--add-to-path "MiKTeX" *miktex-directory*)
   (my-init--warning "!! *miktex-directory* is nil or does not exist: %s" *miktex-directory*))

 
 ;; also below, but does not seem to work, at least after the installation of a more recent version of Emacs

 (unless (my-init--directory-exists-p *latex-preview-pics-directory*)
   (my-init--warning "!! *latex-preview-pics-directory* is nil or does not exist: %s" *latex-preview-pics-directory*))

 ;; coding system (1/2):
 (setq previous-coding-system-for-read coding-system-for-read)
 (setq coding-system-for-read nil) ; otherwise problem in auctex installation

 (use-package tex ;; le package 'auctex' utilise des noms de fichiers en tex-...
   :mode ("\\.tex\\'" . latex-mode)     ; new as of 2023-08-15
   ;; :mode ("\\.tex\\'" . plain-tex-mode)
   :ensure auctex
   :config (my-init--message-package-loaded "tex")
   ) ; end of tex use-package

 (when (null *pdf-viewer-program*)
   (my-init--warning "!! *pdf-viewer-program* is nil: %s" *pdf-viewer-program*))
 
 (use-package latex 
   :ensure auctex
   :mode ("\\.tex\\'" . latex-mode)
   ;; :mode ("\\.tex\\'" . plain-tex-mode)
   ;; :mode ( "\\.(la)?tex\\'" . latex-mode )
   :config
   (my-init--message-package-loaded "latex")
   (setq TeX-save-query nil)            ; autosave before compiling
   (setq TeX-error-overview-open-after-TeX-run t) ; errors and warnings overview
   ;; (setq TeX-auto-save t)
   ;; (setq TeX-parse-self t)
   (setq TeX-PDF-mode t)                ; PDF output by default
   (setq TeX-view-program-list *pdf-viewer-program*) ; Sumatra as PDF viewer
   (setq TeX-view-program-selection
         '(((output-dvi style-pstricks) "dvips and start")
           (output-dvi "Yap")
           (output-pdf "Sumatra PDF")
           (output-html "start")))
   ;; RefTeX:
   (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
   (setq reftex-plug-into-auctex t)
   ;; to allow preview on dark background:
   (when (my-init--dark-background-p)
     (custom-set-faces 
      '(preview-reference-face ((t (:background "#ebdbb2" :foreground "black"))))))) ; end of latex use-package

 ;; coding system (2/2):
 (setq coding-system-for-read previous-coding-system-for-read)

 (defun my-tex-occur ()
   (interactive)
   (occur "^% ===\\|^\\\\def\\\\")
   (other-window 1))

 (defun my-latex-occur ()
   (interactive)
   (occur "^% \\*\\*\\*")
   (other-window 1))

 ;; babel for LaTeX:
 (defun my--org-babel-load-latex (&rest _args)
   (message "Preparing org-mode babel for latex...")
   (add-to-list 'org-babel-load-languages '(latex . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-latex))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-latex)
 
 (setq org-latex-pdf-process
       '("pdflatex -interaction nonstopmode -output-directory %o %f"))
 
 (defhydra hydra-tex (:exit t :hint nil)
   "
^Tex hydra:
^------------
c : occur
"
   ("c" #'my-tex-occur))

 (defhydra hydra-latex (:exit t :hint nil)
   "
^LaTeX hydra:
^------------
c : occur
"
   ("c" #'my-latex-occur))
 
 ) ; end of init section


;;; ===
;;; ===================
;;; ===== GNUPLOT =====
;;; ===================

(my-init--with-duration-measured-section 
 t
 "Gnuplot"

 (unless (my-init--directory-exists-p *gnuplot-directory*)
   (my-init--warning "!! *gnuplot-directory* is nil or does not exist: %s" *gnuplot-directory*))

 (unless (my-init--file-exists-p *gnuplot-program*)
   (my-init--warning "!! *gnuplot-program* is nil or does not exist: %s" *gnuplot-program*))
 
 (use-package gnuplot-mode
   :mode ("\\.[Gg][Pp]\\'" . gnuplot-mode)
   :requires 'gnuplot
   :init
   (setq gnuplot-program *gnuplot-program*)
   (my-init--add-to-path-and-exec-path "Gnuplot" *gnuplot-directory*)
   :config
   (my-init--message-package-loaded "gnuplot-mode")
   ;; (setq auto-mode-alist 
   ;;   (append '(("\\.\\(gp\\|gnuplot\\)$" . gnuplot-mode)) auto-mode-alist))
   )

 ;; babel for Gnuplot:
 (defun my--org-babel-load-gnuplot (&rest _args)
   (message "Preparing org-mode babel for gnuplot...")
   (add-to-list 'org-babel-load-languages '(gnuplot . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-gnuplot))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-gnuplot)

 ;; ... and Gnuplot package shall be installed
 ;; inspiration: https://emacs.stackexchange.com/questions/59517/org-plot-with-gnuplot-searching-for-program-no-such-file-or-direcotry-aspell 

 (defhydra hydra-gnuplot (:exit t :hint nil)
   "
^Gnuplot hydra:
^--------------

You can run the plot command either directly (by M-x gnuplot-run-buffer), or with the (customizable) shortcut C-c C-c

You can also send commands to gnuplot using C-c C-b (send buffer to gnuplot) or C-c C-r (send region to gnuplot), but the error reporting isn’t as helpful with these functions.

(end)"
   ;; ("e" #'a-function)
   )
 
 ) ; end of init section


;;; ===
;;; ===========
;;; === SQL ===
;;; ===========

(my-init--with-duration-measured-section 
 t
 "SQL"

 (setq sql--new-function-names
       '("replace"
         "use"
         "concat"))

 (font-lock-add-keywords 'sql-mode
                         `((,(regexp-opt sql--new-function-names 'words) . font-lock-function-name-face)))

 (add-hook 'sql-mode-hook 
           (lambda ()
             (setq outline-regexp "-- === ")
             (outline-minor-mode)))

 ;; show line number on the left:
 (dolist (mode '(sql-mode-hook))
   (add-hook mode (lambda () (display-line-numbers-mode 1))))

 (defhydra hydra-sql (:exit t :hint nil)
   "
^SQL hydra:
^----------
outline : _o_ hide & _a_ show-all
"
   ("a" #'outline-show-all)
   ("o" #'outline-hide-body))
 
 ) ; end of init section


;;; ===
;;; ===============
;;; ===== ZIP =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "Zip"

 (unless (my-init--path-to-directory-or-file-exists-p *unzip-program*)
   (my-init--warning "!! *unzip-program* is nil or does not exist: %s" *unzip-program*))

 (defun my/unzip ()
   "Unzip file on dired line.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (my-init--file-exists-p *unzip-program*)
     (error "Unable to use unzip since no program defined: %s" *unzip-program*))
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to unzip when not in dired-mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Trying to unzip several files."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def"
                 (replace-regexp-in-string  "/" "\\\\" path)))
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            (file-directory (file-name-directory file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            (file-name-without-extension (file-name-base file-full-name))
            (output-directory
             (if (y-or-n-p "Create directory?")
                 (concat file-directory (read-string "create directory: " file-name-without-extension))
               file-directory))
            (output-directory-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes output-directory))
            (cmd (concat "\"" *unzip-program* "\""
                         " x " "\"" file-full-name-slash-OK-accents-OK "\""
                         " -aou -y"
                         " -o" "\"" output-directory-slash-OK-accents-OK "\""))
            ;; Example of cmd line: 7z e "C:\Users\...\Downloads\emacs-26.2.tar" -y -o"C:\Users\...\Downloads\emacs-26.2"
            ;; https://info.nrao.edu/computing/guide/file-access-and-archiving/7zip/7z-7za-command-line-guide
            )
       (message "Unzipping %s by %s..." file-name (file-name-nondirectory *unzip-program*))
       (message "%s" (shell-command-to-string cmd))
       ;; (call-process-shell-command cmd nil 0)
       (revert-buffer)
       (message "... unzip finished."))))

 (defun my/zip-content-of-current-directory ()
   "Zip content of current directory into a zip archive.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (my-init--file-exists-p *unzip-program*)
     (error "Unable to use unzip since no program defined: %s" *unzip-program*))
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to zip when not in dired-mode."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def"
                 (replace-regexp-in-string  "/" "\\\\" path)))
     (let* ((current-directory-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes default-directory))
            (archive-name (concat (read-string "Archive name (without zip suffix): " "archive") ".zip"))
            (cmd (concat "\"" *unzip-program* "\""
                         " a -tzip "
                         "\"" current-directory-slash-OK-accents-OK archive-name "\""
                         " "
                         "\"" current-directory-slash-OK-accents-OK "*.*\""
                         " -r"))
            ;; Example of cmd line: "c:\Users\...\7-ZipPortable\App\7-Zip64\7z.exe" a -tzip "c:\Users\...\Downloads\test\archive.zip" "c:\Users\...\Downloads\test\*.*" -r
            ;; https://info.nrao.edu/computing/guide/file-access-and-archiving/7zip/7z-7za-command-line-guide
            )
       (message "Zipping %S with %s" current-directory-slash-OK-accents-OK (file-name-nondirectory *unzip-program*))
       ;; (call-process-shell-command cmd nil t)
       (message "%s" (shell-command-to-string cmd))
       (revert-buffer)
       (message "... zip finished."))))

 (defun my/list-zip-content ()
   "List the content of zip file on dired line.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (my-init--file-exists-p *unzip-program*)
     (error "Unable to list content of zip file since no program defined: %s" *unzip-program*))
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to list content of zip file when not in dired-mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Trying to list the content of several files."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def"
                 (replace-regexp-in-string  "/" "\\\\" path)))
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            (cmd (concat "\"" *unzip-program* "\""
                         " l " "\"" file-full-name-slash-OK-accents-OK "\"")))
       (message "Listing content of %s by %s..." file-name (file-name-nondirectory *unzip-program*))
       ;; (shell-command-to-string cmd)
       (shell-command cmd nil nil)
       (revert-buffer)
       (message "... zip content listing finished."))))

 (defun my/zip-add-to-archive-present-in-same-directory () 
   "Add to archive present in same directory.
Attention: overwrite.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (unless (my-init--file-exists-p *unzip-program*)
     (error "Unable to add to zip archive since no program defined: %s" *unzip-program*))
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to add to zip archive when not in dired-mode."))
   (let ((files-to-add (dired-get-marked-files)))
     (message "marked files: %s" files-to-add)
     (when (null files-to-add)
       (error "Trying to add to zip archive but no file selected."))
     (let* ((files-to-add-no-path (mapcar #'file-name-nondirectory files-to-add))
            (all-zip-files (directory-files default-directory nil "\\.zip$"))
            (potential-zip-files (cl-set-difference all-zip-files files-to-add-no-path :test #'string=)))
       (message "files to add: %s" files-to-add-no-path)
       (message "all zip files: %s" all-zip-files)
       (message "potential zip files: %s" potential-zip-files)
       (when (null all-zip-files)
         (error "Impossible to add to archive since no zip file in the directory."))
       (when (null potential-zip-files)
         (error "Impossible to add to archive since all zip files are in the list of files to add."))
       (let* ((chosen-zip-file
               (completing-read
                "Choose archive file: "
                potential-zip-files))
              (target (concat default-directory chosen-zip-file))
              (target-accents-OK target))
         (message "chosen zip file: %s" chosen-zip-file)
         (message "default directory: %s" default-directory)
         (dolist (file-to-add files-to-add)
           (let* ((file-to-add-accents-OK file-to-add)
                  (cmd
                   (concat "\"" *unzip-program* "\""
                           " a -aot "
                           "\"" target-accents-OK "\""
                           " "
                           "\"" file-to-add-accents-OK "\""
                           " -r")))
             (message "- Adding %s to %s" file-to-add target)
             (message "%s" (shell-command-to-string cmd))
             (message "... addition OK.")))
         (revert-buffer)
         (message "All additions finished.")))))

 ) ; end of init section


;;; ===
;;; =================
;;; ===== PDFTK =====
;;; =================

(my-init--with-duration-measured-section 
 t
 "pdftk"

 (when (null *pdftk-program-name*)
   (message "!! *pdftk-program-name* is nil: %s" *pdftk-program-name*))

 (unless (my-init--file-exists-p *pdftk-program*)
   (my-init--warning "!! *pdftk-program* is nil or does not exist: %s" *pdftk-program*))

 (defun my/pdf-burst ()
   "Bursts PDF file on dired line.
(v2, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (when (null *pdftk-program*)
     (error "No PDFTK program is defined."))
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to burst a PDF file when not in dired-mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Trying to burst several files."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def"
                 (replace-regexp-in-string  "/" "\\\\" path)))
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            (file-directory (file-name-directory file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            (file-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-name))
            ;; (file-name-without-extension (file-name-base file-full-name))
            (output-directory file-directory)
            (output-directory-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes output-directory))
            (cmd (concat "\"" *pdftk-program* "\""
                         " "
                         "\"" file-full-name-slash-OK-accents-OK "\""
                         " burst output "
                         "\"" output-directory-slash-OK-accents-OK "page_%03d_of_" file-name-slash-OK-accents-OK "\""))
            ;; Example of cmd line: "c:/Users/.../PDFTKBuilderPortable/App/pdftkbuilder/pdftk.exe" "c:/Users/.../Downloads/test.pdf" burst output "c:/Users/.../Downloads/page_%03d_of_XYZ.pdf"
            )
       (when (not (or (string= (file-name-extension file-full-name) "pdf")
                      (string= (file-name-extension file-full-name) "PDF")))
         (error "Trying to burst a non-PDF file: %S" file-full-name))
       (message "Bursting (splitting) PDF file %S with %s" file-name *pdftk-program-name*)
       (call-process-shell-command cmd nil t)
       (revert-buffer))))

 (defun my/pdf-extract ()
   "Extracts pages from a PDF file on dired line.
(v2, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (when (null *pdftk-program*)
     (error "No PDFTK program is defined."))
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to extract from a PDF file when not in dired-mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Trying to extract from several files."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def"
                 (replace-regexp-in-string  "/" "\\\\" path)))
     (let* ((first-page (read-string "First page: "))
            (last-page (read-string "Last page: "))
            (files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            (file-directory (file-name-directory file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            (file-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-name))
            ;; (file-name-without-extension (file-name-base file-full-name))
            (output-directory file-directory)
            (output-directory-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes output-directory))
            (cmd (concat "\"" *pdftk-program* "\""
                         " "
                         "A=\"" file-full-name-slash-OK-accents-OK "\""
                         " cat A" first-page "-" last-page " output "
                         "\"" output-directory-slash-OK-accents-OK "page_" first-page "_to_" last-page "_of_" file-name-slash-OK-accents-OK "\""))
            ;; Example of cmd line: "c:/Users/.../PDFTKBuilderPortable/App/pdftkbuilder/pdftk.exe" A="c:/Users/.../Downloads/test.pdf" cat A2-4 output "c:/Users/.../Downloads/page_2_to_4_of_XYZ.pdf"
            )
       (when (not (or (string= (file-name-extension file-full-name) "pdf")
                      (string= (file-name-extension file-full-name) "PDF")))
         (error "Trying to extract pages from a non-PDF file: %S" file-full-name))
       (message "Extracting page(s) %s to %s of PDF file %S with %s" first-page last-page file-name *pdftk-program-name*)
       (call-process-shell-command cmd nil t)
       (revert-buffer))))

 (defun my/pdf-join ()
   "Concatenates PDF files
Caution: no accent in file names
If necessary : M-x read-only-mode
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   (when (null *pdftk-program*)
     (error "No PDFTK program is defined."))
   (when (not (string-equal major-mode "dired-mode"))
     (error "Trying to extract from a PDF file when not in dired-mode."))
   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def"
                 (replace-regexp-in-string  "/" "\\\\" path)))
     (let* ((output-file (read-string "Output file (default: output.pdf): " nil nil "output.pdf"))
            (files-list (cl-sort (dired-get-marked-files) 'string-lessp))
            (first-file-full-name (car files-list))
            (files-directory (file-name-directory first-file-full-name))
            (output-directory files-directory)
            (output-directory-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes output-directory))
            (cmd (concat "\"" *pdftk-program* "\""))
            ;; Example of cmd line: "c:/Users/.../PDFTKBuilderPortable/App/pdftkbuilder/pdftk.exe" "c:/Users/.../Downloads/1.pdf" "c:/Users/.../Downloads/2.pdf" cat output "c:/Users/.../Downloads/output.pdf"
            )
       (dolist (file-full-name files-list)
         (when (not (or (string= (file-name-extension file-full-name) "pdf")
                        (string= (file-name-extension file-full-name) "PDF")))
           (error "Trying to join a non-PDF file: %S" file-full-name))
         (let ((file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name)))
           (setq cmd (concat cmd " " "\"" file-full-name-slash-OK-accents-OK "\""))))
       (setq cmd (concat cmd " cat output " "\"" output-directory-slash-OK-accents-OK output-file "\""))
       ;;(message "cmd: %s" cmd)
       (message "Joining PDF files with %s" *pdftk-program-name*)
       (call-process-shell-command cmd nil t)
       (revert-buffer))))
 
 ) ; end of init section


;;; ===
;;; ======================
;;; ===== IRFAN VIEW =====
;;; ======================

(my-init--with-duration-measured-section 
 t
 "IrfanView"

 (unless (my-init--file-exists-p *irfanview-program*)
   (my-init--warning "!! *irfanview-program* is nil or does not exist: %s" *irfanview-program*))

 (defun my/open-with-Irfan ()           ;  (&optional @fname)
   "Open the current file or dired marked files in Irfan.
To be called from dired hydra."
   (interactive)
   (unless (my-init--file-exists-p *irfanview-program*)
     (error "Impossible to launch Irfan View since program path not known: %s" *irfanview-program*))
   (my-init--open-with-external-program
    "Irfan"
    (lambda (file-name)
      (concat "\"" *irfanview-program* "\"" " " "\"" file-name "\""))))

 (defun my/launch-irfan ()
   "Open Irfan"
   (interactive)
   (my-init--open-windows-executable "Irfan" *irfanview-program*))

 ) ; end of init section


;;; ===
;;; ===============
;;; ===== CMD =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "cmd"

 (defun my/start-cmd ()
   "Open a cmd window from current dired buffer or encompassing current file.
To be called from hydra."
   (interactive)
   
   (cond ((string-equal major-mode "dired-mode")
          (let ((proc (start-process "cmd" nil "cmd.exe" "/C" "start" "cmd.exe" "/K" "cd" default-directory)))
            (set-process-query-on-exit-flag proc nil)
            (my-init--message2 "Native cmd window opened in %s directory" default-directory)))

         ((not (null (buffer-file-name)))
          (let ((proc (start-process "cmd" nil "cmd.exe" "/C" "start" "cmd.exe" "/K" "cd" (file-name-directory (buffer-file-name)))))
            (set-process-query-on-exit-flag proc nil)
            (my-init--message2 "Native cmd window opened in directory where %S is located " buffer-file-name)))

         (t
          (let ((proc (start-process "cmd" nil "cmd.exe" "/C" "start" "cmd.exe")))
            (set-process-query-on-exit-flag proc nil)
            (my-init--message2 "Native cmd window opened")))))
 
 ) ; end of init section


;;; ===
;;; =============================================
;;; ===== WINDOWS APPS, WINDOWS EXECUTABLES =====
;;; =============================================

(my-init--with-duration-measured-section 
 t
 "Windows apps, Windows executables"

 (defun my-init--dired-open-directory-if-valid (name path)
   "Open directory PATH (name: NAME) only if non null and valid."
   (if (my-init--directory-exists-p path)
       (progn
         (message "Opening %s: %s" name path)
         (dired path))
     (message "Impossible to open %s directory since path is nil or not valid: %s" name path)))

 (defun my/open-downloads-directory-in-dired ()
   "Open Downloads directory in dired."
   (interactive)
   (my-init--dired-open-directory-if-valid "Downloads" *downloads-directory*))

 (defun my/open-ongoing-directory-in-dired ()
   "Open 'en cours' directory in dired."
   (interactive)
   (my-init--dired-open-directory-if-valid "En cours" *ongoing-directory*))

 (defun my/open-dropbox-directory-in-dired ()
   "Open Dropbox directory in dired."
   (interactive)
   (my-init--dired-open-directory-if-valid "Dropbox" *dropbox-directory*))

 (defun my/open-local-repos-directory-in-dired ()
   "Open 'local repos' directory in dired."
   (interactive)
   (my-init--dired-open-directory-if-valid "local repos" *local-repos-directory*))

 (when nil
   (defun my/open-shared-drives ()
     "Open shared drives M: and S:"
     (interactive)
     (message "Opening shared network drives M: and S: from Emacs")
     (call-process-shell-command "explorer M:" nil 0)
     (call-process-shell-command "explorer S:" nil 0)))

 (defhydra hydra-windows-executables (:exit t :hint nil) ;  :columns 1)
   "
^Windows executables:
^--------------------

_w_: Microsoft Word
_e_: Microsoft Excel
_p_: Microsoft Powerpoint
_b_: Thunderbird
_f_: Firefox
_c_: Chrome
_i_: Irfan

Win-1 et Win-t launch applications from task bar
Win-S-s        screenshot (or W-^-S or W-fn-Impr)
Win-d          Desktop
Win-e          Explorer
Win-i          Parameters
Win-r          command
Win-w          news

Firefox: C-w, C-S-t (?)
F11 full screen
Alt-F4 and Alt-TAB

(end)"
   ("b" (my-init--open-windows-executable "Thunderbird" *thunderbird-executable*))
   ("c" (my-init--open-windows-executable "Chrome" *chrome-executable*))
   ("e" (my-init--open-windows-executable "Microsoft Excel" *excel-path*))
   ("f" (my-init--open-windows-executable "Firefox" *firefox-path*))
   ("i" #'my/launch-irfan)
   ("p" (my-init--open-windows-executable "Microsoft Powerpoint" *powerpoint-path*))
   ("t" (my-init--open-windows-executable "Microsoft Teams" *teams-path*))
   ("w" (my-init--open-windows-executable "Microsoft Word" *word-path*))
   ) ; end of hydra

 (global-set-key (kbd "C-c w") #'hydra-windows-executables/body)
 
 ) ; end of init section


;;; ===
;;; =================
;;; ===== PUTTY =====
;;; =================

;;; void

;;; ===
;;; ===============
;;; ===== IRC =====
;;; ===============

;; M-x erc
;; (do not forget to indicate password)
;; /join #lisp
;; or #emacs

;;; ===
;;; ===============
;;; ===== FTP =====
;;; ===============

;; void

;;; ===
;;; ==============================
;;; ===== REST GET POST HTTP =====
;;; ==============================

;; (require 'restclient)
;; M-x restclient-mode
;; then C-c C-c

;;; ===
;;; =================
;;; ===== TRAMP =====
;;; =================

;;; void

;;; ===
;;; =================
;;; ===== DITAA =====
;;; =================

(my-init--with-duration-measured-section 
 t
 "DITAA"

 (unless (my-init--file-exists-p *ditaa-jar*)
   (message "!! *ditaa-jar* is nil or does not exist: %s" *ditaa-jar*))

 ;; void
 
 ) ; end of init section


;;; ===
;;; ================
;;; ===== JSON =====
;;; ================

(my-init--with-duration-measured-section
 t
 "json"

 (use-package json-mode
   :mode ("\\.json\\'" . json-mode)
   :ensure t
   :config (my-init--message-package-loaded "json-mode"))

 ) ; end of init section


;;; ===
;;; ================
;;; ===== YAML =====
;;; ================

(my-init--with-duration-measured-section
 t
 "yaml"

 (use-package yaml-mode
   :mode ("\\.yaml\\'" . yaml-mode)
   :ensure t
   :config (my-init--message-package-loaded "yaml-mode"))
 
 ) ; end of init section


;;; ===
;;; ======================
;;; ===== R LANGUAGE =====
;;; ======================

(my-init--with-duration-measured-section 
 t
 "R language"

 ;; M-x R to launch REPL
 ;; open a .R file then C-c C-c to execute within REPL
 ;; also work in org-mode source block (Babel)

 (unless (my-init--file-exists-p *R-executable*)
   (my-init--warning "!! *R-executable* is nil or does not exist: %s" *R-executable*))

 (unless (my-init--file-exists-p *Rterm-executable*)
   (my-init--warning "!! *Rterm-executable* is nil or does not exist: %s" *Rterm-executable*))

 ;; Babel:
 (defun my--org-babel-load-R (&rest _args)
   (message "Preparing org-mode babel for R...")
   (add-to-list 'org-babel-load-languages '(R . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-R))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-R)

 ;; Babl complement:
 (setq org-babel-R-command (format "\"%s\" --slave --no-save" *R-executable* ))

 ;; ESS for R integration:
 (use-package ess
   :mode ("\\.R\\'" . R-mode)
   :ensure t
   :config (my-init--message-package-loaded "ess"))

 ;; Setting R executable:
 ;; (setq inferior-R-program-name *Rterm-executable*)
 ;; Byte-compile warning:
 ;;    ‘inferior-R-program-name’ is an obsolete variable (as of ESS 18.10)
 ;;    use ‘inferior-ess-r-program’ instead.
 (setq inferior-ess-r-program *Rterm-executable*)

 ;; Syntax highlighting for R mode, in particular in src blocks:

 (setq R--keywords
       '("%in%"
         ))

 (setq R--types '("tobefilled12345"))

 (setq R--constants
       '(
         "tobefilled12345"
         ))

 (setq R--events '("tobefilled12345"))

 (setq R--functions
       '("aes"
         "c"
         "data.frame"
         "element_blank"
         "element_line"
         "element_rect"
         "element_text"
         "facet_wrap"
         "geom_bar"
         "geom_line"
         "geom_point"
         "geom_smooth"
         "geom_text"
         "ggplot"
         "gsub"
         "library"
         "max"
         "min"
         "options"
         "option"
         "require"
         "rgb"
         "round"
         "scale_y_continuous"
         "theme"
         "unique"
         ))

 (setq R--font-lock-keywords
       (let* (
              ;; generate regex string for each category of keywords
              (x-keywords-regexp (regexp-opt R--keywords 'words))
              (x-types-regexp (regexp-opt R--types 'words))
              (x-constants-regexp (regexp-opt R--constants 'words))
              (x-events-regexp (regexp-opt R--events 'words))
              (x-functions-regexp (regexp-opt R--functions 'words)))

         `(
           (,x-types-regexp . font-lock-type-face)
           (,x-constants-regexp . font-lock-constant-face)
           (,x-events-regexp . font-lock-builtin-face)
           (,x-functions-regexp . font-lock-function-name-face)
           (,x-keywords-regexp . font-lock-keyword-face)
           ;; note: order above matters, because once colored, that part won't change.
           ;; in general, put longer words first
           )))

 (define-derived-mode R-mode fundamental-mode "R mode"
   "Major mode for editing R"
   (setq font-lock-defaults '((R--font-lock-keywords))))

 ) ; end of init section


;;; ===
;;; =================
;;; ===== MAGIT =====
;;; =================

(my-init--with-duration-measured-section 
 t
 "Magit"

 ;; M-x magit-version to test

 (if (my-init--directory-exists-p *git-executable-directory*)
     (my-init--add-to-path-and-exec-path "Git" *git-executable-directory*)
   (my-init--warning "!! *git-executable-directory* is nil or does not exist: %s" *git-executable-directory*))

 (let ((diff3-executable (concat *git-diff3-directory* "/diff3.exe")))
   (if (my-init--file-exists-p diff3-executable)
       (add-to-list 'exec-path *git-diff3-directory*)
     (my-init--warning "!! (magit) diff3.exe not found within %s" *git-diff3-directory*)))
 ;; (setq ediff-diff3-program "C:/portable-programs/Git/usr/bin/diff3.exe")

 (use-package magit
   :bind (("C-x g" . magit-status)
          ("C-x C-g" . magit-status))
   :config (my-init--message-package-loaded "magit"))

 (defhydra hydra-magit-status (:exit t :hint nil)
   "
^Magit-status hydra:
^-------------------

C-x g to access the status buffer
g     to update
?     to know all options
q     to close magit buffer

s     to stage
         and TAB on 'unstaged' line to see hunks one by one
         s / u     (n / p, M-n / M-p to navigate)

       possibility to stage/unstage regions within hunks

c c   to prepare commit, then write info, then C-c C-c
P p   to push to remote (Github)

clean cache: ':' then complete with 'gc'

(end)
"
   ;; ("e" #'a-function)
   )

 (defhydra hydra-magit-diff (:exit t :hint nil)
   "
^Magit-diff hydra:
^-----------------

M-n and p to navigate sections to stage/unstage

(end)
"
   ;; ("e" #'a-function)
   )
 
 ) ; end of init section


;;; ===
;;; ===============
;;; ===== DAX =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "DAX"

 ;; DAX mode
 ;; useful for syntax highlighting in src block

 (setq dax--keywords
       '("RETURN"
         "VAR" ))

 (setq dax--types '("tobefilled12345"))

 (setq dax--constants
       '(
         "DAY"
         ))

 (setq dax--events '("tobefilled12345"))

 (setq dax--functions
       '("ALLSELECTED"
         "ALL"
         "BLANK"
         "CALCULATE"
         "DISTINCTCOUNT"
         "DATEDIFF"
         ;; "DATE"
         "COUNT"
         "DIVIDE"
         "EVALUATE"
         "FILTER"
         "FORMAT"
         "IF"
         "ISBLANK"
         "KEEPFILTERS"
         "left"
         "LEN"
         "MAX"
         "MIN"
         "MOD"
         "ORDER BY"
         "QUOTIENT"
         "RELATED"
         "REMOVEFILTERS"
         "right"
         "SUMX"
         "USERELATIONSHIP"
         "SUMMARIZECOLUMNS"
         "SUMMARIZE"
         "SUM"
         "SWITCH"
         "TODAY"
         "TOPN"
         ))

 (setq dax--font-lock-keywords
       (let* (
              ;; generate regex string for each category of keywords
              (x-keywords-regexp (regexp-opt dax--keywords 'words))
              (x-types-regexp (regexp-opt dax--types 'words))
              (x-constants-regexp (regexp-opt dax--constants 'words))
              (x-events-regexp (regexp-opt dax--events 'words))
              (x-functions-regexp (regexp-opt dax--functions 'words)))

         `(
           (,x-types-regexp . font-lock-type-face)
           (,x-constants-regexp . font-lock-constant-face)
           (,x-events-regexp . font-lock-builtin-face)
           (,x-functions-regexp . font-lock-function-name-face)
           (,x-keywords-regexp . font-lock-keyword-face)
           ;; note: order above matters, because once colored, that part won't change.
           ;; in general, put longer words first
           )))

 (defconst dax--mode-syntax-table
   (let ((table (make-syntax-table)))
     ;; ' is a string delimiter
     ;; (modify-syntax-entry ?' "\"" table)
     ;; " is a string delimiter too
     (modify-syntax-entry ?\" "\"" table)

     ;; / is punctuation, but // is a comment starter
     (modify-syntax-entry ?/ ". 12" table)
     ;; \n is a comment ender
     (modify-syntax-entry ?\n ">" table)
     table))

 (define-derived-mode DAX-mode fundamental-mode "DAX mode"
   "Major mode for editing Power BI DAX"
   :syntax-table dax--mode-syntax-table
   (setq font-lock-defaults '((dax--font-lock-keywords)))
   (setq font-lock-defaults `(dax--font-lock-keywords nil t))

   ;; (font-lock-fontify-buffer)
   ;; not needed in a mode definition because font-lock will be activated automatically?

   (setq font-lock-keywords-case-fold-search t))

 ) ; end of init section


;;; ===
;;; ===============
;;; ===== OCR =====
;;; ===============

(my-init--with-duration-measured-section 
 t
 "OCR"

 (unless (my-init--directory-exists-p *temp-directory*)
   (my-init--warning "!! *temp-directory* is nil or does not exist: %s" *temp-directory*))

 (unless (my-init--file-exists-p *imagemagick-convert-program*)
   (my-init--warning "!! *imagemagick-convert-program* is nil or does not exist: %s" *imagemagick-convert-program*))

 (unless (my-init--directory-exists-p *tesseract-tessdata-dir*)
   (my-init--warning "!! *tesseract-tessdata-dir* is nil or does not exist: %s" *tesseract-tessdata-dir*))

 (unless (my-init--file-exists-p *tesseract-exe*)
   (my-init--warning "!! *tesseract.exe* is nil or does not exist: %s" *tesseract-exe*))

 (defun my/insert-ocr-clipboard ()
   "Insert in current buffer the result of OCR performed on clipboard content (which is supposed to be a snapshot of text).
Uses Tesseract and ImageMagick.
(v1, available in occisn/emacs-utils GitHub repository)"
   (interactive)

   (cl-labels ((paste-image-from-clipboard-to-file-with-imagemagick (destination-file-with-path)
                 "Paste image from clipboard fo file DESTINATION-FILE-WITH-PATH with ImageMagick.
(v1, available in occisn/emacs-utils GitHub repository + adaptations)"
                 (unless (my-init--file-exists-p *imagemagick-convert-program*)
                   (error "Unable to paste image from clipboard to file, since *imagemagick-convert-program* does not contain valid content: %s" *imagemagick-convert-program*))
                 (let ((cmd (concat "\"" *imagemagick-convert-program* "\" " "clipboard: " destination-file-with-path)))
                   (message "Pasting image from clipboard to %s with ImageMagick." destination-file-with-path)
                   (call-process-shell-command cmd nil 0)))) ; end of labels function definitions
     
     (let* ((tmp-file-1 (make-temp-file (concat *temp-directory* "ocr-")))
            (tmp-file-2 (concat (format "%s" tmp-file-1) ".png"))
            (tmp-file-3 (make-temp-file (concat *temp-directory* "ocr-output-")))
            (tmp-file-4 (concat (format "%s" tmp-file-3) ".txt"))
            (cmd (format "\"%s\" --tessdata-dir \"%s\" \"%s\" \"%s\" -l fra" *tesseract-exe* *tesseract-tessdata-dir* tmp-file-2 tmp-file-3)))

       (paste-image-from-clipboard-to-file-with-imagemagick tmp-file-2)
       (unless (file-exists-p tmp-file-2) (sleep-for 0.5))
       (unless (file-exists-p tmp-file-2) (error "File with pasted image does not exist, even after 0.5 s sleep: %s" tmp-file-2))
       (call-process-shell-command cmd nil t)
       (if (file-exists-p tmp-file-4)
           (insert-file-contents tmp-file-4)
         (error "OCR output file does not exist: %s" tmp-file-4))  
       
       (message "OCR of clipboard via Tesseract")

       (when (file-exists-p tmp-file-1) (delete-file tmp-file-1))
       (when (file-exists-p tmp-file-2) (delete-file tmp-file-2))
       (when (file-exists-p tmp-file-4) (delete-file tmp-file-4)))))

 (defun my/scanned-pdf-to-txt ()
   "Convert scanned PDF file on dired line to text buffer.
Uses Imagemagick and Tesseract.
(v4, available in occisn/emacs-utils GitHub repository)"
   (interactive)
   
   (when (not (string-equal major-mode "dired-mode"))
     (error "Scanned pdf to txt: not in dired mode."))
   (when (> (length (dired-get-marked-files)) 1)
     (error "Scanned pdf to txt: more than 1 file has been selected."))

   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def"
                 (replace-regexp-in-string  "/" "\\\\" path)))
     
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            ;; (file-directory (file-name-directory file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            ;; (file-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-name))
            ;; (file-name-without-extension (file-name-base file-full-name))

            (cmd1 (concat "\"" *imagemagick-convert-program* "\" " "-density 300x300 " "\"" file-full-name-slash-OK-accents-OK "\"" " " *temp-directory* "zabcd-%03d.jpg"))
            )

       ;; step 1: convert pdf to jpg with ImageMagick
       (message "Scanned pdf to txt STEP 1: convert pdf to jpg with ImageMagick")
       (call-process-shell-command cmd1 nil 0)

       ;; step 2: convert jpg to txt with Tesseract
       (message "Scanned pdf to txt STEP 2: convert jpg to txt with Tesseract")
       
       (let* ((txt-buffer (generate-new-buffer (format "*Text content of scanned pdf file %s (my/scanned-pdf-to-txt x)*" file-name)))
              (image-files (file-expand-wildcards (concat *temp-directory* "zabcd-*.jpg")))
              (page-count 0))

         (switch-to-buffer txt-buffer)
         
         (dolist (image-file1 image-files)
           
           (setq page-count (+ page-count 1))
           (insert (format "------ PAGE %s -------\n\n" page-count))
           (let* ((tmp-file-3 (make-temp-file (concat *temp-directory* "ocr-output-")))
                  (tmp-file-4 (concat (format "%s" tmp-file-3) ".txt"))
                  (cmd2 (format "\"%s\" --tessdata-dir \"%s\" \"%s\" \"%s\" -l fra" *tesseract-exe* *tesseract-tessdata-dir* image-file1 tmp-file-3)))

             (call-process-shell-command cmd2 nil t)

             (if (file-exists-p tmp-file-4)
                 (progn
                   (insert-file-contents tmp-file-4)
                   (goto-char (point-max)))
               
               (error "my/scanned-pdf-to-txt: OCR output file does not exist: %s" tmp-file-4))

             (when (file-exists-p tmp-file-4) (delete-file tmp-file-4)))) ; end of dolist
         
         (goto-char (point-min)))))) ; end of defun

 ) ; end of init section


;;; ===
;;; ==============================================
;;; ===== C LANGUAGE, C PROGRAMMING LANGUAGE =====
;;; ==============================================

(my-init--with-duration-measured-section 
 t
 "C programming language"

 ;; === gcc in path
 
 (if (my-init--directory-exists-p *gcc-path*)
     (my-init--add-to-path-and-exec-path "gcc" *gcc-path*)
   (my-init--warning "!! *gcc-path* is nil or does not exist: %s" *gcc-path*))

 ;; Note: I have noticed that it is better to avoid space in the path leading to gcc
 
 ;; === Display line number
 
 (dolist (mode '(c-mode-hook c-ts-mode-hook))
   (add-hook mode (lambda () (display-line-numbers-mode 1))))

 ;; === Disable auto-fill in C++ mode (to avoid break lines @ 70)

 (when nil
   (add-hook 'c++-mode-hook
             (lambda ()
               (auto-fill-mode -1)
               (setq fill-column 120))))
 ;; actually handled by eglot/clangd

 ;; === Babel

 (defun my--org-babel-load-C (&rest _args)
   (message "Preparing org-mode babel for C...")
   (add-to-list 'org-babel-load-languages '(C . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-C))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-C)

 ;; === switch/toggle among source, header and test files

 (defun my/toggle-c-h ()
   "Toggle between C/C++ source and header files in the same directory.
Supports: .c <-> .h and .cpp <-> .hpp
Creates the file if it doesn't exist."
   (interactive)
   (let* ((filename (buffer-file-name))
          (extension (file-name-extension filename))
          (base (file-name-sans-extension filename))
          (new-file nil))
     (cond
      ((string= extension "c")
       (setq new-file (concat base ".h")))
      ((string= extension "h")
       (setq new-file (concat base ".c")))
      ((string= extension "cpp")
       (setq new-file (concat base ".hpp")))
      ((string= extension "hpp")
       (setq new-file (concat base ".cpp")))
      (t
       (message "Current file is not a .c/.h or .cpp/.hpp file")))
     (when new-file
       (if (file-exists-p new-file)
           (find-file new-file)
         (find-file new-file)
         (message "Created new file: %s" new-file)))))

 (defun my/toggle-source-test ()
   "Toggle between C/C++ source files in src/ and test files in tests/.
  Test files are named test_<filename> and located in tests/ directory.
  Creates the file if it doesn't exist, but errors if the directory doesn't exist."
   (interactive)
   (let* ((filename (buffer-file-name))
          (basename (file-name-nondirectory filename))
          (extension (file-name-extension filename))
          (dir (file-name-directory filename))
          (project-root (locate-dominating-file dir "src"))
          (new-file nil))
     (unless project-root
       (error "Cannot find project root (no src/ directory found)"))
     (cond
      ;; Current file is in src/ -> go to tests/
      ((string-match "/src/" filename)
       (setq new-file (concat project-root "tests/test_" basename)))
      ;; Current file is in tests/ and starts with test_ -> go to src/
      ((and (string-match "/tests/" filename)
            (string-prefix-p "test_" basename))
       (let ((source-name (substring basename 5))) ; Remove "test_" prefix
         (setq new-file (concat project-root "src/" source-name))))
      (t
       (message "Current file is not in src/ or tests/ directory")))
     (when new-file
       ;; Check if directory exists
       (let ((new-dir (file-name-directory new-file)))
         (unless (file-exists-p new-dir)
           (message "Directory does not exist: %s" new-dir)))
       ;; Open the file (creates it if doesn't exist)
       (find-file new-file)
       (unless (file-exists-p new-file)
         (message "Created new file: %s" new-file)))))

 ;;; === jump to main

 (defun my/jump-to-c-main ()
   "Jump to main.c or main.cpp based on current file extension.
  .c or .h files jump to main.c
  .cpp or .hpp files jump to main.cpp
  Errors if the file doesn't exist or extension is not recognized."
   (interactive)
   (let* ((current-file (buffer-file-name))
          (current-dir (file-name-directory current-file))
          (extension (file-name-extension current-file))
          (main-file nil))
     (cond
      ((member extension '("c" "h"))
       (setq main-file (concat current-dir "main.c")))
      ((member extension '("cpp" "hpp"))
       (setq main-file (concat current-dir "main.cpp")))
      (t
       (error "Unsupported file extension: .%s (expected .c, .h, .cpp, or .hpp)" extension)))
     (if (file-exists-p main-file)
         (find-file main-file)
       (error "File does not exist: %s" main-file))))

 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c m") #'my/jump-to-c-main)))

 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c m") #'my/jump-to-c-main)))

 ;; === add h header guard

 (defun my/insert-cpp-header-guard ()
   "Insert C++ header guard based on current buffer's file name.
If filename begins with a digit, prefix with X_."
   (interactive)
   (let* ((filename (file-name-nondirectory (buffer-file-name)))
          (guard-base (upcase (replace-regexp-in-string "[.-]" "_" filename)))
          (guard-name (if (string-match "^[0-9]" guard-base)
                          (concat "X_" guard-base)
                        guard-base)))
     (save-excursion
       (goto-char (point-min))
       (insert (format "#ifndef %s\n" guard-name))
       (insert (format "#define %s\n\n" guard-name))
       (goto-char (point-max))
       (insert (format "\n\n#endif // %s\n" guard-name)))
     (goto-char (point-min))
     (forward-line 2)))

 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c h") #'my/insert-cpp-header-guard)))

 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c h") #'my/insert-cpp-header-guard)))

 ;; === stand-alone & compile

 (defun c-save-compile-and-run-c-file ()
   "Compile and execute the current C file using gcc on Windows."
   (interactive)
   (let* ((flags "-Wall -Wextra -Werror -O3 -std=c2x -pedantic")
          (source-file (buffer-file-name))
          (file-name (file-name-nondirectory source-file))
          (exe-file (concat (file-name-sans-extension file-name) ".exe"))
          (compile-command (format "gcc %s -o %s %s && %s" 
                                   flags
                                   exe-file 
                                   file-name 
                                   exe-file)))
     (if source-file
         (progn
           (save-buffer)
           (compile compile-command))
       (message "Buffer is not visiting a file!"))))

 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-r") #'c-save-compile-and-run-c-file)))
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-r") #'c-save-compile-and-run-c-file)))

 ;; === stand-alone & shell

 (defun my/create-shell-window ()
   "Delete other windows, split right, open eshell on right, return to left."
   (interactive)
   (delete-other-windows)
   (split-window-right)
   (other-window 1)
   (eshell)
   (other-window -1))

 (defun my/compile-and-execute-current-c-buffer-in-eshell ()
   "Save and compile current C file in eshell"
   (interactive)
   (save-buffer)
   (my--eshell-cd-to-directory-of-current-buffer-if-not-the-case)
   (let* (
          ;; (eshell-buffer (get-buffer "*eshell*"))
          (flags "-Wall -Wextra -Werror -O3 -std=c2x -pedantic")
          (file-name (file-name-nondirectory buffer-file-name))
          (file-name-without-extension (file-name-sans-extension file-name))
          (cmd (concat "gcc " file-name " " flags " -o " file-name-without-extension " && time ./" file-name-without-extension ".exe")))
     (my--eshell-send-cmd cmd)))

 ;; === project & compile

 (defun compile-makefile-project ()
   "Compile using make the executable specified in the Makefile."
   (interactive)
   (let* ((makefile-dir (locate-dominating-file default-directory "Makefile"))
          (default-directory (or makefile-dir default-directory))
          (compile-command "make"))
     (if makefile-dir
         (progn
           (save-some-buffers t)
           (compile compile-command))
       (message "No Makefile found in current or parent directories!"))))

 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-c") #'compile-makefile-project)))
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-c") #'compile-makefile-project)))

 (defun compile-and-run-makefile-project ()
   "Compile using make and run the executable specified in the Makefile."
   (interactive)
   (let* ((makefile-dir (locate-dominating-file default-directory "Makefile"))
          (default-directory (or makefile-dir default-directory))
          (compile-command "make && make run"))
     (if makefile-dir
         (progn
           (save-some-buffers t)
           (compile compile-command))
       (message "No Makefile found in current or parent directories!"))))

 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-m") #'compile-and-run-makefile-project)))
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-m") #'compile-and-run-makefile-project)))

 (defun test-makefile-project ()
   "Test using the Makefile."
   (interactive)
   (let* ((makefile-dir (locate-dominating-file default-directory "Makefile"))
          (default-directory (or makefile-dir default-directory))
          (compile-command "make test"))
     (if makefile-dir
         (progn
           (save-some-buffers t)
           (compile compile-command))
       (message "No Makefile found in current or parent directories!"))))

 (add-hook 'c-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-t") #'test-makefile-project)))
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-t") #'test-makefile-project)))

 ;; === my/dired-clean-build-artifacts

 ;; defined above
 
 ;; === Abbrev for C

 (defun my-init--c-abbrev ()

   (abbrev-mode 1)

   (define-skeleton c-main-skeleton 
     "C main skeleton"
     nil
     "int main(void)\n{\n" > _ "\n" > "return EXIT_SUCCESS;\n" > "}\n")

   
   (define-skeleton c-while-loop-skeleton
     "Insert a while loop structure"
     nil
     > "while (" _ ") {" \n
     > \n
     "}" >)

   
   (define-skeleton c-for-loop-skeleton
     "Insert a for loop structure"
     nil
     > "for (" _ "; ; ) {" \n
     > \n
     "}" >)

   (define-skeleton c-include-skeleton
     "Insert includes"
     nil
     "#include <stdlib.h>\n#include <stdio.h>\n#include <string.h>\n\n")

   
   (define-skeleton c-if-skeleton
     "Insert an if structure"
     nil
     > "if (" _ ") {" \n > \n "}" >)

   (define-skeleton c-if-else-skeleton
     "Insert an if structure"
     nil
     > "if (" _ ") {" \n > \n > "} else {" \n \n "}" >))

 (add-hook 'c-mode-hook
           (lambda ()
             (my-init--c-abbrev)
             (define-abbrev c-mode-abbrev-table "cmain" "" 'c-main-skeleton)
             (define-abbrev c-mode-abbrev-table "cwhile" "" 'c-while-loop-skeleton)
             (define-abbrev c-mode-abbrev-table "cfor" "" 'c-for-loop-skeleton)
             (define-abbrev c-mode-abbrev-table "cinclude" "" 'c-include-skeleton)
             (define-abbrev c-mode-abbrev-table "cif" "" 'c-if-skeleton)
             (define-abbrev c-mode-abbrev-table "cifelse" "" 'c-if-else-skeleton)))
 
 (add-hook 'c-ts-mode-hook
           (lambda ()
             (my-init--c-abbrev)
             (define-abbrev c-ts-mode-abbrev-table "cmain" "" 'c-main-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cwhile" "" 'c-while-loop-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cfor" "" 'c-for-loop-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cinclude" "" 'c-include-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cif" "" 'c-if-skeleton)
             (define-abbrev c-ts-mode-abbrev-table "cifelse" "" 'c-if-else-skeleton)))
 
 ;; === Occur

 (defun my-c-occur ()
   (interactive)
   (occur "^[A-Za-z]\\|// ===")
   (other-window 1))

 ;; === clangd

 ;; clangd will use both files for projects
 ;;     (i) .clangd
 ;;    (ii) compile_commands.json
 ;; The second file is generated from Makefile by this cmd line
 ;;    C:\portable-programs\Python\Python314\Scripts\compiledb --overwrite make

 ;; It requires compiledb to be available.
 ;; Python shall be available on the system
 ;; To install compiledb:
 ;;   (1) download from https://github.com/nickdiego/compiledb
 ;;   (2) [cmd] cd C:\portable-programs\Python\Python314\Scripts
 ;;   (3) [cmd] pip install compiledb
 ;;   (4) test: [cmd] compiledb -h

 (if (my-init--directory-exists-p *clangd-path*)
     (my-init--add-to-path-and-exec-path "clangd" *clangd-path*)
   (my-init--warning "!! *clangd-path* is nil or does not exist: %s" *clangd-path*))

 ;; Treat all .h files as C by default
 (add-to-list 'auto-mode-alist '("\\.h\\'" . c-mode))

 ;; === treesitter installation

 ;; (treesit-library-abi-version) --> 14 ; expects version 14

 (unless (boundp 'treesit-language-source-alist)
   (setq treesit-language-source-alist '()))
 
 (add-to-list 'treesit-language-source-alist
              '(c "https://github.com/tree-sitter/tree-sitter-c" "v0.20.6"))
 ;; "v0.20.6" corresponds to v14 ; if ommitted, v15 is installed

 ;; M-x treesit-install-language-grammar RET c RET
 ;; and c++
 ;; to compile and install
 
 (if (my-init--file-exists-p *c-tree-sitter-dll*)
     ;; Remap c-mode to c-ts-mode (Tree-sitter version):
     (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode))
   (my-init--warning "!! c tree-sitter dll not found: %s" *c-tree-sitter-dll*))

 ;; === lsp (alternative to eglot)

 (when nil
   (use-package lsp-mode
     ;; :ensure t is usually implied if you use package management, but explicit is fine
     :commands (lsp lsp-deferred)
     :init
     ;; Set the key prefix for all lsp commands (e.g., C-c l f for format)
     (setq lsp-keymap-prefix "C-c l")

     :config
     ;; Optional: Better error highlighting with flycheck (instead of default flymake)
     ;; Requires installing the flycheck package separately.
     (setq lsp-diagnostics-provider :flycheck)
     ;; Optional: Enable Which-Key integration for better command discovery
     (lsp-enable-which-key-integration t)
     (my-init--message-package-loaded "lsp-mode")

     :hook
     ;; Start lsp-mode (specifically `lsp-deferred`) for C and C++ major modes.
     ;; `lsp-deferred` waits a moment before starting, preventing Emacs from hanging.
     ((c-mode c-ts-mode) . lsp-deferred)))

 (when nil
   (use-package lsp-ui
     :ensure t
     :hook
     ;; Enable lsp-ui-mode whenever lsp-mode is active
     (lsp-mode . lsp-ui-mode)

     :config
     (my-init--message-package-loaded "lsp-ui")

     :custom
     ;; Display documentation pop-ups at the bottom of the window
     (lsp-ui-doc-position 'bottom)
     ;; Make the pop-up documentation a bit faster
     (lsp-ui-doc-delay 0.8)
     ;; Show lsp-ui-sideline only when the cursor is on the diagnostic
     (lsp-ui-sideline-show-hover nil)))

 ;; Note: lsp-mode automatically registers itself as a company backend,
 ;; so you don't need a separate `company-lsp` package.
 
 ;; === Eglot (alternative to lsp)

 (when t
   
   (add-hook 'c-mode-hook 'eglot-ensure)
   (add-hook 'c-ts-mode-hook 'eglot-ensure)
   
   (use-package eglot
     :defer t           ; Load Eglot only when one of the hooks is run
     :hook
     ;; This is the main line: start Eglot for C/C++ modes
     ((c-mode c-ts-mode c++-mode c++-ts-mode) . eglot-ensure)

     :config
     ;; Optional: Add clangd to the server list explicitly if Emacs doesn't find it.
     ;; If clangd is in your PATH, this may not be strictly necessary.
     (add-to-list 'eglot-server-programs
                  '((c-mode c-ts-mode) . ("clangd")))

     ;; Optional: Enable snippet completion (requires yasnippet to be active)
     (when nil
       (when (featurep 'yasnippet)
         (setq eglot-snippet-insertion 'yasnippet)))
     (my-init--message-package-loaded "eglot")

     (define-key eglot-mode-map (kbd "C-c a") #'eglot-code-actions))

   ;; normally already loaded:
   (use-package company
     :ensure t
     :hook (eglot-managed-mode . company-mode)
     :config (my-init--message-package-loaded "company")))

 ;; === Indentation
 
 (add-hook 'c-mode-hook
           (lambda ()
             (setq c-default-style "gnu" ; "linux, "gnu", "k&r", "bsd", "stroustrup"
                   c-basic-offset 4)     ; tab width
             ))       
 
 ;; already stated elsewhere in this file:
 ;; (setq-default indent-tabs-mode nil)

 ;; normally default:
 ;; (global-font-lock-mode t)

 (defun my/indent-eglot-buffer ()
   "Indent eglot buffer (C/C++)."
   (interactive)
   (save-excursion
     (let ((nb-tabs (count-matches "\t")))

       ;; (1) untabify if necessary:
       (when (> nb-tabs 0)
         (if (= nb-tabs 1)
             (message "1 tab identified... untabifying buffer")
           (message "%d tabs identified... untabifying buffer" nb-tabs))
         (goto-char (point-min))
         (push-mark)
         (goto-char (point-max))
         (untabify (point) (mark))
         (pop-mark))

       ;; (2) indent:
       (let ((window-start (window-start))
             (point (point)))
         (eglot-format-buffer)       ; <-- the actual function
         (goto-char point)
         (set-window-start nil window-start t))
       ;; all the above to avoid a jump in viewport, but does not work
       
       (recenter-top-bottom))))

 ;; === hideshow

 (when t
   (add-hook 'c-ts-mode-hook 'hs-minor-mode)
   (add-hook 'c-mode-hook 'hs-minor-mode)
   
   (setq hs-hide-comments-when-hiding-all t)
   (setq hs-isearch-open t) ; Automatically open folded code during isearch

   ;; Key bindings
   (global-set-key (kbd "C-c f t") 'hs-toggle-hiding)
   (global-set-key (kbd "C-c f r") 'hs-hide-level-recursive)
   (global-set-key (kbd "C-c f s") 'hs-show-block)
   (global-set-key (kbd "C-c f h") 'hs-hide-block)
   (global-set-key (kbd "C-c f S") 'hs-show-all)
   (global-set-key (kbd "C-c f H") 'hs-hide-all))

 ;; === alternative: ts-fold (not available with use-package)

 ;; void
 
 ;; === expand-region

 ;; expand-region package already loaded in lisp section

 ;; === imenu list in side bar

 ;; imenu-list package already loaded in lisp section
 
 ;; === yasnippet... no since abbrev

 (when nil
   (use-package yasnippet
     :ensure t
     :config
     (yas-global-mode 1)))

 ;; === C hydra
 
 (defhydra hydra-c (:exit t :hint nil)
   "
^C hydra:
^--------
FILES: _h_: switch between source and header files | _t_: switch between source and test files
       C-c m jump to main | C-c h insert h/hpp header guard
MOVEMENT :
   move among top-level expressions + select: C-M-a, C-M-e C-M-h
   forward/backward expression: C-M-f, C-M-b
   next/previous sibling C-M-n, C-M-p
   up/down in tree C-M-u C-M-d
JUMP TO TOP-LEVEL EXP: _c_ : occur | M-x imenu | C-' (list in sidebar)
MANIPULATE EXP: [...]
SELECT: select sexp: C-= (expand-region)
COLLAPSE: hideshow : C-c f h / s / t : hide / show / toggle current block
                     C-c f H / S     : hide / show all
MACROS: [...]
INDENT: _i_ndent (eglot-format-buffer)
COMMENT: M-; for end of line or selection | C-x C-; for line | M-x comment-region | M-x uncomment-region
DOCUMENTATION: bottom of screen (automatic) and more with _d_ (M-x eldoc-doc-buffer) or C-h .
REFERENCES: M-. M-, : goto function/variable definition, and back (xref-find-definitions via eglot)
            M-? : find all references (xref-find-references via eglot)
ABBREV: [...]
COMPLETE: C-M-i   completion (eglot)
REFACTOR: _r_efactor symbol at point (eglot-rename) | [projectile]
EXECUTE:
   ONE FILE with compile: C-c C-r: save, compile and run (gcc ...)
   ONE FILE with shell: _s_ : show eshell
                        _x_ : compile & execute in shell (gcc ...)
   PROJECT with compile: C-c C-c, compile project
                         C-c C-m, save compile and run (M-x compile > make && make run)
                         C-c C-t, save and test (M-x compile > make test)
   PROJECT with projectile: compile : C-c p c c > make, make run, make test
                             execute : C-c p u   > make run
DEBUG: C-c a to implement eglot proposed action / correction (eglot-code-actions) | C-h . to access to overlaid eglot/clangd warning
CLEAN: my/dired-clean-build-artifacts (before resynchronization of Dropbox)
SPECIFIC: M-x eglot-shutdown | M-x eglot-reconnect
{end}"
   ("c" #'my-c-occur)
   ("d" #'eldoc-doc-buffer)
   ("h" #'my/toggle-c-h)
   ("i" #'my/indent-eglot-buffer)
   ("r" #'eglot-rename)
   ("s" #'my/create-shell-window)
   ("t" #'my/toggle-source-test)
   ("x" #'my/compile-and-execute-current-c-buffer-in-eshell)
   ) ; end of hydra
 ) ; end of init section


;;; =====================
;;; === C++, CPP, Cpp ===
;;; =====================

(my-init--with-duration-measured-section 
 t
 "C++ programming language"

 ;; === gcc in path
 
 (if (my-init--directory-exists-p *gpp-path*)
     (my-init--add-to-path-and-exec-path "gpp" *gpp-path*)
   (my-init--warning "!! *gpp-path* is nil or does not exist: %s" *gpp-path*))

 ;; === Display line number
 
 (dolist (mode '(c++-mode-hook c++-ts-mode-hook))
   (add-hook mode (lambda () (display-line-numbers-mode 1))))

 ;; === Disable auto-fill in C++ mode (to avoid break lines @ 70)

 (when nil
   (add-hook 'c++-mode-hook
             (lambda ()
               (auto-fill-mode -1)
               (setq fill-column 120))))
 ;; actually handled by eglot/clangd
 
 ;; === Babel

 ;; (C . t) is enough for C and C++
 
 ;; === switch/toggle among source, header and test files

 ;; see above (C)

 ;; === jump to main

 ;; function 'my/jump-to-c-main' defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c m") #'my/jump-to-c-main)))

 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c m") #'my/jump-to-c-main)))

 ;; === add hpp header guard

 ;; function 'my/insert-cpp-header-guard' defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c h") #'my/insert-cpp-header-guard)))

 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c h") #'my/insert-cpp-header-guard)))

 ;; === stand-alone & compile

 ;; function 'my/create-shell-window' defined above

 (defun cpp-save-compile-and-run-c-file ()
   "Compile and execute the current C++ file using g++ on Windows."
   (interactive)
   (let* ((flags "-Wall -Wextra -std=c++17 -O3")
          (source-file (buffer-file-name))
          (file-name (file-name-nondirectory source-file))
          (exe-file (concat (file-name-sans-extension file-name) ".exe"))
          (compile-command (format "g++ %s -o %s %s && %s" 
                                   flags
                                   exe-file 
                                   file-name 
                                   exe-file)))
     (if source-file
         (progn
           (save-buffer)
           (compile compile-command))
       (message "Buffer is not visiting a file!"))))

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-r") #'cpp-save-compile-and-run-c-file)))
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-r") #'cpp-save-compile-and-run-c-file)))

 ;; === stand-alone & shell

 (defun my/compile-and-execute-current-cpp-buffer-in-eshell ()
   "Save and compile current C++ file in eshell"
   (interactive)
   (save-buffer)
   (my--eshell-cd-to-directory-of-current-buffer-if-not-the-case)
   (let* (
          ;; (eshell-buffer (get-buffer "*eshell*"))
          (flags "-Wall -Wextra -std=c++17 -O3")
          (file-name (file-name-nondirectory buffer-file-name))
          (file-name-without-extension (file-name-sans-extension file-name))
          (cmd (concat "g++ " file-name " " flags " -o " file-name-without-extension " && time ./" file-name-without-extension ".exe")))
     (my--eshell-send-cmd cmd)))

 ;; === project & compile

 ;; function 'compile-makefile-project' defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-c") #'compile-makefile-project)))
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-c") #'compile-makefile-project)))

 ;; function 'compile-and-run-makefile-project' defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-m") #'compile-and-run-makefile-project)))
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-m") #'compile-and-run-makefile-project)))

 ;; function 'test-makefile-project' defined above
 
 (add-hook 'c++-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-t") #'test-makefile-project)))
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (local-set-key (kbd "C-c C-t") #'test-makefile-project)))

 ;; === my/dired-clean-build-artifacts

 ;; defined above
 
 ;; === Abbrev for C++

 ;; 'my-init--c-abbrev' is defined above

 (add-hook 'c++-mode-hook
           (lambda ()
             (my-init--c-abbrev)
             (define-abbrev c++-mode-abbrev-table "cmain" "" 'c-main-skeleton)
             (define-abbrev c++-mode-abbrev-table "cwhile" "" 'c-while-loop-skeleton)
             (define-abbrev c++-mode-abbrev-table "cfor" "" 'c-for-loop-skeleton)
             (define-abbrev c++-mode-abbrev-table "cinclude" "" 'c-include-skeleton)
             (define-abbrev c++-mode-abbrev-table "cif" "" 'c-if-skeleton)
             (define-abbrev c++-mode-abbrev-table "cifelse" "" 'c-if-else-skeleton)))
 
 (add-hook 'c++-ts-mode-hook
           (lambda ()
             (my-init--c-abbrev)
             (define-abbrev c++-ts-mode-abbrev-table "cmain" "" 'c-main-skeleton)
             (define-abbrev c++-ts-mode-abbrev-table "cwhile" "" 'c-while-loop-skeleton)
             (define-abbrev c++-ts-mode-abbrev-table "cfor" "" 'c-for-loop-skeleton)
             (define-abbrev c++-ts-mode-abbrev-table "cinclude" "" 'c-include-skeleton)
             (define-abbrev c++-ts-mode-abbrev-table "cif" "" 'c-if-skeleton)
             (define-abbrev c++-ts-mode-abbrev-table "cifelse" "" 'c-if-else-skeleton)))
 
 
 ;; === Occur

 ;; Function 'my-c-occur' is defined above.
 
 ;; === clangd

 (if (my-init--directory-exists-p *clangd-path*)
     (my-init--add-to-path-and-exec-path "clangd" *clangd-path*)
   (my-init--warning "!! *clangd-path* is nil or does not exist: %s" *clangd-path*))

 ;; === treesitter installation

 ;; (treesit-library-abi-version) --> 14 ; expects version 14

 (unless (boundp 'treesit-language-source-alist)
   (setq treesit-language-source-alist '()))
 
 (add-to-list 'treesit-language-source-alist
              '(cpp "https://github.com/tree-sitter/tree-sitter-cpp"))

 ;; M-x treesit-install-language-grammar RET c RET
 ;; and c++
 ;; to compile and install
 
 (if (my-init--file-exists-p *cpp-tree-sitter-dll*)
     ;; Remap c++-mode to c++-ts-mode (Tree-sitter version):
     (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode))
   (my-init--warning "!! cpp tree-sitter dll not found: %s" *cpp-tree-sitter-dll*))
 
 ;; === lsp (alternative to eglot)

 ;; void
 
 ;; === Eglot (alternative to lsp)

 (if (my-init--file-exists-p *gpp-exe*)
     (with-eval-after-load 'eglot
       (add-to-list
        'eglot-server-programs
        `((c++-mode c-mode)
          "clangd"
          ,(concat "--query-driver=" *gpp-exe*))))
   (my-init--warning "!! g++.exe not found: %s" *gpp-exe*))

 (add-hook 'c++-mode-hook 'eglot-ensure)
 (add-hook 'c++-ts-mode-hook 'eglot-ensure)

 ;; use-package eglot
 ;; see C above
 
 ;; use-package company
 ;; see C above
 
 ;; === Indentation
 
 (add-hook 'c++-mode-hook
           (lambda ()
             (c-set-style "stroustrup")
             (setq c-basic-offset 4)))

 ;; already stated elsewhere in this file:
 ;; (setq-default indent-tabs-mode nil)

 ;; normally default:
 ;; (global-font-lock-mode t)

 ;; function my/indent-eglot-buffer defined above

 ;; === hideshow

 (when t
   (add-hook 'c++-ts-mode-hook 'hs-minor-mode)
   (add-hook 'c++-mode-hook 'hs-minor-mode)
   
   (setq hs-hide-comments-when-hiding-all t)
   (setq hs-isearch-open t) ; Automatically open folded code during isearch

   ;; Key bindings
   (global-set-key (kbd "C-c f t") 'hs-toggle-hiding)
   (global-set-key (kbd "C-c f r") 'hs-hide-level-recursive)
   (global-set-key (kbd "C-c f s") 'hs-show-block)
   (global-set-key (kbd "C-c f h") 'hs-hide-block)
   (global-set-key (kbd "C-c f S") 'hs-show-all)
   (global-set-key (kbd "C-c f H") 'hs-hide-all))

 ;; === alternative: ts-fold (not available with use-package)

 ;; void
 
 ;; === expand-region

 ;; expand-region package already loaded in lisp section

 ;; === imenu list in side bar

 ;; imenu-list package already loaded in lisp section
 
 ;; === yasnippet... no since abbrev

 (when nil
   (use-package yasnippet
     :ensure t
     :config
     (yas-global-mode 1)))

 ;; === C++ hydra
 
 (defhydra hydra-cpp (:exit t :hint nil)
   "
^C++ hydra:
^----------
FILES: _h_: switch between source and header files | _t_: switch between source and test files
       C-c m jump to main | C-c h insert h/hpp header guard
MOVEMENT:
   move among top-level expressions + select: C-M-a, C-M-e C-M-h
   forward/backward expression: C-M-f, C-M-b
   next/previous sibling C-M-n, C-M-p
   up/down in tree C-M-u C-M-d
JUMP TO TOP-LEVEL EXP: _c_ : occur | M-x imenu | C-' (list in sidebar)
SELECT: select sexp: C-= (expand-region)
MANIPULATE EXP: [...]
COLLAPSE: hideshow : C-c f h / s / t : hide / show / toggle current block
                     C-c f H / S     : hide / show all
MACROS: [...]
INDENT: _i_ndent (eglot-format-buffer)
COMMENT: M-; for end of line or selection | C-x C-; for line | M-x comment-region | M-x uncomment-region
DOCUMENTATION: bottom of screen (automatic) and more with _d_ (M-x eldoc-doc-buffer) or C-h .
REFERENCES: M-. M-, : goto function/variable definition, and back (xref-find-definitions via eglot)
            M-? : find all references (xref-find-references via eglot)
ABBREV: [...]
COMPLETE: C-M-i   completion (eglot)
REFACTOR: _r_efactor symbol at point (eglot-rename) | [projectile]
EXECUTE:
   ONE FILE with compile: C-c C-r: save, compile and run (g++ ...)
   ONE FILE with shell: _s_ : show eshell
                        _x_ : compile & execute in shell (g++ ...)
   PROJECT with M-x compile: C-c C-c, compile project
                             C-c C-m, save compile and run (M-x compile > make && make run)
                             C-c C-t, save and test (M-x compile > make test)
   PROJECT with projectile: compile : C-c p c c > make, make run, make test
                            execute : C-c p u   > make run
DEBUG: C-c a to implement eglot proposed action / correction (eglot-code-actions) | C-h . to access to overlaid eglot/clangd warning
CLEAN: my/dired-clean-build-artifacts (before resynchronization of Dropbox)
SPECIFIC: M-x eglot-shutdown | M-x eglot-reconnect
{end}"
   ("c" #'my-c-occur)
   ("d" #'eldoc-doc-buffer)
   ("h" #'my/toggle-c-h)
   ("i" #'my/indent-eglot-buffer)
   ("r" #'eglot-rename)
   ("s" #'my/create-shell-window)
   ("t" #'my/toggle-source-test)
   ("x" #'my/compile-and-execute-current-cpp-buffer-in-eshell)
   
   ) ; end of hydra
 ) ; end of init section

;;; ===
;;; ===========================
;;; ===== MAXIMA LANGUAGE =====
;;; ===========================

(my-init--with-duration-measured-section 
 t
 "Maxima language"

 (if (my-init--directory-exists-p *maxima-directory*)
     (my-init--add-to-path-and-exec-path "Maxima" *maxima-directory*)
   (my-init--warning "!! *maxima-directory* is nil or does not exist: %s" *maxima-directory*))

 ;; reference: https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-maxima.html

 ;; Babel:
 (defun my--org-babel-load-maxima (&rest _args)
   (message "Preparing org-mode babel for maxima...")
   (add-to-list 'org-babel-load-languages '(maxima . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-maxima))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-maxima)

 ) ; end of init section


;;; ===
;;; ===========================
;;; ===== PYTHON LANGUAGE =====
;;; ===========================

(my-init--with-duration-measured-section 
 t
 "Python language"

 ;; see "PYTHON IN PATH" above
 
 (use-package elpy
   :mode ("\\.py\\'" . python-mode)
   :config (elpy-enable)
   (my-init--message-package-loaded "elpy"))

 ;; Babel:
 (defun my--org-babel-load-python (&rest _args)
   (message "Preparing org-mode babel for python...")
   (add-to-list 'org-babel-load-languages '(python . t))
   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
   (advice-remove 'org-babel-execute-src-block #'my--org-babel-load-python))

 (advice-add 'org-babel-execute-src-block
             :before #'my--org-babel-load-python)

 ;; \/\/ or choose 'main' Python
 (if (my-init--file-exists-p *python-executable--in-libreoffice-for-unoconv*)
     (progn
       (setq python-shell-interpreter *python-executable--in-libreoffice-for-unoconv*)
       (setq org-babel-python-command (format "\"%s\"" *python-executable--in-libreoffice-for-unoconv*)))
   (my-init--warning "!! *python-executable--in-libreoffice-for-unoconv* is nil or does not exist: %s" *python-executable--in-libreoffice-for-unoconv*))
 
 (defhydra hydra-python (:exit t :hint nil)
   "
^Python hydra:
^-------------

C-c C-p to launch REPL
C-c C-c to compile and execute within REPL

(end)
"
   ;; ("d" #'a-function)
   )
 
 ) ; end of init section


;;; ===
;;; ==================
;;; ===== SCILAB =====
;;; ==================

;;; no interface with Emacs?


;;; ===
;;; =====================================
;;; ===== THUNDERBIRD AND EML FILES =====
;;; =====================================

(my-init--with-duration-measured-section 
 t
 "Thunderbird and EML files"

 (defun eml-add-date-at-beginning-of-eml-file ()
   "Add date at the beginning of eml file in dired.
(v2, available in occisn/emacs-utils GitHub repository)"
   (interactive)

   (cl-labels ((replace-linux-slash-with-two-windows-slashes (path)
                 "Return PATH string after having replaced slashes by two backslashes.
For instance: abc/def --> abc\\def"
                 (replace-regexp-in-string  "/" "\\\\" path))
               (english-month-to-number (month)
                 "Jan --> 1, Dec --> 12"
                 (cond ((equal "Jan" month) 1)
                       ((equal "Feb" month) 2)
                       ((equal "Mar" month) 3)
                       ((equal "Apr" month) 4)
                       ((equal "May" month) 5)
                       ((equal "Jun" month) 6)
                       ((equal "Jul" month) 7)
                       ((equal "Aug" month) 8)
                       ((equal "Sep" month) 9)
                       ((equal "Oct" month) 10)
                       ((equal "Nov" month) 11)
                       ((equal "Dec" month) 12)
                       (t (error "Month not recognized: %s" month))))) ; end of labels definitions
     
     (when (not (string-equal major-mode "dired-mode"))
       (error "Trying to burst a PDF file when not in dired-mode."))
     (when (> (length (dired-get-marked-files)) 1)
       (error "Trying to add dates at the beginning of several files."))
     
     (let* ((files-list (dired-get-marked-files))
            (file-full-name (car files-list))
            (file-full-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-full-name))
            (file-directory (file-name-directory file-full-name))
            (file-name (file-name-nondirectory file-full-name))
            (file-name-slash-OK-accents-OK (replace-linux-slash-with-two-windows-slashes file-name))
            ;; (file-name-without-extension (file-name-base file-full-name))
            (date-line nil))
       (when (not (or (string= (file-name-extension file-full-name) "eml") (string= (file-name-extension file-full-name) "EML") ))
         (error "Trying to extract date from a non-EML fil: %S" file-full-name))
       (with-temp-buffer
         (insert-file-contents file-full-name-slash-OK-accents-OK)
         (goto-char (point-min))
         (search-forward "Date:")
         (set-mark-command nil)
         (end-of-line)
         (setq date-line (buffer-substring (region-beginning) (region-end))))
       (when (null date-line)
         (error "No 'Date:' line found in file %s" file-name-slash-OK-accents-OK))
       (let ((elements (split-string date-line)))
         (when (< (length elements) 4)
           (message "Not enough elements on DATE-LINE: %s" date-line)
           (message "   New attempt...")
           (with-temp-buffer
             (insert-file-contents file-full-name-slash-OK-accents-OK)
             (goto-char (point-min))
             (search-forward "Date:")
             (search-forward "Date:")
             (set-mark-command nil)
             (end-of-line)
             (setq date-line (buffer-substring (region-beginning) (region-end))))
           (when (null date-line)
             (error "No *2nd* 'Date:' line found in file %s" file-name-slash-OK-accents-OK))
           (setq elements (split-string date-line))
           (when (< (length elements) 4)
             (error "On 2nd attemp, not enough elements on DATE-LINE: %s" date-line)))
         (let* ((day (string-to-number (nth 1 elements)))
                (month (nth 2 elements))                 ; Jan...Dec
                (month2 (english-month-to-number month)) ; 1...12
                (year (string-to-number (nth 3 elements)))
                (yyyy-mm-dd (format "%04d-%02d-%02d" year month2 day))
                (file1-old-name file-name)
                (file1-new-name (concat file-directory yyyy-mm-dd " _" file1-old-name)))
           
           (rename-file file1-old-name file1-new-name)
           (message "Date (%s) added at the beginning of file '%s'" yyyy-mm-dd file1-old-name)
           (revert-buffer)
           (dired-goto-file file1-new-name)))))) ; end of defun
 
 ) ; end of init section


;;; ===
;;; ================
;;; ===== EPUB =====
;;; ================

(my-init--with-duration-measured-section 
 t
 "epub"

 (use-package nov
   ;; :mode ("\\.epub\\'" . nov-mode)
   :hook (nov-mode . nov-mode)
   :init (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
   :config (my-init--message-package-loaded "nov (for epub)"))
 ;; https://tech.toryanderson.com/2022/11/23/viewing-epub-in-emacs/
 ;; https://lucidmanager.org/productivity/reading-ebooks-with-emacs/


 (defhydra hydra-nov (:exit t :hint nil)
   "
^Nov (epub) hydra:
^-----------------

t: go Table of contents
n and p or [ and ]: Next or previous chapter
q: Quit the ebook reader
?: Help file with list of other keyboard shortcuts

To increase or decrease the text, use the C-x C-+ and C-c C-- shortcuts. To reset the length of the lines, press g to re-render the document.

Opening the file as an archive with the a key shows the document's structure.
From here, you can also copy images from the book with the C keyboard shortcut
"
   )

 ;; ??? https://www.gnu.org/software/emacs/manual/html_node/emacs/Document-View.html

 ) ; end of init section


;;; ===
;;; ==============================
;;; ===== PERSONAL FUNCTIONS =====
;;; ==============================

(my-init--with-duration-measured-section 
 t
 "Some personal functions"

 (defun my/activate-Commun-projectile ()
   "Activate 'Commun' directory with projectile."
   (interactive)
   (if (not (my-init--directory-exists-p *my-commun-directory*))
       (message "Unable to locate Commun directory: %s" *my-commun-directory*)
     (let ((projectile-file (concat *my-commun-directory* ".projectile")))
       (if (not (my-init--file-exists-p projectile-file))
           (message "Unable to find Commun projectile file: %s" projectile-file)
         (progn
           (find-file projectile-file)
           (kill-buffer (current-buffer))
           (dired *my-commun-directory*))))))

 ) ; end of init section

;;; ===
;;; ======================
;;; === WORK FUNCTIONS ===
;;; ======================

(my-init--with-duration-measured-section 
 t
 "Some work functions"

 (defun my/signature ()
   (interactive)
   "Copy my signature in clipboard."
   
   (cl-labels ((insert-string-in-clipboard (str)
                 "Insert STR (a string) in clipboard.
(v1, available in occisn/emacs-utils GitHub repository)"
                 (with-temp-buffer
                   (insert str)
                   (clipboard-kill-region (point-min) (point-max)))))

     (insert-string-in-clipboard *my-signature*)
     (message "IMT Signature available in clipboard")))

 (defun pro1/open-app1 ()
   "Open APP1, provided that frmservletXXX.jnlp exists in DOWNLOAD directory"
   (interactive)
   (let ((possible-files (directory-files *downloads-directory* nil "frmservlet.*" nil)))
     (when (null possible-files)
       (error "No file beginning with 'frmservlet' in downloads directory"))
     (let* ((target-file1
             (if (= 1 (length possible-files))
                 (car possible-files)
               (cadr (reverse possible-files))))
            (target-file2 (concat *downloads-directory*
                                  target-file1))
            (cmd (concat "\"" target-file2 "\"")))
       (message "Opening %s..." target-file2)
       (call-process-shell-command cmd nil t))))



 ) ; end of init section


;;; ===
;;; ====================
;;; ===== MARKDOWN =====
;;; ====================

(my-init--with-duration-measured-section 
 t
 "markdown"

 ;; https://jblevins.org/projects/markdown-mode/

 (if (my-init--directory-exists-p *pandoc-directory*)
     (my-init--add-to-path-and-exec-path "Pandoc" *pandoc-directory*)
   (my-init--warning "!! pandoc directory is nil or does not exist: %s" *pandoc-directory*))
 
 (use-package markdown-mode
   :mode ("\\.md\\'" . markdown-mode)
   :config
   (my-init--message-package-loaded "markdown-mode")
   (setq markdown-command *pandoc-executable-name*))

 (defun my/md-convert-region-to-anchor-and-kill ()
   "Convert current '## a b c' headline into #a-b-c anchor ready to be pasted."
   (interactive)
   (aprogn
    (beginning-of-line)
    (call-interactively 'set-mark-command)
    (end-of-line)
    (buffer-substring-no-properties (region-beginning) (region-end))
    (substring it 3)                    ; delete '## '
    (downcase it)
    (string-replace ":" "" it)
    (string-replace " " "-" it)
    (concat "#" it) 
    (progn
      (call-interactively 'set-mark-command)
      (kill-new it)
      (message "Ready to be yanked: %s" it))))

 (defhydra hydra-markdown (:exit t :hint nil)
   "
^Markdown hydra:
^--------------

preview in emacs (eww) : C-c C-c l
preview in browser : C-c C-c p

M-x my/md-convert-region-to-anchor-and-kill 

_3_ : copy from markdown to clipboard, under org-mode format

(end)
"
   ("3" #'my/markdown-region-to-org-clipboard)
   )
 
 ) ; end of init section


;;; ===
;;; ==================
;;; ===== IMAGES =====
;;; ==================

;;; void


;;; ===
;;; ==================
;;; ===== SERVER =====
;;; ==================

(my-init--with-duration-measured-section 
 t
 "server"

 ;; Start Emacs server if not already running
 (when nil
   (require 'server)
   (unless (server-running-p)
     (server-start)))

 ;; Actually I have not managed to open an .org file from Windows Explorer by double-click.
 ;; Some tricks allows managing spaces in filename, but not accents.
 ;; So server is not really needed.

 ;; However, we can open an .org file from Windows Explorer by drag-and-drop into Emacs.
 
 ) ; end of init section


;;; ===
;;; =========================
;;; ======= ERT TESTS =======
;;; =========================

(my-init--with-duration-measured-section 
 t
 "ERT tests"

 (defun my/launch-tests ()
   "Launch ERT tests associated to init files."
   (interactive)
   (ert '(tag init)))

 (ert-deftest example ()
   :tags '(example)
   (should (= 4 (+ 2 2))))

 ) ; end of init section

;;; ===
;;; ====================
;;; === PROFESSIONAL ===
;;; ====================

(my-init--with-duration-measured-section 
 t
 "Professional"

 (defhydra hydra-professional (:exit t :hint nil)
   "
^void
")

 (my-init--load-additional-init-file "personal--professional.el")
 
 ) ; end of init section



;;; ===
;;; ============================
;;; === THREE GENERAL HYDRAS ===
;;; ============================

(my-init--with-duration-measured-section 
 t
 "Three general hydras"

 ;; (1) General hydra

 (defhydra hydra-general (:exit t :hint nil)
   "
^General hydra:
^---------------
Go: _d_: open _d_ownloads directory        | _e_: open _e_n-cours (on-going) directory
    _x_: open Dropbo_x_ directory in dired | _m_: ielm
    _s_: open pro1 App1                    | _l_: local-repos
Speedbar: M-x speedbar (b/f = buffers/files, U to go up, SPC)
Recent files : C-x C-r | recent directories : C-u C-x C-r | frequent files with function keys
Frame: C-x 5 c to clone current frame in another | C-x 5 2 or 'M-x make-frame' for new frame | C-x 5 0 to close frame
Window: C-x + to equalize windows | C-x - to swap 
Buffers: _f_: (_f_rom) open dired buffer corresponding to Windows path copied to clipboard
         C-x 3 | C-x o                      C-l to center buffer
         C-x C-j: dired-jump (dired-x) | C-x C-h: kill buffer and dired jump
         C-x m: kill buffer on other window    |||   C-x LEFT et C-x RIGHT to cycle among buffers
         C-h e displays *Messages* buffer      |||   C-x C-b then d and x to close some
         my/kill-all-file-buffers ; my/kill-all-buffers-except-stars
Find and grep --> dired hydra or _P_roject hydra
Mini-buffer : C-q C-j to go to a new line | ivy : ~C-M-j~ to force
Text: _k_: show kill ring (xah-show-kill-ring) | To search and insert Unicode: C-x 8 RET or M-x counsel-unicode-char
      M-LEFT et M-RIGHT to move by word (except in org-mode : C-LEFT et C-RIGHT) | C-DEL (M-d) et C-BACKSPACE (M-DEL) to delete words
      C-c C-SPACE ace jump         | M-< ou M-> [shift] to go to beginning/end of buffer
      search in file: C-s or M-x occur [ C-u C-s for native search ]
      M-x replace-regexp (example: ^abc.*$) 
      get rid of strange highlighting: Alt-'mouse left clic' | problem read-only : M-x read-only-mode
Repeat command: M-x M-p | C-x z | C-x M-:     History of commands: C-h l
Macros : F3 and F4 | M-x kmacro-name-last-macro gives a name to the last defined macro | M-x insert-kbd-macro inserts its definition at point
         repeat macro until error (M-0 C-x e) = my/repeat-macro-until-error | register store C-x C-k x r (kmacro-to-register) | call C-x r j r
Packages: M-x package-install                 | C-x M-: repeat last M-x
Tests: ERT _t_ests associated with init files (my/launch-tests)
Other hydras: _A_ppearance, _F_onts, _T_hemes, _H_elp & documentation, _M_ode-dependent (C-c d), _P_roject (C-c p h), _W_indows (C-c w),, _I_=professional _S_hells, Mails (C-c m)
Undo : C-j to cut undo chain? {end}
"
   ;; ("c" #'my/ready-to-calc) ;; to remove
   ("d" #'my/open-downloads-directory-in-dired) ; ?
   ("e" #'my/open-ongoing-directory-in-dired)
   ("f" #'my/dired-open-path-in-clipboard)
   ("k" #'xah-show-kill-ring)
   ("l" #'my/open-local-repos-directory-in-dired)
   ("m" #'ielm)
   ("p" #'package-list-packages) 
   ;; ("r" #'my/ready-to-move-from-downloads)
   ("s" #'pro1/open-app1)
   ("t" #'my/launch-tests)
   ("x" #'my/open-dropbox-directory-in-dired)
   ;; --
   ("A" #'hydra-appearance/body)
   ("F" #'my/generate-personal-font-buffer)
   ("H" #'hydra-help/body)
   ("I" #'hydra-professional/body)
   ("M" #'context-hydra-launcher)
   ("P" #'hydra-project/body)
   ("S" #'hydra-shells/body)
   ("T" #'my/generate-personal-theme-buffer)
   ("W" #'hydra-windows-executables/body))

 (global-set-key (kbd "C-c g") #'hydra-general/body)

 ;; (2) no-specific-hydra hydra

 (defhydra hydra-no-specific-hydra (:exit t :hint nil) ;  :columns 1)
   "
^No hydra associated with this mode
"
   )

 ;; (3) mode-dependent hydra launcher

 (defun context-hydra-launcher ()
   "Launch hydra according to context."
   (interactive)
   (cond
    ((eql major-mode 'c-mode) (hydra-c/body))
    ((eql major-mode 'c-ts-mode) (hydra-c/body))
    ((eql major-mode 'c++-mode) (hydra-cpp/body))
    ((eql major-mode 'c++-ts-mode) (hydra-cpp/body))
    ((eql major-mode 'calc-mode) (hydra-calc/body))
    ((eql major-mode 'compilation-mode) (hydra-compilation/body))
    ((eql major-mode 'csv-mode) (hydra-csv/body))
    ((eql major-mode 'dired-mode) (hydra-dired/body))
    ((eql major-mode 'doc-view-mode) (hydra-docview/body))
    ((eql major-mode 'emacs-lisp-mode) (hydra-emacs-lisp/body))
    ((eql major-mode 'gnuplot-mode) (hydra-gnuplot/body))
    ((eql major-mode 'ielm-mode) (hydra-ielm/body))
    ((eql major-mode 'latex-mode) (hydra-latex/body))
    ((eql major-mode 'lisp-mode) (hydra-common-lisp/body))
    ((eql major-mode 'magit-diff-mode) (hydra-magit-diff/body))
    ((eql major-mode 'magit-status-mode) (hydra-magit-status/body))
    ((eql major-mode 'markdown-mode) (hydra-markdown/body))
    ((eql major-mode 'nov-mode) (hydra-nov/body))
    ((eql major-mode 'org-mode) (hydra-org-mode/body))
    ((eql major-mode 'plain-tex-mode) (hydra-tex/body))
    ((eql major-mode 'python-mode) (hydra-python/body))
    ((eql major-mode 'slime-repl-mode) (hydra-slime-repl/body))
    ((eql major-mode 'ses-mode) (hydra-ses/body))
    ((eql major-mode 'sql-mode) (hydra-sql/body))
    ((eql major-mode 'tex-mode) (hydra-latex/body))
    (t (hydra-no-specific-hydra/body))))
 ;; Inspired by https://dfeich.github.io/www/org-mode/emacs/2018/05/10/context-hydra.html

 (global-set-key (kbd "C-c d") #'context-hydra-launcher)
 
 ) ; end of init section


;;; ===
;;; ==========================
;;; ===== END OF STARTUP =====
;;; ==========================

(my-init--with-duration-measured-section 
 t
 "End of startup"

 ;; (disabled) Package loadhist to know which package depends on deprecated cl package
 ;; in case "Package cl is deprecated":
 (when nil
   (use-package loadhist
     :config
     (my-init--message-package-loaded "loadhist")
     (message "Message \"Package cl is deprecated\" is due to following packages: %s" (file-dependents (feature-file 'cl)))))

 ;; Reverse start-up tricks:
 (when (boundp 'init--file-name-handler-alist-original)
   (setq file-name-handler-alist init--file-name-handler-alist-original)
   (makunbound 'init--file-name-handler-alist-original))

 ;; Make Emacs more responsive
 (setq gc-cons-threshold (* 2 1000 1000))
 (setq gc-cons-threshold 100000000) ; 100 MB before garbage collection
 (setq read-process-output-max (* 1024 1024)) ; 1mb
 (my-init--message2 "Garbage collector threshold set at %s." gc-cons-threshold)
 
 ) ; end of init section

;;; ===
;;; =======================================
;;; ===== DISPLAY DURATION AND ERRORS =====
;;; =======================================

(my-init--with-duration-measured-section 
 t
 "Display duration and errrors"

 ;; (disabled) Eyebrowse shall be loaded at the end, to override org-mode bindings
 ;; (my-init--load-eyebrowse)
 
 (defun my-init--extract-packages-durations-from-messages-buffer (regexp)
   ""
   (let ((buffer "*Messages*")
         (matches nil))
     (save-match-data
       (save-excursion
         (with-current-buffer buffer
           (save-restriction
             (widen)
             (goto-char 1)
             (while (search-forward-regexp regexp nil t 1)
               (push (cons (match-string 1) (* 1000 (string-to-number (match-string 2)))) matches)))))
       (sort matches (lambda (a b) (> (cdr a) (cdr b)))))))
 ;; inspired by: https://emacs.stackexchange.com/questions/7148/get-all-regexp-matches-in-buffer-as-a-list

 (defvar *packages-configuring-durations*
   (my-init--extract-packages-durations-from-messages-buffer "^Configuring package \\(.*\\)...done (\\(.*\\)s)$"))
 
 (defvar *packages-loading-durations*
   (my-init--extract-packages-durations-from-messages-buffer "^Loading package \\(.*\\)...done (\\(.*\\)s)$"))
 
 ) ; end of init section


;;; ===
;;; ============================
;;; ===== EXPERIMENTATIONS ===== 
;;; ============================

(my-init--with-duration-measured-section 
 t
 "Experimentations"

 (my-init--load-additional-init-file "personal--experimentations.el")
 
 ) ; end of init section

;;; ===
;;; ====================
;;; === THE VERY END ===
;;; ====================


(my-init--message2 "[ very last line of init.el ]")

;;; the very end
