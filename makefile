all:
	cd src; make all
	
clean:
	cd src; make clean

debug:
	cd src; make debug

install:
	cd src; make install
	
uninstall:
	cd src; make uninstall

run:
	sudo ./src/timeshift-gtk --debug
