MTEST_SOURCE = mtest/src

.PHONY: debug
debug:
	@mkdir -p obj
	fpc src/pukdoc.pas -FE"obj/" -gl
	@mv obj/pukdoc .

.PHONY: release
release:
	@mkdir -p obj
	fpc src/pukdoc.pas -FE"obj/" -XX -Xs
	@mv obj/pukdoc .

.PHONY: clean
clean:
	rm -rf obj
	rm ./pukdoc
