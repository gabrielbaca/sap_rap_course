class lhc_booking definition inheriting from cl_abap_behavior_handler.
  private section.

    methods delete for modify
      importing keys for delete booking.

    methods update for modify
      importing entities for update booking.

    methods read for read
      importing keys for read booking result result.

    methods rba_travel for read
      importing keys_rba for read booking\_travel full result_requested result result link association_links.

endclass.

class lhc_booking implementation.

  method delete.

    data messages type /dmo/t_message.

    loop at keys assigning field-symbol(<key>).

      call function '/DMO/FLIGHT_TRAVEL_UPDATE'
        exporting
          is_travel   = value /dmo/s_travel_in( travel_id = <key>-travelid )
          is_travelx  = value /dmo/s_travel_inx( travel_id = <key>-travelid )
          it_booking  = value /dmo/t_booking_in( ( booking_id = <key>-bookingid ) )
          it_bookingx = value /dmo/t_booking_inx( ( booking_id  = <key>-bookingid
                                                    action_code = /dmo/if_flight_legacy=>action_code-delete ) )
        importing
          et_messages = messages.

      if messages is initial.

        append value #( travelid = <key>-travelid
                       bookingid = <key>-bookingid ) to mapped-booking.

      else.

        "fill failed return structure for the framework
        append value #( travelid = <key>-travelid
                        bookingid = <key>-bookingid ) to failed-booking.

        loop at messages into data(message).
          "fill reported structure to be displayed on the UI
          append value #( travelid = <key>-travelid
                          bookingid = <key>-bookingid
                  %msg = new_message( id = message-msgid
                                                number = message-msgno
                                                v1 = message-msgv1
                                                v2 = message-msgv2
                                                v3 = message-msgv3
                                                v4 = message-msgv4
                                                severity = conv #( message-msgty ) )
         ) to reported-booking.
        endloop.



      endif.

    endloop.
  endmethod.

  method update.


    data messages type /dmo/t_message.
    data legacy_entity_in  type /dmo/booking.
    data legacy_entity_x type /dmo/s_booking_inx.


    loop at entities assigning field-symbol(<entity>).

      legacy_entity_in = corresponding #( <entity> mapping from entity ).

      legacy_entity_x-booking_id = <entity>-bookingid.
      legacy_entity_x-_intx      = corresponding zsrap_booking_x_gbaca( <entity> mapping from entity ).
      legacy_entity_x-action_code = /dmo/if_flight_legacy=>action_code-update.

      call function '/DMO/FLIGHT_TRAVEL_UPDATE'
        exporting
          is_travel   = value /dmo/s_travel_in( travel_id = <entity>-travelid )
          is_travelx  = value /dmo/s_travel_inx( travel_id = <entity>-travelid )
          it_booking  = value /dmo/t_booking_in( ( corresponding #( legacy_entity_in ) ) )
          it_bookingx = value /dmo/t_booking_inx( ( legacy_entity_x ) )
        importing
          et_messages = messages.



      if messages is initial.

        append value #( travelid = <entity>-travelid
                       bookingid = legacy_entity_in-booking_id ) to mapped-booking.

      else.

        "fill failed return structure for the framework
        append value #( travelid = <entity>-travelid
                        bookingid = legacy_entity_in-booking_id ) to failed-booking.
        "fill reported structure to be displayed on the UI

        loop at messages into data(message).
          "fill reported structure to be displayed on the UI
          append value #( travelid = <entity>-travelid
                          bookingid = legacy_entity_in-booking_id
                  %msg = new_message( id = message-msgid
                                                number = message-msgno
                                                v1 = message-msgv1
                                                v2 = message-msgv2
                                                v3 = message-msgv3
                                                v4 = message-msgv4
                                                severity = conv #( message-msgty ) )
         ) to reported-booking.
        endloop.

      endif.

    endloop.

  endmethod.

  method read.

    data: legacy_parent_entity_out type /dmo/travel,
          legacy_entities_out      type /dmo/t_booking,
          messages                 type /dmo/t_message.

    "Only one function call for each requested travelid
    loop at keys assigning field-symbol(<key_parent>)
                            group by <key_parent>-travelid .

      call function '/DMO/FLIGHT_TRAVEL_READ'
        exporting
          iv_travel_id = <key_parent>-travelid
        importing
          es_travel    = legacy_parent_entity_out
          et_booking   = legacy_entities_out
          et_messages  = messages.

      if messages is initial.
        "For each travelID find the requested bookings
        loop at group <key_parent> assigning field-symbol(<key>)
                                       group by <key>-%key.

          read table legacy_entities_out into data(legacy_entity_out) with key travel_id  = <key>-%key-travelid
                                                                   booking_id = <key>-%key-bookingid .
          "if read was successfull
          "fill result parameter with flagged fields
          if sy-subrc = 0.

            insert corresponding #( legacy_entity_out mapping to entity ) into table result.

          else.
            "BookingID not found
            insert
              value #( travelid    = <key>-travelid
                       bookingid   = <key>-bookingid
                       %fail-cause = if_abap_behv=>cause-not_found )
              into table failed-booking.
          endif.
        endloop.
      else.
        "TravelID not found or other fail cause
        loop at group <key_parent> assigning <key>.
          failed-booking = value #(  base failed-booking
                                     for msg in messages ( %key-travelid    = <key>-travelid
                                                             %key-bookingid   = <key>-bookingid
                                                             %fail-cause      = cond #( when msg-msgty = 'E' and ( msg-msgno = '016' or msg-msgno = '009' )
                                                                                        then if_abap_behv=>cause-not_found
                                                                                        else if_abap_behv=>cause-unspecific ) ) ).
        endloop.

      endif.

    endloop.
  endmethod.

  method rba_travel.

    data: ls_travel_out  type /dmo/travel,
          lt_booking_out type /dmo/t_booking,
          ls_travel      like line of result,
          lt_message     type /dmo/t_message.

    "result  type table for read result /dmo/i_travel_u\\booking\_travel

    "Only one function call for each requested travelid
    loop at keys_rba assigning field-symbol(<fs_travel>)
                                 group by <fs_travel>-travelid.

      call function '/DMO/FLIGHT_TRAVEL_READ'
        exporting
          iv_travel_id = <fs_travel>-%key-travelid
        importing
          es_travel    = ls_travel_out
          et_messages  = lt_message.

      if lt_message is initial.

        loop at group <fs_travel> assigning field-symbol(<fs_booking>).
          "fill link table with key fields
          insert value #( source-%key = <fs_booking>-%key
                          target-%key = ls_travel_out-travel_id )
           into table association_links .

          if  result_requested  = abap_true.
            "fill result parameter with flagged fields
            ls_travel = corresponding #(  ls_travel_out mapping to entity ).
            insert ls_travel into table result.
          endif.
        endloop.

      else. "fill failed table in case of error
        failed-booking = value #(  base failed-booking
                              for msg in lt_message ( %key-travelid    = <fs_travel>-%key-travelid
                                                      %key-bookingid   = <fs_travel>-%key-bookingid
                                                      %fail-cause      = cond #( when msg-msgty = 'E' and ( msg-msgno = '016' or msg-msgno = '009' )
                                                                                 then if_abap_behv=>cause-not_found
                                                                                else if_abap_behv=>cause-unspecific ) ) ).
      endif.

    endloop.
  endmethod.

endclass.
