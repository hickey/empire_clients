# Makefile for highlight
#

# On most systems, this should work:
# LIBS = -ltermcap
# On some systems, you may need to use this instead:
LIBS = -lcurses

highlight: highlight.c
	$(CC) $(CFLAGS) -o $@ highlight.c $(LIBS)
