;;;; Helpful binary utilities
;;;; Note: s+ and makebins need to be compiled first
;;;; These utilities have been incredibly useful during development
;;;; and testing of the system, and they saved plenty of time that
;;;; would have been wasted typing numbers into a calculator.

;;; General Utilities ------------------------------------------------

(defun s+ (&rest strings)
  "Because it's shorter"
  (apply #'concatenate 'string strings))

(defmacro mapcarp (function lst)
  "Extension of mapcar that appends the input to each output"
  `(mapcar #'(lambda (x) (cons (funcall ,function x) (list x)))
	   ,lst))

(defun >> (num shift)
  (/ num (expt 2 shift)))

(defun << (num shift)
  (* num (expt 2 shift)))

(defun flip (x)
  "Flips the bits in x (in my format)"
  (cond
    ((null x) 'nil)
    (t (cons
	(if (= (car x) 0) 1 0)
	(flip (cdr x))))))

(defun average (lst)
  "Finds average value of a list"
  (/ (apply #'+ lst) (length lst)))


;;; Binary Repr. Stuff -----------------------------------------------
(defparameter +bins+ (makebins 15 11) "My binary format!")
(defparameter +bigbins+ (makebins 32 11) "Large numbers!")

(defun makebins (numbins point)
  "Makes a list of powers for binary positions (4 2 1 0.5 0.25 ...)"
  (cond
    ((= numbins 0) 'nil)
    (t (cons
	(expt 2 (- numbins point))
	(makebins (1- numbins) point)))))

(defun bin2hex (x)
  "Converts bin (my format) to hex representation"
  (if (null x)
      'nil
      (let ((sl (subseq x 0 4)))
	(cons (cond
		((equal sl '(0 0 0 0)) 0)
		((equal sl '(0 0 0 1)) 1)
		((equal sl '(0 0 1 0)) 2)
		((equal sl '(0 0 1 1)) 3)
		((equal sl '(0 1 0 0)) 4)
		((equal sl '(0 1 0 1)) 5)
		((equal sl '(0 1 1 0)) 6)
		((equal sl '(0 1 1 1)) 7)
		((equal sl '(1 0 0 0)) 8)
		((equal sl '(1 0 0 1)) 9)
		((equal sl '(1 0 1 0)) 'A)
		((equal sl '(1 0 1 1)) 'B)
		((equal sl '(1 1 0 0)) 'C)
		((equal sl '(1 1 0 1)) 'D)
		((equal sl '(1 1 1 0)) 'E)
		((equal sl '(1 1 1 1)) 'F))
	      (bin2hex (cddddr x))))))

(defun dec2hex (x)
  (bin2hex (dec2bin x)))


(defun dec2bin (x &optional (bins +bins+))
  "Converts a decimal number into my binary format"
  (labels ((getbin (nx vals)
	     (cond
	       ((null vals)
		(if (= nx 0)
		    'nil
		    (progn
		      (if (> nx 1e-2)
			  (format t "~d: Not representable! error: ~d~%" x nx))
		      'nil)))
	       ((>= nx (car vals))
		(cons 1 (getbin (- nx (car vals)) (cdr vals))))
	       (t
		(cons 0 (getbin nx (cdr vals)))))))
    (if (< x 0) ; Handle negatives by adding first then flipping 
	(flip (cons 0 (getbin (abs (+ x (car (last bins)))) bins)))
	(cons 0 (getbin x bins)))))
    

(defun bin2dec (x &optional (bins +bins+))
  "Converts bin (my format) to decimal"
  (labels ((getdec (nx vals)
	     (cond
	       ((null nx)
		(if (null vals)
		    0
		    (progn
		      (format t "Wrong number of bins")
		      0)))
	       ((= (car nx) 1)
		(+ (car vals) (getdec (cdr nx) (cdr vals))))
	       (t (getdec (cdr nx) (cdr vals))))))
    (float (if (= (car x) 1)
	       (* -1 (+ (car (last bins)) (getdec (flip (cdr x)) bins)))
	       (getdec (cdr x) bins))))) ; Handle negatives by multiplying back


;;; Extra binary things

(defun 2sbin (x &optional (scale 5))
  "Converts x to binary, scaled by amount"
  (dec2bin (<< x scale)))

(defun sbin2dec (x &optional (scale 5))
  "Converts a scaled x back to decimal"
  (>> (bin2dec x) scale))


;;; System Models ----------------------------------------------------

(defvar *k-shift*)
(defvar *result-shift*)
(setf *k-shift* 2)
(setf *result-shift* 3)

(defun gdp ()
  "A model of the GDP as a closure - subsequent calls work right"
  (let ((acc_sum 0))
    (lambda (x k mean omega last_c first_c)
      ((lambda (sum)
	 (if last_c
	     (- k sum)
	     sum))
       (setf acc_sum (+ (* omega (expt (- x mean) 2))
			(if first_c
			    0
			    acc_sum)))))))

(defvar my-gdp (gdp))
(setf my-gdp (gdp))

(defun feed-gdp (x k/shift mean omega last_c first_c &rest more-sets)
  (let ((tgdp (gdp)))
    (funcall tgdp x (<< k/shift *k-shift*) mean omega last_c first_c)
    (dolist (d more-sets)
      (let* ((x (car d)) (mean (third d)) (omega (fourth d))
	     (k (<< (second d) *k-shift*)) (last_c (nth 4 d)) (first_c (nth 5 d))
	     (result (funcall tgdp x k mean omega last_c first_c)))
	(when last_c
	  ;(format t "Result: ~d ~%" result)
	  result)))))


(defun feed-observation (x-comps senones &key (normalise 'nil) (numcomps 25))
  "Get all senone scores for a given observation and senones"
  (format t "Starting scoring of ~a senones, with ~a components per frame~%~%"
	  (length senones) numcomps)
  (let ((result nil)
	(x-comps (subseq (if (oframe-p x-comps)
			     (oframe-components x-comps)
			     x-comps)
			 0 numcomps))
	(best-score -5000))
    (dolist (s senones)  ;; Only use a certain number of components:
      (let ((omegas (subseq (senone-omegas s) 0 numcomps))
	    (means (subseq (senone-means s) 0 numcomps))
	    (k (senone-gconst s)) (tgdp (gdp)) (score 0))
	
	;; Call first calc explicitly
	(funcall tgdp (car x-comps) k (car means) (car omegas) nil t)
	
	;; Process rest of components
	(setf score (loop for (x . rest) on (cdr x-comps)
		       and omega in (cdr omegas)
		       and  mean in (cdr means)
		       when rest do (funcall tgdp x k mean omega nil nil)
		       else do (return (funcall tgdp x k mean omega t nil))))

	(if (> score best-score) (setf best-score score))
	
	;(setf result (cons (cons (senone-sname s) score) result))))
	(setf result (cons score result))))
;	(format t "Senone ~a score: ~d ~a~%"
;		(senone-sname s)
;		score
;		(dec2bin (>> score *result-shift*)))))
    (reverse (if normalise
		 (mapcar (lambda (x) (- best-score x)) result)
		 result))))


;;; Testbench things -------------------------------------------------

(defmacro printl (stream prepend append &rest lines)
  "Make the printlines look nicer below :)"
  (let ((res 'nil))
    (dolist (l lines)
      (setf res
	    (append res
		    `((format ,stream ,(s+ prepend (car l) append) ,@(cdr l))))))
    `(progn
       ,@res)))


(defun print-senone-data (senones &key (stream t) (c-header 'nil) (numcomps 25))
  (format t "Printing ~a senones, with ~a components per frame~%~%"
	  (length senones) numcomps)
  ;; Print header stuff
  (if c-header
      (format stream "Senone senones[N_SENONES] = {~%")
      (format stream "  case (senone_index)~%"))
  (let ((count (length senones)))
    
    ;; Print the rest!
    (dolist (s (reverse senones))  ;; Only use a certain number of components:
      (decf count)
      (let ((omegas (reverse (subseq (senone-omegas s) 0 numcomps)))
	    (means (reverse (subseq (senone-means s) 0 numcomps)))
	    (k (senone-gconst s)))

	(if c-header
	    (printl stream "    " "~%"
		    ("/* Senone ~a (~a): */" count (senone-sname s))
		    ("{ k:     ~a," k)
		    ("  mean:  { ~{~a~^, ~} }," means)
		    ("  omega: { ~{~a~^, ~} } }," omegas))
	    (printl stream "    " "~%"
		    ("/* Senone ~a (~a): */" count (senone-sname s))
		    ("~a: senone = '{ 16'h~{~a~}, // K" count (dec2hex (>> k *k-shift*)))
		    ("    {~{16'h~{~a~}~^, ~}},  // omegas" (mapcar #'dec2hex omegas))
		    ("    {~{16'h~{~a~}~^, ~}}}; // means" (mapcar #'dec2hex means))))))
;	    (printl stream "  " "~%"
;		    ("// Senone ~a (~a)" count (senone-sname s))
;		    ("{ k:      16'h~{~a~}," (dec2hex (>> k *k-shift*)))
;		    ("  omegas: { ~{16'h~{~a~}~^, ~} }," (mapcar #'dec2hex omegas))
;		    ("  means:  { ~{16'h~{~a~}~^, ~} }" (mapcar #'dec2hex means))
;		    ("}~a" (if (= 0 count) " " ","))))))
    
    (format stream (if c-header
		       "};"
		       "~%    default: senone = 'b0;~%  endcase"))))


(defun print-testbench (observations senones &key (stream t) (numcomps 25))
  ;; Print out the list of X etc
  (printl stream "  " "~%"
	  ("reset = 0;")
	  ("new_vector_available = 1'b1;")
	  ("x = { ~{16'h~{~a~}~^, ~} };~%" (reverse
					    (mapcar #'dec2hex observations)))
	  ("#10ns new_vector_available = 0;")
	  ("#~ans; // Wait for output~%~%" (+ 40 (* numcomps 10)))) ;; Assuming period = 10ns
  
  (let ((interval (* numcomps 5)))
    (dolist (val (feed-observation observations senones :normalise t :numcomps numcomps))
      (printl stream "  " "~%"
	      ("assert (score_ready == 1'b1) else $display(\"score_ready not high!\");")
	      ("assert (senone_score[15:6] == 10'b~{~a~}) // (0x~{~a~})"
	       (subseq (dec2bin (>> (cdr val) *result-shift*)) 0 10)
	       (dec2hex (>> (cdr val) *result-shift*)))
	      ("  else $display(\"Error in score for ~a!\");~%" (car val))
	      ("#~ans assert (score_ready == 1'b0) else $display(\"score_ready not low!\");"
	       interval)
	      ("#~ans;" interval)))))  ;; Assuming clk period = 10ns


(defun print-to-file (func filepath &rest args)
  "Outputs the tests to a file instead"
  (with-open-file (fp filepath :direction :output :if-exists :supersede)
    (apply func :stream fp args)
    (format t "---Done---")))

;; Hint: use (subseq senones 0 5) for 5 senones
;; A couple of observations:
;CL-USER> (mapcar #'dec2hex (subseq (oframe-components (car oframes)) 0 6))
;((D A B E) (0 0 C 1) (F D 3 C) (F E D A) (F 6 A 5) (1 7 5 B))
;CL-USER> (mapcar #'dec2hex (subseq (oframe-components (cadr oframes)) 0 6))
;((D 9 F 0) (0 6 2 C) (F F D D) (F D 1 5) (F 9 9 C) (2 A D 9))

;;; NOTES

;; Max, Min, Average scores
;CL-USER> (average (feed-observation (first oframes) senones 5))
;-58.513126
;CL-USER> (apply #'min (feed-observation (first oframes) senones 5))
;-130.46974
;CL-USER> (apply #'max (feed-observation (first oframes) senones 5))
;-38.27107

;; Tests for representability -> result-shift = 3
;CL-USER> (<< (bin2dec (dec2bin (>> -130.46974 3))) 3)
;-130.46875
;CL-USER> (<< (bin2dec (dec2bin (>> -38.27107 3))) 3)
;-38.265625

;; Max, Min K (gconst) values (these are both negative actually!)
;CL-USER> (let ((kmax 0))
;	   (dolist (s senones kmax)
;	     (if (> (abs (senone-gconst s)) kmax)
;		 (setf kmax (abs (senone-gconst s))))))
;63.05575
;CL-USER> (let ((kmax 50))
;	   (dolist (s senones kmax)
;	     (if (< (abs (senone-gconst s)) kmax)
;		 (setf kmax (abs (senone-gconst s))))))
;32.06774
