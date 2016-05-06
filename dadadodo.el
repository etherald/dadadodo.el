;;; dadadodo.el --- Use the dadadodo program to generate markovian text

;; Copyright (C) 2016 E.T. Herald

;; Author: E.T. Herald
;; URL: http://github.com/etherald/dadadodo.el
;; Version: 0.1
;; Package-version: 0.1
;; Keywords: games, markov
;; Package-Requires: ((cl-lib "0.5"))


;;; Commentary:

;; requires the dadadodo program <http://jwz.org/dadadodo>
;; apt-get install dadadodo

(require 'cl)

(defvar dadadodo-input-file-path "~/txt")
(defvar dadadodo-default-count 7)

(defalias 'dodo-file 'dadadodo-file)
(defalias 'dodo-region 'dadadodo-region)
(defalias 'dodo-buffer 'dadadodo-buffer)
(defalias 'dodo-dir 'dadadodo-directory)
(defalias 'dodo-buffers-in-mode 'dadadodo-buffers-in-mode)
(defalias 'dodo-dired-marked-files 'dadadodo-dired-marked-files)
(defalias 'diredodo 'dadadodo-dired-marked-files)

(defun dadadodo-region (start end &optional count)
  (interactive "r")
  (setq fname (make-temp-file "dadadodo"))
  (append-to-file start end fname)
  (dadadodo-file fname count))

(defun dadadodo-buffer (&optional count)
  (interactive "p")
  (if (buffer-file-name)
      (dadadodo-file (shell-quote-argument (buffer-file-name)) count)
    (dadadodo-region (point-min) (point-max) count)))

(defun dadadodo-file (patharg &optional count)
  (interactive "fChoose file: ")
  (save-excursion
    (with-current-buffer (pop-to-buffer "*dadadodo*")
      (insert (shell-command-to-string
               (format "dadadodo -c %d %s 2>/dev/null"
                       (or count current-prefix-arg dadadodo-default-count)
                       patharg))))))

(defun dadadodo-directory (dir)
  ;; use prefix arg to select # random files instead of whole dir
  (interactive (list (read-directory-name "Choose directory: "
                                          dadadodo-input-file-path)))
  (setf files (directory-files dir t "^[^\.\#]"))
  (dadadodo-file
   (mapconcat 'shell-quote-argument
              (dadadodo--list-shuffle
               (subseq files 0 (min 8 (length files)))) " ")))

(defun dadadodo-dired-marked-files ()
  (interactive)
  (unless (memq major-mode '(dired-mode vc-dired-mode))
    (error (format "%s can only be called in dired mode"
                   real-this-command)))
  (save-excursion
    (dired-do-shell-command
     (format "dadadodo -c %d * 2>/dev/null" dadadodo-default-count)
     ;;current-prefix-arg
     nil
     (dired-get-marked-files))
    (with-current-buffer "*Shell Command Output*"
      (setf str (buffer-string)))
    (kill-buffer "*Shell Command Output*")
    (with-current-buffer (pop-to-buffer "*dadadodo*") (insert-string str))))

(defun dadadodo-buffers-in-mode (buf)
  (interactive "b")
  (with-temp-buffer "*dadadodo-temp*"
                    (mapcar 'insert-buffer-substring-no-properties
                            (get-buffers-matching-mode (buffer-mode buf)))
                    (dadadodo-buffer)))

(defun dadadodo--list-swap (LIST el1 el2)
  "in LIST swap indices EL1 and EL2 in place"
  (let ((tmp (elt LIST el1)))
    (setf (elt LIST el1) (elt LIST el2))
    (setf (elt LIST el2) tmp)))

(defun dadadodo--list-shuffle (LIST)
  "Shuffle the elements in LIST.
shuffling is done in place."
  (loop for i in (reverse (number-sequence 1 (1- (length LIST))))
        do (let ((j (random (+ i 1))))
             (dadadodo--list-swap LIST i j)))
  LIST)


(provide 'dadadodo)
