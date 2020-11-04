class lhc_booking definition inheriting from cl_abap_behavior_handler.
  private section.

    methods calculatebookingid for determine on modify
      importing keys for booking~calculatebookingid.

    methods calculatetotalprice for determine on modify
      importing keys for booking~calculatetotalprice.

endclass.

class lhc_booking implementation.

  method calculatebookingid.
    data max_bookingid type /dmo/booking_id.
    data update type table for update zi_rap_travel_gbaca\\booking.

    " Read all travels for the requested bookings.
    " If multiple bookings of the same travel are requested, the travel is returned only once.
    read entities of zi_rap_travel_gbaca in local mode
    entity booking by \_travel
      fields ( traveluuid )
      with corresponding #( keys )
      result data(travels).

    " Process all affected Travels. Read respective bookings, determine the max-id and update the bookings without ID.
    loop at travels into data(travel).
      read entities of zi_rap_travel_gbaca in local mode
        entity travel by \_booking
          fields ( bookingid )
        with value #( ( %tky = travel-%tky ) )
        result data(bookings).

      " Find max used BookingID in all bookings of this travel
      max_bookingid ='0000'.
      loop at bookings into data(booking).
        if booking-bookingid > max_bookingid.
          max_bookingid = booking-bookingid.
        endif.
      endloop.

      " Provide a booking ID for all bookings that have none.
      loop at bookings into booking where bookingid is initial.
        max_bookingid += 10.
        append value #( %tky      = booking-%tky
                        bookingid = max_bookingid
                      ) to update.
      endloop.
    endloop.

    " Update the Booking ID of all relevant bookings
    modify entities of zi_rap_travel_gbaca in local mode
    entity booking
      update fields ( bookingid ) with update
    reported data(update_reported).

    reported = corresponding #( deep update_reported ).
  endmethod.

  method calculatetotalprice.

    " Read all travels for the requested bookings.
    " If multiple bookings of the same travel are requested, the travel is returned only once.
    read entities of zi_rap_travel_gbaca in local mode
    entity booking by \_travel
      fields ( traveluuid )
      with corresponding #( keys )
      result data(travels)
      failed data(read_failed).

    " Trigger calculation of the total price
    modify entities of zi_rap_travel_gbaca in local mode
    entity travel
      execute recalculatetotalprice
      from corresponding #( travels )
    reported data(execute_reported).

    reported = corresponding #( deep execute_reported ).
  endmethod.

endclass.
