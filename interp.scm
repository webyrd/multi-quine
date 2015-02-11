(load "mk.scm")
(load "test-check.scm")

;;; Generation of simple multi-language quines using relational
;;; interpreters for two Scheme-like languages.  Language 1 supports
;;; 'cons' but not 'list', while language 2 supports 'list' but not
;;; 'cons'.
;;;
;;; See the test "multi-lang-quines-langs-1-and-2-non-cheeky" for
;;; multi-language quine inference.
;;;
;;; What languages/features would be more interesting?  How many
;;; different languages could we handle?


(define eval-expo-lang-1
  (lambda (exp env val)
    (fresh ()
      (absento 'closure exp)
      (conde
        ((== `(quote ,val) exp)
         (not-in-envo 'quote env))
        ((symbolo exp) (lookupo exp env val))
        ((fresh (x body)
           (== `(lambda (,x) ,body) exp)
           (== `(closure ,x ,body ,env) val)
           (symbolo x)))
        ((fresh (e1 e2 v1 v2)
           (== `(cons ,e1 ,e2) exp)
           (== `(,v1 . ,v2) val)
           (eval-expo-lang-1 e1 env v1)
           (eval-expo-lang-1 e2 env v2)))
        ((fresh (rator rand x body env^ a)
           (== `(,rator ,rand) exp)
           (eval-expo-lang-1 rator env `(closure ,x ,body ,env^))
           (eval-expo-lang-1 rand env a)
           (eval-expo-lang-1 body `((,x . ,a) . ,env^) val)))))))

(define eval-expo-lang-2
  (lambda (exp env val)
    (fresh ()
      (absento 'closure exp)
      (conde
        ((== `(quote ,val) exp)
         (not-in-envo 'quote env))
        ((symbolo exp) (lookupo exp env val))
        ((fresh (x body)
           (== `(lambda (,x) ,body) exp)
           (== `(closure ,x ,body ,env) val)
           (symbolo x)))
        ((fresh (e*)
           (== `(list . ,e*) exp)
           (not-in-envo 'list env)
           (eval-list-expo-lang-2 e* env val)))
        ((fresh (rator rand x body env^ a)
           (== `(,rator ,rand) exp)
           (eval-expo-lang-2 rator env `(closure ,x ,body ,env^))
           (eval-expo-lang-2 rand env a)
           (eval-expo-lang-2 body `((,x . ,a) . ,env^) val)))))))

(define eval-list-expo-lang-2
  (lambda (e* env v*)
    (conde
      ((== '() e*) (== '() v*))
      ((fresh (e e-rest v v-rest)
         (== `(,e . ,e-rest) e*)
         (== `(,v . ,v-rest) v*)
         (eval-expo-lang-2 e env v)
         (eval-list-expo-lang-2 e-rest env v-rest))))))


(define (not-in-envo x env)
  (conde
    ((== '() env))
    ((fresh (a d)
       (== `(,a . ,d) env)
       (=/= x a)
       (not-in-envo x d)))))


(define lookupo
  (lambda (x env t)
    (fresh (rest y v)
      (== `((,y . ,v) . ,rest) env)
      (conde
        ((== y x) (== v t))
        ((=/= y x) (lookupo x rest t))))))

(test "quine-lang-1"
  (run 1 (q)
    (eval-expo-lang-1 q '() q))
  '((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
      '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
     (=/= ((_.0 closure))) (sym _.0))))

(test "quine-lang-2"
  (run 1 (q)
    (eval-expo-lang-2 q '() q))
  '((((lambda (_.0) (list _.0 (list 'quote _.0)))
      '(lambda (_.0) (list _.0 (list 'quote _.0))))
     (=/= ((_.0 closure))) (sym _.0))))

(test "multi-lang-quines-langs-1-and-2-cheeky"
  ;; miniKanren gets cheeky, as usual!
  (run 1 (p q)
    (eval-expo-lang-1 p '() q)
    (eval-expo-lang-2 q '() p))
  '((('((lambda (_.0)
          (list 'quote (list _.0 (list 'quote _.0))))
        '(lambda (_.0)
           (list 'quote (list _.0 (list 'quote _.0)))))
      ((lambda (_.0)
         (list 'quote (list _.0 (list 'quote _.0))))
       '(lambda (_.0)
          (list 'quote (list _.0 (list 'quote _.0))))))
     (=/= ((_.0 closure))) (sym _.0))))

(test "multi-lang-quines-langs-1-and-2-non-cheeky"
  (car
    (reverse
      (run 17 (p q)
        (eval-expo-lang-1 p '() q)
        (eval-expo-lang-2 q '() p))))
  '(((cons
      '(lambda (_.0)
         (list 'cons _.0
               (list 'quote (list (list 'quote _.0)))))
      '(''(lambda (_.0)
            (list 'cons _.0
                  (list 'quote (list (list 'quote _.0)))))))
     ((lambda (_.0)
        (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
      ''(lambda (_.0)
          (list 'cons _.0
                (list 'quote (list (list 'quote _.0)))))))
    (=/= ((_.0 closure))) (sym _.0)))

;;; prove the answers from multi-lang-quines-langs-1-and-2-non-cheeky are legit
(test "multi-lang-quines-langs-1-and-2-non-cheeky-proof-1"
  (let ((list 'undefined!))
    (cons
     '(lambda (_.0)
        (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
     '(''(lambda (_.0)
           (list 'cons _.0
                 (list 'quote (list (list 'quote _.0))))))))
  '((lambda (_.0)
      (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
    ''(lambda (_.0)
        (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))))

(test "multi-lang-quines-langs-1-and-2-non-cheeky-proof-2"
  (let ((cons 'undefined!))
    ((lambda (_.0)
       (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
     ''(lambda (_.0)
         (list 'cons _.0
               (list 'quote (list (list 'quote _.0)))))))
  '(cons
    '(lambda (_.0)
       (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
    '(''(lambda (_.0)
          (list 'cons _.0
                (list 'quote (list (list 'quote _.0))))))))
