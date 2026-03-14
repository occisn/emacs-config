;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

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
         (my-init--message2 "No need to add %s to %s environment variable since already in: %s" prog-name envt-variable-name directory)
       (setenv envt-variable-name (concat directory (if *my-init--windows-p* ";" ":") envt-variable-content))
       (my-init--message2 "%s is added to %s environment variable." prog-name envt-variable-name))))

 (defun my-init--add-to-path (prog-name directory)
   "Add DIRECTORY corresponding to PROG-NAME to 'PATH' environment variable.
DIRECTORY may have a final slash"
   (my/add-to-environment-variable "PATH" prog-name directory))

 (defun my-init--add-to-exec-path (prog-name directory)
   "Add DIRECTORY corresponding to PROG-NAME to exec-path."
   (if (member directory exec-path)
       (my-init--message2 "No need to add %s to exec-path since already in: %s" prog-name directory)
     (add-to-list 'exec-path directory)
     (my-init--message2 "%s is added to exec-path." prog-name)))

 (defun my-init--add-to-path-and-exec-path (prog-name directory)
   "Add DIRECTORY corresponding to PROG-NAME to 'PATH' and exec-path.
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

 (when *my-init--windows-p*
   (defun my-init--open-windows-executable (exe-name exe-path)
     "Open Windows executable EXE-NAME located at EXE-PATH.
First check that the path is correct."
     (unless (my-init--file-exists-p exe-path)
       (error (concat "Impossible to open " exe-name " from Emacs, since no path is known")))
     (message (concat "Opening " exe-name " from Emacs"))
     (call-process-shell-command exe-path nil 0)))

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

M-x list-[c]olors-display

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

 ;; in order <enter> key of righ-hand-side numerical keypad to behave as main <return> key:
 (define-key key-translation-map (kbd "<enter>") (kbd "<return>"))
 (define-key key-translation-map (kbd "C-<enter>") (kbd "C-<return>"))
 (define-key key-translation-map (kbd "M-<enter>") (kbd "M-<return>"))

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

 (if (>= emacs-major-version 28)
     (use-package keycast
       :commands (keycast-mode)
       :config (my-init--message-package-loaded "keycast"))
   (my-init--warning "Could not use package keycast since emacs version is not >= 28"))

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
   (setq coding-system-for-read (if *my-init--windows-p* 'utf-8-dos nil))
   (my-init--message2 "Encoding: coding-system-for-read was %s and is now %s" tmp coding-system-for-read))
 ;; crucial for FIND et projectile
 ;; Specify the coding system for read operations.

 ;; to solve the problem encountered with doc-view related to accent in file name: 
 (let ((tmp (if (boundp 'default-process-coding-system) default-process-coding-system "UNBOUND")))
   (setq default-process-coding-system (if *my-init--windows-p* '(utf-8 . latin-1) '(utf-8 . utf-8)))
   (my-init--message2 "Encoding: default-process-coding-system was %s and is now %s" tmp default-process-coding-system))
 ;; (setq default-process-coding-system '(utf-8 . latin-1)) ; cp1252-dos cp850-dos
 ;; (setq file-name-coding-system 'latin-1)
 ;; (setq default-process-coding-system '(utf-8-dos . cp1251-dos))
 ;; (setq default-process-coding-system '(utf-8 . cp1251-dos))
 ;; the above allows 'my-init--open-with-external-program' (Sumatra, Irfan, ...), unzip, pdf to work properly
 ;;     without 'encode-filename-or-directory-for-cmd' just below

 (when *my-init--windows-p*
   (defun my-init--encode-filename-or-directory-for-cmd (file-name)
     "Return FILE-NAME (which can also be a directory or a path) in an encoding which allows injecting in cmd"
     (encode-coding-string file-name 'latin-1))

   (defun my-w32explore-fix-encoding (orig-fun &rest args)
     "Solve the issue with Ctrl-RET in dired, which was not able to open directory when accents in path.
This advice changes the encoding of the argument given to w32explore function in w32-browser.el, which calls shell-execute"
     (let* ((file-name (car args))
            (file-name-with-fixed-encoding (my-init--encode-filename-or-directory-for-cmd file-name)))
       (apply orig-fun file-name-with-fixed-encoding (cdr args))))
   (advice-add 'w32explore :around #'my-w32explore-fix-encoding))

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



;;; end of init--core.el
