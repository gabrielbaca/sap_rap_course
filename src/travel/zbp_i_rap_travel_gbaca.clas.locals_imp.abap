class lhc_travel definition inheriting from cl_abap_behavior_handler.
  private section.
    data: begin of travel_status,
            open      type c length 1 value 'O',
            accepted  type c length 1 value 'A',
            cancelled type c length 1 value 'X',
          end of travel_status.

    methods calculatetotalprice for determine on modify
      importing keys for travel~calculatetotalprice.

    methods calculatetravelid for determine on save
      importing keys for travel~calculatetravelid.

    methods setinitialstatus for determine on modify
      importing keys for travel~setinitialstatus.

    methods validateagency for validate on save
      importing keys for travel~validateagency.

    methods validatecustomer for validate on save
      importing keys for travel~validatecustomer.

    methods validatedates for validate on save
      importing keys for travel~validatedates.

    methods accepttravel for modify
      importing keys for action travel~accepttravel result result.

    methods rejecttravel for modify
      importing keys for action travel~rejecttravel result result.

    methods recalculatetotalprice for modify
      importing keys for action travel~recalculatetotalprice.

    methods get_features for features
      importing keys request requested_features for travel result result.

    methods get_authorizations for authorization
      importing keys request requested_authorizations for travel result result.

    methods is_update_granted importing has_before_image      type abap_bool
                                        overall_status        type /dmo/overall_status
                              returning value(update_granted) type abap_bool.

    methods is_delete_granted importing has_before_image      type abap_bool
                                        overall_status        type /dmo/overall_status
                              returning value(delete_granted) type abap_bool.

    methods is_create_granted returning value(create_granted) type abap_bool.
endclass.

