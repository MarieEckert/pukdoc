PPCFLAGS := -FE"obj/" -Fu"TRegExpr/src"

.PHONY: debug
debug:
	@mkdir -p obj
	fpc src/pukdoc.pas -dHAVE_DEBUG_LOGS ${PPCFLAGS} -gl
	@mv obj/pukdoc .

.PHONY: release
release:
	@mkdir -p obj
	fpc src/pukdoc.pas ${PPCFLAGS} -XX -Xs
	@mv obj/pukdoc .

.PHONY: clean
clean:
	rm -rf obj
	rm ./pukdoc
