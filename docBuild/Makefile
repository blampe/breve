.PHONY: classes docbook documentation source spell tidy

all: html pdf

clean: pdf-clean html-clean

pdf-clean:
	rm -rf pdfdocs

html-clean:
	rm -rf htmldocs

docBuild/docExtract: docBuild/docExtract.c
	# g++ chokes here?!
	$(CC) -o docBuild/docExtract docBuild/docExtract.c

classes: docExtract
	mkdir -p htmldocs/classes
	./docExtract ../lib/classes/*.tz | ./docBuild.pl htmldocs/classes
	cp classImages/*.jpg htmldocs/classes/

pdf: pdf-clean
	mkdir -p pdfdocs
	xsltproc --output breve_documentation.fo --stringparam fop.extensions 1 /usr/local/lib/docbook-xsl-1.71.1/fo/docbook.xsl breve.docbook
	fop -fo breve_documentation.fo -pdf pdfdocs/breve_documentation.pdf

html: html-clean classes
	mkdir -p htmldocs
	mkdir -p htmldocs/docs

	cp stylesheet.css htmldocs
	cp stylesheet.css htmldocs/docs

	xsltproc make-html.xsl breve.docbook

	mkdir -p htmldocs/images
	cp images/*.jpg htmldocs/images/
	cp images/*.gif htmldocs/images/
	cp images/*.eps htmldocs/images/

source:
	mkdir -p ../docs/source
	doxygen breve.doxygen
