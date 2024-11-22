;;; transient-example.el ---                         -*- lexical-binding: t; -*-

(transient-define-prefix my/transient ()
  "My Transient"

  ["Arguments & Switches"
    ("-s" "Switch" "--switch")
    ("-n" "Name Argument" "--name=")]

  ["Commands"
    ("m" "message" my/message-from-transient)])

(defun my/message-from-transient (&optional args)
  "Just a quick testing function."
  (interactive (list (transient-args transient-current-command)))
  (if (transient-arg-value "--switch" args)
    (message
      (concat "Hello: " (transient-arg-value "--name=" args)))))
