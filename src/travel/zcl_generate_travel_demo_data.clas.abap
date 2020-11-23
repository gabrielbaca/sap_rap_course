CLASS zcl_generate_travel_demo_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS accepted TYPE c LENGTH 1 VALUE 'A' ##NO_TEXT.
    CONSTANTS cancelled TYPE c LENGTH 1 VALUE 'X' ##NO_TEXT.
    CONSTANTS open TYPE c LENGTH 1 VALUE 'O' ##NO_TEXT.
    METHODS delete_existing_data.
    METHODS insert_travel_demo_data.
    METHODS insert_booking_demo_data.
ENDCLASS.



CLASS ZCL_GENERATE_TRAVEL_DEMO_DATA IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    delete_existing_data( ).
    insert_travel_demo_data( ).
    insert_booking_demo_data( ).

    COMMIT WORK.

    out->write( 'Travel and booking demo data inserted.').
  ENDMETHOD.


  METHOD insert_booking_demo_data.

    INSERT zrap_abook_gbaca FROM (
        SELECT
          FROM   /dmo/booking    AS booking
            JOIN zrap_atrav_gbaca AS z
            ON   booking~travel_id = z~travel_id
          FIELDS
            uuid( )                 AS booking_uuid          ,
            z~travel_uuid           AS travel_uuid           ,
            booking~booking_id      AS booking_id            ,
            booking~booking_date    AS booking_date          ,
            booking~customer_id     AS customer_id           ,
            booking~carrier_id      AS carrier_id            ,
            booking~connection_id   AS connection_id         ,
            booking~flight_date     AS flight_date           ,
            booking~flight_price    AS flight_price          ,
            booking~currency_code   AS currency_code         ,
            z~created_by            AS created_by            ,
            z~last_changed_by       AS last_changed_by       ,
            z~last_changed_at       AS local_last_changed_by
      ).

  ENDMETHOD.


  METHOD insert_travel_demo_data.

    INSERT zrap_atrav_gbaca FROM (
        SELECT
          FROM /dmo/travel
          FIELDS
            uuid(  )      AS travel_uuid           ,
            travel_id     AS travel_id             ,
            agency_id     AS agency_id             ,
            customer_id   AS customer_id           ,
            begin_date    AS begin_date            ,
            end_date      AS end_date              ,
            booking_fee   AS booking_fee           ,
            total_price   AS total_price           ,
            currency_code AS currency_code         ,
            description   AS description           ,
            CASE status
              WHEN 'B' THEN @accepted " accepted
              WHEN 'X' THEN @cancelled " cancelled
              ELSE @open          " open
            END           AS overall_status        ,
            createdby     AS created_by            ,
            createdat     AS created_at            ,
            lastchangedby AS last_changed_by       ,
            lastchangedat AS last_changed_at       ,
            lastchangedat AS local_last_changed_at
            ORDER BY travel_id
      ).

  ENDMETHOD.


  METHOD delete_existing_data.

    DELETE FROM zrap_atrav_gbaca.
    DELETE FROM zrap_abook_gbaca.

  ENDMETHOD.
ENDCLASS.
