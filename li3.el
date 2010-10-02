;;;li3.el ---  Lithium Minor Mode
;; -*- Mode: Emacs-Lisp -*-

;; Copyright (C) 2010 by 101000code/101000LAB

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

;; Version: 0.0.2
;; Author: k1LoW (Kenichirou Oyama), <k1lowxb [at] gmail [dot] com> <k1low [at] 101000lab [dot] org>
;; URL: http://code.101000lab.org, http://trac.codecheck.in

;;; Install
;; Put this file into load-path'ed directory, and byte compile it if
;; desired.  And put the following expression into your ~/.emacs.
;;
;; (require 'li3)
;; (global-li3 t)
;;
;; If you use default key map, Put the following expression into your ~/.emacs.
;;
;; (li3-set-default-keymap)

;;; Commentary:

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `li3'
;;    Lithium minor mode.
;;  `li3-switch-to-model'
;;    Switch to model.
;;  `li3-switch-to-view'
;;    Switch to view.
;;  `li3-switch-to-controller'
;;    Switch to contoroller.
;;  `li3-switch-to-model-testcase'
;;    Switch to model testcase.
;;  `li3-switch-to-controller-testcase'
;;    Switch to contoroller testcase.
;;  `li3-switch-to-fixture'
;;    Switch to fixture.
;;  `li3-switch-to-function'
;;    Switch to function.
;;  `li3-switch-to-element'
;;    Switch to element. If region is active, make new element file.
;;  `li3-switch-to-javascript'
;;    Switch to javascript.
;;  `li3-switch-to-css'
;;    Switch to stylesheet.
;;  `li3-switch'
;;    Omni switch function.
;;  `li3-switch-testcase'
;;    Switch testcase <-> C/M. Or, switch form fixture to testcase.
;;  `li3-switch-to-file-history'
;;    Switch to file history.
;;  `li3-open-dir'
;;    Open directory.
;;  `li3-open-models-dir'
;;    Open models directory.
;;  `li3-open-views-dir'
;;    Open views directory.
;;  `li3-open-controllers-dir'
;;    Open contorollers directory.
;;  `li3-open-behaviors-dir'
;;    Open behaviors directory.
;;  `li3-open-helpers-dir'
;;    Open helpers directory.
;;  `li3-open-components-dir'
;;    Open components directory.
;;  `li3-open-config-dir'
;;    Open config dir.
;;  `li3-open-layouts-dir'
;;    Open layouts directory.
;;  `li3-open-elements-dir'
;;    Open elements directory.
;;  `li3-open-js-dir'
;;    Open JavaScript directory.
;;  `li3-open-css-dir'
;;    Open css directory.
;;  `li3-open-tests-dir'
;;    Open tests directory.
;;  `li3-set-version'
;;    Set Lithium version.
;;  `li3-complete'
;;    Insert Lithium code.
;;  `li3-tail-log'
;;    Show log by "tail".
;;  `li3-singularize'
;;    Singularize str
;;  `li3-pluralize'
;;    Pluralize str
;;  `anything-c-li3-anything-only-source-li3'
;;    anything only anything-c-source-li3 and anything-c-source-li3-model-function.
;;  `anything-c-li3-anything-only-function'
;;    anything only anything-c-source-li3-function.
;;  `anything-c-li3-anything-only-model-function'
;;    anything only anything-c-source-li3-model-function.
;;  `anything-c-li3-anything-only-po'
;;    anything only anything-c-source-li3-po.
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `li3-app-path-search-limit'
;;    Search limit
;;    default = 5
;;  `li3-use-imenu'
;;    Use imenu function
;;    default = nil
;;  `li3-core-version'
;;    Lithium version
;;    default = "0.9.5"

;;; Change Log
;; 0.0.2: Improved switch functions
;; 0.0.1: Initial commit

;;; TODO
;;

;;; Code:

;;require
(require 'cake-inflector)
(require 'cl)
(require 'anything)
(require 'historyf)
(require 'easy-mmode)

(when (require 'anything-show-completion nil t)
  (use-anything-show-completion 'li3-complete
                                '(length li3-initial-input)))

(defgroup li3 nil
  "Lithium minor mode"
  :group 'convenience
  :prefix "li3-")

(defcustom li3-app-path-search-limit 5
  "Search limit"
  :type 'integer
  :group 'li3)

(defcustom li3-use-imenu nil
  "Use imenu function"
  :type 'boolean
  :group 'li3)

(defcustom li3-core-version "0.9.5"
  "Lithium version"
  :type 'string
  :group 'li3)

;;(global-set-key "\C-c\C-v" 'li3)

(define-minor-mode li3
  "Lithium minor mode."
  :lighter " Li3"
  :group 'li3
  (if li3
      (progn
        (setq minor-mode-map-alist
              (cons (cons 'li3 li3-key-map)
                    minor-mode-map-alist))
        (run-hooks 'li3-hook))
    nil))

(if (fboundp 'define-global-minor-mode)
    (define-global-minor-mode global-li3
      li3 li3-maybe
      :group 'li3))

(defun li3-maybe ()
  "What buffer `li3' prefers."
  (if (and (not (minibufferp (current-buffer)))
           (li3-set-app-path))
      (li3 1)
    nil))

