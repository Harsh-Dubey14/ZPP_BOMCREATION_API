CLASS zcl_bom_put_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_http_result,
             success     TYPE abap_boolean,
             status_code TYPE i,
             message     TYPE string,
             response    TYPE string,
           END OF ty_http_result.


    CLASS-METHODS execute_post
      IMPORTING
        iv_path          TYPE string
        iv_payload       TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_http_result.

    CLASS-METHODS execute_delete
      IMPORTING
        iv_path          TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_http_result.

    CLASS-METHODS execute_patch
      IMPORTING
        iv_path          TYPE string
        iv_payload       TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_http_result.

    CLASS-METHODS execute_get
      IMPORTING
        iv_path          TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_http_result.

    CLASS-METHODS extract_error_message
      IMPORTING
        iv_response       TYPE string
      RETURNING
        VALUE(rv_message) TYPE string.

    CLASS-METHODS build_exception_message
      IMPORTING
        ix_error          TYPE REF TO cx_root
      RETURNING
        VALUE(rv_message) TYPE string.

  PRIVATE SECTION.

    CLASS-METHODS get_api_base_url
      RETURNING
        VALUE(rv_url) TYPE string.

    CLASS-METHODS get_basic_auth_header
      RETURNING
        VALUE(rv_authorization) TYPE string.

    CLASS-METHODS fetch_csrf_token
      IMPORTING
        iv_path      TYPE string
      EXPORTING
        ev_token     TYPE string
        ev_response  TYPE string
        ev_status    TYPE i
      RETURNING
        VALUE(rv_ok) TYPE abap_boolean.

ENDCLASS.



