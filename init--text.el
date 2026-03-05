;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; =============================
;;; ===== OTHER EMACS TOOLS =====
;;; =============================

(my-init--with-duration-measured-section 
 t
 "Other Emacs tools"

 ;; Calculator
 
 ;; Battery
 ;;    M-x battery

 ;; Calendar
 ;;    M-x calendar
 ;;    then PAGE-UP et PAGE-DOWN to navigate

 ;; Colors
 ;;   M-x list-colors-display

 ;; M-x memory-report

 ;; Key frequency

 ) ; end of init section


;;; ===
;;; =======================
;;; ===== USER MACROS =====
;;; =======================

(my-init--with-duration-measured-section 
 t
 "User macros"

 (defun my/repeat-macro-until-error ()
   "Repeat previously stored macro until error"
   (interactive)
   (kmacro-end-and-call-macro 0))

 )


;;; ===
;;; ================
;;; ===== TEXT =====
;;; ================

(my-init--with-duration-measured-section 
 t
 "Text"

 ;; indentation by space and not by tabs:
 (setq-default indent-tabs-mode nil)
 ;; see https://github.com/bbatsov/emacs-lisp-style-guide
 
 ;; (setq-default tab-width 4)           ; 4 spaces per tab
 ;; (setq require-final-newline t)       ; Files end with newline
 
 ;; Enable useful disabled commands:
 (put 'narrow-to-region 'disabled nil)
 (put 'upcase-region 'disabled nil)
 (put 'downcase-region 'disabled nil)

 ;; Visual line mode
 (global-visual-line-mode 1)
 ;; "Visual Line mode provides support for editing by visual lines.
 ;; It turns on word-wrapping in the current buffer, and rebinds C-a, C-e, and C-k
 ;; to commands that operate by visual lines instead of logical lines.
 ;; This is a more reliable replacement for longlines-mode."

 ;; Indent when new line
 (define-key global-map (kbd "RET") 'newline-and-indent)

 ;; Ace-jump
 ;; Byte-compilation warning: Package cl is deprecated
 (use-package ace-jump-mode
   :init
   (setq byte-compile-warnings '(not cl-functions obsolete))
   :config (my-init--message-package-loaded "ace-jump-mode")
   :bind ("C-c C-SPC" . ace-jump-mode)) 

 ;; alternative = avy
 (when nil
   (use-package avy
     :config
     (progn
       (global-set-key (kbd "C-c C-SPC") #'avy-goto-word-1)
       (global-set-key (kbd "C-c C-SPC") #'avy-goto-char-timer)
       (my-init--message-package-loaded "avy")))) ; end of when nil

 ;; C-w kills only if region selected
 (defun my-init--kill-only-if-region-selected (_arg)
   "C-w kills region only if region is selected"
   (interactive "*p")
   (if (and transient-mark-mode mark-active)
       (kill-region (region-beginning) (region-end))
     (message "Attempting to kill (C-w) whereas no region was selected. No action done.")))
 (global-set-key (kbd "C-w") #'my-init--kill-only-if-region-selected)
 ;; inspiration: https://andreyorst.gitlab.io/posts/2020-04-29-text-editors/

 
 ;; C-c ; adds ';' comment at the beginning of line
 (when nil
   (defun my/add-comment-symbol-at-beginning-of-line (nb)
     "Add ';' character NB times (default: once)  at the beginning of the line."
     (interactive "p")
     (save-excursion
       (beginning-of-line)
       (dotimes (i (if (null nb) 1 nb))
         (insert ";"))
       (insert " ")))
   (global-set-key (kbd "C-c ;") #'my/add-comment-symbol-at-beginning-of-line)) ; end of when nil

 (defun xah-show-kill-ring ()
   "Insert all `kill-ring' content in a new buffer named *copy history*.
URL `http://ergoemacs.org/emacs/emacs_show_kill_ring.html'
Version 2019-12-02"
   (interactive)
   (let ((buf (generate-new-buffer "*copy history*")))
     (progn
       (switch-to-buffer buf)
       (funcall 'fundamental-mode)
       (dolist (x kill-ring )
         (insert x "\n\nhh=============================================================================\n\n"))
       (goto-char (point-min)))))) ; end of init section


;;; ===
;;; ====================
;;; ===== SPELLING =====
;;; ====================

(my-init--with-duration-measured-section 
 t
 "Spelling"

 ) ; end of init secton


;;; ===
;;; ===============
;;; === KAMOJIS ===
;;; ===============

;;; ¯\_(ツ)_/¯
;;; https://emojidb.org/ascii-emoticons-emojis


;;; ===
;;; ==================
;;; ===== ABBREV =====
;;; ==================

(my-init--with-duration-measured-section 
 t
 "Abbrev"

 ;; M-x list-abbrevs
 
 ;; M-x edit-abbrev then C-c C-c

 ;; delete ~/.emacs.d/abbrev-defs to empty cache

 ;; M-x unexpand-abbrev
 ;; C-q pour ne pas étendre avec SPACE

 (setq abbrev-file-name ;; tell emacs where to read abbrev
       "~/.emacs.d/abbrev-defs")

 (setq save-abbrevs 'silently)  

 (defun my/number-of-abbreviations ()
   "Return the number of abbreviations."
   (let ((count 0))
     (mapatoms (lambda (_) (setq count (1+ count))) global-abbrev-table)
     count))
 
 (define-skeleton quote-skeleton 
   "quote skeleton"
   "Title: "
   "#+BEGIN_QUOTE " str "\n"
   _ "\n"
   "#+END_QUOTE\n")
 (define-abbrev global-abbrev-table "qquote"
   "" 'quote-skeleton)

 (define-skeleton block-skeleton 
   "block skeleton"
   "Title: "
   "#+BEGIN " str "\n"
   _ "\n"
   "#+END\n")
 (define-abbrev global-abbrev-table "blockk"
   "" 'block-skeleton)

 (define-skeleton src-skeleton 
   "SRC skeleton"
   "Langage: "
   "#+BEGIN_SRC " str "\n"
   _ "\n"
   "#+END_SRC\n")
 (define-abbrev global-abbrev-table "srcc"
   "" 'src-skeleton)

 (define-abbrev-table 'global-abbrev-table
   '(("ualpha" "α")
     ("ubeta" "β")
     ("ugamma" "γ")
     ("udelta" "δ")
     ("uepsilon" "ε")
     ("uzeta" "ζ")
     ("ueta" "η")
     ("utheta" "θ")
     ("uiota" "ι")
     ("ukappa" "κ")
     ("ulambda" "λ")
     ("umeta" "μ")
     ("umu" "μ")
     ("unu" "ν")
     ("uxi" "ξ")
     ("uomicron" "ο")
     ("upi" "π")
     ("urho" "ρ")
     ("usigma" "σ")
     ("usigma2" "ς")
     ("utau" "τ")
     ("uupsilon" "υ")
     ("uphi" "φ")
     ("ukhi" "χ")
     ("upsi" "ψ")
     ("uomega" "ω")

     ;; lettres grecques majuscules :
     ("uAlpha" "Α")
     ("uBeta" "Β")
     ("uGamma" "Γ")
     ("uDelta" "Δ")
     ("uEpsilon" "Ε")
     ("uZeta" "Ζ")
     ("uEta" "Η")
     ("uTheta" "Θ")
     ("uIota" "Ι")
     ("uKappa" "Κ")
     ("uLambda" "Λ")
     ("uMu" "Μ")
     ("uNu" "Ν")
     ("uXi" "Ξ")
     ("uOmicron" "Ο")
     ("uPi" "Π")
     ("uRho" "Ρ")
     ("uSigma" "Σ")
     ("uTau" "Τ")
     ("uUpsilon" "Υ")
     ("uPhi" "Φ")
     ("ukhi" "Χ")
     ("upsi" "Ψ")
     ("uOmega" "Ω")))

 (define-abbrev-table 'global-abbrev-table
   '(("ajd" "aujourd'hui")
     ("qu'ajd" "qu'aujourd'hui")
     ("bcp" "beaucoup")
     ("Bcp" "Beaucoup")
     ("càd" "c'est-à-dire")
     ("chgt" "changement")
     ("chgts" "changements")
     ;; ("cmt" "comment")
     ("dvt" "développement")
     ("ê" "être")
     ("envt" "environnement")
     ("fàf" "face-à-face")
     ("impt" "important")
     ("jms" "jamais")
     ("l'odj" "l'ordre du jour")
     ("màd" "mise à disposition")
     ("màj" "mise à jour")
     ("mvs" "mauvais")
     ("mvt" "mouvement")
     ("mvts" "mouvements")
     ("nbx" "nombreux")
     ;; ("odj" "ordre du jour")
     ("pb" "problème")
     ("pbs" "problèmes")
     ("pê" "peut-être")
     ("prq" "pourquoi")
     ("Prq" "Pourquoi")
     ("qqc" "quelque chose")
     ("qqes" "quelques")
     ("qqun" "quelqu'un")
     ("qqx" "quelquefois")
     ("tjs" "toujours")
     ("uel" "eλ")
     ("ufin" "=fin=")
     ("upsy" "Ψ")
     ("vàv" "vis-à-vis")

     ("ué" "É")
     ("d'Ecole" "d'École")
     ("l'Ecole" "l'École")
     ("L'Ecole" "L'École")

     ("u(1)" "①")
     ("u(2)" "②")
     
     ("oeil" "œil")
     ("oeuf" "œuf")
     ("oeufs" "œufs")
     ("oeuvre" "œuvre")
     ("d'oeuvre" "d'œuvre")
     ("l'oeuvre" "l'œuvre")
     ("oeuvres" "œuvres")
     ;; ("coefficients" "cœfficients")
     ;; ("coefficient" "cœfficient")
     ("coeur" "cœur")
     ("coeurs" "cœurs")
     ("soeur" "sœur")
     ("soeurs" "sœurs")
     ("noeud" "nœud")
     ("noeuds" "nœuds")
     ("voeu" "vœu")
     ("voeux" "vœux")
     ("oe" "œ")
     ;; ("ae" "æ")
     ("Oe" "Œ")
     ("OE" "Œ")
     ;; ("AE" "Æ")
     ("manoeuvre" "manœuvre")

     ("ugg" "«")
     ("ugd" "»")
     
     ;; arrows:
     ("udonc" "⇒")                       ; ==> =>
     ("udownarrow" "↓")
     ("udownrightarrow" "↘")
     ("uequ" "⇔")
     ("uequiv" "⇔")
     ("uequivalence" "⇔")
     ("uimplique" "⇒")
     ("uleftarrow" "←")
     ("urightarrow" "→")                 ; pour fonctions: ↦
     ("uuparrow" "↑")
     ("uuprightarrow" "↗")
     ("uevolue" "↝")
     ("uévolue" "↝")

     ;; mathematical symbols:
     ("u+-" "±")
     ("u<>" "≠")
     ("uM" "M̄")
     ("udif" "≠")
     ("udiff" "≠")
     ("udifferent" "≠")
     ("udifférent" "≠")
     ("udiv" "÷")
     ("udivision " "÷")
     ("uemptyset" "∅")
     ("uensemblevide" "∅")
     ("uenv" "≃")
     ("uenviron" "≃")
     ("uexist" "∃")
     ("uexists" "∃")
     ("uf" "ƒ")
     ("uforall" "∀")
     ("uinclus" "⊂" )
     ("uinf" "≤")                        ; <=
     ("uinfini" "∞")
     ("uneg" "¬")
     ("unegation" "¬")
     ("univeau" "≡")
     ("unon" "¬")
     ("uplusminus" "±")
     ("uplusmoins" "±")
     ("upourtout" "∀")
     ("uprob" "ℙ")
     ("usousensemble" "⊂" )
     ("usup" "≥")                        ; >=

     ;; other symbols :
     ("uattention" "⚠")
     ("ubemol" "♭")
     ("ubémol" "♭")
     ("ucroix" "✝")
     ("udiametre" "⌀")
     ("uell" "ℓ")
     ("uhomme" "♂")
     ("ufemale" "♀")
     ("ufemme" "♀")
     ("umale" "♂")
     ("umult" "×")
     ("upointmedian" "·")
     ("uquadrillage" "▦") 
     ("urip" "✝")
     ("uRIP" "✝")
     ("utick" "✓")
     ("utiret" "—")
     ("utiretlong" "—")
     ("utiretcadratin" "—")
     ("uwarning" "⚠")
     
     ;; http://xahlee.info/comp/unicode_index.html

     ("lb" ";;; -*- lexical-binding: t; -*-")))

 (my-init--load-additional-init-file "personal--abbrev.el")

 (dolist (hook '(org-mode-hook
                 text-mode-hook))
   (add-hook hook #'abbrev-mode))

 (write-abbrev-file))



;;; end of init--text.el
