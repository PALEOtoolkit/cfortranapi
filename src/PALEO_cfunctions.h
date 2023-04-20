#ifndef _PALEO_CFUNCTIONS_H_
#define _PALEO_CFUNCTIONS_H_

/* Note, these declarations are function pointers. They can still be
 * called like regular functions without dereferencing.
 */

#ifdef DEFINE_VARIABLES
#define EXTERN /* nothing */
#else
#define EXTERN extern
#endif /* DEFINE_VARIABLES */

/* Model.jl */
EXTERN int     (*create_global_model_from_config)(const char* const config_file, const char* const configmodel);
EXTERN void*   (*get_domain)(const char* const name);
EXTERN int     (*create_modeldata)();
EXTERN int     (*allocate_variables)(int hostdep);
EXTERN int     (*check_ready)();
EXTERN int     (*check_configuration)();
EXTERN int     (*initialize_reactiondata)();
EXTERN int     (*dispatch_setup)();
EXTERN void*   (*create_dispatch_methodlists)(void* cellrange_list);
EXTERN int     (*do_deriv)(void* dispatchlists, double deltat);

/* Domain.jl */
EXTERN void*   (*get_variable)(void* domain, const char* const name);

/* VariableDomain.jl */
EXTERN int     (*set_data)(void* variable, double* data, int* data_size, int data_ndim);
EXTERN int     (*get_data)(void* variable, double** data, int* data_size, int* data_ndim);

/* CellRange.jl */
EXTERN void*   (*create_default_cellrange)(void* domain);
EXTERN void*   (*create_cellrange_list)(void** cellranges, int cellranges_length);


/* Test functions for C - Julia interop */
EXTERN double  (*test42)();
EXTERN int     (*test_string)(const char* const str);
EXTERN int     (*test_array_fromc)(double *const array, int array_length);
EXTERN int     (*test_array_fromjulia)(double ** array, int* array_length);

/* Loads the function pointers above. */
int load_paleo_cfunctions(void);

#endif
