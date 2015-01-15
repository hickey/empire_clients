/* $Id: highlight.c,v 2.9.3.1 1997/06/08 20:09:50 root Exp root $
 *
 *                     highlight.c
 *
 *               Based on print.c by Doug Hay
 *
 *                 Written by Ken Stevens
 *                 21 June 95
 * 
 * DESCRIPTION
 * This C program suppliments pei to let pei do highlighting (required by
 * the "sect" command).  You can get highlighting in pei by piping the
 * output of a highlit command to this program.
 *
 * INSTALLATION
 * 1. Type "make".  (You shouldn't need to edit the "Makefile" file.)
 * 2. Add the following alias to your ~/.peirc file:
 *   alias sect "sect $+ | $PEIPATH/highlight"
 *
 * HOW TO RUN IT
 * The "sect" command should now work properly in pei.
 * If, however, the highlight output doesn't look quite right, try one
 * or both of the following two fixes:
 *
 * FIX 1:
 * Uncomment the following define: */
/* #define CURSES_HIGH */
/*
 * FIX 2:
 * In the file "Makefile", change the line:
 *   LIBS = -ltermcap
 * to:
 *   LIBS = -lcurses
 */

/* BUG REPORTS:
 * mail your bug-reports and comments to:
 * Sam Tetherow <tetherow@nol.org>
 */

/*******************************************************
 *  Copyright (C) Doug Hay, 1989,90,91.
 *  Permission to use and abuse this code, as long
 *  as this copyright notice stays intact and with the
 *  code.  No warranty implied.  This code supplied as is.
 *******************************************************/

#include <stdio.h>

static char *Terminal_SO, *Terminal_SE;

static void terminit();

/*******************************************
 * stripprint
 *
 * Strip any EMPIRE hilighting bits from the
 * string, then print it to passed file.
 */
    static void
stripprint(str)
    char *str;
{
    char *cp=str;

    while (*cp) *cp++ &= 0x7f;
    puts(str);
}

/*******************************************
 * hiprint
 *
 * Find any characters in passed string with EMPIRE
 * highlighting bits set, and hilight those characters.
 */
    static void
hiprint(str)
    char *str;
{
  char *cp;
  int  hav_hi = 0;

  for (cp=str; *cp; cp++) {
    if (*cp & 0x80) hav_hi = 1;
  }

  if (!hav_hi || !Terminal_SO || !Terminal_SE || !*Terminal_SO
      || !*Terminal_SE) {
    if (hav_hi)
      for (cp=str; *cp; cp++) *cp &= 0x7f;
    printf("%s", str);
  } else {
    for (cp=str; *cp;) {
      if (*cp & 0x80) {
	printf("%s", Terminal_SO);
	for ( ; (*cp & 0x80 && putchar(*cp & 0x7f)); cp++);
	printf("%s", Terminal_SE);
      } else
	putchar(*cp++);
    }
  }
  putchar('\n');
}

void main(argc, argv)
int argc;
char *argv[];
{
  char buf[800];

  terminit();

  if (argc > 1) {
    while (!feof(stdin)) {
      if (gets(buf)) {
	stripprint(buf);
      }
    }
  } else {
    while (!feof(stdin)) {
      if (gets(buf)) {
	hiprint(buf);
      }
    }
  }
}

/*******************************************
 * terminit
 *
 * Go find the highlighting strings for the terminal.
 */

    static void
terminit()
{
    char *getenv(), *tgetstr();
    char *cp, *term;
    static char nullstring[2];
    static char termbuf[1024];
    static char data[1024];
    static char *area;

    area = data;
    Terminal_SO = Terminal_SE = nullstring;

    term = getenv("TERM");
    if (!term) {
	fprintf(stderr, "Unable to get TERM environment variable.\n");
	return;
    }

    if (tgetent(termbuf, term) == -1) {
	fprintf(stderr, "terminit tgetent failed\n");
	return;
    }

    cp = area;
    if (tgetstr("so", &area) == NULL) {
	fprintf(stderr, "highlight.c terminit, no so\n");
    } else
	Terminal_SO = cp;

    cp = area;
    if (tgetstr("se", &area) == NULL) {
	fprintf(stderr, "highlight.c terminit, no se\n");
    } else
	Terminal_SE = cp;
#ifndef CURSES_HIGH
    ++Terminal_SO;
    ++Terminal_SE;
#endif
}
