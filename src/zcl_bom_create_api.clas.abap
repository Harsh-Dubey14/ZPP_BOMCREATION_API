CLASS zcl_bom_create_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_header,
             bom_id        TYPE sysuuid_x16,
             material      TYPE i_product-product,
             plant         TYPE i_plant-plant,
             bom_usage(1)  TYPE c,
             alt_bom(2)    TYPE c,
             base_qty      TYPE p LENGTH 16 DECIMALS 3,
             base_uom      TYPE i_billofmaterialitemtp_3-billofmaterialitemunit,
             valid_from    TYPE d,
             bom_status(2) TYPE c,
           END OF ty_header.

    TYPES: BEGIN OF ty_item,
             item_no(4)       TYPE c,
             item_category(1) TYPE c,
             component        TYPE i_product-product,
             quantity         TYPE p LENGTH 16 DECIMALS 3,
             uom              TYPE i_billofmaterialitemtp_3-billofmaterialitemunit,
             item_text(40)    TYPE c,
             sort_string(40)  TYPE c,
           END OF ty_item.

    TYPES ty_item_tab TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    TYPES: BEGIN OF ty_result,
             success      TYPE abap_boolean,
             base_uom     TYPE i_billofmaterialitemtp_3-billofmaterialitemunit,
             status(20)   TYPE c,
             message(255) TYPE c,
             api_response TYPE string,
           END OF ty_result.

    CLASS-METHODS create_bom
      IMPORTING
        is_header        TYPE ty_header
        it_item          TYPE ty_item_tab
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.

    CONSTANTS lc_bom_api_path TYPE string
      VALUE '/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/MaterialBOM'.

    CLASS-METHODS get_base_unit
      IMPORTING
        iv_material        TYPE i_product-product
      RETURNING
        VALUE(rv_base_uom) TYPE i_billofmaterialitemtp_3-billofmaterialitemunit.

    CLASS-METHODS build_payload
      IMPORTING
        is_header      TYPE ty_header
        it_item        TYPE ty_item_tab
        iv_base_uom    TYPE i_billofmaterialitemtp_3-billofmaterialitemunit
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS convert_date_to_odata
      IMPORTING
        iv_date              TYPE d
      RETURNING
        VALUE(rv_odata_date) TYPE string.

    CLASS-METHODS post_to_standard_api
      IMPORTING
        iv_payload       TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_result.

    CLASS-METHODS get_api_base_url
      RETURNING
        VALUE(rv_url) TYPE string.

    CLASS-METHODS get_basic_auth_header
      RETURNING
        VALUE(rv_authorization) TYPE string.

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

ENDCLASS.



CLASS ZCL_BOM_CREATE_API IMPLEMENTATION.


  METHOD create_bom.

    TRY.

        IF is_header-material IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'Material is mandatory'.
          RETURN.
        ENDIF.

        IF is_header-plant IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'Plant is mandatory'.
          RETURN.
        ENDIF.

        IF is_header-alt_bom IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'Alternative BOM / BOM Variant is mandatory'.
          RETURN.
        ENDIF.

        IF it_item IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'At least one BOM item is required'.
          RETURN.
        ENDIF.

        DATA(lv_base_uom) = get_base_unit( is_header-material ).

        IF lv_base_uom IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = |Base unit not found for material { is_header-material }|.
          RETURN.
        ENDIF.

        DATA(lv_payload) = build_payload(
          is_header   = is_header
          it_item     = it_item
          iv_base_uom = lv_base_uom
        ).

        IF lv_payload IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'Payload could not be built. Please check BOM item component, quantity and unit.'.
          RETURN.
        ENDIF.

        rs_result = post_to_standard_api( lv_payload ).
        rs_result-base_uom = lv_base_uom.

        IF rs_result-api_response IS INITIAL.
          rs_result-api_response = 'No API response received. API call may have failed before HTTP execution.'.
        ENDIF.

      CATCH cx_root INTO DATA(lx_error).

        rs_result-success = abap_false.
        rs_result-status  = 'ERROR'.
        rs_result-message = build_exception_message( lx_error ).

        IF rs_result-api_response IS INITIAL.
          rs_result-api_response = 'Exception occurred in create_bom before API response was received.'.
        ENDIF.

    ENDTRY.

  ENDMETHOD.


METHOD get_base_unit.

  SELECT SINGLE baseunit
    FROM i_product WITH PRIVILEGED ACCESS
    WHERE product = @iv_material
    INTO @rv_base_uom.

  IF rv_base_uom IS NOT INITIAL.

    rv_base_uom = zcl_uom_nzr_helper=>normalize_uom(
                    iv_uom = rv_base_uom
                  ).

  ENDIF.

