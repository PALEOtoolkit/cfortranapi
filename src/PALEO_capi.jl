"""
  PALEO.jl C API

  This is a Julia initialisation script that is loaded from C.
  Overall approach:

  - activate an environment and import PALEO.jl modules.
  
  - use @cfunction to define C-callable functions (and associated type mapping) in Julia,
    see eg package by Gunnar Farneback <https://github.com/GunnarFarneback/DynamicallyLoadedEmbedding.jl>
    This is currently (2020-12-20) not the approach described in the Julia manual (which does type mapping in C), 
    although there is an open issue <https://github.com/JuliaLang/julia/issues/38932> and several blog posts advocating 
    this approach, eg by Steven G. Johnson
    <https://scicomp.stackexchange.com/questions/23194/i-am-searching-for-a-c-code-implementing-the-complex-polygamma-function/23733#23733>
    <https://julialang.org/blog/2013/05/callback/>
"""

import Pkg

Pkg.activate(@__DIR__)  # activate environment defined by Project.toml in the folder containing this script (the cfortranapi folder)

import PALEOboxes as PB

# import Infiltrator # Julia debugger

# temporary for testing: include test module
include(joinpath(dirname(dirname(pathof(PB))), "test/ReactionPaleoMockModule.jl"))

################################
# Define C callable functions 
#################################

const C_SUCCESS = Cint(1)
const C_FAILURE = Cint(0)


###################
# global variables
###################

# singleton instances
themodel = nothing
themodeldata = nothing
# holder to prevent garbage collection for references handed back to C 
refs = IdDict()

##################################
# C callable function for Model.jl
##################################

"create model and set themodel singleton.
 Using pointer_from_objref / unsafe_pointer_to_objref would provide a way of returning an opaque
 pointer to C, would still then need to store a reference on the Julia side to prevent garbage collection"
function create_global_model_from_config(config_file_c::Cstring, configmodel_c::Cstring)
    config_file = unsafe_string(config_file_c)
    configmodel = unsafe_string(configmodel_c)
    ret::Cint = C_SUCCESS
    try
        global themodel = PB.create_model_from_config(config_file, configmodel)
    catch e
        println("Exception ", e)
        ret = C_FAILURE
    end
    return ret
end
const create_global_model_from_config_c = @cfunction(create_global_model_from_config, Cint, (Cstring, Cstring))

function get_domain(name_c::Cstring)::Ptr{Cvoid}
    name = unsafe_string(name_c)

    domain_c =Ptr{Cvoid}(0)
    try
        domain = PB.get_domain(themodel, name)
        if !isnothing(domain)
            domain_c = pointer_from_objref(domain)
        end
    catch e
        println("Exception ", e)       
    end
    return domain_c
end
const get_domain_c = @cfunction(get_domain, Ptr{Cvoid}, (Cstring, ))



function create_modeldata()::Cint
    ret = C_SUCCESS
    try
        global themodeldata = PB.create_modeldata(themodel::PB.Model)
    catch e
        println("Exception ", e)
        ret = C_FAILURE
    end
    return ret
end
const create_modeldata_c = @cfunction(create_modeldata, Cint, ())

function allocate_variables(hostdep::Cint)::Cint
    ret = C_SUCCESS
    try
        PB.allocate_variables!(themodel::PB.Model, themodeldata::PB.ModelData, hostdep=Bool(hostdep))
    catch e
        println("Exception ", e)
        ret = C_FAILURE
    end
    return ret
end
const allocate_variables_c = @cfunction(allocate_variables, Cint, (Cint,))

function check_ready()::Cint
    ret = C_SUCCESS
    try
        if !PB.check_ready(themodel::PB.Model, themodeldata::PB.ModelData, check_hostdep_varnames=false, throw_on_error=false)
            ret = C_FAILURE
        end
    catch e
        println("Exception ", e)
        ret = C_FAILURE
    end
    return ret
end
const check_ready_c = @cfunction(check_ready, Cint, ())

function check_configuration()::Cint
    ret = C_SUCCESS
    try
        if !PB.check_configuration(themodel::PB.Model, throw_on_error=false)
            ret = C_FAILURE
        end
    catch e
        println("Exception ", e)
        ret = C_FAILURE
    end
    return ret
