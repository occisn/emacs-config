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

 ;; sshx works on both WSL and Windows (OpenSSH); uses ~/.ssh/config aliases.
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

 ;; Skip Projectile entirely on remote paths — not needed on the VPS for now,
 ;; and it would otherwise add its own marker-file probes on top of project.el.
 (with-eval-after-load 'projectile
   (defun my-init--projectile-skip-on-remote (orig &rest args)
     "Return nil for `projectile-project-root' on TRAMP paths."
     (unless (file-remote-p default-directory) (apply orig args)))
   (advice-add 'projectile-project-root :around
               #'my-init--projectile-skip-on-remote)))


;;; end of init--network.el