CLASS ZCL_BOM_PUT_HELPER IMPLEMENTATION.


  METHOD get_api_base_url.

    DATA lv_url TYPE string.

    lv_url = cl_abap_context_info=>get_system_url( ).
    CONDENSE lv_url NO-GAPS.

    IF lv_url CP '*/'.
      lv_url = substring(
        val = lv_url
        off = 0
        len = strlen( lv_url ) - 1
      ).
    ENDIF.

    IF lv_url CS '-api.s4hana.cloud.sap'.
      " Already API URL
    ELSE.
      REPLACE FIRST OCCURRENCE OF '.s4hana.cloud.sap'
        IN lv_url
        WITH '-api.s4hana.cloud.sap'.
    ENDIF.

    IF lv_url NA '://'.
      lv_url = |https://{ lv_url }|.
    ENDIF.

    rv_url = lv_url.

  ENDMETHOD.


  METHOD get_basic_auth_header.

    DATA lv_username TYPE string.
    DATA lv_password TYPE string.
    DATA lv_raw      TYPE string.
    DATA lv_base64   TYPE string.
    DATA lv_sysid    TYPE string.

    lv_sysid = sy-sysid.
    CONDENSE lv_sysid NO-GAPS.


    CASE lv_sysid.


      WHEN 'EGF'.

        lv_username = 'VIKRAM_API'.
        lv_password = '>z{2B%bvBB)3y+<9Xk652v}$q[SyyF]Y@pr%-Gc2'.

      WHEN 'EI8'.

        lv_username = 'VBOM_CREATE'.
        lv_password = 'xR[ai4)Xb\%}]9-Q%PunHT69qrpVRWY%@z>dqRwq'.

      WHEN 'ETT'.

        lv_username = 'ZCS01_BOM'.
        lv_password = 'A%3ENCn<sy~f2%hq97@S\qfVeF({9tjQGlEe+4(-'.

    ENDCASE.

    IF lv_username IS INITIAL OR lv_password IS INITIAL.
      CLEAR rv_authorization.
      RETURN.
    ENDIF.

    lv_raw = |{ lv_username }:{ lv_password }|.

    lv_base64 = cl_web_http_utility=>encode_base64(
      unencoded = lv_raw
    ).

    rv_authorization = |Basic { lv_base64 }|.

  ENDMETHOD.


  METHOD fetch_csrf_token.

    CLEAR: ev_token, ev_response, ev_status.

    TRY.

        DATA(lv_base_url)      = get_api_base_url( ).
        DATA(lv_authorization) = get_basic_auth_header( ).

        IF lv_base_url IS INITIAL OR lv_authorization IS INITIAL.
          ev_status   = 0.
          ev_response = 'Base URL or authorization is initial'.
          rv_ok       = abap_false.
          RETURN.
        ENDIF.

        DATA(lo_destination) =
          cl_http_destination_provider=>create_by_url(
            i_url = lv_base_url
          ).

        DATA(lo_client) =
          cl_web_http_client_manager=>create_by_http_destination(
            i_destination = lo_destination
          ).

        DATA(lo_request) = lo_client->get_http_request( ).

        lo_request->set_uri_path( iv_path ).

        lo_request->set_header_fields( VALUE #(
          ( name = 'Accept'        value = 'application/json' )
          ( name = 'Authorization' value = lv_authorization )
          ( name = 'x-csrf-token'  value = 'Fetch' )
        ) ).

        DATA(lo_response) = lo_client->execute(
          i_method = if_web_http_client=>get
        ).

        ev_status   = lo_response->get_status( )-code.
        ev_response = lo_response->get_text( ).
        ev_token    = lo_response->get_header_field( 'x-csrf-token' ).

        IF ev_status >= 200 AND ev_status < 300 AND ev_token IS NOT INITIAL.
          rv_ok = abap_true.
        ELSE.
          rv_ok = abap_false.
        ENDIF.

      CATCH cx_root INTO DATA(lx_error).
        ev_status   = 0.
        ev_response = build_exception_message( lx_error ).
        rv_ok       = abap_false.
    ENDTRY.

  ENDMETHOD.


  METHOD execute_get.

    TRY.

        DATA(lv_base_url)      = get_api_base_url( ).
        DATA(lv_authorization) = get_basic_auth_header( ).

        IF lv_base_url IS INITIAL.
          rs_result-success = abap_false.
          rs_result-message = 'API base URL could not be determined'.
          RETURN.
        ENDIF.

        IF lv_authorization IS INITIAL.
          rs_result-success = abap_false.
          rs_result-message = |Authorization could not be created for system { sy-sysid }|.
          RETURN.
        ENDIF.

        DATA(lo_destination) =
          cl_http_destination_provider=>create_by_url(
            i_url = lv_base_url
          ).

        DATA(lo_client) =
          cl_web_http_client_manager=>create_by_http_destination(
            i_destination = lo_destination
          ).

        DATA(lo_request) = lo_client->get_http_request( ).

        lo_request->set_uri_path( iv_path ).

        lo_request->set_header_fields( VALUE #(
          ( name = 'Accept'        value = 'application/json' )
          ( name = 'Authorization' value = lv_authorization )
        ) ).

        DATA(lo_response) = lo_client->execute(
          i_method = if_web_http_client=>get
        ).

        rs_result-status_code = lo_response->get_status( )-code.
        rs_result-response    = lo_response->get_text( ).

        IF rs_result-status_code >= 200 AND rs_result-status_code < 300.
          rs_result-success = abap_true.
          rs_result-message = |GET successful. HTTP status: { rs_result-status_code }|.
        ELSE.
          rs_result-success = abap_false.
          rs_result-message = |GET failed. HTTP status: { rs_result-status_code }. { extract_error_message( rs_result-response ) }|.
        ENDIF.

      CATCH cx_root INTO DATA(lx_error).
        rs_result-success = abap_false.
        rs_result-message = build_exception_message( lx_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD execute_patch.

    TRY.

        DATA lv_token    TYPE string.
        DATA lv_response TYPE string.
        DATA lv_status   TYPE i.

        DATA(lv_base_url)      = get_api_base_url( ).
        DATA(lv_authorization) = get_basic_auth_header( ).

        IF lv_base_url IS INITIAL.
          rs_result-success  = abap_false.
          rs_result-message  = 'API base URL could not be determined'.
          rs_result-response = iv_payload.
          RETURN.
        ENDIF.

        IF lv_authorization IS INITIAL.
          rs_result-success  = abap_false.
          rs_result-message  = |Authorization could not be created for system { sy-sysid }|.
          rs_result-response = iv_payload.
          RETURN.
        ENDIF.

        DATA(lo_destination) =
          cl_http_destination_provider=>create_by_url(
            i_url = lv_base_url
          ).

        DATA(lo_client) =
          cl_web_http_client_manager=>create_by_http_destination(
            i_destination = lo_destination
          ).

        "------------------------------------------------------------
        " 1. Fetch CSRF token using SAME HTTP client
        "------------------------------------------------------------
        DATA(lo_request) = lo_client->get_http_request( ).

        lo_request->set_uri_path( iv_path ).

        lo_request->set_header_fields( VALUE #(
          ( name = 'Accept'        value = 'application/json' )
          ( name = 'Authorization' value = lv_authorization )
          ( name = 'x-csrf-token'  value = 'Fetch' )
        ) ).

        DATA(lo_response) = lo_client->execute(
          i_method = if_web_http_client=>get
        ).

        lv_status   = lo_response->get_status( )-code.
        lv_response = lo_response->get_text( ).
        lv_token    = lo_response->get_header_field( 'x-csrf-token' ).

        IF lv_status < 200 OR lv_status >= 300 OR lv_token IS INITIAL.
          rs_result-success     = abap_false.
          rs_result-status_code = lv_status.
          rs_result-message     = |CSRF token fetch failed. HTTP status: { lv_status }. { extract_error_message( lv_response ) }|.
          rs_result-response    = |API Response: { lv_response } Payload Prepared: { iv_payload }|.
          RETURN.
        ENDIF.

        "------------------------------------------------------------
        " 2. PATCH using SAME HTTP client/session
        "------------------------------------------------------------
        lo_request = lo_client->get_http_request( ).

        lo_request->set_uri_path( iv_path ).

        lo_request->set_header_fields( VALUE #(
          ( name = 'Accept'        value = 'application/json' )
          ( name = 'Content-Type'  value = 'application/json' )
          ( name = 'Authorization' value = lv_authorization )
          ( name = 'x-csrf-token'  value = lv_token )
          ( name = 'If-Match'      value = '*' )
        ) ).

        lo_request->set_text( iv_payload ).

        lo_response = lo_client->execute(
          i_method = if_web_http_client=>patch
        ).

        rs_result-status_code = lo_response->get_status( )-code.
        rs_result-response    = lo_response->get_text( ).

        IF rs_result-status_code = 204.
          rs_result-success = abap_true.
          rs_result-message = |PATCH successful. HTTP status: { rs_result-status_code }|.
        ELSE.
          rs_result-success = abap_false.
          rs_result-message = |PATCH failed. HTTP status: { rs_result-status_code }. { extract_error_message( rs_result-response ) }|.
        ENDIF.

      CATCH cx_web_http_client_error INTO DATA(lx_http_error).
        rs_result-success  = abap_false.
        rs_result-message  = |HTTP client error: { lx_http_error->get_text( ) }|.
        rs_result-response = |Payload Prepared: { iv_payload }|.

      CATCH cx_root INTO DATA(lx_error).
        rs_result-success  = abap_false.
        rs_result-message  = build_exception_message( lx_error ).
        rs_result-response = |Payload Prepared: { iv_payload }|.

    ENDTRY.

  ENDMETHOD.


  METHOD extract_error_message.

    rv_message = iv_response.

    IF iv_response IS INITIAL.
      rv_message = 'No response body received from API'.
      RETURN.
    ENDIF.

    TRY.

        TYPES: BEGIN OF ty_error_message,
                 value TYPE string,
               END OF ty_error_message.

        TYPES: BEGIN OF ty_error,
                 code    TYPE string,
                 message TYPE ty_error_message,
               END OF ty_error.

        TYPES: BEGIN OF ty_error_root,
                 error TYPE ty_error,
               END OF ty_error_root.

        DATA ls_error TYPE ty_error_root.

        /ui2/cl_json=>deserialize(
          EXPORTING
            json = iv_response
          CHANGING
            data = ls_error
        ).

        IF ls_error-error-message-value IS NOT INITIAL.
          rv_message = ls_error-error-message-value.
        ELSEIF ls_error-error-code IS NOT INITIAL.
          rv_message = ls_error-error-code.
        ELSE.
          rv_message = iv_response.
        ENDIF.

      CATCH cx_root.
        rv_message = iv_response.
    ENDTRY.

  ENDMETHOD.


  METHOD build_exception_message.

    DATA lv_class_name TYPE string.
    DATA lv_text       TYPE string.

    IF ix_error IS INITIAL.
      rv_message = 'Unknown exception occurred'.
      RETURN.
    ENDIF.

    TRY.
        lv_class_name = cl_abap_classdescr=>get_class_name( ix_error ).
      CATCH cx_root.
        lv_class_name = 'UNKNOWN_EXCEPTION_CLASS'.
    ENDTRY.

    lv_text = ix_error->get_text( ).

    IF lv_text IS INITIAL.
      rv_message = |Exception: { lv_class_name }|.
    ELSE.
      rv_message = |Exception: { lv_class_name } - { lv_text }|.
    ENDIF.

  ENDMETHOD.


  METHOD execute_post.

    TRY.

        DATA lv_token    TYPE string.
        DATA lv_response TYPE string.
        DATA lv_status   TYPE i.

        DATA(lv_base_url)      = get_api_base_url( ).
        DATA(lv_authorization) = get_basic_auth_header( ).

        IF lv_base_url IS INITIAL.
          rs_result-success  = abap_false.
          rs_result-message  = 'API base URL could not be determined'.
          rs_result-response = iv_payload.
          RETURN.
        ENDIF.

        IF lv_authorization IS INITIAL.
          rs_result-success  = abap_false.
          rs_result-message  = |Authorization could not be created for system { sy-sysid }|.
          rs_result-response = iv_payload.
          RETURN.
        ENDIF.

        DATA(lo_destination) =
          cl_http_destination_provider=>create_by_url(
            i_url = lv_base_url
          ).

        DATA(lo_client) =
          cl_web_http_client_manager=>create_by_http_destination(
            i_destination = lo_destination
          ).

        "------------------------------------------------------------
        " 1. Fetch CSRF token using SAME HTTP client/session
        "------------------------------------------------------------
        DATA(lo_request) = lo_client->get_http_request( ).

