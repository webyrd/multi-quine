# multi-quine
Generation of simple multi-language quines using relational interpreters for two Scheme-like languages.

This is really a proof-of-concept, given that both languages are just variants of Scheme.  Which languages with more interesting differences should we implement?


Language 1 supports `cons` but not `list`, while language 2 supports `list` but not `cons`.  Language 1 also supports 'eval' and lazy $cons/$car/$cdr.  Thanks to Dan Friedman for the lazy cons.

Here is the last (and most interesting) pair of programs from the "multi-lang-quines-langs-1-and-2-non-cheeky" multi-language quine inference test:

```
(run 17 (p q)
  (eval-expo-lang-1 p '() q)
  (eval-expo-lang-2 q '() p))
```

The program `p` from Language 1 uses `cons` but not `list`.  That is, all occurrences of `list` are quoted:

```
(cons
  '(lambda (_.0)
     (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
  '(''(lambda (_.0)
        (list 'cons _.0
              (list 'quote (list (list 'quote _.0)))))))
```

Program `p` evaluates to a program `q` in Language 2, which uses `list` but not `cons`.  That is, all occurrences of `cons` are quoted:

```
((lambda (_.0)
   (list 'cons _.0 (list 'quote (list (list 'quote _.0)))))
 ''(lambda (_.0)
     (list 'cons _.0
           (list 'quote (list (list 'quote _.0))))))
```

Of course, `q` in turn evaluates to `p`...


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
