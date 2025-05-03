(defun vmon-format-function ()
  "Format the whole buffer."
  (setq tab-width 4)
  (indent-region (point-min) (point-max) nil)
  (tabify (point-min) (point-max))
  (save-buffer)
)
