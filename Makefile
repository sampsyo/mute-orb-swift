SOURCES := main.swift blutil.swift

mute-orb: $(SOURCES)
	swiftc $^ -o $@
