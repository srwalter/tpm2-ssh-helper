prefix ?= /usr

all:
	true

install:
	mkdir -p $(DESTDIR)/$(prefix)/bin
	install -m755 -t $(DESTDIR)/$(prefix)/bin tpm-ssh-helper setup-tpm-ssh