*        lo_request->set_uri_path( iv_path ).


lo_request->set_uri_path(
  '/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/'
).
        lo_request->set_header_fields( VALUE #(
          ( name = 'Accept'        value = 'application/json' )
          ( name = 'Authorization' value = lv_authorization )
          ( name = 'x-csrf-token'  value = 'Fetch' )
        ) ).

        DATA(lo_response) = lo_client->execute(
          i_method = if_web_http_client=>get
        ).

        lv_status   = lo_response->get_status( )-code.
        lv_response = lo_response->get_text( ).
        lv_token    = lo_response->get_header_field( 'x-csrf-token' ).

        IF lv_status < 200 OR lv_status >= 300 OR lv_token IS INITIAL.
          rs_result-success     = abap_false.
          rs_result-status_code = lv_status.
          rs_result-message     = |CSRF token fetch failed. HTTP status: { lv_status }. { extract_error_message( lv_response ) }|.
          rs_result-response    = |API Response: { lv_response } Payload Prepared: { iv_payload }|.
          RETURN.
        ENDIF.

        "------------------------------------------------------------
        " 2. POST using SAME HTTP client/session
        "------------------------------------------------------------
        lo_request = lo_client->get_http_request( ).

        lo_request->set_uri_path( iv_path ).

        lo_request->set_header_fields( VALUE #(
          ( name = 'Accept'        value = 'application/json' )
          ( name = 'Content-Type'  value = 'application/json' )
          ( name = 'Authorization' value = lv_authorization )
          ( name = 'x-csrf-token'  value = lv_token )
        ) ).

        lo_request->set_text( iv_payload ).

        lo_response = lo_client->execute(
          i_method = if_web_http_client=>post
        ).

        rs_result-status_code = lo_response->get_status( )-code.
        rs_result-response    = lo_response->get_text( ).

        IF rs_result-status_code = 201.
          rs_result-success = abap_true.
          rs_result-message = |POST successful. HTTP status: { rs_result-status_code }|.
        ELSE.
          rs_result-success = abap_false.
          rs_result-message = |POST failed. HTTP status: { rs_result-status_code }. { extract_error_message( rs_result-response ) }|.
        ENDIF.

      CATCH cx_web_http_client_error INTO DATA(lx_http_error).
        rs_result-success  = abap_false.
        rs_result-message  = |HTTP client error: { lx_http_error->get_text( ) }|.
        rs_result-response = |Payload Prepared: { iv_payload }|.

      CATCH cx_root INTO DATA(lx_error).
        rs_result-success  = abap_false.
        rs_result-message  = build_exception_message( lx_error ).
        rs_result-response = |Payload Prepared: { iv_payload }|.

    ENDTRY.

  ENDMETHOD.



