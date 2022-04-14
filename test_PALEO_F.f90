program test_PALEO_F

use, intrinsic :: iso_c_binding
use PALEO_fortran

implicit none
character(len=:), allocatable       :: version_string
integer(kind=4)                     :: success, exit_code
real(kind=8)                        :: theanswer
real(kind=8), dimension(3)          :: A = (/1.0, 2.0, 3.0/)
real(kind=8), dimension(:), pointer :: B
type(c_ptr)                         :: domain_ocean
type(c_ptr)                         :: var_scalar_dep, var_mock_phy
real(kind=8), dimension(1)          :: data_scalar_dep = (/42.0/)
type(c_ptr)                         :: domain_ocean_cellrange, cellrange_list, dispatch_lists
real(kind=8), dimension(:,:), pointer :: data_mock_phy

write(*,*) 'test_PALEO_F start'

version_string = julia_preinitialize()
write(*,*) 'Julia version ', version_string

success = julia_initialize(''//C_NULL_CHAR)
write(*,*) 'julia_initialize returned ', success

success = julia_eval_string('include("PALEO_capi.jl")'//C_NULL_CHAR, 'PALEO_capi.jl include failed'//C_NULL_CHAR)
write(*,*) 'julia_eval_string returned ', success

success = load_paleo_cfunctions()
if (success .eq. 0) then
  exit_code = julia_exit(1)
  stop 'load_paleo_cfunctions failed'
end if


theanswer = test42()
write(*,*) 'theanswer=', theanswer

success = test_array_fromf(A)
write(*,*) 'A=', A

success = test_array_fromjulia(B)
write(*,*) 'B=', B

success = create_global_model_from_config('configbase.yaml'//C_NULL_CHAR, 'model_2D'//C_NULL_CHAR)
write(*,*) 'create_global_model_from_config returned ', success

domain_ocean = get_domain('ocean'//C_NULL_CHAR)
write(*,*) 'get_domain returned domain_ocean=', domain_ocean

success = create_modeldata()
write(*,*) 'create_modeldata returned ', success

success = allocate_variables(.false.)
write(*,*) 'allocate_variables returned ', success

success = check_ready()
write(*,*) 'check_ready returned ', success, ' (expect 0 ie failed)'

var_scalar_dep = get_variable(domain_ocean, 'scalar_dep'//C_NULL_CHAR)
write(*,*) 'get_variable returned ', var_scalar_dep

success = set_data(var_scalar_dep, data_scalar_dep)
write(*,*) 'set_data returned ', success

success = check_ready()
write(*,*) 'check_ready returned ', success, ' (expect 1 ie success)'

success = check_configuration();
write(*,*) 'check_configuration returned ', success

success = initialize_reactiondata()
write(*,*) 'initialize_reactiondata returned ', success

domain_ocean_cellrange = create_default_cellrange(domain_ocean)
write(*,*) 'create_cellrange returned ', domain_ocean_cellrange

cellrange_list = create_cellrange_list([domain_ocean_cellrange])
write(*,*) 'create_cellrange_list returned ', cellrange_list

success = dispatch_setup();
write(*,*) 'dispatch_setup returned ', success

dispatch_lists = create_dispatch_methodlists(cellrange_list)
write(*,*) 'create_dispatch_methodlists returned ', dispatch_lists

success = do_deriv(dispatch_lists, 0.0_8) ! use the right kind of zero (_8 means kind=8)
write(*,*) 'do_deriv returned ', success

var_mock_phy = get_variable(domain_ocean, 'mock_phy'//C_NULL_CHAR)
write(*,*) 'get_variable returned ', var_mock_phy

success = get_data(var_mock_phy, data_mock_phy)
write(*,*) 'get_data returned ', success
write(*,*) 'shape(data_mock_phy) ', shape(data_mock_phy)
write(*,*) '(expect 5 2)'
write(*,*) 'data_mock_phy ', data_mock_phy
write(*,*) '(expect 0.15)'
exit_code = julia_exit(0)

end program test_PALEO_F