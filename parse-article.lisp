;;; parse-article.lisp --- A simple HTTP service that emits mizar parse trees

(in-package :mwiki)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Temporary files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun stream-lines (stream)
  (when stream
    (let (lines)
      (symbol-macrolet
	  (($line (read-line stream nil nil)))
	(do ((line $line $line))
	    ((null line))
	  (push line lines)))
      (reverse lines))))

(defun lines-of-file (path)
  (let (lines)
    (with-open-file (file path :direction :input
			       :if-does-not-exist :error)
      (symbol-macrolet
	  (($line (read-line file nil nil)))
	(do ((line $line $line))
	    ((null line))
	  (push line lines))))
    (reverse lines)))

(defgeneric replace-extension (path old-extension new-extension))

(defmethod replace-extension ((path string) old-extension new-extension)
  (pathname (concatenate 'string
			 (subseq path 0 (- (length path)
					   (length old-extension)))
			 new-extension)))

(defmethod replace-extension ((path pathname) old-extension new-extension)
  (replace-extension (namestring path) old-extension new-extension))

(defun temporary-file (&key (base "") (extension "") (tmp-dir "/tmp"))
  (if (or (stringp tmp-dir)
	  (pathnamep tmp-dir))
      (if (stringp extension)
	  (if (scan "^\\.?[a-zA-Z0-9]*$" extension)
	      (if (stringp base)
		  (if (scan "^[A-Za-z]*$" base)
		      (register-groups-bind (real-ext)
			  ("^\\.?([a-zA-Z0-9]*)$" extension)
			(let ((real-tmp-dir (pathname-as-directory tmp-dir)))
			  (if (directory-p real-tmp-dir)
			      (loop
				 with real-tmp-dir-name = (namestring real-tmp-dir)
				 for i from 1 upto 1000
				 for tmp-path = (if (string= real-ext "")
						    (format nil "~a/~a~d" real-tmp-dir-name base i)
						    (format nil "~a/~a~d.~a" real-tmp-dir-name base i real-ext))
				 do
				   (unless (probe-file tmp-path)
				     (return (pathname tmp-path)))
				 finally
				   (if (string= base "")
				       (error "We have run out of temporary file names in ~a!" tmp-dir)
				       (error "We have run out of temporary file names in ~a! with the base name ~a" tmp-dir base)))
			      (error "We cannot understand '~a' as a directory" tmp-dir))))
		      (error "BASE must consist of alphanumeric characters only; '~a' is not a suitable argument" base))
		  (error "BASE must be a string; '~a' is not a suitable argument" base))
	      (error "EXTENSION must be a string consisting of alphanumeric characters, possibly beginning with a period '.'; '~a' is not a suitable argument" extension))
	  (error "EXTENSION must be a string (possibly the empty string); '~a' is not a suitable value" extension))
      (error "TMP-DIR must be either a string or a pathname; '~a' is not a suitable argument" tmp-dir)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Running programs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; stolen from mizar-item's utils.lisp

(defun run-program (program args &key search input output error wait if-output-exists)
  #+sbcl
  (sb-ext:run-program program
		      args
		      :search t
		      :input nil
		      :output nil
		      :error nil
		      :wait wait
		      :if-output-exists if-output-exists)
  #+ccl
  (ccl:run-program program
		   args
		   :input input
		   :output output
		   :error error
		   :wait wait
		   :if-output-exists if-output-exists))

(defun process-exit-code (process)
  #+sbcl
  (sb-ext:process-exit-code process)
  #+ccl
  (multiple-value-bind (status exit-code)
      (ccl:external-process-status process)
    (declare (ignore status))
    exit-code))

(defun process-output (process)
  #+sbcl
  (sb-ext:process-output process)
  #+ccl
  (ccl:external-process-output-stream process))

(defun process-error (process)
  #+sbcl
  (sb-ext:process-error process)
  #+ccl
  (ccl:external-process-error-stream process))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Server configuration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar *mwiki-dispatch-table* nil
  "The hunchentoot dispatch table used by mwiki.")

(define-constant +unsupported-methods+
    (list :put :delete :trace :connect :post)
  :test #'set-equal
  :documentation "A list of those HTTP methods which are not supported for any resource")

(defmacro parse-article-reply (return-code)
  `(progn
     (setf (return-code *reply*) ,return-code)
     (setf (content-length* *reply*) 0)
     (setf (header-out "Allow") "OPTIONS, GET, HEAD")
     (setf (content-type*) "text/plain")
     (send-headers)))

(defun respond-to-unhandled-request ()
  (parse-article-reply +http-method-not-allowed+))

(defun respond-to-options ()
  (parse-article-reply +http-ok+))

(define-constant +largest-article-length+ 100000
  :documentation "We will reject articles that have more than this many bytes."
  :test #'=)

(defun mwiki-request-dispatcher (request)
  "Selects a request handler based on a list of individual request
dispatchers all of which can either return a handler or neglect by
returning NIL."
  (let ((method (request-method*))
	(text (get-parameter "text")))
    (if text
	(cond ((member method +unsupported-methods+)
	       (respond-to-unhandled-request))
	      ((> (length text) +largest-article-length+)
	       (parse-article-reply +http-request-entity-too-large+))
	      ((eq method :options)
	       (respond-to-options))
	      (t
	       (loop
		  for dispatcher in *mwiki-dispatch-table*
		  for action = (funcall dispatcher request)
		  when action return
		    (let ((response (funcall action)))
		      (setf (content-length* *reply*) (length response))
		      (if (eq method :head)
			  (send-headers) ;; stop now
			  response))
		  finally
		    (parse-article-reply +http-bad-request+))))
	(parse-article-reply +http-not-found+))))

(defvar *acceptor*
  (make-instance 'hunchentoot:acceptor
		 :port 4531
		 :request-dispatcher #'mwiki-request-dispatcher))

(defun startup-server ()
  (unless (hunchentoot::acceptor-listen-socket *acceptor*)
    (hunchentoot:start *acceptor*))
  (setf *message-log-pathname* "/tmp/mizar-parse-service-messages"
	*access-log-pathname* "/tmp/mizar-parse-service-access"
	*handle-http-errors-p* nil
	*log-lisp-errors-p* t
	*log-lisp-warnings-p* t
	*log-lisp-backtraces-p* t
	*show-lisp-errors-p* t)
  (initialize-uris)
  (format t "Ready.")
  (terpri)
  t)

(defun shutdown-server ()
  (stop *acceptor*))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Invoking accommodator and newparser
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun accom (text)
  (declare (ignore text))
  (values t ""))

(defun newparser (text)
  (let* ((temp-miz-path (temporary-file :base "p" :extension "miz"))
	 (temp-err-path (replace-extension temp-miz-path "miz" "err"))
	 (temp-wsx-path (replace-extension temp-miz-path "miz" "wsx")))
    (write-string-into-file text
			    temp-miz-path
			    :if-exists :error
			    :if-does-not-exist :create)
    (open temp-err-path :direction :probe) ;; ensure existence of .err
    (let ((accom-proc (run-program "accom"
				   (list "-q" "-l" (namestring temp-miz-path))
				   :search t
				   :output nil
				   :input nil
				   :wait t)))
      (if (zerop (process-exit-code accom-proc))
	  (let ((newparser-proc (run-program "newparser"
					     (list "-q" "-l" (namestring temp-miz-path))
					     :search t
					     :output nil
					     :input nil
					     :wait t)))
	    (if (zerop (process-exit-code newparser-proc))
		(if (file-exists-p temp-wsx-path)
		    (values t
			    (format nil "~{~a~%~}" (lines-of-file temp-wsx-path)))
		    (values nil
			    "Although newparser exited cleanly, it did not generate a .wsx file!"))
		(values nil
			(format nil "~{~a~%~}" (lines-of-file temp-err-path)))))
	  (values nil
		  (format nil "~{~a~%~}" (lines-of-file temp-err-path)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Our supported URIs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro register-regexp-dispatcher (uri-regexp dispatcher)
  `(progn
     (push (create-regex-dispatcher ,uri-regexp ,dispatcher)
	   *mwiki-dispatch-table*)
     t))

(defun parse-and-emit-mizar ()
  (let ((text (get-parameter "text")))
    (multiple-value-bind (newparser-ok newparser-explanation)
	(newparser text)
      (unless newparser-ok
	(setf (return-code *reply*) +http-bad-request+))
      newparser-explanation)))

(defun initialize-uris ()
  (register-regexp-dispatcher "^/$" #'parse-and-emit-mizar))

;;; parse-article.lisp ends here