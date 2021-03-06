(load "mk.scm")
(load "test-check.scm")

;;; Generation of simple multi-language quines using relational
;;; interpreters for two Scheme-like languages.  Language 1 supports
;;; 'cons' but not 'list', while language 2 supports 'list' but not
;;; 'cons'.  Language 1 also supports 'eval' and lazy $cons/$car/$cdr.
;;; Thanks to Dan Friedman for the lazy cons.
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
      (absento 'suspended-pair exp)
      (absento 'suspend exp)
      (conde
        ((== `(quote ,val) exp)
         (not-in-envo 'quote env))
        ((symbolo exp) (lookupo exp env val))
        ((fresh (x body)
           (== `(lambda (,x) ,body) exp)
           (== `(closure ,x ,body ,env) val)
           (symbolo x)
           (not-in-envo 'lambda env)))
        ((fresh (e1 e2)
           (== `($cons ,e1 ,e2) exp)
           (== `(suspended-pair
                  (suspend ,e1 ,env)
                  (suspend ,e2 ,env))
               val)
           (not-in-envo '$cons env)))        
        ((fresh (e1 e2 v1 v2)
           (== `(cons ,e1 ,e2) exp)
           (== `(,v1 . ,v2) val)
           (not-in-envo 'cons env)
           (eval-expo-lang-1 e1 env v1)
           (eval-expo-lang-1 e2 env v2)))        
        ((fresh (e e1 e2 env^)
          (== `($car ,e) exp)
          (not-in-envo '$car env)
          (eval-expo-lang-1 e env
                            `(suspended-pair
                              (suspend ,e1 ,env^)
                              (suspend ,e2 ,env^)))
          (eval-expo-lang-1 e1 env^ val)))
        ((fresh (e e1 e2 env^)
          (== `($cdr ,e) exp)
          (not-in-envo '$cdr env)
          (eval-expo-lang-1 e env
                            `(suspended-pair
                              (suspend ,e1 ,env^)
                              (suspend ,e2 ,env^)))
          (eval-expo-lang-1 e2 env^ val)))
        ((fresh (e value)
           (== `(eval ,e) exp)
           (not-in-envo 'eval env)
           (eval-expo-lang-1 e env value)
           (eval-expo-lang-1 value '() val)))        
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
   (=/= ((_.0 closure)) ((_.0 suspend)) ((_.0 suspended-pair)))
   (sym _.0))))

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
     (=/= ((_.0 closure)) ((_.0 suspend)) ((_.0 suspended-pair)))
     (sym _.0))))

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
    (=/= ((_.0 closure)) ((_.0 suspend)) ((_.0 suspended-pair)))
    (sym _.0)))

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



