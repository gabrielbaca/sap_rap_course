class lhc_travel definition inheriting from cl_abap_behavior_handler.
  private section.

    methods create for modify
      importing entities for create travel.

    methods delete for modify
      importing keys for delete travel.

    methods update for modify
      importing entities for update travel.

    methods lock for lock
      importing keys for lock travel.

    methods read for read
      importing keys for read travel result result.

    methods cba_booking for modify
      importing entities_cba for create travel\_booking.

    methods rba_booking for read
      importing keys_rba for read travel\_booking full result_requested result result link association_links.

endclass.

class lhc_travel implementation.

  method create.
    data messages   type /dmo/t_message.
    data legacy_entity_in  type /dmo/travel.
    data legacy_entity_out type /dmo/travel.
    loop at entities assigning field-symbol(<entity>).

      legacy_entity_in = corresponding #( <entity> mapping from entity using control ).

      call function '/DMO/FLIGHT_TRAVEL_CREATE'
        exporting
          is_travel   = corresponding /dmo/s_travel_in( legacy_entity_in )
        importing
          es_travel   = legacy_entity_out
          et_messages = messages.

      if messages is initial.
        append value #( %cid = <entity>-%cid travelid = legacy_entity_out-travel_id ) to mapped-travel.
      else.

        "fill failed return structure for the framework
        append value #( travelid = legacy_entity_in-travel_id ) to failed-travel.
        "fill reported structure to be displayed on the UI
        append value #( travelid = legacy_entity_in-travel_id
                        %msg = new_message( id = messages[ 1 ]-msgid
                                            number = messages[ 1 ]-msgno
                                            v1 = messages[ 1 ]-msgv1
                                            v2 = messages[ 1 ]-msgv2
                                            v3 = messages[ 1 ]-msgv3
                                            v4 = messages[ 1 ]-msgv4
                                            severity = conv #( messages[ 1 ]-msgty ) )
       ) to reported-travel.


      endif.

    endloop.
  endmethod.

  method delete.
    data messages type /dmo/t_message.

    loop at keys assigning field-symbol(<key>).

      call function '/DMO/FLIGHT_TRAVEL_DELETE'
        exporting
          iv_travel_id = <key>-travelid
        importing
          et_messages  = messages.

      if messages is initial.

        append value #( travelid = <key>-travelid ) to mapped-travel.

      else.

        "fill failed return structure for the framework
        append value #( travelid = <key>-travelid ) to failed-travel.
        "fill reported structure to be displayed on the UI
        append value #( travelid = <key>-travelid
                        %msg = new_message( id = messages[ 1 ]-msgid
                                            number = messages[ 1 ]-msgno
                                            v1 = messages[ 1 ]-msgv1
                                            v2 = messages[ 1 ]-msgv2
                                            v3 = messages[ 1 ]-msgv3
                                            v4 = messages[ 1 ]-msgv4
                                            severity = conv #( messages[ 1 ]-msgty ) )
       ) to reported-travel.

      endif.

    endloop.

  endmethod.

  method update.
    data legacy_entity_in   type /dmo/travel.
    data legacy_entity_x  type /dmo/s_travel_inx . "refers to x structure (> BAPIs)
    data messages type /dmo/t_message.

    loop at entities assigning field-symbol(<entity>).

      legacy_entity_in = corresponding #( <entity> mapping from entity ).
      legacy_entity_x-travel_id = <entity>-travelid.
      legacy_entity_x-_intx = corresponding zsrap_travel_x_gbaca( <entity> mapping from entity ).

      call function '/DMO/FLIGHT_TRAVEL_UPDATE'
        exporting
          is_travel   = corresponding /dmo/s_travel_in( legacy_entity_in )
          is_travelx  = legacy_entity_x
        importing
          et_messages = messages.

      if messages is initial.

        append value #( travelid = legacy_entity_in-travel_id ) to mapped-travel.

      else.

        "fill failed return structure for the framework
        append value #( travelid = legacy_entity_in-travel_id ) to failed-travel.
        "fill reported structure to be displayed on the UI
        append value #( travelid = legacy_entity_in-travel_id
                        %msg = new_message( id = messages[ 1 ]-msgid
                                            number = messages[ 1 ]-msgno
                                            v1 = messages[ 1 ]-msgv1
                                            v2 = messages[ 1 ]-msgv2
                                            v3 = messages[ 1 ]-msgv3
                                            v4 = messages[ 1 ]-msgv4
                                            severity = conv #( messages[ 1 ]-msgty ) )
       ) to reported-travel.

      endif.


    endloop.

  endmethod.

  method lock.
    "Instantiate lock object
    data(lock) = cl_abap_lock_object_factory=>get_instance( iv_name = '/DMO/ETRAVEL' ).


    loop at keys assigning field-symbol(<key>).
      try.
          "enqueue travel instance
          lock->enqueue(
              it_parameter  = value #( (  name = 'TRAVEL_ID' value = ref #( <key>-travelid ) ) )
          ).
          "if foreign lock exists
        catch cx_abap_foreign_lock into data(lx_foreign_lock).

          "fill failed return structure for the framework
          append value #( travelid = <key>-travelid ) to failed-travel.
          "fill reported structure to be displayed on the UI
          append value #( travelid = <key>-travelid
                          %msg = new_message( id = '/DMO/CM_FLIGHT_LEGAC'
                                              number = '032'
                                              v1 = <key>-travelid
                                              v2 = lx_foreign_lock->user_name
                                              severity = conv #( 'E' ) )
         ) to reported-travel.

      endtry.
    endloop.

  endmethod.

  method read.
    data: legacy_entity_out type /dmo/travel,
          messages          type /dmo/t_message.

    loop at keys into data(key) group by key-travelid.

      call function '/DMO/FLIGHT_TRAVEL_READ'
        exporting
          iv_travel_id = key-travelid
        importing
          es_travel    = legacy_entity_out
          et_messages  = messages.

      if messages is initial.
        "fill result parameter with flagged fields

        insert corresponding #( legacy_entity_out mapping to entity ) into table result.

      else.

        "fill failed return structure for the framework
        append value #( travelid = key-travelid ) to failed-travel.

        loop at messages into data(message).

          "fill reported structure to be displayed on the UI
          append value #( travelid = key-travelid
                          %msg = new_message( id = message-msgid
                                              number = message-msgno
                                              v1 = message-msgv1
                                              v2 = message-msgv2
                                              v3 = message-msgv3
                                              v4 = message-msgv4
                                              severity = conv #( message-msgty ) )


         ) to reported-travel.
        endloop.
      endif.
    endloop.

    endmethod.

    method cba_booking.

      data messages        type /dmo/t_message.
      data lt_booking_old     type /dmo/t_booking.
      data entity         type /dmo/booking.
      data last_booking_id type /dmo/booking_id value '0'.

      loop at entities_cba assigning field-symbol(<entity_cba>).

        data(travelid) = <entity_cba>-travelid.

        call function '/DMO/FLIGHT_TRAVEL_READ'
          exporting
            iv_travel_id = travelid
          importing
            et_booking   = lt_booking_old
            et_messages  = messages.

        if messages is initial.

          if lt_booking_old is not initial.

            last_booking_id = lt_booking_old[ lines( lt_booking_old ) ]-booking_id.

          endif.

          loop at <entity_cba>-%target assigning field-symbol(<entity>).

            entity = corresponding #( <entity> mapping from entity using control ) .

            last_booking_id += 1.
            entity-booking_id = last_booking_id.

            call function '/DMO/FLIGHT_TRAVEL_UPDATE'
              exporting
                is_travel   = value /dmo/s_travel_in( travel_id = travelid )
                is_travelx  = value /dmo/s_travel_inx( travel_id = travelid )
                it_booking  = value /dmo/t_booking_in( ( corresponding #( entity ) ) )
                it_bookingx = value /dmo/t_booking_inx(
                  (
                    booking_id  = entity-booking_id
                    action_code = /dmo/if_flight_legacy=>action_code-create
                  )
                )
              importing
                et_messages = messages.

            if messages is initial.

              insert
                value #(
                  %cid = <entity>-%cid
                  travelid = travelid
                  bookingid = entity-booking_id
                )
                into table mapped-booking.

            else.


              insert value #( %cid = <entity>-%cid travelid = travelid ) into table failed-booking.

              loop at messages into data(message) where msgty = 'E' or msgty = 'A'.

                insert
                   value #(
                     %cid     = <entity>-%cid
                     travelid = <entity>-travelid
                     %msg     = new_message(
                       id       = message-msgid
                       number   = message-msgno
                       severity = if_abap_behv_message=>severity-error
                       v1       = message-msgv1
                       v2       = message-msgv2
                       v3       = message-msgv3
                       v4       = message-msgv4
                     )
                   )
                   into table reported-booking.

              endloop.

            endif.

          endloop.

        else.

          "fill failed return structure for the framework
          append value #( travelid = travelid ) to failed-travel.
          "fill reported structure to be displayed on the UI
          append value #( travelid = travelid
                          %msg = new_message( id = messages[ 1 ]-msgid
                                              number = messages[ 1 ]-msgno
                                              v1 = messages[ 1 ]-msgv1
                                              v2 = messages[ 1 ]-msgv2
                                              v3 = messages[ 1 ]-msgv3
                                              v4 = messages[ 1 ]-msgv4
                                              severity = conv #( messages[ 1 ]-msgty ) )
         ) to reported-travel.



        endif.

      endloop.

    endmethod.

    method rba_booking.
      data: legacy_parent_entity_out type /dmo/travel,
            legacy_entities_out      type /dmo/t_booking,
            entity                   like line of result,
            message                  type /dmo/t_message.


      loop at keys_rba  assigning field-symbol(<key_rba>) group  by <key_rba>-travelid.

        call function '/DMO/FLIGHT_TRAVEL_READ'
          exporting
            iv_travel_id = <key_rba>-travelid
          importing
            es_travel    = legacy_parent_entity_out
            et_booking   = legacy_entities_out
            et_messages  = message.

        if message is initial.

          loop at legacy_entities_out assigning field-symbol(<fs_booking>).
            "fill link table with key fields

            insert
              value #(
                  source-%key = <key_rba>-%key
                  target-%key = value #(
                    travelid  = <fs_booking>-travel_id
                    bookingid = <fs_booking>-booking_id
                )
              )
              into table  association_links .

            "fill result parameter with flagged fields
            if result_requested = abap_true.

              entity = corresponding #( <fs_booking> mapping to entity ).
              insert entity into table result.

            endif.

          endloop.

        else.
          "fill failed table in case of error

          failed-travel = value #(
            base failed-travel
            for msg in message (
              %key = <key_rba>-travelid
              %fail-cause = cond #(
                when msg-msgty = 'E' and  ( msg-msgno = '016' or msg-msgno = '009' )
                then if_abap_behv=>cause-not_found
                else if_abap_behv=>cause-unspecific
              )
            )
          ).

        endif.

      endloop.
    endmethod.

endclass.

class lsc_zi_rap_travel_u_gbaca definition inheriting from cl_abap_behavior_saver.
protected section.

  methods check_before_save redefinition.

  methods finalize          redefinition.

  methods save              redefinition.

endclass.

class lsc_zi_rap_travel_u_gbaca implementation.

method check_before_save.
endmethod.

method finalize.
endmethod.

method save.
  call function '/DMO/FLIGHT_TRAVEL_SAVE'.
endmethod.

endclass.
