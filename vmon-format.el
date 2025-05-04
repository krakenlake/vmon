(defun vmon-asm-mode-hook ()

(defun asm-calculate-indentation ()
  (or
   ;; Flush labels to the left margin.
   (and (looking-at "\\(\\sw\\|\\s_\\)+:") 0)
   ;; Section names
   (and (looking-at "\\.[[:word:]]+") 0)
   ;; CPP directives
   (and (looking-at "#[[:word:]]+") 0)
   ;; Same thing for `;;;' comments.
   (and (looking-at "\\s<\\s<\\s<") 0)
   ;; Simple `;' comments go to the comment-column.
   (and (looking-at "\\s<\\(\\S<\\|\\'\\)") comment-column)
   ;; The rest goes at the first tab stop.
   (indent-next-tab-stop 0))))

(defun vmon-format-function ()
  "Format the whole buffer."
  (setq tab-width 4)
  (add-hook 'asm-mode-hook #'vmon-asm-mode-hook)
  (asm-mode)

  (indent-region (point-min) (point-max) nil)
  (tabify (point-min) (point-max))
  (save-buffer)
)
