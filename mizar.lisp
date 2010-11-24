
(in-package :mizar)

(defparameter *mizfiles* 
  (sb-ext:posix-getenv "MIZFILES")
  "The directory that contains the MML and the mml.lar file.

The default value is the value of the MIZFILES environment
variable (at load time).")

(defun run-mizar-utility (utility)

;;; mizar.lisp ends here