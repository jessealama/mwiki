;;; packages.lisp --- The packages defined and used by mwiki

(in-package :cl-user)

(defpackage :mwiki
  (:use :cl :hunchentoot :alexandria :cl-ppcre :com.gigamonkeys.pathnames))

;;; packages.lisp ends here