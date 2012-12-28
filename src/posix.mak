ifeq (,$(TARGET))
    OS:=$(shell uname)
    OSVER:=$(shell uname -r)
    ifeq (Darwin,$(OS))
        TARGET=OSX
    else
        ifeq (Linux,$(OS))
            TARGET=LINUX
        else
            ifeq (FreeBSD,$(OS))
                TARGET=FREEBSD
            else
                ifeq (OpenBSD,$(OS))
                    TARGET=OPENBSD
                else
                    ifeq (Solaris,$(OS))
                        TARGET=SOLARIS
                    else
                        ifeq (SunOS,$(OS))
                            TARGET=SOLARIS
                        else
                            $(error Unrecognized or unsupported OS for uname: $(OS))
                        endif
                    endif
                endif
            endif
        endif
    endif
endif

ifeq (,$(TARGET_CPU))
    $(warning no cpu specified, assuming X86)
    TARGET_CPU=X86
endif

ifeq (X86,$(TARGET_CPU))
    TARGET_CH = $C/code_x86.h
    TARGET_OBJS = cg87.o cgxmm.o cgsched.o cod1.o cod2.o cod3.o cod4.o ptrntab.o
else
    ifeq (stub,$(TARGET_CPU))
        TARGET_CH = $C/code_stub.h
        TARGET_OBJS = platform_stub.o
    else
        $(error unknown TARGET_CPU: '$(TARGET_CPU)')
    endif
endif

C=backend
TK=tk
ROOT=root

MODEL=32
ifneq (x,x$(MODEL))
    MODEL_FLAG=-m$(MODEL)
endif

ifeq (OSX,$(TARGET))
    SDKDIR=/Developer/SDKs
    ifeq "$(wildcard $(SDKDIR))" ""
        SDKDIR=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs
    endif
    ## See: http://developer.apple.com/documentation/developertools/conceptual/cross_development/Using/chapter_3_section_2.html#//apple_ref/doc/uid/20002000-1114311-BABGCAAB
    ENVP= MACOSX_DEPLOYMENT_TARGET=10.3
    SDKVERS:=1 2 3 4 5 6 7 8
    SDKFILES=$(foreach SDKVER, $(SDKVERS), $(wildcard $(SDKDIR)/MacOSX10.$(SDKVER).sdk))
    SDK=$(firstword $(SDKFILES))
    TARGET_CFLAGS=-isysroot ${SDK}
    #-syslibroot is only passed to libtool, not ld.
    #if gcc sees -isysroot it should pass -syslibroot to the linker when needed
    #LDFLAGS=-lstdc++ -isysroot ${SDK} -Wl,-syslibroot,${SDK} -framework CoreServices
    LDFLAGS=-lstdc++ -isysroot ${SDK} -Wl -framework CoreServices
else
    LDFLAGS=-lm -lstdc++ -lpthread
endif

HOST_CC=g++
CC=$(HOST_CC) $(MODEL_FLAG) $(TARGET_CFLAGS)

#OPT=-g -g3
#OPT=-O2

#COV=-fprofile-arcs -ftest-coverage

WARNINGS=-Wno-deprecated -Wstrict-aliasing

#GFLAGS = $(WARNINGS) -D__pascal= -fno-exceptions -g -DDEBUG=1 -DUNITTEST $(COV)
GFLAGS = $(WARNINGS) -D__pascal= -fno-exceptions -O2

CFLAGS = $(GFLAGS) -I$(ROOT) -DMARS=1 -DTARGET_$(TARGET)=1 -DDM_TARGET_CPU_$(TARGET_CPU)=1
MFLAGS = $(GFLAGS) -I$C -I$(TK) -I$(ROOT) -DMARS=1 -DTARGET_$(TARGET)=1 -DDM_TARGET_CPU_$(TARGET_CPU)=1

CH= $C/cc.h $C/global.h $C/oper.h $C/code.h $C/type.h \
	$C/dt.h $C/cgcv.h $C/el.h $C/obj.h $(TARGET_CH)

