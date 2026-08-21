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
     (message "Signature available in clipboard")))

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

 ;; Start Emacs server if not already running.
 ;;
 ;; Beware: `server-running-p' is NOT a liveness test for *this* Emacs.
 ;; On Windows `server-use-tcp' is t, so it does not connect to anything: it
 ;; merely reads the connection file <server-auth-dir>/<server-name>
 ;; (here C:/portable-programs/emacs-30.2/.emacs.d/server/server), and returns
 ;; t as soon as *some* process owns the PID recorded in that file -- without
 ;; ever checking that this process is an Emacs.
 ;; So when Emacs is killed instead of exiting cleanly, the file survives with
 ;; a dead PID; Windows recycles PIDs quickly (merely starting WSL spawns
 ;; wsl.exe / wslhost.exe / wslservice / VM helpers), the PID gets reused, and
 ;; `server-running-p' then claims a server is running while there is none:
 ;; `server-start' was skipped and `emacsclient' could not connect.
 ;; (On GNU/Linux the same function takes the local-socket branch, where it
 ;; really opens a connection, hence the problem is Windows-only.)
 ;;
 ;; Trustworthy checks instead:
 ;;   - `server-process' + its status : did THIS Emacs start a server?
 ;;   - `server-eval-at'              : does a real Emacs answer on that file?
 (require 'server)
 (unless (and server-process
              (eq (process-status server-process) 'listen))
   ;; This Emacs has no server. Before starting one, get rid of a possibly
   ;; stale connection file: if nothing real answers through it, it is a
   ;; leftover, and `server-start' would otherwise warn and refuse to start.
   ;; (Caveat: if several Emacs run on Windows under the same HOME, this makes
   ;; the last one started own the name "server".)
   (unless (ignore-errors (server-eval-at server-name '(emacs-pid)))
     (let ((inhibit-message t))          ; silence "No connection file ..."
       (server-force-delete)))
   (server-start)
   (my-init--message2 "Emacs server started"))

 ;; Note: I have not managed to open an .org file from Windows Explorer by double-click:
 ;; some tricks allow managing spaces in filename, but not accents.
 ;; However, we can open an .org file from Windows Explorer by drag-and-drop into Emacs,
 ;; and the server allows `emacsclient' to reuse this Emacs instance.
 
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

 (when *my-init--linux-p*
   (ert-deftest test-linux-core-tools ()
     "Check that essential Linux tools are available."
     :tags '(init linux)
     (should (executable-find "git"))
     (should (executable-find "grep"))
     (should (executable-find "find")))

   (ert-deftest test-linux-optional-tools ()
     "Check optional tools and report missing ones."
     :tags '(init linux)
     (dolist (tool '("gcc" "g++" "gnuplot" "R" "sbcl" "evince"
                     "xclip" "7z" "tesseract" "pdftk" "pandoc"
                     "gs" "convert" "python3"))
       (unless (executable-find tool)
         (message "Optional tool not found: %s" tool)))))

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