ENDMETHOD.


  METHOD build_payload.

    DATA lv_date TYPE d.

    lv_date = COND #(
      WHEN is_header-valid_from IS INITIAL
      THEN cl_abap_context_info=>get_system_date( )
      ELSE is_header-valid_from
    ).

    DATA(lv_valid_from) = convert_date_to_odata( lv_date ).

    DATA(lv_usage) = COND string(
      WHEN is_header-bom_usage IS INITIAL THEN '1'
      ELSE is_header-bom_usage
    ).
    CONDENSE lv_usage NO-GAPS.
    TRANSLATE lv_usage TO UPPER CASE.

    DATA(lv_alt_bom) = CONV string( is_header-alt_bom ).
    CONDENSE lv_alt_bom NO-GAPS.

    DATA(lv_material) = |{ is_header-material ALPHA = OUT }|.
    CONDENSE lv_material NO-GAPS.

    DATA(lv_plant) = CONV string( is_header-plant ).
    CONDENSE lv_plant NO-GAPS.

    DATA(lv_base_uom) = CONV string( iv_base_uom ).
    CONDENSE lv_base_uom NO-GAPS.

    DATA(lv_header_qty) = |{ is_header-base_qty }|.
    CONDENSE lv_header_qty NO-GAPS.

    DATA(lv_bom_status) = COND string(
  WHEN is_header-bom_status IS INITIAL THEN '2'
  ELSE is_header-bom_status
).

    CONDENSE lv_bom_status NO-GAPS.

    IF lv_header_qty IS INITIAL OR lv_header_qty = '0.000' OR lv_header_qty = '0'.
      lv_header_qty = '1'.
    ENDIF.

    DATA(lv_items_json) = ``.

    LOOP AT it_item INTO DATA(ls_item).

      IF ls_item-component IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_component) = |{ ls_item-component ALPHA = OUT }|.
      CONDENSE lv_component NO-GAPS.

      DATA(lv_item_category) = COND string(
        WHEN ls_item-item_category IS INITIAL THEN 'L'
        ELSE ls_item-item_category
      ).
      CONDENSE lv_item_category NO-GAPS.
      TRANSLATE lv_item_category TO UPPER CASE.

      DATA(lv_qty) = |{ ls_item-quantity }|.
      CONDENSE lv_qty NO-GAPS.

      IF lv_qty IS INITIAL OR lv_qty = '0.000' OR lv_qty = '0'.
        CONTINUE.
      ENDIF.

      DATA(lv_item_no) = CONV string( ls_item-item_no ).
      CONDENSE lv_item_no NO-GAPS.

      IF lv_item_no IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_uom) = CONV string( ls_item-uom ).
      CONDENSE lv_uom NO-GAPS.
      TRANSLATE lv_uom TO UPPER CASE.

      IF lv_uom IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_sort_string) = CONV string( ls_item-sort_string ).
      CONDENSE lv_sort_string NO-GAPS.
      TRANSLATE lv_sort_string TO UPPER CASE.

      DATA(lv_sort_string_json) = ``.

      IF lv_sort_string IS NOT INITIAL.
        lv_sort_string_json = `"BOMItemSorter":"` && lv_sort_string && `",`.
      ENDIF.

      DATA(lv_relevance_json) = ``.

      CASE lv_usage.

        WHEN '1'. "Production
          lv_relevance_json = `"IsProductionRelevant":true`.

        WHEN '2'. "Engineering / Design
          lv_relevance_json = `"IsEngineeringRelevant":true`.

        WHEN '4'. "Plant Maintenance
          lv_relevance_json = `"BOMItemIsPlantMaintRelevant":true`.

        WHEN '5'. "Sales and Distribution
          lv_relevance_json = `"IsSalesRelevant":true`.

        WHEN 'S'. "Service Management
          lv_relevance_json = `"BOMItemIsPlantMaintRelevant":true`.

        WHEN OTHERS.
          lv_relevance_json = `"IsProductionRelevant":true`.

      ENDCASE.

      DATA(lv_item_json) =
        `{` &&
        `"BillOfMaterialItemCategory":"` && lv_item_category && `",` &&
        `"BillOfMaterialComponent":"` && lv_component && `",` &&
        `"BillOfMaterialItemQuantity":"` && lv_qty && `",` &&
        `"BillOfMaterialItemUnit":"` && lv_uom && `",` &&
        `"BillOfMaterialItemNumber":"` && lv_item_no && `",` &&
        lv_sort_string_json &&
        lv_relevance_json &&
        `}`.

      IF lv_items_json IS INITIAL.
        lv_items_json = lv_item_json.
      ELSE.
        lv_items_json = lv_items_json && `,` && lv_item_json.
      ENDIF.

    ENDLOOP.

    IF lv_items_json IS INITIAL.
      rv_json = ``.
      RETURN.
    ENDIF.

    rv_json =
      `{` &&
      `"BillOfMaterialCategory":"M",` &&
      `"BillOfMaterialVariant":"` && lv_alt_bom && `",` &&
      `"Material":"` && lv_material && `",` &&
      `"Plant":"` && lv_plant && `",` &&
      `"BillOfMaterialVariantUsage":"` && lv_usage && `",` &&
      `"BOMHeaderBaseUnit":"` && lv_base_uom && `",` &&
      `"BOMHeaderQuantityInBaseUnit":"` && lv_header_qty && `",` &&
      `"HeaderValidityStartDate":"` && lv_valid_from && `",` &&
      `"BillOfMaterialStatus":"` && lv_bom_status && `",` &&
      `"to_BillOfMaterialItem":{` &&
      `"results":[` && lv_items_json && `]` &&
      `}` &&
      `}`.

  ENDMETHOD.


  METHOD convert_date_to_odata.

    DATA lv_timestamp TYPE timestampl.

    IF iv_date IS INITIAL.
      RETURN.
    ENDIF.

    CONVERT DATE iv_date TIME '000000'
      INTO TIME STAMP lv_timestamp
      TIME ZONE 'UTC'.

    DATA(lv_seconds) = cl_abap_tstmp=>subtract(
      tstmp1 = lv_timestamp
      tstmp2 = CONV timestampl( '19700101000000' )
    ).

    DATA(lv_milliseconds) = lv_seconds * 1000.

    rv_odata_date = |/Date({ lv_milliseconds })/|.

  ENDMETHOD.


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
      "Already API URL
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


  METHOD post_to_standard_api.

    DATA lv_base_url      TYPE string.
    DATA lv_authorization TYPE string.
    DATA lv_token         TYPE string.
    DATA lv_response      TYPE string.
    DATA lv_status        TYPE i.

    TRY.

        lv_base_url      = get_api_base_url( ).
        lv_authorization = get_basic_auth_header( ).

        IF lv_base_url IS INITIAL.

          rs_result-success      = abap_false.
          rs_result-status       = 'ERROR'.
          rs_result-message      = 'API base URL could not be determined.'.
          rs_result-api_response = iv_payload.
          RETURN.

        ENDIF.

        IF lv_authorization IS INITIAL.

          rs_result-success      = abap_false.
          rs_result-status       = 'ERROR'.
          rs_result-message      = |Authorization could not be created for system { sy-sysid }.|.
          rs_result-api_response = iv_payload.
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

        lo_request->set_uri_path( lc_bom_api_path ).

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

        IF lv_status < 200 OR lv_status >= 300.

          rs_result-success      = abap_false.
          rs_result-status       = 'ERROR'.
          rs_result-message      = |CSRF token fetch failed. HTTP status: { lv_status }. { extract_error_message( lv_response ) }|.
          rs_result-api_response = |API Response: { lv_response } Payload Prepared: { iv_payload }|.
          RETURN.

        ENDIF.

        lv_token = lo_response->get_header_field( 'x-csrf-token' ).

        IF lv_token IS INITIAL.

          rs_result-success      = abap_false.
          rs_result-status       = 'ERROR'.
          rs_result-message      = 'CSRF token not received from BOM API'.
          rs_result-api_response = |API Response: { lv_response } Payload Prepared: { iv_payload }|.
          RETURN.

        ENDIF.

        lo_request = lo_client->get_http_request( ).

        lo_request->set_uri_path( lc_bom_api_path ).

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

        lv_status   = lo_response->get_status( )-code.
        lv_response = lo_response->get_text( ).

        IF lv_status >= 200 AND lv_status < 300.

          rs_result-success      = abap_true.
          rs_result-status       = 'SUCCESS'.
          rs_result-message      = |BOM created successfully. HTTP status: { lv_status }|.
          rs_result-api_response = lv_response.

        ELSE.

          DATA(lv_api_error) = extract_error_message( lv_response ).

          rs_result-success      = abap_false.
          rs_result-status       = 'ERROR'.
          rs_result-message      = |BOM creation failed. HTTP status: { lv_status }. { lv_api_error }|.
          rs_result-api_response = |API Response: { lv_response } Payload Sent: { iv_payload }|.

        ENDIF.

      CATCH cx_web_http_client_error INTO DATA(lx_http_error).

        rs_result-success = abap_false.
        rs_result-status  = 'ERROR'.

        DATA(lv_http_error_text) = lx_http_error->get_text( ).

        IF lv_http_error_text IS INITIAL.
          lv_http_error_text = 'CX_WEB_HTTP_CLIENT_ERROR occurred, but no detailed text was returned.'.
        ENDIF.

        rs_result-message =
          |HTTP client error while calling BOM API. Base URL: { lv_base_url }. API Path: { lc_bom_api_path }. Error: { lv_http_error_text }|.

        IF lv_response IS NOT INITIAL.
          rs_result-api_response = |API Response: { lv_response } Payload Sent: { iv_payload }|.
        ELSE.
          rs_result-api_response = |No HTTP response received. Payload Prepared: { iv_payload }|.
        ENDIF.

      CATCH cx_root INTO DATA(lx_error).

        rs_result-success = abap_false.
        rs_result-status  = 'ERROR'.
        rs_result-message = build_exception_message( lx_error ).

        IF lv_response IS NOT INITIAL.
          rs_result-api_response = |API Response: { lv_response } Payload Sent: { iv_payload }|.
        ELSE.
          rs_result-api_response =
            |Exception occurred before SAP API response was received. Payload Prepared: { iv_payload }|.
        ENDIF.

    ENDTRY.

  ENDMETHOD.


  METHOD extract_error_message.

    rv_message = iv_response.

    IF iv_response IS INITIAL.
      rv_message = 'No response body received from API.'.
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
      rv_message = 'Unknown exception occurred.'.
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
ENDCLASS.