DMD_OBJS = \
	access.o array.o attrib.o bcomplex.o blockopt.o \
	cast.o code.o cg.o cgcod.o cgcs.o cgelem.o cgen.o \
	cgreg.o class.o cod5.o \
	constfold.o irstate.o cond.o debug.o \
	declaration.o dsymbol.o dt.o dump.o e2ir.o ee.o eh.o el.o \
	dwarf.o enum.o evalu8.o expression.o func.o gdag.o gflow.o \
	glocal.o gloop.o glue.o gnuc.o go.o gother.o iasm.o id.o \
	identifier.o impcnvtab.o import.o inifile.o init.o inline.o \
	lexer.o link.o mangle.o mars.o rmem.o module.o msc.o mtype.o \
	nteh.o cppmangle.o opover.o optimize.o os.o out.o outbuf.o \
	parse.o ph.o root.o rtlsym.o s2ir.o scope.o statement.o \
	stringtable.o struct.o csymbol.o template.o tk.o tocsym.o todt.o \
	type.o typinf.o util.o var.o version.o strtold.o utf.o staticassert.o \
	toobj.o toctype.o toelfdebug.o entity.o doc.o macro.o \
	hdrgen.o delegatize.o aa.o ti_achar.o toir.o interpret.o traits.o \
	builtin.o ctfeexpr.o clone.o aliasthis.o \
	man.o arrayop.o port.o response.o async.o json.o speller.o aav.o unittests.o \
	imphint.o argtypes.o ti_pvoid.o apply.o sideeffect.o \
	intrange.o canthrow.o \
	pdata.o cv8.o \
	$(TARGET_OBJS)

ifeq (OSX,$(TARGET))
    DMD_OBJS += libmach.o machobj.o
else
    DMD_OBJS += libelf.o elfobj.o
endif

