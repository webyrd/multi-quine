# multi-quine
Generation of simple multi-language quines using relational interpreters for two Scheme-like languages.

Language 1 supports 'cons' but not 'list', while language 2 supports 'list' but not 'cons'.

See the test "multi-lang-quines-langs-1-and-2-non-cheeky" for an example of multi-language quine inference:

Language 1 program using `cons` but not `list` (that is, all occurrences of `list` are quoted):

```
(cons
  '(lambda (_.0)
     (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
  '(''(lambda (_.0)
        (list 'cons _.0
              (list 'quote (list (list 'quote _.0)))))))
```

which evaluates to the Language 2 program using `list` but not `cons` (that is, all occurrences of `cons` are quoted):

```
((lambda (_.0)
   (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
 ''(lambda (_.0)
     (list 'cons _.0
           (list 'quote (list (list 'quote _.0))))))
```

which in turn evaluates to the Language 2 program...


Proof, in Scheme, that Language 1 doesn't use `list`:

```
(let ((list 'undefined!))
  (cons
    '(lambda (_.0)
       (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
    '(''(lambda (_.0)
          (list 'cons _.0
                (list 'quote (list (list 'quote _.0))))))))
=>
((lambda (_.0)
   (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
 ''(lambda (_.0)
     (list 'cons _.0 (list 'quote (list (list 'quote _.0))))))
```


Proof, in Scheme, that Language 2 doesn't use `cons`:

```
(let ((cons 'undefined!))
  ((lambda (_.0)
     (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
   ''(lambda (_.0)
       (list 'cons _.0
             (list 'quote (list (list 'quote _.0)))))))
=>
(cons
  '(lambda (_.0)
     (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
  '(''(lambda (_.0)
        (list 'cons _.0
              (list 'quote (list (list 'quote _.0)))))))
```

TODO
* What languages/features would be more interesting?  
* How many different languages could we handle?