METHOD execute_delete.

  TRY.

      DATA lv_token    TYPE string.
      DATA lv_response TYPE string.
      DATA lv_status   TYPE i.

      DATA(lv_base_url)      = get_api_base_url( ).
      DATA(lv_authorization) = get_basic_auth_header( ).

      IF lv_base_url IS INITIAL.
        rs_result-success = abap_false.
        rs_result-message = 'API base URL could not be determined'.
        RETURN.
      ENDIF.

      IF lv_authorization IS INITIAL.
        rs_result-success = abap_false.
        rs_result-message = |Authorization could not be created for system { sy-sysid }|.
        RETURN.
      ENDIF.

      DATA(lo_destination) =
        cl_http_destination_provider=>create_by_url(
          i_url = lv_base_url
        ).

      DATA(lo_client) =
        cl_web_http_client_manager=>create_by_http_destination(
          i_destination = lo_destination
        ).

      "------------------------------------------------------------
      " 1. Fetch CSRF token from SERVICE ROOT, not item path
      "    Important: item GET can fail if old UOM ST is not maintained
      "------------------------------------------------------------
      DATA(lo_request) = lo_client->get_http_request( ).

      lo_request->set_uri_path(
        '/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/'
      ).

      lo_request->set_header_fields( VALUE #(
        ( name = 'Accept'        value = 'application/json' )
        ( name = 'Authorization' value = lv_authorization )
        ( name = 'x-csrf-token'  value = 'Fetch' )
      ) ).

      DATA(lo_response) = lo_client->execute(
        i_method = if_web_http_client=>get
      ).

      lv_status   = lo_response->get_status( )-code.
      lv_response = lo_response->get_text( ).
      lv_token    = lo_response->get_header_field( 'x-csrf-token' ).

      IF lv_status < 200 OR lv_status >= 300 OR lv_token IS INITIAL.
        rs_result-success     = abap_false.
        rs_result-status_code = lv_status.
        rs_result-message     = |CSRF token fetch failed. HTTP status: { lv_status }. { extract_error_message( lv_response ) }|.
        rs_result-response    = lv_response.
        RETURN.
      ENDIF.

      "------------------------------------------------------------
      " 2. DELETE actual BOM item using If-Match = *
      "------------------------------------------------------------
      lo_request = lo_client->get_http_request( ).

      lo_request->set_uri_path( iv_path ).

      lo_request->set_header_fields( VALUE #(
        ( name = 'Accept'        value = 'application/json' )
        ( name = 'Authorization' value = lv_authorization )
        ( name = 'x-csrf-token'  value = lv_token )
        ( name = 'If-Match'      value = '*' )
      ) ).

      lo_response = lo_client->execute(
        i_method = if_web_http_client=>delete
      ).

      rs_result-status_code = lo_response->get_status( )-code.
      rs_result-response    = lo_response->get_text( ).

      IF rs_result-status_code = 204.
        rs_result-success = abap_true.
        rs_result-message = |DELETE successful. HTTP status: { rs_result-status_code }|.
      ELSE.
        rs_result-success = abap_false.
        rs_result-message = |DELETE failed. HTTP status: { rs_result-status_code }. { extract_error_message( rs_result-response ) }|.
      ENDIF.

    CATCH cx_web_http_client_error INTO DATA(lx_http_error).

      rs_result-success = abap_false.
      rs_result-message = |HTTP client error: { lx_http_error->get_text( ) }|.

    CATCH cx_root INTO DATA(lx_error).

      rs_result-success = abap_false.
      rs_result-message = build_exception_message( lx_error ).

  ENDTRY.

ENDMETHOD.
ENDCLASS.