SRC = win32.mak posix.mak \
	mars.cpp enum.cpp struct.cpp dsymbol.cpp import.cpp idgen.cpp impcnvgen.cpp \
	identifier.cpp mtype.cpp expression.cpp optimize.cpp template.h \
	template.cpp lexer.cpp declaration.cpp cast.cpp cond.h cond.cpp link.cpp \
	aggregate.h parse.cpp statement.cpp constfold.cpp version.h version.cpp \
	inifile.cpp iasm.cpp module.cpp scope.cpp dump.cpp init.h init.cpp attrib.h \
	attrib.cpp opover.cpp class.cpp mangle.cpp tocsym.cpp func.cpp inline.cpp \
	access.cpp complex_t.h irstate.h irstate.cpp glue.cpp msc.cpp ph.cpp tk.cpp \
	s2ir.cpp todt.cpp e2ir.cpp util.cpp identifier.h parse.h \
	scope.h enum.h import.h mars.h module.h mtype.h dsymbol.h \
	declaration.h lexer.h expression.h irstate.h statement.h eh.cpp \
	utf.h utf.cpp staticassert.h staticassert.cpp \
	typinf.cpp toobj.cpp toctype.cpp tocvdebug.cpp toelfdebug.cpp entity.cpp \
	doc.h doc.cpp macro.h macro.cpp hdrgen.h hdrgen.cpp arraytypes.h \
	delegatize.cpp toir.h toir.cpp interpret.cpp traits.cpp cppmangle.cpp \
	builtin.cpp clone.cpp lib.h libomf.cpp libelf.cpp libmach.cpp arrayop.cpp \
	libmscoff.cpp \
	aliasthis.h aliasthis.cpp json.h json.cpp unittests.cpp imphint.cpp \
	argtypes.cpp apply.cpp sideeffect.cpp \
	intrange.h intrange.cpp canthrow.cpp \
	scanmscoff.cpp ctfe.h ctfeexpr.cpp \
	$C/cdef.h $C/cc.h $C/oper.h $C/ty.h $C/optabgen.cpp \
	$C/global.h $C/code.h $C/type.h $C/dt.h $C/cgcv.h \
	$C/el.h $C/iasm.h $C/rtlsym.h \
	$C/bcomplex.cpp $C/blockopt.cpp $C/cg.cpp $C/cg87.cpp $C/cgxmm.cpp \
	$C/cgcod.cpp $C/cgcs.cpp $C/cgcv.cpp $C/cgelem.cpp $C/cgen.cpp $C/cgobj.cpp \
	$C/cgreg.cpp $C/var.cpp $C/strtold.cpp \
	$C/cgsched.cpp $C/cod1.cpp $C/cod2.cpp $C/cod3.cpp $C/cod4.cpp $C/cod5.cpp \
	$C/code.cpp $C/symbol.cpp $C/debug.cpp $C/dt.cpp $C/ee.cpp $C/el.cpp \
	$C/evalu8.cpp $C/go.cpp $C/gflow.cpp $C/gdag.cpp \
	$C/gother.cpp $C/glocal.cpp $C/gloop.cpp $C/newman.cpp \
	$C/nteh.cpp $C/os.cpp $C/out.cpp $C/outbuf.cpp $C/ptrntab.cpp $C/rtlsym.cpp \
	$C/type.cpp $C/melf.h $C/mach.h $C/mscoff.h $C/bcomplex.h \
	$C/cdeflnx.h $C/outbuf.h $C/token.h $C/tassert.h \
	$C/elfobj.cpp $C/cv4.h $C/dwarf2.h $C/exh.h $C/go.h \
	$C/dwarf.cpp $C/dwarf.h $C/aa.h $C/aa.cpp $C/tinfo.h $C/ti_achar.cpp \
	$C/ti_pvoid.cpp $C/platform_stub.cpp $C/code_x86.h $C/code_stub.h \
	$C/machobj.cpp $C/mscoffobj.cpp \
	$C/xmm.h $C/obj.h $C/pdata.cpp $C/cv8.cpp \
	$C/md5.cpp $C/md5.h \
	$(TK)/filespec.h $(TK)/mem.h $(TK)/list.h $(TK)/vec.h \
	$(TK)/filespec.cpp $(TK)/mem.cpp $(TK)/vec.cpp $(TK)/list.cpp \
	$(ROOT)/root.h $(ROOT)/root.cpp $(ROOT)/array.cpp \
	$(ROOT)/rmem.h $(ROOT)/rmem.cpp $(ROOT)/port.h $(ROOT)/port.cpp \
	$(ROOT)/gnuc.h $(ROOT)/gnuc.cpp $(ROOT)/man.cpp \
	$(ROOT)/stringtable.h $(ROOT)/stringtable.cpp \
	$(ROOT)/response.cpp $(ROOT)/async.h $(ROOT)/async.cpp \
	$(ROOT)/aav.h $(ROOT)/aav.cpp \
	$(ROOT)/longdouble.h $(ROOT)/longdouble.cpp \
	$(ROOT)/speller.h $(ROOT)/speller.cpp \
	$(TARGET_CH)


all: dmd

dmd: $(DMD_OBJS)
	$(ENVP) $(HOST_CC) -o dmd $(MODEL_FLAG) $(COV) $(DMD_OBJS) $(LDFLAGS)

clean:
	rm -f $(DMD_OBJS) dmd optab.o id.o impcnvgen idgen id.cpp id.h \
	impcnvtab.cpp optabgen debtab.cpp optab.cpp cdxxx.cpp elxxx.cpp fltables.cpp \
	tytab.cpp core \
	*.cov *.gcda *.gcno

######## optabgen generates some source

optabgen: $C/optabgen.cpp $C/cc.h $C/oper.h
	$(ENVP) $(CC) $(MFLAGS) $< -o optabgen
	./optabgen

optabgen_output = debtab.cpp optab.cpp cdxxx.cpp elxxx.cpp fltables.cpp tytab.cpp
$(optabgen_output) : optabgen

