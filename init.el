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

(defvar *my-init--windows-p* (eq system-type 'windows-nt)
  "Non-nil when running on Windows.")

(defvar *my-init--linux-p* (eq system-type 'gnu/linux)
  "Non-nil when running on GNU/Linux (including WSL).")

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
For instance: abc/def --> abc\\def.
On Linux, returns PATH unchanged since backslashes are not needed."
   (if *my-init--windows-p*
       (replace-regexp-in-string  "/" "\\\\" path)
     path))

 (ert-deftest my-init--replace-linux-slash-with-two-windows-slashes ()
   :tags '(init)
   (if *my-init--windows-p*
       (should (string= "abc\\def" (my-init--replace-linux-slash-with-two-windows-slashes "abc/def")))
     (should (string= "abc/def" (my-init--replace-linux-slash-with-two-windows-slashes "abc/def")))))) ; end of init section

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
   (unless (string= major-mode "dired-mode")
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
   (unless (string= major-mode "dired-mode")
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
   (unless (string= major-mode "dired-mode")
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
   (unless (string= major-mode "dired-mode")
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
                          (unless (null zip-files-and-sizes)
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
   (unless (string= major-mode "dired-mode")
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
                                 (unless (string= current-dir dir1)
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
       *pandoc-executable-name* (if *my-init--windows-p* "pandoc.exe" "pandoc")

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
        (insert (format "Current font: %s (within %s available mono fonts)\n" (my-init--default-font) (length (delete-dups (mapcar #'car *my-mono-available-fonts*)))))
        
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

 ;; Avoid freezing at start-up (Windows-only variable):
 (when *my-init--windows-p*
   (setq w32-get-true-file-attributes nil))

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
;;; ====================================
;;; === LOAD MODULES (split init.el) ===
;;; ====================================

(my-init--with-duration-measured-section
 t
 "Loading modules (split init.el)"

 (my-init--load-additional-init-file "init--core.el")
 (my-init--load-additional-init-file "init--appearance.el")
 (my-init--load-additional-init-file "init--text.el")
 (my-init--load-additional-init-file "init--org.el")
 (my-init--load-additional-init-file "init--calc.el")
 (my-init--load-additional-init-file "init--shells.el")
 (my-init--load-additional-init-file "init--dired.el")
 (my-init--load-additional-init-file "init--completion.el")
 (my-init--load-additional-init-file "init--project.el")
 (my-init--load-additional-init-file "init--lang-lisp.el")
 (my-init--load-additional-init-file "init--documents.el")
 (my-init--load-additional-init-file "init--external-tools.el")
 (my-init--load-additional-init-file "init--network.el")
 (my-init--load-additional-init-file "init--lang-sql.el")
 (my-init--load-additional-init-file "init--lang-gnuplot.el")
 (my-init--load-additional-init-file "init--lang-json-yaml.el")
 (my-init--load-additional-init-file "init--lang-latex.el")
 (my-init--load-additional-init-file "init--lang-c.el")
 (my-init--load-additional-init-file "init--lang-cpp.el")
 (my-init--load-additional-init-file "init--lang-python.el")
 (my-init--load-additional-init-file "init--lang-r.el")
 (my-init--load-additional-init-file "init--lang-maxima.el")
 (my-init--load-additional-init-file "init--lang-scilab.el")
 (my-init--load-additional-init-file "init--lang-dax.el")
 (my-init--load-additional-init-file "init--magit.el")
 (my-init--load-additional-init-file "init--hydras.el")
 (my-init--load-additional-init-file "init--tests.el")

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
