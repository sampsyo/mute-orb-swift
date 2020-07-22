SOURCES := main.swift blutil.swift orb.swift

mute-orb: $(SOURCES)
	swiftc $^ -o $@
