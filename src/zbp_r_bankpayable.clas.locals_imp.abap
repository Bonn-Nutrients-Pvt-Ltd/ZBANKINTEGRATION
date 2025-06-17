CLASS LHC_ZR_BANKPAYABLE DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR ZrBankpayable
        RESULT result.

          METHODS falsedelete FOR MODIFY
      IMPORTING keys FOR ACTION ZrBankpayable~falsedelete.


ENDCLASS.

CLASS LHC_ZR_BANKPAYABLE IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.

  METHOD falsedelete.

    MODIFY ENTITIES OF zr_bankpayable IN LOCAL MODE
            ENTITY ZrBankpayable
            UPDATE FIELDS ( Isdeleted )
            WITH VALUE #( FOR key IN keys INDEX INTO i (
                %tky       = key-%tky
                Isdeleted = abap_true
              ) )
            FAILED DATA(lt_failed)
            REPORTED DATA(lt_reported).



  ENDMETHOD.

ENDCLASS.
