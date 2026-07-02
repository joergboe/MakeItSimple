objects = main.o src1.o src2.o

main: $(objects)
	g++ -o $@ $^

$(objects): %.o: %.cpp
	g++ -o $@ $< -c -MMD -MF $*.dep

depfiles = $(objects:.o=.dep)
-include $(depfiles)

