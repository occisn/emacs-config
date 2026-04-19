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

 ;; Predicate: is `default-directory' on a remote mount?
 ;; Covers three cases, in all of which Emacs's normal `file-remote-p'
 ;; is insufficient:
 ;;   - WSL TRAMP paths for VPS `sshx' (caught by `file-remote-p' — the
 ;;     only case where it is sufficient, listed for completeness).
 ;;   - Windows SSHFS-Win mounts for VPS and FTP-1 (drive letters look
 ;;     local to Emacs; caught by drive-letter prefix check).
 ;;   - WSL/Linux sshfs mount for FTP-1 (local path from Emacs's point
 ;;     of view; caught by path prefix check).
 (defun my-init--on-remote-p ()
   "Return non-nil if `default-directory' is on a remote mount.
Matches TRAMP paths, Windows SSHFS-Win mounts for VPS and FTP-1, and
the WSL/Linux sshfs mount for FTP-1."
   (or (file-remote-p default-directory)
       (and default-directory
            (or (and *my-init--windows-p*
                     *my-init--vps-sshfs-path*
                     (string-prefix-p (expand-file-name *my-init--vps-sshfs-path*)
                                      (expand-file-name default-directory)
                                      t))
                (and *my-init--windows-p*
                     *my-init--ftp-1-sshfs-path*
                     (string-prefix-p (expand-file-name *my-init--ftp-1-sshfs-path*)
                                      (expand-file-name default-directory)
                                      t))
                (and (not *my-init--windows-p*)
                     *my-init--ftp-1-wsl-mount*
                     (string-prefix-p (expand-file-name *my-init--ftp-1-wsl-mount*)
                                      (expand-file-name default-directory)
                                      t))))))

 ;; Skip Projectile on remote paths when
 ;; `*my-init--deactivate-projectile-on-remote-p*' is non-nil (default
 ;; t).  Projectile's marker-file probes walk up from
 ;; `default-directory' issuing ~300 `file-exists-p' calls per lookup;
 ;; on remote each becomes an SSH/SFTP round-trip and dominates
 ;; cold-path Dired time.
 (with-eval-after-load 'projectile
   (defun my-init--projectile-skip-on-remote (orig &rest args)
     "Return nil for `projectile-project-root' on remote paths when
`*my-init--deactivate-projectile-on-remote-p*' is set."
     (unless (and *my-init--deactivate-projectile-on-remote-p*
                  (my-init--on-remote-p))
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
 ;;
 ;; Values for `*my-init--vps-sshfs-path*' (drive letter) and
 ;; `*my-init--sshfs-win-manager-exe*' (Manager exe path) are set in
 ;; personal--directories-and-files-and-constants.el; placeholders
 ;; declared in init.el.

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
   (when *my-init--vps-sshfs-path*
     (dir-locals-set-directory-class
      *my-init--vps-sshfs-path* 'sshfs-vps-speedups)))

 ;; Silence the dir-locals confirmation prompt for the values above;
 ;; they only turn off automatic probing, nothing security-sensitive.
 (when *my-init--windows-p*
   (dolist (var-val '((vc-handled-backends . nil)
                      (project-vc-extra-root-markers . nil)))
     (add-to-list 'safe-local-variable-values var-val)))

 ;; Disable `all-the-icons-dired-mode' on remote paths when
 ;; `*my-init--deactivate-dired-icons-on-remote-p*' is non-nil (default
 ;; t).  Per-entry `file-symlink-p' + icon text-property allocation
 ;; dominates Dired open time on SSHFS mounts (~53% in profiling a
 ;; ~50-file home dir: 16% direct + 37% GC).
 (defun my-init--disable-dired-icons-on-remote ()
   "Disable `all-the-icons-dired-mode' on remote paths when
`*my-init--deactivate-dired-icons-on-remote-p*' is set."
   (when (and *my-init--deactivate-dired-icons-on-remote-p*
              (bound-and-true-p all-the-icons-dired-mode)
              (my-init--on-remote-p))
     (all-the-icons-dired-mode -1)))
 (with-eval-after-load 'all-the-icons-dired
   (add-hook 'dired-mode-hook #'my-init--disable-dired-icons-on-remote 90)))


;;; ===
;;; ===============
;;; ===== FTP =====
;;; ===============

(my-init--with-duration-measured-section
 t
 "ftp"

 ;; FTP-1: shared-hosting SFTP (Perso-tier plans typical).  Password auth, no shell.
 ;; WSL/Linux: local sshfs mount at `*my-init--ftp-1-wsl-mount*'.
 ;;   `my/open-ftp-1' auto-mounts via sshfs if not already active,
 ;;   prompting for password (cached by `password-cache-expiry').
 ;; Windows: SSHFS-Win mount to `*my-init--ftp-1-sshfs-path*'.
 ;;   `my/open-ftp-1' launches SSHFS-Win Manager if mount is absent.
 ;; TRAMP `/sftp:' is NOT used: tramp-gvfs requires GVFS+D-Bus and does
 ;; not resolve SSH aliases through GVFS, so password prompts loop.
 ;; Shared Windows plumbing (Manager exe, `sshfs-vps-speedups' dir-locals
 ;; class, `w32-get-true-file-attributes' tune) lives in the TRAMP section
 ;; above.  Placeholders for the three FTP-1 vars are declared in init.el;
 ;; real values set in personal--directories-and-files-and-constants.el.

 (defun my-init--ftp-1-launch-sshfs-win-manager ()
   "Launch SSHFS-Win Manager so the user can connect FTP-1 hosting.
Signal `user-error' if the Manager executable is missing."
   (if (and *my-init--sshfs-win-manager-exe*
            (my-init--file-exists-p *my-init--sshfs-win-manager-exe*))
       (progn
         (start-process "sshfs-win-manager" nil *my-init--sshfs-win-manager-exe*)
         (message "FTP-1 not mounted — SSHFS-Win Manager launched. Connect `%s', then re-run `my/open-ftp-1'."
                  (or *my-init--ftp-1-ssh-alias* "FTP-1")))
     (user-error "FTP-1 not mounted and SSHFS-Win Manager not found at %s"
                 *my-init--sshfs-win-manager-exe*)))

 (defun my-init--ftp-1-wsl-mount-active-p ()
   "Return non-nil if `*my-init--ftp-1-wsl-mount*' is a live mount.
Uses /proc/mounts rather than `file-directory-p' because a stub
directory that exists without a backing mount would fool the latter."
   (when (and *my-init--ftp-1-wsl-mount*
              (file-exists-p "/proc/mounts"))
     (let ((mount (expand-file-name *my-init--ftp-1-wsl-mount*)))
       (with-temp-buffer
         (insert-file-contents "/proc/mounts")
         (goto-char (point-min))
         (re-search-forward
          (concat " " (regexp-quote mount) " ") nil t)))))

 (defun my-init--ftp-1-wsl-sshfs-mount ()
   "Mount FTP-1 via sshfs to `*my-init--ftp-1-wsl-mount*' (WSL/Linux).
Prompts for the SSHFS password, cached for `password-cache-expiry'
seconds (see TRAMP section).  Invalidates the cache on failure so the
next attempt re-prompts with a fresh entry.  Pipes the password to
sshfs via stdin (`-o password_stdin'), avoiding shell-quoting issues
for any characters in the password.  Signals `user-error' if sshfs is
not installed or the mount fails."
   (unless (executable-find "sshfs")
     (user-error "sshfs not found in PATH — install with: sudo apt install sshfs"))
   (let* ((mount (expand-file-name *my-init--ftp-1-wsl-mount*))
          (alias *my-init--ftp-1-ssh-alias*)
          (cache-key (format "sshfs-%s" alias))
          (password (password-read
                     (format "SSHFS password for %s: " alias)
                     cache-key)))
     (unless (file-directory-p mount)
       (make-directory mount t))
     (with-temp-buffer
       (insert password)
       (let ((exit (call-process-region
                    (point-min) (point-max)
                    "sshfs" t t nil
                    (format "%s:" alias)
                    mount
                    "-o" "password_stdin"
                    "-o" "reconnect"
                    "-o" "ServerAliveInterval=15"
                    "-o" "ServerAliveCountMax=3"
                    "-o" "idmap=user"
                    "-o" "StrictHostKeyChecking=accept-new")))
         (if (zerop exit)
             (message "FTP-1 mounted at %s" mount)
           (password-cache-remove cache-key)
           (user-error "sshfs mount failed (exit %s): %s"
                       exit (string-trim (buffer-string))))))))

 (defun my/open-ftp-1 ()
   "Open FTP-1 shared-hosting root in Dired.
On Windows: via SSHFS-Win mount (`*my-init--ftp-1-sshfs-path*').  If the
mount is not currently available, launch SSHFS-Win Manager so the user
can connect FTP-1 (alias `*my-init--ftp-1-ssh-alias*'), then re-run this
command once connected.
On WSL/Linux: via a local sshfs mount (`*my-init--ftp-1-wsl-mount*').
If the mount is not currently active, runs `sshfs' automatically
(prompting for password, cached by `password-cache-expiry').  This
mirrors the Windows SSHFS-Win pattern and avoids the tramp-gvfs /
GVFS / D-Bus dependency chain that is often broken on headless WSL,
and avoids TRAMP's inability to resolve SSH aliases through GVFS."
   (interactive)
   (unless *my-init--ftp-1-ssh-alias*
     (user-error "`*my-init--ftp-1-ssh-alias*' is not set (check personal--directories-and-files-and-constants.el)"))
   (let ((gc-cons-threshold (* 100 1024 1024)))
     (cond
      ((not *my-init--windows-p*)
       (unless *my-init--ftp-1-wsl-mount*
         (user-error "`*my-init--ftp-1-wsl-mount*' is not set (check personal--directories-and-files-and-constants.el).  Example: (setq *my-init--ftp-1-wsl-mount* \"~/mnt/ovh\")"))
       (unless (my-init--ftp-1-wsl-mount-active-p)
         (my-init--ftp-1-wsl-sshfs-mount))
       (dired (expand-file-name *my-init--ftp-1-wsl-mount*)))
      (t
       (unless *my-init--ftp-1-sshfs-path*
         (user-error "`*my-init--ftp-1-sshfs-path*' is not set (check personal--directories-and-files-and-constants.el)"))
       (condition-case _err
           (dired *my-init--ftp-1-sshfs-path*)
         (file-error
          (my-init--ftp-1-launch-sshfs-win-manager)))))))

 ;; Register FTP-1 mount under the shared `sshfs-vps-speedups' dir-locals
 ;; class (defined in TRAMP section above).  Same optimizations: no VC,
 ;; no project.el marker probing.
 ;; The cross-cutting icons + projectile deactivation is handled in the
 ;; TRAMP section via `my-init--on-remote-p' and the two flags declared
 ;; in init.el; nothing FTP-specific needed here.
 (when (and *my-init--windows-p* *my-init--ftp-1-sshfs-path*)
   (dir-locals-set-directory-class
    *my-init--ftp-1-sshfs-path* 'sshfs-vps-speedups)))


;;; end of init--network.el
