# Copyright (c) 2017 by the author(s)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Author(s):
#   Philipp Wagner <philipp.wagner@tum.de>

# Build the OSD Documentation
#
# Note: this Makefile is *not* used by Read The Docs, it exec()'s the conf.py
# file directly. Hence, all special build steps here are only relevant for
# local builds, not for RTD builds. Add all build steps which should be executed
# in RTD builds as Python code into the conf.py file.

srcdir = .
VPATH = .

SPHINXOPTS    =
SPHINXBUILD   = .venv/bin/sphinx-build
SPHINXPROJ    = OpenSoCDebug
SOURCEDIR     = $(srcdir)
BUILDDIR      = _build

SVG2PDF       = inkscape
SVG2PDF_FLAGS =

# Build a list of SVG files to convert to PDFs
IMAGES_SVG_REL := $(shell find $(SOURCEDIR) -iname '*.svg' -printf '%P\n')
IMAGES_PDF := $(addprefix $(BUILDDIR)/,$(IMAGES_SVG_REL:.svg=.pdf))

all: html

help: .venv
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.venv: requirements.txt
	echo Creating Python venv for Sphinx build
	python3 -m venv .venv
	.venv/bin/pip -q install --upgrade pip
	.venv/bin/pip -q install -r $(srcdir)/requirements.txt

.SECONDEXPANSION:
$(IMAGES_PDF): %.pdf : $$(subst $$(BUILDDIR),$$(SOURCEDIR),%).svg
	mkdir -p $(@D)
	$(SVG2PDF) -f $< -A $@

# Convert images from SVG to PDF for LaTeX PDF output
images-pdf: $(IMAGES_PDF)

# Convert images to PDF before running the LaTeX PDF build
latexpdf: .venv images-pdf
	@$(SPHINXBUILD) -M latexpdf "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# Convert images to PDF before running the LaTeX PDF build
html: .venv
	@$(SPHINXBUILD) -M html "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

clean-images:
	-rm $(IMAGES_PDF)

clean-doxygen:
	rm doxygen.cfg
	rm -r xml

clean: .venv clean-images clean-doxygen
	@$(SPHINXBUILD) -M clean "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

distclean:
	-rm -rf .venv sphinx/__pycache__ $(BUILDDIR)

.PHONY: help html

# these targets are required by automake, but are not used here
EMPTY_AUTOMAKE_TARGETS = dvi pdf ps info tags ctags check installcheck
.PHONY: $(EMPTY_AUTOMAKE_TARGETS)
$(EMPTY_AUTOMAKE_TARGETS):
