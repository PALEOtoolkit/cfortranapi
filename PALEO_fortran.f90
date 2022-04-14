module PALEO_fortran

use, intrinsic :: iso_c_binding

implicit none

private

! Initialize Julia and Fortran API
public :: julia_preinitialize, julia_initialize, julia_eval_string, julia_exit
public :: load_paleo_cfunctions
! Model.jl
public :: create_global_model_from_config, get_domain, create_modeldata, & 
    & allocate_variables, check_ready, check_configuration, initialize_reactiondata, dispatch_setup, &
    & create_dispatch_methodlists, do_deriv
! Domain.jl
public :: get_variable
! VariableDomain.jl
public :: set_data, get_data
! CellRange
public :: create_default_cellrange, create_cellrange_list

! test functions
public :: test42, test_array_fromf, test_array_fromjulia

interface
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! PALEO julia initialization and shutdown
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! wrapper function required
    function julia_preinitialize_c() result(version_cstr) bind(C, name='julia_preinitialize')
        use, intrinsic :: iso_c_binding
        type(c_ptr) :: version_cstr
    end function julia_preinitialize_c

    function julia_initialize(julia_system_image_path_str) result(success) bind(C, name='julia_initialize')
        use, intrinsic :: iso_c_binding
        character(kind=c_char), intent(in) :: julia_system_image_path_str(*)
        integer(c_int) :: success
    end function julia_initialize

    function julia_eval_string(command, error_message) result(success) bind(C, name='julia_eval_string')
        use, intrinsic :: iso_c_binding
        character(kind=c_char), intent(in) :: command(*), error_message(*)
        integer(c_int) :: success
    end function julia_eval_string

    function load_paleo_cfunctions() result(success) bind(C, name='load_paleo_cfunctions')
        use, intrinsic :: iso_c_binding
        integer(c_int) :: success
    end function load_paleo_cfunctions

    function julia_exit(exit_code_in) result(exit_code_out) bind(C, name='julia_exit')
        use, intrinsic :: iso_c_binding
        integer(c_int) :: exit_code_in, exit_code_out
    end function julia_exit
end interface

interface
    !!!!!!!!!!!!!!!!!!!!!!
    ! Model.jl
    !!!!!!!!!!!!!!!!!!!!!!
    function create_global_model_from_config(config_file, configmodel) result(success) &
        & bind(C, name='ext_create_global_model_from_config')
        use, intrinsic :: iso_c_binding
        character(kind=c_char), intent(in) :: config_file(*), configmodel(*)
        integer(c_int) :: success
    end function create_global_model_from_config

    function get_domain(name) result(domain) bind(C, name='ext_get_domain')
        use, intrinsic :: iso_c_binding
        character(kind=c_char), intent(in) :: name(*)
        type(c_ptr) :: domain    
    end function get_domain

    function create_modeldata() result(success) bind(C, name='ext_create_modeldata')
        use, intrinsic :: iso_c_binding
        integer(c_int) :: success
    end function create_modeldata

    ! wrapper function required
    function ext_allocate_variables(hostdep) result(success) bind(C, name='ext_allocate_variables')
        use, intrinsic :: iso_c_binding
        integer(c_int), value, intent(in) :: hostdep
        integer(c_int) :: success
    end function ext_allocate_variables

    function check_ready() result(success) bind(C, name='ext_check_ready')
        use, intrinsic :: iso_c_binding
        integer(c_int) :: success
    end function check_ready

    function check_configuration() result(success) bind(C, name='ext_check_configuration')
        use, intrinsic :: iso_c_binding
        integer(c_int) :: success
    end function check_configuration

    function initialize_reactiondata() result(success) bind(C, name='ext_initialize_reactiondata')
        use, intrinsic :: iso_c_binding
        integer(c_int) :: success
    end function initialize_reactiondata

    function dispatch_setup() result(success) bind(C, name='ext_dispatch_setup')
        use, intrinsic :: iso_c_binding
        integer(c_int) :: success
    end function dispatch_setup

    function create_dispatch_methodlists(cellrange_list) result(dispatch_lists) &
        & bind(C, name='ext_create_dispatch_methodlists')
        use, intrinsic :: iso_c_binding
        type(c_ptr), value, intent(in) :: cellrange_list
        type(c_ptr) :: dispatch_lists
    end function create_dispatch_methodlists

    function do_deriv(dispatch_lists, deltat) result(success) bind(C, name='ext_do_deriv')
        use, intrinsic :: iso_c_binding
        type(c_ptr), value, intent(in) :: dispatch_lists
        real(c_double), value, intent(in) :: deltat
        integer(c_int) :: success
    end function do_deriv
end interface

