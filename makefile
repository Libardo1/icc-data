SHELL = /bin/sh

all: wgeturl transfer ocr transfer
.Phony: all


wgeturl: 
	@echo "\nDownloading ICC Decisions"
	@wget -r -N --no-parent -w 1 --limit-rate=100k http://digital.library.okstate.edu/icc/

transfer: 
	mkdir -p pdf
	@echo "\nCollecting Decisions"
		find digital.library.okstate.edu/ -iname "iccv*.pdf" -exec cp {} ./pdf \;

OCR_OUTPUTS := $(patsubst pdf/%.pdf, text/%.txt, $(wildcard pdf/*.pdf))

ocr : $(OCR_OUTPUTS)
	@echo "\nDone doing OCR for all the PDFs in ./pdf"

temp/%.txt : pdf/%.pdf
	mkdir -p temp
	@echo "\nBursting $^ into separate files"
	pdftk $^ burst output temp/$*.page-%04d.pdf
	@echo "\nConverting the PDFs for $^ to the image files"
	for pdf in temp/$*.page-*.pdf ; do \
		convert -density 600 -depth 8 $$pdf $$pdf.png ; \
	done
	@echo "\nDoing OCR for each page in $^"
	for png in temp/$*.page-*.pdf.png ; do \
		tesseract $$png $$png tesseract-config ; \
	done
	@echo "\nConcatenating the text files into $@"
	cat temp/$*.page-*.pdf.png.txt > temp/$*.txt

text/%.txt : temp/%.txt
	awk -vRS="-\n+" -vORS="" '1' $^ > $@

.PHONY : clean
clean : 
	rm -rf temp/
	rm -rf pdf/

.PHONY : clobber
clobber : 
	rm -rf text/*



