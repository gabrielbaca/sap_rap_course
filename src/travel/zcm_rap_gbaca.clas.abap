class zcm_rap_gbaca definition
  public
  inheriting from cx_static_check
  final
  create public .

  public section.

    interfaces if_t100_dyn_msg .
    interfaces if_t100_message .
    interfaces if_abap_behv_message .

    constants:
      begin of date_interval,
        msgid type symsgid value 'ZRAP_MSG_GBACA',
        msgno type symsgno value '001',
        attr1 type scx_attrname value 'BEGINDATE',
        attr2 type scx_attrname value 'ENDDATE',
        attr3 type scx_attrname value 'TRAVELID',
        attr4 type scx_attrname value '',
      end of date_interval .
    constants:
      begin of begin_date_before_system_date,
        msgid type symsgid value 'ZRAP_MSG_GBACA',
        msgno type symsgno value '002',
        attr1 type scx_attrname value 'BEGINDATE',
        attr2 type scx_attrname value '',
        attr3 type scx_attrname value '',
        attr4 type scx_attrname value '',
      end of begin_date_before_system_date .
    constants:
      begin of customer_unknown,
        msgid type symsgid value 'ZRAP_MSG_GBACA',
        msgno type symsgno value '003',
        attr1 type scx_attrname value 'CUSTOMERID',
        attr2 type scx_attrname value '',
        attr3 type scx_attrname value '',
        attr4 type scx_attrname value '',
      end of customer_unknown .
    constants:
      begin of agency_unknown,
        msgid type symsgid value 'ZRAP_MSG_GBACA',
        msgno type symsgno value '004',
        attr1 type scx_attrname value 'AGENCYID',
        attr2 type scx_attrname value '',
        attr3 type scx_attrname value '',
        attr4 type scx_attrname value '',
      end of agency_unknown .
    constants:
      begin of unauthorized,
        msgid type symsgid value 'ZRAP_MSG_GBACA',
        msgno type symsgno value '005',
        attr1 type scx_attrname value '',
        attr2 type scx_attrname value '',
        attr3 type scx_attrname value '',
        attr4 type scx_attrname value '',
      end of unauthorized .

    methods constructor
      importing
        severity   type if_abap_behv_message=>t_severity default if_abap_behv_message=>severity-error
        textid     like if_t100_message=>t100key optional
        previous   type ref to cx_root optional
        begindate  type /dmo/begin_date optional
        enddate    type /dmo/end_date optional
        travelid   type /dmo/travel_id optional
        customerid type /dmo/customer_id optional
        agencyid   type /dmo/agency_id  optional.

    data begindate type /dmo/begin_date read-only.
    data enddate type /dmo/end_date read-only.
    data travelid type string read-only.
    data customerid type string read-only.
    data agencyid type string read-only.
  protected section.
  private section.
ENDCLASS.



CLASS ZCM_RAP_GBACA IMPLEMENTATION.


  method constructor ##ADT_SUPPRESS_GENERATION.
    call method super->constructor
      exporting
        previous = previous.
    clear me->textid.
    if textid is initial.
      if_t100_message~t100key = if_t100_message=>default_textid.
    else.
      if_t100_message~t100key = textid.
    endif.

    me->if_abap_behv_message~m_severity = severity.
    me->begindate = begindate.
    me->enddate = enddate.
    me->travelid = |{ travelid alpha = out }|.
    me->customerid = |{ customerid alpha = out }|.
    me->agencyid = |{ agencyid alpha = out }|.
  endmethod.
ENDCLASS.
