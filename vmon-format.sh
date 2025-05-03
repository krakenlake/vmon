 #!/bin/sh
if [ $# -eq 0 ]
then
  echo "vmon-format.sh requires at least one argument." 1>&2
  echo "Usage: vmon-format.sh files-to-indent" 1>&2
  exit 1
fi

while [ $# -ge 1 ]
do
  if [ -d $1 ]
  then
    echo "Argument of vmon-format.sh $1 cannot be a directory." 1>&2
    exit 1
  fi

  # Check for existence of file:
  ls $1 2>/dev/null | grep $1 > /dev/null
  if [ $? != 0 ]
  then
    echo "vmon-format.sh: $1 not found." 1>&2
    exit 1
  fi

  echo "Indenting $1 with emacs in batch mode"
  #  emacs -batch $1 -l ~/bin/emacs-format-file -f emacs-format-function
  emacs -batch $1 -l ~/src/riscv/vmon/vmon-format.el -f vmon-format-function
  echo
  shift 1
done

exit 0