;; key-map
(defvar li3-key-map
  (make-sparse-keymap)
  "Keymap for Li3.")

(defvar li3-app-path nil
  "Lithium app directory path.")

(defvar li3-action-name "index"
  "Lithium action name.")

(defvar li3-lower-camelized-action-name "index"
  "Lithium lower camelized action name.")

(defvar li3-snake-action-name "index"
  "Lithium snake_case action name.")

(defvar li3-view-extension "html.php"
  "Lithium view extension.")

(defvar li3-singular-name nil
  "Lithium current singular name.")

(defvar li3-camelized-singular-name nil
  "Lithium current camelized singular name.")

(defvar li3-plural-name nil
  "Lithium current plural name.")

(defvar li3-camelized-plural-name nil
  "Lithium current camelized plural name.")

(defvar li3-model-regexp "^.+/app/models/\\([^/]+\\)\.php$"
  "Model file regExp.")

(defvar li3-view-regexp "^.+/app/views/\\([^/]+\\)/\\([^/]+/\\)?\\([^/.]+\\)\\.\\(html.php\\)$"
  "View file regExp.")

(defvar li3-controller-regexp "^.+/app/controllers/\\([^/]+\\)Controller\.php$"
  "Contoroller file regExp.")

(defvar li3-javascript-regexp "^.+/app/webroot/js/.+\.js$"
  "JavaScript file regExp.")

(defvar li3-css-regexp "^.+/app/webroot/css/.+\.css$"
  "Css file regExp.")

(defvar li3-current-file-type nil
  "Current file type.")

(defvar li3-file-history nil
  "Switch file history.")

(defvar li3-hook nil
  "Hook")