interface
    !!!!!!!!!!!!!!!!!!!!
    ! Domain.jl
    !!!!!!!!!!!!!!!!!!!!!
 
    function get_variable(domain, name) result(variable) bind(C, name='ext_get_variable')
        use, intrinsic :: iso_c_binding
        type(c_ptr), value, intent(in) :: domain 
        character(kind=c_char), intent(in) :: name(*)
        type(c_ptr) :: variable
    end function get_variable
end interface

interface
    !!!!!!!!!!!!!!!!!!!!!
    ! VariableDomain.jl
    !!!!!!!!!!!!!!!!!!!!!!
    ! wrapper function required
    function ext_set_data(variable, data_ptr, data_size, data_ndim) result(success) bind(C, name='ext_set_data')
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), value, intent(in) :: variable
        integer(c_int), intent(in), value :: data_ndim
        integer(c_int), intent(in), dimension(data_ndim) :: data_size
        type(c_ptr), value, intent(in) :: data_ptr
        integer(c_int) :: success
    end function ext_set_data

    ! wrapper function required
    function ext_get_data(variable, data_ptr, data_size, data_ndim) result(success) bind(C, name='ext_get_data')
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), value, intent(in) :: variable
        type(c_ptr), intent(out) :: data_ptr
        integer(c_int), intent(out) :: data_ndim
        integer(c_int), intent(out) :: data_size(*)
        integer(c_int) :: success
    end function ext_get_data
end interface

interface set_data
    module procedure set_data1D, set_data2D, set_data3D
end interface

interface get_data
    module procedure get_data1D, get_data2D, get_data3D
end interface

interface
    !!!!!!!!!!!!!!!!!!!!!!
    ! CellRange.jl
    !!!!!!!!!!!!!!!!!!!!!
    function create_default_cellrange(domain) result(cellrange) bind(C, name='ext_create_default_cellrange')
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), value, intent(in) :: domain
        type(c_ptr) :: cellrange
    end function create_default_cellrange

    ! wrapper function required
    function ext_create_cellrange_list(cellranges, cellranges_length) result(cellrange_list) &
        & bind(C, name='ext_create_cellrange_list')
        use, intrinsic :: iso_c_binding
        implicit none
        integer(c_int), intent(in), value :: cellranges_length
        type(c_ptr), intent(in), dimension(cellranges_length) :: cellranges
        type(c_ptr) :: cellrange_list
    end function ext_create_cellrange_list
end interface

interface
    !!!!!!!!!!!!!!!!!
    ! Test functions
    !!!!!!!!!!!!!!!!
    function test42()  bind(C, name='ext_test42') 
        ! Interface blocks don't know about their context,
        ! so we need to use iso_c_binding to get c_int definition
        use, intrinsic :: iso_c_binding
        implicit none
        real(c_double) :: test42
    end function test42

    ! wrapper function required
    function ext_test_array_fromc(array, array_length) result(success) bind(C, name='ext_test_array_fromc') 
        ! Interface blocks don't know about their context,
        ! so we need to use iso_c_binding to get c_int definition
        use, intrinsic :: iso_c_binding
        implicit none
        integer(c_int) :: success
        integer(c_int), intent(in), value :: array_length
        real(c_double), intent(in), dimension(array_length) :: array
    end function ext_test_array_fromc

    ! wrapper function required
    function ext_test_array_fromjulia(array_ptr, array_length) result(success) bind(C, name='ext_test_array_fromjulia')
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), intent(out) :: array_ptr
        integer(c_int), intent(out) :: array_length
        integer(c_int) :: success
    end function ext_test_array_fromjulia
end interface

interface
    !!!!!!!!!!!!!!!!!!!!!!!!!!
    ! C utility functions
    !!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Interface to C strlen
    ! see eg http://fortranwiki.org/fortran/show/c_interface_module
    ! Fortran doesn't appear to have a way to say C_char_ptr
    function C_strlen(C_string_ptr) result(length) bind(C, name='strlen')
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), value, intent(in) :: C_string_ptr
        integer(c_size_t) :: length
    end function C_strlen 
end interface