class lhc_travel implementation.

  method calculatetotalprice.
    modify entities of zi_rap_travel_gbaca in local mode
      entity travel
        execute recalculatetotalprice
        from corresponding #( keys )
      reported data(execute_reported).

    reported = corresponding #( deep execute_reported ).
  endmethod.

  method calculatetravelid.
    " Please note that this is just an example for calculating a field during _onSave_.
    " This approach does NOT ensure for gap free or unique travel IDs! It just helps to provide a readable ID.
    " The key of this business object is a UUID, calculated by the framework.

    " check if TravelID is already filled
    read entities of zi_rap_travel_gbaca in local mode
      entity travel
        fields ( travelid ) with corresponding #( keys )
      result data(travels).

    " remove lines where TravelID is already filled.
    delete travels where travelid is not initial.

    " anything left ?
    check travels is not initial.

    " Select max travel ID
    select single
      max( travel_id ) as travelid
    from
      zrap_atrav_gbaca
    into
      @data(max_travelid).

    " Set the travel ID
    modify entities of zi_rap_travel_gbaca in local mode
    entity travel
      update
        from value #( for travel in travels index into i (
          %tky              = travel-%tky
          travelid          = max_travelid + i
          %control-travelid = if_abap_behv=>mk-on ) )
    reported data(update_reported).

    reported = corresponding #( deep update_reported ).
  endmethod.

  method setinitialstatus.
    " Read relevant travel instance data
    read entities of zi_rap_travel_gbaca in local mode
      entity travel
        fields ( travelstatus ) with corresponding #( keys )
      result data(travels).

    " Remove all travel instance data with defined status
    delete travels where travelstatus is not initial.
    check travels is not initial.

    " Set default travel status
    modify entities of zi_rap_travel_gbaca in local mode
    entity travel
      update
        fields ( travelstatus )
        with value #( for travel in travels
                      ( %tky         = travel-%tky
                        travelstatus = travel_status-open ) )
    reported data(update_reported).

    reported = corresponding #( deep update_reported ).
  endmethod.

  method validateagency.
    " Read relevant travel instance data
    read entities of zi_rap_travel_gbaca in local mode
      entity travel
        fields ( agencyid ) with corresponding #( keys )
      result data(travels).

    data agencies type sorted table of /dmo/agency with unique key agency_id.

    " Optimization of DB select: extract distinct non-initial agency IDs
    agencies = corresponding #( travels discarding duplicates mapping agency_id = agencyid except * ).
    delete agencies where agency_id is initial.

    if agencies is not initial.
      " Check if agency ID exist
      select from /dmo/agency fields agency_id
        for all entries in @agencies
        where agency_id = @agencies-agency_id
        into table @data(agencies_db).
    endif.

    " Raise msg for non existing and initial agencyID
    loop at travels into data(travel).
      " Clear state messages that might exist
      append value #(  %tky               = travel-%tky
                       %state_area        = 'VALIDATE_AGENCY' )
        to reported-travel.

      if travel-agencyid is initial or not line_exists( agencies_db[ agency_id = travel-agencyid ] ).
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_AGENCY'
                        %msg        = new zcm_rap_gbaca(
                                          severity = if_abap_behv_message=>severity-error
                                          textid   = zcm_rap_gbaca=>agency_unknown
                                          agencyid = travel-agencyid )
                        %element-agencyid = if_abap_behv=>mk-on )
          to reported-travel.
      endif.
    endloop.
  endmethod.

  method validatecustomer.
    " Read relevant travel instance data
    read entities of zi_rap_travel_gbaca in local mode
      entity travel
        fields ( customerid ) with corresponding #( keys )
      result data(travels).

    data customers type sorted table of /dmo/customer with unique key customer_id.

    " Optimization of DB select: extract distinct non-initial customer IDs
    customers = corresponding #( travels discarding duplicates mapping customer_id = customerid except * ).
    delete customers where customer_id is initial.
    if customers is not initial.
      " Check if customer ID exist
      select from /dmo/customer fields customer_id
        for all entries in @customers
        where customer_id = @customers-customer_id
        into table @data(customers_db).
    endif.

    " Raise msg for non existing and initial customerID
    loop at travels into data(travel).
      " Clear state messages that might exist
      append value #(  %tky        = travel-%tky
                       %state_area = 'VALIDATE_CUSTOMER' )
        to reported-travel.

      if travel-customerid is initial or not line_exists( customers_db[ customer_id = travel-customerid ] ).
        append value #(  %tky = travel-%tky ) to failed-travel.

        append value #(  %tky        = travel-%tky
                         %state_area = 'VALIDATE_CUSTOMER'
                         %msg        = new zcm_rap_gbaca(
                                           severity   = if_abap_behv_message=>severity-error
                                           textid     = zcm_rap_gbaca=>customer_unknown
                                           customerid = travel-customerid )
                         %element-customerid = if_abap_behv=>mk-on )
          to reported-travel.
      endif.
    endloop.
  endmethod.

  method validatedates.
    " Read relevant travel instance data
    read entities of zi_rap_travel_gbaca in local mode
      entity travel
        fields ( travelid begindate enddate ) with corresponding #( keys )
      result data(travels).

    loop at travels into data(travel).
      " Clear state messages that might exist
      append value #(  %tky        = travel-%tky
                       %state_area = 'VALIDATE_DATES' )
        to reported-travel.

      if travel-enddate < travel-begindate.
        append value #( %tky = travel-%tky ) to failed-travel.
        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = new zcm_rap_gbaca(
                                                 severity  = if_abap_behv_message=>severity-error
                                                 textid    = zcm_rap_gbaca=>date_interval
                                                 begindate = travel-begindate
                                                 enddate   = travel-enddate
                                                 travelid  = travel-travelid )
                        %element-begindate = if_abap_behv=>mk-on
                        %element-enddate   = if_abap_behv=>mk-on ) to reported-travel.

      elseif travel-begindate < cl_abap_context_info=>get_system_date( ).
        append value #( %tky               = travel-%tky ) to failed-travel.
        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = new zcm_rap_gbaca(
                                                 severity  = if_abap_behv_message=>severity-error
                                                 textid    = zcm_rap_gbaca=>begin_date_before_system_date
                                                 begindate = travel-begindate )
                        %element-begindate = if_abap_behv=>mk-on ) to reported-travel.
      endif.
    endloop.
  endmethod.

  method accepttravel.
    " Set the new overall status
    modify entities of zi_rap_travel_gbaca in local mode
      entity travel
         update
           fields ( travelstatus )
           with value #( for key in keys
                           ( %tky         = key-%tky
                             travelstatus = travel_status-accepted ) )
      failed failed
      reported reported.

    " Fill the response table
    read entities of zi_rap_travel_gbaca in local mode
      entity travel
        all fields with corresponding #( keys )
      result data(travels).

    result = value #( for travel in travels
                        ( %tky   = travel-%tky
                          %param = travel ) ).
  endmethod.

  method rejecttravel.
    " Set the new overall status
    modify entities of zi_rap_travel_gbaca in local mode
      entity travel
         update
           fields ( travelstatus )
           with value #( for key in keys
                           ( %tky         = key-%tky
                             travelstatus = travel_status-cancelled ) )
      failed failed
      reported reported.

    " Fill the response table
    read entities of zi_rap_travel_gbaca in local mode
      entity travel
        all fields with corresponding #( keys )
      result data(travels).

    result = value #( for travel in travels
                        ( %tky   = travel-%tky
                          %param = travel ) ).
  endmethod.

  method recalculatetotalprice.
    types: begin of ty_amount_per_currencycode,
             amount        type /dmo/total_price,
             currency_code type /dmo/currency_code,
           end of ty_amount_per_currencycode.

    data: amount_per_currencycode type standard table of ty_amount_per_currencycode.

    " Read all relevant travel instances.
    read entities of zi_rap_travel_gbaca in local mode
          entity travel
             fields ( bookingfee currencycode )
             with corresponding #( keys )
          result data(travels).

    delete travels where currencycode is initial.

    loop at travels assigning field-symbol(<travel>).
      " Set the start for the calculation by adding the booking fee.
      amount_per_currencycode = value #( ( amount        = <travel>-bookingfee
                                           currency_code = <travel>-currencycode ) ).
      " Read all associated bookings and add them to the total price.
      read entities of zi_rap_travel_gbaca in local mode
         entity travel by \_booking
            fields ( flightprice currencycode )
          with value #( ( %tky = <travel>-%tky ) )
          result data(bookings).
      loop at bookings into data(booking) where currencycode is not initial.
        collect value ty_amount_per_currencycode( amount        = booking-flightprice
                                                  currency_code = booking-currencycode ) into amount_per_currencycode.
      endloop.

      clear <travel>-totalprice.
      loop at amount_per_currencycode into data(single_amount_per_currencycode).
        " If needed do a Currency Conversion
        if single_amount_per_currencycode-currency_code = <travel>-currencycode.
          <travel>-totalprice += single_amount_per_currencycode-amount.
        else.
          /dmo/cl_flight_amdp=>convert_currency(
             exporting
               iv_amount                   =  single_amount_per_currencycode-amount
               iv_currency_code_source     =  single_amount_per_currencycode-currency_code
               iv_currency_code_target     =  <travel>-currencycode
               iv_exchange_rate_date       =  cl_abap_context_info=>get_system_date( )
             importing
               ev_amount                   = data(total_booking_price_per_curr)
            ).
          <travel>-totalprice += total_booking_price_per_curr.
        endif.
      endloop.
    endloop.

    " write back the modified total_price of travels
    modify entities of zi_rap_travel_gbaca in local mode
      entity travel
        update fields ( totalprice )
        with corresponding #( travels ).
  endmethod.

  method get_features.
    " Read the travel status of the existing travels
    read entities of zi_rap_travel_gbaca in local mode
      entity travel
        fields ( travelstatus ) with corresponding #( keys )
      result data(travels)
      failed failed.

    result =
      value #(
        for travel in travels
          let is_accepted =   cond #( when travel-travelstatus = travel_status-accepted
                                        then if_abap_behv=>fc-o-disabled
                                      else if_abap_behv=>fc-o-enabled  )
              is_rejected =   cond #( when travel-travelstatus = travel_status-cancelled
                                        then if_abap_behv=>fc-o-disabled
                                      else if_abap_behv=>fc-o-enabled )
          in
            ( %tky                 = travel-%tky
              %action-accepttravel = is_accepted
              %action-rejecttravel = is_rejected
             ) ).

  endmethod.

  method get_authorizations.
    data: has_before_image    type abap_bool,
          is_update_requested type abap_bool,
          is_delete_requested type abap_bool,
          update_granted      type abap_bool,
          delete_granted      type abap_bool.

    data: failed_travel like line of failed-travel.

    " Read the existing travels
    read entities of zi_rap_travel_gbaca in local mode
      entity travel
        fields ( travelstatus ) with corresponding #( keys )
      result data(travels)
      failed failed.

    check travels is not initial.

