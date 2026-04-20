;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; ==================
;;; ===== SHELLS =====
;;; ==================

(my-init--with-duration-measured-section
 t
 "shells"

 ;; === Display line number in shell scripts

 (dolist (mode '(sh-mode-hook bash-ts-mode-hook))
   (add-hook mode (lambda () (display-line-numbers-mode 1))))

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

 ;; === cmd syntax highlighting in org-mode source blocks
 (with-eval-after-load 'org-src
   (add-to-list 'org-src-lang-modes '("cmd" . bat)))

 ;; === cmd shell (Windows only)

 (when *my-init--windows-p*
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
         (message "cmd.exe started in %s (UTF-8 mode)" default-dir)))))

 ;; === powershell

 (use-package powershell
   :commands (powershell-mode)
   :config (my-init--message-package-loaded "powershell"))

 (when *my-init--windows-p*
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
         (message "PowerShell started in %s (UTF-8 mode)" default-dir)))))

 ;; === msys2 bash (Windows only)

 (when *my-init--windows-p*
 (defun my/open-msys2-external ()
   "Open MSYS2 in a native window, within the directory of current buffer (if it is a dired or a file)."
   (interactive)
   (let ((msys2-shell-cmd (bound-and-true-p *msys2-shell-cmd*)))
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
         (message "MSYS2 shell started in %s (UTF-8 mode)" default-dir))))) ) ; end of when *my-init--windows-p* for msys2

 ;; === git bash (Windows only)

 (when *my-init--windows-p*
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
         (message "Git Bash started in %s (UTF-8 mode)" default-dir))))) ) ; end of when *my-init--windows-p* for git bash

 ;; === eat (pure-elisp terminal emulator — renders TUIs like claude, htop, vim)

 (use-package eat
   :commands (eat eat-mode eat-exec)
   :config (my-init--message-package-loaded "eat"))

 ;; On native Windows Emacs, `eat-exec' fails with "Invalid argument":
 ;; eat prepends `/usr/bin/env sh -c "stty ..."' to every spawned command
 ;; (to set pty dimensions before exec'ing the target), and neither
 ;; `/usr/bin/env' nor `sh' exists on Windows, so `CreateProcess' fails.
 ;; This around-advice temporarily rebinds `make-process' inside
 ;; `eat-exec' so that when eat passes its wrapper-prefixed command
 ;; list, we strip the wrapper and spawn the target command directly.
 ;; Pty sizing is then handled by eat's `eat--adjust-process-window-size'
 ;; hook rather than by the bypassed `stty' call.
 ;;
 ;; FRAGILE: tied to the exact shape of the :command plist built inside
 ;; eat-exec (see eat.el, `defun eat-exec').  If upstream eat changes
 ;; the wrapper prefix, this advice silently becomes a no-op and the
 ;; "Invalid argument" error will return — re-check against
 ;; <https://codeberg.org/akib/emacs-eat/src/branch/master/eat.el>.
 (when *my-init--windows-p*
   (with-eval-after-load 'eat
     (defun my--eat-exec-strip-sh-wrapper (orig-fn &rest args)
       "Around-advice for `eat-exec' on native Windows Emacs.
Rebind `make-process' within ORIG-FN's dynamic extent so that eat's
`/usr/bin/env sh -c ...' command-list prefix (with its `..' sentinel)
is stripped — spawning the target command directly and letting
`CreateProcess' succeed."
       (cl-letf* ((real-make-process (symbol-function 'make-process))
                  ((symbol-function 'make-process)
                   (lambda (&rest mp-args)
                     (let ((cmd (plist-get mp-args :command)))
                       (when (and (listp cmd)
                                  (>= (length cmd) 5)
                                  (equal (nth 0 cmd) "/usr/bin/env")
                                  (equal (nth 1 cmd) "sh")
                                  (equal (nth 2 cmd) "-c")
                                  (equal (nth 4 cmd) ".."))
                         (setq mp-args
                               (plist-put (copy-sequence mp-args)
                                          :command (nthcdr 5 cmd))))
                       (apply real-make-process mp-args)))))
         (apply orig-fn args)))
     (advice-add 'eat-exec :around #'my--eat-exec-strip-sh-wrapper)
     (my-init--message2 "Installed Windows workaround advice on `eat-exec'")))

 ;; === wsl bash (Windows only: launching WSL from Windows Emacs)

 ;; to install WSL on Windows :
 ;;   [cmd] wsl.exe --install
 ;; then, to know available distributions:
 ;;   [cmd] wsl.exe --list --online
 ;; and to install one:
 ;;   [cmd] wsl.exe --install Ubuntu
 ;; then to update it:
 ;;   [wsl] sudo apt update && sudo apt full-upgrade

 (when *my-init--windows-p*
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

 (defun my/open-wsl-shell-in-emacs--eat ()
   "Open WSL bash inside an Emacs buffer using `eat' (pure-elisp terminal
emulator), starting in the current buffer's directory.

Unlike `my/open-wsl-shell-in-emacs' (comint-based, dumb terminal),
this supports full-screen TUI programs such as `claude', `htop',
`vim', `less', `top', etc."
   (interactive)
   (unless (require 'eat nil t)
     (user-error "Package `eat' is not installed"))
   (let* ((win-dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                       (file-name-directory (or (buffer-file-name) default-directory))
                     (expand-file-name "~")))
          (wsl-path (or (executable-find "wsl.exe")
                        (user-error "Could not find wsl.exe")))
          (buffer (generate-new-buffer "*WSL (eat)*")))
     ;; `wsl.exe --cd <win-dir>' starts inside the corresponding Linux
     ;; path (handles `/mnt/c/...' translation for us).
     ;;
     ;; The rest of the command chain exists because wsl.exe, when
     ;; spawned from `make-process' (i.e. without a real Windows
     ;; console), does NOT forward Emacs's ConPTY into WSL as a Linux
     ;; pty — bash inside WSL sees stdin as a pipe, `isatty(0)' is
     ;; false, readline never activates, and there is no echo or line
     ;; editing (confirmed: `tty' returns "not a tty" in this mode).
     ;; To work around that we use `script -qfc CMD /dev/null', which
     ;; allocates a fresh pty on the Linux side and runs CMD inside it.
     ;; (`script' is part of util-linux and present on all
     ;; Debian/Ubuntu WSL distributions by default.  `-q' suppresses
     ;; "Script started" banners, `-f' flushes output after each write
     ;; so typing feels live, `/dev/null' discards the typescript file.)
     ;;
     ;; Inside the new pty we reset TERMINFO and TERM: eat exports
     ;; TERM=eat-truecolor and TERMINFO=<Windows-path> into the child's
     ;; environment, and WSL ncurses cannot read a Windows terminfo
     ;; directory.  Clearing TERMINFO and forcing TERM=xterm-256color
     ;; gives readline a terminfo entry it can find, at the cost of a
     ;; few eat-specific color/cursor extensions.
     (with-current-buffer buffer
       (setq default-directory win-dir)
       (eat-mode)
       (eat-exec buffer "WSL" wsl-path nil
                 (list "--cd" win-dir "--"
                       "script" "-qfc"
                       "env -u TERMINFO TERM=xterm-256color bash --login -i"
                       "/dev/null")))
     (pop-to-buffer buffer)
     (message "WSL (eat) started in %s" win-dir))) ) ; end of when *my-init--windows-p* for wsl

 ;; === Linux shell functions

 (when *my-init--linux-p*
   (defun my/open-terminal-external ()
     "Open an external terminal in the current directory."
     (interactive)
     (let ((dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                    (file-name-directory (or (buffer-file-name) default-directory))
                  (expand-file-name "~"))))
       (start-process "terminal" nil "x-terminal-emulator" "--working-directory" dir)
       (message "External terminal opened in %s" dir)))

   (defun my/open-bash-in-emacs ()
     "Open a bash shell inside an Emacs buffer."
     (interactive)
     (let* ((default-dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                             (file-name-directory (or (buffer-file-name) default-directory))
                           (expand-file-name "~")))
            (buf-name (generate-new-buffer-name (format "*bash: %s*" (abbreviate-file-name default-dir)))))
       (let ((default-directory default-dir))
         (shell buf-name)
         (message "bash started in %s" default-dir))))

   (defun my/open-bash-in-emacs--eat ()
     "Open a bash shell inside an Emacs buffer using `eat' (pure-elisp
terminal emulator), starting in the current buffer's directory.

Unlike `my/open-bash-in-emacs' (comint-based, dumb terminal), this
supports full-screen TUI programs such as `claude', `htop', `vim',
`less', `top', etc.

We launch bash via `/usr/bin/env -u TERMINFO TERM=xterm-256color'
and with `--login -i' so that:
 - eat's `TERM=eat-truecolor' (which most `.bashrc' color-prompt
   case-branches do not recognize) is replaced with the widely-handled
   `xterm-256color', giving the same colored PS1 as a native WSL
   terminal;
 - eat's `TERMINFO' pointing at an Emacs-side terminfo dir is
   unset (harmless for xterm-256color, which ncurses finds system-wide);
 - the shell is both login and interactive, so `.bash_profile' and
   `.bashrc' both run (matching how `wsl.exe' starts bash)."
     (interactive)
     (unless (require 'eat nil t)
       (user-error "Package `eat' is not installed"))
     (let* ((default-dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                             (file-name-directory (or (buffer-file-name) default-directory))
                           (expand-file-name "~")))
            (buffer (generate-new-buffer "*bash (eat)*")))
       (with-current-buffer buffer
         (setq default-directory default-dir)
         (eat-mode)
         (eat-exec buffer "bash" "/usr/bin/env" nil
                   '("-u" "TERMINFO" "TERM=xterm-256color"
                     "bash" "--login" "-i")))
       (pop-to-buffer buffer)
       (message "bash (eat) started in %s" default-dir))))

 ;; === WSL shell functions (from inside WSL)

 (when *my-init--wsl-p*
   (defun my/open-wsl-shell-external-from-wsl ()
     "Open an external WSL terminal window in the directory of the current buffer.
Uses `cmd.exe /C start wsl.exe --cd DIR' so Windows spawns a new console
and WSL starts inside DIR (accepts Linux or Windows paths)."
     (interactive)
     (let* ((dir (if (or (buffer-file-name) (derived-mode-p 'dired-mode))
                     (file-name-directory (or (buffer-file-name) default-directory))
                   (expand-file-name "~")))
            (cmd-exe (or (executable-find "cmd.exe")
                         "/mnt/c/Windows/System32/cmd.exe")))
       (unless (file-executable-p cmd-exe)
         (user-error "Could not find cmd.exe to launch external WSL terminal"))
       (let ((proc (start-process "wsl-term" nil
                                  cmd-exe "/C" "start" "wsl.exe" "--cd" dir)))
         (set-process-query-on-exit-flag proc nil)
         (message "External WSL terminal opened in %s" dir)))))

 ;; === open WSL bashrc
 ;; TIP: when you edited .bashrc from Windows, it saved the file with
 ;; \r\n line endings instead of Unix \n, which breaks bash.
 ;; Fix it with this one command in WSL:
 ;;   sed -i 's/\r//' ~/.bashrc

 (defun my/open-wsl-bashrc ()
   "Open the WSL .bashrc file for editing."
   (interactive)
   (unless *my-init--wsl-p*
     (user-error "This command is only available when Emacs is running under WSL"))
   (let ((bashrc (bound-and-true-p *wsl-bashrc-path*)))
     (unless bashrc
       (user-error "Variable *wsl-bashrc-path* is not set (check personal--directories-and-files-and-constants.el)"))
     (unless (my-init--file-exists-p bashrc)
       (user-error "WSL .bashrc not found at %s" bashrc))
     (find-file bashrc)))

 ;; === hydra

 (cond
  (*my-init--windows-p*
   (defhydra hydra-shells (:exit t :hint nil)
     "
^Shells hydra:
^-------------

eshell :     [e] in buffer
cmd shell :  [c] external or [d] in buffer
powershell : [p] external or [o] in buffer
msys2 :      [m] external or [y] in buffer
git bash :   [g] external or [i] in buffer (Windows native equivalents)
wsl shell :  [w] external, [s] in buffer (comint) or [a] in buffer (eat, supports TUIs)
"
     ("a" #'my/open-wsl-shell-in-emacs--eat)
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
     ("y" #'my/open-msys2-in-emacs)))
  (*my-init--wsl-p*
   (defhydra hydra-shells (:exit t :hint nil)
     "
^Shells hydra:
^-------------

eshell :       [e] in buffer
bash :         [b] in buffer (comint) or [a] in buffer (eat, supports TUIs)
WSL terminal : [t] external (via Windows)
bashrc :       [r] open WSL .bashrc
"
     ("a" #'my/open-bash-in-emacs--eat)
     ("b" #'my/open-bash-in-emacs)
     ("e" #'eshell)
     ("r" #'my/open-wsl-bashrc)
     ("t" #'my/open-wsl-shell-external-from-wsl)))
  (t
   (defhydra hydra-shells (:exit t :hint nil)
     "
^Shells hydra:
^-------------

eshell :  [e] in buffer
bash :    [b] in buffer (comint) or [a] in buffer (eat, supports TUIs)
terminal: [t] external
"
     ("a" #'my/open-bash-in-emacs--eat)
     ("b" #'my/open-bash-in-emacs)
     ("e" #'eshell)
     ("t" #'my/open-terminal-external))))

 ) ; end of init section



;;; end of init--shells.el
