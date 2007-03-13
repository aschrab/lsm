/*
 * File: lsmcheck.c
 * Purpose: Program to check correctness of LSM entries
 * Description: This program contains the main program for lsmcheck, which checks
 *	the correctness of a set of Linux Software Map entries.  Most of the
 *	program consists of routines from the Publib lsm modules (part of
 *	liw-modules); you should consult those for a complete understanding.
 * Author: Lars Wirzenius
 * ID: "@(#)lsmcheck:$Id: lsmcheck.c,v 1.2 1996/02/24 08:22:37 liw Exp $"
 */

#include <stdio.h>
#include <stdlib.h>
#include <publib.h>

static int silent_mode = 0;

static void print_entry(lsm_entry *e) {
	char *p;
	int i;
	
	for (i = 0; (p = lsm_get_line(e, i)) != NULL; ++i)
		printf("%2d: %s\n", i+1, p);
}
		

int check_file(FILE *f) {
	lsm_entry e;
	long lineno;
	char *p;
	int ret, any_correct, any_incorrect;
	
	lsm_init_entry(&e);
	lineno = 0;
	any_correct = 0;
	any_incorrect = 0;
	while ((ret = lsm_read_entry(f, &lineno, &e)) > 0) {
		if (lsm_check_entry(&e) == -1) {
			printf("The following entry has errors:\n\n");
			print_entry(&e);
			printf("\n");
			printf("(first number below, if any, is the line number\n");
			printf("as given in the listing above)\n");
			while ((p = lsm_error()) != NULL)
				printf("error: %s\n", p);
			printf("\n\n\n");
			any_incorrect = 1;
		} else {
			if (!silent_mode) {
				printf("The following entry looks correct:\n\n");
				print_entry(&e);
				printf("\n\n\n");
			}
			any_correct = 1;
		}
		lsm_clear_entry(&e);
	}
	
	if (any_correct && !silent_mode) {
		printf("Correct entries will be added to the database.\n");
		if (!any_incorrect) {
			printf("\n");
			printf("(With compliments from the LSM Robot.)\n");
		}
	}
	if (any_incorrect) {
		printf("Incorrect entries will NOT be added to the database;\n");
		printf("please fix the problems and send them again.  If you\n");
		printf("can't figure out how to fix the problem, please send\n");
		printf("e-mail to the Linux Software Map maintainer, liw@iki.fi\n");
		printf("\n");
		printf("Thank you.\n");
		ret = -1;
	}
	
	if (!any_correct && !any_incorrect) {
		printf("The input did not contain any entries.\n");
		printf("Remember to put a line consisting of `Begin3' (no white space\n");
		printf("and the 3 is important) immediately before the first\n");
		printf("line of the entry, and a line consisting of `End'\n");
		printf("immediately after the last line of the entry.\n");
		printf("\n");
		printf("If you sent something that has `Begin2' instead of `Begin3'\n");
		printf("then you're probably using an old format for the entries.\n");
		printf("Please upgrade to the newer format.\n");
		ret = -1;
	}
	
	return ret;
}


int main(int argc, char **argv) {
	int i, exitcode;
	FILE *f;

	exitcode = EXIT_SUCCESS;

	if (argc > 1 && strcmp(argv[1], "-s") == 0) {
		silent_mode = 1;
		--argc;
		++argv;
	}
	
	if (argc <= 1) {
		if (check_file(stdin) == -1)
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
				if (check_file(f) == -1 || ferror(f))
					exitcode = EXIT_FAILURE;
				if (fclose(f) == EOF)
					exitcode = EXIT_FAILURE;
			}
		}
	}
	return exitcode;
}
