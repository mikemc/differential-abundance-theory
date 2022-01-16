gitbook:
	R -e "bookdown::render_book('.', 'bookdown::gitbook', quiet = TRUE)"

pdf:
	R -e "bookdown::render_book('.', 'bookdown::pdf_book', quiet = TRUE)"

word:
	R -e "bookdown::render_book('.', 'bookdown::word_document2', quiet = TRUE)"
