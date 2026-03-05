;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; =================
;;; ===== MAGIT =====
;;; =================

(my-init--with-duration-measured-section 
 t
 "Magit"

 ;; M-x magit-version to test

 (if *my-init--windows-p*
     ;; Windows: add Git to PATH (on Linux, git is natively in PATH)
     (progn
       (if (my-init--directory-exists-p *git-executable-directory*)
           (my-init--add-to-path-and-exec-path "Git" *git-executable-directory*)
         (my-init--warning "!! *git-executable-directory* is nil or does not exist: %s" *git-executable-directory*))

       (let ((diff3-executable (concat *git-diff3-directory* "/diff3.exe")))
         (if (my-init--file-exists-p diff3-executable)
             (add-to-list 'exec-path *git-diff3-directory*)
           (my-init--warning "!! (magit) diff3.exe not found within %s" *git-diff3-directory*))))
   (my-init--message2 "Git: assuming git and diff3 are available in PATH"))
 ;; (setq ediff-diff3-program "C:/portable-programs/Git/usr/bin/diff3.exe")
 
 (if (>= emacs-major-version 28)
     (use-package magit
       :bind (("C-x g" . magit-status)
              ("C-x C-g" . magit-status))
       :config (my-init--message-package-loaded "magit"))
   (my-init--warning "Could not use package magit since emacs version is not >= 28"))

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



;;; end of init--magit.el
