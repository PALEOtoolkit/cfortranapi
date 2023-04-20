#include "julia_embedding.h"

#define DEFINE_VARIABLES
#include "PALEO_cfunctions.h"

int load_paleo_cfunctions()
{
    int success = 1;

    /* Model.jl */
    create_global_model_from_config = get_cfunction_pointer("create_global_model_from_config_c", &success);
    get_domain                      = get_cfunction_pointer("get_domain_c", &success);
    create_modeldata                = get_cfunction_pointer("create_modeldata_c", &success);
    allocate_variables              = get_cfunction_pointer("allocate_variables_c", &success);
    check_ready                     = get_cfunction_pointer("check_ready_c", &success);
    check_configuration             = get_cfunction_pointer("check_configuration_c", &success);
    initialize_reactiondata         = get_cfunction_pointer("initialize_reactiondata_c", &success);
    dispatch_setup                  = get_cfunction_pointer("dispatch_setup_c", &success);
    create_dispatch_methodlists     = get_cfunction_pointer("create_dispatch_methodlists_c", &success);
    do_deriv                        = get_cfunction_pointer("do_deriv_c", &success);

    /* Domain.jl */
    get_variable                    = get_cfunction_pointer("get_variable_c", &success);

    /* VariableDomain.jl */
    set_data                        = get_cfunction_pointer("set_data_c", &success);
    get_data                        = get_cfunction_pointer("get_data_c", &success);

    /* CellRange.jl */    
    create_default_cellrange        = get_cfunction_pointer("create_default_cellrange_c", &success);
    create_cellrange_list           = get_cfunction_pointer("create_cellrange_list_c", &success);

    /* test functions for C - Julia interop */
    test42                          = get_cfunction_pointer("test42_c", &success);    
    test_string                     = get_cfunction_pointer("test_string_c", &success);
    test_array_fromc                = get_cfunction_pointer("test_array_fromc_c", &success);
    test_array_fromjulia            = get_cfunction_pointer("test_array_fromjulia_c", &success);

    return success;
}

/* 'Normal' externally-linkable versions of each function (as eg Fortran API requires a 'normal' 
    function to link against, not a function pointer) */

/* Model.jl */
int     ext_create_global_model_from_config(const char* const config_file, const char* const configmodel) { 
    return create_global_model_from_config(config_file, configmodel); }
void*   ext_get_domain(const char* const name) { return get_domain(name); }
int     ext_create_modeldata() { return create_modeldata(); }
int     ext_allocate_variables(int hostdep) { return allocate_variables(hostdep); }
int     ext_check_ready() { return check_ready(); }
int     ext_check_configuration() { return check_configuration(); }
int     ext_initialize_reactiondata(){ return initialize_reactiondata(); }
int     ext_dispatch_setup(){ return dispatch_setup(); }
void*   ext_create_dispatch_methodlists(void* cellrange_list){ return create_dispatch_methodlists(cellrange_list); }
int     ext_do_deriv(void* dispatchlists, double deltat) { return do_deriv(dispatchlists, deltat);}

/* Domain.jl */
void*   ext_get_variable(void* domain, const char* const name){ return get_variable(domain, name);}

/* VariableDomain.jl */
int     ext_set_data(void* variable, double* data, int* data_size, int data_ndim){return set_data(variable, data, data_size, data_ndim);}
int     ext_get_data(void* variable, double** data, int* data_size, int* data_ndim){ return get_data(variable, data, data_size, data_ndim);}

/* CellRange.jl */
void*   ext_create_default_cellrange(void* domain){return create_default_cellrange(domain);}
void*   ext_create_cellrange_list(void** cellranges, int cellranges_length){
    return create_cellrange_list(cellranges, cellranges_length);}

/* Test functions for C - Julia interop */
double  ext_test42(){ return test42(); }
int     ext_test_string(const char* const str){ return test_string(str);}
int     ext_test_array_fromc(double *const array, int array_length) {return test_array_fromc(array, array_length);}
int     ext_test_array_fromjulia(double ** array, int* array_length){ return test_array_fromjulia(array, array_length);}


