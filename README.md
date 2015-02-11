# multi-quine
Generation of simple multi-language quines using relational interpreters for two Scheme-like languages.

This is really a proof-of-concept, given that the languages are almost identical.  Which languages with more interesting differences should we implement?


Language 1 supports `cons` but not `list`, while language 2 supports `list` but not `cons`.

Here is a pair of programs from the "multi-lang-quines-langs-1-and-2-non-cheeky" multi-language quine inference test.

Language 1 program using `cons` but not `list` (that is, all occurrences of `list` are quoted):

```
(cons
  '(lambda (_.0)
     (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
  '(''(lambda (_.0)
        (list 'cons _.0
              (list 'quote (list (list 'quote _.0)))))))
```

which evaluates to the Language 2 program, which uses `list` but not `cons` (that is, all occurrences of `cons` are quoted):

```
((lambda (_.0)
   (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
 ''(lambda (_.0)
     (list 'cons _.0
           (list 'quote (list (list 'quote _.0))))))
```

which in turn evaluates to the Language 1 program...


Proof, in Scheme, that the Language 1 program doesn't use `list`:

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


Proof, in Scheme, that the Language 2 program doesn't use `cons`:

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
* Which languages/features would be more interesting?  Perhaps call-by-value vs. call-by-name.  Or variadic functions + `apply` vs. a Curried language.
* How many different languages could we handle?


Thanks to Seth Schroeder (@foogoof on Twitter) for inspiring me to finally try this experiment!  :)

Resources:

* Quine relay: https://github.com/mame/quine-relay
