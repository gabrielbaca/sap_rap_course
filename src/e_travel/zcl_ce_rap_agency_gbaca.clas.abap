class zcl_ce_rap_agency_gbaca definition
  public
  final
  create public .

  public section.
    interfaces if_oo_adt_classrun.
    interfaces if_rap_query_provider.

    types t_agency_range type range of zz_travel_agency_es5_gbaca-agencyid.
    types t_business_data type table of zz_travel_agency_es5_gbaca.

    methods get_agencies
      importing
        filter_cond        type if_rap_query_filter=>tt_name_range_pairs   optional
        top                type i optional
        skip               type i optional
        is_data_requested  type abap_bool
        is_count_requested type abap_bool
      exporting
        business_data      type t_business_data
        count              type int8
      raising
        /iwbep/cx_cp_remote
        /iwbep/cx_gateway
        cx_web_http_client_error
        cx_http_dest_provider_error
      .

  protected section.
  private section.
endclass.



class zcl_ce_rap_agency_gbaca implementation.

  method if_oo_adt_classrun~main.

    data business_data type t_business_data.
    data count type int8.
    data filter_conditions  type if_rap_query_filter=>tt_name_range_pairs .
    data ranges_table type if_rap_query_filter=>tt_range_option .
    ranges_table = value #( (  sign = 'I' option = 'GE' low = '070015' ) ).
    filter_conditions = value #( ( name = 'AGENCYID'  range = ranges_table ) ).

    try.
        get_agencies(
          exporting
            filter_cond        = filter_conditions
            top                = 3
            skip               = 1
            is_count_requested = abap_true
            is_data_requested  = abap_true
          importing
            business_data  = business_data
            count          = count
          ) .
        out->write( |Total number of records = { count }| ) .
        out->write( business_data ).
      catch cx_root into data(exception).
        out->write( cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ) ).
    endtry.


  endmethod.

  method get_agencies.

    data: filter_factory   type ref to /iwbep/if_cp_filter_factory,
          filter_node      type ref to /iwbep/if_cp_filter_node,
          root_filter_node type ref to /iwbep/if_cp_filter_node.

    data: http_client        type ref to if_web_http_client,
          odata_client_proxy type ref to /iwbep/if_cp_client_proxy,
          read_list_request  type ref to /iwbep/if_cp_request_read_list,
          read_list_response type ref to /iwbep/if_cp_response_read_lst.

    data service_consumption_name type cl_web_odata_client_factory=>ty_service_definition_name.

    data(http_destination) = cl_http_destination_provider=>create_by_url( i_url = 'https://sapes5.sapdevcenter.com' ).
    http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = http_destination ).

    service_consumption_name = to_upper( 'ZSC_RAP_AGENCY_GBACA' ).

    odata_client_proxy = cl_web_odata_client_factory=>create_v2_remote_proxy(
      exporting
        iv_service_definition_name = service_consumption_name
        io_http_client             = http_client
        iv_relative_service_root   = '/sap/opu/odata/sap/ZAGENCYCDS_SRV/' ).

    " Navigate to the resource and create a request for the read operation
    read_list_request = odata_client_proxy->create_resource_for_entity_set( 'Z_TRAVEL_AGENCY_ES5' )->create_request_for_read( ).

    " Create the filter tree
    filter_factory = read_list_request->create_filter_factory( ).
    loop at  filter_cond  into data(filter_condition).
      filter_node  = filter_factory->create_by_range( iv_property_path     = filter_condition-name
                                                              it_range     = filter_condition-range ).
      if root_filter_node is initial.
        root_filter_node = filter_node.
      else.
        root_filter_node = root_filter_node->and( filter_node ).
      endif.
    endloop.

    if root_filter_node is not initial.
      read_list_request->set_filter( root_filter_node ).
    endif.

    if is_data_requested = abap_true.
      read_list_request->set_skip( skip ).
      if top > 0 .
        read_list_request->set_top( top ).
      endif.
    endif.

    if is_count_requested = abap_true.
      read_list_request->request_count( ).
    endif.

    if is_data_requested = abap_false.
      read_list_request->request_no_business_data( ).
    endif.

    " Execute the request and retrieve the business data and count if requested
    read_list_response = read_list_request->execute( ).
    if is_data_requested = abap_true.
      read_list_response->get_business_data( importing et_business_data = business_data ).
    endif.
    if is_count_requested = abap_true.
      count = read_list_response->get_count( ).
    endif.

  endmethod.


  method if_rap_query_provider~select.
    data business_data type t_business_data.
    data(top)     = io_request->get_paging( )->get_page_size( ).
    data(skip)    = io_request->get_paging( )->get_offset( ).
    data(requested_fields)  = io_request->get_requested_elements( ).
    data(sort_order)    = io_request->get_sort_elements( ).
    data count type int8.
    try.
        data(filter_condition) = io_request->get_filter( )->get_as_ranges( ).

        get_agencies(
                 exporting
                   filter_cond        = filter_condition
                   top                = conv i( top )
                   skip               = conv i( skip )
                   is_data_requested  = io_request->is_data_requested( )
                   is_count_requested = io_request->is_total_numb_of_rec_requested(  )
                 importing
                   business_data  = business_data
                   count     = count
                 ) .

        if io_request->is_total_numb_of_rec_requested(  ).
          io_response->set_total_number_of_records( count ).
        endif.
        if io_request->is_data_requested(  ).
          io_response->set_data( business_data ).
        endif.

      catch cx_root into data(exception).
        data(exception_message) = cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ).
    endtry.
  endmethod.

endclass.
