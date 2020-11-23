class zcl_rap_eml_gbaca definition
  public
  final
  create public .

  public section.
    interfaces if_oo_adt_classrun.
  protected section.
  private section.
ENDCLASS.



CLASS ZCL_RAP_EML_GBACA IMPLEMENTATION.


  method if_oo_adt_classrun~main.

    "READ key fields
*    read entities of zi_rap_travel_gbaca
*        entity travel
*            from value #( ( traveluuid = '40FB0F50240CB34917000602FBDF465D' ) ) "Travel ID 17
*        result data(travels).


    "READ with fields
*    read entities of zi_rap_travel_gbaca
*        entity travel
*        fields ( AgencyID CustomerID )
*        with value #( ( traveluuid = '40FB0F50240CB34917000602FBDF465D' ) ) "Travel ID 17
*        result data(travels).

    "READ all fields
*    read entities of zi_rap_travel_gbaca
*        entity travel
*        all fields
*        with value #( ( traveluuid = '40FB0F50240CB34917000602FBDF465D' ) ) "Travel ID 17
*        result data(travels).

*    "READ by association
*    read entities of zi_rap_travel_gbaca
*        entity travel by \_Booking
*        all fields
*        with value #( ( traveluuid = '40FB0F50240CB34917000602FBDF465D' ) ) "Travel ID 17
*        result data(travels).

    "READ by association
*    read entities of zi_rap_travel_gbaca
*        entity travel by \_Booking
*        all fields
*        with value #( ( traveluuid = 'DOES_NOT_EXIST' ) ) "Travel ID 17
*        result data(travels)
*        failed data(failed)
*        reported data(reported).
*
*    out->write( travels ).
*    out->write( failed ). "Not supported
*    out->write( reported ). "Not supported

*    "Modify
*    modify entities of zi_rap_travel_gbaca
*    entity travel
*    update
*    set fields with value
*        #( ( traveluuid = '40FB0F50240CB34917000602FBDF465D'
*             description = 'I''m learning RAP@OpenSAP' ) )
*    failed data(failed)
*    reported data(reported).
*
*    out->write( |Update done| ).
*
*    commit entities response of zi_rap_travel_gbaca
*    failed data(failed_commit)
*    reported data(reported_commit).

    "Modify
*    modify entities of zi_rap_travel_gbaca
*    entity travel
*    create
*    set fields with value
*        #( ( %cid = 'MyContentID_1'
*             agencyid = '70012'
*             customerid = '14'
*             begindate = cl_abap_context_info=>get_system_date( )
*             enddate = cl_abap_context_info=>get_system_date( ) + 10
*             description = 'I''m learning RAP@OpenSAP creation' ) )
*    mapped data(mapped)
*    failed data(failed)
*    reported data(reported).
*
*    out->write( mapped-travel ).
*
*    commit entities response of zi_rap_travel_gbaca
*    failed data(failed_commit)
*    reported data(reported_commit).
*
*    out->write( 'Create done' ).

    "Modify delete
    modify entities of zi_rap_travel_gbaca
    entity travel
    delete from
    value
        #( ( TravelUUID = '129FA47496A51EEB87C7659FB7B8D712' ) )
    failed data(failed)
    reported data(reported).

    commit entities response of zi_rap_travel_gbaca
    failed data(failed_commit)
    reported data(reported_commit).

    out->write( 'Delete done' ).
  endmethod.
ENDCLASS.