######## idgen generates some source

idgen_output = id.h id.cpp
$(idgen_output) : idgen

idgen : idgen.cpp
	$(ENVP) $(CC) idgen.cpp -o idgen
	./idgen

######### impcnvgen generates some source

impcnvtab_output = impcnvtab.cpp
$(impcnvtab_output) : impcnvgen

impcnvgen : mtype.h impcnvgen.cpp
	$(ENVP) $(CC) $(CFLAGS) impcnvgen.cpp -o impcnvgen
	./impcnvgen

#########

$(DMD_OBJS) : $(idgen_output) $(optabgen_output) $(impcnvgen_output)

aa.o: $C/aa.cpp $C/aa.h $C/tinfo.h
	$(CC) -c $(MFLAGS) -I. $<

aav.o: $(ROOT)/aav.cpp
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

access.o: access.cpp
	$(CC) -c $(CFLAGS) $<

aliasthis.o: aliasthis.cpp
	$(CC) -c $(CFLAGS) $<

apply.o: apply.cpp
	$(CC) -c $(CFLAGS) $<

argtypes.o: argtypes.cpp
	$(CC) -c $(CFLAGS) $<

array.o: $(ROOT)/array.cpp
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

arrayop.o: arrayop.cpp
	$(CC) -c $(CFLAGS) $<

async.o: $(ROOT)/async.cpp
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

attrib.o: attrib.cpp
	$(CC) -c $(CFLAGS) $<

bcomplex.o: $C/bcomplex.cpp
	$(CC) -c $(MFLAGS) $<

blockopt.o: $C/blockopt.cpp
	$(CC) -c $(MFLAGS) $<

builtin.o: builtin.cpp
	$(CC) -c $(CFLAGS) $<

canthrow.o: canthrow.cpp
	$(CC) -c $(CFLAGS) $<

cast.o: cast.cpp
	$(CC) -c $(CFLAGS) $<

cg.o: $C/cg.cpp fltables.cpp
	$(CC) -c $(MFLAGS) -I. $<

cg87.o: $C/cg87.cpp
	$(CC) -c $(MFLAGS) $<

cgcod.o: $C/cgcod.cpp
	$(CC) -c $(MFLAGS) -I. $<

cgcs.o: $C/cgcs.cpp
	$(CC) -c $(MFLAGS) $<

cgcv.o: $C/cgcv.cpp
	$(CC) -c $(MFLAGS) $<

cgelem.o: $C/cgelem.cpp $C/rtlsym.h
	$(CC) -c $(MFLAGS) -I. $<

cgen.o: $C/cgen.cpp $C/rtlsym.h
	$(CC) -c $(MFLAGS) $<

cgobj.o: $C/cgobj.cpp
	$(CC) -c $(MFLAGS) $<

cgreg.o: $C/cgreg.cpp
	$(CC) -c $(MFLAGS) $<

cgsched.o: $C/cgsched.cpp $C/rtlsym.h
	$(CC) -c $(MFLAGS) $<

cgxmm.o: $C/cgxmm.cpp
	$(CC) -c $(MFLAGS) $<

class.o: class.cpp
	$(CC) -c $(CFLAGS) $<

clone.o: clone.cpp
	$(CC) -c $(CFLAGS) $<

cod1.o: $C/cod1.cpp $C/rtlsym.h
	$(CC) -c $(MFLAGS) $<

cod2.o: $C/cod2.cpp $C/rtlsym.h
	$(CC) -c $(MFLAGS) $<

cod3.o: $C/cod3.cpp $C/rtlsym.h
	$(CC) -c $(MFLAGS) $<

cod4.o: $C/cod4.cpp
	$(CC) -c $(MFLAGS) $<

cod5.o: $C/cod5.cpp
	$(CC) -c $(MFLAGS) $<

code.o: $C/code.cpp
	$(CC) -c $(MFLAGS) $<

