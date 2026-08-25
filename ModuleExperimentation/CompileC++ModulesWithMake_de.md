# C++ Projekte mit Modulen mit GNU Make und der GNU Compiler Collection Builden

## Hintergrund

Mit dem Standard C++20 haben Module in C++ Einzug gehalten. C++-Module haben eine Reihe von Vorteilen 
gegenüber den herkömmlichen Include-Direktiven des Präprozessors; sie können die Übersetzungszeiten 
senken und verbessern die Code-Hygiene. Module erhöhen aber die Anforderungen an den Build-Prozess, weil 
neue Abhängigkeiten für Modul-Import und Modul-Export zu berücksichtigen sind. Insbesondere muss das 
kompilierte Modul-Interface (CMI) des exportierenden Moduls vorliegen bevor eine Übersetzungseinheit, 
die den Modul importiert, erfolgreich übersetzt werden kann. Außerdem ist es erforderlich, eine 
Zuordnung von Quelldatei, exportierten Modulname und Modul-Interface zu ermöglichen.

Der folgende Artikel erläutert eine Möglichkeit wie das mit der GNU-Compiler-Collection und GNU-Make zu 
realisieren ist.

## Der klassische Build-Prozess

Im klassischen Build-Prozess, ohne C++-Module, sind alle Übersetzungseinheiten (TU) unabhängig voneinander 
und nur von den includierten Header-Dateien abhängig. Alle Übersetzungseinheiten könne also unabhängig 
voneinander insbesondere auch parallel zu Objektdateien übersetzt werden. Zuletzt erfolgt das Linken aller 
Objekte zu einer ausführbaren Datei oder einer Library. Dazu müssen dem Make-Programm alle Abhängigkeiten 
bekannt gemacht werden.

Im folgenden Beispiel includiert das Hauptproramm `main.cpp` Funktionen etc., die in den Header-Files 
`head1.h` und `head2.h` definiert sind. Die Implementierung der Funktionen befindet sich in den 
Übersetzungseinheiten `src1.cpp` bzw. `src2.cpp`. Ausserdem includiert `src1.cpp` Funktionen etc. von 
`head2.h`. Das kann in folgenden Makefile Rules zum Ausdruck gebracht werden:

	//Makefile
	my_program: main.o src1.o src2.o
		$(CXX) -o my_program $(LINKFLAGS) main.o src1.o src2.o
	main.o: main.cpp head1.h head2.h
		$(CXX) -o main.o main.cpp -c $(CPPFLAGS) $(CXXFLAGS)
	src1.o: src1.cpp head1.h head2.h
		$(CXX) -o src1.o src1.cpp -c $(CPPFLAGS) $(CXXFLAGS)
	src2.o: src2.cpp head2.h
		$(CXX) -o src2.o src2.h -c $(CPPFLAGS) $(CXXFLAGS)

Hier wird das `my_program` aus 3 Objektdateien gelinkt und die 3 Objektdateien `main.o`, `src1.o` und
`src2.o` werden aus den entsprechenden Quelldateien erzeugt. Make sorgt dafür, dass nichtexistierende 
oder veraltete Targets neu erzeugt werden und dass die Regeln erst dann ausgeführt werden, wenn alle 
Voraussetzungen abgeschlossen sind. Insbesondere wird in dem Beispiel der Linker erst dann gestartet, 
wenn alle Objekte fertiggestellt sind. Die Kompilierung der Quelldateien kann hier parallel erfolgen.

Compiler ermöglichen die automatische Erzeugung des Abhängikeitsbaumes indem sie Regeln erzeugen, die 
die Abhängigkeiten einer Objektdatei von includierten Header-Dateien beschreiben. In unserem Beispiel 
wären das:

	//main.dep
	main.o: main.cpp head1.h head2.h

	//src1.dep
	src1.o: src1.cpp head1.h head2.h

	//src2.dep
	src2.o: src2.cpp head2.h

Wird jetzt z. Bsp. nur die Datei `src1.h` geändert, werden bei einem Build-Lauf nur die Dateien 
`src1.o`, `main.o` und anschliessend `my_program` neu gebaut, `src2.o` wird nicht neu übersetzt, da keine 
der Voraussetzungen geändert wurde.

Eine vollständige Erklärung der Automatischen Abhängigkeitserzeugung findet sich hier:
<https://make.mad-scientist.net/papers/advanced-auto-dependency-generation/>

## Der Build-Prozess mit C++ Modulen

### Der neue Abhängikeitsbaum

