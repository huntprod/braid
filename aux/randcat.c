/*
   This file is part of braid <https://huntprod.com/s/braid>
   Copyright 2018 Hunt Productions, Inc.

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the
   "Software"), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to permit
   persons to whom the Software is furnished to do so, subject to the
   following conditions:

   The above copyright notice and this permission notice shall be included
   in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
   NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
   OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
   USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/*
   randcat - Like cat(1) with random sleeps and bursts.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <fcntl.h>
#include <time.h>

static int
parse_range(const char *s, int *min, int *max)
{
	int *cur = min;

	cur = min;
	for (; *s; s++) {
		switch (*s) {
		default: return -1;
		case ':':
			if (cur == max) return -1;
			cur = max;
			break;
		case '0': case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			*cur = *cur * 10 + (*s - '0');
			break;
		}
	}

	return 0;
}

static int
randn(int min, int max) {
	if (min == max) return min;
	return min + (int)(rand() * 1.0 / RAND_MAX * (max - min));
}

/* USAGE: cat [-D] [-b N[:M]] [-s N[:M]] [file] */
int main(int argc, char **argv)
{
	int debug, fd, idx;
	const char *file;
	char *buf;
	int bmin, bmax, smin, smax;

	debug = 0;
	bmin = 1024; bmax = 2048;
	smin = 100;  smax = 400;  /* ms */
	file = NULL;

	for (idx = 1; idx < argc; idx++) {
		if (!argv[idx]) continue;

		switch (argv[idx][0]) {
		case '-':
			if(argv[idx][2] != '\0') {
				fprintf(stderr, "Unrecognized flag %s\n", argv[idx]);
				exit(2);
			}

			switch (argv[idx][1]) {
			default:
				fprintf(stderr, "Unrecognized flag %s\n", argv[idx]);
				exit(1);

			case 'D':
				debug = 1;
				break;

			case 'b':
				idx++;
				if (idx == argc) {
					fprintf(stderr, "Flag '-b' requires a value.\n");
					exit(1);
				}
				bmin = bmax = 0;
				if (parse_range(argv[idx], &bmin, &bmax) != 0) {
					fprintf(stderr, "Non-numeric value given to -b flag.\n");
					exit(2);
				}
				break;

			case 's':
				idx++;
				if (idx == argc) {
					fprintf(stderr, "Flag '-s' requires a value.\n");
					exit(1);
				}
				smin = smax = 0;
				if (parse_range(argv[idx], &smin, &smax) != 0) {
					fprintf(stderr, "Non-numeric value given to -s flag.\n");
					exit(2);
				}
				break;

			case '-': break;
			case 'h':
				fprintf(stderr, "Usage: %s [-D] [-b N[:M]] [-s N[:M]] [FILE]\n", argv[0]);
				fprintf(stderr, "\n");
				fprintf(stderr, "  -h  Print this help screen and exit.\n");
				fprintf(stderr, "  -D  Enable debugging mode.\n");
				fprintf(stderr, "\n");
				fprintf(stderr, "  -b  How many octets (bytes) to be read per cycle.\n");
				fprintf(stderr, "      If only a single number is given, that is always\n");
				fprintf(stderr, "      used.  If a range (i.e. 100:200) is given, a random\n");
				fprintf(stderr, "      value between those points is chosen every time.\n");
				fprintf(stderr, "\n");
				fprintf(stderr, "  -s  How many milliseconds to sleep per cycle.\n");
				fprintf(stderr, "      If only a single number is given, that is always\n");
				fprintf(stderr, "      used.  If a range (i.e. 100:200) is given, a random\n");
				fprintf(stderr, "      value between those points is chosen every time.\n");
				fprintf(stderr, "\n");
				exit(0);
			}
			break;

		default:
			if (file) {
				fprintf(stderr, "Too many files provided.\n");
				exit(2);
			}
			file = argv[idx];
		}
	}

	if (bmin == 0) bmin = 1;
	if (bmax == 0) bmax = bmin;
	if (smin == 0) smin = 100;
	if (smax == 0) smax = smin;

	fd = 0;
	if (file) {
		fd = open(file, O_RDONLY);
		if (fd < 0) {
			fprintf(stderr, "%s: %s\n", file, strerror(errno));
			exit(4);
		}
	}

	if (debug) {
		fprintf(stderr, "DEBUG: bmin = %d, bmax = %d\n", bmin, bmax);
		fprintf(stderr, "DEBUG: smin = %d, smax = %d\n", smin, smax);
	}

	buf = malloc(sizeof(char) * bmax);
	for (;;) {
		int want; struct timespec nap;
		ssize_t n, nread, nwrit;

		want = randn(bmin, bmax);
		if (debug) {
			fprintf(stderr, "DEBUG: chose (randomly) to read %d octets\n", want);
		}
		nread = read(fd, buf, want);
		if (nread == 0) break;

		for (n = 0; n < nread; ) {
			nwrit = write(1, buf+n, nread-n);
			if (nwrit < 0) {
				fprintf(stderr, "write failed\n");
				exit(3);
			}
			n += nwrit;
		}

		want = randn(smin, smax);
		if (debug) {
			fprintf(stderr, "DEBUG: chose (randomly) to sleep %d milliseconds\n", want);
		}
		nap.tv_sec  = want / 1000;
		nap.tv_nsec = (want % 1000) * 1000 * 1000;
		nanosleep(&nap, NULL);
	}

	close(fd);
	return 0;
}
