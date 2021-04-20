# Quick steps to measure the performance of CDS:
#
# make run0   = no CDS (-Xshare:off)
# make run1   = default CDS archive
# make runs   = static CDS archive
# make rund   = dynamic CDS archive
#
# Example timing (with my JDK 17 personal build/20210420)
#
# run0:    1.702895430 seconds time elapsed                                          ( +-  0.48% )
# run1:    1.573997668 seconds time elapsed                                          ( +-  0.26% )
# runs:    1.478010901 seconds time elapsed                                          ( +-  0.52% )
# rund:    1.397676981 seconds time elapsed                                          ( +-  0.62% )

JAVA = $(TESTBED)/bin/java

CMDLINE = -jar target/cds-example-0.0.1-SNAPSHOT.jar


classlist:
	$(JAVA) -XX:DumpLoadedClassList=classlist ${CMDLINE}

base.jsa:
	rm -f base.map
	$(JAVA) -Xshare:dump -XX:SharedArchiveFile=base.jsa -Xlog:cds+map=debug:file=base.map:none:filesize=0
	grep '@@ Class' base.map | sed -e 's/.* [0-9]* //g' | sort > base.cls

static.jsa: classlist
	rm -f static.map
	$(JAVA) -Xshare:dump -XX:SharedClassListFile=classlist -XX:SharedArchiveFile=static.jsa -Xlog:cds+map=debug:file=static.map:none:filesize=0 ${CMDLINE}
	grep '@@ Class' static.map | sed -e 's/.* [0-9]* //g' | sort > static.cls

# Same as statis.jsa, but use ExtraSharedClassListFile instead of SharedClassListFile
static_e.jsa: classlist
	rm -f static_e.map
	$(JAVA) -Xshare:dump -XX:ExtraSharedClassListFile=classlist -XX:SharedArchiveFile=static_e.jsa -Xlog:cds+map=debug:file=static_e.map:none:filesize=0 ${CMDLINE}
	grep '@@ Class' static_e.map | sed -e 's/.* [0-9]* //g' | sort > static_e.cls

dynamic.jsa:
	rm -f dynamic.map
	$(JAVA) -XX:ArchiveClassesAtExit=dynamic.jsa -Xlog:cds+map=debug:file=dynamic.map:none:filesize=0 ${CMDLINE}
	grep '@@ Class' dynamic.map | sed -e 's/.* [0-9]* //g' | sort > dynamic.cls
	uniq < dynamic.cls > dynamic.cls.u

clean:
	rm -f classlist *.jsa *~ *.map *.map.* *.cls *.cls.u

run0:
	perf stat -r 10 $(JAVA) -Xshare:off ${CMDLINE}

run1:
	perf stat -r 10 $(JAVA) -Xshare:on ${CMDLINE}

runs: static.jsa
	perf stat -r 10 $(JAVA) -Xshare:on -XX:SharedArchiveFile=static.jsa ${CMDLINE}

runse: static_e.jsa
	perf stat -r 10 $(JAVA) -Xshare:on -XX:SharedArchiveFile=static_e.jsa ${CMDLINE}

rund: dynamic.jsa
	perf stat -r 10 $(JAVA) -Xshare:on -XX:SharedArchiveFile=dynamic.jsa ${CMDLINE}