(test "lazy cons 1"
  (run* (q) (eval-expo-lang-1 `($car ($cons (quote 5) ((lambda (x) (x x)) (lambda (x) (x x))))) '() q))
  '(5))

(test "lazy cons quines"
  (run 3 (q) (eval-expo-lang-1 q '() q))
  '((((lambda (_.0)
        (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
      '(lambda (_.0)
         (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0))
    (((lambda (_.0)
        (cons _.0
              (cons (cons 'quote (cons _.0 '()))
                    ($car ($cons '() _.1)))))
      '(lambda (_.0)
         (cons _.0
               (cons (cons 'quote (cons _.0 '()))
                     ($car ($cons '() _.1))))))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (suspend _.1)
              (suspended-pair _.1)))
    (((lambda (_.0)
        (cons _.0
              (cons (cons 'quote (cons _.0 '()))
                    ($cdr ($cons _.1 '())))))
      '(lambda (_.0)
         (cons _.0
               (cons (cons 'quote (cons _.0 '()))
                     ($cdr ($cons _.1 '()))))))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (suspend _.1)
              (suspended-pair _.1)))))

(test "programs that evaluate to (5. 6)"
  (run 100 (q) (eval-expo-lang-1 q '() '(5 . 6)))
  '('(5 . 6)
    (cons '5 '6)
    (($car ($cons '(5 . 6) _.0))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (($cdr ($cons _.0 '(5 . 6)))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons '5 ($car ($cons '6 _.0)))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons ($car ($cons '5 _.0)) '6)
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (eval ''(5 . 6))
    (($car ($cons (cons '5 '6) _.0))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons '5 ($cdr ($cons _.0 '6)))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (((lambda (_.0) '(5 . 6)) '_.1)
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (suspend _.1)
              (suspended-pair _.1)))
    (cons '5 (eval ''6))
    ((cons ($cdr ($cons _.0 '5)) '6)
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons ($car ($cons '5 _.0)) ($car ($cons '6 _.1)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (((lambda (_.0) _.0) '(5 . 6))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0))
    (($cdr ($cons _.0 (cons '5 '6)))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (($car ($cons ($car ($cons '(5 . 6) _.0)) _.1))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons ($car ($cons '5 _.0)) ($cdr ($cons _.1 '6)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons '5 ($car ($cons ($car ($cons '6 _.0)) _.1)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (($car ($car ($cons ($cons '(5 . 6) _.0) _.1)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons '5 ((lambda (_.0) '6) '_.1))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (suspend _.1)
              (suspended-pair _.1)))
    (((lambda (_.0) '(5 . 6)) (lambda (_.1) _.2))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)) ((_.1 closure)) ((_.1 suspend))
          ((_.1 suspended-pair)))
     (sym _.0 _.1)
     (absento (closure _.2) (suspend _.2)
              (suspended-pair _.2)))
    ((cons ($car ($cons '5 _.0)) (eval ''6))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons ($cdr ($cons _.0 '5)) ($car ($cons '6 _.1)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons '5 ((lambda (_.0) _.0) '6))
     (=/= ((_.0 closure)) ((_.0 suspend)) ((_.0 suspended-pair)))
     (sym _.0))
    (eval '(cons '5 '6))
    (cons (eval ''5) '6)
    (($car ($cons ($cdr ($cons _.0 '(5 . 6))) _.1))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (($cdr ($cons _.0 ($car ($cons '(5 . 6) _.1))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons '5 ($car ($cons ($cdr ($cons _.0 '6)) _.1)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (($car ($car ($cons ($cons (cons '5 '6) _.0) _.1)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (eval (cons 'quote '((5 . 6))))
    (($car ($cons (cons '5 ($car ($cons '6 _.0))) _.1))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons '5 ($cdr ($cons _.0 ($car ($cons '6 _.1)))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (($car ($cons (cons ($car ($cons '5 _.0)) '6) _.1))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons ($cdr ($cons _.0 '5)) ($cdr ($cons _.1 '6)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons ($car ($cons '5 _.0))
           ($car ($cons ($car ($cons '6 _.1)) _.2)))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    (($cdr ($car ($cons ($cons _.0 '(5 . 6)) _.1)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons '5 ($car ($car ($cons ($cons '6 _.0) _.1))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (($car ($cons (eval ''(5 . 6)) _.0))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (((lambda (_.0) '(5 . 6)) ($cons _.1 _.2))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (closure _.2) (suspend _.1)
              (suspend _.2) (suspended-pair _.1)
              (suspended-pair _.2)))
    ((cons '5 ($car ($cons (eval ''6) _.0)))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (($car
      ($car
       ($cons ($cons ($car ($cons '(5 . 6) _.0)) _.1) _.2)))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    ((cons '5 ((lambda (_.0) '6) (lambda (_.1) _.2)))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)) ((_.1 closure)) ((_.1 suspend))
          ((_.1 suspended-pair)))
     (sym _.0 _.1)
     (absento (closure _.2) (suspend _.2)
              (suspended-pair _.2)))
    ((cons ($car ($cons '5 _.0)) ((lambda (_.1) '6) '_.2))
     (=/= ((_.1 closure)) ((_.1 suspend))
          ((_.1 suspended-pair)))
     (sym _.1)
     (absento (closure _.0) (closure _.2) (suspend _.0)
              (suspend _.2) (suspended-pair _.0)
              (suspended-pair _.2)))
    (((lambda (_.0) (cons '5 '6)) '_.1)
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (suspend _.1)
              (suspended-pair _.1)))
    ((cons ($cdr ($cons _.0 '5)) (eval ''6))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (($cdr ($cons _.0 ($cdr ($cons _.1 '(5 . 6)))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons (eval ''5) ($car ($cons '6 _.0)))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons ($car ($cons '5 _.0)) ((lambda (_.1) _.1) '6))
     (=/= ((_.1 closure)) ((_.1 suspend))
          ((_.1 suspended-pair)))
     (sym _.1)
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (($car ($cdr ($cons _.0 ($cons '(5 . 6) _.1))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((eval '($car ($cons '(5 . 6) _.0)))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (($car ($cons ($car ($cons (cons '5 '6) _.0)) _.1))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (((lambda (_.0) (cons '5 _.0)) '6)
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0))
    (($car ($cons (cons '5 ($cdr ($cons _.0 '6))) _.1))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons '5 ($cdr ($cons _.0 ($cdr ($cons _.1 '6)))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (($cdr ($car ($cons ($cons _.0 (cons '5 '6)) _.1)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons ($car ($cons '5 _.0))
           ($car ($cons ($cdr ($cons _.1 '6)) _.2)))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    ((cons '5 (eval '($car ($cons '6 _.0))))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (cons '5 (eval (cons 'quote '(6))))
    ((cons '5
           ($car
            ($car ($cons ($cons ($car ($cons '6 _.0)) _.1) _.2))))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    (($cdr ($cons _.0 (cons '5 ($car ($cons '6 _.1)))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (($car
      ($car
       ($cons ($cons ($cdr ($cons _.0 '(5 . 6))) _.1) _.2)))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    ((cons ($car ($cons '5 _.0))
           ($cdr ($cons _.1 ($car ($cons '6 _.2)))))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    ((cons '5
           ($car
            ($cons ($car ($cons ($car ($cons '6 _.0)) _.1)) _.2)))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    (($cdr ($cons _.0 (cons ($car ($cons '5 _.1)) '6)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (eval (cons 'cons '('5 '6)))
    (($car ($cdr ($cons _.0 ($cons (cons '5 '6) _.1))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (((lambda (_.0) (cons _.0 '6)) '5)
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0))
    ((cons '5 ($cdr ($car ($cons ($cons _.0 '6) _.1))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons (eval ''5) ($cdr ($cons _.0 '6)))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons ($cdr ($cons _.0 '5))
           ($car ($cons ($car ($cons '6 _.1)) _.2)))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    ((cons ($car ($cons '5 _.0))
           ($car ($car ($cons ($cons '6 _.1) _.2))))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    (($cdr ($cons _.0 (eval ''(5 . 6))))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons ($car ($cons ($car ($cons '5 _.0)) _.1)) '6)
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (($car
      ($car
       ($cons ($cons (cons '5 ($car ($cons '6 _.0))) _.1)
              _.2)))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    (($car ($cons ((lambda (_.0) '(5 . 6)) '_.1) _.2))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (closure _.2) (suspend _.1)
              (suspend _.2) (suspended-pair _.1)
              (suspended-pair _.2)))
    ((cons '5 ((lambda (_.0) '6) ($cons _.1 _.2)))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (closure _.2) (suspend _.1)
              (suspend _.2) (suspended-pair _.1)
              (suspended-pair _.2)))
    (($car ($cons (cons '5 (eval ''6)) _.0))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons '5 ($cdr ($cons _.0 (eval ''6))))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons '5 ($car ($cons ((lambda (_.0) '6) '_.1) _.2)))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (closure _.2) (suspend _.1)
              (suspend _.2) (suspended-pair _.1)
              (suspended-pair _.2)))
    (($car
      ($car
       ($cons ($cons (cons ($car ($cons '5 _.0)) '6) _.1)
              _.2)))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    (($cdr
      ($car
       ($cons ($cons _.0 ($car ($cons '(5 . 6) _.1))) _.2)))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    (($car ($cons (cons ($cdr ($cons _.0 '5)) '6) _.1))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (($car
      ($cons
       (cons ($car ($cons '5 _.0)) ($car ($cons '6 _.1)))
       _.2))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    ((cons '5
           ($car
            ($car ($cons ($cons ($cdr ($cons _.0 '6)) _.1) _.2))))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    ((cons ($car ($cons '5 _.0)) ($car ($cons (eval ''6) _.1)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons ($cdr ($cons _.0 '5)) ((lambda (_.1) '6) '_.2))
     (=/= ((_.1 closure)) ((_.1 suspend))
          ((_.1 suspended-pair)))
     (sym _.1)
     (absento (closure _.0) (closure _.2) (suspend _.0)
              (suspend _.2) (suspended-pair _.0)
              (suspended-pair _.2)))
    ((cons ($car ($cons '5 _.0))
           ((lambda (_.1) '6) (lambda (_.2) _.3)))
     (=/= ((_.1 closure)) ((_.1 suspend))
          ((_.1 suspended-pair)) ((_.2 closure)) ((_.2 suspend))
          ((_.2 suspended-pair)))
     (sym _.1 _.2)
     (absento (closure _.0) (closure _.3) (suspend _.0)
              (suspend _.3) (suspended-pair _.0)
              (suspended-pair _.3)))
    ((eval ($car ($cons ''(5 . 6) _.0)))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (($car ($car ($cons ($cons (eval ''(5 . 6)) _.0) _.1)))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    (($car ($cons ((lambda (_.0) _.0) '(5 . 6)) _.1))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (suspend _.1)
              (suspended-pair _.1)))
    (((lambda (_.0) (cons '5 '6)) (lambda (_.1) _.2))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)) ((_.1 closure)) ((_.1 suspend))
          ((_.1 suspended-pair)))
     (sym _.0 _.1)
     (absento (closure _.2) (suspend _.2)
              (suspended-pair _.2)))
    (((lambda (_.0) ($car ($cons '(5 . 6) _.1))) '_.2)
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (closure _.2) (suspend _.1)
              (suspend _.2) (suspended-pair _.1)
              (suspended-pair _.2)))
    ((cons '5 ($car ($cons ((lambda (_.0) _.0) '6) _.1)))
     (=/= ((_.0 closure)) ((_.0 suspend))
          ((_.0 suspended-pair)))
     (sym _.0)
     (absento (closure _.1) (suspend _.1)
              (suspended-pair _.1)))
    ((eval '($cdr ($cons _.0 '(5 . 6))))
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    (($car
      ($cdr
       ($cons _.0 ($cons ($car ($cons '(5 . 6) _.1)) _.2))))
     (absento (closure _.0) (closure _.1) (closure _.2)
              (suspend _.0) (suspend _.1) (suspend _.2)
              (suspended-pair _.0) (suspended-pair _.1)
              (suspended-pair _.2)))
    (cons (eval ''5) (eval ''6))
    (($cdr ($cdr ($cons _.0 ($cons _.1 '(5 . 6)))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))
    ((cons ($cdr ($cons _.0 '5)) ((lambda (_.1) _.1) '6))
     (=/= ((_.1 closure)) ((_.1 suspend))
          ((_.1 suspended-pair)))
     (sym _.1)
     (absento (closure _.0) (suspend _.0)
              (suspended-pair _.0)))
    ((cons '5 ($car ($cdr ($cons _.0 ($cons '6 _.1)))))
     (absento (closure _.0) (closure _.1) (suspend _.0)
              (suspend _.1) (suspended-pair _.0)
              (suspended-pair _.1)))))
