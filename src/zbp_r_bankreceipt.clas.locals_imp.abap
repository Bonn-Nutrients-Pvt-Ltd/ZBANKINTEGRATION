CLASS LHC_ZR_BANKRECEIPT DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.




  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR ZrBankreceipt
        RESULT result.
    METHODS falsedelete FOR MODIFY
      IMPORTING keys FOR ACTION ZrBankreceipt~falsedelete.


*       METHODS publish FOR MODIFY
*      IMPORTING keys FOR ACTION ZrBankreceipt~publishAction.







  ENDCLASS.

CLASS LHC_ZR_BANKRECEIPT IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.
  METHOD falsedelete.

    MODIFY ENTITIES OF zr_bankreceipt IN LOCAL MODE
            ENTITY ZrBankreceipt
            UPDATE FIELDS ( Isdeleted )
            WITH VALUE #( FOR key in keys INDEX INTO i (
                %tky       = key-%tky
                Isdeleted = abap_true
              ) )
            FAILED DATA(lt_failed)
            REPORTED DATA(lt_reported).



  ENDMETHOD.

ENDCLASS.