*   In this example the authorization is defined based on the Activity + Travel Status
*   For the Travel Status we need the before-image from the database. We perform this for active (is_draft=00) as well as for drafts (is_draft=01) as we can't distinguish between edit or new drafts
    select from zrap_atrav_gbaca
      fields travel_uuid, overall_status
      for all entries in @travels
      where travel_uuid eq @travels-traveluuid
      order by primary key
      into table @data(travels_before_image).

    is_update_requested = cond #( when requested_authorizations-%update              = if_abap_behv=>mk-on or
                                       requested_authorizations-%action-accepttravel = if_abap_behv=>mk-on or
                                       requested_authorizations-%action-rejecttravel = if_abap_behv=>mk-on or
*                                       requested_authorizations-%action-Prepare      = if_abap_behv=>mk-on OR
*                                       requested_authorizations-%action-Edit         = if_abap_behv=>mk-on OR
                                       requested_authorizations-%assoc-_booking      = if_abap_behv=>mk-on
                                  then abap_true else abap_false ).

    is_delete_requested = cond #( when requested_authorizations-%delete = if_abap_behv=>mk-on
                                    then abap_true else abap_false ).

    loop at travels into data(travel).
      update_granted = delete_granted = abap_false.

      read table travels_before_image into data(travel_before_image)
           with key travel_uuid = travel-traveluuid binary search.
      has_before_image = cond #( when sy-subrc = 0 then abap_true else abap_false ).

      if is_update_requested = abap_true.
        " Edit of an existing record -> check update authorization
        if has_before_image = abap_true.
          update_granted = is_update_granted( has_before_image = has_before_image  overall_status = travel_before_image-overall_status ).
          if update_granted = abap_false.
            append value #( %tky        = travel-%tky
                            %msg        = new zcm_rap_gbaca( severity = if_abap_behv_message=>severity-error
                                                             textid   = zcm_rap_gbaca=>unauthorized )
                          ) to reported-travel.
          endif.
          " Creation of a new record -> check create authorization
        else.
          update_granted = is_create_granted( ).
          if update_granted = abap_false.
            append value #( %tky        = travel-%tky
                            %msg        = new zcm_rap_gbaca( severity = if_abap_behv_message=>severity-error
                                                            textid   = zcm_rap_gbaca=>unauthorized )
                          ) to reported-travel.
          endif.
        endif.
      endif.

      if is_delete_requested = abap_true.
        delete_granted = is_delete_granted( has_before_image = has_before_image  overall_status = travel_before_image-overall_status ).
        if delete_granted = abap_false.
          append value #( %tky        = travel-%tky
                          %msg        = new zcm_rap_gbaca( severity = if_abap_behv_message=>severity-error
                                                          textid   = zcm_rap_gbaca=>unauthorized )
                        ) to reported-travel.
        endif.
      endif.

      append value #( %tky = travel-%tky

                      %update              = cond #( when update_granted = abap_true then if_abap_behv=>auth-allowed else if_abap_behv=>auth-unauthorized )
                      %action-accepttravel = cond #( when update_granted = abap_true then if_abap_behv=>auth-allowed else if_abap_behv=>auth-unauthorized )
                      %action-rejecttravel = cond #( when update_granted = abap_true then if_abap_behv=>auth-allowed else if_abap_behv=>auth-unauthorized )