constfold.o: constfold.cpp
	$(CC) -c $(CFLAGS) $<

ctfeexpr.o: ctfeexpr.cpp ctfe.h
	$(CC) -c $(CFLAGS) $<

irstate.o: irstate.cpp irstate.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

csymbol.o: $C/symbol.cpp
	$(CC) -c $(MFLAGS) $< -o $@

cond.o: cond.cpp
	$(CC) -c $(CFLAGS) $<

cppmangle.o: cppmangle.cpp
	$(CC) -c $(CFLAGS) $<

cv8.o: $C/cv8.cpp
	$(CC) -c $(MFLAGS) $<

debug.o: $C/debug.cpp
	$(CC) -c $(MFLAGS) -I. $<

declaration.o: declaration.cpp
	$(CC) -c $(CFLAGS) $<

delegatize.o: delegatize.cpp
	$(CC) -c $(CFLAGS) $<

doc.o: doc.cpp
	$(CC) -c $(CFLAGS) $<

dsymbol.o: dsymbol.cpp
	$(CC) -c $(CFLAGS) $<

dt.o: $C/dt.cpp $C/dt.h
	$(CC) -c $(MFLAGS) $<

dump.o: dump.cpp
	$(CC) -c $(CFLAGS) $<

dwarf.o: $C/dwarf.cpp $C/dwarf.h
	$(CC) -c $(MFLAGS) -I. $<

e2ir.o: e2ir.cpp $C/rtlsym.h expression.h toir.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

ee.o: $C/ee.cpp
	$(CC) -c $(MFLAGS) $<

eh.o: eh.cpp $C/cc.h $C/code.h $C/type.h $C/dt.h
	$(CC) -c $(MFLAGS) $<

el.o: $C/el.cpp $C/rtlsym.h $C/el.h
	$(CC) -c $(MFLAGS) $<

elfobj.o: $C/elfobj.cpp
	$(CC) -c $(MFLAGS) $<

entity.o: entity.cpp
	$(CC) -c $(CFLAGS) $<

enum.o: enum.cpp
	$(CC) -c $(CFLAGS) $<

evalu8.o: $C/evalu8.cpp
	$(CC) -c $(MFLAGS) $<

expression.o: expression.cpp expression.h
	$(CC) -c $(CFLAGS) $<

func.o: func.cpp
	$(CC) -c $(CFLAGS) $<

gdag.o: $C/gdag.cpp
	$(CC) -c $(MFLAGS) $<

gflow.o: $C/gflow.cpp
	$(CC) -c $(MFLAGS) $<

#globals.o: globals.cpp
#	$(CC) -c $(CFLAGS) $<

glocal.o: $C/glocal.cpp $C/rtlsym.h
	$(CC) -c $(MFLAGS) $<

gloop.o: $C/gloop.cpp
	$(CC) -c $(MFLAGS) $<

glue.o: glue.cpp $(CH) $C/rtlsym.h mars.h module.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

gnuc.o: $(ROOT)/gnuc.cpp $(ROOT)/gnuc.h
	$(CC) -c $(GFLAGS) $<

go.o: $C/go.cpp
	$(CC) -c $(MFLAGS) $<

gother.o: $C/gother.cpp
	$(CC) -c $(MFLAGS) $<

hdrgen.o: hdrgen.cpp
	$(CC) -c $(CFLAGS) $<

iasm.o: iasm.cpp $(CH) $C/iasm.h
	$(CC) -c $(MFLAGS) -I$(ROOT) -fexceptions $<

id.o: id.cpp id.h
	$(CC) -c $(CFLAGS) $<

identifier.o: identifier.cpp
	$(CC) -c $(CFLAGS) $<

impcnvtab.o: impcnvtab.cpp mtype.h
	$(CC) -c $(CFLAGS) -I$(ROOT) $<

imphint.o: imphint.cpp
	$(CC) -c $(CFLAGS) $<

