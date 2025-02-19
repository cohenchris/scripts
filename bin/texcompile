#!/bin/bash

if [[ $1 == *".tex" ]]
then
  tex_filename=$1
elif [[ $1 == *"." ]]
then
  tex_filename=$1"tex"
else
  tex_filename=$1".tex"
fi

biber_filename=${tex_filename%.*}

xelatex=$(grep fontspec $tex_filename | wc -l)

if [[ $xelatex -ne 0 ]]; then
  xelatex $tex_filename
  biber $biber_filename
  xelatex $tex_filename
else
  pdflatex $tex_filename
  biber $biber_filename
  pdflatex $tex_filename
fi

# Removes all extraneous files from compilation
rm *.out *.aux *.blg *.bbl *.log *.bcf *.run.xml > /dev/null 2>&1
