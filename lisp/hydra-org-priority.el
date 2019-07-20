;;; hydra-org-priority.el --- Hydra for handling priorities in org-mode -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(defvar zp/hydra-org-priority-chain nil
    "When non-nil, make zp/hydra-org-priority chain the commands.")

(defun zp/hydra-org-priority-chain-toggle ()
  "Toggle zp/hydra-org-priority-chain."
  (interactive)
  (if zp/hydra-org-priority-chain
      (setq zp/hydra-org-priority-chain nil)
    (setq zp/hydra-org-priority-chain t)))

(defun zp/hydra-org-priority-set (&optional action show)
  "Change the priority of an item, and possibly chain the commands."
  (interactive)
  (let ((in-agenda (eq major-mode 'org-agenda-mode)))
    (if in-agenda
        (org-agenda-priority action)
      (org-priority action show))
    (when (and zp/hydra-org-priority-chain
               (zp/hydra-org-priority-goto-sibling))
      (zp/hydra-org-priority/body))))

(defun zp/hydra-org-priority-raise (&optional lower)
  "Raise the priority of an item, and possibly chain the commands.
When LOWER is non-nil, raise the priority instead."
  (interactive)
  (let ((in-agenda (derived-mode-p 'org-agenda-mode))
        (fun-agenda (if lower
                        'org-agenda-priority-down
                      'org-agenda-priority-up))
        (fun-org (if lower
                     'org-priority-down
                   'org-priority-up)))
    (cond (in-agenda
           (funcall fun-agenda))
          (t
           (funcall fun-org)))
    (when zp/hydra-org-priority-chain
      (zp/hydra-org-priority/body))))

(defun zp/hydra-org-priority-goto-sibling (&optional previous)
  (interactive)
  (let ((in-agenda (eq major-mode 'org-agenda-mode))
        (fun-agenda (if previous
                        'org-agenda-previous-item
                      'org-agenda-next-item)))
    (cond (in-agenda
           (funcall fun-agenda 1))
          (t
           (org-goto-sibling (if previous t))))))

(defun zp/hydra-org-priority-todo ()
  (interactive)
  (let ((in-agenda (derived-mode-p 'org-agenda-mode)))
    (cond (in-agenda
           (org-agenda-todo current-prefix-arg))
          (t
           (org-todo)))
    (zp/hydra-org-priority/body)))

(defhydra zp/hydra-org-priority (:color blue
                                 :hint nil)
  "
_a_: #A    _p_: previous  _w_: refile
_b_: #B    _n_: next      _t_: todo
_c_: #C    _l_: lower
_d_: #D    _r_: raise
_e_: #E    _SPC_: remove

"
  ("x" zp/hydra-org-priority-chain-toggle (concat (if zp/hydra-org-priority-chain
                                                      "[x]"
                                                    "[ ]")
                                                  " chain") :exit nil)
  ("a" (zp/hydra-org-priority-set ?a))
  ("b" (zp/hydra-org-priority-set ?b))
  ("c" (zp/hydra-org-priority-set ?c))
  ("d" (zp/hydra-org-priority-set ?d))
  ("e" (zp/hydra-org-priority-set ?e))

  ("p" (zp/hydra-org-priority-goto-sibling t) :exit nil)
  ("n" (zp/hydra-org-priority-goto-sibling) :exit nil)

  ("l" (zp/hydra-org-priority-raise t) :exit nil)
  ("r" (zp/hydra-org-priority-raise) :exit nil)

  ("w" (zp/hydra-org-refile/body))

  ("t" (zp/hydra-org-priority-todo))

  ("SPC" (zp/hydra-org-priority-set 'remove))

  ("q" nil "cancel"))



(provide 'hydra-org-priority)
;;; test.el ends here