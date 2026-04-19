;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-


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

(my-init--with-duration-measured-section
 t
 "tramp"

 ;; TRAMP default method: `sshx' everywhere it works (WSL + Linux).
 ;;
 ;; Windows note: TRAMP is effectively unusable from Windows-native Emacs
 ;; against a Linux remote — every method (`sshx', `ssh', `ssh'+-tt, `plink')
 ;; fails in `tramp-open-shell' because the Windows PTY (ConPTY, used by
 ;; both Windows OpenSSH and modern plink) mangles line endings in the
 ;; shell-setup echo, gluing two prompts onto one line. For Windows, use
 ;; SSHFS-Win instead — see `my/open-vps-1' below. For one-off shell
 ;; access, use `plink <alias>' from cmd/PowerShell (alias from ~/.ssh/config).
 (setq tramp-default-method "sshx")

 (setq tramp-verbose 1)

 ;; Skip VC on remote files — biggest single TRAMP speedup.
 (with-eval-after-load 'tramp
   (setq vc-ignore-dir-regexp
         (format "%s\\|%s"
                 vc-ignore-dir-regexp
                 tramp-file-name-regexp)))

 ;; Defer to ~/.ssh/config for ControlMaster/persist rather than fighting it.
 (setq tramp-use-ssh-controlmaster-options nil)

 ;; Cache remote directory listings longer than the 10s default.
 (setq tramp-completion-reread-directory-timeout 60)

 ;; Cache SSH passphrase for one hour instead of the 16s default.
 (setq password-cache-expiry 3600)

 ;; Disable VC and project.el root-marker probing on remote files.
 ;; Without this, opening a remote file triggers ~300 `test -e` round-trips
 ;; (.git, Cargo.toml, pyproject.toml, Eldev, …) walking up to /, which on
 ;; a ~100ms-RTT VPS turned a ~0.2s ssh handshake into a 35s connection.
 (connection-local-set-profile-variables
  'remote-without-vc
  '((vc-handled-backends . nil)
    (project-vc-extra-root-markers . nil)))
 (connection-local-set-profiles
  '(:application tramp) 'remote-without-vc)

 ;; Cache remote file attributes for 60s so VC/project don't re-probe per command.
 (setq remote-file-name-inhibit-cache 60)

 ;; Skip Projectile on paths where its marker-file probes are expensive:
 ;;   - TRAMP paths (each `file-exists-p' is an ssh round-trip)
 ;;   - Windows SSHFS-Win VPS mount (each `file-exists-p' is an SFTP
 ;;     round-trip; the mount looks local to Emacs so the TRAMP check
 ;;     alone doesn't catch it). Profiling showed this dominated the
 ;;     cold-path cost of opening `R:/' in Dired.
 (with-eval-after-load 'projectile
   (defun my-init--projectile-skip-on-remote (orig &rest args)
     "Return nil for `projectile-project-root' on TRAMP paths or the VPS mount."
     (unless (or (file-remote-p default-directory)
                 (and (boundp '*my-init--windows-p*) *my-init--windows-p*
                      (boundp '*my-init--vps-sshfs-path*) *my-init--vps-sshfs-path*
                      default-directory
                      (string-prefix-p
                       (expand-file-name *my-init--vps-sshfs-path*)
                       (expand-file-name default-directory)
                       t)))
       (apply orig args)))
   (advice-add 'projectile-project-root :around
               #'my-init--projectile-skip-on-remote))

 ;; Windows has no working TRAMP path to the VPS; SSHFS-Win Manager
 ;; (`evsar3.sshfs-win-manager') mounts the remote via SFTP to a drive
 ;; letter, so Windows Emacs can edit files as if local. The autofs
 ;; UNC (`\\sshfs.k\...') does NOT work on this stack: the WinFsp
 ;; launcher runs as LocalSystem and cannot reach the user-session
 ;; Pageant named pipe. The Manager runs sshfs.exe in the user session
 ;; and reads the OpenSSH key directly, side-stepping that entirely.
 (defvar *my-init--vps-sshfs-path*
   "R:/"
   "Drive letter mounted by SSHFS-Win Manager onto the VPS home directory.
Configured in the Manager GUI as connection `*my-init--vps-ssh-alias*'
using an OpenSSH private key for auth.")

 ;; Auto-launch SSHFS-Win Manager when `my/open-vps-1' is called and the
 ;; VPS drive isn't accessible. winget installs the Manager at
 ;; %LOCALAPPDATA%/Programs/sshfs-win-manager/ by default.
 (defvar *my-init--sshfs-win-manager-exe*
   (when *my-init--windows-p*
     (expand-file-name "Programs/sshfs-win-manager/SSHFS-Win Manager.exe"
                       (or (getenv "LOCALAPPDATA") "~/AppData/Local")))
   "Full path to SSHFS-Win Manager executable (Windows only).
Set to nil on non-Windows. Adjust if installed elsewhere.")

 (when (and *my-init--windows-p*
            *my-init--sshfs-win-manager-exe*
            (not (my-init--file-exists-p *my-init--sshfs-win-manager-exe*)))
   (my-init--warning
    (format "SSHFS-Win Manager not found at %s; `my/open-vps-1' will error when the VPS is not already mounted"
            *my-init--sshfs-win-manager-exe*)))

 (defun my-init--vps-launch-sshfs-win-manager ()
   "Launch SSHFS-Win Manager so the user can connect the VPS.
Message the user with next-step instructions. Signal `user-error'
if the Manager executable is missing."
   (if (and *my-init--sshfs-win-manager-exe*
            (my-init--file-exists-p *my-init--sshfs-win-manager-exe*))
       (progn
         (start-process "sshfs-win-manager" nil *my-init--sshfs-win-manager-exe*)
         (message "VPS not mounted — SSHFS-Win Manager launched. Connect `%s', then re-run `my/open-vps-1'."
                  (or *my-init--vps-ssh-alias* "the VPS")))
     (user-error "VPS not mounted and SSHFS-Win Manager not found at %s"
                 *my-init--sshfs-win-manager-exe*)))

 (defun my/open-vps-1 ()
   "Open the VPS home directory in Dired.
On Windows: via SSHFS-Win mount (`*my-init--vps-sshfs-path*'). If the
mount is not currently available, launch SSHFS-Win Manager so the user
can connect the VPS (alias `*my-init--vps-ssh-alias*'), then re-run
this command once connected.
On WSL/Linux: via TRAMP `sshx' to `*my-init--vps-ssh-alias*'.

`gc-cons-threshold' is bumped to 100 MB for the duration: cold-path
Dired over SSHFS was measured at ~36% GC (≈5s out of 14s)."
   (interactive)
   (unless *my-init--vps-ssh-alias*
     (user-error "`*my-init--vps-ssh-alias*' is not set (check personal--directories-and-files-and-constants.el)"))
   (let ((gc-cons-threshold (* 100 1024 1024)))
     (cond
      ((not *my-init--windows-p*)
       (dired (format "/sshx:%s:" *my-init--vps-ssh-alias*)))
      (t
       ;; Trust the real operation, not a preflight check: SSHFS-Win
       ;; can leave a stub drive letter after disconnect so
       ;; `file-directory-p' returns t while `dired' still fails.
       (condition-case _err
           (dired *my-init--vps-sshfs-path*)
         (file-error
          (my-init--vps-launch-sshfs-win-manager)))))))

 ;; Windows Dired on SSHFS was measured at 60s for a ~50-file home dir.
 ;; Root cause: `w32-get-true-file-attributes' defaults to `local', which
 ;; issues one `GetFileInformationByHandle' per entry. WinFsp translates
 ;; each call into an SFTP round-trip — 50 entries × ~1s RTT = 60s. The
 ;; attributes it returns (hard-link count, precise ownership) are not
 ;; meaningful on a POSIX-over-SFTP filesystem anyway. Disable globally.
 (when *my-init--windows-p*
   (setq w32-get-true-file-attributes nil))

 ;; On the SSHFS mount, also skip VC and project.el root-marker probing
 ;; per visited file/Dired entry (same class of fix as the TRAMP
 ;; connection-local profile, but scoped by directory since the mount
 ;; looks local to Emacs). Applied via dir-locals class.
 (when *my-init--windows-p*
   (dir-locals-set-class-variables
    'sshfs-vps-speedups
    '((nil . ((vc-handled-backends . nil)
              (project-vc-extra-root-markers . nil)))))
   (dir-locals-set-directory-class
    *my-init--vps-sshfs-path* 'sshfs-vps-speedups))

 ;; Silence the dir-locals confirmation prompt for the values above;
 ;; they only turn off automatic probing, nothing security-sensitive.
 (when *my-init--windows-p*
   (dolist (var-val '((vc-handled-backends . nil)
                      (project-vc-extra-root-markers . nil)))
     (add-to-list 'safe-local-variable-values var-val)))

 ;; `all-the-icons-dired' dominates Dired open time on the SSHFS mount:
 ;; per-entry `file-symlink-p' + icon lookup, each one an SFTP round-trip,
 ;; plus heavy GC from allocating icon text properties. Profiling a
 ;; ~50-file home dir put this at ~53% (16% direct + 37% GC). Disable
 ;; the minor mode for Dired buffers rooted under the mount.
 (when *my-init--windows-p*
   (defun my-init--sshfs-disable-dired-icons ()
     "Disable `all-the-icons-dired-mode' under the VPS SSHFS mount."
     (when (and (bound-and-true-p all-the-icons-dired-mode)
                default-directory
                (string-prefix-p
                 (expand-file-name *my-init--vps-sshfs-path*)
                 (expand-file-name default-directory)
                 t))
       (all-the-icons-dired-mode -1)))
   (with-eval-after-load 'all-the-icons-dired
     (add-hook 'dired-mode-hook #'my-init--sshfs-disable-dired-icons 90))))


;;; end of init--network.el