import.o: import.cpp
	$(CC) -c $(CFLAGS) $<

inifile.o: inifile.cpp
	$(CC) -c $(CFLAGS) $<

init.o: init.cpp
	$(CC) -c $(CFLAGS) $<

inline.o: inline.cpp
	$(CC) -c $(CFLAGS) $<

interpret.o: interpret.cpp ctfe.h
	$(CC) -c $(CFLAGS) $<

intrange.o: intrange.h intrange.cpp
	$(CC) -c $(CFLAGS) intrange.cpp

json.o: json.cpp
	$(CC) -c $(CFLAGS) $<

lexer.o: lexer.cpp
	$(CC) -c $(CFLAGS) $<

libelf.o: libelf.cpp $C/melf.h
	$(CC) -c $(CFLAGS) -I$C $<

libmach.o: libmach.cpp $C/mach.h
	$(CC) -c $(CFLAGS) -I$C $<

libmscoff.o: libmscoff.cpp $C/mscoff.h
	$(CC) -c $(CFLAGS) -I$C $<

link.o: link.cpp
	$(CC) -c $(CFLAGS) $<

machobj.o: $C/machobj.cpp
	$(CC) -c $(MFLAGS) -I. $<

macro.o: macro.cpp
	$(CC) -c $(CFLAGS) $<

man.o: $(ROOT)/man.cpp
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

mangle.o: mangle.cpp
	$(CC) -c $(CFLAGS) $<

mars.o: mars.cpp
	$(CC) -c $(CFLAGS) $<

rmem.o: $(ROOT)/rmem.cpp
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

module.o: module.cpp
	$(CC) -c $(CFLAGS) -I$C $<

mscoffobj.o: $C/mscoffobj.cpp $C/mscoff.h
	$(CC) -c $(MFLAGS) $<

msc.o: msc.cpp $(CH) mars.h
	$(CC) -c $(MFLAGS) $<

mtype.o: mtype.cpp
	$(CC) -c $(CFLAGS) $<

nteh.o: $C/nteh.cpp $C/rtlsym.h
	$(CC) -c $(MFLAGS) $<

opover.o: opover.cpp
	$(CC) -c $(CFLAGS) $<

optimize.o: optimize.cpp
	$(CC) -c $(CFLAGS) $<

os.o: $C/os.cpp
	$(CC) -c $(MFLAGS) $<

out.o: $C/out.cpp
	$(CC) -c $(MFLAGS) $<

outbuf.o: $C/outbuf.cpp $C/outbuf.h
	$(CC) -c $(MFLAGS) $<

parse.o: parse.cpp
	$(CC) -c $(CFLAGS) $<

pdata.o: $C/pdata.cpp
	$(CC) -c $(MFLAGS) $<

ph.o: ph.cpp
	$(CC) -c $(MFLAGS) $<

platform_stub.o: $C/platform_stub.cpp
	$(CC) -c $(MFLAGS) $<

port.o: $(ROOT)/port.cpp
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

ptrntab.o: $C/ptrntab.cpp $C/iasm.h
	$(CC) -c $(MFLAGS) $<

response.o: $(ROOT)/response.cpp
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

root.o: $(ROOT)/root.cpp
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

rtlsym.o: $C/rtlsym.cpp $C/rtlsym.h
	$(CC) -c $(MFLAGS) $<

s2ir.o: s2ir.cpp $C/rtlsym.h statement.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

scope.o: scope.cpp
	$(CC) -c $(CFLAGS) $<

sideeffect.o: sideeffect.cpp
	$(CC) -c $(CFLAGS) $<

speller.o: $(ROOT)/speller.cpp
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

statement.o: statement.cpp
	$(CC) -c $(CFLAGS) $<

staticassert.o: staticassert.cpp staticassert.h
	$(CC) -c $(CFLAGS) $<

stringtable.o: $(ROOT)/stringtable.cpp
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