Wird ein C++-Modul übersetzt, der Funktionen, Variablen etc. exportiert, werden von GCC 2 Dateien 
erzeugt, die Objektdatei und das Compilierte-Module-Interface (CMI).

Wird eine Quelldatei (TU) übersetzt, die Dinge aus einem anderen Modul importiert, wird das 
Compilierte-Module-Interface (CMI) der Importe benötigt. Wenn Make die korrekten Abhängigkeitsdaten 
hat, werden die Quelldateien in der entsprechenden Reihenfolge übersetzt.

GNU-Make unterstützt *Rules with Grouped Targets*, die ausdrücken, dass eine Regel mehrere Ausgangsdateien 
erzeugt. Siehe: <https://www.gnu.org/software/make/manual/make.html#Multiple-Targets>

Im folgenden Beispiel importiert das Hauptproramm `main.cpp` Funktionen etc., aus den Modulen `module1` 
und `module2`. Die Export-Deklarationen und die Definitionen befinden sich in den Übersetzungseinheiten 
`src1.cpp` bzw. `src2.cpp`. Ausserdem Importiert `src1.cpp` Funktionen etc. aus Modul `module2`. 
Das kann in folgenden Makefile Rules zum Ausdruck gebracht werden:

	//Makefile
	# Link all together
	my_program: main.o src1.o src2.o
		$(CXX) -o my_program $(LINKFLAGS) main.o src1.o src2.o
	# Compile TU main with import of module1 and module2
	main.o: main.cpp module1.cmi module2.cmi
		$(CXX) -o main.o main.cpp -c -fmodules $(CPPFLAGS) $(CXXFLAGS)
	# src1 exports module1 and imports from module2
	src1.o module1.cmi &: src.cpp module2_cmi
		$(CXX) -o src1.o src1.cpp -c -fmodules $(CPPFLAGS) $(CXXFLAGS)
	# src2 exports module2
	src2.o module2.cmi &: src2.cpp
		$(CXX) -o src2.o src2.cpp -c -fmodules $(CPPFLAGS) $(CXXFLAGS)

Im klassischen Build-Prozess, ohne Module, gibt es eine feste vordefinierte Zuordnung von Eingabe- 
und Ausgabe-Dateinamen: Aus Quelldatei xxx.cpp wird Objektdatei xxx.o. Das kann auch im Modul-Fall 
beibehalten werden.

GCC unterstützt verschiedene Methoden der Zuordnung von CMI-File, Modulnamen und Quelldateiname. Im 
einfachsten Fall werden die CMI-Dateien im Directory `gcm.cache` unter dem Modulnamen abgelegt und 
mit der Endung `.gcm` versehen.

### Vorschlag für die automatische Erzeugung des Abhängigkeitsbaumes

GCC kann Dateien erzeugen, die ähnlich wie im klassischen Fall, den Abhängigkeitsbaum beschreiben. 
Die Zuordnung von Quelldatei zu CMI-Datei für Modul-Exporte kann dabei über Variablen erfolgen.

Für das o. g. Beispiel werden folgende Abhängigkeits-Fragmente benötigt:

	//main.dep
	# like in the classical case
	main.o : main.cpp
	# add prerequisites coming from module imports
	main.o : $$(CXX_MOD_CMI_module1) $$(CXX_MOD_CMI_module2)

	//src1.dep
	# the 'classical' dependencies
	src1.o gcm.cache/module1.gcm : src1.cpp
	# add prerequisites comming from module imports
	src1.o gcm.cache/module1.gcm : $$(CXX_MOD_CMI_module2)
	# module to CMI file database
	CXX_MOD_CMI_module1 = gcm.cache/module1.gcm
	# append TU to list of Module Interface Units
	CXX_MODULE_INTERFACE_UNITS += src1.cpp
	# append generated CMI file to list
	CXX_CMI_FILES += gcm.cache/module1.gcm

	//src2.dep
	src2.o gcm.cache/module2.gcm : src2.cpp
	CXX_MOD_CMI_module2 = gcm.cache/module2.gcm
	CXX_MODULE_INTERFACE_UNITS += src2.cpp
	CXX_CMI_FILES += gcm.cache/module2.gcm

In der ersten Phase des Build-Prozesses werden die Dependency-Dateien erzeugt. Diese Dateien 
werden im Makefile Includiert. Wenn die Dateien nicht existierten oder wenn sich der Inhalt ändert, 
führt Make ein re-start aus bevor die 2. Phase des Build-Prozesses abläuft und stellt sicher, dass der 
aktuelle Abhängigkeitsbaum verwendet wird. Siehe: 
<https://www.gnu.org/software/make/manual/make.html#Remaking-Makefiles>