*                      %action-Prepare      = COND #( WHEN update_granted = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
*                      %action-Edit         = COND #( WHEN update_granted = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      %assoc-_booking      = cond #( when update_granted = abap_true then if_abap_behv=>auth-allowed else if_abap_behv=>auth-unauthorized )

                      %delete              = cond #( when delete_granted = abap_true then if_abap_behv=>auth-allowed else if_abap_behv=>auth-unauthorized )
                    )
        to result.
    endloop.
  endmethod.

  method is_create_granted.
    authority-check object 'ZOSTATGB'
      id 'ZOSTATGB' dummy
      id 'ACTVT' field '01'.
    create_granted = cond #( when sy-subrc = 0 then abap_true else abap_false ).
    " Simulate full access - for testing purposes only! Needs to be removed for a productive implementation.
    create_granted = abap_true.
  endmethod.

  method is_delete_granted.
    if has_before_image = abap_true.
      authority-check object 'ZOSTATGB'
        id 'ZOSTATGB' field overall_status
        id 'ACTVT' field '06'.
    else.
      authority-check object 'ZOSTATGB'
        id 'ZOSTATGB' dummy
        id 'ACTVT' field '06'.
    endif.
    delete_granted = cond #( when sy-subrc = 0 then abap_true else abap_false ).

    " Simulate full access - for testing purposes only! Needs to be removed for a productive implementation.
    delete_granted = abap_true.
  endmethod.

  method is_update_granted.
    if has_before_image = abap_true.
      authority-check object 'ZOSTATGB'
        id 'ZOSTATGB' field overall_status
        id 'ACTVT' field '02'.
    else.
      authority-check object 'ZOSTATGB'
        id 'ZOSTATGB' dummy
        id 'ACTVT' field '02'.
    endif.
    update_granted = cond #( when sy-subrc = 0 then abap_true else abap_false ).

    " Simulate full access - for testing purposes only! Needs to be removed for a productive implementation.
    update_granted = abap_true.
  endmethod.

endclass.