strtold.o: $C/strtold.cpp
	$(CC) -c -I$(ROOT) $<

struct.o: struct.cpp
	$(CC) -c $(CFLAGS) $<

template.o: template.cpp
	$(CC) -c $(CFLAGS) $<

ti_achar.o: $C/ti_achar.cpp $C/tinfo.h
	$(CC) -c $(MFLAGS) -I. $<

ti_pvoid.o: $C/ti_pvoid.cpp $C/tinfo.h
	$(CC) -c $(MFLAGS) -I. $<

tk.o: tk.cpp
	$(CC) -c $(MFLAGS) $<

tocsym.o: tocsym.cpp $(CH) mars.h module.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

toctype.o: toctype.cpp $(CH) $C/rtlsym.h mars.h module.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

todt.o: todt.cpp mtype.h expression.h $C/dt.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

toelfdebug.o: toelfdebug.cpp $(CH) mars.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

toir.o: toir.cpp $C/rtlsym.h expression.h toir.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

toobj.o: toobj.cpp $(CH) mars.h module.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

traits.o: traits.cpp
	$(CC) -c $(CFLAGS) $<

type.o: $C/type.cpp
	$(CC) -c $(MFLAGS) $<

typinf.o: typinf.cpp $(CH) mars.h module.h mtype.h
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

util.o: util.cpp
	$(CC) -c $(MFLAGS) $<

utf.o: utf.cpp utf.h
	$(CC) -c $(CFLAGS) $<

unittests.o: unittests.cpp
	$(CC) -c $(CFLAGS) $<

var.o: $C/var.cpp optab.cpp
	$(CC) -c $(MFLAGS) -I. $<

version.o: version.cpp
	$(CC) -c $(CFLAGS) $<

######################################################

gcov:
	gcov access.cpp
	gcov aliasthis.cpp
	gcov apply.cpp
	gcov arrayop.cpp
	gcov attrib.cpp
	gcov builtin.cpp
	gcov canthrow.cpp
	gcov cast.cpp
	gcov class.cpp
	gcov clone.cpp
	gcov cond.cpp
	gcov constfold.cpp
	gcov declaration.cpp
	gcov delegatize.cpp
	gcov doc.cpp
	gcov dsymbol.cpp
	gcov dump.cpp
	gcov e2ir.cpp
	gcov eh.cpp
	gcov entity.cpp
	gcov enum.cpp
	gcov expression.cpp
	gcov func.cpp
	gcov glue.cpp
	gcov iasm.cpp
	gcov identifier.cpp
	gcov imphint.cpp
	gcov import.cpp
	gcov inifile.cpp
	gcov init.cpp
	gcov inline.cpp
	gcov interpret.cpp
	gcov ctfeexpr.cpp
	gcov irstate.cpp
	gcov json.cpp
	gcov lexer.cpp
ifeq (OSX,$(TARGET))
	gcov libmach.cpp
else
	gcov libelf.cpp
endif
	gcov link.cpp
	gcov macro.cpp
	gcov mangle.cpp
	gcov mars.cpp
	gcov module.cpp
	gcov msc.cpp
	gcov mtype.cpp
	gcov opover.cpp
	gcov optimize.cpp
	gcov parse.cpp
	gcov ph.cpp
	gcov scope.cpp
	gcov sideeffect.cpp
	gcov statement.cpp
	gcov staticassert.cpp
	gcov s2ir.cpp
	gcov struct.cpp
	gcov template.cpp
	gcov tk.cpp
	gcov tocsym.cpp
	gcov todt.cpp
	gcov toobj.cpp
	gcov toctype.cpp
	gcov toelfdebug.cpp
	gcov typinf.cpp
	gcov utf.cpp
	gcov util.cpp
	gcov version.cpp
	gcov intrange.cpp

#	gcov hdrgen.cpp
#	gcov tocvdebug.cpp

######################################################

zip:
	-rm -f dmdsrc.zip
	zip dmdsrc $(SRC)