(defun li3-set-default-keymap ()
  "Set default key-map"
  (setq li3-key-map
        (let ((map (make-sparse-keymap)))
          (define-key map "\C-cs" 'li3-switch)
          (define-key map "\C-ct" 'li3-switch-testcase)
          (define-key map "\C-cm" 'li3-switch-to-model)
          (define-key map "\C-cv" 'li3-switch-to-view)
          (define-key map "\C-cc" 'li3-switch-to-controller)
          (define-key map "\C-cf" 'li3-switch-to-function)
          (define-key map "\C-ce" 'li3-switch-to-element)
          (define-key map "\C-cj" 'li3-switch-to-javascript)
          (define-key map "\C-cb" 'li3-switch-to-file-history)
          (define-key map "\C-cM" 'li3-open-models-dir)
          (define-key map "\C-cV" 'li3-open-views-dir)
          (define-key map "\C-cC" 'li3-open-controllers-dir)
          (define-key map "\C-cL" 'li3-open-layouts-dir)
          (define-key map "\C-cE" 'li3-open-elements-dir)
          (define-key map "\C-cJ" 'li3-open-js-dir)
          (define-key map "\C-cS" 'li3-open-css-dir)
          (define-key map "\C-cT" 'cake-open-tests-dir)
          (define-key map "\C-c\C-g" 'li3-open-config-dir)
          (define-key map "\C-c\C-l" 'li3-tail-log)
          ;; anything-functions
          (define-key map "\C-cl" 'anything-c-li3-anything-only-source-li3)
          (define-key map "\C-co" 'anything-c-li3-anything-only-function)
          map)))

(defun li3-is-model-file ()
  "Check whether current file is model file."
  (li3-set-app-path)
  (if (not (string-match li3-model-regexp (buffer-file-name)))
      nil
    (setq li3-singular-name (match-string 1 (buffer-file-name)))
    (setq li3-camelized-singular-name (li3-camelize li3-singular-name))
    (setq li3-plural-name (li3-pluralize li3-singular-name))
    (setq li3-camelized-plural-name (li3-camelize li3-plural-name))
    (setq li3-current-file-type 'model)))

(defun li3-is-view-file ()
  "Check whether current file is view file."
  (li3-set-app-path)
  (if (not (string-match li3-view-regexp (buffer-file-name)))
      nil
    (setq li3-plural-name (match-string 1 (buffer-file-name)))
    (setq li3-camelized-plural-name (li3-camelize li3-plural-name))
    (setq li3-action-name (match-string 3 (buffer-file-name)))
    ;;(setq li3-view-extension (match-string 4 (buffer-file-name)))
    (setq li3-lower-camelized-action-name (li3-lower-camelize li3-action-name))
    (setq li3-singular-name (li3-singularize li3-plural-name))
    (setq li3-camelized-singular-name (li3-camelize li3-singular-name))
    (setq li3-current-file-type 'view)))

(defun li3-is-controller-file ()
  "Check whether current file is contoroller file."
  (li3-set-app-path)
  (if (not (string-match li3-controller-regexp (buffer-file-name)))
      nil
    (setq li3-plural-name (downcase (match-string 1 (buffer-file-name))));; test
    (setq li3-camelized-plural-name (li3-camelize li3-plural-name))
    (save-excursion
      (if
          (not (re-search-backward "function[ \t]*\\([a-zA-Z0-9_]+\\)[ \t]*\(" nil t))
          (re-search-forward "function[ \t]*\\([a-zA-Z0-9_]+\\)[ \t]*\(" nil t)))
    (setq li3-action-name (match-string 1))
    (setq li3-lower-camelized-action-name (li3-lower-camelize li3-action-name))
    (setq li3-snake-action-name (li3-snake li3-action-name))
    (setq li3-singular-name (li3-singularize li3-plural-name))
    (setq li3-camelized-singular-name (li3-camelize li3-singular-name))
    (setq li3-current-file-type 'controller)))

(defun li3-is-javascript-file ()
  "Check whether current file is JavaScript file."
  (li3-set-app-path)
  (if (not (string-match li3-javascript-regexp (buffer-file-name)))
      nil
    (setq li3-current-file-type 'javascript)))

(defun li3-is-css-file ()
  "Check whether current file is JavaScript file."
  (li3-set-app-path)
  (if (not (string-match li3-css-regexp (buffer-file-name)))
      nil
    (setq li3-current-file-type 'css)))

(defun li3-is-file ()
  "Check whether current file is Lithium's file."
  (if (or (li3-is-model-file)
          (li3-is-controller-file)
          (li3-is-view-file)
          (li3-is-javascript-file)
          (li3-is-css-file))
      t nil))

(defun li3-get-current-line ()
  "Get current line."
  (thing-at-point 'line))

(defun li3-set-app-path ()
  "Set app path."
  (li3-is-app-path))

(defun li3-is-app-path ()
  "Check app directory name and set regExp."
  (setq li3-app-path (li3-find-app-path))
  (if (not li3-app-path)
      nil
    (li3-set-regexp)))

(defun li3-find-app-path ()
  "Find app directory"
  (let ((current-dir default-directory))
    (loop with count = 0
          until (file-exists-p (concat current-dir "config/bootstrap/connections.php"))
          ;; Return nil if outside the value of
          if (= count li3-app-path-search-limit)
          do (return nil)
          ;; Or search upper directories.
          else
          do (incf count)
          (setq current-dir (expand-file-name (concat current-dir "../")))
          finally return current-dir)))

(defun li3-set-regexp ()
  "Set regExp."
  (setq li3-model-regexp (concat li3-app-path "models/\\([^/]+\\)\.php"))
  (setq li3-view-regexp (concat li3-app-path "views/\\([^/]+\\)/\\([^/]+/\\)?\\([^/.]+\\)\\.\\(html.php\\)$"))
  (setq li3-controller-regexp (concat li3-app-path "controllers/\\([^/]+\\)Controller\.php$"))
  (setq li3-model-testcase-regexp (concat li3-app-path "tests/cases/models/\\([^/]+\\)\.test\.php$"))
  (setq li3-javascript-regexp (concat li3-app-path "webroot/js/.+\.js$"))
  (setq li3-css-regexp (concat li3-app-path "webroot/css/.+\.css$"))
  t)

(defun li3-switch-to-model ()
  "Switch to model."
  (interactive)
  (if (li3-is-file)
      (li3-switch-to-file (concat li3-app-path "models/" li3-camelized-singular-name ".php"))
    (message "Can't find model name.")))

(defun li3-switch-to-view ()
  "Switch to view."
  (interactive)
  (let ((view-files nil))
    (if (li3-is-file)
        (progn
          (if (li3-is-model-file) (setq li3-plural-name (li3-pluralize li3-singular-name)))
          (setq view-files (li3-set-view-list))
          (if view-files
              (cond
               ((= 1 (length view-files))
                (find-file (concat li3-app-path "views/" li3-plural-name "/" (car view-files))))
               (t (anything
                   '(((name . "Switch to view")
                      (candidates . view-files)
                      (display-to-real . (lambda (candidate)
                                           (concat li3-app-path "views/" li3-plural-name "/" candidate)
                                           ))
                      (type . file)))
                   nil nil nil nil)
                  ))
            (if (y-or-n-p "Make new file?")
                (progn
                  (unless (file-directory-p (concat li3-app-path "views/" li3-plural-name "/"))
                    (make-directory (concat li3-app-path "views/" li3-plural-name "/")))
                  (find-file (concat li3-app-path "views/" li3-plural-name "/" li3-action-name "." li3-view-extension)))
              (message (format "Can't find %s" (concat li3-app-path "views/" li3-plural-name "/" li3-action-name "." li3-view-extension))))))
      (message "Can't switch to view."))))

(defun li3-set-view-list ()
  "Set view list"
  (let ((dir (concat li3-app-path "views/" li3-plural-name))
        (view-dir nil)
        (view-files nil))
    (unless (not (file-directory-p dir))
      (setq view-dir (remove-if-not (lambda (x) (file-directory-p (concat li3-app-path "views/" li3-plural-name "/" x))) (directory-files dir)))
      (setq view-dir (remove-if (lambda (x) (equal x "..")) view-dir))
      (loop for x in view-dir do (if (file-exists-p (concat li3-app-path "views/" li3-plural-name "/" x "/" li3-snake-action-name "." li3-view-extension))
                                     (unless (some (lambda (y) (equal (concat x "/" li3-snake-action-name "." li3-view-extension) y)) view-files)
                                       (push (concat x "/" li3-snake-action-name "." li3-view-extension) view-files))))
      (loop for x in view-dir do (if (file-exists-p (concat li3-app-path "views/" li3-plural-name "/" x "/" li3-action-name "." li3-view-extension))
                                     (unless (some (lambda (y) (equal (concat x "/" li3-action-name "." li3-view-extension) y)) view-files)
                                       (push (concat x "/" li3-action-name "." li3-view-extension) view-files)))))
    view-files))

(defun li3-switch-to-controller ()
  "Switch to contoroller."
  (interactive)
  (if (li3-is-file)
      (progn
        (if (file-exists-p (concat li3-app-path "controllers/" li3-camelized-plural-name "Controller.php"))
            (progn
              (find-file (concat li3-app-path "controllers/" li3-camelized-plural-name "Controller.php"))
              (goto-char (point-min))
              (if (not (re-search-forward (concat "function[ \t]*" li3-lower-camelized-action-name "[ \t]*\(") nil t))
                  (progn
                    (goto-char (point-min))
                    (re-search-forward (concat "function[ \t]*" li3-action-name "[ \t]*\(") nil t)))
              (recenter))
          (if (y-or-n-p "Make new file?")
              (find-file (concat li3-app-path "controllers/" li3-camelized-plural-name "Controller.php"))
            (message (format "Can't find %s" (concat li3-app-path "controllers/" li3-camelized-plural-name "Controller.php"))))))
    (message "Can't switch to contoroller.")))

(defun li3-switch-to-file (file-path)
  "Switch to file."
  (if (file-exists-p file-path)
      (find-file file-path)
    (if (y-or-n-p "Make new file?")
        (find-file file-path)
      (message (format "Can't find %s" file-path)))))

(defun li3-search-functions ()
  "Search function from current buffer."
  (let ((func-list nil))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "function[ \t]*\\([a-zA-Z0-9_]+\\)[ \t]*\(" nil t)
        (push (match-string 1) func-list))
      func-list)))

(defun li3-switch-to-function ()
  "Switch to function."
  (interactive)
  (let ((current-func nil))
    (if (and li3-use-imenu
             (require 'imenu nil t))
        (anything 'anything-c-source-imenu)
      (if (or (li3-is-controller-file)
              (li3-is-model-file)
              (li3-is-javascript-file))
          (progn
            (setq current-func (li3-search-functions))
            (anything
             '(((name . "Switch to current function")
                (candidates . current-func)
                (display-to-real . (lambda (candidate)
                                     (concat "function[ \t]*" candidate "[ \t]*\(")))
                (action
                 ("Switch to Function" . (lambda (candidate)
                                           (goto-char (point-min))
                                           (re-search-forward candidate nil t)
                                           (recenter)
                                           )))))
             nil nil nil nil))
        (message "Can't switch to function.")))))

(defun li3-switch ()
  "Omni switch function."
  (interactive)
  (if (li3-set-app-path)
      (cond
       ;;li3-switch-to-controller
       ((li3-is-view-file) (li3-switch-to-controller))
       ;;li3-switch-to-view
       ((li3-is-controller-file) (li3-switch-to-view))
       (t (message "Current buffer is neither view nor controller.")))
    (message "Can't set app path.")))

(defun li3-switch-to-file-history ()
  "Switch to file history."
  (interactive)
  (historyf-back '(li3)))

(defun li3-open-dir (dir &optional recursive)
  "Open directory."
  (interactive)
  (if (li3-set-app-path)
      (anything-other-buffer
       (li3-create-open-dir-anything-sources dir recursive) nil)
    (message "Can't set app path.")))

(defun li3-create-open-dir-anything-sources (dir &optional recursive)
  "Careate 'Open dir' anything-sources"
  (let (sources)
    (unless (listp dir)
      (setq dir (list dir)))
    (if (li3-set-app-path)
        (progn
          (loop for d in dir do
                (unless (not (file-directory-p (concat li3-app-path d)))
                  (push
                   `((name . ,(concat "Open directory: " d))
                     (candidates . ,(li3-directory-files d recursive))
                     (display-to-real . (lambda (candidate)
                                          (concat ,li3-app-path ,d candidate)))
                     (type . file))
                   sources)))
          (reverse sources))
      (message "Can't set app path."))))

(defun li3-directory-files (dir &optional recursive)
  "Get directory files recuresively."
  (let
      ((file-list nil))
    (if (not recursive)
        (directory-files (concat li3-app-path dir))
      (loop for x in (li3-get-recuresive-path-list (concat li3-app-path dir))
            do (progn
                 (string-match (concat li3-app-path dir "\\(.+\\)") x)
                 (push (match-string 1 x) file-list)))
      file-list)))

(defun li3-get-recuresive-path-list (file-list)
  "Get file path list recuresively."
  (let ((path-list nil))
    (unless (listp file-list)
      (setq file-list (list file-list)))
    (loop for x
          in file-list
          do (if (file-directory-p x)
                 (setq path-list
                       (append
                        (li3-get-recuresive-path-list
                         (remove-if
                          (lambda(y) (string-match "\\.$\\|\\.svn" y)) (directory-files x t)))
                        path-list))
               (setq path-list (push x path-list))))
    path-list))

(defun li3-open-models-dir ()
  "Open models directory."
  (interactive)
  (li3-open-dir "models/"))

(defun li3-open-views-dir ()
  "Open views directory."
  (interactive)
  (if (or (li3-is-model-file) (li3-is-controller-file) (li3-is-view-file))
      (li3-open-dir (concat "views/" li3-plural-name "/"))
    (li3-open-dir "views/" t)))

(defun li3-open-controllers-dir ()
  "Open contorollers directory."
  (interactive)
  (li3-open-dir "controllers/"))

(defun li3-open-config-dir ()
  "Open config dir."
  (interactive)
  (li3-open-dir "config/" t))

(defun li3-open-layouts-dir ()
  "Open layouts directory."
  (interactive)
  (li3-open-dir "views/layouts/" t))

(defun li3-open-elements-dir ()
  "Open elements directory."
  (interactive)
  (li3-open-dir "views/elements/" t))

(defun li3-open-js-dir ()
  "Open JavaScript directory."
  (interactive)
  (li3-open-dir "webroot/js/" t))

(defun li3-open-css-dir ()
  "Open css directory."
  (interactive)
  (li3-open-dir "webroot/css/" t))

(defun li3-open-tests-dir ()
  "Open tests directory."
  (interactive)
  (li3-open-dir "tests/" t))

(defvar li3-source-version
  '((name . "Lithium core version")
    (candidates . (lambda () (list "0.9.5")))
    (action
     ("Set Version" . (lambda (candidate)
                        (setq li3-core-version candidate))))))

(defun li3-set-version ()
  "Set Lithium version."
  (interactive)
  (if (li3-set-app-path)
      (anything '(li3-source-version)
                nil "Version: " nil)))

;;php-completion.el code
(defvar li3-initial-input nil)
(defun li3-get-initial-input ()
  (setq li3-initial-input
        (buffer-substring-no-properties (point)
                                        (progn (save-excursion
                                                 (skip-syntax-backward "w_")
                                                 (point))))))

(defun li3-logs ()
  "Set logs list."
  (if (li3-set-app-path)
      (mapcar
       (function (lambda (el)
                   (if (listp el) el(cons el el))))
       (directory-files (concat li3-app-path "tmp/logs/") nil "\\.log$"))
    nil))

(defun li3-tail-log (log)
  "Show log by \"tail\"."
  (interactive
   (list (completing-read "tail log: " (li3-logs) nil t "debug.log")))
  (if (require 'tail nil t)             ;xcezx patch.
      (tail-file (concat li3-app-path "tmp/logs/" log))
    (let ((logbuffer (concat "*" log "*")))
      (if (and (li3-logs) (executable-find "tail"))
          (progn
            (unless (get-buffer logbuffer)
              (get-buffer-create logbuffer)
              (set-buffer logbuffer)
              (insert-before-markers (concat "tail -f" li3-app-path "tmp/logs/" log "\n"))
              (setq buffer-read-only t)
              (start-process "tail" logbuffer "tail" "-f" (concat li3-app-path "tmp/logs/" log)))
            (switch-to-buffer logbuffer))
        (message "Can't set log.")))))

(defun li3-singularize (str)
  "Singularize str"
  (interactive)
  (let ((result str))
    (loop for rule in cake-singular-rules do
          (unless (not (string-match (nth 0 rule) str))
            (setq result (replace-match (nth 1 rule) nil nil str))
            (return result)))))
;;(li3-singularize "cases")

(defun li3-pluralize (str)
  "Pluralize str"
  (interactive)
  (let ((result str))
    (loop for rule in cake-plural-rules do
          (unless (not (string-match (nth 0 rule) str))
            (setq result (replace-match (nth 1 rule) nil nil str))
            (return result)))))
;;(li3-pluralize "case")

(defun li3-camelize (str)
  "Change snake_case to Camelize."
  (let ((camelize-str str) (case-fold-search nil))
    (setq camelize-str (capitalize (downcase camelize-str)))
    (replace-regexp-in-string
     "_" ""
     camelize-str)))
;;(li3-camelize "li3_camelize")

(defun li3-lower-camelize (str)
  "Change snake_case to lowerCamelize."
  (let ((head-str "") (tail-str "") (case-fold-search nil))
    (if (string-match "^\\([a-z]+_\\)\\([a-z0-9_]*\\)" (downcase str))
        (progn
          (setq head-str (match-string 1 (downcase str)))
          (setq tail-str (match-string 2 (capitalize str)))
          (if (string-match "_" head-str)
              (setq head-str (replace-match "" t nil head-str)))
          (while (string-match "_" tail-str)
            (setq tail-str (replace-match "" t nil tail-str)))
          (concat head-str tail-str))
      str)))
;;(li3-lower-camelize "li3_lower_camelize")

(defun li3-snake (str) ;;copied from rails-lib.el
  "Change snake_case."
  (let ((case-fold-search nil))
    (downcase
     (replace-regexp-in-string
      "\\([A-Z]+\\)\\([A-Z][a-z]\\)" "\\1_\\2"
      (replace-regexp-in-string
       "\\([a-z\\d]\\)\\([A-Z]\\)" "\\1_\\2"
       str)))))
;;(li3-snake "Li3Snake")
;;(li3-snake "CLi3Snake")

;;; anything sources and functions

(when (require 'anything-show-completion nil t)
  (use-anything-show-completion 'anything-c-li3-anything-only-function
                                '(length li3-initial-input)))

(defvar li3-candidate-function-name nil)

(defvar anything-c-source-li3
  '((name . "Li3 Switch")
    (init
     . (lambda ()
         (if
             (and (li3-set-app-path) (executable-find "grep"))
             (with-current-buffer (anything-candidate-buffer 'local)
               (call-process-shell-command
                (concat "grep '[^_]function' "
                        li3-app-path
                        "controllers/*Controller.php --with-filename")
                nil (current-buffer))
               (call-process-shell-command
                (concat "grep '[^_]function' "
                        li3-app-path
                        "*Controller.php --with-filename")
                nil (current-buffer))
               (goto-char (point-min))
               (while (re-search-forward ".+\\/\\([^\\/]+\\)Controller\.php:.*function *\\([^ ]+\\) *(.*).*$" nil t)
                 (replace-match (concat (match-string 1) " / " (match-string 2))))
               )
           (with-current-buffer (anything-candidate-buffer 'local)
             (call-process-shell-command nil nil (current-buffer)))
           )))
    (candidates-in-buffer)
    (display-to-real . anything-c-li3-set-names)
    (action
     ("Switch to Contoroller" . (lambda (candidate)
                                  (anything-c-li3-switch-to-controller)))
     ("Switch to View" . (lambda (candidate)
                           (anything-c-li3-switch-to-view)))
     ("Switch to Model" . (lambda (candidate)
                            (anything-c-li3-switch-to-model))))))

(defun anything-c-li3-set-names (candidate)
  "Set names by display-to-real"
  (progn
    (string-match "\\(.+\\) / \\(.+\\)" candidate)
    (setq li3-plural-name (match-string 1 candidate))
    (setq li3-action-name (match-string 2 candidate))
    (setq li3-singular-name (li3-singularize li3-plural-name))
    (setq li3-lower-camelized-action-name li3-action-name)
    (setq li3-snake-action-name (li3-snake li3-action-name))))

(defun anything-c-li3-switch-to-view ()
  "Switch to view."
  (progn
    (li3-set-app-path)
    (cond ((file-exists-p (concat li3-app-path "views/" li3-plural-name "/" li3-snake-action-name "." li3-view-extension))
           (find-file (concat li3-app-path "views/" li3-plural-name "/" li3-snake-action-name "." li3-view-extension)))
          ((file-exists-p (concat li3-app-path "views/" li3-plural-name "/" li3-action-name "." li3-view-extension))
           (find-file (concat li3-app-path "views/" li3-plural-name "/" li3-action-name "." li3-view-extension)))
          ((y-or-n-p "Make new file?")
           (unless (file-directory-p (concat li3-app-path "views/" li3-plural-name "/"))
             (make-directory (concat li3-app-path "views/" li3-plural-name "/")))
           (find-file (concat li3-app-path "views/" li3-plural-name "/" li3-action-name "." li3-view-extension)))
          (t (message (format "Can't find %s" (concat li3-app-path "views/" li3-plural-name "/" li3-action-name "." li3-view-extension)))))))

(defun anything-c-li3-switch-to-controller ()
  "Switch to contoroller."
  (li3-set-app-path)
  (if (file-exists-p (concat li3-app-path "controllers/" li3-plural-name "Controller.php"))
      (progn
        (find-file (concat li3-app-path "controllers/" li3-plural-name "Controller.php"))
        (goto-char (point-min))
        (if (not (re-search-forward (concat "function[ \t]*" li3-lower-camelized-action-name "[ \t]*\(") nil t))
            (progn
              (goto-char (point-min))
              (re-search-forward (concat "function[ \t]*" li3-action-name "[ \t]*\(") nil t))))
    (if (file-exists-p (concat li3-app-path li3-plural-name "Controller.php"))
        (progn
          (find-file (concat li3-app-path li3-plural-name "Controller.php"))
          (goto-char (point-min))
          (if (not (re-search-forward (concat "function[ \t]*" li3-lower-camelized-action-name "[ \t]*\(") nil t))
              (progn
                (goto-char (point-min))
                (re-search-forward (concat "function[ \t]*" li3-action-name "[ \t]*\(") nil t))))
      (if (y-or-n-p "Make new file?")
          (find-file (concat li3-app-path "controllers/" li3-plural-name "Controller.php"))
        (message (format "Can't find %s" (concat li3-app-path "controllers/" li3-plural-name "Controller.php")))))))

(defun anything-c-li3-switch-to-model ()
  "Switch to model."
  (li3-set-app-path)
  (if (file-exists-p (concat li3-app-path "models/" li3-singular-name ".php"))
      (find-file (concat li3-app-path "models/" li3-singular-name ".php"))
    (if (y-or-n-p "Make new file?")
        (find-file (concat li3-app-path "models/" li3-singular-name ".php"))
      (message (format "Can't find %s" (concat li3-app-path "models/" li3-singular-name ".php"))))))

(defun anything-c-li3-switch-to-file-function (dir)
  "Switch to file and search function."
  (li3-set-app-path)
  (if (not (file-exists-p (concat li3-app-path dir li3-singular-name ".php")))
      (if (y-or-n-p "Make new file?")
          (find-file (concat li3-app-path dir li3-singular-name ".php"))
        (message (format "Can't find %s" (concat li3-app-path dir li3-singular-name ".php"))))
    (find-file (concat li3-app-path dir li3-singular-name ".php"))
    (goto-char (point-min))
    (re-search-forward (concat "function[ \t]*" li3-candidate-function-name "[ \t]*\(") nil t)))

(defvar anything-c-source-li3-model-function
  '((name . "Li3 Model Function Switch")
    (init
     . (lambda ()
         (if
             (and (li3-set-app-path) (executable-find "grep"))
             (with-current-buffer (anything-candidate-buffer 'local)
               (call-process-shell-command
                (concat "grep '[^_]function' "
                        li3-app-path
                        "models/*.php --with-filename")
                nil (current-buffer))
               (goto-char (point-min))
               (while (not (eobp))
                 (if (not (re-search-forward ".+\\/\\(.+\\)\.php:.*function *\\([^ ]+\\) *(.*).*" nil t))
                     (goto-char (point-max))
                   (setq class-name (li3-camelize (match-string 1)))
                   (setq function-name (match-string 2))
                   (delete-region (point) (save-excursion (beginning-of-line) (point)))
                   (insert (concat class-name "->" function-name))
                   )))
           (with-current-buffer (anything-candidate-buffer 'local)
             (call-process-shell-command nil nil (current-buffer)))
           )))
    (candidates-in-buffer)
    (display-to-real . anything-c-li3-set-names2)
    (action
     ("Switch to Function" . (lambda (candidate)
                               (anything-c-li3-switch-to-file-function "models/")))
     ("Insert" . (lambda (candidate)
                   (insert candidate))))))

(defun anything-c-li3-set-names2 (candidate)
  "Set names by display-to-real"
  (progn
    (string-match "\\(.+\\)->\\(.+\\)" candidate)
    (setq li3-camelized-singular-name (match-string 1 candidate))
    (setq li3-candidate-function-name (match-string 2 candidate))
    (setq li3-singular-name (li3-snake li3-camelized-singular-name))))

(defun anything-c-li3-anything-only-source-li3 ()
  "anything only anything-c-source-li3 and anything-c-source-li3-model-function."
  (interactive)
  (anything (list anything-c-source-li3
                  anything-c-source-li3-model-function)
            nil "Find Lithium Sources: " nil nil))

(defun anything-c-li3-anything-only-function ()
  "anything only anything-c-source-li3-function."
  (interactive)
  (let* ((initial-pattern (regexp-quote (or (thing-at-point 'symbol) ""))))
    (anything (list anything-c-source-li3-model-function) initial-pattern "Find Li3 Functions: " nil)))

(defun anything-c-li3-anything-only-model-function ()
  "anything only anything-c-source-li3-model-function."
  (interactive)
  (let* ((initial-pattern (regexp-quote (or (thing-at-point 'symbol) ""))))
    (anything '(anything-c-source-li3-model-function) initial-pattern "Find Model Functions: " nil)))

;; mode provide
(provide 'li3)

;;; end
;;; li3.el ends here