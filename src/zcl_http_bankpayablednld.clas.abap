class ZCL_HTTP_BANKPAYABLEDNLD definition
  public
  create public .

public section.

  interfaces IF_HTTP_SERVICE_EXTENSION .

  METHODS getDataForCSV
    IMPORTING
      VALUE(request) TYPE REF TO if_web_http_request
    RETURNING
      VALUE(message) TYPE string .
protected section.
private section.
ENDCLASS.



CLASS ZCL_HTTP_BANKPAYABLEDNLD IMPLEMENTATION.


  METHOD IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.
   CASE request->get_method(  ).
      WHEN CONV string( if_web_http_client=>post ).
        response->set_text( getDataForCSV( request ) ).
    ENDCASE.
  ENDMETHOD.


  METHOD getDataForCSV.

    DATA(file_name) = request->get_form_field( i_name = 'filename' ).

    SELECT * FROM zr_bankpayable
      WHERE UploadFileName = @file_name
            AND IsDeleted = ''
            AND IsPosted = ''
      INTO TABLE @DATA(lt_bankpayable).

    LOOP AT lt_bankpayable INTO DATA(ls_bankpayable).

      ls_bankpayable-Vutaacode = |{ ls_bankpayable-Vutaacode ALPHA = IN }|.

      SELECT SINGLE FROM I_BusinessPartnerBank AS a
          INNER JOIN I_Bank_2 AS b ON a~BankNumber = b~BankInternalID AND a~BankCountryKey = b~BankCountry
          FIELDS a~BankName, a~BankAccount AS BeneficiaryAccount, a~BankNumber AS IFSCCode, a~BankAccountHolderName AS BeneficiaryName,
                 b~BankBranch
          WHERE BusinessPartner = @ls_bankpayable-Vutaacode
          INTO @DATA(ls_businesspartnerbank).

      message = |{ message }{ ls_bankpayable-TransType },{ ls_bankpayable-Vutaacode },{ ls_businesspartnerbank-beneficiaryaccount },{ ls_bankpayable-Vutamt },| &&
                  |{ ls_businesspartnerbank-beneficiaryname },,,,,,,,{ ls_bankpayable-InstructionRefNum },{ ls_bankpayable-Custref },{ ls_bankpayable-Vutref },{ ls_bankpayable-UniqTracCode },,,,,,,{ ls_bankpayable-Vutdate },,| &&
                  |{ ls_businesspartnerbank-ifsccode },{ ls_businesspartnerbank-BankName },{ ls_businesspartnerbank-BankBranch },"{ ls_bankpayable-Vutemail }"\n|.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