end
const check_configuration_c = @cfunction(check_configuration, Cint, ())

function initialize_reactiondata()::Cint
    ret = C_SUCCESS
    try
        PB.initialize_reactiondata!(themodel::PB.Model, themodeldata::PB.ModelData)
    catch e
        println("Exception ", e)
        ret = C_FAILURE
    end
    return ret
end
const initialize_reactiondata_c = @cfunction(initialize_reactiondata, Cint, ())

function dispatch_setup()::Cint
    ret = C_SUCCESS    
    # cellranges = unsafe_pointer_to_objref(cellrange_list_c)
    try
        model = themodel::PB.Model
        modeldata = themodeldata::PB.ModelData
        
        # PB.dispatch_setup(model::PB.Model, :norm_value, modeldata)
        # PB.copy_norm!(modeldata.solver_view_all)
        # Initialise state variables etc     
        PB.dispatch_setup(model, :initial_value, modeldata)
    catch e
        println("Exception ", e)
        ret = C_FAILURE
    end
    return ret
end
const dispatch_setup_c = @cfunction(dispatch_setup, Cint, ())

function create_dispatch_methodlists(cellrange_list_c::Ptr{Cvoid})::Ptr{Cvoid}
    dispatchlists_c =Ptr{Cvoid}(0)
    cellranges = unsafe_pointer_to_objref(cellrange_list_c)
    try
        # wrap NamedTuple in a Ref as it is immutable hence can't be returned as pointer_from_objref
        dispatchlists = Ref(PB.create_dispatch_methodlists(themodel::PB.Model, themodeldata::PB.ModelData, cellranges))
        global refs[dispatchlists] = dispatchlists  # keep a reference to prevent garbage collection
        dispatchlists_c = pointer_from_objref(dispatchlists)
    catch e
        println("Exception ", e)       
    end
    return dispatchlists_c
end
const create_dispatch_methodlists_c = @cfunction(create_dispatch_methodlists, Ptr{Cvoid}, (Ptr{Cvoid}, ))

function do_deriv(dispatchlists_c::Ptr{Cvoid}, deltat::Cdouble)::Cint
    ret = C_SUCCESS
    dispatchlists = unsafe_pointer_to_objref(dispatchlists_c)
    try
        PB.do_deriv(dispatchlists[], deltat)
    catch e
        println("Exception ", e)
        ret = C_FAILURE
    end
    return ret
end
const do_deriv_c = @cfunction(do_deriv, Cint, (Ptr{Cvoid}, Cdouble))

############################
# CellRange.jl
############################

"return opaque pointer to a single (default) CellRange for one Domain"
function create_default_cellrange(domain_c::Ptr{Cvoid})::Ptr{Cvoid}
    domain = unsafe_pointer_to_objref(domain_c)::PB.Domain
    cellrange_c =Ptr{Cvoid}(0)
    try
        cellrange = PB.Grids.create_default_cellrange(domain, domain.grid)
        if !isnothing(cellrange)
            global refs[cellrange] = cellrange  # keep a reference to prevent garbage collection
            cellrange_c = pointer_from_objref(cellrange)
        end
    catch e
        println("Exception ", e)       
    end
    return cellrange_c
end
const create_default_cellrange_c = @cfunction(create_default_cellrange, Ptr{Cvoid}, (Ptr{Cvoid}, ))

"return opaque reference to a Julia Vector of CellRange objects, supplied as a C array of opaque pointers"
function create_cellrange_list(cellranges_c::Ptr{Ptr{Cvoid}}, cellranges_len::Cint)::Ptr{Cvoid}
    cellrange_ptrs = unsafe_wrap(Vector{Ptr{Cvoid}}, cellranges_c, cellranges_len, own=false)
    cellrange_list = [unsafe_pointer_to_objref(cellrange_c) for cellrange_c in cellrange_ptrs]
    global refs[cellrange_list] = cellrange_list
    cellrange_list_c = pointer_from_objref(cellrange_list)
