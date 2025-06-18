

class ZCL_HTTP_BANKPAYABLEPOST definition
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.


    INTERFACES if_http_service_extension .
    CLASS-METHODS postData
      IMPORTING
        request        TYPE REF TO if_web_http_request
      RETURNING
        VALUE(message) TYPE string .


    CLASS-METHODS  checkDateFormat
      IMPORTING
        date           TYPE string
        dateType       TYPE string
      RETURNING
        VALUE(message) TYPE string.

    CLASS-METHODS getCID RETURNING VALUE(cid) TYPE abp_behv_cid.

    CLASS-METHODS  postSupplierPayment
      IMPORTING
        wa_data        TYPE zr_bankpayable
        psDate         TYPE string
        dcDate         TYPE string
      RETURNING
        VALUE(message) TYPE string .

PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_BANKPAYABLEPOST IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.
    CASE request->get_method(  ).
      WHEN CONV string( if_web_http_client=>post ).
        response->set_text( postData( request ) ).
    ENDCASE.
  ENDMETHOD.


  METHOD postData.

    TYPES: BEGIN OF ty_json_structure,
             vutdate     TYPE c LENGTH 10,
             unit        TYPE c LENGTH 20,
             vutacode    TYPE c LENGTH 10,
             createdtime TYPE c LENGTH 6,
           END OF ty_json_structure.

    DATA tt_json_structure TYPE TABLE OF ty_json_structure WITH EMPTY KEY.

    TRY.

        xco_cp_json=>data->from_string( request->get_text( ) )->write_to( REF #( tt_json_structure ) ).

        LOOP AT tt_json_structure INTO DATA(wa).

          SELECT SINGLE * FROM zr_bankpayable
          WHERE Vutdate = @wa-vutdate AND
                Unit = @wa-unit AND
                Vutacode = @wa-vutacode AND
                Createdtime = @wa-createdtime
             INTO @DATA(wa_data).

          IF wa_data-PayStatus NE 'E'.
            message = |Payment not processed for Transaction Id - { wa_data-UniqTracCode }.|.
            UPDATE zbankpayable
               SET log = @message
               WHERE Vutdate = @wa-vutdate AND
                Unit = @wa-unit AND
                Vutacode = @wa-vutacode AND
                Createdtime = @wa-createdtime.
            RETURN.
          ENDIF.



          DATA(psDate) = checkDateFormat( date = CONV string( wa_data-PostingDate ) datetype = 'Posting' ).
          FIND 'Invalid' IN psDate.
          IF sy-subrc = 0.
            message = psDate.
            UPDATE zbankpayable
               SET log = @message
               WHERE Vutdate = @wa-vutdate AND
                Unit = @wa-unit AND
                Vutacode = @wa-vutacode AND
                Createdtime = @wa-createdtime.
            RETURN.
          ENDIF.

          DATA(dcDate) = checkDateFormat( date = CONV string( wa_data-Vutdate ) datetype = 'Document' ).
          FIND 'Invalid' IN dcDate.
          IF sy-subrc = 0.
            message = dcDate.
            UPDATE zbankpayable
               SET log = @message
               WHERE Vutdate = @wa-vutdate AND
                Unit = @wa-unit AND
                Vutacode = @wa-vutacode AND
                Createdtime = @wa-createdtime.
            RETURN.
          ENDIF.

          message = postSupplierPayment( wa_data = wa_data psdate = psDate dcdate = dcDate ).

        ENDLOOP.

      CATCH cx_sy_conversion_no_date INTO DATA(lx_date).
        message = |Error in Date Conversion: { lx_date->get_text( ) }|.

      CATCH cx_sy_conversion_no_time INTO DATA(lx_time).
        message = |Error in Time Conversion: { lx_time->get_text( ) }|.

      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
        message = |SQL Error: { lx_sql->get_text( ) }|.

      CATCH cx_root INTO DATA(lx_root).
        message = |General Error: { lx_root->get_text( ) }|.
    ENDTRY.


  ENDMETHOD.


  METHOD getCID.
    TRY.
        cid = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
      CATCH cx_uuid_error.
        ASSERT 1 = 0.
    ENDTRY.
  ENDMETHOD.

      METHOD postSupplierPayment.
        DATA: lt_je_deep     TYPE TABLE FOR ACTION IMPORT i_journalentrytp~post,
              document       TYPE string,
              lv_postingdate TYPE d.

        SELECT SINGLE FROM ztable_plant
        FIELDS comp_code,profitcenter
        WHERE plant_code = @wa_data-Unit
        INTO @DATA(ls_company).

        SELECT SINGLE FROM zbrstable
          FIELDS  acc_id AS HouseBankAccount, house_bank AS HouseBank
          WHERE out_gl = @wa_data-Vutacode
                  AND comp_code = @ls_company-comp_code
          INTO @DATA(ls_housebank).


        APPEND INITIAL LINE TO lt_je_deep ASSIGNING FIELD-SYMBOL(<je_deep>).
        <je_deep>-%cid = getCid(  ).
        <je_deep>-%param = VALUE #(
        companycode = ls_company
        businesstransactiontype = 'RFBU'
        accountingdocumenttype = 'KZ'
        CreatedByUser = sy-uname
        documentdate = dcDate
        postingdate = COND #( WHEN psDate IS INITIAL
                      THEN cl_abap_context_info=>get_system_date( )
                      ELSE psDate )

        _apitems = VALUE #( ( glaccountlineitem = |002|
                                Supplier = wa_data-Vutaacode
                                BusinessPlace = wa_data-Unit
                                DocumentItemText = wa_data-Vutnart
                              _currencyamount = VALUE #( (
                                                currencyrole = '00'
                                                journalentryitemamount = wa_data-Vutamt
                                                currency = 'INR' ) ) )
                           )
        _glitems = VALUE #(
                            ( glaccountlineitem = |001|
                            glaccount = wa_data-Vutacode
                            HouseBank = ls_housebank-Housebank
                            HouseBankAccount = ls_housebank-HouseBankAccount
                            AssignmentReference = wa_data-utr
                            ProfitCenter = ls_company-profitcenter
                            DocumentItemText = wa_data-Vutnart
                            _currencyamount = VALUE #( (
                                                currencyrole = '00'
                                                journalentryitemamount = wa_data-Vutamt * -1
                                                currency = 'INR' ) ) ) )
        ).

        MODIFY ENTITIES OF i_journalentrytp PRIVILEGED
        ENTITY journalentry
        EXECUTE post FROM lt_je_deep
        FAILED DATA(ls_failed_deep)
        REPORTED DATA(ls_reported_deep)
        MAPPED DATA(ls_mapped_deep).

        IF ls_failed_deep IS NOT INITIAL.

          LOOP AT ls_reported_deep-journalentry ASSIGNING FIELD-SYMBOL(<ls_reported_deep>).
            message = <ls_reported_deep>-%msg->if_message~get_text( ).
          ENDLOOP.
          RETURN.
        ELSE.

          COMMIT ENTITIES BEGIN
          RESPONSE OF i_journalentrytp
          FAILED DATA(lt_commit_failed)
          REPORTED DATA(lt_commit_reported).

          IF lt_commit_reported IS NOT INITIAL.
            LOOP AT lt_commit_reported-journalentry ASSIGNING FIELD-SYMBOL(<ls_reported>).
              document = <ls_reported>-AccountingDocument.
            ENDLOOP.
          ELSE.
            LOOP AT lt_commit_failed-journalentry ASSIGNING FIELD-SYMBOL(<ls_failed>).
              message = <ls_failed>-%fail-cause.
            ENDLOOP.
            RETURN.
          ENDIF.

          COMMIT ENTITIES END.

          IF document IS NOT INITIAL.
            message = |Document Created Successfully: { document }|.
            MODIFY ENTITIES OF zr_bankpayable
            ENTITY ZrBankpayable
            UPDATE FIELDS ( Accountingdocument Isposted )
            WITH VALUE #(  (
                Accountingdocument = document
                Isposted = abap_true
                Createdtime = wa_data-Createdtime
                Vutdate = wa_data-Vutdate
                Unit = wa_data-Unit
                Vutacode = wa_data-Vutacode
                )  )
            FAILED DATA(lt_failed)
            REPORTED DATA(lt_reported).

            COMMIT ENTITIES BEGIN
            RESPONSE OF zr_bankpayable
            FAILED DATA(lt_commit_failed2)
            REPORTED DATA(lt_commit_reported2).

            ...
            COMMIT ENTITIES END.
          ELSE.
            message = |Document Creation Failed: { message }|.
          ENDIF.

        ENDIF.

      ENDMETHOD.


  METHOD checkDateFormat.

    DATA: lv_date_parts TYPE TABLE OF string.
    TRY.
        SPLIT date AT '/' INTO  DATA(lv_date_parts1) DATA(lv_date_parts2) DATA(lv_date_parts3) .
        message = lv_date_parts3 && lv_date_parts2 && lv_date_parts1.
      CATCH cx_sy_itab_line_not_found.
        message = |Invalid { dateType } date format: { date }|.
        RETURN.
    ENDTRY.
  ENDMETHOD.



ENDCLASS.
