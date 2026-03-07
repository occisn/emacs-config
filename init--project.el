;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ===================================
;;; ===== PROJECT AND PROJECTILE ===== 
;;; ==================================

(my-init--with-duration-measured-section
 t
 "Project and Projectile A (projectile)"

 ;; if a newly created .projectile file is not recognized,
 ;; try discovering the project explicitly:
 ;;        M-x projectile-discover-projects-in-directory
 
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
                                     (unless (null tags-string1)
                                       (cl-loop for tag0 in (split-string tags-string1 " ")
                                                do
                                                (unless (member tag0 tags-list)
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
                                     (unless (null tags-string1)
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
- C-c p b    project buffers open
- C-c p o    multi-occur ; mais uniquement sur les buffers ouverts
- C-c p D    open root in dired (idem C-p p modifié)
- C-c p e    recently-visited project file (not enabled?)
- C-c p ESC  switch to the most recently selected Projectile buffer.
- [a] list of projets (~/.emacs.d/projectile-bookmarks.eld)

Find:
- C-c p d
- C-c p f

Git : C-x g to access the status buffer

FILETAGS:
- [t]: my/find-file-with-given-filetag
- [l]: my/list-all-filetags-in-project

Grep :
- with ag: C-c p s s [then C-c to to show in another window]
           M-x projectile-ag (show in another window)
           a[g] / grep in projectile project (pb encoding ?)
- with ripgrep: C-c p s r [then C-c o to show in another window]
                M-x projectile-ripgrep [does not seem to work]
- projectile-[p]t (M-x projectile-pt)
- my projectile [s]earch (pb accents)
- [x]ah / grep in projectile project
- C-c p s g  (grep by pt ?)

Search & replace:
- C-c p r : search and replace (Y to approve all)"
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
   (unless (string= major-mode "dired-mode")
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
                                 (unless (string= current-dir dir1)
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
   (unless (string= major-mode "dired-mode")
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
   
   (unless (string= major-mode "dired-mode")
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
                                 (unless (string= current-dir dir1)
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

 ;;  Install ripgrep & add to path
 ;; -
 ;; 1) winget install BurntSushi.ripgrep.MSVC 
 ;; 2) relancer shell
 ;; 3) ~rg --version~

 (if (>= emacs-major-version 28)
     (use-package rg
       :commands (projectile-ripgrep)
       :config
       (my-init--message-package-loaded "rg"))
   (my-init--warning "Could not use package rg since emacs version is not >= 28"))
 
 ) ; end of init section



;;; end of init--project.el