end
const create_cellrange_list_c = @cfunction(create_cellrange_list, Ptr{Cvoid}, (Ptr{Ptr{Cvoid}}, Cint))

##########################
# Domain.jl
##########################

function get_variable(domain_c::Ptr{Cvoid}, name_c::Cstring)::Ptr{Cvoid}
    name = unsafe_string(name_c)
    domain = unsafe_pointer_to_objref(domain_c)::PB.Domain
    var_c =Ptr{Cvoid}(0)
    try
        var = PB.get_variable(domain, name)
        if !isnothing(var)
            var_c = pointer_from_objref(var)
        end
    catch e
        println("Exception ", e)       
    end
    return var_c
end
const get_variable_c = @cfunction(get_variable, Ptr{Cvoid}, (Ptr{Cvoid}, Cstring))

#####################################
# VariableDomain.jl
#####################################

function set_data(variable_c::Ptr{Cvoid}, data_c::Ptr{T}, data_size::Ptr{Cint}, data_ndim::Cint)::Cint where T
    variable = unsafe_pointer_to_objref(variable_c)::PB.VariableDomain
    println("set_data var=", variable, "  Domain=", variable.domain)
    size = unsafe_wrap(Vector{Cint}, data_size, data_ndim, own=false)
    println("set_data size=", size, "  ", typeof(size))
    data = unsafe_wrap(Array{T}, data_c, Tuple(size), own=false)
    println("set_data data=", data, "  ", typeof(data))

    ret = C_SUCCESS
    try
        PB.set_data!(variable, themodeldata::PB.ModelData, data)
    catch e
        println("Exception ", e)
        ret = C_FAILURE
    end

    return ret
end
const set_data_c = @cfunction(set_data, Cint, (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cint}, Cint))

function get_data(variable_c::Ptr{Cvoid}, data_c::Ptr{Ptr{T}}, data_size::Ptr{Cint}, data_ndim::Ptr{Cint})::Cint where T
    variable = unsafe_pointer_to_objref(variable_c)::PB.VariableDomain
  
    ret = C_SUCCESS
    try
        data = PB.get_data(variable, themodeldata::PB.ModelData)
        unsafe_store!(data_c, pointer(data))
        size_vec = unsafe_wrap(Vector{Cint}, data_size, ndims(data), own=false)
        size_vec .= size(data)
        unsafe_store!(data_ndim, ndims(data))
    catch e
        println("Exception ", e)
        ret = C_FAILURE
    end
    return ret
end
const get_data_c = @cfunction(get_data, Cint, (Ptr{Cvoid}, Ptr{Ptr{Cdouble}}, Ptr{Cint}, Ptr{Cint}))

#########################################
# Test functions for Julia - C interop
#######################################

function test42()
    return 42.0
end
const test42_c = @cfunction(test42, Cdouble, () )

"wrap a C char* in a a Julia String"
function test_string(teststr_c::Cstring)::Cint
    teststr = unsafe_string(teststr_c)
    println("test_string: '$teststr'")
    ret::Cint = length(teststr)
    return ret
end
const test_string_c = @cfunction(test_string, Cint, (Cstring, ))

"wrap a C pointer in a Julia array"
function test_array_fromc(parray_c::Ptr{T}, array_len::Cint)::Cint where T
    println("test_array_fromc: ", typeof(parray_c), "  array_len ", array_len)

    array = unsafe_wrap(Vector{T}, parray_c, array_len, own=false)

    fill!(array, 42.0)

    return C_SUCCESS
end
const test_array_fromc_c = @cfunction(test_array_fromc, Cint, (Ptr{Cdouble}, Cint ))

test_array=[1.0, 2.0, 3.0, 4.0]

"return raw C pointer and length from a Julia array"
function test_array_fromjulia(parray_c, array_len)::Cint
    println("test_array_fromjulia: ", typeof(parray_c), "  array_len ", typeof(array_len))

    unsafe_store!(parray_c, pointer(test_array))
    unsafe_store!(array_len, length(test_array))

    return C_SUCCESS
end
const test_array_fromjulia_c = @cfunction(test_array_fromjulia, Cint, (Ptr{Ptr{Cdouble}}, Ptr{Cint} ))
