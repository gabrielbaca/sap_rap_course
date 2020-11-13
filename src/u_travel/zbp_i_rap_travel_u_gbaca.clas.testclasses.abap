*"* use this source file for your ABAP unit test classes
class ltcl_integration_test definition final for testing
     duration short
     risk level harmless.

  private section.

    class-data:
     cds_test_environment type ref to if_cds_test_environment.

    class-methods:
      class_setup,
      class_teardown.
    methods:
      setup,
      teardown.
    methods:
      create_travel for testing raising cx_static_check.
endclass.


class ltcl_integration_test implementation.

  method create_travel.

    data(today) = cl_abap_context_info=>get_system_date( ).
    data travels_in type table for create zi_rap_travel_u_gbaca\\travel.

    travels_in = value #(     ( agencyid      = 070001   "Agency 070001 does exist, Agency 1 does not exist
                              customerid    = 1
                              begindate     = today
                              enddate       = today + 30
                              bookingfee    = 30
                              totalprice    = 330
                              currencycode  = 'EUR'
                              description   = |Test travel XYZ|
                             ) ).

    modify entities of zi_rap_travel_u_gbaca
      entity travel
         create fields (    agencyid
                            customerid
                            begindate
                            enddate
                            bookingfee
                            totalprice
                            currencycode
                            description
                            status )
           with travels_in
      mapped   data(mapped)
      failed   data(failed)
      reported data(reported).

    cl_abap_unit_assert=>assert_initial( failed-travel ).
    cl_abap_unit_assert=>assert_initial( reported-travel ).
    commit entities.

    data(new_travel_id) = mapped-travel[ 1 ]-travelid.

    select * from zi_rap_travel_u_gbaca where travelid = @new_travel_id into table @data(lt_travel)  .

    cl_abap_unit_assert=>assert_not_initial( lt_travel ).

    cl_abap_unit_assert=>assert_not_initial(
         value #( lt_travel[  travelid = new_travel_id ] optional )
       ).
    cl_abap_unit_assert=>assert_equals(
        exp = 'N'
        act = lt_travel[ travelid = new_travel_id ]-status
      ).
  endmethod.

  method class_setup.
    cds_test_environment = cl_cds_test_environment=>create_for_multiple_cds(
        i_for_entities = value #( ( i_for_entity = 'zi_rap_travel_u_gbaca' )
                                ( i_for_entity = 'zi_rap_booking_u_gbaca' ) )
                              ).
  endmethod.

  method class_teardown.
    cds_test_environment->destroy( ).
  endmethod.

  method setup.
  endmethod.

  method teardown.
    rollback entities.
    cds_test_environment->clear_doubles( ).
  endmethod.

endclass.
