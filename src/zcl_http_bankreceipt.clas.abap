class ZCL_HTTP_BANKRECEIPT definition
  public
  create public .

public section.

  interfaces IF_HTTP_SERVICE_EXTENSION .
  interfaces if_oo_adt_classrun .


   CLASS-METHODS getCID RETURNING VALUE(cid) TYPE abp_behv_cid.
   CLASS-METHODS saveData
    IMPORTING
      VALUE(request)  TYPE REF TO if_web_http_request
    RETURNING
      VALUE(message)  TYPE STRING .

protected section.
private section.
ENDCLASS.



CLASS ZCL_HTTP_BANKRECEIPT IMPLEMENTATION.

METHOD if_oo_adt_classrun~main.
DELETE From zbankpayable where vutatag = ''.
ENDMETHOD.


  method IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.
  CASE request->get_method(  ).
      WHEN CONV string( if_web_http_client=>post ).
        response->set_text( saveData( request ) ).
    ENDCASE.


  ENDMETHOD.


  METHOD saveData.
   TYPES: BEGIN OF ty_bank_receipt,
         id                TYPE i,
         transactionId     TYPE C LENGTH 25,
         remitterName      TYPE C LENGTH 100,
         fromAccountNumber TYPE C LENGTH 70,
         fromBankName      TYPE C LENGTH 100,
         AccountId         TYPE C LENGTH 15,
         utr               TYPE C LENGTH 22,
         virtualAccount    TYPE C LENGTH 25,
         amount            TYPE p LENGTH 16 DECIMALS 2,
         transferMode      TYPE c LENGTH 20,
         creditDateTime    TYPE C LENGTH 25,
         ipFrom            TYPE C LENGTH 20,
         createon          TYPE C LENGTH 25,
         CompanyCode       TYPE C LENGTH 4,
         Plant             TYPE C LENGTH 4,
       END OF ty_bank_receipt.

    DATA tt_json_structure TYPE TABLE OF ty_bank_receipt WITH EMPTY KEY.

    TRY.

        xco_cp_json=>data->from_string( request->get_text( ) )->write_to( REF #( tt_json_structure ) ).

        LOOP AT tt_json_structure INTO DATA(wa).

          DATA(cid) = getcid( ).
          MODIFY ENTITIES OF zr_bankreceipt
         ENTITY ZrBankreceipt
         CREATE FIELDS (
               Id
               TransactionId
               RemitterName
               FromAccountNumber
               FromBankName
               Utr
               VirtualAccount
               Amount
               TransferMode
               CreditDateTime
               IpFrom
               Createon
               AccountId
               CompanyCode
               Plant
              )
         WITH VALUE #( (
                %cid = cid
                Id = wa-id
                TransactionId = wa-transactionid
                RemitterName = wa-remittername
                FromAccountNumber = wa-fromaccountnumber
                FromBankName = wa-frombankname
                Utr = wa-utr
                VirtualAccount = wa-virtualaccount
                Amount = wa-amount
                TransferMode = wa-transfermode
                CreditDateTime = wa-creditdatetime
                IpFrom = wa-ipfrom
                Createon = wa-createon
                AccountId = wa-accountid
                CompanyCode = wa-companycode
                Plant = wa-plant
              ) )
          REPORTED DATA(ls_po_reported)
          FAILED   DATA(ls_po_failed)
          MAPPED   DATA(ls_po_mapped).

          COMMIT ENTITIES BEGIN
             RESPONSE OF zr_bankreceipt
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

  METHOD getCID.
    TRY.
        cid = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
      CATCH cx_uuid_error.
        ASSERT 1 = 0.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
