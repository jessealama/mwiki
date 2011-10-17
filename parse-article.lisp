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

(defun file-as-string (path)
  (let ((newline (make-string 1 :initial-element #\Newline))
	(lines (lines-of-file path)))
    (if lines
	(reduce #'(lambda (s1 s2)
		    (concatenate 'string s1 newline s2))
		(lines-of-file path))
	"")))

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
     (setf (content-type*) "application/xml")
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

(defparameter *error-explanations*
  (list '(1 . "It is not true")
	'(4 . "This inference is not accepted")
	'(8 . "Too many instantiations")
	'(9 . "Too many instantiations")
	'(10 . "Too many basic sentences in an inference")
	'(11 . "Too many constants in an inference")
	'(12 . "Too long universal prefix")
	'(13 . "Too many complexes")
	'(14 . "Too many terms in an inference")
	'(15 . "Too many equalities in an inference")
	'(16 . "Collection overflow")
	'(20 . "The structure of the sentences disagrees with the scheme")
	'(21 . "Invalid instantiation of a scheme functor")
	'(22 . "Invalid instantiation of a scheme predicate")
	'(23 . "Invalid order of arguments in the instantiated predicate")
	'(24 . "Instantiations of the same scheme predicate do not match")
	'(25 . "Instantiations of the same scheme constant do not match")
	'(26 . "Substituted constant does not expand properly")
	'(27 . "Invalid instantiation of a scheme constant")
	'(28 . "Invalid list of arguments of a functor")
	'(29 . "Instantiations of the same scheme functor do not match")
	'(30 . "Invalid type of the instantiated functor")
	'(31 . "Disagreement of correspondents of a constant")
	'(32 . "Too many fillings of a functor")
	'(33 . "Too many fillings of a predicate")
	'(40 . "Non-unique matching of a locus of the substitute of a predicate variable")
	'(41 . "Non-unique matching of a locus of the substitute of a functor variable")
	'(42 . "Non-unique matching of a locus of the substitute of a functor variable")
	'(43 . "Cannot decompose a conjunction of formal sentences")
	'(44 . "Formal predicate in a Fraenkel operator of formal construction")
	'(45 . "Wrong order of the declarations of scheme functor or nested functor")
	'(46 . "Probably the incorporation of an argument")
	'(50 . "Nongeneralizable variable in the skeleton of a reasoning")
	'(51 . "Invalid conclusion")
	'(52 . "Invalid assumption")
	'(53 . "Invalid case")
	'(54 . "The cases are not exhausted")
	'(55 . "Invalid generalization")
	'(56 . "Disagreement of types")
	'(57 . "The type of the instatiated term doesn't widen properly")
	'(58 . "Mixing \"case\" with \"suppose\" is not allowed in one \"per cases\" reasoning")
	'(59 . "The theses in each case should be equal formulae")
	'(60 . "Something remains to be proved in this case")
	'(62 . "Free variables not allowed in an iterative equality")
	'(63 . "Unexpected proof")
	'(64 . "Invalid exemplification in a diffuse statement")
	'(65 . "\"thesis\" is only allowed inside a proof")
	'(66 . "\"axiom\" is only allowed in an axiomatic file")
	'(68 . "Nongeneralizable variable in the skeleton of a reasoning")
	'(69 . "Nongeneralizable variable in a definiens")
	'(70 . "Something remains to be proved")
	'(72 . "Unexpected correctness condition")
	'(73 . "Correctness condition missing")
	'(76 . "Registration correctness condition mismatch")
	'(77 . "Still not implemented")
	'(78 . "The type of the argument must widen to the result type")
	'(79 . "Types of arguments must be equal")
	'(80 . "Cannot be used in a permissive definition")
	'(81 . "It is only meaningful for binary predicates")
	'(82 . "It is only meaningful for binary functors")
	'(83 . "It is only meaningful for unary functors")
	'(84 . "The result type is not invariant under swapping the arguments")
	'(85 . "The result type must widen to the type of the argument")
	'(89 . "As yet not implemented for redefined functors")
	'(90 . "Attributes are not allowed in a prefix")
	'(91 . "Homonymic fields in structure declaration")
	'(92 . "Type of the field must be equal to the type in prefix")
	'(93 . "Missing field of a prefix")
	'(94 . "Prefix must be a structure")
	'(95 . "Inconsistent cluster")
	'(96 . "Only standard functors and selectors can be used in a functorial cluster registration")
	'(97 . "Non clusterable attribute")
	'(98 . "Cannot mix left and right pattern arguments")
	'(99 . "The argument(s) must belong to the left or right pattern")
	'(100 . "Unused locus")
	'(101 . "Unknown mode")
	'(102 . "Unknown predicate")
	'(103 . "Unknown functor")
	'(104 . "Unknown structure")
	'(105 . "Illegal projection")
	'(106 . "Unknown attribute")
	'(107 . "Invalid list of arguments of redefined constructor")
	'(108 . "Invalid list of arguments of redefined constructor")
	'(109 . "Invalid order of arguments of redefined constructor")
	'(110 . "Only nullary prefixes are allowed")
	'(111 . "Non registered attribute cluster")
	'(112 . "Unknown predicate")
	'(113 . "Unknown functor")
	'(114 . "Unknown mode")
	'(115 . "Unknown attribute")
	'(116 . "Invalid \"qua\"")
	'(117 . "Invalid specification")
	'(118 . "Invalid specification")
	'(119 . "Illegal cluster")
	'(120 . "Disagreement of argument types")
	'(121 . "Disagreement of argument types")
	'(122 . "Disagreement of argument types")
	'(123 . "Disagreement of argument types")
	'(124 . "Disagreement of argument types")
	'(125 . "Argument of a selector must be a structure")
	'(126 . "Unknown selector functor")
	'(127 . "Argument must be an elementary type")
	'(128 . "Arguments must be elementary types")
	'(129 . "Invalid free variables in a Fraenkel operator")
	'(130 . "Redefinition of an attribute with predicate pattern is not allowed")
	'(131 . "No reserved type for a variable, free in the default type")
	'(132 . "Invalid \"exactly\"")
	'(133 . "Cannot cluster attribute with arguments")
	'(134 . "Cannot redefine expandable mode")
	'(135 . "Inaccessible selector")
	'(136 . "Non registered cluster")
	'(137 . "\"SUBSET\" missing in the \"requirements\" directive")
	'(138 . "Cannot identify a local constant, free in the default type")
	'(139 . "Invalid type of an argument. ")
	'(140 . "Unknown variable")
	'(141 . "Locus repeated")
	'(142 . "Unknown locus")
	'(143 . "No implicit qualification")
	'(144 . "Unknown label")
	'(145 . "Inaccessible label")
	'(146 . "Theorem number must be greater than 0")
	'(147 . "Unknown theorems file")
	'(148 . "Unknown private functor")
	'(149 . "Unknown private predicate")
	'(150 . "A variable free in default type has explicit qualification")
	'(151 . "Unknown mode format")
	'(152 . "Unknown functor format")
	'(153 . "Unknown predicate format")
	'(154 . "Unknown field")
	'(155 . "Unknown prefix")
	'(156 . "Invalid equality format")
	'(157 . "Exactly one term is expected before \"is\"")
	'(158 . "Two different formats for a structure symbol")
	'(159 . "Invalid iterative equality")
	'(160 . "This variable still cannot be accessed")
	'(161 . "Fixed variables cannot be postqualified")
	'(162 . "A free variable identified with a new implicit qualification")
	'(163 . "Disagreement of reservations of a free variable")
	'(164 . "Nothing to link")
	'(165 . "Unknown functor format")
	'(166 . "Unknown functor format")
	'(167 . "Unknown functor format")
	'(168 . "Unknown functor format")
	'(169 . "Unknown functor format")
	'(170 . "Unknown functor format")
	'(171 . "Unknown functor format")
	'(172 . "Unknown functor format")
	'(173 . "Unknown functor format")
	'(174 . "Unknown functor format")
	'(175 . "Unknown attribute format")
	'(176 . "Unknown structure format")
	'(177 . "Link assumes a straightforward justification")
	'(178 . "Link assumes a straightforward justification")
	'(179 . "It is not a locus")
	'(180 . "Too many arguments")
	'(181 . "Not so many arguments in this definition")
	'(182 . "Unknown selector format")
	'(183 . "Accessible mode format has empty list of arguments")
	'(184 . "Accessible structure format has empty list of arguments")
	'(185 . "Unknown structured mode format")
	'(186 . "\"equals\" is only allowed for functors")
	'(189 . "Left and right pattern must have the same number of arguments")
	'(190 . "Inaccessible theorem")
	'(191 . "Unknown scheme")
	'(192 . "Inaccessible theorem")
	'(193 . "Inaccessible scheme")
	'(194 . "Wrong number of premises")
	'(195 . "Scheme uses constructors which are not in your environment")
	'(196 . "Unknown scheme")
	'(197 . "Scheme definition repeated")
	'(198 . "It is meaningless to define an antonym to a functor or a mode")
	'(199 . "Inaccessible definitional theorem")
	'(200 . "Too long source line")
	'(201 . "Only characters with decimal ASCII codes between 32 and 126 are allowed")
	'(202 . "Too large numeral")
	'(203 . "Unknown token, maybe an illegal character used in an identifier")
	'(210 . "Wrong item in environment declaration")
	'(211 . "Unexpected \"environ\"")
	'(212 . "\"environ\" expected")
	'(213 . "\"begin\" missing")
	'(214 . "\"end\" missing")
	'(215 . "No pairing \"end\" for this word")
	'(216 . "Unexpected \"end\"")
	'(217 . "\";\" missing")
	'(218 . "Unexpected \"(\" - parenthesizing attributes is not allowed")
	'(219 . "Unexpected \"proof\"")
	'(220 . "Local predicates are not allowed in library items ")
	'(221 . "Local functors are not allowed in library items")
	'(222 . "Local constants are not allowed in library items  ")
	'(223 . "Adjective cluster expected")
	'(228 . "Unexpected \"reconsider\"")
	'(229 . "\"redefine\" repeated")
	'(230 . "Only one \"per cases\" is allowed in a reasoning")
	'(231 . "\"per cases\" missing")
	'(232 . "\"case\" or \"suppose\" expected")
	'(240 . "Definition blocks must not be nested")
	'(241 . "Directives are not allowed in the text proper")
	'(242 . "\"reserve\", \"struct\", \"scheme\" and \"theorem\" not allowed in a definition block")
	'(250 . "\"$1\",...,\"$10\" are only allowed inside the definiens of a private constructor")
	'(251 . "\"it\" is only allowed inside the definiens of a public functor or mode")
	'(253 . "\"means\" or \"equals\" expected")
	'(255 . "It is not allowed for expandable modes")
	'(256 . "\"of\" expected")
	'(271 . "Redefined mode cannot be expandable")
	'(272 . "It is meaningless to redefine a cluster")
	'(273 . "\"redefine\" is not allowed here")
	'(274 . "\"means\" not allowed in a definition of an expandable mode")
	'(300 . "Identifier expected")
	'(301 . "Predicate symbol expected")
	'(302 . "Functor symbol expected")
	'(303 . "Mode symbol expected")
	'(304 . "Structure symbol expected")
	'(305 . "Selector symbol expected")
	'(306 . "Attribute symbol expected")
	'(307 . "Numeral expected")
	'(308 . "Identifier or theorem file name expected")
	'(309 . "Mode symbol or attribute symbol expected")
	'(310 . "Right functor bracket expected")
	'(311 . "Paired functor brackets must be of the same kind")
	'(312 . "Scheme reference is not allowed in a simple justification")
	'(313 . "\"sch\" expected")
	'(314 . "Incorrect beginning of a pattern")
	'(315 . "Mode \"set\" cannot be parametrized")
	'(320 . "Selector or structure symbol expected")
	'(321 . "Predicate symbol or \"is\" expected")
	'(329 . "Selector without arguments is only allowed inside a structure pattern")
	'(330 . "Unexpected end of an item (perhaps \";\" missing)")
	'(336 . "Associative notation must not be used for \"iff\" and \"implies\"")
	'(340 . "\"holds\", \"for\" or \"ex\" expected")
	'(350 . "\"that\" expected")
	'(351 . "\"cases\" expected")
	'(360 . "\"(\" expected")
	'(361 . "\"[\" expected")
	'(362 . "\"{\" expected")
	'(363 . "\"(#\" expected")
	'(364 . "\"(\" or \"[\" expected")
	'(370 . "\")\" expected")
	'(371 . "\"]\" expected")
	'(372 . "\"}\" expected")
	'(373 . "\"#)\" expected")
	'(374 . "Incorrect order of arguments in an attribute definition")
	'(375 . "Wrong beginning of a cluster registration")
	'(376 . "Incorrect functorial registration - addjectives expected")
	'(377 . "Incorrect conditional registration - type expected")
	'(378 . "Parenthesizing adjective clusters is not allowed")
	'(379 . "Term list is not allowed here")
	'(380 . "\"=\" expected")
	'(381 . "\"if\" expected")
	'(382 . "\"for\" expected")
	'(383 . "\"is\" expected")
	'(384 . "\":\" expected")
	'(385 . "\"->\" expected")
	'(386 . "\"means\" or \"equals\" expected")
	'(387 . "\"st\" expected")
	'(388 . "\"as\" expected")
	'(389 . "\"proof\" expected")
	'(390 . "\"and\" expected")
	'(391 . "Incorrect beginning of a text item")
	'(392 . "Incorrect beginning of a definition item")
	'(393 . "Incorrect beginning of a reasoning item")
	'(394 . "Statement expected")
	'(395 . "Justification expected")
	'(396 . "Formula expected")
	'(397 . "Term expected")
	'(398 . "Type expected")
	'(399 . "Functor pattern expected")
	'(400 . "Still not implemented")
	'(401 . "\"not\" expected")
	'(402 . "A bare infinitive expected")
	'(403 . "\"such\" expected")
	'(404 . "\"to\" expected")
	'(405 . "\"for\" expected")
	'(406 . "\"for\" or \"->\" expected")
	'(450 . "Too many variables")
	'(451 . "Too many predicate formats")
	'(452 . "Too many functor formats")
	'(453 . "Too many mode formats")
	'(454 . "Too large theorem number")
	'(455 . "Too many labels in a definition block")
	'(456 . "Too many references in an inference")
	'(458 . "Too many private predicates")
	'(459 . "Too many private functors")
	'(460 . "Too many reserved identifiers")
	'(461 . "Too many free variables")
	'(462 . "Too many modes")
	'(465 . "Too many predicates")
	'(466 . "Too many functors")
	'(467 . "Too many structures")
	'(468 . "Too many selectors")
	'(469 . "Too many loci")
	'(470 . "Too complicated term")
	'(471 . "Too many selectors in one structure definition")
	'(472 . "Too many references")
	'(473 . "Too many premisses in a simple justification")
	'(474 . "Too complicated term")
	'(476 . "Too many default signature files")
	'(477 . "Too many predicate, mode or functor symbols")
	'(478 . "Too many labels")
	'(479 . "Too many loci in one definition block")
	'(480 . "Too many default vocabulary files")
	'(481 . "Too many functor symbols in default vocabulary files")
	'(482 . "Too many free variable scopes")
	'(483 . "Too many variables")
	'(484 . "Too many reservations")
	'(485 . "Too nested reasoning")
	'(486 . "Too many functor formats")
	'(487 . "Too many scheme identifiers")
	'(488 . "Too many unreserved free variables")
	'(489 . "Memory handling in unifier failed")
	'(490 . "Too many free variables in reservations")
	'(491 . "Too many structure formats")
	'(492 . "Too many functor formats")
	'(493 . "Too many parameters in one scheme")
	'(494 . "Too complicated scheme (too many external variables)")
	'(495 . "Too complicated scheme (too many occurrences of a functor variable)")
	'(496 . "Too complicated scheme (too many occurrences of a predicate variable)")
	'(497 . "Too many functor symbols")
	'(498 . "Too many occurrences of arguments of a second order variable")
	'(499 . "Too many errors")
	'(601 . "Irrelevant label")
	'(602 . "Irrelevant reference")
	'(603 . "Irrelevant linking")
	'(604 . "Irrelevant inference")
	'(605 . "Irrelevant linked inference")
	'(607 . "Justification can be straightforward")
	'(608 . "Linkable statement")
	'(609 . "Irrelevant \"that\"")
	'(610 . "Beginning of an inaccessible item")
	'(611 . "End of an inaccessible item")
	'(612 . "Beginning of inaccessible conditions")
	'(613 . "End of inaccessible conditions")
	'(614 . "Duplicated label identifier")
	'(615 . "Unexpected \"@proof\"")
	'(616 . "\"be\" recommended")
	'(703 . "Unnecessary \"proof thus thesis; end;\"")
	'(704 . "Irrelevant signature directive")
	'(706 . "Unnecessary item in the \"theorems\" directive")
	'(707 . "Unnecessary item in the \"schemes\" directive")
	'(708 . "Theorem should be replaced by an equal one")
	'(709 . "Irrelevant item in the \"vocabularies\" directive")
	'(710 . "Irrelevant item in the \"definitions\" directive")
	'(711 . "Identity functor definition")
	'(712 . "Synonym of a functor definition")
	'(713 . "Irrelevant redefinition of a functor")
	'(714 . "Irrelevant redefinition of a mode")
	'(715 . "Irrelevant \"reconsider\" of a variable")
	'(716 . "Irrelevant \"reconsider\" of a term")
	'(717 . "Irrelevant reconsider")
	'(720 . "The first two arguments of the iterative equality are equal")
	'(721 . "The first argument of the iterative equality is equal to the next one")
	'(722 . "The second argument of the iterative equality is equal to the next one")
	'(724 . "This argument of the iterative equality is equal to the next one")
	'(725 . "This argument of the iterative equality is equal to the previous one")
	'(730 . "Redundant reconsidering of variables")
	'(731 . "Redundant reconsidering of terms")
	'(732 . "Redundant reconsidering of a variable")
	'(733 . "Redundant reconsidering of a term")
	'(734 . "Redundant considering")
	'(735 . "Irrelevant variable reservation")
	'(736 . "Unused private functor")
	'(737 . "Unused private predicate")
	'(738 . "Unused variable introduced by \"set\"")
	'(739 . "The variable introduced by \"set\" used only once ")
	'(740 . "Unused variable introduced by \"given\"")
	'(742 . "Unused variable introduced by \"take\"")
	'(743 . "Unused variable introduced by \"consider\"")
	'(746 . "References can be moved to the next step of this iterative equality")
	'(800 . "Library corrupted")
	'(801 . "Cannot find vocabulary file")
	'(802 . "Cannot find formats file")
	'(803 . "Cannot find notations file")
	'(804 . "Cannot find signature file")
	'(805 . "Cannot find definitions file")
	'(806 . "Cannot find theorems file")
	'(807 . "Cannot find schemes file")
	'(808 . "Cannot find constructors file")
	'(809 . "Cannot find registrations file")
	'(810 . "Directive name repeated")
	'(811 . "Invalid priority of a functor symbol on a vocabulary file")
	'(812 . "An empty line on a vocabulary file")
	'(813 . "Invalid qualifier on a vocabulary file")
	'(814 . "Invalid character or space in a symbol")
	'(815 . "A vocabulary symbol repeated")
	'(816 . "Invalid priority")
	'(817 . "An empty symbol")
	'(821 . "A scheme identifier repeated")
	'(825 . "Cannot find constructors name on constructor list")
	'(830 . "Nothing imported from notations")
	'(831 . "Nothing imported from registrations")
	'(832 . "Nothing imported from definitions")
	'(833 . "Nothing imported from theorems")
	'(834 . "Nothing imported from schemes")
	'(855 . "Cannot find requirements file")
	'(856 . "Inaccessible requirements directive")
	'(891 . "MML identifier should be written in capitals")
	'(892 . "MML identifier should be at most eight characters long")
	'(900 . "Too complex skeleton")
	'(911 . "Too long term without parentheses")
	'(912 . "Too long right nesting of a term")
	'(913 . "Too many labels (simultaneously accessible)")
	'(914 . "Too many references in an inference")
	'(915 . "Too many ranges of free variables")
	'(916 . "Too many reservations")
	'(917 . "Too many free variables in reservations")
	'(918 . "Too many variables (simultaneously accessible)")
	'(919 . "Too many reserved identifiers")
	'(920 . "Too many private functors")
	'(921 . "Too many private predicates")
	'(923 . "Too many different clusters")
	'(924 . "Common number of loci exceeded")
	'(925 . "Too many predicate patterns")
	'(926 . "Too many functors")
	'(927 . "Too many functor patterns")
	'(928 . "Too many modes")
	'(929 . "Too many mode patterns")
	'(930 . "Too many attributes")
	'(931 . "Too many attribute patterns")
	'(933 . "Too many structures")
	'(935 . "Too many selectors")
	'(936 . "Too many registered clusters")
	'(937 . "Too many arguments")
	'(938 . "Too many terms")
	'(950 . "Too many schemes")
	'(951 . "Too many imported files")
	'(1001 . "Invalid function number")
	'(1002 . "File not found")
	'(1003 . "Path not found")
	'(1004 . "Too many open files")
	'(1005 . "File access denied")
	'(1006 . "Invalid file handle")
	'(1012 . "Invalid file access code")
	'(1015 . "Invalid drive number")
	'(1016 . "Cannot remove current directory")
	'(1017 . "Cannot rename across drives")
	'(1018 . "No more files")
	'(1100 . "Disk read error")
	'(1101 . "Disk write error")
	'(1102 . "File not assigned")
	'(1103 . "File not open")
	'(1104 . "File not open for input")
	'(1105 . "File not open for output")
	'(1106 . "Invalid numeric format")
	'(1150 . "Disk is write-protected")
	'(1151 . "Bad drive request struct length")
	'(1152 . "Drive not ready")
	'(1154 . "CRC error in data")
	'(1156 . "Disk seek error")
	'(1157 . "Unknown media type")
	'(1158 . "Sector Not Found")
	'(1159 . "Printer out of paper")
	'(1160 . "Device write fault")
	'(1161 . "Device read fault")
	'(1162 . "Hardware failure")
	'(1200 . "Division by zero")
	'(1201 . "Range check error")
	'(1202 . "Stack overflow error")
	'(1203 . "Heap overflow error")
	'(1204 . "Invalid pointer operation")
	'(1205 . "Floating point overflow")
	'(1206 . "Floating point underflow")
	'(1207 . "Invalid floating point operation")
	'(1208 . "Overlay manager not installed")
	'(1209 . "Overlay file read error")
	'(1210 . "Object not initialized")
	'(1211 . "Call to abstract method")
	'(1212 . "Stream registration error")
	'(1213 . "Collection index out of range")
	'(1214 . "Collection overflow error")
	'(1215 . "Arithmetic overflow error")
	'(1216 . "General Protection fault")
	'(1217 . "Segmentation fault")
	'(1255 . "Ctrl Break")
	'(1994 . "I/O stream error: Put of unregistered object type")
	'(1995 . "I/O stream error: Get of unregistered object type")
	'(1996 . "I/O stream error: Cannot expand stream")
	'(1997 . "I/O stream error: Read beyond end of stream")
	'(1998 . "I/O stream error: Cannot initialize stream")
	'(1999 . "I/O stream error: Access error"))
  "Mizar error code explanations.  (Current as of Mizar 7.12.01.)")

(defun escape-double-quote (str)
  (with-output-to-string (s)
    (loop
       for char across str
       do
	 (cond ((char= char #\")
		(format s "\\\""))
	       (t
		(format s "~a" char))))))

(defun err-file-as-xml (err-file)
  "Render the contents of the mizar error file ERR-FILE as an XML document.  The root element of the document is <errors>; children elements are <error> elements with three attributes: line, column, and error-code."
  (with-output-to-string (xml)
    (loop
       initially
	 (format xml "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>")
	 (terpri xml)
	 (format xml "<errors>")
	 (terpri xml)
       for line in (lines-of-file err-file)
       do
	 (register-groups-bind (line-num col-num err-code-str)
	     ("([1-9][0-9]*) ([1-9][0-9]*) ([1-9][0-9]*)" line)
	   (let* ((err-code (parse-integer err-code-str :junk-allowed nil))
		  (explanation (cdr (assoc err-code *error-explanations*))))
	     (format xml "<error line=\"~a\" col=\"~a\" code=\"~d\" explanation=\"~a\">"
		     line-num
		     col-num
		     err-code
		     (if explanation
			 (escape-double-quote explanation)
			 "(no explanation is available)"))
	     (terpri xml)))
       finally
	 (format xml "</errors>")
	 (terpri xml))))

(defun accom (text)
  (declare (ignore text))
  (values t ""))

(defparameter *newparser-clean-exit-no-wsx-error-message*
  (with-output-to-string (s)
    (format s "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>")
    (terpri s)
    (format s "<errors>")
    (terpri s)
    (format s "<error line=\"0\" col=\"0\" code=\"0\" explanation=\"Although newparser exited cleanly, it did not generate the expected output file\">")
    (terpri s)
    (format s "</errors>")
    (terpri s)))

(defun newparser (text)
  (let* ((temp-miz-path (temporary-file :base "p" :extension "miz"))
	 (temp-err-path (replace-extension temp-miz-path "miz" "err"))
	 (temp-wsx-path (replace-extension temp-miz-path "miz" "wsx")))
    (write-string-into-file text
			    temp-miz-path
			    :if-exists :error
			    :if-does-not-exist :create)
    (open temp-err-path :direction :probe
	                :if-exists :supersede
			:if-does-not-exist :create) ;; ensure existence of .err
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
			    *newparser-clean-exit-no-wsx-error-message*))
		(values nil
			(err-file-as-xml temp-err-path))))
	  (values nil
		  (err-file-as-xml temp-err-path))))))


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
    (setf (content-type* *reply*) "application/xml")
    (multiple-value-bind (newparser-ok newparser-explanation)
	(newparser text)
      (unless newparser-ok
	(setf (return-code *reply*) +http-bad-request+))
      newparser-explanation)))

(defun initialize-uris ()
  (register-regexp-dispatcher "^/$" #'parse-and-emit-mizar))

;;; parse-article.lisp ends here