/*
 * File: lsmfmt.c
 * Purpose: Program to format LSM entries
 * Description: This program contains the main program for lsmfmt, which reads
 *	LSM entries and formats them for nicer output.
 * Author: Lars Wirzenius
 * ID: "@(#)lsmcheck:$Id: lsmfmt.c,v 1.1.1.1 1996/01/07 21:55:16 liw Exp $"
 */

#include <stdio.h>
#include <stdlib.h>
#include <publib.h>

static void print_formatted(char **tab, int n) {
	while (--n >= 0)
		printf("%s\n", (tab++)[0]);
}


int format_file(FILE *f) {
	lsm_entry e;
	long lineno;
	int n, ret;
	char *tab[1024];
	const int maxtab = sizeof(tab)/sizeof(*tab);
	
	lsm_init_entry(&e);
	lineno = 0;
	while ((ret = lsm_read_entry(f, &lineno, &e)) > 0) {
		if ((n = lsm_format_entry(&e, tab, maxtab, 16, 75)) == -1)
			return -1;
		print_formatted(tab, n);
		lsm_clear_entry(&e);
	}
	
	return ret;
}


int main(int argc, char **argv) {
	int i, exitcode;
	FILE *f;

	exitcode = EXIT_SUCCESS;
	
	if (argc <= 1) {
		if (format_file(stdin) == -1)
			exitcode = EXIT_FAILURE;
	} else {
		for (i = 1; i < argc; ++i) {
			if (argc > 2) {
				if (i > 1)
					printf("\n\n---------------------------------\n\n");
				printf("Processing file %s.\n\n\n", argv[i]);
			}
			f = fopen(argv[i], "r");
			if (f == NULL) {
				perror(argv[i]);
				exitcode = EXIT_FAILURE;
			} else {
				if (format_file(f) == -1 || ferror(f))
					exitcode = EXIT_FAILURE;
				if (fclose(f) == EOF)
					exitcode = EXIT_FAILURE;
			}
		}
	}
	return exitcode;
}