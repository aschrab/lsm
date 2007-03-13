/*
 * File: lsmextract.c
 * Purpose: Program to extract LSM entries from input
 * Description: This program contains the main program for lsmextract,
 *	which finds and extracts entries from the standard input.
 * Author: Lars Wirzenius
 * ID: "@(#)lsmcheck:$Id: lsmextract.c,v 1.1.1.1 1996/01/07 21:55:16 liw Exp $"
 */

#include <stdio.h>
#include <stdlib.h>
#include <publib.h>

int main(int argc, char **argv) {
	lsm_entry e;
	long lineno;
	char *p;
	int i;

	lsm_init_entry(&e);
	lineno = 0;
	while (lsm_read_entry(stdin, &lineno, &e) > 0) {
		if (lineno > 0)
			printf("\n\n");
		printf("Begin3\n");
		for (i = 0; (p = lsm_get_line(&e, i)) != NULL; ++i)
			printf("%s\n", p);
		printf("End\n");
		lsm_clear_entry(&e);
	}
	
	return 0;
}
