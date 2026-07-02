# C++ Projekte mit Modulen mit GNU Make und der GNU Compiler Collection Builden

## Hintergrund

Mit dem Standard C++20 haben Module in C++ Einzug gehalten. C++-Module haben eine Reihe von Vorteilen 
gegenüber den herkömmlichen Include-Direktiven des Präprozessors; sie können die Übersetzungszeiten 
senken und verbessern die Code-Hygiene. Module erhöhen aber die Anforderungen an den Build-Prozess, weil 
neue Abhängigkeiten für Modul-Import und Modul-Export zu berücksichtigen sind. Insbesondere muss das 
kompilierte Modul-Interface (CMI) des exportierenden Moduls vorliegen bevor eine Übersetzungseinheit, 
die den Modul importiert, erfolgreich übersetzt werden kann. Außerdem ist es erforderlich, eine 
Zuordnung von Quelldatei, Modulname und Modul-Interface-Datei vorzunehmen.

Der folgende Artikel erläutert eine Möglichkeit, wie das mit der GNU-Compiler-Collection und GNU-Make zu 
realisieren ist.

## Der klassische Build-Prozess

Im klassischen Build-Prozess ohne C++-Module sind alle Übersetzungseinheiten (TU) unabhängig voneinander 
und nur von den includierten Header-Dateien abhängig. Alle Übersetzungseinheiten könne also unabhängig 
voneinander insbesondere auch parallel zu Objektdateien übersetzt werden. Zuletzt erfolgt das Linken aller 
Objekte zu einer ausführbaren Datei oder einer Bibliothek.

Im Entwicklungsprozess muss ein Projekt normalerweise sehr häufig übersetzt werden. Dabei ist es gängige 
Praxis, dass ein Build-System die und nur die Übersetzungseinheiten neu übersetzt, zu denen geänderte 
Dateien beitragen. Dazu müssen dem Make-Programm alle Abhängigkeiten bekannt gemacht werden.

Im folgenden Beispiel includiert das Hauptproramm `main.cpp` Funktionen etc., die in den Header-Files 
`head1.h` und `head2.h` definiert sind. Die Implementierung der Funktionen befindet sich in den 
Übersetzungseinheiten `src1.cpp` bzw. `src2.cpp`. Außerdem includiert `src1.cpp` Funktionen etc. von 
`head2.h`. Das kann in folgenden Makefile Rules zum Ausdruck gebracht werden:

	//Makefile1.mk
	my_program : main.o src1.o src2.o
		g++ -o my_program main.o src1.o src2.o
	main.o : main.cpp head1.h head2.h
		g++ -o main.o main.cpp -c
	src1.o : src1.cpp head1.h head2.h
		g++ -o src1.o src1.cpp -c
	src2.o : src2.cpp head2.h
		g++ -o src2.o src2.cpp -c

Hier wird das Programm `my_program` aus 3 Objektdateien gelinkt und die 3 Objektdateien 
`main.o`, `src1.o` und`src2.o` werden aus den entsprechenden Quelldateien erzeugt. Make sorgt 
dafür, dass nichtexistierende oder veraltete Ziele neu erzeugt werden und dass Regeln erst 
dann ausgeführt werden, wenn alle Voraussetzungen abgeschlossen sind. Insbesondere wird in dem 
Beispiel der Linker erst dann gestartet, wenn alle Objekte fertiggestellt sind. Die Kompilierung 
aller Quelldateien kann hier parallel erfolgen.

Compiler ermöglichen die automatische Erzeugung des Abhängigkeitsbaumes indem sie Regeln erzeugen, die 
die Abhängigkeiten einer Objektdatei von der Quelldatei und von includierten Header-Dateien beschreiben. 
In unserem Beispiel sind das:

	//main.dep
	main.o : main.cpp head1.h head2.h

	//src1.dep
	src1.o : src1.cpp head1.h head2.h

	//src2.dep
	src2.o : src2.cpp head2.h

Wird jetzt z. Bsp. nur die Datei `head1.h` geändert, werden bei einem Build-Lauf nur die Dateien 
`src1.o`, `main.o` und anschließend `my_program` neu gebaut, `src2.o` wird nicht neu übersetzt, da keine 
der Voraussetzungen geändert wurde.

