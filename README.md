# cfortranapi

Proof-of-concept API for embedding a PALEO biogeochemical model in a C/Fortran host model.

## C/Fortran API test code
Test code for a C and Fortran API is in `cfortranapi/src`.  This demonstrates embedding in a C or Fortran host program.  The Julia shared library (libjulia.so on linux) needs to be available at runtime, eg by setting the `LD_LIBRARY_PATH` environment variable. 

To build and run the test programs (from a linux bash shell using gcc and gfortran, the Makefile will need updating for other platforms):

    > cd src
    > make
    > which julia    # libjulia.so will be in ./lib next to ./bin
    /data/sd336/software/julia/julia-1.7.2/bin/julia
    > export LD_LIBRARY_PATH=/data/sd336/software/julia/julia-1.7.2/lib
    > ./test_PALEO_C
    > ./test_PALEO_F

The test programs demonstrate initialising a simple PALEO model (defined in `src/configbase.yaml`), setting array references, and calling the main loop do_ methods from C and Fortran.   A complete API would need to extend this to allow the host to set more complex Domain configurations and provide query methods for available state Variables etc to enable more complex Reaction and Variable configurations.

## C/Fortran API implementation 

The C API uses the Julia @cfunction macro to define C-callable functions (and associated type mapping) in Julia (in `src/PALEO_capi.jl`), following the approach of the package <https://github.com/GunnarFarneback/DynamicallyLoadedEmbedding.jl>.
    
This is much simpler than the approach currently (2020-12-20) described in the Julia manual (which does the type mapping in C), although there is an open issue <https://github.com/JuliaLang/julia/issues/38932> advocating this approach.

The Fortran API then uses the Fortran 2003 ISO C interoperability calls to provide a standards-based and portable implementation.