contains

    ! see eg http://fortranwiki.org/fortran/show/c_interface_module
    ! convert a null-terminated C string C_string (as a c_ptr) to a fortran string F_string
    ! returns empty string if C_string is a null pointer
    function c_to_f_string(C_string_ptr) result(F_string)
        implicit none   
        character(len=:),allocatable                        :: F_string
        type(c_ptr), intent(in)                             :: C_string_ptr
        character(len=1,kind=c_char), dimension(:), pointer :: p_chars
        integer(c_size_t)                                   :: length, i
    
        if (.not. c_associated(C_string_ptr)) then
            F_string = ''
        else
            length = C_strlen(C_string_ptr) ! get string length
            call c_f_pointer(C_string_ptr, p_chars, [length])
            allocate(character(len=length) :: F_string)
            forall (i=1:length)
                F_string(i:i) = p_chars(i)
            end forall
        end if
        
    end function c_to_f_string

    function julia_preinitialize() result(version_str)
        implicit none
        !! wrapper to C function char *julia_preinitialize(void)
    
        character(len=:),allocatable :: version_str
    
        version_str = c_to_f_string(julia_preinitialize_c())
    
    end function julia_preinitialize
    
    !! wrapper to provide hostdep as optional logical argument, default .false.
    function allocate_variables(hostdep_opt) result(success)
        use, intrinsic :: iso_c_binding
        implicit none
        logical, intent(in), optional :: hostdep_opt
        logical :: hostdep
        integer(c_int) :: success

        if (present(hostdep_opt)) then
            hostdep = hostdep_opt
        else
            hostdep = .false. ! default value
        end if

        success = ext_allocate_variables(merge(1, 0, hostdep))
    end function allocate_variables

    function set_data1D(variable, array) result(success)
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), value, intent(in) :: variable
        real(c_double), intent(in), dimension(:), target :: array
        integer(c_int) :: success

        success = ext_set_data(variable, c_loc(array), shape(array), 1)
    end function set_data1D

    function set_data2D(variable, array) result(success)
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), value, intent(in) :: variable
        real(c_double), intent(in), dimension(:, :), target :: array
        integer(c_int) :: success

        success = ext_set_data(variable, c_loc(array), shape(array), 2)
    end function set_data2D

    function set_data3D(variable, array) result(success)
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), value, intent(in) :: variable
        real(c_double), intent(in), dimension(:, :, :), target :: array
        integer(c_int) :: success

        success = ext_set_data(variable, c_loc(array), shape(array), 3)
    end function set_data3D

    function get_data1D(variable, array) result(success)
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), value, intent(in) :: variable
        real(c_double), pointer, dimension(:) :: array
        type(c_ptr) :: data_ptr
        integer(c_int) :: array_shape(3) ! shape for max likely ndim
        integer(c_int) :: array_ndim
        integer(c_int) :: success

        success = ext_get_data(variable, data_ptr, array_shape, array_ndim)
        if (array_ndim .ne. 1) then
            write(*,*) 'get_data1D: ndim ', array_ndim, ' != 1'
            success = 0
        end if
        if (success .gt. 0) then
            call c_f_pointer(data_ptr, array, array_shape(1:1))
        end if
    end function get_data1D

    function get_data2D(variable, array) result(success)
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), value, intent(in) :: variable
        real(c_double), pointer, dimension(:, :) :: array
        type(c_ptr) :: data_ptr
        integer(c_int) :: array_shape(3) ! shape for max likely ndim
        integer(c_int) :: array_ndim
        integer(c_int) :: success

        success = ext_get_data(variable, data_ptr, array_shape, array_ndim)
        if (array_ndim .ne. 2) then
            write(*,*) 'get_data2D: ndim ', array_ndim, ' != 2'
            success = 0
        end if
        if (success .gt. 0) then
            call c_f_pointer(data_ptr, array, array_shape(1:2))
        end if
    end function get_data2D

    function get_data3D(variable, array) result(success)
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), value, intent(in) :: variable
        real(c_double), pointer, dimension(:, :, :) :: array
        type(c_ptr) :: data_ptr
        integer(c_int) :: array_shape(3) ! shape for max likely ndim
        integer(c_int) :: array_ndim
        integer(c_int) :: success

        success = ext_get_data(variable, data_ptr, array_shape, array_ndim)
        if (array_ndim .ne. 3) then
            write(*,*) 'get_data3D: ndim ', array_ndim, ' != 3'
            success = 0
        end if
        if (success .gt. 0) then
            call c_f_pointer(data_ptr, array, array_shape(1:3))
        end if
    end function get_data3D


    function create_cellrange_list(cellranges) result(cellrange_list)
        use, intrinsic :: iso_c_binding
        implicit none
        type(c_ptr), intent(in), dimension(:) :: cellranges
        type(c_ptr) :: cellrange_list
        cellrange_list = ext_create_cellrange_list(cellranges, size(cellranges))
    end function create_cellrange_list

    function test_array_fromf(array) result(success)
        implicit none
        integer(c_int) :: success
        real(c_double), intent(in), dimension(:) :: array
        success = ext_test_array_fromc(array, size(array))
    end function test_array_fromf

    function test_array_fromjulia(array) result(success)
        implicit none
        integer(c_int) :: success
        real(c_double), pointer, dimension(:) :: array
        type(c_ptr) :: array_ptr
        integer(c_int) :: array_length

        success = ext_test_array_fromjulia(array_ptr, array_length)
        call c_f_pointer(array_ptr, array, [array_length])

    end function test_array_fromjulia

  end module PALEO_fortran