Eine vollständige Erklärung der Automatischen Abhängigkeitserzeugung findet sich hier:
<https://make.mad-scientist.net/papers/advanced-auto-dependency-generation/>

Für die Kompilierung, gibt es in der Regel eine feste vordefinierte Zuordnung von Eingabe- und 
Ausgabe-Dateinamen: z. B.: Aus Quelldatei foo.cpp wird Objektdatei foo.o.
Daher können die Regeln für die Kompilierung zusammengefasst werden und in Form von impliziten Regeln 
oder Statischen-Muster-Regeln 
(Siehe: <https://www.gnu.org/software/make/manual/html_node/Static-Pattern.html>) formuliert werden. 
Das vereinfachte Makefile:

	//Makefile2.mk
	objects = main.o src1.o src2.o

	my_program : $(objects)
		g++ -o my_program $^

	$(objects) : %.o: %.cpp
		g++ -o $@ $< -c -MMD -MF $*.dep

	depfiles = $(objects:.o=.dep)
	-include $(depfiles)

## Der Build-Prozess mit C++ Modulen

### Der neue Abhängigkeitsbaum

Wird ein C++-Modul übersetzt, der Funktionen, Variablen etc. exportiert, werden von GCC 2 Ausgabedateien 
erzeugt, die Objektdatei und das Compilierte-Module-Interface (CMI).

GCC unterstützt verschiedene Methoden der Zuordnung von CMI-File, Modulnamen und Quelldateiname. Im 
einfachsten Fall werden die CMI-Dateien im Directory `gcm.cache` unter dem Modulnamen abgelegt und 
mit der Endung `.gcm` versehen.

Die feste vordefinierte Zuordnung von Source- und Objekt-Dateinamen, kann auch im Modulfall 
beibehalten werden.

Wird eine Quelldatei übersetzt, die Dinge aus einem anderen Modul importiert, wird das 
Compilierte-Module-Interface (CMI) der Importe benötigt. Wenn Make die korrekten Abhängigkeitsdaten 
hat, werden die Quelldateien in der entsprechenden Reihenfolge übersetzt.

GNU-Make unterstützt Gruppierte-Ziele-Regeln, die ausdrücken, dass eine Regel mehrere Ausgangsdateien 
erzeugt. Siehe: <https://www.gnu.org/software/make/manual/make.html#Multiple-Targets>

Im folgenden Beispiel importiert das Hauptprogramm `main.cpp` Funktionen etc., aus den Modulen `module1` 
und `module2`. Die Export-Deklarationen und die Definitionen befinden sich in den Übersetzungseinheiten 
`src1.cpp` bzw. `src2.cpp`. Außerdem Importiert `src1.cpp` Funktionen etc. aus Modul `module2`. 
Weiter includieren die Quelldateien Konstanten aus den Header-Dateien `header1.h` und `header2.h`. 
Die Regeln für die Übersetzung der Quelldateien und für den Linker können wie folgt aussehen:

	//Makefile1.mk
	my_program: main.o src1.o src2.o
		g++ -o my_program main.o src1.o src2.o

	main.o: main.cpp header2.h gcm.cache/module1.gcm gcm.cache/module2.gcm
		g++ -o main.o main.cpp -c -fmodules

	src1.o gcm.cache/module1.gcm &: src1.cpp header1.h gcm.cache/module2.gcm
		g++ -o src1.o src1.cpp -c -fmodules

	src2.o gcm.cache/module2.gcm &: src2.cpp header2.h
		g++ -o src2.o src2.cpp -c -fmodules

Der Standard erlaubt keine zirkulären Modulimporte. Make gibt eine Warnung aus, wenn eine 
Zirkularität im Abhängigkeitsbaum erkannt wird und beendet die Abhängigkeitsanalyse.

### Die automatische Erzeugung der Abhängigkeitsregeln

GCC kann Dateien erzeugen die, ähnlich wie im klassischen Fall den Abhängigkeitsbaum beschreiben. 
Die erzeugten Dependency-Dateien müssen zusätzlich zu den herkömmlichen Header-Abhängigkeiten, die 
Abhängigkeiten von den CMI-Dateien der importierten Module enthalten. Der Speicherort der CMI-Dateien 
kann variieren, daher wird diese Abhängigkeit als Variable der Form `CXX_MOD_<module name>_CMI` 
zum Ausdruck gebracht. Der Wert der Variable wird im Make-Script ermittelt.

Für Modulpartitionen werden Namen verwendet, die einen Doppelpunkt enthalten. Doppelpunkte haben für 
Make eine spezielle Bedeutung und können nicht in Variablennamen verwendet werden. Daher müssen 
Doppelpunkte durch einfache Striche `-` ersetzt werden. Alle anderen Zeichen, die in C++ Modulnamen 
verwendet werden können, auch Zeichen aus dem erweiterten Zeichensatz sind in Make Variablennamen 
erlaubt. Ein Dollarsymbol `$` muss durch zwei bzw. vier aufeinanderfolgende Dollarsymbole dargestellt 
werden.

Namen für Submodule enthalten Punkte. Punkte haben für Make keine spezielle Bedeutung und können 
in Variablennamen verwendet werden.

Außerdem müssen die Dependency-Dateien Informationen bereitstellen, die vom Quelldateinamen auf 
den enthaltenen Modulnamen schließen lassen. Dazu wird eine Liste erzeugt, die für jede Modulquelle 
ein Tripel aus Quelldateiname, Modulname und einen boolschen Wert 'is_interface' enthält 
(`CXX_SRC_MOD_IF_LIST`). Die Teile des Tripels werden durch Semikolon getrennt. Ein Semikolon 
darf weder in einem Modulnamen noch in einem Dateinamen erscheinen. Auch hier muss ein 
Doppelpunkt im Modulnamen durch einen einfachen Strich und das Dollarsymbol durch zwei 
Dollarsymbole ersetzt werden.

Da nicht sichergestellt werden kann, dass die Deklarationen der Variablen `CXX_MOD_<module name>_CMI` 
vor den Regeln die sie benötigen erfolgt, müssen diese Variablen in der Secondary Expansion 
ausgewertet werden. Dazu muss das Target `.SECONDEXPANSION` vor den Abhängigkeitsregeln 
definiert werden.
Siehe: <https://www.gnu.org/software/make/manual/make.html#Secondary-Expansion>

Die Abhängigkeitsregeln für das Beispiel:

	//main.dep
	main.o : main.cpp header2.h
	main.o : $$(CXX_MOD_module1_CMI) $$(CXX_MOD_module2_CMI)

	//src1.dep
	src1.o : src1.cpp header1.h
	src1.o : $$(CXX_MOD_module2_CMI)
	CXX_SRC_MOD_IF_LIST += src1.cpp;module1;1

	//src2.dep
	src2.o : src2.cpp header2.h
	CXX_SRC_MOD_IF_LIST += src2.cpp;module2;1

	//automatic generated definitions
	CXX_MOD_module1_CMI = gcm.cache/module1.gcm
	CXX_MOD_module2_CMI = gcm.cache/module2.gcm
	modsources = src1.cpp src2.cpp

Die Voraussetzungen sind hier nur für die Objektdateien aufgelistet. Da für die Produktion der 
Modul-Objekte eine Gruppierten-Target-Regel verwendet wird, erkennt Make dass das Modul-Objekt 
und CMI-Datei gleichzeitig erzeugt werden.

Die erzeugten Abhängigkeitsdateien werden anschließend includiert.

Make versucht stets zuerst die Regeln auszuführen, die 'Makefile' oder die includierten Dateien 
'main.dep', 'src1.dep', oder 'src2.dep' auf aktuellen Stand bringen.
Siehe: <https://www.gnu.org/software/make/manual/make.html#Remaking-Makefiles>

So werden in der ersten Phase des Build-Prozesses die Abhängigkeitsdateien erzeugt. Wenn sich der 
Inhalt der includierten Dateien ändert, führt Make einen Restart aus bevor die 2. Phase des 
Build-Prozesses abläuft und stellt so sicher, dass immer der aktuelle Abhängigkeitsbaum verwendet 
wird.

Das Make-Script:

	//Makefile3.mk
	sources = main.cpp src1.cpp src2.cpp
	objects = $(sources:.cpp=.o)

	# Link all together
	my_program: $(objects)
		g++ -o my_program $(objects) -std=c++20 -fmodules

	# generate dependency files
	depfiles = $(sources:.cpp=.dep)
	$(depfiles) : %.dep: %.cpp
		g++ $< -MM -MF $@ -MQ $@ -fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o -c -std=c++20 -fmodules
		p1689_to_make2.sh $*.ddi $< $*.o $@

	# Include all depfiles
	.SECONDEXPANSION:
	include $(depfiles)

Die Regel zur Erzeugung der Abhängigkeitsdatei führt folgende Schritte aus:

1. Das Ziel dieser Regel ist die Abhängigkeitsdatei (.dep) selbst. Damit wird erreicht, dass die 
Abhängigkeitsdatei neu erzeugt wird wenn sie nicht existiert oder wenn die Quelldatei oder eine 
der includierten Header-Dateien neuer ist als das Target. (`-MM -MF $@ -MQ $@`)

2. Die Modulabhängigkeiten werden in einer JSON-Codierten Datei (.ddi) abgelegt. 
(`-fdeps-format=p1689r5 -fdeps-file=$*.ddi -fdeps-target=$*.o`)

3. Das Script `p1689_to_make2.sh` liest die ddi-Datei und erweitert die dep-Datei 
um die Modulabhängigkeiten im Makeformat.


### Die automatisierte Erzeugung der Produktionsregeln

Die Regeln für die Kompilierung vom Module-Units unterscheiden sich von den Regeln 
gewöhnlicher Quelldateien. Da der Zusammenhang von Quelldateiname und Modulname 
nicht durch Mustersubstitution hergestellt werden kann, können keine Musterregeln 
für die Module-Units benutzt werden. Hier werden Gruppierte-Ziele-Regeln durch 
die `eval` Funktion in einer Schleife erzeugt.

Die Liste `CXX_SRC_MOD_IF_LIST` wird benutzt um alle Gruppierte-Ziele-Regeln 
zur Übersetzung der Moduldateien zu erzeugen und um die Verknüpfung von Modulname zu 
CMI-File aufzulösen. Wenn ein spezielles Mapping der CMI-Dateien gewünscht ist, kann das 
an dieser Stelle verwirklicht werden. Das Beispiel verwendet die Standardzuordnung.

	//Makefile3.mk
	define modul_rule_template
	$(src:.cpp=.o) gcm.cache/$(mod).gcm &: $(src:.cpp=.dep)
		g++ -o $(src:.cpp=.o) $(src) -c -std=c++20 -fmodules
	endef

	$(foreach line,$(CXX_SRC_MOD_IF_LIST),\
		$(let src mod is_if,$(subst ;, ,$(line)),\
			$(eval $(modul_rule_template))\
			$(eval CXX_MOD_$(mod)_CMI = gcm.cache/$(mod).gcm)\
			$(eval modsources += $(src))\
		)\
	)

Als Voraussetzung für eine Objektdatei wird die dazugehörige Abhängigkeitsdatei 
angegeben. Damit werden alle Header-Abhängigkeiten der Abhängigkeitsdatei auf die 
Objektdatei übertragen.

In einer Gruppierte-Ziele-Regel kombiniert Make die Abhägigkeitsbäume aller Ziele 
und stellt sicher dass die Ziele neu erzeugt werden, wenn eine Voraussetzung aller 
Ziele neuer ist als das ältesete Ziel der Regel.

Die Regeln für gewöhnliche Quelldateien lassen sich wie bisher als implizite Regel 
oder als Statische-Muster-Regel formulieren.

	//Makefile3.mk
	# no module sources
	nomodsources = $(filter-out $(modsources),$(sources))
	nomodobjects = $(nomodsources:.cpp=.o)

	$(nomodobjects): %.o: %.cpp %.dep
		g++ -o $@ $< -c -std=c++20 -fmodules


### Header Units

Wenn eine Übersetzungseinheit Header-Units importiert, muss das Compilierte-Header-
Interface vorliegen bevor die Abhängigkeitsdatei erzeugt werden kann. Daher müssen 
alle Header-Units in einem vorgelagerten Schritt übersetzt werden.
