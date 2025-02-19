#!/bin/bash

echo "\documentclass[12pt]{article}

\usepackage[backend=biber]{biblatex}
\addbibresource{BIBRESOURCE PATH GOES HERE}

\usepackage[margin=1in]{geometry}
\usepackage{times}
\usepackage{titling}

\usepackage{setspace}
\doublespacing

\author{Chris Cohen}
\title{TITLE GOES HERE}
\date{\today}


\renewcommand\maketitle{
	\begin{flushleft}
	\textbf{\theauthor}\\\\
	\textbf{\thedate}\\\\
	\textbf{ASSIGNMENT NAME GOES HERE}\\\\
	\end{flushleft}

	\begin{center}
	\Large{\textbf{\thetitle}}
	\end{center}
}

\begin{document}
\maketitle

\newpage
\printbibliography
\end{document}" >> $1
