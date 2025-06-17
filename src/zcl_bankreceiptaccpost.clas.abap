CLASS zcl_bankreceiptaccpost DEFINITION
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

    CLASS-METHODS  postCustomerPayment
      IMPORTING
        wa_data        TYPE zr_bankreceipt
        psDate         TYPE string
        dcDate         TYPE string
      RETURNING
        VALUE(message) TYPE string .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_bankreceiptaccpost IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.
    CASE request->get_method(  ).
      WHEN CONV string( if_web_http_client=>post ).
        response->set_text( postData( request ) ).
    ENDCASE.
  ENDMETHOD.


  METHOD postData.

    DATA: lv_oipaym TYPE TABLE OF zr_oipayments,
          wa_oipaym TYPE zr_oipayments.

    TYPES: BEGIN OF ty_json_structure,
             Id TYPE i,
           END OF ty_json_structure.

    DATA tt_json_structure TYPE TABLE OF ty_json_structure WITH EMPTY KEY.

    TRY.

        xco_cp_json=>data->from_string( request->get_text( ) )->write_to( REF #( tt_json_structure ) ).

        LOOP AT tt_json_structure INTO DATA(wa).

          SELECT SINGLE * FROM zr_bankreceipt
          WHERE Id = @wa-Id
             INTO @DATA(wa_data).

          wa_data-Creditdatetime = wa_data-Creditdatetime+0(10).

          DATA(psDate) = checkDateFormat( date = CONV string( wa_data-Creditdatetime ) datetype = 'Posting' ).
          FIND 'Invalid' IN psDate.
          IF sy-subrc = 0.
            message = psDate.
            UPDATE zbankreceipt
               SET errorlog = @message
               WHERE Id = @wa_data-Id.
            RETURN.
          ENDIF.

          DATA(dcDate) = checkDateFormat( date = CONV string( wa_data-Creditdatetime ) datetype = 'Document' ).
          FIND 'Invalid' IN dcDate.
          IF sy-subrc = 0.
            message = dcDate.
            UPDATE zbankreceipt
               SET errorlog = @message
               WHERE Id = @wa_data-Id.
            RETURN.
          ENDIF.

          message = postCustomerPayment( wa_data = wa_data psdate = psDate dcdate = dcDate ).

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

 METHOD postCustomerPayment.
   DATA: lt_je_deep TYPE TABLE FOR ACTION IMPORT i_journalentrytp~post,
         document   TYPE string.

   SELECT SINGLE FROM ztable_plant
    FIELDS  profitcenter
    WHERE plant_code = @wa_data-Plant
    INTO @DATA(lv_centers).

   SELECT SINGLE FROM zbrstable
    FIELDS  acc_id as HouseBankAccount, main_gl as Glaccount, house_bank as HouseBank
    WHERE acc_id = @wa_data-AccountId
            AND comp_code = @wa_data-Companycode
    INTO @DATA(wa_gl).


   APPEND INITIAL LINE TO lt_je_deep ASSIGNING FIELD-SYMBOL(<je_deep>).
   <je_deep>-%cid = getCid(  ).
   <je_deep>-%param = VALUE #(
   companycode = wa_data-Companycode
   businesstransactiontype = 'RFBU'
   accountingdocumenttype = 'DZ'
   CreatedByUser = sy-uname
   documentdate = dcDate
   postingdate = COND #( WHEN psDate IS INITIAL
                 THEN cl_abap_context_info=>get_system_date( )
                 ELSE psDate )

   _aritems = VALUE #( ( glaccountlineitem = |001|
                           Customer = wa_data-Virtualaccount
*                                DocumentItemText = wa_data-
                           BusinessPlace = wa_data-Plant
                         _currencyamount = VALUE #( (
                                           currencyrole = '00'
                                           journalentryitemamount = wa_data-Amount * -1
                                           currency = 'INR' ) ) )
                      )
        _glitems = VALUE #(
                            ( glaccountlineitem = |002|
                            glaccount = wa_gl-Glaccount
                            HouseBank = wa_gl-Housebank
                            HouseBankAccount = wa_gl-HouseBankAccount
                            BusinessPlace = wa_data-Plant
                            AssignmentReference = wa_data-Utr
*                            DocumentItemText = wa_data-Gltext
                            ProfitCenter = lv_centers
                            _currencyamount = VALUE #( (
                                                currencyrole = '00'
                                                journalentryitemamount = wa_data-Amount
                                                currency = 'INR' ) ) ) )
        )
   .

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
     UPDATE zbankreceipt
       SET errorlog = @message
       WHERE Id = @wa_data-Id.
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
       UPDATE zbankreceipt
       SET errorlog = @message
       WHERE Id = @wa_data-Id.
       RETURN.
     ENDIF.

     COMMIT ENTITIES END.

     IF document IS NOT INITIAL.
       message = |Document Created Successfully: { document }|.
       MODIFY ENTITIES OF zr_bankreceipt
       ENTITY ZrBankreceipt
       UPDATE FIELDS ( Accountingdocument Isposted )
       WITH VALUE #(  (
           Accountingdocument = document
           Isposted = abap_true
           Id = wa_data-Id
           )  )
       FAILED DATA(lt_failed)
       REPORTED DATA(lt_reported).
       COMMIT ENTITIES BEGIN
          RESPONSE OF zr_oipayments
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

    DATA: lv_match TYPE i.
    DATA: lv_date_parts TYPE TABLE OF string.

    FIND REGEX '^\d{2}-\d{2}-\d{4}$'  IN date.

    IF sy-subrc = 0.
      lv_match = 1.
    ELSE.
      lv_match = 0.
    ENDIF.

    FIND REGEX '^\d{4}-\d{2}-\d{2}$'  IN date.
    IF sy-subrc = 0.
      lv_match = 2.
    ENDIF.

    IF lv_match = 1.
      TRY.
          SPLIT date AT '-' INTO  DATA(lv_date_parts1) DATA(lv_date_parts2) DATA(lv_date_parts3) .
          message = lv_date_parts3 && lv_date_parts2 && lv_date_parts1.
        CATCH cx_sy_itab_line_not_found.
          message = |Invalid { dateType } date format: { date }|.
          RETURN.
      ENDTRY.
    ELSEIF lv_match = 2.
      TRY.
          DATA(lv_date_parts4) = date.
          REPLACE ALL OCCURRENCES OF '-' IN lv_date_parts4 WITH ''.
          message = lv_date_parts4.
        CATCH cx_sy_itab_line_not_found.
          message = |Invalid { dateType } date format: { date }|.
          RETURN.
      ENDTRY.
    ELSE.
      message = |Invalid { dateType } date format: { date }|.
      RETURN.
    ENDIF.

  ENDMETHOD.



ENDCLASS.
