class ZCL_HTTP_BANKPAYABLE definition
  public
  create public .

PUBLIC SECTION.

  INTERFACES if_http_service_extension .

  CLASS-METHODS getCID RETURNING VALUE(cid) TYPE abp_behv_cid.
  CLASS-METHODS getLastUniq
    RETURNING
      VALUE(max_num) TYPE string.
  CLASS-METHODS saveData
    IMPORTING
      VALUE(request) TYPE REF TO if_web_http_request
    RETURNING
      VALUE(message) TYPE string .

protected section.
private section.
ENDCLASS.



CLASS ZCL_HTTP_BANKPAYABLE IMPLEMENTATION.



  method IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.
  CASE request->get_method(  ).
      WHEN CONV string( if_web_http_client=>post ).
        response->set_text( saveData( request ) ).
    ENDCASE.
  ENDMETHOD.


  METHOD saveData.

*  DATA(filename) = request->get_form_field( i_name = 'uploadName' ).
    TYPES: BEGIN OF ty_bank_receipt,
             vutdate    TYPE c LENGTH 10,
             unit       TYPE c LENGTH 20,
             vutacode   TYPE c LENGTH 10,
             vutatag    TYPE c LENGTH 1,
             vutaacode  TYPE c LENGTH 10,
             vutamt     TYPE p LENGTH 15 DECIMALS 2,
             custref    TYPE c LENGTH 80,
             vutref     TYPE c LENGTH 50,
             vutnart    TYPE c LENGTH 80,
             vutcostcd  TYPE c LENGTH 20,
             vutbgtcd   TYPE c LENGTH 20,
             vutloccd   TYPE c LENGTH 20,
             vutemail   TYPE c LENGTH 255,
             uploadName TYPE c LENGTH 100,
           END OF ty_bank_receipt.

    DATA tt_json_structure TYPE TABLE OF ty_bank_receipt WITH EMPTY KEY.

    TRY.

        xco_cp_json=>data->from_string( request->get_text( ) )->write_to( REF #( tt_json_structure ) ).

        LOOP AT tt_json_structure INTO DATA(wa).
          DATA code TYPE c LENGTH 1.
          DATA lv_max_refnum TYPE i.
          DATA(cid) = getcid( ).


          SELECT SINGLE FROM I_businesspartnerbank
          FIELDS BankNumber
          WHERE BusinessPartner = @wa-Vutacode
          INTO @DATA(bank).

*          IF bank IS INITIAL.
*            message = |Bank code not found for Vutacode: { wa-vutacode }| .
*            RETURN.
*          ELSE
          IF bank+0(4) = 'HDFC'.
            code = 'I'.
          ELSEIF wa-vutamt < 200000.
            code = 'N'.
          ELSE.
            code = 'R'.
          ENDIF.


          DATA(unique_ref) = getlastuniq( ).
          CONDENSE unique_ref NO-GAPS.
          DATA(concater) = |{ code }{ unique_ref }DT{ wa-vutdate }A{ wa-vutacode }{ wa-vutatag }{ wa-vutaacode }|.


          MODIFY ENTITIES OF zr_bankpayable
          ENTITY ZrBankpayable
          CREATE FIELDS (
                Vutdate
                Unit
                Vutacode
                Createdtime
                Vutatag
                Vutaacode
                Vutamt
                Custref
                Vutref
                Vutnart
                Vutcostcd
                Vutbgtcd
                Vutloccd
                Vutemail
                UploadFileName
                TransType
                InstructionRefNum
                UniqTracCode
               )
          WITH VALUE #( (
                 %cid = cid
                 Vutdate = wa-vutdate
                 Unit = wa-unit
                 Createdtime = cl_abap_context_info=>get_system_time( )
                 Vutacode = wa-vutacode
                 Vutatag = wa-vutatag
                 Vutaacode = wa-vutaacode
                 Vutamt = wa-vutamt
                 Custref = wa-custref
                 Vutref = wa-vutref
                 Vutnart = wa-vutnart
                 Vutcostcd = wa-vutcostcd
                 Vutbgtcd = wa-vutbgtcd
                 Vutloccd = wa-vutloccd
                 Vutemail = wa-vutemail
                 UploadFileName = wa-uploadName
                 TransType = code
                 InstructionRefNum = unique_ref
                 UniqTracCode = |{ code }{ unique_ref }DT{ wa-vutdate }A{ wa-vutacode }{ wa-vutatag }{ wa-vutaacode }|
               ) )
           REPORTED DATA(ls_po_reported)
           FAILED   DATA(ls_po_failed)
           MAPPED   DATA(ls_po_mapped).

          COMMIT ENTITIES BEGIN
             RESPONSE OF zr_bankpayable
             FAILED DATA(ls_save_failed)
             REPORTED DATA(ls_save_reported).

          IF ls_po_failed IS NOT INITIAL OR ls_save_failed IS NOT INITIAL.
            message = 'Failed to save data'.
          ELSE.
            message = 'Data saved successfully'.
          ENDIF.

          COMMIT ENTITIES END.
        ENDLOOP.

      CATCH cx_root INTO DATA(lx_root).
        message = |General Error: { lx_root->get_text( ) }|.
    ENDTRY.


  ENDMETHOD.

  METHOD getLastUniq.


    SELECT FROM zr_bankpayable
      FIELDS instructionrefnum
      INTO TABLE @DATA(last_record).

    max_num = REDUCE #( INIT max = CONV posnr( '000000' )
                FOR line IN last_record
                    NEXT max = COND posnr( WHEN line-InstructionRefNum > max
                                           THEN line-InstructionRefNum
                                           ELSE max )
              ).

    IF max_num EQ '000000'.
      max_num = '100001'.
    ELSE.
      max_num += 1.
    ENDIF.


  ENDMETHOD.


  METHOD getCID.
    TRY.
        cid = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
      CATCH cx_uuid_error.
        ASSERT 1 = 0.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
