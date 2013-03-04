;;;; Helpful binary utilities

;;; Utilities

(defun s+ (&rest strings)
  "Because it's shorter"
  (apply #'concatenate 'string strings))

(defmacro mapcarp (function lst)
  "Extension of mapcar that appends the input to each output"
  `(mapcar #'(lambda (x) (cons (funcall ,function x) (list x)))
	   ,lst))


;;; Binary repr stuff

(defun makebins (numbins point)
  "Makes a list of powers for binary positions (4 2 1 0.5 0.25 ...)"
  (cond
    ((= numbins 0) 'nil)
    (t (cons
	(expt 2 (- numbins point))
	(makebins (1- numbins) point)))))

(defparameter +bins+ (makebins 15 5) "My binary format!")

(defun flip (x)
  "Flips the bits in x (in my format)"
  (cond
    ((null x) 'nil)
    (t (cons
	(if (= (car x) 0) 1 0)
	(flip (cdr x))))))


(defun dec2bin (x)
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
	(flip (cons 0 (getbin (abs (+ x (car (last +bins+)))) +bins+)))
	(cons 0 (getbin x +bins+)))))
    

(defun bin2dec (x)
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
    (* (if (= (car x) 1) -1 1) ; Handle negatives by multiplying back
       (float (getdec (cdr x) +bins+)))))


;;; Testbench things

(defmacro printl (stream &rest lines)
  "Make the printlines look nicer below :D"
  (let ((res 'nil))
    (dolist (l lines)
      (setf res
	    (append res
		    `((format ,stream ,(s+ "    " (car l) "~%") ,@(cdr l))))))
    `(progn
       ,@res)))
  

(defun print-tests3 (stream &rest tests)
  "Print tests in format (x y z)"
  (let ((xs "x") (ys "y") (zs "theta") (delay 20))
    (dolist (test tests)
      ;;For each test, print out a testbench thing
      (let* ((x (first test)) (y (second test))
	     (a (third test)) (b (fourth test))
	     (res (multiple-value-list (assig3 x y a b))))
	(printl stream
		("~%  #~dns;" delay)
		("x = 16'b~{~a~}; // ~a" (dec2bin x) x)
		("y = 16'b~{~a~}; // ~a" (dec2bin y) y)
		("a = 16'b~{~a~}; // ~a" (dec2bin a) a)
		("b = 16'b~{~a~}; // ~a" (dec2bin b) b)
		("//X: ~a  (~a)" (dec2bin (car res)) (car res))
		("//Y: ~a  (~a)" (dec2bin (cadr res)) (cadr res)))))))

(defun print-tests2 (stream &rest tests)
  "Prints tests for part 1"
  (dolist (test tests)
    (let* ((x (first test)) (y (second test)) (z (2rad (third test)))
	   (res (multiple-value-list (cordic x y (third test) :rot 'nil))))
      (printl stream
	      ("~%   #20ns")
	      ("x = 16'b~{~a~}; // ~a" (dec2bin x) x)
	      ("y = 16'b~{~a~}; // ~a" (dec2bin y) y)
	      ("z = 16'b~{~a~}; // ~a" (dec2bin z) z)
	      ("//sqrt: ~a (~a)" (dec2bin (car res)) (car res))
	      ("//atan: ~a (~a)" (dec2bin (2rad (caddr res)))
				 (2rad (caddr res)))))))


(defun print-to-file (func filepath &rest tests)
  "Outputs the tests to a file instead"
  (with-open-file (fp filepath :direction :output :if-exists :supersede)
    (apply func fp tests)
    (format t "---Done---")))
