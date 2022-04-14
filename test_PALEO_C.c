// This file is a part of PALEOjl. Licence TBD

/**
 * This uses Julia-side mapping of C types (using @cfunction to define c-callable Julia functions).
 * It also uses dynamic loading of Julia, with an API based on:
 *  https://github.com/GunnarFarneback/DynamicallyLoadedEmbedding.jl
 * 
 * See also:
 * https://scicomp.stackexchange.com/questions/23194/i-am-searching-for-a-c-code-implementing-the-complex-polygamma-function/23733#23733
 * https://julialang.org/blog/2013/05/callback/
*/

#include "julia_embedding.h"
#include "PALEO_cfunctions.h"
#include <stdlib.h>
#include <stdio.h>

int main(int argc, const char **argv)
{
    const char *system_image_path = NULL;
    if (argc > 1)
        system_image_path = argv[1];
    
    const char *version_string = julia_preinitialize();
    /* The primary reason for making the version string easily
     * available is that system images are version dependent and this
     * gives an opportunity to find an appropriate custom system
     * image.
     *
     * See https://github.com/JuliaLang/PackageCompiler.jl for making
     * your own system images.
     *
     * If you have no use for the version string,
     * `julia_preinitialize` does not need to be called.
     */
    printf("Julia version %s\n", version_string);

    /* Initialize Julia. Argument is the path of the system
     * image to start Julia with. If this is NULL or an empty string,
     * the default system image is loaded.
     */
    if (!julia_initialize(system_image_path))
        return EXIT_FAILURE;

    // include PALEOc_api.jl  (activates environment, loads modules, defines c callable functions)
    julia_eval_string("include(\"PALEO_capi.jl\")", "PALEO_capi.jl include failed");

    /* Load the `cfunction` pointers defined in
     * `julia_cfunctions.c`/`julia_cfunctions.h`.
     */
    if (!load_paleo_cfunctions()) {
        return julia_exit(EXIT_FAILURE);
    }

    /* Test the Julia `cfunctions`. */
 
    double retDouble = test42();
    printf("test42() returned %e\n", retDouble);
    
    int success = test_string("hello julia");
    printf("test_string returned %i\n", success);

    int cArray_len = 10;
    double *existingArray = (double*)malloc(sizeof(double)*cArray_len);
    success = test_array_fromc(existingArray, cArray_len);
    printf("test_array_fromc returned %i\n", success);
    int i;
    for (i = 0; i < cArray_len; i++) {
        printf("%g ", existingArray[i]);
    }
    printf("\n");

    double *juliaArray;
    int juliaArray_len;
    success = test_array_fromjulia(&juliaArray, &juliaArray_len);
    printf("test_array_fromjulia returned %i\n", success);
    for (i = 0; i < juliaArray_len; i++) {
        printf("%g ", juliaArray[i]);
    }
    printf("\n");
    
    success = create_global_model_from_config("configbase.yaml", "model1");
    printf("create_global_model_from_config returned %i\n", success);

    void* domain_ocean = get_domain("ocean");
    printf("get_domain returned %p\n", domain_ocean);
    int domain_ocean_size = 10; /* ReactionUnstructuredVectorGrid ncells in .yaml file */

    success = create_modeldata();
    printf("create_modeldata returned %i\n", success);

    success = allocate_variables(0);
    printf("allocate_variables returned %i\n", success);

    success = check_ready();
    printf("check_ready returned %i\n", success);

    void* var_scalar_dep = get_variable(domain_ocean, "scalar_dep");
    printf("get_variable returned %p\n", var_scalar_dep);

    double data_scalar_dep = 42.0;
    int scalar_size = 1;
    success = set_data(var_scalar_dep, &data_scalar_dep, &scalar_size, 1);

    success = check_ready();
    printf("check_ready returned %i\n", success);

    success = check_configuration();
    printf("check_configuration returned %i\n", success);

    success = initialize_reactiondata();
    printf("initialize_reactiondata returned %i\n", success);

    void* domain_ocean_cellrange = create_default_cellrange(domain_ocean);
    printf("create_cellrange returned %p\n", domain_ocean_cellrange);

    void* cellrange_list = create_cellrange_list(&domain_ocean_cellrange, 1);
    printf("create_cellrange_list returned %p\n", cellrange_list);

    success = dispatch_setup();
    printf("dispatch_setup returned %i\n", success);

    void* dispatch_lists = create_dispatch_methodlists(cellrange_list);
    printf("create_dispatch_methodlists returned %p\n", dispatch_lists);

    success = do_deriv(dispatch_lists, 0.0);
    printf("do_deriv returned %i\n", success);

    void* var_mock_phy = get_variable(domain_ocean, "mock_phy");
    printf("get_variable returned %p\n", var_scalar_dep);

    double* data_mock_phy;
    int data_mock_phy_size[3];
    int data_mock_phy_ndim;
    success = get_data(var_mock_phy, &data_mock_phy, data_mock_phy_size, &data_mock_phy_ndim);
    printf("get_data returned %i\n", success);
    printf("data_mock_phy_ndim %i size[0] %i\n", data_mock_phy_ndim, data_mock_phy_size[0]);
    success = 1;
    if (data_mock_phy_size[0] != domain_ocean_size) {
        success = 0;
    }
    for (i = 0; i < data_mock_phy_size[0]; i++) {
        printf("%g ", data_mock_phy[i]);
        if (data_mock_phy[i] != 0.15) {
            success = 0;
        }
    }
    printf("\n");

    if (success) {
        printf("PASS\n");
    } else {
        printf("FAIL\n");
    }

    return julia_exit(EXIT_SUCCESS);
}
