#ifndef _PALEO_CFUNCTIONS_H_
#define _PALEO_CFUNCTIONS_H_

/* Note, these declarations are function pointers. They can still be
 * called like regular functions without dereferencing.
 */

/* Model.jl */
int     (*create_global_model_from_config)(const char* const config_file, const char* const configmodel);
void*   (*get_domain)(const char* const name);
int     (*create_modeldata)();
int     (*allocate_variables)(int hostdep);
int     (*check_ready)();
int     (*check_configuration)();
int     (*initialize_reactiondata)();
int     (*dispatch_setup)();
void*   (*create_dispatch_methodlists)(void* cellrange_list);
int     (*do_deriv)(void* dispatchlists, double deltat);

/* Domain.jl */
void*   (*get_variable)(void* domain, const char* const name);

/* VariableDomain.jl */
int     (*set_data)(void* variable, double* data, int* data_size, int data_ndim);
int     (*get_data)(void* variable, double** data, int* data_size, int* data_ndim);

/* CellRange.jl */
void*   (*create_default_cellrange)(void* domain);
void*   (*create_cellrange_list)(void** cellranges, int cellranges_length);


/* Test functions for C - Julia interop */
double  (*test42)();
int     (*test_string)(const char* const str);
int     (*test_array_fromc)(double *const array, int array_length);
int     (*test_array_fromjulia)(double ** array, int* array_length);

/* Loads the function pointers above. */
int load_paleo_cfunctions(void);

#endif