Da nicht sichergestellt werden kann, dass die Deklarationen der Variablen `CXX_MOD_CMI_<module name>` 
vor den Rules die sie referenzieren erfolgt, müssen diese Variablen in der *Secondary Expansion* 
ausgewertet werden. Dazu muss das Target `.SECONDEXPANSION` vor den Dependency-Rules definiert werden.
Siehe: <https://www.gnu.org/software/make/manual/make.html#Secondary-Expansion>

Die Variable mit der Liste aller Module Interface Units `CXX_MODULE_INTERFACE_UNITS` wird benutzt um 
alle Gruppierten-Target-Rules zur Compilierung der entsprechenden Quelldateien zu erzeugen. Da Pattern-
Rules nicht die Sythax `&:` verwenden können bleibt hier nur der Weg über die `eval` function.

Für Modulpartitionen werden Namen verwendet, die einen Doppelpunkt enthalten. Doppelpunkte haben für 
Make eine spezielle Bedeutung. Daher sollten Doppelpunkte durch einfache Striche `-` ersetzt werden.

Namen für Submodule enthalten Punkte. Punkte haben für Make keine spezielle Bedeutung und können 
daher verwendet werden.

### Beispiel Makefile

	ifndef MAKE_RESTARTS
	$(info **** Starting Makefile)
	else
	$(info **** Re-starting Makefile: number of restarts = $(MAKE_RESTARTS))
	endif

	RMDIR = rm -rf
	MKDIR = mkdir -p

	TARGET := my_program
	CXX = g++-15
	MODULFLAGS = -std=c++20 -fmodules
	CXXFLAGS ?= -Wall -Wextra -Wpedantic -ftabstop=4 -fmessage-length=0
	DEPFLAGS = -MMD -MP -MF '$*.dep.tmp' -MT '$*.o'
	OUTPUT_OPTION = -o $@

	sourcescpp := $(wildcard *.cpp)
	prepcoccpp := $(sourcescpp:.cpp=.ii)
	objectscpp := $(sourcescpp:.cpp=.o)
	depfiles := $(sourcescpp:.cpp=.dep)
	deptempfiles := $(addsuffix .tmp,$(depfiles))

	.PHONY: all
	all: $(TARGET)

	.SECONDEXPANSION:
	include $(depfiles)

	notamoduleinterface := $(filter-out $(CXX_MODULE_INTERFACE_UNITS),$(sourcescpp))
	notamoduleinterfaceobj := $(notamoduleinterface:.cpp=.o)

	$(info source files : $(sourcescpp))
	$(info object files : $(objectscpp))
	$(info depend files : $(depfiles))
	$(info CXX_MODULE_INTERFACE_UNITS files : $(CXX_MODULE_INTERFACE_UNITS))
	$(info notamoduleinterface files : $(notamoduleinterface))
	$(info )

	# Link final program
	$(TARGET): $(objectscpp)
		$(CXX) $(OUTPUT_OPTION) $(foreach var,$^,'$(var)')
		@echo -e "Finished linking: $@\n"

	# Rule for translating all non-interface files
	%.o: %.cpp
	$(notamoduleinterfaceobj): %.o : %.cpp %.dep
		$(CXX) $(OUTPUT_OPTION) $< -c $(MODULFLAGS) $(CPPFLAGS) $(CXXFLAGS)
		@echo -e "Finished compiling: $<\n"

	# Rules with Grouped Targets for module Interfaces to translate a source into object and CMI file
	define modul_template =
	$(1).o $(2) &: $(1).cpp $(1).dep | gcm.cache
		$(CXX) -o $(1).o $$< -c $(MODULFLAGS) $(CPPFLAGS) $(CXXFLAGS)
		@echo -e "Finished modul compiling: $$<\n"

	endef

	# Generate rules for all module interfaces
	$(foreach mod,$(CXX_MODULE_INTERFACE_UNITS),$(eval $(call modul_template,$(mod:.cpp=),$$(CXX_SRC_CMI_$(mod)))))

	# order only target to make the directory if not existing
	gcm.cache:
		$(MKDIR) '$@'
		@echo

	# Rule to build the dependency files
	$(depfiles): %.dep : %.cpp
		$(CXX) -o '$*.ii' $< -E $(DEPFLAGS) $(MODULFLAGS) $(CPPFLAGS) $(CXXFLAGS)
		fixdep.sh '$*.dep.tmp' '$@' '$<' '.c++-module'
		@echo -e "Finished preprocessing: $<\n"

