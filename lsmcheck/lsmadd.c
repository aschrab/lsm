/*
 * File: lsmadd.c
 * Purpose: Program to add new entries to an LSM database
 * Description: This program contains the main program for lsmadd, which adds
 *	new entries to an LSM database.  It reads the database from stdin,
 *	the new entries from one or more named files on the command line,
 *	and outputs the updated database to stdout, and appends old entries to
 *	a file called LSM.old.
 * Author: Lars Wirzenius
 * ID: "@(#)lsmcheck:$Id: lsmadd.c,v 1.1 1996/04/08 21:30:13 liw Exp $"
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <publib.h>

static char *field(const lsm_entry *e, const char *name) {
	int i, n;
	char *p;
	
	n = strlen(name);
	for (i = 0; (p = lsm_get_line(e,i)) != NULL; ++i)
		if (strncmp(p, name, n) == 0 && p[n] == ':')
			return p;
	return NULL;
}

static char *title(const lsm_entry *e) {
	char *p;
	p = field(e, "Title");
	if (p == NULL)
		p = "";
	return p;
}

static unsigned long date(const lsm_entry *e) {
	char *p, months[] = "JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC";
	char temp[4];
	int dd, mm, yy;

	p = field(e, "Entered-date");
	if (p == NULL)
		return 0;
	p = strchr(p, ':');
	if (p == NULL)
		return 0;
	do {
		++p;
	} while (isspace(*p));
	if (strlen(p) < 7)
		return 0;
	dd = 10 * (p[0]-'0') + (p[1]-'0');
	yy = 10 * (p[5]-'0') + (p[6]-'0');
	if (dd < 1 || dd > 31 || yy < 0 || yy > 99)
		return 0;

	temp[0] = toupper(p[2]);
	temp[1] = toupper(p[3]);
	temp[2] = toupper(p[4]);
	temp[3] = '\0';
	p = strstr(months, temp);
	if (p == NULL)
		return 0;
	mm = (p-months)/3;
	
	return 366UL*yy + 31UL*mm + dd;
}

static int compare_titles(const void *a, const void *b) {
	return strcmp(title(a), title(b));
}

static int compare_dates(const void *a, const void *b) {
	unsigned long aa, bb;
	aa = date(a);
	bb = date(b);
	if (aa < bb)
		return -1;
	if (aa > bb)
		return 1;
	return 0;
}

static int read_database(FILE *f, struct dynarr *da) {
	int ret;
	lsm_entry e;
	long lineno;

	lineno = 0;
	for (;;) {
		lsm_init_entry(&e);
		ret = lsm_read_entry(f, &lineno, &e);
		if (ret <= 0)
			break;
		if (dynarr_resize(da, da->used+1) == -1)
			return -1;
		((lsm_entry *) da->data) [da->used] = e;
		++da->used;
	}
	qsort(da->data, da->used, sizeof(e), compare_titles);
	return ret;
}

static int write_database(FILE *f, struct dynarr *da) {
	int i;

	for (i = 0; i < da->used; ++i) {
		if (lsm_write_entry(f, ((lsm_entry *) da->data) + i) == -1)
			return -1;
		if (fprintf(f, "\n\n\n") < 0)
			return -1;
	}
	return 0;
}

static int insert(struct dynarr *lsm, lsm_entry *e) {
	if (dynarr_resize(lsm, lsm->used+1) == -1)
		return -1;
	memisort(lsm->data, lsm->used, sizeof(*e), e, compare_titles);
	++lsm->used;
	return 0;
}

static int add(struct dynarr *lsm, struct dynarr *lsm_old, lsm_entry *e) {
	lsm_entry *p;
	p = bsearch(e, lsm->data, lsm->used, sizeof(*e), compare_titles);
	if (p == NULL)
		return insert(lsm, e);
	if (compare_dates(e, p) < 0)
		return insert(lsm_old, e);
	if (insert(lsm_old, p) == -1)
		return -1;
	*p = *e;
	return 0;
}

int main(int argc, char **argv) {
	struct dynarr lsm, lsm_old;
	long lineno;
	int i, ret;
	FILE *f;
	lsm_entry e;
	
	dynarr_init(&lsm, sizeof(lsm_entry));
	dynarr_init(&lsm_old, sizeof(lsm_entry));

	if (read_database(stdin, &lsm) == -1)
		errormsg(1, -1, "Error reading database from stdin");

	for (i = 1; i < argc; ++i) {
		f = xfopen(argv[i], "r");
		lineno = 0;
		for (;;) {
			lsm_init_entry(&e);
			ret = lsm_read_entry(f, &lineno, &e);
			if (ret <= 0)
				break;
			if (add(&lsm, &lsm_old, &e) == -1)
				errormsg(1, -1, "Out of memory?\n");
		}
		if (ret == -1)
			errormsg(1, -1, 
				"Error reading entry from %s (line %ld)",
				argv[i], lineno);
		xfclose(f);
	}
	
	f = xfopen("LSM.old", "a");
	if (write_database(f, &lsm_old) == -1)
		errormsg(1, -1, "Error writing old entries to LSM.old");
	xfclose(f);

	if (write_database(stdout, &lsm) == -1)
		errormsg(1, -1, "Error writing new database stdout");

	return 0;
}
