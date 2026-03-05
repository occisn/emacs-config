;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

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



;;; end of init--tests.el
