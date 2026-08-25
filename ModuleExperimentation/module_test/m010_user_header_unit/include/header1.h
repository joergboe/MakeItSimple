#ifndef HEADER1_H_
#define HEADER1_H_

#ifdef MAIN
#warning "header1.h included from main.cpp."
#define VERSION "Main version 2.3.4"
#else
#warning "header1.h included from elswhere."
#define VERSION "2.3.4"
#endif

extern const char another_string[];

const char * greeting();

const char * version();

#endif