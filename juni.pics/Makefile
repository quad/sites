in_photos := $(patsubst %.HEIC,%.jpg,$(wildcard content/*.HEIC))
in := config.toml \
      $(in_photos) \
      $(wildcard content/*.md) \
      $(wildcard templates/*.html) \
      $(wildcard templates/macros/*.html) \
      static/photoswipe-lightbox.esm.min.js \
      static/photoswipe.css \
      static/photoswipe.esm.min.js \
      static/style.css

%.jpg: %.HEIC
	magick $< -strip $@

public: $(in)
	zola build

.PHONY: clean all
clean:
	$(RM) $(in_photos)
	$(RM) -r public

all: public
