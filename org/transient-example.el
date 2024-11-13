;;; transient-example.el ---                         -*- lexical-binding: t; -*-

(transient-define-prefix my/transient ()
  "My Transient"

  ["Arguments & Switches"
    ("-s" "Switch" "--switch")
    ("-c" "Go to composed" "--composed")
    ("-n" "Name Argument" "--name=")]

  ["Commands"
    ("m" "message" my/message-from-transient)])

(transient-define-prefix my/composed-transient-prefix ()
  "My Composed Transient"

  ["Arguments & Switches"
    ("-l" "Loop" "--loop")]

  ["Commands"
    ("x" "Execute" my/composed-suffix)])

(defun my/message-from-transient (&optional args)
  "Just a quick testing function."
  (interactive (list (transient-args transient-current-command)))
  (if (transient-arg-value "--switch" args)
    (message
      (concat "Hello: " (transient-arg-value "--name=" args)))
    (if (transient-arg-value "--composed" args)
        (my/composed-transient-prefix))))

(defun my/composed-suffix (&optional args)
  (interactive (list (transient-args transient-current-command)))
  (if (transient-arg-value "--name=" args)
      (message (transient-arg-value "--name=" args)))
  (if (transient-arg-value "--loop" args)
      (my/transient)))
