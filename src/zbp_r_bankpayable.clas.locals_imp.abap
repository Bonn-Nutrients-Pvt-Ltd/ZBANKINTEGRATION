CLASS LHC_ZR_BANKPAYABLE DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR ZrBankpayable
        RESULT result.

          METHODS falsedelete FOR MODIFY
      IMPORTING keys FOR ACTION ZrBankpayable~falsedelete2.


ENDCLASS.

CLASS LHC_ZR_BANKPAYABLE IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.

  METHOD falsedelete.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

       DATA(Vutacode) = |{ <key>-Vutacode ALPHA = OUT }|.

      MODIFY ENTITIES OF zr_bankpayable IN LOCAL MODE
              ENTITY ZrBankpayable
              UPDATE FIELDS ( Isdeleted )
              WITH VALUE #( (
                  Isdeleted = abap_true
                   Createdtime = <key>-Createdtime
                   Vutdate = <key>-Vutdate
                   Unit = <key>-Unit
                   Vutacode = Vutacode
                ) )
              FAILED DATA(lt_failed)
              REPORTED DATA(lt_reported).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
