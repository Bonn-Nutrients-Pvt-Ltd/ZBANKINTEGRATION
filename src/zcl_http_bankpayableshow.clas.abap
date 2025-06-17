class ZCL_HTTP_BANKPAYABLESHOW definition
  public
  create public .

public section.

  interfaces IF_HTTP_SERVICE_EXTENSION .
  CLASS-METHODS saveData
    IMPORTING
      VALUE(request) TYPE REF TO if_web_http_request
    RETURNING
      VALUE(message) TYPE string .
protected section.
private section.
ENDCLASS.



CLASS ZCL_HTTP_BANKPAYABLESHOW IMPLEMENTATION.


  METHOD IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.
   CASE request->get_method(  ).
      WHEN CONV string( if_web_http_client=>post ).
        response->set_text( saveData( request ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD saveData.

    DATA(filename) = request->get_header_field( 'filename' ).
    SPLIT request->get_text( ) AT cl_abap_char_utilities=>newline INTO TABLE DATA(lt_lines).
    LOOP AT lt_lines INTO DATA(lv_line).
      SPLIT lv_line AT ',' INTO TABLE DATA(lt_fields).

      DATA(lv_posting_date) = lt_fields[ 6 ].
      DATA(lv_unique_id) = lt_fields[ 9 ].
      DATA(lv_status) = lt_fields[ 12 ].

      SELECT SINGLE * FROM zr_bankpayable
      WHERE UniqTracCode = @lv_unique_id
      INTO @DATA(ls_bankpayable).

      IF ls_bankpayable IS NOT INITIAL.

        DATA(status) = COND #(
                            WHEN lv_status = 'E' THEN 'Executed'
                            WHEN lv_status = 'R' THEN 'Rejected'
                            WHEN lv_status = 'P' THEN 'Pending'
                        ).

        DATA(utr) = COND #(
                            WHEN ls_bankpayable-TransType = 'I' THEN lt_fields[ 11 ]
                            WHEN ls_bankpayable-TransType = 'R' THEN lt_fields[ 16 ]
                            WHEN ls_bankpayable-TransType = 'N' THEN lt_fields[ 11 ]
                        ).

        DATA(log) = |{ status } in file - { filename }|.

        IF ls_bankpayable-PayStatus NE 'E' AND ls_bankpayable-PayStatus NE 'R'.
          MODIFY ENTITIES OF zr_bankpayable
          ENTITY ZrBankpayable
          UPDATE FIELDS ( PostingDate PayStatus utr Log )
           WITH VALUE #( (
               PostingDate = lv_posting_date
               PayStatus = lv_status
               utr = utr
               Log = log
               Createdtime = ls_bankpayable-Createdtime
               Vutdate = ls_bankpayable-Vutdate
               Unit = ls_bankpayable-Unit
               Vutacode = ls_bankpayable-Vutacode
             ) )
           FAILED DATA(lt_failed)
           REPORTED DATA(lt_reported).
            COMMIT ENTITIES BEGIN
             RESPONSE OF zr_bankpayable
             FAILED DATA(ls_save_failed)
             REPORTED DATA(ls_save_reported).
          COMMIT ENTITIES END.
          message = |Data saved successfully for Unique ID: { lv_unique_id }|.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
